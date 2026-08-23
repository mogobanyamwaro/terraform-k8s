# 12. Special Permissions, Collaboration, And ACLs

**Objectives:** Create and configure set-GID directories for collaboration. Diagnose and correct file permission problems.

The set-GID collaborative directory is one of the most reliably predictable tasks on the exam. Learn the four-command recipe and it is free points.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Setting SGID on a directory once beats re-reading the permission table three times.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Meet the three special bits

```bash
ls -l /usr/bin/passwd
ls -ld /tmp
```

**You should see** `-rwsr-xr-x` on `passwd` (SUID in the user slot) and `drwxrwxrwt` on `/tmp` (sticky in the other slot).

SUID, SGID, and sticky are three extra permission bits. They appear as `s` or `t` where execute would normally be.

### 2. Read SUID on a real binary

```bash
ls -l /usr/bin/passwd
stat -c '%a %A %U:%G %n' /usr/bin/passwd
```

**You should see** mode `4755` or `-rwsr-xr-x`, owned by `root`.

SUID on a **file** means any user who runs it executes with the **file owner's** effective UID. That is why ordinary users can change passwords — `passwd` runs as root long enough to write `/etc/shadow`.

### 3. Read the sticky bit on `/tmp`

```bash
ls -ld /tmp
```

**You should see** `drwxrwxrwt` — world-writable with a **`t`** in the other slot.

`/tmp` must be writable by everyone, but without the sticky bit any user could delete anyone else's files. The sticky bit restricts deletion to the file owner, the directory owner, or root.

### 4. Set special bits with `chmod`

```bash
sudo mkdir -p /tmp/special-demo
sudo chmod 2770 /tmp/special-demo
ls -ld /tmp/special-demo
```

**You should see** `drwxrws---` — a lowercase **`s`** in the group slot (SGID).

Numeric form uses a **fourth leading digit**: SUID `4`, SGID `2`, sticky `1`. So `2770` is SGID plus `rwxrwx---`.

Remove it when done:

```bash
sudo chmod 0750 /tmp/special-demo
```

### 5. Spot capital `S` and `T` — usually mistakes

```bash
sudo cp /bin/cat /tmp/mycat
sudo chmod 4755 /tmp/mycat
ls -l /tmp/mycat
sudo chmod u-x /tmp/mycat
ls -l /tmp/mycat
```

**You should see** lowercase `s` first, then capital **`S`** after you remove execute.

A capital `S` or `T` means the special bit is set but the corresponding execute bit is not — almost always wrong on a binary, though expected on `other` for some sticky directories.

```bash
sudo rm -f /tmp/mycat
```

### 6. Build the collaborative directory — steps 1–3

```bash
sudo groupadd devs 2>/dev/null || true
sudo useradd alice 2>/dev/null; sudo useradd bob 2>/dev/null
sudo usermod -aG devs alice
sudo usermod -aG devs bob

sudo mkdir -p /shared/devs
sudo chgrp devs /shared/devs
ls -ld /shared/devs
```

**You should see** the directory owned by `root:devs`.

The recipe is four steps: **group, members, `chgrp`, `chmod`**. You are halfway there.

### 7. Apply SGID — step 4 of the recipe

```bash
sudo chmod 2770 /shared/devs
ls -ld /shared/devs
```

**You should see** `drwxrws---` with group `devs`.

SGID on a **directory** makes **new files inherit the directory's group**, not the creator's primary group. That is the entire point of the collaborative-directory task.

### 8. Prove group inheritance

```bash
sudo -u alice touch /shared/devs/alicefile
ls -l /shared/devs/alicefile
sudo -u bob sh -c 'echo bob >> /shared/devs/alicefile'
cat /shared/devs/alicefile
```

**You should see** owner `alice`, group **`devs`** (not `alice`), and bob's line appended.

Without SGID, alice's file would belong to group `alice` and bob could not write to it.

### 9. Add the sticky bit when members must not delete each other's files

```bash
sudo chmod 3770 /shared/devs
ls -ld /shared/devs
sudo -u bob rm /shared/devs/alicefile
```

**You should see** a capital **`T`** at the end (sticky without other-execute — correct here), and bob's `rm` fails with `Operation not permitted`.

Write permission on a directory normally lets any member delete **any** file inside it. Sticky changes that rule.

```bash
sudo -u alice touch /shared/devs/alicefile
```

### 10. Grant an ACL to one user outside the group

```bash
sudo useradd carol 2>/dev/null
sudo touch /shared/devs/notes.txt
sudo chgrp devs /shared/devs/notes.txt
sudo setfacl -m u:carol:rw /shared/devs/notes.txt
getfacl /shared/devs/notes.txt
ls -l /shared/devs/notes.txt
```

**You should see** a `user:carol:rw-` entry in `getfacl` and a **`+`** at the end of the `ls -l` mode.

The `+` tells you an ACL exists — the first thing to look for in a diagnosis task.

Carol still cannot read the file yet:

```bash
sudo -u carol cat /shared/devs/notes.txt
```

### 11. ACL on a file is useless without path traversal

```bash
sudo setfacl -m u:carol:rx /shared/devs
sudo -u carol cat /shared/devs/notes.txt
```

**You should see** the file contents — it works now.

An ACL on a file does nothing if the user cannot traverse every directory above it. Same principle as `namei -l`.

### 12. Default ACLs beat umask

```bash
sudo setfacl -m d:g:devs:rw /shared/devs
sudo touch /shared/devs/rootfile
getfacl /shared/devs/rootfile
```

**You should see** `group:devs:rw-` on a file root created — despite root's `022` umask producing `644` without the default ACL.

Default ACLs (the `d:` prefix) apply to **newly created** files only. They are the robust answer when the task says group members must always be able to write.

### 13. Diagnose with `namei -l`

```bash
sudo mkdir -p /data/reports
sudo groupadd analysts 2>/dev/null || true
sudo usermod -aG analysts bob 2>/dev/null || true
sudo touch /data/reports/summary.txt
sudo chgrp analysts /data/reports/summary.txt
sudo chmod 644 /data/reports/summary.txt
sudo chmod 700 /data/reports

namei -l /data/reports/summary.txt
sudo -u bob cat /data/reports/summary.txt
```

**You should see** `drwx------` on `reports` in `namei` output, and bob gets `Permission denied` even though the file is `644` and he is in group `analysts`.

`namei -l` shows the mode of **every component** in a path. A missing `x` three levels up is instantly visible.

Fix it:

```bash
sudo chmod 755 /data/reports
sudo -u bob cat /data/reports/summary.txt
```

### 14. When even root cannot delete — check attributes

```bash
sudo touch /root/locked.txt
sudo chattr +i /root/locked.txt
sudo rm -f /root/locked.txt
sudo lsattr /root/locked.txt
sudo chattr -i /root/locked.txt
sudo rm -f /root/locked.txt
```

**You should see** `rm` fail even as root, then `----i---------` in `lsattr`, then success after `chattr -i`.

The immutable attribute overrides all permissions and is invisible to `ls -l`.

### Mini checkpoint

Before the practice tasks, you should be able to explain:

| Bit | Octal | On a directory |
| --- | --: | --- |
| SUID | 4 | No effect |
| SGID | 2 | New files inherit the directory's group |
| Sticky | 1 | Only the owner can delete their own files |

And recite the collaboration recipe: **`groupadd`, `usermod -aG`, `chgrp`, `chmod 2770`**.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Identify three SUID binaries on the system and explain what the SUID bit achieves for `/usr/bin/passwd`.

> Hint: `find -perm -4000` under `/usr/bin` and `/usr/sbin`; the leading `-` means "at least this bit".

**Task 2.** Show the permissions of `/tmp` and identify which special bit is set and why.

> Hint: `ls -ld`; look for `t` in the other slot and mode `1777`.

**Task 3.** Create a collaborative directory `/shared/devs` for members of a new group `devs`, so that files created inside it are automatically owned by group `devs` and all members can read and write them. Non-members must have no access.

> Hint: the four-step recipe from follow-along steps 6–7 — group, members, `chgrp`, `chmod 2770`.

**Task 4.** Prove the group inheritance works by creating a file as `alice` and inspecting its group.

> Hint: `sudo -u alice touch`; compare the file's group to alice's primary group with `id alice`.

**Task 5.** Modify `/shared/devs` so that members can create files but cannot delete files belonging to other members.

> Hint: add the sticky bit — `3770` instead of `2770`.

**Task 6.** Create `/shared/projects` with mode `2775` owned by group `devs`, and explain how it differs from `2770`.

> Hint: the last digit controls `other` — `5` is `r-x`, `0` is `---`.

**Task 7.** Grant user `carol`, who is **not** in the `devs` group, read and write access to the single file `/shared/devs/notes.txt` using an ACL.

> Hint: `setfacl -m u:carol:rw` on the file **and** traversal on the directory — follow-along steps 10–11.

**Task 8.** Configure `/shared/devs` so that any **new** file created inside it automatically grants group `devs` read and write access, regardless of the creating user's umask.

> Hint: a **default** ACL with the `d:` prefix — follow-along step 12.

**Task 9.** Show all ACLs on `/shared/devs` and identify the mask.

> Hint: `getfacl`; look for the `mask::` line and any `#effective:` annotations.

**Task 10.** Remove all ACLs from `/shared/devs/notes.txt`.

> Hint: `-b` removes everything; `-k` only defaults, `-x` one entry.

**Task 11.** User `bob` reports he cannot read `/data/reports/summary.txt` even though the file is mode `644` and he is in the owning group. Create this scenario, diagnose it with the correct tool, and fix it.

> Hint: follow-along step 13 — `namei -l` shows the missing `x` on a parent directory.

**Task 12.** A file `/root/locked.txt` cannot be deleted even by root. Create this scenario and resolve it.

> Hint: follow-along step 14 — `chattr +i` and `lsattr`.

**Task 13.** Find all SGID directories under `/shared`.

> Hint: `find -type d -perm -2000` or `-perm -g+s`.

**Task 14.** Set the SUID bit on a copy of `/bin/cat` at `/tmp/mycat` and observe the resulting `ls -l` output. Then remove the execute bit and observe the difference in notation.

> Hint: follow-along step 5 — `4755` then `chmod u-x`; lowercase `s` versus capital `S`.

---

## Solutions

**Task 1.**

```bash
sudo find /usr/bin /usr/sbin -perm -4000 -type f 2>/dev/null | head
ls -l /usr/bin/passwd /usr/bin/sudo /usr/bin/mount
```

`/usr/bin/passwd` is `-rwsr-xr-x root root`. When any user runs it, the process runs with the **effective UID of root**, which is required because changing a password means writing `/etc/shadow` — a file with mode `000`. Without SUID, users could not change their own passwords.

`-perm -4000` needs the leading `-`, meaning "at least this bit". See `01-shell-fundamentals.md`.

**Task 2.**

```bash
ls -ld /tmp
```

```text
drwxrwxrwt. 20 root root 4096 Aug 18 17:00 /tmp
```

The final **`t`** is the **sticky bit** (numeric `1777`). `/tmp` must be world-writable so any process can create temporary files, but write permission on a directory normally allows deleting *any* file in it. The sticky bit restricts deletion to the file's **owner**, the directory's owner, or root — so users cannot delete each other's temporary files.

**Task 3.**

```bash
sudo groupadd devs
sudo useradd alice 2>/dev/null; sudo useradd bob 2>/dev/null
sudo usermod -aG devs alice
sudo usermod -aG devs bob

sudo mkdir -p /shared/devs
sudo chgrp devs /shared/devs
sudo chmod 2770 /shared/devs
```

Verify:

```bash
ls -ld /shared/devs
# drwxrws---. 2 root devs 6 Aug 18 17:00 /shared/devs
id alice
```

The four steps, in order: **group, members, `chgrp`, `chmod 2770`.** Memorise that sequence.

Reading `2770`: SGID (2) plus `rwx` for owner, `rwx` for group, `---` for other. The `---` for other is what satisfies "non-members must have no access".

**Task 4.**

```bash
sudo -u alice touch /shared/devs/alicefile
ls -l /shared/devs/alicefile
```

```text
-rw-rw-r--. 1 alice devs 0 Aug 18 17:05 alicefile
#              └────┴─ owner alice, group DEVS (not alice)
```

The group is `devs`, inherited from the directory's SGID bit, not `alice` (her primary group). Test the collaboration:

```bash
sudo -u bob sh -c 'echo "bob was here" >> /shared/devs/alicefile'
cat /shared/devs/alicefile
```

Bob can write because the file's group is `devs`, he is in `devs`, and alice's umask of `002` made it group-writable.

Compare with a non-SGID directory to see the difference:

```bash
sudo mkdir /shared/nosgid && sudo chgrp devs /shared/nosgid && sudo chmod 770 /shared/nosgid
sudo -u alice touch /shared/nosgid/f
ls -l /shared/nosgid/f     # group is ALICE — bob cannot write
```

**Task 5.**

```bash
sudo chmod 3770 /shared/devs
ls -ld /shared/devs
```

```text
drwxrws--T. 2 root devs ... /shared/devs
```

`3` = SGID (2) + sticky (1). The trailing **`T`** is capital because `other` has no execute bit; that is correct and expected here, not an error.

Verify:

```bash
sudo -u bob rm /shared/devs/alicefile
# rm: cannot remove 'alicefile': Operation not permitted
```

Bob can still read and modify the file, but not delete it. That is exactly the sticky bit's purpose.

**Task 6.**

```bash
sudo mkdir -p /shared/projects
sudo chgrp devs /shared/projects
sudo chmod 2775 /shared/projects
ls -ld /shared/projects
# drwxrwsr-x. 2 root devs ...
```

The difference is the last digit:

| Mode | other | Meaning |
| --- | --- | --- |
| **`2770`** | `---` | Only group members can enter or read the directory |
| **`2775`** | `r-x` | Anyone can enter and list it; only members can write |

Choose based on the task wording. "Only members of devs may access" is `2770`. "Members can write, others can read" is `2775`. Getting this wrong is a common way to lose the point on an otherwise correct answer.

**Task 7.**

```bash
sudo useradd carol 2>/dev/null
sudo touch /shared/devs/notes.txt
sudo chgrp devs /shared/devs/notes.txt
sudo setfacl -m u:carol:rw /shared/devs/notes.txt
getfacl /shared/devs/notes.txt
```

```text
user::rw-
user:carol:rw-
group::rw-
mask::rw-
other::r--
```

But this alone is **not enough**: carol also needs to traverse `/shared/devs`, which is `2770` and excludes non-members. Grant her directory access too:

```bash
sudo setfacl -m u:carol:rx /shared/devs
sudo -u carol cat /shared/devs/notes.txt      # now works
```

**This is the key insight.** An ACL on a file is useless if the user cannot traverse the path to reach it. Same principle as `namei -l` — permissions apply at every level.

Confirm the `+` marker appeared:

```bash
ls -l /shared/devs/notes.txt      # -rw-rw-r--+
ls -ld /shared/devs               # drwxrws---+
```

**Task 8.**

```bash
sudo setfacl -m d:g:devs:rw /shared/devs
getfacl /shared/devs
```

Test:

```bash
sudo touch /shared/devs/rootfile        # created by ROOT, umask 022
getfacl /shared/devs/rootfile
```

```text
group:devs:rw-        <- granted by the DEFAULT ACL, despite root's 022 umask
```

Without the default ACL, root's `022` umask would have produced `644` and group members could not write. **A default ACL is the robust answer to "group members must always be able to write", because it is independent of each user's umask.**

Note the `d:` prefix marks it as a default (inherited) entry. Default ACLs apply only to **newly created** files, not existing ones. To also fix existing files:

```bash
sudo setfacl -R -m g:devs:rw /shared/devs
```

**Task 9.**

```bash
getfacl /shared/devs
```

The **`mask::`** line is the ceiling applied to all named user entries, all named group entries, and the `group::` entry. It does **not** limit `user::` (the owner) or `other::`.

If any entry shows `#effective:` with fewer permissions than granted, the mask is capping it:

```text
user:carol:rwx    #effective:r-x       <- mask is r-x
mask::r-x
```

Raise the mask if needed:

```bash
sudo setfacl -m m::rwx /shared/devs
```

**Careful:** running `chmod g-w` on a file with ACLs lowers the mask, silently reducing every named entry. That is a genuinely confusing failure mode and is worth recognising.

**Task 10.**

```bash
sudo setfacl -b /shared/devs/notes.txt
getfacl /shared/devs/notes.txt
ls -l /shared/devs/notes.txt        # the + is gone
```

`-b` removes all ACL entries. `-k` removes only **default** ACLs, leaving access ACLs intact. `-x` removes one named entry:

```bash
sudo setfacl -x u:carol /shared/devs/notes.txt      # just carol
sudo setfacl -k /shared/devs                        # just the defaults
sudo setfacl -b /shared/devs                        # everything
```

**Task 11.**

Build the scenario:

```bash
sudo mkdir -p /data/reports
sudo groupadd analysts 2>/dev/null
sudo usermod -aG analysts bob
sudo touch /data/reports/summary.txt
sudo chgrp analysts /data/reports/summary.txt
sudo chmod 644 /data/reports/summary.txt
sudo chmod 700 /data/reports          # <- the actual problem
```

Confirm the failure:

```bash
sudo -u bob cat /data/reports/summary.txt
# cat: /data/reports/summary.txt: Permission denied
```

Diagnose:

```bash
namei -l /data/reports/summary.txt
```

```text
f: /data/reports/summary.txt
 dr-xr-xr-x root root     /
 drwxr-xr-x root root     data
 drwx------ root root     reports        <- bob has no x here
 -rw-r--r-- root analysts summary.txt
```

The file is readable by group `analysts` and bob is a member, but he cannot **traverse** `/data/reports` to reach it. Fix:

```bash
sudo chmod 755 /data/reports
sudo -u bob cat /data/reports/summary.txt      # works
```

Or, if only analysts should be able to enter:

```bash
sudo chgrp analysts /data/reports
sudo chmod 750 /data/reports
sudo -u bob cat /data/reports/summary.txt      # also works
```

**Run `namei -l` first on every permission-diagnosis task.** It finds this class of problem in one command.

One more thing to check if this were real: bob's group membership must be active in his session. `id bob` shows the configured groups; a shell he opened before you added him to `analysts` would not have it.

**Task 12.**

```bash
sudo touch /root/locked.txt
sudo chattr +i /root/locked.txt
sudo rm -f /root/locked.txt
# rm: cannot remove '/root/locked.txt': Operation not permitted
```

Even root is refused. Diagnose:

```bash
sudo lsattr /root/locked.txt
# ----i---------e------- /root/locked.txt
#     └── immutable
```

Fix:

```bash
sudo chattr -i /root/locked.txt
sudo rm -f /root/locked.txt
```

**When root cannot delete or modify a file, check `lsattr`.** The immutable attribute overrides all permissions and is invisible to `ls -l`. Useful attributes: `i` immutable, `a` append-only.

**Task 13.**

```bash
sudo find /shared -type d -perm -2000
```

Or with symbolic notation:

```bash
sudo find /shared -type d -perm -g+s -ls
```

`-perm -2000` finds directories with at least the SGID bit. Similarly `-perm -4000` for SUID and `-perm -1000` for sticky. The leading `-` is required.

**Task 14.**

```bash
sudo cp /bin/cat /tmp/mycat
sudo chmod 4755 /tmp/mycat
ls -l /tmp/mycat
```

```text
-rwsr-xr-x. 1 root root ... /tmp/mycat
#   └── lowercase s: SUID set AND the owner has execute
```

Now remove the owner's execute bit:

```bash
sudo chmod u-x /tmp/mycat
ls -l /tmp/mycat
```

```text
-rwSr-xr-x. 1 root root ... /tmp/mycat
#   └── CAPITAL S: SUID set but NO execute — the bit is meaningless here
```

**Lowercase `s` means the special bit and the execute bit are both set. Capital `S` means the special bit is set without execute**, which is almost always a mistake. The same applies to `t` versus `T` for the sticky bit.

Clean up:

```bash
sudo rm -f /tmp/mycat
```

---

## Verify

```bash
ls -ld /shared/devs /shared/projects
getfacl /shared/devs
namei -l /data/reports/summary.txt
sudo find /shared -type d -perm -2000
id alice; id bob; id carol
sudo -u alice touch /shared/devs/verify && ls -l /shared/devs/verify
```

## Persistence Check

| Change | Persists? | Notes |
| --- | --- | --- |
| `chmod`, `chgrp`, special bits | **Yes** | Inode metadata |
| ACLs | **Yes**, if the filesystem supports them | xfs and ext4 do by default |
| Default ACLs | **Yes** | Applied to new files as they are created |
| `chattr` attributes | **Yes** | Inode metadata |
| Group membership | **Yes** | `/etc/group` |

**One real risk: ACLs require filesystem support.** On xfs and ext4 they are enabled by default on RHEL. If you created a filesystem with unusual options, or the mount uses `noacl`, ACLs silently fail to apply. Check:

```bash
findmnt -o TARGET,FSTYPE,OPTIONS /shared
mount | grep -w /shared
```

**The other risk: the directory must be on a persistent mount.** If `/shared` is on a filesystem you created but did not add to `/etc/fstab`, everything here vanishes on reboot. See `30-filesystems-fstab.md`.

Post-reboot verification:

```bash
findmnt /shared                   # if it is a separate filesystem
ls -ld /shared/devs               # drwxrws--- still?
getfacl /shared/devs              # default ACLs still there?
sudo -u alice touch /shared/devs/rebootcheck
ls -l /shared/devs/rebootcheck    # group should still be devs
```

## Quick Reference

Come back here when you need a command you forgot — not before your first pass through Follow Along.

### The three special bits

| Bit | Octal | Symbol | On a **file** | On a **directory** |
| --- | --: | --- | --- | --- |
| **SUID** | **4** | `s` in the **user** slot | Runs as the file's **owner** | No effect |
| **SGID** | **2** | `s` in the **group** slot | Runs as the file's **group** | **New files inherit the directory's group** |
| **Sticky** | **1** | `t` in the **other** slot | No effect | **Only the owner can delete their own files** |

Where they appear in `ls -l`:

```text
-rwsr-xr-x   SUID      the x in the USER slot became s
-rwxr-sr-x   SGID      the x in the GROUP slot became s
drwxrwxrwt   sticky    the x in the OTHER slot became t

-rwSr--r--   SUID set but NO underlying x  -> capital S, usually a mistake
drwxrwxrwT   sticky set but no other-x     -> capital T
```

**A capital `S` or `T` means the special bit is set but the corresponding execute bit is not.** That is almost always an error worth spotting in a diagnosis task.

### Canonical examples

```bash
ls -l /usr/bin/passwd     # -rwsr-xr-x  SUID root: any user can write /etc/shadow
ls -ld /tmp               # drwxrwxrwt  sticky: world-writable but delete-protected
ls -l /usr/bin/write      # -rwxr-sr-x  SGID tty
```

`/usr/bin/passwd` is SUID root because changing your own password requires writing `/etc/shadow`, which is mode `000`. `/tmp` is sticky because it is world-writable and without the sticky bit any user could delete anyone else's files.

### Setting them

```bash
# Symbolic
chmod u+s file            # SUID
chmod g+s dir             # SGID
chmod o+t dir             # sticky
chmod g-s dir             # remove SGID

# Numeric: a FOURTH leading digit
chmod 4755 file           # SUID + rwxr-xr-x
chmod 2775 dir            # SGID + rwxrwxr-x
chmod 1777 dir            # sticky + rwxrwxrwx
chmod 3770 dir            # SGID + sticky + rwxrwx---
chmod 0755 dir            # explicitly clear all special bits
```

The leading digit is the sum: **SUID 4 + SGID 2 + sticky 1**. So `3770` is SGID plus sticky.

### The collaborative directory recipe

This is the task. A group of users share a directory; every file created in it belongs to the shared group so all members can work on it.

```bash
# 1. The group
sudo groupadd devs

# 2. The members
sudo usermod -aG devs alice
sudo usermod -aG devs bob

# 3. The directory, owned by the group
sudo mkdir -p /shared/devs
sudo chgrp devs /shared/devs

# 4. SGID plus group write
sudo chmod 2770 /shared/devs
```

Verify:

```bash
ls -ld /shared/devs
# drwxrws---. 2 root devs 6 Aug 18 17:00 /shared/devs
#       └── the s is the SGID bit
```

**Why SGID is essential:** without it, a file alice creates in the directory belongs to group `alice` (her primary group), and bob cannot write to it. With SGID, the file inherits group `devs`, so bob can.

Prove it:

```bash
sudo -u alice touch /shared/devs/alicefile
ls -l /shared/devs/alicefile
# -rw-rw-r--. 1 alice devs ...     <- group is devs, NOT alice
```

**Add the sticky bit when members should not delete each other's files:**

```bash
sudo chmod 3770 /shared/devs
# drwxrws--T
```

Without sticky, `w` on the directory lets any member delete any file regardless of its own permissions. Whether you want that depends on the task wording: "members can collaborate" is `2770`; "members cannot delete each other's files" is `3770`.

**The `2770` versus `2775` choice:** use `2770` when the task says only group members should have access, and `2775` when others may read. Read the wording.

### One gap the recipe leaves

SGID makes new files inherit the **group**, but their **permissions** still come from each user's umask. With the RHEL default umask of `002`, a regular user creates files as `664`, which is group-writable — so collaboration works. But **root's umask is `022`**, so files root creates in the directory are `644` and not group-writable.

If a task requires that group members can always write each other's files, either ensure they create them as themselves, or set a default ACL (below), which is the robust answer.

### Access Control Lists

ACLs grant permissions to **specific users or groups** beyond the three standard sets. Use them when the ugo model cannot express the requirement.

```bash
getfacl file                          # show ACLs
setfacl -m u:alice:rw file            # grant alice read+write
setfacl -m g:devs:rx dir              # grant group devs read+execute
setfacl -m o::- file                  # set the 'other' entry
setfacl -m m::rx file                 # set the mask
setfacl -x u:alice file               # remove alice's entry
setfacl -b file                       # remove ALL ACLs
setfacl -R -m u:alice:rx dir          # recursive

# DEFAULT ACLs: inherited by NEW files in a directory
setfacl -m d:u:alice:rw dir           # default for user alice
setfacl -m d:g:devs:rwx dir            # default for group devs
setfacl -k dir                        # remove default ACLs
```

Reading `getfacl` output:

```text
# file: shared
# owner: root
# group: devs
user::rwx
user:alice:rw-              <- a named user entry
group::rwx
group:contractors:r-x       <- a named group entry
mask::rwx                   <- the CEILING on all named entries and group::
other::---
default:user::rwx           <- inherited by new files
default:group:devs:rwx
```

Two things to understand:

1. **The `+` in `ls -l`** tells you an ACL exists:

```bash
ls -l file
# -rw-rw-r--+ 1 root devs ...
#           └── an ACL is present
```

That `+` is the first thing to look for in a permission-diagnosis task.

2. **The mask caps effective permissions.** If the mask is `r-x` and alice's ACL grants `rw-`, her effective permission is `r--`. `getfacl` shows this explicitly:

```text
user:alice:rw-      #effective:r--
```

`chmod` on a file with ACLs modifies the **mask**, not the group entry, which is why a `chmod g-w` can silently strip write access from every named ACL entry. If ACL entries stop working after a `chmod`, this is why.

### Diagnosing permission problems

A method, in order:

```bash
# 1. What are the file's own permissions and ownership?
ls -l /path/to/file
stat -c '%a %A %U:%G %n' /path/to/file

# 2. Is there an ACL? (look for the + in ls -l)
getfacl /path/to/file

# 3. Can the user traverse EVERY directory in the path?
namei -l /path/to/file

# 4. What groups is the user actually in?
id username

# 5. Is SELinux blocking it?
ls -lZ /path/to/file
sudo ausearch -m AVC -ts recent
getenforce

# 6. Test as the user
sudo -u username cat /path/to/file
sudo -u username touch /path/to/dir/testfile

# 7. Is the filesystem read-only?
findmnt /path
mount | grep -w /path
```

**`namei -l` is the highest-value tool here** and few candidates know it. It shows the mode, owner, and group of every component in a path, so a missing `x` three levels up is instantly visible:

```text
$ namei -l /shared/devs/report.txt
f: /shared/devs/report.txt
 dr-xr-xr-x root root  /
 drwxr-x--- root root  shared      <- alice is not in root group: BLOCKED HERE
 drwxrws--- root devs  devs
 -rw-rw-r-- alice devs report.txt
```

The seven causes of "permissions look right but access fails", roughly in order of frequency:

| Cause | Detect with |
| --- | --- |
| **Missing `x` on a parent directory** | `namei -l` |
| Group membership not active in the current session | `id` vs `id` after re-login |
| An ACL mask capping a named entry | `getfacl`, look for `#effective:` |
| **SELinux context wrong** | `ls -lZ`, `ausearch -m AVC` |
| Filesystem mounted read-only or `noexec` | `findmnt` |
| Immutable attribute set | `lsattr` |
| Wrong file entirely (a symlink elsewhere) | `readlink -f` |

### Extended attributes: immutable

Occasionally the answer to "root cannot delete this file".

```bash
lsattr file                # list attributes
sudo chattr +i file        # IMMUTABLE: cannot be modified, deleted, or renamed
sudo chattr -i file        # remove
sudo chattr +a file        # append-only
```

An immutable file cannot be changed even by root until the attribute is removed. If a task presents an undeletable file with apparently correct permissions, run `lsattr`.

## Exam Tips

- **SUID 4, SGID 2, sticky 1.** They form the fourth, leading digit of `chmod`.
- **SGID on a directory makes new files inherit the directory's group.** That is the entire point of the collaborative-directory task.
- **The collaboration recipe: `groupadd`, `usermod -aG`, `chgrp`, `chmod 2770`.** Four steps, in that order.
- **`2770` = members only. `2775` = members write, others read.** Match the task wording.
- **Add the sticky bit (`3770`) when members must not delete each other's files.**
- **Sticky bit on `/tmp` is `1777`.** Without it, any user could delete anyone's files.
- **Lowercase `s`/`t` means the execute bit is also set. Capital `S`/`T` means it is not** — usually a mistake, but expected on `other` for a `3770` directory.
- **`ls -l` shows `+` when an ACL exists.** Look for it first in diagnosis tasks.
- **`namei -l` is the best permission-diagnosis tool.** It shows the mode of every path component and finds the missing `x` upstream.
- **An ACL on a file is useless without traversal on the directories above it.**
- **`setfacl -m u:user:rw file`** for a user; **`d:`** prefix for a default (inherited) ACL.
- **A default ACL beats umask**, so it is the robust way to guarantee group write access.
- **The ACL `mask` caps named entries.** `chmod g-w` lowers the mask and can silently break ACLs. Look for `#effective:` in `getfacl`.
- **`setfacl -b`** removes all ACLs, **`-k`** only defaults, **`-x`** one entry.
- **`lsattr` / `chattr -i`** when even root cannot delete a file.
- `find -perm -4000` SUID, `-perm -2000` SGID, `-perm -1000` sticky. The leading `-` is required.
- Group membership only applies to **new** logins.
- If permissions look correct but access still fails, the remaining suspects are **SELinux** (`ls -lZ`, `ausearch -m AVC`) and a **read-only mount** (`findmnt`).
