# 11. Password Aging And Superuser Access

**Objectives:** Change passwords and adjust password aging for local user accounts. Configure superuser access.

Both halves are common exam tasks. `chage` flags and the `sudoers` file format are worth memorising precisely.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Confusing password expiry with account expiry, or `login.defs` with existing users, loses points on otherwise correct work.

---

## Follow Along

Work on your lab VM. Create a test user first if you need one: `sudo useradd labuser`.

After each step, compare your output to **You should see**.

### 1. Read shadow aging in human form

```bash
sudo chage -l labuser
sudo getent shadow labuser
```

**You should see** dates and day counts in `chage -l`, while `getent shadow` shows raw epoch day numbers in fields 3–8.

Dates in `/etc/shadow` are stored as **days since 1970-01-01**. That is why `chage -l` exists.

### 2. Map shadow fields to chage flags

```text
alice:$6$xyz...:19950:0:90:7:14:20000:
  │      │        │   │  │  │  │   │
  │      │        │   │  │  │  │   └─ 8. account expiry       chage -E
  │      │        │   │  │  │  └───── 7. inactive after expiry chage -I
  │      │        │   │  │  └──────── 6. warning days          chage -W
  │      │        │   │  └─────────── 5. maximum password age  chage -M
  │      │        │   └────────────── 4. minimum password age  chage -m
  │      │        └────────────────── 3. last change            chage -d
  │      └───────────────────────────  2. hash ('!' = locked)
  └────────────────────────────────── 1. username
```

Memorable order: **`-m` minimum, `-M` Maximum, `-W` Warn, `-I` Inactive, `-E` Expire.**

### 3. Set maximum, minimum, and warning periods

```bash
sudo chage -M 90 -m 7 -W 14 labuser
sudo chage -l labuser | grep -E 'Minimum|Maximum|warning'
```

**You should see** maximum 90 days, minimum 7 days, warning 14 days.

**Lowercase `-m` is minimum. Uppercase `-M` is maximum.** Swapping them is a common exam trap.

Equivalent with `passwd`:

```bash
sudo passwd -n 7 -x 90 -w 14 labuser
```

### 4. Force a password change at next login

```bash
sudo chage -d 0 labuser
sudo chage -l labuser | head -2
```

**You should see** `Last password change : password must be changed`.

`-d 0` sets the last-change date to the epoch, so any non-zero `-M` makes the password immediately expired. Equivalent: `sudo passwd -e labuser`.

### 5. Set an account expiry date

```bash
sudo chage -E 2027-06-30 labuser
sudo chage -l labuser | grep -i 'account expires'
```

**You should see** `Account expires : Jun 30, 2027`. Format is **`YYYY-MM-DD`**.

Remove it with `sudo chage -E -1 labuser` or `sudo usermod -e '' labuser`.

### 6. Password expiry versus account expiry

| | Password expiry (`-M`) | Account expiry (`-E`) |
| --- | --- | --- |
| What happens | User is **forced to change** password at login | Account is **disabled entirely** |
| Can the user recover? | Yes, by setting a new password | No — admin must extend it |
| Set by | `chage -M` | `chage -E` or `usermod -e` |

**You should see** these are different columns in `chage -l`. The exam tests the distinction.

### 7. Set a password non-interactively

```bash
echo 'Redhat123' | sudo passwd --stdin labuser
sudo passwd -S labuser
```

**You should see** `labuser PS ...` — password set. Portable alternative: `echo 'labuser:Redhat123' | sudo chpasswd`.

### 8. System-wide defaults for new users

```bash
sudo grep -E '^PASS_' /etc/login.defs
```

**You should see** `PASS_MAX_DAYS`, `PASS_MIN_DAYS`, `PASS_WARN_AGE`. Edit them to change defaults for **future** accounts only:

```bash
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sudo grep -E '^PASS_' /etc/login.defs
```

**Existing users are unchanged.** If a task says "all users, including existing ones", you must also loop with `chage`.

### 9. Grant sudo via the wheel group

```bash
sudo grep -E '^\s*%wheel' /etc/sudoers
sudo usermod -aG wheel labuser
id labuser
```

**You should see** the line `%wheel  ALL=(ALL)       ALL` and `wheel` in labuser's groups.

**`-aG`, not `-G`.** Membership takes effect at the user's **next login**.

### 10. Create a sudoers drop-in safely

```bash
echo '%admins ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/admins
sudo chmod 440 /etc/sudoers.d/admins
sudo visudo -c
ls -l /etc/sudoers.d/admins
```

**You should see** mode **`440`** and `visudo -c` reports parsed OK.

Files that are group- or world-writable are **silently ignored**. Filenames with a `.` or `~` are also skipped.

**Never edit `/etc/sudoers` with plain vim.** Use `visudo`.

### 11. Verify another user's sudo privileges

```bash
sudo -l -U labuser
sudo -l                            # your own privileges
```

**You should see** what commands labuser may run, without logging in as her. This is the correct verification for any sudoers task.

### 12. Lock and unlock a password

```bash
sudo usermod -L labuser
sudo getent shadow labuser | cut -d: -f2 | head -c 3
sudo passwd -S labuser
sudo usermod -U labuser
sudo passwd -S labuser
```

**You should see** `LK` when locked (hash prefixed with `!`), then `PS` when unlocked.

Remember: **a locked password still allows SSH key login.** Use `chage -E 0` or `nologin` to block everything.

### Mini checkpoint

| Flag | Sets |
| --- | --- |
| `-m` | minimum days between password changes |
| `-M` | maximum password age |
| `-W` | warning days before expiry |
| `-I` | inactive days after password expires |
| `-E` | account expiry date |
| `-d 0` | force change at next login |

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Set the password for user `natasha` to `Redhat123` without an interactive prompt.

> Hint: `passwd --stdin` or `chpasswd`; verify with `passwd -S`.

**Task 2.** Display all current password aging information for `natasha`.

> Hint: `chage -l`.

**Task 3.** Configure `natasha`'s account so her password must be changed every 60 days, cannot be changed more than once every 3 days, and warns her 10 days in advance.

> Hint: `chage -M 60 -m 3 -W 10`; watch lowercase vs uppercase.

**Task 4.** Force `natasha` to change her password at her next login.

> Hint: `chage -d 0` or `passwd -e`.

**Task 5.** Set `natasha`'s account to expire on 30 June 2027.

> Hint: `chage -E 2027-06-30`; format `YYYY-MM-DD`.

**Task 6.** Configure the system so that **newly created** users have a maximum password age of 90 days and a warning period of 14 days.

> Hint: edit `PASS_MAX_DAYS` and `PASS_WARN_AGE` in `/etc/login.defs`; verify with a test user.

**Task 7.** Apply a maximum password age of 90 days to **every existing** regular user account on the system.

> Hint: loop `chage -M 90` over `awk -F: '$3>=1000'`.

**Task 8.** Grant user `harry` full administrative privileges using the standard RHEL group mechanism.

> Hint: `usermod -aG wheel`; confirm the `%wheel` rule in `/etc/sudoers`.

**Task 9.** Create a sudo rule allowing every member of the group `admins` to run all commands **without being prompted for a password**. Use a drop-in file and validate it.

> Hint: `%admins`, `NOPASSWD:`, mode `440`, `visudo -c`; no dot in the filename.

**Task 10.** Create a sudo rule allowing user `bob` to run only `/usr/bin/systemctl restart httpd` and nothing else.

> Hint: `visudo -f /etc/sudoers.d/bob`; use the absolute path from `which systemctl`.

**Task 11.** Verify what commands `bob` is permitted to run via sudo, without logging in as him.

> Hint: `sudo -l -U bob`.

**Task 12.** Lock `natasha`'s password, verify the lock in `/etc/shadow`, then unlock it.

> Hint: `usermod -L` / `-U`; hash starts with `!`; `passwd -S` shows `LK`.

**Task 13.** Configure the account `contractor` so that it is automatically disabled 15 days after its password expires.

> Hint: `chage -I 15` — capital I for inactive period.

**Task 14.** Determine which users on the system currently have passwords that never expire.

> Hint: field 5 empty or `99999` in `/etc/shadow`, or `chage -l` maximum of 99999.

**Task 15.** A sudo drop-in file exists at `/etc/sudoers.d/devteam` but appears to have no effect. Diagnose and fix it.

> Hint: check permissions (`440`), filename (no dots), and `#includedir` in `/etc/sudoers`.

---

## Solutions

**Task 1.**

```bash
echo 'Redhat123' | sudo passwd --stdin natasha
```

Portable alternative:

```bash
echo 'natasha:Redhat123' | sudo chpasswd
```

Verify:

```bash
sudo passwd -S natasha        # natasha PS ...
```

`PS` confirms a password is set. Interactively, plain `sudo passwd natasha` is perfectly acceptable on the exam and often quicker.

**Task 2.**

```bash
sudo chage -l natasha
```

The raw equivalent, if you want to see the stored fields:

```bash
sudo getent shadow natasha
```

`chage -l` converts the epoch day counts into dates, which is why you use it.

**Task 3.**

```bash
sudo chage -M 60 -m 3 -W 10 natasha
sudo chage -l natasha
```

Expected:

```text
Minimum number of days between password change          : 3
Maximum number of days between password change          : 60
Number of days of warning before password expires       : 10
```

**Lowercase `-m` is minimum, uppercase `-M` is maximum.** Swapping them sets a minimum of 60 days, which would prevent the user changing their password for two months — the opposite of the intent.

Equivalent with `passwd`:

```bash
sudo passwd -n 3 -x 60 -w 10 natasha
```

**Task 4.**

```bash
sudo chage -d 0 natasha
sudo chage -l natasha | head -2
```

Shows `Last password change : password must be changed`. At her next login she is required to set a new one before getting a shell.

Equivalent:

```bash
sudo passwd -e natasha
```

Verify the mechanism: `-d 0` sets field 3 to zero, meaning "changed on 1 Jan 1970", so any non-zero `-M` makes it already expired.

**Task 5.**

```bash
sudo chage -E 2027-06-30 natasha
sudo chage -l natasha | grep -i 'account expires'
```

Format is **`YYYY-MM-DD`**. To remove an expiry:

```bash
sudo chage -E -1 natasha
```

`usermod -e 2027-06-30 natasha` does the same thing. Both are correct.

**Task 6.**

```bash
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs
sudo grep -E '^PASS_' /etc/login.defs
```

Verify by creating a test account:

```bash
sudo useradd testaging
sudo chage -l testaging | grep -i maximum      # 90
sudo userdel -r testaging
```

**This affects new accounts only.** The task said "newly created", so this is complete. If it had said "all users", you would also need Task 7.

**Task 7.**

```bash
for u in $(awk -F: '$3>=1000 && $3<65534 {print $1}' /etc/passwd); do
  sudo chage -M 90 "$u"
done
```

Verify:

```bash
for u in $(awk -F: '$3>=1000 && $3<65534 {print $1}' /etc/passwd); do
  printf '%-12s %s\n' "$u" "$(sudo chage -l $u | awk -F: '/Maximum/{print $2}')"
done
```

**Read the task wording carefully.** "Configure the default for new users" is `/etc/login.defs`. "Configure all users" requires this loop as well. A task that says "all users, including existing ones" needs both, and candidates routinely do only one.

**Task 8.**

```bash
sudo usermod -aG wheel harry
id harry
```

Verify the `wheel` rule is active:

```bash
sudo grep -E '^\s*%wheel' /etc/sudoers
sudo -l -U harry
```

**`-aG`, not `-G`.** And membership takes effect at his **next login** — an existing session keeps the old group set. If a task requires immediate effect in a current session, `newgrp wheel` or a re-login is needed.

**Task 9.**

```bash
echo '%admins ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/admins
sudo chmod 440 /etc/sudoers.d/admins
sudo visudo -c
```

Verify:

```bash
sudo -l -U natasha        # natasha's primary group is admins
```

Three details that matter: the **`%`** prefix marks a group, mode **`440`** is required or the file is ignored, and **`visudo -c`** confirms you have not broken sudo globally.

The filename must contain no dots. `/etc/sudoers.d/admins` is fine; `/etc/sudoers.d/admins.conf` would be silently skipped.

**Task 10.**

```bash
sudo visudo -f /etc/sudoers.d/bob
```

Content:

```text
bob ALL=(ALL) /usr/bin/systemctl restart httpd
```

Then:

```bash
sudo chmod 440 /etc/sudoers.d/bob
sudo visudo -c
```

Verify:

```bash
sudo -l -U bob
```

**Use the absolute path.** `systemctl restart httpd` without `/usr/bin/` does not match and the rule will not work. Find the path with:

```bash
which systemctl        # /usr/bin/systemctl
```

Be aware this rule is weaker than it looks: `systemctl` can be persuaded to do more than restart httpd. That is a real security consideration but not something the exam grades.

**Task 11.**

```bash
sudo -l -U bob
```

Output:

```text
User bob may run the following commands on server1:
    (ALL) /usr/bin/systemctl restart httpd
```

`-U user` inspects another user's privileges without becoming them. This is the correct verification for any sudoers task.

**Task 12.**

```bash
sudo usermod -L natasha
sudo getent shadow natasha | cut -d: -f2 | head -c 3
sudo passwd -S natasha           # LK
```

The hash is now prefixed with **`!`**. `passwd -l` uses `!!`; either indicates a locked password.

Unlock:

```bash
sudo usermod -U natasha
sudo passwd -S natasha           # PS
```

Remember the limitation: **a locked password does not prevent SSH key authentication.** To deny all access:

```bash
sudo chage -E 0 natasha          # expire the account
sudo usermod -s /sbin/nologin natasha
```

**Task 13.**

```bash
sudo chage -I 15 contractor
sudo chage -l contractor
```

`-I` (capital i) is the **inactive** period: after the password expires, the user has 15 days to change it, after which the account is disabled entirely. It corresponds to field 7 of `/etc/shadow`.

The sequence is: password expires (field 5) → grace period (field 7) → account disabled. Distinct from `-E`, which is an absolute date regardless of password state.

**Task 14.**

```bash
sudo awk -F: '$5 == "" || $5 >= 99999 {print $1}' /etc/shadow
```

Field 5 is the maximum age. `99999` days is roughly 273 years, which is the RHEL default and effectively "never".

A more readable loop:

```bash
for u in $(awk -F: '$3>=1000 && $3<65534 {print $1}' /etc/passwd); do
  max=$(sudo chage -l "$u" | awk -F: '/Maximum/{gsub(/ /,"",$2); print $2}')
  [ "$max" = "99999" ] && echo "$u never expires"
done
```

**Task 15.**

Create the broken scenario:

```bash
echo '%devs ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/devteam
sudo chmod 666 /etc/sudoers.d/devteam        # the problem
```

Diagnose:

```bash
sudo -l -U alice                     # the rule does not appear
sudo visudo -c
```

`visudo -c` reports something like:

```text
/etc/sudoers.d/devteam: bad permissions, should be mode 0440
```

Fix:

```bash
sudo chmod 440 /etc/sudoers.d/devteam
sudo visudo -c
sudo -l -U alice                     # now present
```

The three reasons a drop-in is ignored, in order of likelihood:

1. **Permissions are too open.** Must be `0440` (or at least not group/world-writable), owned by root.
2. **The filename contains a `.` or ends in `~`.** Those are skipped by design.
3. **`#includedir /etc/sudoers.d` is missing** from `/etc/sudoers`. Check with `sudo grep includedir /etc/sudoers`.

---

## Verify

```bash
sudo chage -l natasha
sudo chage -l contractor
sudo passwd -S natasha
sudo grep -E '^PASS_' /etc/login.defs
ls -l /etc/sudoers.d/
sudo visudo -c
sudo -l -U harry
sudo -l -U bob
id harry
```

## Persistence Check

| Change | Persistent artifact |
| --- | --- |
| `passwd`, `chpasswd` | `/etc/shadow` |
| `chage` settings | `/etc/shadow` fields 3-8 |
| `usermod -L` / `-U` | `/etc/shadow` hash prefix |
| `login.defs` edits | `/etc/login.defs` |
| `wheel` membership | `/etc/group` |
| sudo rules | `/etc/sudoers` or `/etc/sudoers.d/*` |

All of it persists with no service to enable. The failure modes are different here:

- **A sudoers drop-in with the wrong permissions** looks correct in the file but does nothing. Verify with `sudo -l -U user`, not by reading the file.
- **`login.defs` changes do not retroactively apply.** If the task covers existing users, loop with `chage`.
- **Group membership takes effect at next login**, so verifying in your current shell can mislead you.

Post-reboot check:

```bash
sudo visudo -c                     # all files parse
sudo -l -U harry                   # rule still in effect
sudo chage -l natasha | head -4    # aging still set
id harry                           # still in wheel
```

## Quick Reference

Come back here when you need a flag you forgot — not before your first pass through Follow Along.

### /etc/shadow field map

The nine colon-separated fields, and the `chage` flag that sets each:

```text
alice:$6$xyz...:19950:0:90:7:14:20000:
  │      │        │   │  │  │  │   │
  │      │        │   │  │  │  │   └─ 8. account expiry date       chage -E
  │      │        │   │  │  │  └───── 7. inactive days after expiry chage -I
  │      │        │   │  │  └──────── 6. warning days              chage -W
  │      │        │   │  └─────────── 5. maximum password age       chage -M
  │      │        │   └────────────── 4. minimum password age       chage -m
  │      │        └────────────────── 3. last change (days since epoch)  chage -d
  │      └───────────────────────────  2. hash ('!' or '!!' prefix = locked)
  └────────────────────────────────── 1. username
```

**Dates are stored as days since 1970-01-01**, not as readable dates. That is why `chage -l` exists — it converts them for you.

```bash
sudo getent shadow alice
sudo chage -l alice          # the same data, human-readable
```

### chage

```bash
chage -l alice                    # LIST current aging settings
chage -M 90 alice                 # maximum age: must change every 90 days
chage -m 7 alice                  # minimum age: cannot change again for 7 days
chage -W 14 alice                 # warn 14 days before expiry
chage -I 30 alice                 # disable account 30 days after password expires
chage -E 2026-12-31 alice         # ACCOUNT expiry date
chage -E -1 alice                 # remove account expiry
chage -d 0 alice                  # FORCE a password change at next login
chage -d 2026-08-18 alice         # set the last-change date explicitly
chage alice                       # interactive
```

**`chage -d 0` is the "must change password at next login" task.** It sets the last-change date to the epoch, so the password is immediately considered expired.

The flags in a memorable order: **`-m` minimum, `-M` Maximum, `-W` Warn, `-I` Inactive, `-E` Expire.** Lowercase `-m` is minimum days, uppercase `-M` is maximum days.

Example `chage -l` output:

```text
Last password change                                    : Aug 18, 2026
Password expires                                        : Nov 16, 2026
Password inactive                                       : Dec 16, 2026
Account expires                                         : never
Minimum number of days between password change           : 7
Maximum number of days between password change           : 90
Number of days of warning before password expires        : 14
```

### Password expiry versus account expiry

A distinction the exam tests.

| | Password expiry (`-M`) | Account expiry (`-E`) |
| --- | --- | --- |
| What happens | User is **forced to change** the password at login | Account is **disabled entirely** |
| Can the user recover? | Yes, by setting a new password | No, an administrator must extend it |
| Stored in | Field 5 (max age), computed against field 3 | Field 8 (absolute date) |
| Also set by | `usermod` has no equivalent | `usermod -e` |

### passwd

```bash
passwd                            # change your own
sudo passwd alice                 # change alice's
echo 'Pass123' | sudo passwd --stdin alice     # non-interactive (Red Hat)
echo 'alice:Pass123' | sudo chpasswd           # non-interactive (portable)

sudo passwd -l alice              # LOCK (prepends !!)
sudo passwd -u alice              # unlock
sudo passwd -S alice              # STATUS
sudo passwd -e alice              # EXPIRE now, force change at next login
sudo passwd -d alice              # DELETE the password — dangerous
sudo passwd -n 7 -x 90 -w 14 alice   # min, max, warn — same as chage
```

`passwd -S` output decoded:

```text
alice PS 2026-08-18 7 90 14 30
  │    │      │     │  │  │  │
  │    │      │     │  │  │  └─ inactive days
  │    │      │     │  │  └──── warning days
  │    │      │     │  └─────── max days
  │    │      │     └────────── min days
  │    │      └──────────────── last change
  │    └─────────────────────── PS = set, LK = locked, NP = no password
  └──────────────────────────── username
```

### System-wide defaults

New accounts inherit aging defaults from `/etc/login.defs`. Changing them affects **future** accounts only.

```bash
sudo grep -E '^PASS_' /etc/login.defs
```

```text
PASS_MAX_DAYS   99999      # effectively never expires
PASS_MIN_DAYS   0
PASS_WARN_AGE   7
```

```bash
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/'  /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs
```

**This does not change existing users.** If a task says "all users, including existing ones", you must also loop with `chage`. That is a favourite exam subtlety.

### Superuser access: sudo

Membership of the **`wheel`** group grants full sudo on RHEL, by way of this line in `/etc/sudoers`:

```text
%wheel  ALL=(ALL)       ALL
```

So the simplest answer to "give alice administrative access" is:

```bash
sudo usermod -aG wheel alice
```

Confirm the rule is actually present and not commented out:

```bash
sudo grep -E '^\s*%wheel' /etc/sudoers
```

### The sudoers line format

```text
alice   ALL=(ALL)       ALL
  │      │    │          │
  │      │    │          └─ commands allowed
  │      │    └──────────── users they may become  (ALL, or root, or alice)
  │      └───────────────── hosts this rule applies on  (ALL)
  └────────────────────────  who the rule is for  (%name = a group)
```

Common patterns:

```text
alice           ALL=(ALL)       ALL                    # full sudo, password required
%wheel          ALL=(ALL)       ALL                    # the whole wheel group
%wheel          ALL=(ALL)       NOPASSWD: ALL          # no password prompt
alice           ALL=(ALL)       NOPASSWD: /usr/bin/systemctl restart httpd
%devs           ALL=(ALL)       /usr/bin/dnf, /usr/bin/rpm
bob             ALL=(alice)     /bin/ls                # run ls AS alice
%ops            ALL=(ALL)       !/usr/bin/passwd root  # deny one command
```

Absolute paths are required for commands. `systemctl` will not match; `/usr/bin/systemctl` will.

### Never edit /etc/sudoers directly

```bash
sudo visudo                                  # edits /etc/sudoers WITH VALIDATION
sudo visudo -f /etc/sudoers.d/alice          # edit a drop-in with validation
sudo visudo -c                               # check syntax of everything
```

**A syntax error in `/etc/sudoers` breaks `sudo` for everyone, including you.** `visudo` validates before saving and refuses to install a broken file. There is no reason to use plain `vim` here.

If you do get locked out, the recovery is `pkexec` if available, or single-user mode via `16-boot-interrupt-root-recovery.md`.

### Prefer drop-in files

`/etc/sudoers` includes `/etc/sudoers.d/` at the end. Drop-ins are the modern, update-safe way.

```bash
echo 'alice ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/alice
sudo chmod 440 /etc/sudoers.d/alice
sudo visudo -c
```

**Mode `440` matters.** `sudo` ignores files in `/etc/sudoers.d/` that are group- or world-writable, silently. If your rule seems to have no effect, check the permissions first.

Also: files with a `.` or `~` in the name are ignored. Name it `alice`, not `alice.conf`.

```bash
ls -l /etc/sudoers.d/
```

### Testing sudo

```bash
sudo -l                            # what can I run
sudo -l -U alice                   # what can ALICE run
sudo -u alice command              # run as alice
sudo -v                            # refresh the credential timestamp
sudo -k                            # forget the cached credential
```

`sudo -l -U alice` is the correct way to verify a sudoers task without logging in as her.

### PolicyKit, briefly

Some graphical and systemd operations use PolicyKit rather than sudo. You are unlikely to be tested on writing rules, but recognise the tool:

```bash
pkexec command
```

## Exam Tips

- **`chage -M` maximum, `-m` minimum, `-W` warn, `-I` inactive, `-E` account expiry.** Case matters: `-m` and `-M` are different settings.
- **`chage -d 0 user`** forces a password change at next login. So does `passwd -e`.
- **`chage -l user`** is the readable view; `/etc/shadow` stores **days since 1970-01-01**.
- **Password expiry (`-M`) forces a change. Account expiry (`-E`) disables the account.** Different things.
- **`chage -E -1`** removes an account expiry.
- Account expiry dates are **`YYYY-MM-DD`**.
- **`/etc/login.defs` affects new users only.** For existing users, loop `chage` over `awk -F: '$3>=1000'`.
- **`passwd -S`**: `PS` set, `LK` locked, `NP` none. A locked hash starts with `!`.
- **A locked password still allows SSH key login.** Use `chage -E 0` or `nologin` to block everything.
- **`usermod -aG wheel user`** is the standard way to grant sudo on RHEL.
- **Never edit `/etc/sudoers` with vim. Use `visudo`**, and `visudo -c` to validate.
- **Sudoers drop-ins must be mode `0440`** and must have **no dot in the filename**, or they are silently ignored.
- **`%group`** in sudoers denotes a group. Commands need **absolute paths**.
- **`sudo -l -U user`** verifies another user's privileges without logging in as them.
- Group membership changes take effect at the **next login**.
- `echo 'pass' | sudo passwd --stdin user` on Red Hat; `echo 'user:pass' | sudo chpasswd` portably.
