# Permissions Deep Dive

Standard permissions, special bits, `umask`, ACLs, and the collaborative directory. Two of these are stated objectives in their own right — "create and configure set-GID directories for collaboration" and "diagnose and correct file permission problems" — and permissions turn up as a hidden cause inside storage, container, and web-server tasks.

Step-by-step tasks are in `06.md` and `12.md`.

---

## Reading `ls -l`

```bash
ls -l /etc/passwd
```

```text
-rw-r--r--. 1 root root 2847 Aug 18 17:22 /etc/passwd
│└┬┘└┬┘└┬┘│ │  │    │    │
│ │  │  │ │ │  │    │    └─ size
│ │  │  │ │ │  │    └─ group
│ │  │  │ │ │  └─ owner
│ │  │  │ │ └─ link count
│ │  │  │ └─ . = an SELinux context is present; + = an ACL is present
│ │  │  └─ other
│ │  └─ group
│ └─ owner
└─ type
```

| Type character | Meaning |
| --- | --- |
| `-` | Regular file |
| `d` | Directory |
| `l` | Symbolic link |
| `b` | Block device |
| `c` | Character device |
| `s` | Socket |
| `p` | Named pipe |

**The character after the permissions matters:**

| Character | Meaning |
| --- | --- |
| `.` | An SELinux context is present |
| **`+`** | **An ACL is present — run `getfacl`** |
| (space) | Neither |

**`+` is easy to miss and explains permissions that make no sense from the mode alone.**

---

## Numeric and symbolic

| | r | w | x |
| --- | --- | --- | --- |
| Value | **4** | **2** | **1** |

| Digit | Bits |
| --- | --- |
| 7 | rwx |
| 6 | rw- |
| 5 | r-x |
| 4 | r-- |
| 3 | -wx |
| 2 | -w- |
| 1 | --x |
| 0 | --- |

```bash
chmod 755 file          # rwxr-xr-x
chmod 644 file          # rw-r--r--
chmod 600 file          # rw-------
chmod 640 file          # rw-r-----
chmod 750 dir           # rwxr-x---
chmod 700 dir           # rwx------
chmod 777 file          # rwxrwxrwx — almost never correct
```

Symbolic form, which is better when you want to change one thing without touching the rest:

```bash
chmod u+x file          # add execute for the owner
chmod g-w file          # remove write from the group
chmod o= file           # remove everything from other
chmod a+r file          # add read for all
chmod u=rwx,g=rx,o= file
chmod g+s dir           # SGID
chmod +t dir            # sticky
chmod -R g+rwX dir      # capital X: directories and already-executable files only
chmod --reference=template file
```

| Who | |
| --- | --- |
| `u` | owner (user) |
| `g` | group |
| `o` | other |
| `a` | all three |

| Operator | |
| --- | --- |
| `+` | add |
| `-` | remove |
| `=` | set exactly, clearing the rest |

**`chmod -R g+rwX dir` is the right recursive form.** Lowercase `x` would make every text file executable; **capital `X` adds execute only to directories and to files that already have it somewhere.**

---

## Permissions on directories mean something different

| Bit | On a file | **On a directory** |
| --- | --- | --- |
| **r** | Read the contents | **List the names inside** |
| **w** | Modify the contents | **Create, delete, and rename entries inside** |
| **x** | Execute it | **Enter it and access things inside by name** |

**Three consequences that cause real confusion:**

**1. `x` without `r`** — you can reach a known filename but cannot list the directory:

```bash
sudo chmod 711 /srv/private
ls /srv/private                       # Permission denied
cat /srv/private/known.txt            # WORKS
```

**2. `r` without `x`** — you can see names and nothing else:

```bash
sudo chmod 744 /srv/listable
ls /srv/listable                      # names appear
ls -l /srv/listable                   # every entry shows ?
cat /srv/listable/file.txt            # Permission denied
```

**3. `w` on the directory controls deletion, not `w` on the file.**

```bash
# alice can delete a root-owned, read-only file if she can write the directory
sudo mkdir /tmp/demo && sudo chmod 777 /tmp/demo
sudo touch /tmp/demo/rootfile && sudo chmod 444 /tmp/demo/rootfile
su - alice -c 'rm -f /tmp/demo/rootfile'      # SUCCEEDS
```

**That is what the sticky bit exists to prevent.**

**And every directory in the path needs `x`:**

```bash
namei -l /srv/data/reports/file.txt
```

```text
f: /srv/data/reports/file.txt
 drwxr-xr-x root root /
 drwxr-xr-x root root srv
 drwx------ root root data      ← the block is HERE
 drwxr-xr-x root root reports
 -rw-r--r-- root root file.txt
```

**`namei -l` walks the whole path and shows exactly which component denies access.** It is the single best tool for "diagnose and correct file permission problems" and hardly anyone knows it.

---

## Ownership

```bash
sudo chown alice file
sudo chown alice:devs file
sudo chown :devs file                 # group only
sudo chown alice: file                # group becomes alice's primary group
sudo chgrp devs file
sudo chown -R alice:devs /srv/app
sudo chown --reference=template file
sudo chown -h alice symlink           # the link itself, not its target
```

| Who may | |
| --- | --- |
| Change the owner | **Only root** |
| Change the group | root, or the owner — to a group the owner belongs to |
| Change the mode | root, or the owner |

**A regular user cannot give a file away**, which is why ownership tasks always need `sudo`.

---

## umask

`umask` masks out permission bits from newly created files and directories.

```bash
umask                                 # 0022
umask -S                              # u=rwx,g=rx,o=rx
umask 0027
umask 0077
```

| | Base | Typical umask 022 | umask 027 | umask 077 |
| --- | --- | --- | --- | --- |
| **File** | **666** | 644 | 640 | 600 |
| **Directory** | **777** | 755 | 750 | 700 |

**Files start from 666, not 777.** Execute permission is never granted by creation — a compiler or `chmod` adds it.

```bash
umask 0027
touch /tmp/f && mkdir /tmp/d
ls -l /tmp/f          # -rw-r-----
ls -ld /tmp/d         # drwxr-x---
```

**Defaults on RHEL:**

| User | umask |
| --- | --- |
| root | **022** |
| Regular user with a user private group | **002** |

**`002` is safe only because each user has their own group.** Change a user's primary group to a shared one and `002` means group-writable files everywhere — which is sometimes exactly what a collaboration task wants.

### Making it persistent

```bash
# All users, login and non-login shells
echo 'umask 0027' | sudo tee /etc/profile.d/custom-umask.sh

# One user
echo 'umask 0027' >> ~/.bashrc

# Login sessions, via PAM
sudo vim /etc/login.defs               # UMASK 027
```

```bash
grep -i umask /etc/login.defs /etc/profile /etc/bashrc /etc/profile.d/*.sh 2>/dev/null
```

**Verify by opening a new session, not in the current shell:**

```bash
su - alice -c 'umask'
```

**A task saying "the default permissions for new files must be X" is a `umask` task.** Work backwards: 640 means the mask removes `w` from group and everything from other, so `umask 027`.

---

## Special permissions

| Bit | Numeric | Symbolic | On a file | On a directory |
| --- | --- | --- | --- | --- |
| **SUID** | **4000** | `u+s` | **Runs as the file's owner** | Nothing |
| **SGID** | **2000** | `g+s` | Runs as the file's group | **New entries inherit the directory's group** |
| **Sticky** | **1000** | `+t` | Nothing (historically) | **Only the owner may delete** |

```bash
sudo chmod 4755 /usr/local/bin/tool      # SUID
sudo chmod u+s /usr/local/bin/tool
sudo chmod 2775 /shared/devs             # SGID
sudo chmod g+s /shared/devs
sudo chmod 1777 /shared/scratch          # sticky
sudo chmod +t /shared/scratch
sudo chmod 3770 /shared/both             # SGID + sticky
```

### Reading them in `ls -l`

```text
-rwsr-xr-x   SUID set, owner has x        ← /usr/bin/passwd
-rwSr--r--   SUID set, owner has NO x     ← capital S: probably a mistake
drwxrwsr-x   SGID set, group has x        ← a collaborative directory
drwxrwxrwt   sticky set, other has x      ← /tmp
drwxrwxrwT   sticky set, other has NO x
```

**Lowercase means the underlying execute bit is also set; uppercase means it is not.** A capital `S` or `T` is usually a sign the mode was set wrong.

```bash
ls -l /usr/bin/passwd
ls -ld /tmp
sudo find / -perm /4000 -type f 2>/dev/null      # every SUID file
sudo find / -perm /2000 -type f 2>/dev/null      # every SGID file
sudo find / -perm /6000 -type f 2>/dev/null      # both
sudo find / -perm -1000 -type d 2>/dev/null      # sticky directories
```

**`/4000` means "any of these bits". `4000` alone means "exactly this mode and nothing else", which matches almost nothing.** That distinction is worth remembering — it is a common exam trap.

### Why SUID exists

```bash
ls -l /usr/bin/passwd
```

```text
-rwsr-xr-x. 1 root root 32656 /usr/bin/passwd
```

**`passwd` must write `/etc/shadow`, which is mode 000 and owned by root.** SUID lets any user run it with root's identity for the duration.

**SUID on a shell script does nothing on Linux** — the kernel ignores it for interpreted files, deliberately, because it is unsafe. A task asking for privileged script execution wants `sudo`, not SUID.

### The collaborative directory

**This is a stated objective and it appears on nearly every exam.**

```bash
# 1. The group
sudo groupadd devs

# 2. The members
sudo usermod -aG devs alice
sudo usermod -aG devs bob

# 3. The directory
sudo mkdir -p /shared/devs

# 4. Group ownership
sudo chown root:devs /shared/devs

# 5. SGID plus group write, nothing for others
sudo chmod 2770 /shared/devs

# 6. Verify
ls -ld /shared/devs
```

```text
drwxrws---. 2 root devs 6 Aug 18 19:30 /shared/devs
   │  └─ s here is the SGID bit
   └─ group has rwx
```

**All five steps are needed, and the mode is the one people get wrong. `2770` breaks down as:**

| Digit | Meaning |
| --- | --- |
| **2** | **SGID — new entries inherit the `devs` group** |
| 7 | Owner rwx |
| **7** | **Group rwx — members can create and delete** |
| 0 | Nothing for anyone else |

**Prove it works:**

```bash
su - alice -c 'touch /shared/devs/alice.txt'
su - bob   -c 'touch /shared/devs/bob.txt'
ls -l /shared/devs/
```

```text
-rw-rw-r--. 1 alice devs 0 Aug 18 19:31 alice.txt
-rw-rw-r--. 1 bob   devs 0 Aug 18 19:31 bob.txt
                          └─ the GROUP is devs, not alice or bob
```

**Without SGID the group would be `alice` and `bob` respectively, and neither could write the other's files.**

```bash
su - bob -c 'echo "edited by bob" >> /shared/devs/alice.txt'   # works
```

**Two refinements that appear in harder tasks:**

**Sticky as well**, so members cannot delete each other's files:

```bash
sudo chmod 3770 /shared/devs
ls -ld /shared/devs                          # drwxrws--T
su - bob -c 'rm -f /shared/devs/alice.txt'   # now Permission denied
```

**A default ACL**, so files are group-writable even when a member's umask is restrictive:

```bash
sudo setfacl -m d:g:devs:rwx /shared/devs
sudo setfacl -m g:devs:rwx /shared/devs
getfacl /shared/devs
```

**SGID sets the group; it does not set group *write* on the new file — the creator's `umask` does that.** With `umask 022` a member creates `-rw-r--r--` files that colleagues cannot edit. **A default ACL is the fix, and it is what "members must be able to edit each other's files" really requires.**

---

## ACLs

ACLs extend the three-slot owner/group/other model to arbitrary users and groups.

```bash
getfacl /shared/devs
```

```text
# file: shared/devs
# owner: root
# group: devs
# flags: -s-
user::rwx
group::rwx
other::---
default:user::rwx
default:group::rwx
default:other::---
```

### Setting

```bash
sudo setfacl -m u:alice:rwx file          # a named user
sudo setfacl -m g:devs:rx file            # a named group
sudo setfacl -m o::--- file               # other
sudo setfacl -m m::rx file                # the mask
sudo setfacl -m u:alice:rwx,g:devs:rx file
sudo setfacl -R -m u:alice:rX dir         # recursive
sudo setfacl -m d:u:alice:rwx dir         # DEFAULT — applies to new entries
sudo setfacl -Rm d:g:devs:rwx dir
sudo setfacl --set-file=saved.acl file
```

### Removing

```bash
sudo setfacl -x u:alice file              # one entry
sudo setfacl -x g:devs file
sudo setfacl -b file                      # ALL ACLs
sudo setfacl -k dir                       # only the default ACLs
sudo setfacl -R -b dir
```

### Backup and restore

```bash
getfacl -R /shared > acls.txt
sudo setfacl --restore=acls.txt
```

**Worth knowing because `restorecon` and recursive `chmod` can flatten ACLs.**

### Access versus default

| | Access ACL | **Default ACL** |
| --- | --- | --- |
| Applies to | The file or directory itself | **Entries created inside, later** |
| Set with | `setfacl -m u:alice:rwx` | **`setfacl -m d:u:alice:rwx`** |
| On files | Yes | **No — directories only** |
| Inherited | No | **Yes** |

```bash
sudo setfacl -m  u:alice:rwx /shared/project     # alice can use the directory now
sudo setfacl -m d:u:alice:rwx /shared/project    # and everything created in it later
```

**A task saying "alice must have access to files created in this directory in the future" needs the default ACL.** Both entries are usually wanted — the access ACL for now, the default for later.

```bash
sudo touch /shared/project/newfile
getfacl /shared/project/newfile          # inherited the default as an access ACL
```

### The mask

```text
user::rwx
user:alice:rwx           #effective:r-x      ← the mask is limiting alice
group::rwx               #effective:r-x
mask::r-x
other::---
```

**The mask is the ceiling for every named user, every named group, and the owning group.** An entry granting more than the mask allows is shown with `#effective:` and the reduced rights.

```bash
sudo setfacl -m m::rwx file              # raise the mask
getfacl file
```

**`chmod g+w` on a file with ACLs changes the mask, not the group entry.** That is why a `chmod` can appear to break an ACL. Re-check with `getfacl` after any `chmod` on an ACL'd file.

### ACLs and the filesystem

```bash
sudo tune2fs -l /dev/sdb1 | grep -i 'default mount'
mount | grep /data
```

| Filesystem | ACL support |
| --- | --- |
| **xfs** | **Always on** |
| **ext4** | On by default on RHEL; can be forced with the `acl` mount option |
| vfat | **None** |

```text
LABEL=data  /data  ext4  defaults,acl  0 2
```

**`Operation not supported` from `setfacl` means either vfat or an ext4 mounted without `acl`.**

---

## Diagnosing permission problems

**This is a stated objective. A method beats guessing.**

```text
"alice cannot read /srv/data/reports/file.txt"

 1. WHO is alice, really?
    id alice
    (is she in the group you think? did usermod -aG actually take effect?
     an existing login session has the OLD group list — she must log out and in)

 2. WHAT does the whole path look like?
    namei -l /srv/data/reports/file.txt
    ← this finds most problems immediately

 3. Are there ACLs?
    ls -l file            (look for +)
    getfacl file

 4. Is it SELinux rather than permissions?
    ls -Z file
    sudo ausearch -m AVC -ts recent
    sudo setenforce 0     (does it work now? then set it back to 1 and fix properly)

 5. Is the filesystem read-only or mounted with noexec/nosuid?
    findmnt /srv
    mount | grep /srv

 6. Test as her, do not reason about it
    su - alice -c 'cat /srv/data/reports/file.txt'
    sudo -u alice cat /srv/data/reports/file.txt
```

**Step 6 is the one to do first if you have any doubt.** Reasoning about permissions is error-prone; testing takes two seconds.

**Step 1's group caveat catches people constantly:**

```bash
sudo usermod -aG devs alice
id alice                              # shows devs
su - alice -c 'id'                    # shows devs — a NEW session
# but alice's EXISTING ssh session still has the old groups until she reconnects
```

### The clues

| Observation | Diagnosis |
| --- | --- |
| `chmod 777` changes nothing | **SELinux** |
| `+` in `ls -l` | An ACL is involved |
| Works as root, fails as a user | Ordinary DAC — use `namei -l` |
| Works for one user, not another | Group membership, or an ACL |
| Can read the file, cannot list the directory | Directory `x` without `r` |
| Can list, cannot read anything | Directory `r` without `x` |
| Can delete a file they do not own | Directory `w` — add the sticky bit |
| New files get the wrong group | **SGID missing on the directory** |
| New files are not group-writable | **`umask`, or a missing default ACL** |
| `Read-only file system` | `findmnt` — remounted read-only after an error |
| A script will not run | Missing `x`, or a bad shebang, or `noexec` on the mount |
| `Operation not supported` from setfacl | vfat, or ext4 without `acl` |

---

## Worked example

**Task: `/srv/project` is a shared area for the `devs` group. Members must be able to create, read, and edit each other's files, but not delete files they do not own. The user `auditor` needs read-only access. Nobody else gets anything.**

```bash
# 1. Group and members
sudo groupadd devs
sudo usermod -aG devs alice
sudo usermod -aG devs bob

# 2. The directory, owned by the group
sudo mkdir -p /srv/project
sudo chown root:devs /srv/project

# 3. SGID for group inheritance, sticky against deletion, nothing for others
sudo chmod 3770 /srv/project

# 4. Default ACL so new files are group-writable regardless of umask
sudo setfacl -m  g:devs:rwx /srv/project
sudo setfacl -m d:g:devs:rwx /srv/project

# 5. auditor, read-only, now and in future
sudo setfacl -m  u:auditor:rx  /srv/project
sudo setfacl -m d:u:auditor:rx /srv/project

# 6. Verify the structure
ls -ld /srv/project
getfacl /srv/project
```

```text
drwxrws--T+ 2 root devs 6 Aug 18 19:45 /srv/project
   │  │  │└─ + : an ACL is present
   │  │  └─ T : sticky
   │  └─ s : SGID
```

```bash
# 7. Verify the BEHAVIOUR, which is what is graded
su - alice -c 'echo hello > /srv/project/alice.txt'
su - bob   -c 'echo "bob was here" >> /srv/project/alice.txt'   # must work
su - bob   -c 'rm -f /srv/project/alice.txt'                    # must FAIL
su - auditor -c 'cat /srv/project/alice.txt'                    # must work
su - auditor -c 'touch /srv/project/x'                          # must FAIL
ls -l /srv/project/
getfacl /srv/project/alice.txt
```

```text
-rw-rw-r--+ 1 alice devs 25 Aug 18 19:46 alice.txt
              └─ group devs, from SGID; group-writable, from the default ACL
```

**Everything here persists because it is all filesystem metadata** — no service, no configuration file, nothing to enable. **But it still deserves a reboot check**, because a `restorecon -R` or a recursive `chmod` from a later task can undo it.

---

## Verification

```bash
ls -l file                         # mode, owner, group, + for ACL, . for SELinux
ls -ld dir
namei -l /full/path/to/file        # every component of the path
stat file                          # numeric mode and all timestamps
getfacl file                       # ACLs, including effective rights
ls -Z file                         # SELinux context
umask ; umask -S
su - USER -c 'command'             # the only test that really counts
sudo find / -perm /6000 -type f 2>/dev/null     # SUID and SGID audit
grep -i umask /etc/login.defs /etc/profile /etc/profile.d/*.sh 2>/dev/null
```

---

## The five things to take away

1. **On a directory, `x` means enter, `w` means create and delete.** `namei -l` shows which component of a path is blocking.
2. **A collaborative directory is `chown root:GROUP` plus `chmod 2770`** — and add a default ACL if members must edit each other's files.
3. **`find -perm /4000`, with the slash.** Without it you are matching an exact mode.
4. **`+` in `ls -l` means an ACL. Run `getfacl` before concluding anything.**
5. **If `chmod 777` does not fix it, it is SELinux.** Change nothing further until you have checked `ls -Z` and `ausearch`.
