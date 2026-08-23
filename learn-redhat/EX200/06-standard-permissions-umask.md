# 06. Standard Permissions And umask

**Objectives:** List, set, and change standard `ugo/rwx` permissions. Manage default file permissions.

Permissions run through the entire exam. A storage task, a collaboration task, and a web-server task can all fail on a permission mistake.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Octal notation stops feeling mysterious once you chmod a file and read it back with `ls -l`.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Read permission notation

```bash
ls -l /etc/passwd /etc/shadow
ls -ld /tmp /root
```

**You should see** something like `-rw-r--r--` for `passwd`, `----------` or `---------` for `shadow`, and `drwxrwxrwt` for `/tmp`.

The first character is type (`-` file, `d` directory). Next three groups are **user**, **group**, **other**. **`r=4, w=2, x=1`** — add them for octal.

### 2. Set permissions with octal notation

```bash
touch /tmp/perm-demo.txt
chmod 640 /tmp/perm-demo.txt
ls -l /tmp/perm-demo.txt
```

**You should see** `-rw-r-----` — owner read+write (6), group read (4), other nothing (0).

Octal sets **all bits at once**. `640` is a common exam answer for "owner read/write, group read only".

### 3. Adjust permissions symbolically

```bash
chmod u=rw,g=rw,o=r /tmp/perm-demo.txt
ls -l /tmp/perm-demo.txt
chmod g-w /tmp/perm-demo.txt
ls -l /tmp/perm-demo.txt
```

**You should see** `rw-rw-r--` then `rw-r--r--`. Symbolic form adjusts only what you name: `u` user, `g` group, `o` other, `a` all. `+` add, `-` remove, `=` set exactly.

The `=` form is safer than `+`/`-` because it does not depend on the starting state.

### 4. Directory permissions are different

```bash
ls -ld /tmp /root /home
mkdir /tmp/dir-demo
chmod 644 /tmp/dir-demo
ls -ld /tmp/dir-demo
ls /tmp/dir-demo
```

**You should see** "Permission denied" when trying to `ls` the directory at mode 644.

On a **directory**: `r` lists names, `x` lets you enter (`cd`) and access files by name, `w` lets you create/delete entries. **`r` without `x` is useless** — you see names but cannot open anything.

### 5. Change owner and group

```bash
sudo groupadd devs-demo 2>/dev/null || true
sudo useradd -G devs-demo alice-demo 2>/dev/null || true
sudo touch /tmp/own-demo.txt
sudo chown alice-demo:devs-demo /tmp/own-demo.txt
ls -l /tmp/own-demo.txt
```

**You should see** `alice-demo` as owner and `devs-demo` as group.

**Only root can change a file's owner.** `chown alice:devs file` sets both; `chown :devs file` sets group only.

### 6. Check and interpret umask

```bash
umask
umask -S
touch /tmp/umask-file; mkdir /tmp/umask-dir
ls -l /tmp/umask-file; ls -ld /tmp/umask-dir
```

**You should see** umask `0002` or `0022`, and new files at `664`/`644` and directories at `775`/`755` depending on your user.

umask is **subtracted** from base permissions: **666 for files**, **777 for directories**. Regular users on RHEL typically get `0002`; root gets `0022`.

### 7. Set umask for this shell

```bash
umask 027
touch /tmp/u027-file; mkdir /tmp/u027-dir
ls -l /tmp/u027-file; ls -ld /tmp/u027-dir
```

**You should see** `-rw-r-----` (640) and `drwxr-x---` (750).

umask affects only **newly created** files in this shell. It is not retroactive.

### 8. Recursive permissions with capital X

```bash
sudo mkdir -p /tmp/shared-demo/subdir
sudo touch /tmp/shared-demo/file.txt /tmp/shared-demo/subdir/nested.txt
sudo chmod -R g+rwX /tmp/shared-demo
ls -lR /tmp/shared-demo
```

**You should see** group read/write on files, and execute added to **directories only** — not on plain text files.

Capital **`X`** adds execute only to directories and files that already had some execute bit. **`chmod -R g+rwx`** would wrongly make every data file executable.

### 9. Diagnose path permissions with `namei`

```bash
sudo mkdir -p /tmp/private-demo
sudo touch /tmp/private-demo/secret.txt
sudo chmod 644 /tmp/private-demo/secret.txt
sudo chmod 700 /tmp/private-demo
namei -l /tmp/private-demo/secret.txt
```

**You should see** every directory in the path with its mode. `private-demo` at `700` blocks anyone except root from traversing in — even if the file itself is `644`.

**You need `x` on every directory in the path.** This is the number-one cause of "permissions look right but access fails".

### 10. Find world-writable files

```bash
find /tmp -type f -perm -o+w 2>/dev/null
```

**You should see** any files under `/tmp` writable by others — or nothing if your system is clean.

`-perm -o+w` means "other has write bit set". World-writable files are a security finding.

### 11. Preserve permissions when copying

```bash
sudo cp -p /etc/shadow /tmp/shadow-copy
ls -l /etc/shadow /tmp/shadow-copy
stat -c '%a %U:%G %n' /etc/shadow /tmp/shadow-copy
```

**You should see** matching permissions and ownership. Plain `cp` applies your umask instead.

### 12. Persistent system-wide umask

```bash
sudo tee /etc/profile.d/umask-demo.sh <<'EOF'
umask 007
EOF
sudo chmod 644 /etc/profile.d/umask-demo.sh
bash -l -c umask
```

**You should see** `0007` in a fresh login shell.

Files in **`/etc/profile.d/`** survive package updates. Prefer this over editing `/etc/profile` directly.

### Mini checkpoint

Before the practice tasks, you should know:

| Octal | Symbolic | Typical use |
| --- | --- | --- |
| 644 | `rw-r--r--` | normal file |
| 755 | `rwxr-xr-x` | directory or executable |
| 600 | `rw-------` | private file |
| 775 | `rwxrwxr-x` | group-writable directory |

If any row is blank, re-run the step above that covers it.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Create `/tmp/perm-test.txt` and set its permissions to `rw-r-----` using octal notation.

> Hint: `chmod 640` from follow-along step 2.

**Task 2.** Set the same file to `rw-rw-r--` using symbolic notation only, without using numbers.

> Hint: `u=`, `g=`, `o=` from step 3.

**Task 3.** Create the directory `/srv/data` owned by user `alice` and group `devs`, with permissions `775`. Create the user and group first if needed.

> Hint: `groupadd`, `useradd`, `mkdir`, `chown`, `chmod` from steps 4–5.

**Task 4.** Show the current umask in both numeric and symbolic form, and state what permissions a new file and a new directory would receive.

> Hint: `umask` and `umask -S` from step 6; prove with `touch` and `mkdir`.

**Task 5.** Set your shell's umask to `027`, create a file and a directory, and confirm the resulting permissions.

> Hint: step 7.

**Task 6.** Configure the system so that all users get a umask of `007` on login, in a way that survives package updates and a reboot.

> Hint: `/etc/profile.d/` from step 12.

**Task 7.** Recursively give the group read, write, and directory-traverse access to `/srv/data`, without making data files executable.

> Hint: `chmod -R g+rwX` — capital X from step 8.

**Task 8.** Diagnose why user `bob` cannot read `/srv/private/notes.txt` even though the file is mode `644`. Create the scenario, then fix it.

> Hint: path traversal and `namei -l` from step 9.

**Task 9.** Find all files under `/home` that are world-writable.

> Hint: `find -perm -o+w` from step 10.

**Task 10.** Copy `/etc/shadow` to `/tmp/shadow-copy` preserving its permissions and ownership, then verify.

> Hint: `cp -p` from step 11.

**Task 11.** Change the group of every file under `/srv/data` to `devs` without changing the owner.

> Hint: `chgrp -R` or `chown -R :devs`.

**Task 12.** Make `/tmp/script.sh` executable by its owner and group but not by others, in a single symbolic command.

> Hint: `ug+x,o-x` — step 3 symbolic form.

**Task 13.** Show the permissions of every component in the path `/srv/data`.

> Hint: `namei -l` from step 9.

**Task 14.** Determine what permissions a new file would get if the umask were `0077`, and verify by experiment.

> Hint: subshell `( umask 0077; touch ... )` from step 7 concept.

---

## Solutions

**Task 1.**

```bash
touch /tmp/perm-test.txt
chmod 640 /tmp/perm-test.txt
ls -l /tmp/perm-test.txt
```

`rw- r-- ---` is `4+2=6`, `4`, `0`, so `640`.

**Task 2.**

```bash
chmod u=rw,g=rw,o=r /tmp/perm-test.txt
ls -l /tmp/perm-test.txt
```

Or additively from the current state:

```bash
chmod g+w,o+r /tmp/perm-test.txt
```

The `=` form is safer because it sets an absolute value regardless of what was there before. `+`/`-` depend on the starting state, which you may have misread.

**Task 3.**

```bash
sudo groupadd devs
sudo useradd -G devs alice
sudo mkdir -p /srv/data
sudo chown alice:devs /srv/data
sudo chmod 775 /srv/data
ls -ld /srv/data
```

Expected:

```text
drwxrwxr-x. 2 alice devs 6 Aug 18 15:00 /srv/data
```

Order matters slightly: `chown` before `chmod` if you use SGID later, because some operations clear the SGID bit. Covered in `12-special-permissions-acls.md`.

**Task 4.**

```bash
umask
umask -S
```

With the default `0002` for a regular user:

- New **file**: `666 - 002 = 664` → `rw-rw-r--`
- New **directory**: `777 - 002 = 775` → `rwxrwxr-x`

As root, the umask is `0022`, giving `644` and `755`.

Prove it:

```bash
touch /tmp/umask-file; mkdir /tmp/umask-dir
ls -l /tmp/umask-file; ls -ld /tmp/umask-dir
```

**Task 5.**

```bash
umask 027
touch /tmp/u027-file
mkdir /tmp/u027-dir
ls -l /tmp/u027-file      # -rw-r-----   (666 - 027 = 640)
ls -ld /tmp/u027-dir      # drwxr-x---   (777 - 027 = 750)
```

The change applies only to this shell and only to files created after it. Existing files are unaffected — umask is not retroactive.

**Task 6.**

```bash
sudo tee /etc/profile.d/umask.sh <<'EOF'
umask 007
EOF
sudo chmod 644 /etc/profile.d/umask.sh
```

Verify by starting a fresh login shell:

```bash
bash -l -c umask
# or log out and back in
su - alice -c umask
```

Everything in `/etc/profile.d/*.sh` is sourced by login shells. This is the right place for system-wide shell settings; do not edit `/etc/profile` itself, because a package update can replace it.

Note the quoted heredoc delimiter `<<'EOF'`. Not strictly needed here, but the habit prevents accidental variable expansion when the content contains `$`.

**Task 7.**

```bash
sudo chmod -R g+rwX /srv/data
ls -lR /srv/data
```

Capital **`X`** adds execute only to directories and to files that already had an execute bit. With lowercase `x`, every text file in the tree becomes executable, which is wrong. This is the standard answer to "give group access to a tree".

**Task 8.**

Create the scenario:

```bash
sudo useradd bob
sudo mkdir -p /srv/private
sudo touch /srv/private/notes.txt
sudo chmod 644 /srv/private/notes.txt
sudo chmod 700 /srv/private            # the actual problem
```

Confirm the failure and diagnose:

```bash
sudo -u bob cat /srv/private/notes.txt
# cat: /srv/private/notes.txt: Permission denied

namei -l /srv/private/notes.txt
```

`namei -l` shows `drwx------ root root private`. The file is readable, but `bob` has no `x` on the parent directory, so he cannot traverse into it to reach the file at all.

Fix:

```bash
sudo chmod 755 /srv/private
sudo -u bob cat /srv/private/notes.txt      # now works
```

**This is the most important permission concept on the exam.** File permissions are irrelevant if any directory in the path denies traversal. Whenever a "diagnose the permission problem" task appears, run `namei -l` first.

**Task 9.**

```bash
sudo find /home -type f -perm -o+w
```

Or in octal:

```bash
sudo find /home -type f -perm -002
```

The leading `-` means "at least these bits". World-writable files are a genuine security finding, so this is a realistic task. To fix them:

```bash
sudo find /home -type f -perm -o+w -exec chmod o-w {} +
```

**Task 10.**

```bash
sudo cp -p /etc/shadow /tmp/shadow-copy
sudo ls -l /etc/shadow /tmp/shadow-copy
sudo stat -c '%a %U:%G %n' /etc/shadow /tmp/shadow-copy
```

Both should report mode `0` (or `000`) owned by `root:root`. `/etc/shadow` is mode `000` on RHEL and is readable only because root bypasses permission checks.

Without `-p`, the copy would get your umask-derived permissions, which for a file containing password hashes would be a serious mistake. Use `cp -a` if the SELinux context also matters.

**Task 11.**

```bash
sudo chgrp -R devs /srv/data
```

Or equivalently:

```bash
sudo chown -R :devs /srv/data
```

The `:group` form of `chown` with no user before the colon changes only the group. Both are correct; `chgrp` is clearer about intent.

**Task 12.**

```bash
chmod ug+x,o-x /tmp/script.sh
ls -l /tmp/script.sh
```

Note that `chmod +x` alone applies to all three sets, filtered by your umask, which is not the same thing. Being explicit with `ug+x,o-x` guarantees the result.

**Task 13.**

```bash
namei -l /srv/data
```

Alternatively:

```bash
namei -om /srv/data
ls -ld / /srv /srv/data
```

Get comfortable with `namei -l`. It answers path-permission questions in one command instead of three `ls -ld` calls.

**Task 14.**

`666 - 077 = 600` for a file, `777 - 077 = 700` for a directory. Verify:

```bash
( umask 0077; touch /tmp/u77-file; mkdir /tmp/u77-dir )
ls -l /tmp/u77-file       # -rw-------
ls -ld /tmp/u77-dir       # drwx------
```

Running it inside `( ... )` uses a subshell, so your interactive shell's umask is untouched. A neat trick for testing without side effects.

---

## Verify

```bash
ls -ld /srv/data
namei -l /srv/private/notes.txt
bash -l -c umask
stat -c '%a %A %U:%G %n' /tmp/perm-test.txt
```

## Persistence Check

| Change | Persists? | Notes |
| --- | --- | --- |
| `chmod`, `chown`, `chgrp` | **Yes** | Written to the inode |
| `umask` typed in a shell | **No** | Lost on logout |
| `umask` in `/etc/profile.d/*.sh` | **Yes** | The correct persistent method |
| `umask` in `~/.bashrc` | Yes, for that user only | |

After a reboot, confirm the system-wide umask:

```bash
cat /etc/profile.d/umask.sh
bash -l -c umask
su - alice -c umask
```

Also confirm ownership survived, which it will, since it lives in the inode. What does **not** survive is anything you set on a filesystem that is not in `/etc/fstab`.

## Quick Reference

Come back here when you need a fact you forgot — not before your first pass through Follow Along.

### The three sets and three bits

```text
-rwxr-xr--
│└┬┘└┬┘└┬┘
│ │  │  └── other  (everyone else)
│ │  └───── group  (members of the file's group)
│ └──────── user   (the owner)
└────────── type
```

| Bit | Symbol | Octal | On a **file** | On a **directory** |
| --- | --- | --: | --- | --- |
| read | `r` | **4** | Read contents | **List** the names inside |
| write | `w` | **2** | Modify contents | **Create, delete, rename** entries inside |
| execute | `x` | **1** | Run it | **Enter** it (`cd`), and access items by name |

**Directory permissions are where people go wrong.** The rules that matter:

- **`x` without `r`**: you can `cd` into the directory and access a file if you already know its exact name, but you cannot list it.
- **`r` without `x`**: you can list the names (`ls`) but you get "Permission denied" on every one of them, because you cannot traverse into the directory to read their inodes. `ls -l` shows question marks.
- **`w` on a directory lets you delete a file you do not own**, regardless of that file's own permissions. This is why `/tmp` needs the sticky bit.
- **To reach `/a/b/c/file` you need `x` on `/a`, `/a/b`, and `/a/b/c`.** A single missing `x` anywhere in the path blocks access. This is the number-one cause of "the permissions on the file look right but it still fails".

### Octal notation

```text
r = 4    w = 2    x = 1

7 = rwx      4 = r--
6 = rw-      3 = -wx
5 = r-x      2 = -w-
             1 = --x
             0 = ---
```

| Octal | Symbolic | Typical use |
| --- | --- | --- |
| **644** | `rw-r--r--` | A normal file |
| **755** | `rwxr-xr-x` | A directory, or an executable |
| **600** | `rw-------` | A private file, e.g. an SSH private key |
| **700** | `rwx------` | A private directory, e.g. `~/.ssh` |
| **664** | `rw-rw-r--` | A group-writable file |
| **775** | `rwxrwxr-x` | A group-writable directory |
| **2770** | `rwxrws---` | A **set-GID collaborative** directory |
| **1777** | `rwxrwxrwt` | `/tmp`, world-writable with the **sticky bit** |
| **440** | `r--r-----` | Read-only for owner and group, e.g. `/etc/sudoers.d` files |

### chmod

```bash
# Numeric: sets ALL bits at once
chmod 644 file
chmod 755 dir
chmod -R 755 /var/www/html        # recursive

# Symbolic: adjusts only what you name
chmod u+x file                    # add execute for the owner
chmod g-w file                    # remove write from the group
chmod o= file                     # remove ALL permissions from other
chmod a+r file                    # add read for all (a = ugo)
chmod u=rw,g=r,o= file            # set each set explicitly
chmod +x script.sh                # add x, respecting umask
chmod g+s dir                     # SGID: files inherit the group
chmod o+t dir                     # sticky bit
chmod u+s binary                  # SUID

# The X trick: x on directories, and on files that already have some x
chmod -R g+rwX /shared            # capital X
```

**Capital `X` is genuinely useful.** `chmod -R g+rwx /shared` makes every data file executable, which is wrong and sloppy. `chmod -R g+rwX /shared` adds `x` only to directories and to files that were already executable. Use it whenever you recurse.

Symbolic reference:

| Who | Operator | What |
| --- | --- | --- |
| `u` user/owner | `+` add | `r` read |
| `g` group | `-` remove | `w` write |
| `o` other | `=` set exactly | `x` execute |
| `a` all (ugo) | | `X` conditional execute |
| | | `s` SUID/SGID |
| | | `t` sticky |

### chown and chgrp

```bash
chown alice file                  # owner
chown alice:devs file             # owner and group
chown :devs file                  # group only
chown -R alice:devs /srv/project  # recursive
chgrp devs file                   # group only
chown --reference=/etc/hosts file # copy ownership from another file

# Preserve ownership when copying
cp -p src dst
cp -a srcdir dstdir
```

**Only root can change a file's owner.** A regular user can change a file's group, but only to a group they belong to. If a task says "make alice the owner", you need `sudo`.

### umask: default permissions

New files and directories are created with permissions determined by the **base** permissions minus the umask.

```text
Base for a DIRECTORY: 777
Base for a FILE:      666      <- never 777. Files are never created executable
```

```text
Directory:  777 - 022 = 755
File:       666 - 022 = 644

Directory:  777 - 002 = 775
File:       666 - 002 = 664

Directory:  777 - 077 = 700
File:       666 - 077 = 600
```

| Default umask | Applies to | Dir | File |
| --- | --- | --- | --- |
| **`0022`** | **root** and system accounts | 755 | 644 |
| **`0002`** | **regular users** (UID >= 1000) | 775 | 664 |

RHEL gives regular users `002` rather than `022` because of **user private groups**: every user gets their own group of the same name, so group-write is harmless by default and makes collaboration easier when you do change the group.

```bash
umask                 # show current, e.g. 0002
umask -S              # symbolic, e.g. u=rwx,g=rwx,o=rx
umask 027             # set for this shell only
umask 0027
```

Setting it **persistently**:

```bash
# For one user
echo 'umask 007' >> ~/.bashrc

# System-wide, the correct RHEL way
sudo tee /etc/profile.d/umask.sh <<'EOF'
umask 007
EOF
sudo chmod 644 /etc/profile.d/umask.sh
```

Prefer a file in **`/etc/profile.d/`** over editing `/etc/profile` or `/etc/bashrc` directly. It survives package updates and is the documented approach. The logic that sets `002` versus `022` lives in `/etc/profile` and `/etc/bashrc`, keyed on whether the UID is at least 1000.

Note that umask is **subtractive by bit masking, not arithmetic**. `777 - 022 = 755` happens to work, but the operation is really "clear the bits set in the mask". With an odd mask like `023`, think in bits: `777` clear `023` gives `754`.

### Checking effective access

```bash
ls -l file
ls -ld dir
stat -c '%a %A %U %G %n' file      # octal, symbolic, owner, group, name

namei -l /var/www/html/index.html   # PERMISSIONS OF EVERY PATH COMPONENT
sudo -u alice test -r /path/file && echo readable
sudo -u alice ls /srv/project       # test as another user
```

**`namei -l`** is the best diagnostic tool for permission problems and few people know it. It shows the owner, group, and mode of every directory in the path, so a missing `x` three levels up is immediately visible.

```bash
$ namei -l /srv/project/docs/report.txt
f: /srv/project/docs/report.txt
 dr-xr-xr-x root root    /
 drwxr-xr-x root root    srv
 drwx------ root root    project      <- here is the problem
 drwxr-xr-x root root    docs
 -rw-r--r-- root root    report.txt
```

## Exam Tips

- **`r=4, w=2, x=1`.** 644 files, 755 directories, 600 private files, 700 private directories.
- **On a directory: `r` lists, `w` creates/deletes, `x` enters.** These are not the same as on a file.
- **You need `x` on every directory in the path.** A missing `x` upstream defeats correct permissions on the file. Diagnose with **`namei -l`**.
- **`w` on a directory lets you delete files you do not own.** That is what the sticky bit exists to prevent.
- **Use `chmod -R g+rwX`, capital X**, when recursing, so data files do not become executable.
- **Only root can change the owner.** A user can change the group only to one they are in.
- **`cp -p` or `cp -a`** when permissions or ownership must be preserved. Plain `cp` applies your umask.
- **umask bases: 666 for files, 777 for directories.** Files are never created executable.
- **Default umask is `022` for root and `002` for regular users** on RHEL, because of user private groups.
- `umask 022` → 644/755. `umask 002` → 664/775. `umask 027` → 640/750. `umask 077` → 600/700.
- Persist a system-wide umask in **`/etc/profile.d/umask.sh`**, not in `/etc/profile`.
- umask is **not retroactive**. It only affects newly created files.
- **`stat -c '%a %A %U:%G %n'`** gives you octal, symbolic, and ownership in one line.
- `chmod u=rw,g=r,o=` is safer than `+`/`-` because it sets an absolute value.
