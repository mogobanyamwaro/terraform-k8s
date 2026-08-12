# Users And Groups Deep Dive

Account creation, password aging, sudo, and the files behind them. This is one of the more mechanical domains — the commands are short and the marks are easy, provided you use the right flag. Step-by-step tasks are in `10-users-groups.md` and `11-password-aging-sudo.md`.

---

## The files

| File | Mode | Contents |
| --- | --- | --- |
| `/etc/passwd` | **644** | Account records, world-readable |
| **`/etc/shadow`** | **000** | **Password hashes and aging** |
| `/etc/group` | 644 | Groups and their secondary members |
| `/etc/gshadow` | 000 | Group passwords and administrators |
| `/etc/login.defs` | 644 | Defaults for **new** accounts |
| `/etc/default/useradd` | 644 | More `useradd` defaults |
| `/etc/skel/` | — | **Copied into every new home directory** |
| `/etc/sudoers`, `/etc/sudoers.d/` | 440 | sudo policy |

```bash
ls -l /etc/passwd /etc/shadow /etc/group /etc/gshadow
```

**`/etc/shadow` is mode 000 and root still reads it, because root ignores DAC.** That is why `passwd` needs to be SUID for ordinary users.

### `/etc/passwd`

```text
alice:x:1500:1500:Alice Anderson:/home/alice:/bin/bash
  │   │  │    │         │            │           │
  │   │  │    │         │            │           └─ 7. shell
  │   │  │    │         │            └─ 6. home directory
  │   │  │    │         └─ 5. GECOS / comment
  │   │  │    └─ 4. primary GID
  │   │  └─ 3. UID
  │   └─ 2. 'x' — the hash lives in /etc/shadow
  └─ 1. username
```

| Field | Notes |
| --- | --- |
| 1 username | |
| 2 password | **Always `x`** on a modern system |
| 3 UID | **0 root; 1-999 system; 1000+ regular** |
| 4 GID | The primary group |
| 5 GECOS | Comment, set by `useradd -c` |
| 6 home | |
| 7 shell | **`/sbin/nologin` denies interactive login** |

**A second account with UID 0 is a root equivalent.** If you ever see one in a troubleshooting task, that is the finding:

```bash
awk -F: '$3==0 {print $1}' /etc/passwd
```

### `/etc/shadow`

```text
alice:$6$xyz...:20318:7:60:7:14:20500:
  │       │       │   │  │ │  │   │  │
  │       │       │   │  │ │  │   │  └─ 9. reserved
  │       │       │   │  │ │  │   └─ 8. account expiry date (days since epoch)
  │       │       │   │  │ │  └─ 7. inactive days after password expiry
  │       │       │   │  │ └─ 6. warning days
  │       │       │   │  └─ 5. maximum password age
  │       │       │   └─ 4. minimum days between changes
  │       │       └─ 3. date of last change (days since epoch)
  │       └─ 2. hash: $6$ = SHA-512, $y$ = yescrypt (RHEL 9+)
  └─ 1. username
```

| Field 2 value | Meaning |
| --- | --- |
| `$6$...` | SHA-512 hash |
| `$y$...` | yescrypt, the RHEL 9+ default |
| **`!`** or **`!!`** | **Locked** |
| **`*`** | **No password; cannot log in with one** |
| Empty | **No password required — a serious problem** |

```bash
sudo grep alice /etc/shadow
sudo passwd -S alice
awk -F: '$2==""{print $1" HAS NO PASSWORD"}' /etc/shadow      # as root
```

```text
alice PS 2026-08-18 7 60 7 14
```

**`!` prefixed to an existing hash is how `usermod -L` locks an account — the hash is preserved and unlocking restores it.**

### `/etc/group`

```text
devs:x:5000:alice,bob
  │  │  │      │
  │  │  │      └─ SECONDARY members only
  │  │  └─ GID
  │  └─ 'x'
  └─ group name
```

**A user's primary group membership is not listed here.** It is field 4 of their `/etc/passwd` line. So a user can be in a group without appearing in `/etc/group`:

```bash
grep devs /etc/group                  # may not list alice
id alice                              # does
groups alice
getent group devs
```

**Always verify membership with `id`, never by reading `/etc/group`.**

---

## Creating accounts

```bash
sudo useradd alice
sudo useradd -u 1500 -g devs -G wheel,ops -c "Alice Anderson" \
  -s /bin/bash -m -d /home/alice alice
```

| Flag | Meaning |
| --- | --- |
| `-u 1500` | UID |
| **`-g devs`** | **Primary group — must already exist** |
| **`-G wheel,ops`** | **Secondary groups, comma separated, no spaces** |
| `-c "text"` | Comment / full name |
| `-s /bin/bash` | Shell |
| `-m` / `-M` | Create / do not create the home directory |
| `-d /path` | Home directory location |
| `-r` | System account: UID below 1000, no home by default, no aging |
| `-e 2026-12-31` | Account expiry date |
| `-f 14` | Inactive days after password expiry |
| `-N` | Do not create a user private group |
| `-k /etc/skel` | Skeleton directory |

**`-g` versus `-G` is the distinction that matters: lowercase is the single primary group, uppercase is the list of secondary groups.**

```bash
sudo useradd alice
id alice
```

```text
uid=1500(alice) gid=1500(alice) groups=1500(alice)
```

**By default RHEL creates a user private group with the same name and GID.** That is what makes `umask 002` safe for ordinary users.

**A service account:**

```bash
sudo useradd -r -M -s /sbin/nologin -c "Application service account" appsvc
id appsvc
grep appsvc /etc/passwd
```

```text
appsvc:x:988:988:Application service account:/home/appsvc:/sbin/nologin
```

**`-r` gives a UID from the system range and no password aging. `-s /sbin/nologin` denies interactive login. `-M` skips the home directory.**

### `/etc/skel`

```bash
ls -la /etc/skel/
sudo cp /etc/skel/.bashrc /etc/skel/.bash_profile /tmp/  # inspect
echo "Welcome" | sudo tee /etc/skel/README
sudo useradd -m newuser
ls -la /home/newuser/          # README is there
```

**`/etc/skel` is copied at creation time only.** Adding a file to it does not affect existing users — a task asking for a file in every home directory needs a loop.

### Defaults

```bash
sudo useradd -D                       # show /etc/default/useradd
sudo useradd -D -s /bin/bash          # change a default
grep -vE '^#|^$' /etc/login.defs
```

```text
UID_MIN                  1000
UID_MAX                 60000
SYS_UID_MIN               201
PASS_MAX_DAYS           99999
PASS_MIN_DAYS               0
PASS_WARN_AGE               7
CREATE_HOME               yes
UMASK                     022
ENCRYPT_METHOD         SHA512
```

**`/etc/login.defs` affects new accounts only.** A task saying "all future users must have a 60-day maximum password age" is `PASS_MAX_DAYS 60` in this file. A task saying "all users" needs both the file and a loop over existing accounts.

---

## Modifying accounts

```bash
sudo usermod -aG wheel alice          # APPEND to secondary groups
sudo usermod -G wheel alice           # REPLACE all secondary groups
sudo usermod -g newprimary alice
sudo usermod -c "New Name" alice
sudo usermod -s /sbin/nologin alice
sudo usermod -l newname oldname       # rename the account only
sudo usermod -u 2000 alice
sudo usermod -d /new/home -m alice    # -m MOVES the contents
sudo usermod -L alice                 # lock
sudo usermod -U alice                 # unlock
sudo usermod -e 2026-12-31 alice      # account expiry
sudo usermod -f 14 alice
```

### `-aG` versus `-G`

```bash
id alice                              # groups=1500(alice),10(wheel),5001(ops)
sudo usermod -G devs alice
id alice                              # groups=1500(alice),5000(devs)
```

**`ops` and `wheel` are gone. Alice has lost sudo access, silently, with no error message.**

```bash
sudo usermod -aG devs alice           # the correct form
id alice
```

**Make `id USER` the command you run immediately after any `usermod`.** It is the only way to catch this.

### Locking, three ways

| Command | Effect | Reversal |
| --- | --- | --- |
| **`usermod -L`** / `passwd -l` | **`!` prefixed to the hash. Password login blocked, SSH keys still work** | `usermod -U` / `passwd -u` |
| **`usermod -s /sbin/nologin`** | **No shell at all. Blocks SSH keys too** | Set a real shell |
| `usermod -e 1` | Account expired | `usermod -e ""` |
| `chage -E 0` | Account expired | `chage -E -1` |

**"Lock the account so the user cannot log in at all" needs more than `usermod -L`**, because key-based SSH still works with a locked password. Combine:

```bash
sudo usermod -L alice
sudo usermod -s /sbin/nologin alice
sudo passwd -S alice
```

```text
alice L 2026-08-18 0 99999 7 -1
      └─ L = locked (P = usable password, NP = no password)
```

### Renaming

```bash
sudo usermod -l bob alice             # the LOGIN NAME only
```

**`-l` changes nothing else.** The home directory is still `/home/alice`, the group is still `alice`, and any files still show the new name only because the UID is unchanged. A full rename is four commands:

```bash
sudo usermod -l bob -d /home/bob -m alice
sudo groupmod -n bob alice
id bob
ls -ld /home/bob
```

### Deleting

```bash
sudo userdel alice                    # leaves /home/alice behind
sudo userdel -r alice                 # removes the home directory and mail spool
sudo userdel -f alice                 # force, even if logged in
```

**`userdel` without `-r` leaves an orphaned directory with a numeric owner:**

```bash
ls -l /home/
sudo find / -nouser -o -nogroup 2>/dev/null
```

```text
drwx------. 3 1500 1500 78 Aug 18 /home/alice
```

**`find / -nouser` is how a task asks you to find these.** And a task saying "remove the user and all their files" means `-r`.

---

## Groups

```bash
sudo groupadd devs
sudo groupadd -g 5000 devs
sudo groupadd -r sysgroup             # system GID range
sudo groupmod -n newname oldname
sudo groupmod -g 5001 devs
sudo groupdel devs
sudo gpasswd -a alice devs            # add a member
sudo gpasswd -d alice devs            # remove a member
sudo gpasswd -A alice devs            # make alice a group administrator
sudo gpasswd -M alice,bob devs        # SET the member list
getent group devs
groups alice
id -nG alice
```

**`gpasswd -a` and `usermod -aG` do the same thing for secondary membership.** `gpasswd` is group-centric, `usermod` is user-centric; use whichever suits the task's wording.

**`groupdel` refuses to remove a group that is somebody's primary group:**

```bash
sudo groupdel alice
```

```text
groupdel: cannot remove the primary group of user 'alice'
```

**Change their primary group first, or delete the user.**

### Which groups matter

| Group | Grants |
| --- | --- |
| **`wheel`** | **sudo access, via the default `/etc/sudoers` rule** |
| `root` | Rarely used for access |
| `adm` | Read access to some logs |
| `systemd-journal` | Read the full journal |
| `docker`, `libvirt` | Effective root, where present |

```bash
grep -E '^%wheel' /etc/sudoers
```

```text
%wheel  ALL=(ALL)       ALL
```

**So `usermod -aG wheel alice` is the fastest way to give a user full sudo access**, and a task saying "alice must be able to run any command as root" is satisfied by it.

---

## Passwords and aging

```bash
sudo passwd alice
echo 'RedHat123' | sudo passwd --stdin alice     # non-interactive
sudo passwd -l alice ; sudo passwd -u alice
sudo passwd -e alice                             # expire now
sudo passwd -S alice
sudo passwd -d alice                             # DELETE the password — dangerous
sudo passwd -n 7 -x 60 -w 7 -i 14 alice          # aging, same as chage
```

**`--stdin` is a Red Hat extension and works on RHEL.** The portable alternative:

```bash
echo 'alice:RedHat123' | sudo chpasswd
```

### chage

```bash
sudo chage -l alice
```

```text
Last password change                                    : Aug 18, 2026
Password expires                                        : Oct 17, 2026
Password inactive                                       : Oct 31, 2026
Account expires                                         : never
Minimum number of days between password change          : 7
Maximum number of days between password change          : 60
Number of days of warning before password expires       : 7
```

```bash
sudo chage -m 7 alice                 # minimum days between changes
sudo chage -M 60 alice                # maximum password age
sudo chage -W 7 alice                 # warning days
sudo chage -I 14 alice                # inactive days AFTER expiry
sudo chage -E 2026-12-31 alice        # ACCOUNT expiry date
sudo chage -d 0 alice                 # must change at next login
sudo chage -E -1 alice                # account never expires
sudo chage -M -1 alice                # password never expires
sudo chage -m 7 -M 60 -W 7 -I 14 -E 2026-12-31 alice
```

| Flag | Field | Meaning |
| --- | --- | --- |
| `-m` | 4 | **Minimum** days before another change is allowed |
| `-M` | 5 | **Maximum** password age |
| `-W` | 6 | **Warning** days before expiry |
| `-I` | 7 | **Inactive** days after expiry before the account locks |
| `-E` | 8 | **Account** expiry date |
| `-d` | 3 | Last change date; **`-d 0` forces a change at next login** |

**Two pairs that get confused:**

**Password expiry (`-M`) versus account expiry (`-E`).** Password expiry forces a change; account expiry disables the account entirely.

**`-M` versus `-I`.** After `-M` days the password must change; the user is prompted at login. After a further `-I` days without changing it, the account becomes unusable.

```bash
sudo chage -d 0 alice
sudo chage -l alice
```

```text
Last password change            : password must be changed
Password expires                : password must be changed
```

**`chage -d 0` is the answer to "the user must change their password at first login".**

### For every existing user

```bash
for u in $(awk -F: '$3>=1000 && $3<60000 {print $1}' /etc/passwd); do
  sudo chage -M 60 -W 7 "$u"
done

for u in $(awk -F: '$3>=1000 && $3<60000 {print $1}' /etc/passwd); do
  printf '%-12s ' "$u"; sudo chage -l "$u" | grep -i 'Maximum'
done
```

**The UID filter excludes system accounts and `nobody` (65534).**

### Password quality

```bash
grep -vE '^#|^$' /etc/security/pwquality.conf
sudo authselect current
```

```text
minlen = 8
dcredit = -1
```

**Not an EX200 objective, but it explains "Password is too short" when you try to set a weak password.** `echo x | sudo passwd --stdin` bypasses the check because root is setting it.

---

## sudo

### Editing safely

```bash
sudo visudo                           # /etc/sudoers, syntax-checked on save
sudo visudo -f /etc/sudoers.d/devs    # a drop-in — the better habit
sudo visudo -c                        # verify every file
```

**Never `vim /etc/sudoers`.** A syntax error disables all sudo access, and if root login is also disabled the only recovery is a boot interruption. `visudo` refuses to save a broken file and offers to re-edit.

```text
>>> /etc/sudoers: syntax error near line 110 <<<
What now?
```

**Drop-in files are better than editing the main file** — they are self-contained, easy to remove, and cannot corrupt the base policy. `/etc/sudoers` includes them:

```bash
grep includedir /etc/sudoers
```

```text
@includedir /etc/sudoers.d
```

**Files in `/etc/sudoers.d/` must not contain a `.` or end in `~`**, or they are ignored:

```bash
sudo ls -l /etc/sudoers.d/
```

### Rule syntax

```text
who    where=(as_whom)    what

alice  ALL=(ALL)          ALL
%devs  ALL=(ALL)          ALL
%ops   ALL=(ALL)          NOPASSWD: ALL
alice  ALL=(root)         /usr/bin/systemctl restart httpd
bob    ALL=(ALL)          /usr/bin/dnf, /usr/bin/rpm
carol  ALL=(ALL)          ALL, !/usr/bin/passwd root
```

| Element | Meaning |
| --- | --- |
| `alice` | A user |
| **`%devs`** | **A group — the percent sign is required** |
| `ALL=` | On which hosts |
| `(ALL)` | Which identities may be assumed |
| `(root)` | Only root |
| `ALL` (last field) | Any command |
| **`NOPASSWD:`** | **No password prompt** |
| `!command` | Explicitly deny |

**Common tasks and their answers:**

```bash
# Full sudo for a group
echo '%devs   ALL=(ALL)       ALL' | sudo tee /etc/sudoers.d/devs
sudo visudo -c -f /etc/sudoers.d/devs

# Passwordless sudo for a group
echo '%ops    ALL=(ALL)       NOPASSWD: ALL' | sudo tee /etc/sudoers.d/ops

# One user, specific commands only
sudo visudo -f /etc/sudoers.d/alice
```

```text
alice   ALL=(root)      /usr/bin/systemctl restart httpd, \
                        /usr/bin/systemctl status httpd
```

```bash
# Or just add them to wheel, which is often what a task means
sudo usermod -aG wheel alice
```

**Use absolute paths for commands.** A bare `systemctl` is meaningless to sudo and the rule will not match.

**Restricting to specific commands has a caveat worth knowing:** a permitted command that can run other commands (an editor, `find -exec`, `less`, `vi`) is effectively full root. `sudoedit` exists for the editor case.

### Verifying

```bash
sudo -l                               # what can I do
sudo -l -U alice                      # what can alice do
sudo visudo -c
su - alice -c 'sudo -l'
su - alice -c 'sudo id'               # the real test
```

```text
User alice may run the following commands on server1:
    (ALL) ALL
```

**Test as the user.** Reading the file tells you what you wrote; `sudo -l -U alice` tells you what sudo parsed.

### Other useful settings

```text
Defaults:alice          timestamp_timeout=0        # always prompt
Defaults               timestamp_timeout=30        # 30-minute grace
Defaults               log_output                  # log command output
Defaults               requiretty
Defaults               secure_path="/sbin:/bin:/usr/sbin:/usr/bin"
```

```bash
sudo -v                               # refresh the timestamp
sudo -k                               # invalidate it
sudo -i                               # a root login shell
sudo -u alice command                 # run as alice
sudo -i -u alice                      # a login shell as alice
```

**sudo usage is logged to `/var/log/secure`:**

```bash
sudo grep sudo /var/log/secure | tail
sudo journalctl _COMM=sudo -n 20
```

---

## Auditing and checking

```bash
sudo pwck                             # /etc/passwd and /etc/shadow consistency
sudo grpck                            # /etc/group and /etc/gshadow
sudo vipw ; sudo vipw -s              # edit passwd/shadow with locking
sudo vigr ; sudo vigr -s
lslogins ; lslogins -u                # a good summary
who ; w ; last ; lastb ; lastlog
last alice ; lastlog -u alice
loginctl list-sessions ; loginctl user-status alice
```

Useful one-liners:

```bash
# Regular users only
awk -F: '$3>=1000 && $3<60000 {print $1, $3}' /etc/passwd

# Anyone with a login shell
awk -F: '$7!~/(nologin|false)$/ {print $1, $7}' /etc/passwd

# UID 0 accounts
awk -F: '$3==0 {print $1}' /etc/passwd

# Empty passwords (as root)
sudo awk -F: '$2=="" {print $1}' /etc/shadow

# Locked accounts
sudo awk -F: '$2 ~ /^!/ {print $1}' /etc/shadow

# Duplicate UIDs
cut -d: -f3 /etc/passwd | sort | uniq -d

# Members of a group, including primary members
getent group devs
awk -F: -v gid="$(getent group devs | cut -d: -f3)" '$4==gid {print $1}' /etc/passwd

# Orphaned files
sudo find /home -nouser -o -nogroup 2>/dev/null
```

---

## Worked example

**Task: create the group `webadmin` with GID 6000. Create `alice` (UID 1501) and `bob` (UID 1502) with `webadmin` as their primary group, bash shells, and home directories. Both must change their password at first login and must change it at least every 45 days with 5 days' warning. `webadmin` members may restart httpd with sudo and nothing else. `bob`'s account must expire on 2026-12-31.**

```bash
# 1. Group
sudo groupadd -g 6000 webadmin
getent group webadmin

# 2. Users
sudo useradd -u 1501 -g webadmin -s /bin/bash -m -c "Alice Anderson" alice
sudo useradd -u 1502 -g webadmin -s /bin/bash -m -c "Bob Brown" bob
id alice ; id bob

# 3. Passwords
echo 'RedHat123' | sudo passwd --stdin alice
echo 'RedHat123' | sudo passwd --stdin bob

# 4. Aging
sudo chage -M 45 -W 5 alice
sudo chage -M 45 -W 5 bob
sudo chage -d 0 alice
sudo chage -d 0 bob

# 5. Account expiry for bob only
sudo chage -E 2026-12-31 bob

# 6. sudo
sudo visudo -f /etc/sudoers.d/webadmin
```

```text
%webadmin  ALL=(root)  /usr/bin/systemctl restart httpd
```

```bash
sudo visudo -c
sudo -l -U alice
```

Verify everything:

```bash
getent group webadmin
id alice ; id bob
sudo chage -l alice ; sudo chage -l bob
ls -ld /home/alice /home/bob
sudo -l -U alice
sudo -l -U bob
sudo visudo -c
```

```text
Last password change      : password must be changed
Maximum number of days between password change : 45
Number of days of warning before password expires : 5
Account expires           : Dec 31, 2026
```

Then the behavioural test:

```bash
su - alice                            # should demand a password change
su - alice -c 'sudo systemctl restart httpd'    # should work
su - alice -c 'sudo systemctl restart sshd'     # should be REFUSED
```

**Everything here lives in `/etc/passwd`, `/etc/shadow`, `/etc/group`, and `/etc/sudoers.d/`, so it is persistent by nature.** A reboot check is still worth doing — it costs nothing and confirms nothing else you did broke it.

---

## Verification

```bash
id USER ; groups USER ; getent passwd USER ; getent group GROUP
sudo chage -l USER
sudo passwd -S USER
grep USER /etc/passwd
sudo grep USER /etc/shadow
ls -ld /home/USER
sudo -l -U USER
sudo visudo -c
lslogins
su - USER -c 'id; sudo -l'            # the behavioural test
```

---

## The five things to take away

1. **`usermod -aG`, never `-G`.** And run `id USER` immediately afterwards to confirm.
2. **`-g` is the primary group, `-G` is the secondary list.**
3. **`chage -d 0` forces a password change at next login.** `-M` is password age, `-E` is account expiry.
4. **`visudo`, always** — and prefer a file in `/etc/sudoers.d/`.
5. **`/etc/login.defs` and `/etc/skel` apply to new accounts only.** "All existing users" needs a loop.
