# 10. Users And Groups

**Objectives:** Create, delete, and modify local user accounts. Create, delete, and modify local groups and group memberships. Log in and switch users in multiuser targets.

Near-certain exam content, and mercifully mechanical once you know the flags.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Creating users without setting passwords is the most common incomplete-task mistake on the exam. The follow-along makes that stick.

---

## Follow Along

Work on your lab VM as root or with `sudo`. After each step, compare your output to **You should see**.

### 1. The four account files

```bash
ls -l /etc/passwd /etc/shadow /etc/group /etc/gshadow
head -3 /etc/passwd
```

**You should see** `/etc/passwd` and `/etc/group` are world-readable (`644`). `/etc/shadow` and `/etc/gshadow` are mode `000` — root only.

Account definitions live in `passwd`; password hashes and aging live in `shadow`.

### 2. Read a passwd entry

```bash
getent passwd root
```

**You should see** seven colon-separated fields:

```text
root:x:0:0:root:/root:/bin/bash
  │   │  │  │   │     │      └─ login shell
  │   │  │  │   │     └──────── home directory
  │   │  │  │   └────────────── GECOS / comment
  │   │  │  └────────────────── primary GID
  │   │  └───────────────────── UID
  │   └──────────────────────── password placeholder ('x' = see shadow)
  └──────────────────────────── username
```

The `x` in field 2 means the hash is in `/etc/shadow`. An **empty** field 2 means no password is required — a security hole.

### 3. Primary versus secondary group membership

```bash
grep '^wheel:' /etc/group
id root
```

**You should see** field 4 of `/etc/group` lists **secondary** members only. A user whose *primary* group is `wheel` does **not** appear there. That is why `groups alice` and `grep devs /etc/group` can disagree.

### 4. UID ranges for regular users

```bash
grep -E '^(UID_MIN|UID_MAX|GID_MIN|GID_MAX|SYS_UID)' /etc/login.defs
awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3}' /etc/passwd | head
```

**You should see** regular users start at UID **1000**. UID 0 is root; 65534 is `nobody`. The exam constantly asks you to filter on `$3 >= 1000`.

### 5. Create a user with defaults

```bash
sudo useradd demo1
id demo1
sudo getent shadow demo1 | cut -d: -f2 | head -c 5
```

**You should see** a user private group with the same name and GID, and a home directory under `/home/demo1`. The shadow hash starts with `!!` — **locked, no password set**.

**`useradd` does not set a password.** The account cannot log in until you run `passwd`.

### 6. Lowercase `-g` versus uppercase `-G`

```bash
sudo groupadd labteam
sudo useradd -g labteam -G wheel demo2
id demo2
```

**You should see** `gid=...(labteam)` as the primary group and `wheel` in the groups list.

**`-g` is primary (lowercase). `-G` is secondary (uppercase).** Swapping them fails the task.

### 7. Append to groups — never replace by accident

```bash
sudo usermod -aG labteam demo2
id demo2
```

**You should see** demo2 still in `wheel` **and** now also in `labteam`.

Compare what `-G` alone would do:

```bash
# DO NOT run on a real exam account — this REPLACES all secondary groups:
# sudo usermod -G labteam demo2    # would REMOVE wheel silently
```

**Always use `-aG` to add.** Plain `-G` replaces the entire secondary list.

### 8. Set a password non-interactively

```bash
echo 'Redhat123' | sudo passwd --stdin demo1
sudo passwd -S demo1
```

**You should see** `PS` (password set), not `LK` (locked). On portable systems: `echo 'demo1:Redhat123' | sudo chpasswd`.

### 9. Delete a user — with and without home

```bash
sudo userdel demo2          # account gone, home may remain
sudo useradd -M -s /sbin/nologin demo3
sudo userdel -r demo3       # account AND home/mail spool removed
getent passwd demo2 demo3   # no output
```

**You should see** no entries for either user. **`-r` is what "delete user and home directory" means.**

Find orphaned files after careless deletes:

```bash
sudo find /home -nouser -o -nogroup 2>/dev/null
```

### 10. Group management

```bash
sudo groupadd -g 4000 auditors
sudo groupmod -n auditgrp auditors
getent group auditgrp
sudo groupdel auditgrp
```

**You should see** the group rename keeps the same GID — file ownership is unaffected. `groupdel` refuses if the group is anyone's primary group.

Add/remove members:

```bash
sudo groupadd devs
sudo usermod -aG devs demo1
sudo gpasswd -d demo1 devs      # clean one-member removal
```

### 11. Inspect accounts — prefer getent

```bash
id demo1
getent passwd demo1
getent group wheel
groups demo1
who
w
```

**You should see** `getent` works like grepping the files but also covers LDAP/SSSD sources. **`id`** is the right tool for membership questions, not `grep` on `/etc/group`.

### 12. Switch users — the dash matters

```bash
sudo su - demo1 -c 'pwd; echo $HOME; whoami'
sudo su demo1 -c 'pwd; echo $HOME'
```

**You should see** `su - demo1` lands in `/home/demo1` with demo1's environment. Without the dash, `$HOME` and the working directory stay yours.

Any task saying "log in as" or "switch to" means **`su - user`**.

### 13. Block interactive login

```bash
sudo useradd -s /sbin/nologin svcacct
getent passwd svcacct | cut -d: -f7
sudo su - svcacct
```

**You should see** shell `/sbin/nologin` and the message "This account is currently not available."

| Mechanism | Effect |
| --- | --- |
| `usermod -s /sbin/nologin` | No interactive shell; SSH keys and `su` also fail |
| `usermod -L` | Password disabled; **SSH key auth still works** |
| `chage -E 0` | Account expired; all access denied |

### 14. Seed new home directories with /etc/skel

```bash
grep SKEL /etc/default/useradd
ls -la /etc/skel/
echo 'Welcome to the system.' | sudo tee /etc/skel/README
sudo useradd skeltest
ls -la /home/skeltest/README
sudo userdel -r skeltest
```

**You should see** `/etc/skel` copied into every new home directory. Existing users are not affected — copy files to them manually.

### Mini checkpoint

Before the practice tasks, you should be able to explain:

| Flag / command | Does |
| --- | --- |
| `-g` | primary group |
| `-G` | secondary groups |
| `-aG` | append to secondary groups |
| `-M` | no home directory |
| `-r` (userdel) | remove home and mail spool |
| `su - user` | full login environment |
| `getent` | query all name sources |

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Create the group `sysadmin` with GID `3000`.

> Hint: `groupadd -g`.

**Task 2.** Create the user `natasha` with UID `1500`, a comment of `Natasha R`, primary group `sysadmin`, and the bash shell.

> Hint: `-u`, `-c`, `-g` (lowercase), `-s`. Create the group first.

**Task 3.** Create the user `harry` as a member of the secondary group `sysadmin` without changing his primary group.

> Hint: uppercase `-G` for secondary; primary stays the user private group.

**Task 4.** Create the user `sarah` who cannot log in interactively and has no home directory.

> Hint: `-M` and `-s /sbin/nologin`.

**Task 5.** Add existing user `harry` to the additional group `wheel` without removing him from any group he is already in.

> Hint: `usermod -aG`, never plain `-G`.

**Task 6.** Show every group `harry` belongs to, and identify which is his primary group.

> Hint: `id`, `id -gn`, `id -Gn`.

**Task 7.** Set a password of `Redhat123` for `natasha` non-interactively.

> Hint: `passwd --stdin` on Red Hat, or `chpasswd`.

**Task 8.** Rename the group `sysadmin` to `admins`, then confirm existing members are still in it.

> Hint: `groupmod -n`; GID unchanged so membership persists.

**Task 9.** Remove `harry` from the group `admins` without touching his other memberships.

> Hint: `gpasswd -d` is cleaner than restating the whole list with `usermod -G`.

**Task 10.** Create the user `contractor` whose account expires on 31 December 2026.

> Hint: `useradd -e` with `YYYY-MM-DD`, or `chage -E`.

**Task 11.** Lock `natasha`'s account so she cannot authenticate with a password, then verify from `/etc/shadow` that it is locked, then unlock it.

> Hint: `usermod -L` / `-U`; locked hash starts with `!`; `passwd -S` shows `LK`.

**Task 12.** Delete the user `sarah` completely, including her home directory if one exists.

> Hint: `userdel -r`.

**Task 13.** List all regular user accounts on the system, that is those with UID 1000 or above, showing username and UID only.

> Hint: `awk -F: '$3 >= 1000'` on `/etc/passwd` or `getent passwd`.

**Task 14.** Switch to user `natasha` with a full login environment and confirm her home directory and identity, then return.

> Hint: `su - natasha`; compare `pwd` and `$HOME` with and without the dash.

**Task 15.** Find any files on the system owned by a UID that no longer maps to a user.

> Hint: `find / -nouser -o -nogroup`.

**Task 16.** Configure the system so every newly created user automatically receives a file called `README` in their home directory.

> Hint: place the file in `/etc/skel`; verify with a test user.

---

## Solutions

**Task 1.**

```bash
sudo groupadd -g 3000 sysadmin
getent group sysadmin
```

Output: `sysadmin:x:3000:` — note the empty fourth field; no secondary members yet.

**Task 2.**

```bash
sudo useradd -u 1500 -c "Natasha R" -g sysadmin -s /bin/bash natasha
id natasha
getent passwd natasha
```

Verify:

```text
uid=1500(natasha) gid=3000(sysadmin) groups=3000(sysadmin)
```

`-g` sets the **primary** group and it must already exist, which is why Task 1 comes first. Because `-g` was given, no user private group named `natasha` is created.

Remember: **she still has no password**, so she cannot log in. See Task 7.

**Task 3.**

```bash
sudo useradd -G sysadmin harry
id harry
```

```text
uid=1501(harry) gid=1501(harry) groups=1501(harry),3000(sysadmin)
```

`-G` (uppercase) sets **secondary** groups. His primary group is his own user private group `harry`, which is the RHEL default. Compare with Task 2, where `-g` (lowercase) overrode the primary group.

**Lowercase `-g` is primary, uppercase `-G` is secondary.** Get this the wrong way round and the task fails.

**Task 4.**

```bash
sudo useradd -M -s /sbin/nologin sarah
getent passwd sarah
ls /home/                     # no sarah directory
```

`-M` suppresses home directory creation, `-s /sbin/nologin` prevents interactive login. Confirm:

```bash
su - sarah                    # "This account is currently not available."
```

**Task 5.**

```bash
sudo usermod -aG wheel harry
id harry
```

**`-aG`, not `-G`.** With plain `-G wheel`, harry would be removed from `sysadmin`. Verify he kept both:

```text
groups=1501(harry),10(wheel),3000(sysadmin)
```

Membership of `wheel` grants sudo on RHEL by default. See `11-password-aging-sudo.md`.

**Task 6.**

```bash
id harry
groups harry
id -gn harry          # PRIMARY group name only
id -Gn harry          # all group names
```

`id -gn` isolates the primary group, which is the precise answer to "which is his primary group". Reading it from `id` output: the primary is the one after `gid=`.

Note that `grep sysadmin /etc/group` shows harry (a secondary member) but **would not** show natasha, whose membership is primary. Use `id`, not the group file, to answer membership questions.

**Task 7.**

```bash
echo 'Redhat123' | sudo passwd --stdin natasha
```

`--stdin` is a Red Hat extension and works on RHEL and its rebuilds. The portable alternative:

```bash
echo 'natasha:Redhat123' | sudo chpasswd
```

Verify a hash now exists:

```bash
sudo getent shadow natasha | cut -d: -f2 | head -c 20
```

Interactively it is simply:

```bash
sudo passwd natasha
```

On the exam, interactive `passwd` is perfectly fine and often faster than remembering `--stdin`.

**Task 8.**

```bash
sudo groupmod -n admins sysadmin
getent group admins
id harry
```

The GID is unchanged, so **file ownership is unaffected** — files owned by GID 3000 now simply display the new name. Members are retained because membership is stored by GID.

Note that natasha's primary group is still GID 3000, now called `admins`:

```bash
id natasha
```

**Task 9.**

```bash
sudo gpasswd -d harry admins
id harry
```

`gpasswd -d` removes one member cleanly. The `usermod` route requires restating the full remaining list:

```bash
sudo usermod -G wheel harry        # risky: you must remember every other group
```

Prefer `gpasswd -d` for removals.

**Task 10.**

```bash
sudo useradd -e 2026-12-31 contractor
sudo chage -l contractor | grep -i expire
```

Output includes `Account expires : Dec 31, 2026`.

The date format is **`YYYY-MM-DD`**. To change it later, or to remove the expiry:

```bash
sudo usermod -e 2027-06-30 contractor
sudo usermod -e '' contractor          # remove the expiry
sudo chage -E -1 contractor            # also removes it
```

**Do not confuse account expiry with password expiry.** `-e` / `chage -E` expires the **account**; `chage -M` expires the **password**. See `11-password-aging-sudo.md`.

**Task 11.**

```bash
sudo usermod -L natasha
sudo getent shadow natasha | cut -d: -f2 | head -c 5
```

A locked password has a **`!`** prepended to the hash. `passwd -l` uses `!!`; both mean locked.

```bash
sudo passwd -S natasha
# natasha LK 2026-08-18 0 99999 7 -1   <- LK = locked
```

Unlock:

```bash
sudo usermod -U natasha
sudo passwd -S natasha          # PS = password set
```

`passwd -S` status codes: **`PS`** password set, **`LK`** locked, **`NP`** no password.

Remember: locking the password does **not** block SSH key authentication. To block all access, expire the account with `chage -E 0` or set the shell to `nologin`.

**Task 12.**

```bash
sudo userdel -r sarah
getent passwd sarah          # no output
ls /home/                    # no sarah
```

`userdel -r` also removes the mail spool at `/var/spool/mail/sarah`. Since sarah was created with `-M`, there is no home directory to remove and `userdel -r` warns about that; the warning is harmless.

**Task 13.**

```bash
awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3}' /etc/passwd
```

Or using `getent`, which also covers non-local sources:

```bash
getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3}'
```

Or the purpose-built tool:

```bash
lslogins -u
```

The `< 65534` bound excludes `nobody`. **UID 1000 is where regular accounts begin** — that is the number to remember.

**Task 14.**

```bash
sudo su - natasha
pwd            # /home/natasha
id             # uid=1500(natasha) ...
whoami
echo $HOME
exit
```

**The dash matters.** Compare:

```bash
sudo su natasha    ; pwd    # still your old directory, your old PATH
sudo su - natasha  ; pwd    # /home/natasha, natasha's full environment
```

Any task phrased as "log in as" or "switch to" means a login shell, so use `su -`.

**Task 15.**

```bash
sudo find / -nouser -o -nogroup 2>/dev/null
```

`-nouser` finds files whose UID has no matching account; `-nogroup` the same for GIDs. These appear after `userdel` without `-r`.

To clean up:

```bash
sudo find /home -nouser -exec ls -ld {} +      # inspect first
sudo find /home -nouser -delete                # or reassign with chown
```

**Task 16.**

```bash
sudo tee /etc/skel/README <<'EOF'
Welcome. Contact the administrator with any questions.
EOF
sudo chmod 644 /etc/skel/README
```

Verify by creating a test user:

```bash
sudo useradd testuser
sudo ls -la /home/testuser/
sudo userdel -r testuser
```

**`/etc/skel` is copied into every new home directory** by `useradd`. It does not affect existing users — for those you would copy the file manually. The skeleton location is configurable in `/etc/default/useradd`:

```bash
grep SKEL /etc/default/useradd
```

---

## Verify

```bash
getent passwd natasha harry contractor
getent group admins wheel
id natasha; id harry
sudo chage -l contractor | head -6
sudo passwd -S natasha
awk -F: '$3>=1000 && $3<65534 {print $1, $3}' /etc/passwd
ls -la /etc/skel/
```

## Persistence Check

Everything in this file writes directly to `/etc/passwd`, `/etc/shadow`, `/etc/group`, or `/etc/gshadow`, so it all persists automatically. There is no service to enable and nothing to make permanent.

Two things that can still catch you:

1. **A home directory on a non-persistent filesystem.** If `/home` is a mount you created and did not add to `/etc/fstab`, the users exist after a reboot but their home directories do not. See `30-filesystems-fstab.md`.
2. **A password you never set.** `useradd` alone leaves the account unusable. If the task says the user must be able to log in, you must run `passwd`.

Post-reboot verification:

```bash
getent passwd natasha
id natasha
sudo passwd -S natasha        # PS, not LK
su - natasha -c pwd           # home directory reachable
findmnt /home                 # if /home is a separate filesystem
```

## Quick Reference

Come back here when you need a flag you forgot — not before your first pass through Follow Along.

### The four files

| File | Holds | Permissions |
| --- | --- | --- |
| **`/etc/passwd`** | Account definitions | `644`, world-readable |
| **`/etc/shadow`** | Password hashes and aging | **`000`** — root-only |
| **`/etc/group`** | Group definitions and secondary members | `644` |
| `/etc/gshadow` | Group passwords, rarely used | `000` |

### /etc/passwd format

```text
alice:x:1001:1001:Alice Smith:/home/alice:/bin/bash
  │   │  │    │        │           │          │
  │   │  │    │        │           │          └─ 7. login shell
  │   │  │    │        │           └──────────── 6. home directory
  │   │  │    │        └──────────────────────── 5. GECOS / comment
  │   │  │    └───────────────────────────────── 4. primary GID
  │   │  └────────────────────────────────────── 3. UID
  │   └───────────────────────────────────────── 2. password placeholder ('x' = see /etc/shadow)
  └───────────────────────────────────────────── 1. username
```

Seven fields. The `x` in field 2 means "the hash lives in `/etc/shadow`". A **completely empty** field 2 means no password is required at all, which is a security hole worth recognising.

### /etc/group format

```text
devs:x:1005:alice,bob,carol
  │  │  │        │
  │  │  │        └─ 4. SECONDARY members, comma-separated
  │  │  └────────── 3. GID
  │  └───────────── 2. password placeholder
  └──────────────── 1. group name
```

**Field 4 lists only secondary members.** A user whose *primary* group is `devs` does **not** appear here. This is why `groups alice` and `grep devs /etc/group` can disagree, and it is a genuine source of confusion.

### UID and GID ranges

| Range | Purpose |
| --- | --- |
| **0** | root |
| 1-200 | Static system accounts assigned by Red Hat |
| 201-999 | Dynamic system accounts (daemons) |
| **1000-60000** | **Regular user accounts** |
| 65534 | `nobody` |

Defined in `/etc/login.defs`:

```bash
grep -E '^(UID_MIN|UID_MAX|GID_MIN|GID_MAX|SYS_UID)' /etc/login.defs
```

**Regular users start at 1000.** That fact is used constantly, for example `awk -F: '$3>=1000' /etc/passwd`.

### User private groups

RHEL creates a group with the same name and GID as each new user, and makes it that user's primary group. This is why a regular user's default umask can safely be `002`: group-write only affects a group containing just that one user.

```bash
useradd alice
id alice
# uid=1001(alice) gid=1001(alice) groups=1001(alice)
```

### useradd

```bash
useradd alice                          # all defaults
useradd -u 1500 alice                  # specific UID
useradd -g devs alice                  # PRIMARY group (must already exist)
useradd -G devs,ops alice              # SECONDARY groups
useradd -c "Alice Smith" alice         # GECOS comment
useradd -d /opt/alice alice            # custom home directory
useradd -s /bin/bash alice             # login shell
useradd -s /sbin/nologin svcacct       # NO interactive login
useradd -M alice                       # do NOT create a home directory
useradd -m alice                       # create it (default on RHEL anyway)
useradd -r svcacct                     # SYSTEM account: UID below 1000, no aging
useradd -e 2026-12-31 contractor       # account expiry date
useradd -f 30 alice                    # inactive days after password expiry
useradd -N alice                       # do not create a user private group

# A realistic combination
useradd -u 1500 -g devs -G ops,wheel -c "Alice Smith" -s /bin/bash alice
```

**`useradd` does not set a password.** The account is created with a locked password (`!!` in `/etc/shadow`), so the user cannot log in until you run `passwd`. Forgetting this is the most common incomplete-task error.

Defaults come from:

```bash
cat /etc/default/useradd        # shell, skel, home base, inactive, expire
grep -v '^#' /etc/login.defs | grep -v '^$'
useradd -D                      # show the defaults
useradd -D -s /bin/bash         # CHANGE a default
```

### usermod

```bash
usermod -c "New Name" alice
usermod -u 1600 alice                  # change UID
usermod -g newprimary alice            # change PRIMARY group
usermod -aG devs alice                 # APPEND to secondary groups
usermod -G devs,ops alice              # REPLACE all secondary groups
usermod -s /sbin/nologin alice         # change shell
usermod -d /opt/alice alice            # change home dir (does not move files)
usermod -d /opt/alice -m alice         # change AND MOVE the files
usermod -l newname oldname             # rename the login
usermod -L alice                       # LOCK the password
usermod -U alice                       # UNLOCK
usermod -e 2026-12-31 alice            # expiry date
usermod -e '' alice                    # remove expiry
```

**`-aG` versus `-G` is the single most important distinction in this file.**

```bash
usermod -aG devs alice       # ADDS devs, keeps existing groups
usermod -G devs alice        # REPLACES all secondary groups with just devs
```

Running `usermod -G devs alice` when alice was already in `wheel` **silently removes her from `wheel`**, which can break sudo access. Always use `-aG` unless you specifically intend to replace the whole list.

### userdel

```bash
userdel alice              # remove the account, LEAVE the home directory
userdel -r alice           # remove the account AND home directory and mail spool
userdel -f alice           # force, even if logged in
```

**`-r` is what "delete the user and their home directory" means.** Without it, `/home/alice` remains and its files become owned by an orphaned UID.

After deleting users, orphaned files are worth finding:

```bash
sudo find / -nouser -o -nogroup 2>/dev/null
```

### Groups

```bash
groupadd devs
groupadd -g 2000 devs              # specific GID
groupadd -r sysgroup               # system group, GID below 1000

groupmod -n newname oldname        # RENAME
groupmod -g 2500 devs              # change GID

groupdel devs                      # delete
```

`groupdel` refuses to remove a group that is any user's **primary** group. Change that user's primary group first, or delete the user.

Managing membership:

```bash
usermod -aG devs alice             # the usual way
gpasswd -a alice devs              # add a member
gpasswd -d alice devs              # REMOVE a member
gpasswd -M alice,bob,carol devs    # set the member list exactly
gpasswd -A alice devs              # make alice a group administrator
```

`gpasswd -d` is the clean way to remove one member. Doing it with `usermod -G` means retyping the whole list correctly, which is error-prone.

### Inspecting

```bash
id                                 # yourself
id alice                           # uid, gid, all groups
id -u alice                        # UID only
id -g alice                        # primary GID only
id -G alice                        # all GIDs
id -nG alice                       # all group NAMES

groups alice                       # group names
getent passwd alice                # the passwd entry (works with LDAP too)
getent group devs
getent passwd | wc -l              # every account, all sources
lslogins                           # a nice summary table
lslogins -u                        # only user accounts

who                                # who is logged in now
w                                  # who, plus what they are doing
last                               # login history
lastlog                            # last login per account
lastb                              # failed login attempts
```

**Prefer `getent` over `grep` on `/etc/passwd`.** `getent` consults every configured name source, so it works identically on a system using LDAP or SSSD. On the exam either works, but `getent` is the better habit.

### Switching users

```bash
su alice                # switch user, KEEP the current environment and cwd
su - alice              # LOGIN shell: full environment, cd to home. PREFERRED
su -l alice             # same as su -
su -                    # become root with a login shell
su - alice -c 'whoami'  # run one command as alice

sudo -u alice command    # run one command as alice
sudo -i                  # root login shell
sudo -s                  # root shell, current environment
sudo -l                  # what am I allowed to run
```

**`su - alice` versus `su alice` matters.** Without the dash you keep your own `PATH`, `HOME`, and working directory, so scripts behave oddly and `~` points at the wrong place. Always use the dash.

### Shells and nologin

```bash
cat /etc/shells                    # valid login shells
usermod -s /sbin/nologin svcacct   # prevent interactive login
usermod -s /bin/bash alice         # allow it
chsh -s /bin/bash alice
```

`/sbin/nologin` prints a message and exits. Service accounts should have it. If a task says "create an account that cannot log in interactively", this is the answer — not a locked password, which is a different thing.

| Mechanism | Effect |
| --- | --- |
| `usermod -s /sbin/nologin` | No interactive shell. SSH keys and `su` also fail |
| `usermod -L` | Password disabled (`!` prefix). **SSH key auth still works** |
| `chage -E 0` | Account expired. All access denied |
| `passwd -d` | Password **removed** — dangerous, allows empty-password login |

The distinction between `-L` and `nologin` is examinable: locking the password does **not** stop key-based SSH login.

## Exam Tips

- **`-g` is the primary group (lowercase, singular). `-G` is secondary groups (uppercase).**
- **`usermod -aG` appends. `usermod -G` replaces.** Omitting `-a` silently removes existing memberships, including `wheel`.
- **`useradd` does not set a password.** Run `passwd` afterwards, or the account is locked.
- **`userdel -r`** to remove the home directory and mail spool. Without `-r` you leave orphaned files.
- **Regular UIDs start at 1000.** System accounts are below it; `nobody` is 65534.
- **`/etc/group` field 4 lists secondary members only.** Use `id`, not `grep`, to answer membership questions.
- **`getent passwd` / `getent group`** rather than grepping the files.
- **`su - user`, with the dash**, for a full login environment. `su user` keeps your own environment.
- **`passwd -S user`**: `PS` set, `LK` locked, `NP` none. A locked hash starts with `!`.
- **`usermod -L` blocks password auth but NOT SSH keys.** Use `nologin` or `chage -E 0` to block everything.
- **`/sbin/nologin`** for service accounts that must not log in.
- **`-M`** suppresses home directory creation; **`-m`** forces it.
- **`useradd -r`** for a system account (UID below 1000, no aging).
- **`gpasswd -d user group`** to remove one member without restating the list.
- **`groupmod -n new old`** renames without changing the GID, so file ownership is unaffected.
- **`/etc/skel`** seeds new home directories. **`/etc/default/useradd`** and **`/etc/login.defs`** hold the defaults.
- Account expiry dates use **`YYYY-MM-DD`**.
- **`find / -nouser -o -nogroup`** finds orphaned files after a careless `userdel`.
