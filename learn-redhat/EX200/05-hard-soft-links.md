# 05. Hard And Soft Links

**Objective:** Create hard and soft links.

A small objective, but it appears as a quick task and the conceptual difference is examinable. Get the distinction exactly right and this is free points.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Hard versus soft links click the moment you delete the original and see what survives.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Create a file and two links

```bash
echo hello > /tmp/original.txt
ln /tmp/original.txt /tmp/hard.txt
ln -s /tmp/original.txt /tmp/soft.txt
ls -l /tmp/original.txt /tmp/hard.txt /tmp/soft.txt
```

**You should see:**

- `original.txt` and `hard.txt`: regular files (`-`), link count **2**
- `soft.txt`: type **`l`**, arrow `-> /tmp/original.txt`, link count **1**

`ln` without `-s` creates a **hard link** — another name for the same inode. `ln -s` creates a **soft link** (symlink) — a separate file containing a path string.

### 2. Compare inode numbers

```bash
ls -li /tmp/original.txt /tmp/hard.txt /tmp/soft.txt
```

**You should see** `original.txt` and `hard.txt` share the **same inode number**. `soft.txt` has a different inode.

Same inode = same file with two names. There is no "original" at the filesystem level.

### 3. Write through the hard link

```bash
echo second >> /tmp/hard.txt
cat /tmp/original.txt
cat /tmp/soft.txt
```

**You should see** both lines in all three paths. Writing through any hard link name writes to the same data blocks.

### 4. Delete the original — the key experiment

```bash
rm /tmp/original.txt
cat /tmp/hard.txt
cat /tmp/soft.txt
ls -l /tmp/hard.txt /tmp/soft.txt
```

**You should see:**

- `hard.txt` still works — data remains while any hard link exists
- `soft.txt` fails with "No such file or directory" — it stored the path string, which no longer resolves

This is the single most examined fact about links.

### 5. Hard links cannot cross filesystems

```bash
df /etc /tmp
ln /etc/hosts /tmp/hosts-hard 2>&1 || true
```

**You should see** either success (if `/etc` and `/tmp` share a filesystem) or:

```text
ln: failed to create hard link '/tmp/hosts-hard' => '/etc/hosts': Invalid cross-device link
```

Inode numbers are only unique within one filesystem. Hard links cannot span them. Try `/boot` if `/tmp` is on the same filesystem as `/etc`:

```bash
ln /etc/hosts /boot/hosts-hard 2>&1 || true
```

### 6. Hard links cannot point to directories

```bash
ln /etc /tmp/etc-hard 2>&1 || true
```

**You should see:**

```text
ln: /etc: hard link not allowed for directory
```

Linux forbids this to prevent directory-tree cycles. Use a symlink for directories.

### 7. Symlink to a directory

```bash
ln -s /etc/ssh /tmp/etcssh
ls -l /tmp/etcssh
ls /tmp/etcssh/
```

**You should see** the link and a listing of `sshd_config` and friends through it.

Soft links can cross filesystems and can point to directories. **`ls -l /tmp/etcssh`** describes the link; **`ls /tmp/etcssh/`** lists the target's contents.

### 8. Inspect and resolve symlinks

```bash
readlink /tmp/soft.txt
readlink -f /tmp/etcssh
realpath /tmp/etcssh
```

**You should see** the stored path from `readlink`, and the fully resolved target from `readlink -f` and `realpath`.

`readlink` shows one level. `readlink -f` and `realpath` follow the whole chain.

### 9. Find broken symlinks

```bash
find /tmp -xtype l
```

**You should see** `/tmp/soft.txt` — its target was deleted in step 4.

`-xtype l` finds links whose target does not resolve. Plain `-type l` finds all symlinks, broken or not.

### 10. System symlinks you already use

```bash
ls -l /etc/systemd/system/default.target
readlink -f /etc/systemd/system/default.target
```

**You should see** a symlink pointing at something like `multi-user.target` or `graphical.target`.

**`systemctl enable` creates a symlink** in a `.wants` directory. That is literally what enablement is.

### 11. Replace a symlink in one command

```bash
ln -sf /etc/hostname /tmp/soft.txt
readlink /tmp/soft.txt
```

**You should see** `/etc/hostname`. `-f` removes the existing link first.

### 12. Multiple hard links to one file

```bash
echo data > /tmp/multi.txt
ln /tmp/multi.txt /tmp/l1
ln /tmp/multi.txt /tmp/l2
ls -li /tmp/multi.txt /tmp/l1 /tmp/l2
stat -c '%h %i %n' /tmp/multi.txt
```

**You should see** link count **3** (original plus two links), all sharing one inode.

### Mini checkpoint

Before the practice tasks, you should be able to fill in:

| | Hard link | Soft link |
| --- | --- | --- |
| Command | `ln target link` | `ln -s target link` |
| Survives deleting original | **Yes** | **No** |
| Cross filesystems | **No** | **Yes** |
| Link to directory | **No** | **Yes** |
| `ls -l` type | `-` | **`l`** |

If any cell is blank, re-run the step above that covers it.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Create the file `/tmp/original.txt` containing the text `hello`. Create a hard link to it at `/tmp/hard.txt` and a soft link at `/tmp/soft.txt`.

> Hint: follow-along step 1 — `ln` versus `ln -s`.

**Task 2.** Show the inode numbers of all three files and state which two share an inode.

> Hint: `ls -li` from step 2.

**Task 3.** Append the line `second` to `/tmp/hard.txt`, then display `/tmp/original.txt`. Explain the result.

> Hint: same inode, same data — step 3.

**Task 4.** Delete `/tmp/original.txt`. Show which of the two links still works and which does not.

> Hint: the key experiment from step 4.

**Task 5.** Attempt to create a hard link from `/etc/hosts` to a file on a different filesystem. Record the exact error.

> Hint: check filesystems with `df`; try `/boot` — step 5.

**Task 6.** Attempt to create a hard link to the directory `/etc`. Record the exact error.

> Hint: step 6.

**Task 7.** Create a symbolic link at `/tmp/etcssh` pointing to the directory `/etc/ssh`, and list the target's contents through the link.

> Hint: step 7.

**Task 8.** Find all broken symbolic links under `/tmp`.

> Hint: `find -xtype l` from step 9.

**Task 9.** Determine what `/etc/systemd/system/default.target` points to, using two different commands.

> Hint: `ls -l` and `readlink -f` from step 10.

**Task 10.** Create `/tmp/chain1` pointing to `/tmp/chain2`, which points to `/etc/hostname`. Fully resolve `/tmp/chain1` to its final target.

> Hint: build the chain with two `ln -s`; resolve with `readlink -f`.

**Task 11.** Create a file `/tmp/multi.txt` with three hard links named `/tmp/l1`, `/tmp/l2`, `/tmp/l3`. Show that the link count is 4 and find every name pointing to that inode.

> Hint: step 12; use `find -samefile` or `find -inum`.

**Task 12.** Replace an existing symlink `/tmp/soft.txt` so it points to `/etc/hostname` instead, in a single command.

> Hint: `ln -sf` from step 11.

---

## Solutions

**Task 1.**

```bash
echo hello > /tmp/original.txt
ln /tmp/original.txt /tmp/hard.txt
ln -s /tmp/original.txt /tmp/soft.txt
ls -l /tmp/original.txt /tmp/hard.txt /tmp/soft.txt
```

Expected `ls -l` output shape:

```text
-rw-r--r--. 2 you you  6 Aug 18 14:00 /tmp/hard.txt
-rw-r--r--. 2 you you  6 Aug 18 14:00 /tmp/original.txt
lrwxrwxrwx. 1 you you 18 Aug 18 14:00 /tmp/soft.txt -> /tmp/original.txt
```

Note the link count of **2** on the first two, the type `l` on the symlink, and that the symlink's size (18) is the character length of the path it stores, not the size of the file.

**Task 2.**

```bash
ls -li /tmp/original.txt /tmp/hard.txt /tmp/soft.txt
```

`/tmp/original.txt` and `/tmp/hard.txt` share the same inode number. `/tmp/soft.txt` has its own. Same inode means they are the same file with two names; there is no "original" among them at the filesystem level.

**Task 3.**

```bash
echo second >> /tmp/hard.txt
cat /tmp/original.txt
```

Both lines appear. Writing through either name writes to the same inode and therefore the same data blocks. There is no copy involved.

**Task 4.**

```bash
rm /tmp/original.txt
cat /tmp/hard.txt      # works: hello / second
cat /tmp/soft.txt      # fails: No such file or directory
ls -l /tmp/hard.txt /tmp/soft.txt
```

`/tmp/hard.txt` still works because the inode's link count only dropped from 2 to 1; data is freed only when the count reaches 0 and no process holds it open. `/tmp/soft.txt` is now dangling because it stores the string `/tmp/original.txt`, which no longer resolves.

This is the single most examined fact about links.

**Task 5.**

```bash
df /etc /tmp                       # confirm they are different filesystems first
ln /etc/hosts /tmp/hosts-hard
```

Error:

```text
ln: failed to create hard link '/tmp/hosts-hard' => '/etc/hosts': Invalid cross-device link
```

If `/tmp` is on the same filesystem as `/etc` on your lab box, the command succeeds. Use a separate mount to reproduce it:

```bash
df -h                              # find a genuinely separate mount
ln /etc/hosts /boot/hosts-hard     # /boot is normally its own filesystem
```

The message to remember is **"Invalid cross-device link"**. Hard links cannot span filesystems because an inode number only identifies a file within one filesystem.

**Task 6.**

```bash
ln /etc /tmp/etc-hard
```

Error:

```text
ln: /etc: hard link not allowed for directory
```

Linux forbids this outright. Allowing it would let you create cycles in the directory tree, which would break tree-walking tools and reference counting. Use a symlink for directories.

**Task 7.**

```bash
ln -s /etc/ssh /tmp/etcssh
ls -l /tmp/etcssh
ls /tmp/etcssh/
```

The link resolves transparently, so `ls /tmp/etcssh/` lists `sshd_config` and friends. Note the trailing slash difference:

```bash
ls -l /tmp/etcssh      # describes the LINK
ls -l /tmp/etcssh/     # lists the TARGET's contents
```

Same distinction as `ls -ld` in `01-shell-fundamentals.md`.

**Task 8.**

```bash
find /tmp -xtype l
```

`-xtype l` finds links whose target does not resolve. Plain `-type l` finds all symlinks, broken or not. After Task 4, `/tmp/soft.txt` should appear here.

**Task 9.**

```bash
ls -l /etc/systemd/system/default.target
readlink -f /etc/systemd/system/default.target
```

Both show it pointing at `/usr/lib/systemd/system/multi-user.target` (or `graphical.target`). This is exactly what `systemctl get-default` reports and what `systemctl set-default` rewrites — the "default target" is a symlink, nothing more. See `15-systemd-targets-boot.md`.

**Task 10.**

```bash
ln -s /etc/hostname /tmp/chain2
ln -s /tmp/chain2 /tmp/chain1

readlink /tmp/chain1        # /tmp/chain2       — one level only
readlink -f /tmp/chain1     # /etc/hostname     — fully resolved
realpath /tmp/chain1        # /etc/hostname
cat /tmp/chain1             # the hostname: chains resolve transparently
```

`readlink` without `-f` shows only the immediate target. `readlink -f` and `realpath` follow the whole chain. Symlink chains work but are fragile; anything in the middle breaking breaks the whole path.

**Task 11.**

```bash
echo data > /tmp/multi.txt
ln /tmp/multi.txt /tmp/l1
ln /tmp/multi.txt /tmp/l2
ln /tmp/multi.txt /tmp/l3

ls -li /tmp/multi.txt /tmp/l1 /tmp/l2 /tmp/l3
stat -c '%h %i %n' /tmp/multi.txt
```

The link count is **4**: the original name plus three more. All four share one inode.

Find every name for that inode:

```bash
find /tmp -samefile /tmp/multi.txt
# or, by inode number
INODE=$(stat -c %i /tmp/multi.txt)
find /tmp -inum "$INODE"
```

`find -samefile` is easier and does not require you to look up the number first.

**Task 12.**

```bash
ln -sf /etc/hostname /tmp/soft.txt
readlink /tmp/soft.txt
```

`-f` removes the existing link first. Without `-f` you get `File exists`. Be careful: if the destination is a **regular file** rather than a link, `-f` deletes it.

A subtle trap: if the existing symlink points at a **directory**, `ln -sf target link` creates the new link *inside* that directory instead of replacing it. Use `-n` to prevent that:

```bash
ln -sfn /new/dir /tmp/dirlink
```

`-n` treats the existing symlink as a file rather than following it. Worth knowing, because the failure is silent and confusing.

---

## Verify

```bash
ls -li /tmp/multi.txt /tmp/l1 /tmp/l2 /tmp/l3
find /tmp -xtype l
readlink -f /tmp/chain1
ls -l /tmp/etcssh
```

## Persistence Check

Links are on-disk filesystem structures, so they survive a reboot automatically. Two related points do matter for later files:

- A symlink created on a filesystem that is not mounted at boot disappears with it. If a task says "create a link at `/mnt/data/link`", the mount must also be in `/etc/fstab`.
- **`systemctl enable` works by creating a symlink** in `/etc/systemd/system/<target>.wants/`. If you ever want to confirm a service really is enabled, you can look at that directory directly:

```bash
ls -l /etc/systemd/system/multi-user.target.wants/
```

## Quick Reference

Come back here when you need a fact you forgot — not before your first pass through Follow Along.

### What a file actually is

A filename is not a file. A filename is a **directory entry** pointing at an **inode**. The inode holds the metadata (permissions, owner, timestamps, size) and the pointers to the data blocks. The name is just a label in a directory.

```text
DIRECTORY ENTRY          INODE 12345              DATA BLOCKS
┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│ "file.txt"   │──────► │ perms, owner │──────► │  contents    │
│              │        │ links: 1     │        │              │
└──────────────┘        └──────────────┘        └──────────────┘
```

A **hard link** is a second directory entry pointing at the **same inode**:

```text
┌──────────────┐
│ "file.txt"   │──────┐
└──────────────┘      │   ┌──────────────┐        ┌──────────────┐
                      ├──►│ INODE 12345  │──────► │  contents    │
┌──────────────┐      │   │ links: 2     │        │              │
│ "hardlink"   │──────┘   └──────────────┘        └──────────────┘
└──────────────┘
```

A **soft link** (symbolic link, symlink) is a **separate file with its own inode** whose contents are a path string:

```text
┌──────────────┐        ┌──────────────┐
│ "softlink"   │──────► │ INODE 99999  │  contents: "file.txt"
└──────────────┘        │ type: link   │            │
                        └──────────────┘            │ resolved at access time
                                                    ▼
┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│ "file.txt"   │──────► │ INODE 12345  │──────► │  contents    │
└──────────────┘        └──────────────┘        └──────────────┘
```

### The comparison table to memorise

| | Hard link | Soft link (symlink) |
| --- | --- | --- |
| Command | `ln target linkname` | **`ln -s`** `target linkname` |
| Points to | The **inode** | A **path string** |
| Own inode | No, shares the target's | **Yes** |
| Cross filesystems | **No** | **Yes** |
| Link to a directory | **No** (only root, and not on Linux) | **Yes** |
| Survives the original being deleted | **Yes**, data remains | **No**, becomes a dangling link |
| Increments the link count | **Yes** | No |
| `ls -l` type character | `-` (same as a file) | **`l`** |
| Size shown | The file's size | The **length of the path string** |
| Can point to a nonexistent target | No | **Yes**, a dangling link |
| Permissions | The target's | Shows `lrwxrwxrwx`, but the target's apply |

The two limitations of hard links are the most examined facts: **they cannot cross filesystems and they cannot point to directories.** Both follow from the same reason — inode numbers are only unique within a single filesystem, and allowing hard-linked directories would permit loops in the directory tree.

### Creating links

```bash
# Hard link
ln /path/to/original /path/to/hardlink

# Soft link — DO NOT FORGET -s
ln -s /path/to/original /path/to/softlink

# Force: replace an existing link
ln -sf /new/target /path/to/link

# Link into a directory, keeping the same basename
ln -s /etc/hosts /tmp/          # creates /tmp/hosts

# Relative versus absolute target
ln -s /etc/hosts /tmp/abs-link      # absolute: survives moving the link
ln -s ../etc/hosts /tmp/rel-link    # relative: breaks if the link moves
```

**Always use an absolute path for the target** unless you have a specific reason not to. A relative symlink is resolved relative to the **link's own directory**, so moving the link breaks it.

### Inspecting links

```bash
ls -l file                    # link count is the number after the permissions
ls -li file                   # show the inode number
stat file                     # inode and link count, spelled out

readlink softlink             # what does this symlink say
readlink -f softlink          # fully resolve, following chains
realpath softlink             # same idea

find /path -type l            # find symlinks
find /path -xtype l           # find BROKEN symlinks
find / -inum 12345            # find every name for one inode (hard links)
find /path -samefile file     # find hard links to this file
```

### Where the system uses links

Recognising these helps in other tasks.

```bash
ls -l /etc/systemd/system/default.target       # symlink to a target unit
ls -l /etc/localtime                           # symlink into /usr/share/zoneinfo
ls -l /bin /lib /lib64 /sbin                   # symlinks into /usr on modern RHEL
ls -l /etc/systemd/system/multi-user.target.wants/   # symlinks: this is what `enable` creates
```

**`systemctl enable` creates a symlink** in a `.wants` directory. That is literally what enablement is, and it is why enablement persists across reboots while `start` does not. Knowing this makes `14-systemd-services.md` and `15-systemd-targets-boot.md` much clearer.

## Exam Tips

- **`ln` is hard, `ln -s` is soft.** Forgetting `-s` is the single most common mistake here.
- **Hard links cannot cross filesystems** — "Invalid cross-device link".
- **Hard links cannot point to directories** — "hard link not allowed for directory".
- Soft links can do both, and can point at something that does not exist yet.
- **Delete the original: the hard link still works, the soft link breaks.**
- `ls -l` shows **`l`** as the type for a symlink and `->` with the target. Hard links look exactly like ordinary files.
- The **link count** in `ls -l` is the number of hard links to that inode.
- A symlink's **size is the length of its target path string**.
- **`ls -li`** to compare inodes. Same inode means the same file.
- **`readlink`** shows one level; **`readlink -f`** and **`realpath`** fully resolve.
- **`find -xtype l`** finds broken links. `find -samefile X` finds hard links to X.
- **Use absolute paths as symlink targets.** Relative targets resolve from the link's directory.
- **`ln -sf`** replaces a link; add **`-n`** when the existing link points to a directory.
- `systemctl enable` is implemented as a symlink into a `.wants` directory.
