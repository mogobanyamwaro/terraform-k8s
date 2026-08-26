# 01. Shell Fundamentals And File Management

**Objectives:** Access a shell prompt and issue commands with correct syntax. Create, delete, copy, and move files and directories.

These are the operations underneath every other task on the exam. You will not get a task that says "copy a file", but you will get twenty tasks that require it while the clock runs.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Reading every `ls` flag and `find` option upfront feels like learning. Typing them one at a time actually is.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Where you are (`pwd` and `cd`)

```bash
pwd
cd /etc
pwd
cd ../..
pwd
cd
pwd
cd -
pwd
```

**You should see** `/etc`, then `/` (up two levels from `/etc`), then your home directory, then `/` again. `cd -` toggles to the **previous** directory.

```bash
cd                  # home directory
cd ~alice           # alice's home directory (if that user exists)
```

Absolute paths start with `/`. Relative paths do not. `cd -` is the one people underuse on the exam.

### 2. List files — the flags you will actually type

```bash
ls /etc | head
ls -l /etc | head
ls -la ~ | head
ls -lh /var/log | head
ls -lt /var/log | head
ls -ltr /var/log | tail
```

**You should see:**

- Plain names, then a long listing (perms, links, owner, group, size, mtime, name).
- `-a` includes dotfiles. `-h` makes sizes human-readable.
- `-t` newest first. `-tr` oldest first, newest at the **bottom** — best for logs.

The combination you will type most is `ls -la`. For "what changed recently", use `ls -ltr`.

```bash
ls -li /etc/passwd
ls -lZ /etc/passwd
```

**You should see** an inode number (`-i`) and an SELinux context (`-Z`).

### 3. Describe a directory itself (`ls -ld`)

```bash
ls -l /etc | head
ls -ld /etc
ls -ldZ /etc/ssh
```

**You should see** the first command list **contents** of `/etc`. The second describes the **directory** `/etc` itself. The third adds the SELinux context of `/etc/ssh`.

`ls -ld` is the one people forget. Without `-d`, asking about a directory lists what is inside it instead of describing it.

### 4. Read an `ls -l` line

```bash
ls -l /etc/passwd
```

**You should see** a line like this. Map every column:

```text
-rw-r--r--. 1 root root 1024 Aug 18 14:32 file.txt
│└─┬┘└┬┘└┬┘│ │  │    │    │      │          │
│  │  │  │ │ │  │    │    │      │          └─ name
│  │  │  │ │ │  │    │    │      └─ modification time
│  │  │  │ │ │  │    │    └─ size in bytes
│  │  │  │ │ │  │    └─ group
│  │  │  │ │ │  └─ owner
│  │  │  │ │ └─ hard link count
│  │  │  │ └─ '.' = has an SELinux context, '+' = has an ACL
│  │  │  └─ other permissions
│  │  └─ group permissions
│  └─ owner permissions
└─ type: '-' file, 'd' directory, 'l' symlink, 'b' block, 'c' char, 's' socket, 'p' pipe
```

The `.` versus `+` in position 11 matters: a `+` tells you an ACL is present, which is the first clue in a "diagnose this permission problem" task. Covered in `12-special-permissions-acls.md`.

### 5. Create files and directories

```bash
mkdir -p /tmp/lab01/{docs,src,build}
touch /tmp/lab01/docs/report{1..5}.txt
ls -R /tmp/lab01
```

**You should see** three directories under `/tmp/lab01`, and five `reportN.txt` files in `docs`.

`-p` creates missing parents and does not error if the target already exists. Always use it. Brace expansion `{docs,src,build}` and `{1..5}` are one command each — no loops.

```bash
touch /tmp/lab01/empty.txt          # create empty, or update mtime if it exists
mkdir /tmp/lab01/one-level          # one level only; fails if parent is missing
```

### 6. Brace expansion as a backup idiom

```bash
cp /etc/hosts /tmp/lab01/hosts.copy
cp /tmp/lab01/hosts.copy{,.bak}
ls -l /tmp/lab01/hosts.copy*
```

**You should see** `hosts.copy` and `hosts.copy.bak`. `file{,.bak}` expands to `file file.bak`.

Memorise this. Before you edit `/etc/fstab`, `/etc/sudoers`, or `/etc/default/grub`, back it up in one short command:

```bash
# pattern you will use on real system files:
# sudo cp /etc/fstab{,.bak}
```

### 7. Copy files — `-r`, `-p`, and `-a`

```bash
cp /etc/hosts /tmp/lab01/hosts-plain
cp -p /etc/hosts /tmp/lab01/hosts-preserved
ls -l /etc/hosts /tmp/lab01/hosts-plain /tmp/lab01/hosts-preserved
stat -c '%a %U:%G %y' /etc/hosts /tmp/lab01/hosts-plain /tmp/lab01/hosts-preserved
```

**You should see** `hosts-preserved` match the original's mode, owner, and timestamp. `hosts-plain` has a fresh timestamp and your umask-derived permissions.

| Flag | Meaning |
| --- | --- |
| `cp src dst` | Copy a file |
| `cp -r srcdir dstdir` | Recursive directory copy |
| `cp -p` | Preserve mode, ownership, timestamps |
| `cp -a` | Archive: `-r` plus preserve **everything**, including SELinux |
| `cp -i` | Prompt before overwrite |

When a task says "copy these files preserving permissions", it means `-a` or `-p`.

```bash
cp -r /tmp/lab01/docs /tmp/lab01/docs-copy
ls /tmp/lab01/docs-copy
```

**You should see** the five reports inside `docs-copy`.

### 8. The SELinux copy versus move trap

```bash
ls -Z /etc/hosts
cp /etc/hosts /tmp/lab01/hosts-inherited
cp -a /etc/hosts /tmp/lab01/hosts-archive
ls -Z /tmp/lab01/hosts-inherited /tmp/lab01/hosts-archive
```

**You should see** the plain `cp` pick up a context from `/tmp` (destination). `cp -a` keeps the source context.

| Command | Resulting SELinux context |
| --- | --- |
| `cp file /new/path` | **Inherits from the destination directory** |
| `cp -a file /new/path` | Preserves the source's context |
| `mv file /new/path` | **Keeps the original context**, which is often wrong for the new location |

This is why moving a file into `/var/www/html` breaks Apache while copying it works. Covered fully in `27-selinux.md`.

### 9. Move, rename, and delete

```bash
mv /tmp/lab01/empty.txt /tmp/lab01/renamed.txt
ls /tmp/lab01/renamed.txt
mv /tmp/lab01/renamed.txt /tmp/lab01/docs/
ls /tmp/lab01/docs/renamed.txt
```

**You should see** the file renamed, then sitting under `docs/`. `mv` is rename and move.

```bash
rm /tmp/lab01/docs/renamed.txt
rmdir /tmp/lab01/one-level
rm -r /tmp/lab01/docs-copy
ls /tmp/lab01
```

**You should see** `renamed.txt` gone, `one-level` gone, `docs-copy` gone. `rmdir` only removes **empty** directories. Use `rm -r` otherwise. `rm -rf` is force plus recursive — be careful.

### 10. Wildcards are expanded by the shell

```bash
touch /tmp/lab01/{a,b,c}.conf
ls /tmp/lab01/*.conf
ls /tmp/lab01/file?.txt 2>/dev/null || echo "no match for ?"
ls /tmp/lab01/report[12].txt
ls /tmp/lab01/report[1-3].txt
```

**You should see** `a.conf b.conf c.conf`, then no `file?.txt` (you never created those), then `report1.txt report2.txt`, then reports 1–3.

| Pattern | Matches |
| --- | --- |
| `*` | any characters |
| `?` | exactly one character |
| `[12]` | one character from the set |
| `[1-3]` | a range |
| `[!1]` | not 1 |

Wildcards are expanded by the **shell**, not the command. That is why this fails when matching files exist in the current directory:

```bash
cd /tmp/lab01/docs
find . -name *.txt          # shell expands *.txt first — often wrong
find . -name '*.txt'        # quoted: find gets the pattern. CORRECT
cd
```

**You should see** the quoted form list every `.txt`. Always quote patterns you pass to `find`.

### 11. Find files by name

```bash
find /tmp/lab01 -name "*.txt"
find /tmp/lab01 -iname "*.TXT"
find /tmp/lab01 -type d
find /tmp/lab01 -type f -maxdepth 1
```

**You should see** the report files (and any other `.txt`), the same with `-iname` (case-insensitive), then only directories, then only files in `/tmp/lab01` itself (no recurse past depth 1).

`find` needs `sudo` when searching system paths, or you drown in "Permission denied". Redirect those away when you do not care:

```bash
sudo find /etc -name "*.conf" 2>/dev/null | head
```

**You should see** `.conf` paths under `/etc` with no permission noise.

### 12. Find by size, time, and owner

```bash
find /tmp/lab01 -type f -size -1k
sudo find /var/log -type f -mtime -7 2>/dev/null | head
sudo find /home -type f -mmin -30 2>/dev/null | head
```

**You should see** the small lab files, then log files modified in the last 7 days, then anything under `/home` touched in the last 30 minutes (maybe empty on a fresh VM).

| Test | Meaning |
| --- | --- |
| `-size +10M` | larger than 10 MB |
| `-size -1k` | smaller than 1 KB |
| `-mtime -7` | modified in the last 7 days |
| `-mtime +7` | older than 7 days |
| `-mtime 7` | **exactly** 7 days — almost never what you want |
| `-mmin -30` | modified in the last 30 minutes |
| `-user alice` | owned by alice |
| `-group devs` | owned by group devs |

### 13. Find by permissions — SUID needs the leading `-`

```bash
sudo find /usr -type f -perm -4000 2>/dev/null | head
```

**You should see** a handful of SUID binaries (`passwd`, `sudo`, and similar).

`-perm -4000` means "has **at least** the SUID bit". `-perm 4000` would mean "has SUID and no other permission bits at all", which matches nothing. The leading `-` is the whole trick.

Same pattern: `-perm -2000` for SGID, `-perm -1000` for sticky.

Write the list to a root-owned file:

```bash
sudo find /usr -type f -perm -4000 2>/dev/null | sudo tee /tmp/lab01/suid-sample.txt | wc -l
```

**You should see** a line count, and the file contains the paths. Note `sudo tee` rather than `> /root/...`. The redirection is performed by your **shell**, which is not root, so `sudo find ... > /root/file` fails with permission denied. This trips people up constantly. See `02-redirection-pipes.md`.

### 14. `-exec`, `-delete`, and left-to-right tests

```bash
find /tmp/lab01 -type f -name "*.conf" -exec ls -l {} \;
find /tmp/lab01 -type f -name "*.conf" -exec ls -l {} +
```

**You should see** the same three `.conf` files. `\;` runs `ls` once per file. `+` batches them into as few invocations as possible — much faster.

```bash
find /tmp/lab01 -type f -name "*.conf" -delete
ls /tmp/lab01/*.conf 2>/dev/null || echo "conf files gone"
find /tmp/lab01
```

**You should see** the `.conf` files gone and the directory tree still there.

`-type f` is essential. Without it, `-delete` would also try to remove matching directories. Put `-delete` **last**; `find` applies tests left to right, and `find /srv -delete -name '*.txt'` deletes everything before the name test is ever considered.

### 15. History and keyboard shortcuts

```bash
history | tail
echo "practice argument"
echo !$
```

**You should see** numbered history, then `practice argument` printed twice. `!$` is the last argument of the previous command.

Type these until they are reflexes. Do not skip them because they look like "just shortcuts":

| Key / bang | Does |
| --- | --- |
| `Ctrl+r` | reverse search history. **USE THIS** |
| `!!` | rerun the last command |
| `sudo !!` | rerun the last command with sudo |
| `!123` | rerun command 123 from history |
| `Tab` / `Tab Tab` | complete / show all completions |
| `Ctrl+a` / `Ctrl+e` | start / end of line |
| `Ctrl+u` / `Ctrl+k` | delete to start / end of line |
| `Ctrl+w` | delete previous word |
| `Ctrl+l` | clear screen |
| `Ctrl+c` | kill the running command |
| `Ctrl+d` | EOF / logout |
| `Ctrl+z` | suspend, then `fg` or `bg` |

`Ctrl+r` and `sudo !!` are the two biggest per-minute time savers on a timed hands-on exam.

### 16. Read files without an editor

```bash
head -n 5 /etc/passwd
tail -n 5 /etc/passwd
wc /etc/services
file /bin/ls
stat /etc/passwd
```

**You should see** the first five and last five passwd lines, then **lines, words, bytes** for `/etc/services`, then `file` saying `/bin/ls` is an ELF executable, then `stat` with three timestamps.

`stat` is the tool for "when was this changed" questions:

| Field | Meaning | Changed by |
| --- | --- | --- |
| **Access** | Last read | `cat`, `less` |
| **Modify** | Contents last changed | Editing, appending |
| **Change** | **Inode** last changed | Editing, **and also** `chmod`, `chown`, renaming |

So `chmod` updates Change but not Modify. That distinction is what "when was this file's permission last altered" questions are testing.

Other readers you will use constantly:

```bash
cat -n /etc/hosts | head        # whole file with line numbers
# less /var/log/messages        # pager: / search, n next, q quit, G end, g start
# tail -f /var/log/messages     # follow. Ctrl+c to stop
```

### Mini checkpoint

Before the practice tasks, you should be able to explain:

| Command / idea | Does |
| --- | --- |
| `ls -ld` | the directory itself, not its contents |
| `ls -ltr` | oldest first, newest at the bottom |
| `mkdir -p` | create parents, no error if exists |
| `cp -p` / `cp -a` | preserve perms (and SELinux, for `-a`) |
| `cp file{,.bak}` | one-command backup |
| `find -perm -4000` | SUID — the leading `-` is required |
| `sudo cmd \| sudo tee file` | write to a root-owned file |
| `stat` | Access vs Modify vs Change |

If any row is blank in your head, re-run the step above that covers it.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

Work on `server1`. Prefer `/srv/project` as specified — you will need `sudo`.

**Task 1.** Create the directory tree `/srv/project/{docs,src,build}` in a single command.

> Hint: `mkdir -p` and brace expansion from follow-along steps 5 and 6.

**Task 2.** Inside `/srv/project/docs`, create five files named `report1.txt` through `report5.txt` in a single command.

> Hint: `touch` with `{1..5}` from step 5.

**Task 3.** Copy `/etc/hosts` to `/srv/project/docs/hosts.bak` preserving its permissions, ownership, and timestamps. Prove they were preserved.

> Hint: `cp -p` and `stat` from steps 7 and 16.

**Task 4.** Find every file under `/etc` whose name ends in `.conf` and that was modified in the last 30 days. Suppress permission errors.

> Hint: `-name`, `-mtime -30`, and `2>/dev/null` from steps 11 and 12.

**Task 5.** Find all files on the system with the SUID bit set, and write the list to `/root/suid-files.txt`.

> Hint: `-perm -4000` and `sudo tee` from step 13. Do not use `sudo find ... > /root/...`.

**Task 6.** Report how many lines, words, and bytes are in `/etc/services`.

> Hint: `wc` from step 16.

**Task 7.** Show the details of the `/etc/ssh` directory itself, not its contents, including its SELinux context.

> Hint: `ls -ldZ` from step 3.

**Task 8.** Create a backup of `/etc/fstab` named `/etc/fstab.bak` using brace expansion, in one short command.

> Hint: the `file{,.bak}` idiom from step 6.

**Task 9.** List the ten most recently modified files in `/var/log`, newest last.

> Hint: `ls -ltr` and `tail` from steps 2 and 16.

**Task 10.** Find all files under `/home` larger than 1 MB owned by a user other than root, and show them in long format.

> Hint: `-size +1M`, `! -user root`, `-exec ls -lh {} +` from steps 12 and 14.

**Task 11.** Determine the exact access, modify, and change timestamps of `/etc/passwd`.

> Hint: `stat` from step 16.

**Task 12.** Delete every `.txt` file under `/srv/project` but leave the directory structure intact.

> Hint: `find -type f -name '*.txt' -delete` from step 14. `-delete` last.

---

## Solutions

**Task 1.**

```bash
sudo mkdir -p /srv/project/{docs,src,build}
ls -R /srv/project
```

`-p` does two things: creates missing parents, and does not error if the target already exists. Always use it.

**Task 2.**

```bash
sudo touch /srv/project/docs/report{1..5}.txt
ls /srv/project/docs
```

`{1..5}` is a sequence expansion. `{a..e}` works for letters, and `{01..10}` zero-pads.

**Task 3.**

```bash
sudo cp -p /etc/hosts /srv/project/docs/hosts.bak
ls -l /etc/hosts /srv/project/docs/hosts.bak
stat -c '%a %U:%G %y' /etc/hosts /srv/project/docs/hosts.bak
```

Both `stat` lines must match. Without `-p`, the copy gets the current time and your umask-derived permissions. `cp -a` would also work and additionally preserves the SELinux context.

**Task 4.**

```bash
sudo find /etc -name "*.conf" -mtime -30 2>/dev/null
```

`-mtime -30` means "less than 30 days ago". `-mtime +30` means "more than 30 days ago". `-mtime 30` means "exactly 30 days ago", which is almost never what you want.

**Task 5.**

```bash
sudo find / -type f -perm -4000 2>/dev/null | sudo tee /root/suid-files.txt
sudo wc -l /root/suid-files.txt
sudo head /root/suid-files.txt
```

`-perm -4000` means "has at least the SUID bit". `-perm 4000` would mean "has SUID and no other permission bits at all", which matches nothing.

Note `sudo tee` rather than `> /root/...`. The redirection is performed by your shell, which is not root, so `sudo find ... > /root/file` fails with permission denied. See `02-redirection-pipes.md`.

**Task 6.**

```bash
wc /etc/services
```

Output order is **lines, words, bytes**. For one at a time, use `wc -l`, `wc -w`, `wc -c`.

**Task 7.**

```bash
ls -ldZ /etc/ssh
```

`-d` describes the directory rather than listing it. `-Z` adds the SELinux context. Without `-d` you get every file inside instead.

**Task 8.**

```bash
sudo cp /etc/fstab{,.bak}
ls -l /etc/fstab.bak
```

This expands to `cp /etc/fstab /etc/fstab.bak`. Build the habit now: back up every system file before you edit it. On the exam, a mangled `/etc/fstab` with no backup is how a small mistake becomes an unbootable machine.

**Task 9.**

```bash
ls -ltr /var/log | tail -n 10
```

`-t` sorts by time newest first, `-r` reverses it so newest ends up last, and `tail` takes that end. This is the standard idiom for "what changed most recently".

**Task 10.**

```bash
sudo find /home -type f -size +1M ! -user root -exec ls -lh {} +
```

`!` negates the next test. `-size +1M` is "larger than 1 MB". Using `-exec ... +` batches results into as few `ls` invocations as possible, which is much faster than `\;` running one per file.

**Task 11.**

```bash
stat /etc/passwd
```

Three timestamps, and knowing which is which is the point. `chmod` updates **Change** but not **Modify**.

**Task 12.**

```bash
sudo find /srv/project -type f -name "*.txt" -delete
find /srv/project
```

`-type f` is essential. Without it, `-delete` would also try to remove matching directories. Put `-delete` last.

---

## Verify

```bash
ls -R /srv/project
sudo wc -l /root/suid-files.txt
ls -l /etc/fstab.bak
ls -ldZ /etc/ssh
```

## Persistence Check

Nothing in this file needs to survive a reboot; these are filesystem operations that are already on disk. Two habits from this file protect everything that does:

```bash
# Back up config files BEFORE editing
sudo cp /etc/fstab{,.bak}

# sudo command > /root/file does NOT work. The shell opens the file, not sudo.
sudo find / -type f -perm -4000 2>/dev/null | sudo tee /root/suid-files.txt
```

## Quick Reference

Come back here when you need a flag you forgot — not before your first pass through Follow Along.

### Navigation and listing

```bash
pwd                     # print working directory
cd /etc                 # absolute path
cd ../..                # relative, up two levels
cd                      # home directory
cd -                    # PREVIOUS directory. Toggles
cd ~alice               # alice's home directory

ls                      # plain
ls -l                   # long: perms, links, owner, group, size, mtime, name
ls -a                   # include dotfiles
ls -la                  # both, the one you will type most
ls -lh                  # human-readable sizes
ls -ld /etc             # the DIRECTORY itself, not its contents
ls -lt                  # newest first
ls -ltr                 # oldest first, newest at the BOTTOM. Best for logs
ls -lR                  # recursive
ls -li                  # show inode numbers
ls -lZ                  # show SELinux context
ls -ldZ /etc/ssh        # directory itself + SELinux context
```

### Create, copy, move, delete

```bash
touch file.txt                   # create empty, or update mtime
mkdir dir                        # one level
mkdir -p /a/b/c/d                # create parents as needed
mkdir -p /srv/{dev,test,prod}    # brace expansion: three directories at once

cp src dst                       # copy a file
cp -r srcdir dstdir              # copy a directory, recursively
cp -p src dst                    # PRESERVE mode, ownership, timestamps
cp -a srcdir dstdir              # archive: -r plus preserve everything, incl. SELinux
cp -i src dst                    # prompt before overwrite
cp file1 file2 file3 /dest/      # many into a directory
cp file.txt{,.bak}               # copy to file.txt.bak

mv old new                       # rename
mv file /other/dir/              # move
mv -i old new                    # prompt

rm file                          # delete
rm -f file                       # force, no prompt, no error if absent
rm -r dir                        # recursive
rm -rf dir                       # both. Be careful
rmdir dir                        # only removes EMPTY directories
```

### Brace, tilde, and wildcards

```bash
touch file{1..5}.txt             # file1.txt ... file5.txt
touch {a,b,c}.conf               # a.conf b.conf c.conf
mkdir -p /srv/{web,db}/{conf,data}
cp file.txt{,.bak}               # copy to file.txt.bak

echo ~                           # /home/you
echo ~root                       # /root

ls *.conf                        # any characters
ls file?.txt                     # exactly one character
ls file[12].txt                  # one char from the set
ls file[1-3].txt                 # a range
ls file[!1].txt                  # NOT 1
```

Quote wildcards passed to `find`: `-name '*.conf'`.

### find

```bash
find /etc -name "*.conf"                 # by name, case-sensitive
find /etc -iname "*.CONF"                # case-insensitive
find / -type d -name "log"               # directories only
find /home -type f -size +10M            # larger than 10 MB
find /home -type f -size -1k             # smaller than 1 KB
find /var -mtime -7                      # modified in the last 7 days
find /var -mmin -30                      # modified in the last 30 minutes
find / -user alice                       # owned by alice
find / -group devs
find / -perm 0644                        # exactly these bits
find / -perm -0644                       # at least these bits
find / -perm /u+s                        # any of these bits: finds SUID files
find / -perm -4000 -type f               # SUID, the classic audit query
find /tmp -type f -name "*.log" -delete
find /tmp -type f -exec ls -l {} \;      # run a command per result
find /tmp -type f -exec ls -l {} +       # batch them, much faster
find /etc -maxdepth 1 -type f            # do not recurse
find / -nouser -o -nogroup               # orphaned files
find /etc -name "*.conf" 2>/dev/null     # hide permission denied

locate passwd                            # fast, uses a database
sudo updatedb                            # refresh that database first
```

### History and line editing

```bash
history                          # numbered command history
!123                             # rerun command 123
!!                               # rerun the last command
sudo !!                          # rerun the last command with sudo
!$                               # last argument of the previous command
```

`Ctrl+r` reverse-search history. `Tab` complete. `Ctrl+a`/`Ctrl+e` start/end of line. `Ctrl+u`/`Ctrl+k` delete to start/end. `Ctrl+w` delete previous word. `Ctrl+l` clear. `Ctrl+c` kill. `Ctrl+d` EOF. `Ctrl+z` suspend.

### Reading files

```bash
cat file                         # whole file
cat -n file                      # with line numbers
tac file                         # reversed
less file                        # pager: / to search, n next, q quit, G end, g start
head file                        # first 10 lines
head -n 5 file
tail file                        # last 10 lines
tail -n 20 file
tail -f /var/log/messages        # follow. Ctrl+c to stop
wc -l file                       # line count
wc -w file                       # word count
wc -c file                       # byte count
wc file                          # lines, words, bytes
file /bin/ls                     # what kind of file is this
stat file                        # inode, size, all three timestamps, perms
stat -c '%a %U:%G %y' file       # mode, owner:group, modify time
```

## Exam Tips

- **`ls -ld`** for a directory itself. **`ls -lZ`** for SELinux context. **`ls -ltr`** for recent changes.
- Position 11 of `ls -l`: **`.` means SELinux context, `+` means an ACL exists.** The `+` is your first clue in permission-diagnosis tasks.
- **`mkdir -p`** always. **`cp -a`** or **`cp -p`** when permissions or ownership must be preserved.
- **`cp` inherits the destination's SELinux context. `mv` keeps the original's.** This causes real breakage; see `27-selinux.md`.
- **`cp file{,.bak}`** to back up before editing. Do it every time.
- `find -perm -4000` needs the leading **`-`** to mean "at least these bits".
- `-mtime -7` is "within 7 days", `+7` is "older than 7 days".
- Quote wildcards passed to `find`: **`-name '*.conf'`**, because the shell would otherwise expand them first.
- `-exec ... +` is much faster than `-exec ... \;`.
- **`sudo cmd > /root/file` fails.** Use `sudo cmd | sudo tee /root/file`.
- `stat` shows three timestamps. **`chmod` changes Change time, not Modify time.**
- **`Ctrl+r`** to search history and **`sudo !!`** to rerun with privilege. These save real minutes.
- `rmdir` only removes empty directories. Use `rm -r` otherwise.
- Put **`-delete` last** on `find`, and always add **`-type f`** when you mean files only.
