# 07. System Documentation

**Objective:** Locate, read, and use system documentation including `man`, `info`, and files in `/usr/share/doc`.

This objective is unusual: it is rarely a task on its own. It is tested by the fact that **the exam gives you no internet, no notes, and no books — only the documentation on the machine.** Every flag you cannot remember has to come from here. Treat this as a survival skill, not a topic.

## Concept Refresher

### man pages

```bash
man passwd                # the command
man 5 passwd              # the FILE FORMAT — a different page, same name
man -f passwd             # which sections exist for this name (same as whatis)
man -k selinux            # SEARCH descriptions by keyword (same as apropos)
man -K "semanage port"    # search the full TEXT of all pages (slow, thorough)
man -a passwd             # show every section in turn
man -w passwd             # print the file path of the page
```

### The section numbers

Memorise 1, 5, and 8. They cover almost everything you need.

| Section | Contents | Example |
| --: | --- | --- |
| **1** | User commands | `man 1 passwd` — the `passwd` command |
| 2 | System calls | `man 2 open` |
| 3 | Library functions | `man 3 printf` |
| 4 | Device files | `man 4 tty` |
| **5** | **File formats and configuration files** | `man 5 passwd` — the format of `/etc/passwd` |
| 6 | Games | |
| 7 | Miscellany, conventions | `man 7 hier` — the filesystem layout |
| **8** | **System administration commands** | `man 8 useradd`, `man 8 semanage-fcontext` |

**Section 5 is the one that saves you on this exam.** When you cannot remember the field order in `/etc/fstab`, `/etc/shadow`, or `/etc/crontab`, the answer is in section 5:

```bash
man 5 fstab
man 5 shadow
man 5 crontab
man 5 exports          # NFS
man 5 sudoers
man 5 hosts
man 5 chrony.conf
man 5 login.defs
man 5 systemd.unit
man 5 systemd.service
man 5 systemd.timer
man 5 auto.master      # autofs
man 5 nsswitch.conf
```

Say it as: **"section 5 is the config file, section 1 or 8 is the command."**

### Navigating a man page

man uses `less`, so:

| Key | Action |
| --- | --- |
| `Space` / `f` | Page down |
| `b` | Page up |
| `d` / `u` | Half page down / up |
| **`/text`** | **Search forward** |
| `?text` | Search backward |
| **`n` / `N`** | **Next / previous match** |
| `g` / `G` | Top / bottom |
| `q` | Quit |
| `h` | less's own help |

**The fastest way to use a man page under time pressure is `/EXAMPLE`.** Many pages, especially the systemd and `semanage` ones, have a worked example that is exactly what you need:

```bash
man semanage-fcontext
# then type: /EXAMPLE  and press Enter
```

### Finding the command when you do not know its name

This is the real value of `man -k`.

```bash
man -k "password"
man -k "user account"
man -k selinux
man -k "logical volume"
man -k firewall
man -k "time zone"

# Restrict to a section
man -k -s 8 selinux
man -k -s 5 crontab
```

If `man -k` returns nothing at all, the index database is missing. Build it:

```bash
sudo mandb
```

Worth knowing: on a freshly installed minimal system, `man -k` can be empty until `mandb` has run.

### Bundled help that is not man

```bash
command --help            # usually the fastest reminder of flag syntax
command -h
ls --help | grep -- '-d'  # grep the help output for a specific flag

help cd                   # for SHELL BUILTINS, man does not work properly
help test
help for
type cd                   # is it a builtin, alias, or file?
```

**`help` versus `man` matters.** `cd`, `test`, `for`, `if`, `umask`, `export`, and `source` are shell builtins. `man cd` either fails or shows a generic page; `help cd` gives the real documentation. When a man page for something basic seems missing, try `help`.

### info pages

GNU's format, more thorough than man for some tools (`coreutils`, `tar`, `sed`, `grep`).

```bash
info tar
info coreutils 'ls invocation'
info                      # top-level directory of all info documents
```

| Key | Action |
| --- | --- |
| `Space` / `Del` | Page forward / back |
| `n` / `p` | Next / previous node at this level |
| `u` | Up one level |
| `Enter` | Follow the menu item under the cursor |
| `s` | Search |
| `q` | Quit |
| `H` | Help |

Realistically, on a 3-hour exam you will use `man` and `--help` far more than `info`. Know that it exists and how to quit it.

### /usr/share/doc

Package-supplied documentation: READMEs, sample configuration, changelogs. **This is where you find working example config files.**

```bash
ls /usr/share/doc/
ls /usr/share/doc/httpd/
ls /usr/share/doc/chrony/

# Find every sample config on the system
find /usr/share/doc -name "*.conf" 2>/dev/null | head -30
find /usr/share/doc -iname "*example*" 2>/dev/null | head -30
find /usr/share/doc -iname "README*" | head
```

The classic use: you need to write an autofs map or an httpd virtual host and cannot remember the syntax. There is usually a sample in `/usr/share/doc` you can copy and edit.

```bash
# Which package owns a file, and what docs came with it
rpm -qf /etc/chrony.conf            # -> chrony-x.y-z
rpm -qd chrony                      # list the package's doc files
rpm -qc chrony                      # list the package's CONFIG files
rpm -ql chrony                      # list ALL files in the package
```

**`rpm -qc <package>`** is excellent: it tells you exactly which files you are supposed to edit for a service.

### systemd's own documentation

```bash
systemctl cat sshd                       # the actual unit file, as loaded
systemctl show sshd                      # every property and its value
systemctl help sshd                      # open the man page FOR THAT SERVICE
man systemd.unit
man systemd.service
man systemd.timer
```

`systemctl cat` is the right way to read a unit, because it shows the real file plus any drop-in overrides in order.

### Other places answers hide

```bash
ls /etc/skel/                       # what new users' home dirs are seeded with
timedatectl list-timezones          # valid timezone names
cat /etc/login.defs                 # heavily commented: UID ranges, password aging
cat /etc/fstab                      # existing lines are a template for new ones
ls /etc/yum.repos.d/                # an existing .repo file shows the format
firewall-cmd --get-services         # every predefined firewall service
tuned-adm list                      # available tuning profiles
semanage boolean -l                 # every SELinux boolean, with a description
semanage fcontext -l | grep httpd   # what context a path should have
```

**An existing correct example on the system is often faster than a man page.** Need an `fstab` line? Look at the ones already there. Need a `.repo` file? Copy one from `/etc/yum.repos.d/`. Need a unit file? `systemctl cat` a similar service.

## Tasks

**Task 1.** Determine the field order of `/etc/fstab` using only documentation on the system.

**Task 2.** Find which man section documents the format of `/etc/shadow`, and list the meaning of each field.

**Task 3.** Find every man page whose description mentions SELinux, restricted to section 8.

**Task 4.** Find the documentation for the `crontab` **file format**, not the command.

**Task 5.** Locate sample or example configuration supplied by the `autofs` package.

**Task 6.** Determine which package owns `/etc/chrony.conf`, then list all configuration files that package provides.

**Task 7.** Find the correct syntax for adding a persistent SELinux port label, using only `man`.

**Task 8.** Show the documentation for the shell builtin `test`.

**Task 9.** List all valid timezone names containing `Nairobi`.

**Task 10.** Find the full unit definition for `sshd`, including any drop-in overrides.

**Task 11.** Find every man page related to logical volume management.

**Task 12.** Find the exact spelling of the SELinux boolean that allows httpd to make network connections.

**Task 13.** Determine what files a new user's home directory is populated with, and where they come from.

**Task 14.** Find an example `.repo` file on the system to use as a template.

---

## Solutions

**Task 1.**

```bash
man 5 fstab
```

The six fields:

```text
<device>  <mountpoint>  <fstype>  <options>  <dump>  <fsck>
UUID=...  /mnt/data     xfs       defaults   0       0
```

Field 5 (`dump`) is essentially always `0`. Field 6 (`fsck` pass) is `1` for root, `2` for other ext filesystems, and `0` for xfs and swap.

Faster in practice:

```bash
cat /etc/fstab
```

The existing entries and header comment give you the format immediately. **Use the machine, not just the manual.**

**Task 2.**

```bash
man 5 shadow
```

Section **5**. The nine colon-separated fields:

```text
1 login name
2 encrypted password
3 date of last password change (days since 1970-01-01)
4 minimum days between changes    (chage -m)
5 maximum days password is valid  (chage -M)
6 warning period in days          (chage -W)
7 inactivity period after expiry  (chage -I)
8 account expiration date         (chage -E)
9 reserved
```

Fields 4-8 map directly onto `chage` flags, which is the point of knowing this. See `11-password-aging-sudo.md`.

**Task 3.**

```bash
man -k -s 8 selinux
```

You should see `semanage`, `restorecon`, `setsebool`, `getsebool`, `sestatus`, `fixfiles`, `chcon`, `matchpathcon`, and the `semanage-*` subcommand pages. That list alone is a decent SELinux revision aid.

If it returns nothing:

```bash
sudo mandb
man -k -s 8 selinux
```

**Task 4.**

```bash
man 5 crontab
```

Section 1 is the `crontab` **command** (how to install and edit a crontab). Section 5 is the **file format** (the five time fields, special strings like `@daily`, and the extra user field in `/etc/crontab`). For the field layout you want section 5.

**Task 5.**

```bash
rpm -qd autofs
ls /usr/share/doc/autofs/
find /usr/share/doc -iname "*auto.master*" 2>/dev/null
```

`rpm -qd autofs` lists the doc files that package installed, which is more reliable than guessing directory names. You will typically find sample `auto.master` and `auto.misc` files showing exactly the map syntax needed in `32-nfs-autofs.md`.

**Task 6.**

```bash
rpm -qf /etc/chrony.conf
rpm -qc chrony
```

`-qf` asks "which package owns this **f**ile". `-qc` lists that package's **c**onfig files. The pair answers "I need to configure this service, which files do I edit" in two commands.

Also useful:

```bash
rpm -qd chrony      # documentation files
rpm -ql chrony      # every file
rpm -qi chrony      # package info and description
```

**Task 7.**

```bash
man semanage-port
```

Then `/EXAMPLE`. You will find:

```bash
semanage port -a -t http_port_t -p tcp 8080
```

The flags: `-a` add, `-t` type, `-p` protocol. `-m` modifies an existing label, `-l` lists, `-d` deletes.

The route to that page if you did not know its name:

```bash
man -k semanage
man semanage           # the main page, which lists the subcommand pages
man semanage-port
```

This chain — `man -k` to find it, main page to see the subcommands, subcommand page for `/EXAMPLE` — is the single most valuable documentation skill for the SELinux tasks in `27-selinux.md`.

**Task 8.**

```bash
help test
```

`test` is a shell builtin. `man test` shows the external `/usr/bin/test`, which exists but is not what bash actually runs. `help test` documents the builtin, including the `-f`, `-d`, `-z`, `-n`, `-eq` operators you need in `33-shell-scripting.md`.

```bash
type test          # test is a shell builtin
help [             # the bracket form
help [[            # the bash conditional
```

**Task 9.**

```bash
timedatectl list-timezones | grep -i nairobi
```

Gives `Africa/Nairobi`. Alternatively:

```bash
find /usr/share/zoneinfo -name "Nairobi"
```

`timedatectl list-timezones` is preferable because it lists only names that `timedatectl set-timezone` will actually accept. See `21-time-chrony.md`.

**Task 10.**

```bash
systemctl cat sshd
```

This prints the unit file with a `# /usr/lib/systemd/system/sshd.service` header, followed by any drop-ins from `/etc/systemd/system/sshd.service.d/`. That ordering tells you what is overriding what.

```bash
systemctl show sshd                    # all resolved properties
systemctl show -p ExecStart sshd       # one property
systemctl help sshd                    # jumps to sshd's man page
```

**Task 11.**

```bash
man -k "logical volume"
man -k lvm
```

You get `lvm`, `pvcreate`, `pvs`, `pvdisplay`, `vgcreate`, `vgs`, `vgextend`, `lvcreate`, `lvs`, `lvextend`, `lvremove`, and more. Every LVM command needed in `29-lvm.md` is discoverable this way, which means an LVM task is never unrecoverable even if you blank on the flags.

**Task 12.**

```bash
sudo semanage boolean -l | grep -i httpd
```

Look for `httpd_can_network_connect`. Alternatively:

```bash
getsebool -a | grep httpd
```

`semanage boolean -l` includes a plain-English description of each boolean, which `getsebool -a` does not. When a task says "allow httpd to connect to a database", this is how you find the boolean's exact name rather than guessing.

**Task 13.**

```bash
ls -la /etc/skel/
```

`/etc/skel` is copied into every new home directory by `useradd`. It normally contains `.bash_profile`, `.bashrc`, and `.bash_logout`. If a task says "ensure all new users get a particular file", the answer is to put it in `/etc/skel`. Confirmed by:

```bash
grep -i skel /etc/default/useradd
man 8 useradd          # then /skel
```

**Task 14.**

```bash
ls /etc/yum.repos.d/
cat /etc/yum.repos.d/*.repo | head -20
man 5 dnf.conf         # then /repo
```

Copying an existing `.repo` file and editing the `name`, `baseurl`, and `gpgkey` is far faster and less error-prone than typing one from memory. See `22-software-management-dnf.md`.

---

## Verify

```bash
man -k selinux | wc -l          # non-zero means mandb is populated
man 5 fstab | head -20
rpm -qc chrony
systemctl cat sshd | head
ls /usr/share/doc | wc -l
```

## Persistence Check

Nothing here changes system state, with one exception:

```bash
sudo mandb        # builds the man index; needed for man -k to work
```

If your lab was installed minimally and `man -k` returns nothing, run `mandb` once. On the exam system the index will already exist.

If documentation is missing entirely:

```bash
sudo dnf install -y man-pages man-db
```

## Exam Tips

- **Section 1 = command. Section 5 = config file format. Section 8 = admin command.** The single most useful fact here.
- **`man 5 fstab`, `man 5 shadow`, `man 5 crontab`, `man 5 exports`, `man 5 sudoers`, `man 5 auto.master`.** Practise reaching these.
- **`man -k keyword`** (= `apropos`) to find a command you cannot name. Add **`-s 8`** to restrict the section.
- If `man -k` returns nothing, run **`sudo mandb`**.
- **Inside a man page, type `/EXAMPLE`.** The `semanage-*` and systemd pages have copy-ready examples.
- **`man -K`** searches the full text of all pages. Slow, but finds what `-k` misses.
- **`help builtin`** for shell builtins: `cd`, `test`, `for`, `umask`, `export`. `man` does not cover them properly.
- **`command --help`** is usually the fastest flag reminder.
- **`rpm -qf FILE`** for which package owns a file; **`rpm -qc PKG`** for its config files; **`rpm -qd PKG`** for its docs.
- **`/usr/share/doc/<package>/`** holds sample configs. Find them with `find /usr/share/doc -iname '*example*'`.
- **`systemctl cat UNIT`** shows the unit plus drop-in overrides, in order.
- **Read the machine, not just the manual.** Existing `fstab` lines, existing `.repo` files, and `/etc/skel` are faster templates than any man page.
- `semanage boolean -l` includes descriptions; `getsebool -a` does not.
- `timedatectl list-timezones` gives names guaranteed to be valid.
- To quit `info` or `man`, press `q`. Do not lose thirty seconds to this.
