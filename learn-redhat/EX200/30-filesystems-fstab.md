# 30. Filesystems, Mounting, And /etc/fstab

**Objectives:** Configure systems to mount file systems at boot by universally unique ID (UUID) or label. Create, mount, unmount, and use vfat, ext4, and xfs file systems.

**This file contains the single most important thing on the exam: `/etc/fstab`.** A wrong entry here does not just fail a task, it stops the machine booting — and the exam is graded after a reboot.

## Concept Refresher

### Filesystem types

| Type | Default for | Grow | Shrink | Notes |
| --- | --- | --- | --- | --- |
| **XFS** | **RHEL default** | **Yes, mounted** | **NEVER** | `mkfs.xfs`, `xfs_growfs`, `xfs_repair` |
| **ext4** | Widely used | Yes | **Yes, unmounted** | `mkfs.ext4`, `resize2fs`, `fsck.ext4` |
| **vfat** | USB, EFI | Yes | No | `mkfs.vfat`, no permissions or ownership |
| ext3, ext2 | Legacy | Yes | Yes | Rare |
| swap | Swap | — | — | `mkswap`, see `31-swap.md` |
| iso9660 | Optical, ISO | — | — | Read-only |

```bash
sudo mkfs.xfs /dev/sdb1
sudo mkfs.ext4 /dev/sdb1
sudo mkfs.vfat /dev/sdb1
sudo mkfs -t xfs /dev/sdb1
sudo mkfs.xfs -f /dev/sdb1                 # -f forces over an existing filesystem
sudo mkfs.xfs -L mydata /dev/sdb1          # with a label
sudo mkfs.ext4 -L mydata /dev/sdb1
sudo mkfs.vfat -n MYDATA /dev/sdb1         # vfat uses -n, and UPPERCASE labels
```

**Note the label flags differ: `-L` for XFS and ext4, `-n` for vfat.**

**`mkfs` destroys everything on the device.** There is no confirmation for a blank device, and only a warning for one with an existing signature.

The three the objective names are XFS, ext4, and vfat, so know all three. RHEL 10 may need a package for vfat:

```bash
sudo dnf install -y dosfstools          # mkfs.vfat
sudo dnf install -y e2fsprogs xfsprogs
```

### Mounting

```bash
sudo mount /dev/sdb1 /data
sudo mount UUID=4b2c9e1f-... /data
sudo mount LABEL=mydata /data
sudo mount -t xfs /dev/sdb1 /data
sudo mount -o ro /dev/sdb1 /data
sudo mount -o remount,rw /data
sudo mount -a                              # everything in /etc/fstab
sudo mount /data                           # if /data is in /etc/fstab

sudo umount /data
sudo umount /dev/sdb1
sudo umount -l /data                       # lazy
sudo umount -f /data                       # force (NFS)
```

**The mount point must exist first:**

```bash
sudo mkdir -p /data
```

Inspecting mounts:

```bash
mount                                      # everything, verbose
findmnt                                    # tree view — much better
findmnt /data
findmnt -no SOURCE,FSTYPE /data
findmnt --verify                           # VALIDATE /etc/fstab
df -hT
df -i                                      # inode usage
cat /proc/mounts
lsblk -f
```

```text
$ findmnt /data
TARGET SOURCE    FSTYPE OPTIONS
/data  /dev/sdb1 xfs    rw,relatime,seclabel,attr2,inode64
```

**`findmnt` is better than `mount`** — it is a readable tree, it filters, and **`findmnt --verify` validates `/etc/fstab`**, which no other tool does.

### /etc/fstab

Six whitespace-separated fields:

```text
UUID=4b2c9e1f-3a8d-4e7f-9c1b-2d5a8f3e6b9c  /data  xfs  defaults  0 0
              1                              2      3      4     5 6
```

| # | Field | Purpose | Common values |
| --- | --- | --- | --- |
| **1** | **Device** | What to mount | **`UUID=...`**, `LABEL=...`, `/dev/vg/lv` |
| **2** | **Mount point** | Where | `/data`, `none` for swap |
| **3** | **Type** | Filesystem | `xfs`, `ext4`, `vfat`, `swap`, `nfs`, `auto` |
| **4** | **Options** | How | **`defaults`**, `noauto`, `nofail`, `ro`, `_netdev` |
| 5 | Dump | Backup flag, obsolete | **`0`** |
| 6 | fsck order | Boot-time check | **`0`** for XFS, `1` for `/`, `2` for others |

```bash
cat /etc/fstab
grep -v '^#' /etc/fstab | grep -v '^$'
```

```text
UUID=4b2c9e1f-...  /                       xfs   defaults        0 0
UUID=8f3a1c2d-...  /boot                   xfs   defaults        0 0
UUID=7d5e3a8b-...  none                    swap  defaults        0 0
UUID=a1b2c3d4-...  /data                   xfs   defaults        0 0
```

**Fields 5 and 6 are `0 0` for everything you will add.** XFS does its own journal recovery and ignores field 6 entirely.

### Why UUID and not /dev/sdb1

```bash
sudo blkid
sudo blkid /dev/sdb1
sudo blkid -s UUID -o value /dev/sdb1
lsblk -f
```

**Device names depend on detection order.** Add a disk, change a controller, or boot with a USB stick inserted, and today's `/dev/sdb` becomes tomorrow's `/dev/sdc`. The `/etc/fstab` entry then mounts the wrong filesystem or fails — and a failure at boot means emergency mode.

**A UUID belongs to the filesystem and never changes** unless you re-run `mkfs`.

| Identifier | Stable across | Use in fstab |
| --- | --- | --- |
| `/dev/sdb1` | Nothing reliable | **Avoid** |
| **`UUID=...`** | **Everything except `mkfs`** | **Preferred** |
| `LABEL=...` | Everything except `mkfs`/relabel | Acceptable |
| `/dev/vg/lv` | Everything except renaming | Acceptable for LVM |

**The objective explicitly says "by UUID or label", so this is graded.** Write the line without transcribing anything:

```bash
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1)  /data  xfs  defaults  0 0" | sudo tee -a /etc/fstab
```

**That one-liner eliminates the mistyped-UUID failure mode**, which is one of the most common ways to end up in emergency mode.

Labels:

```bash
sudo xfs_admin -L mydata /dev/sdb1         # XFS — must be UNMOUNTED
sudo xfs_admin -l /dev/sdb1                # read the label
sudo e2label /dev/sdb1 mydata              # ext4
sudo e2label /dev/sdb1
sudo fatlabel /dev/sdb1 MYDATA             # vfat
lsblk -f
```

### Mount options

| Option | Effect |
| --- | --- |
| **`defaults`** | `rw,suid,dev,exec,auto,nouser,async` |
| `ro` / `rw` | Read-only / read-write |
| `noexec` | Forbid executing binaries |
| `nosuid` | Ignore SUID bits |
| `nodev` | Ignore device files |
| **`noauto`** | **Do NOT mount at boot or with `mount -a`** |
| **`nofail`** | **Do not fail the boot if the device is missing** |
| `_netdev` | Wait for the network — **required for NFS and iSCSI** |
| `user` | Allow any user to mount |
| `acl` | Enable POSIX ACLs (default on XFS) |
| `usrquota`, `grpquota` | Enable quotas |
| `x-systemd.automount` | Mount on first access |
| `noatime`, `relatime` | Reduce access-time writes |
| `uid=`, `gid=`, `dmask=`, `fmask=` | **vfat ownership and permissions** |

Combine with commas, no spaces:

```text
UUID=xxx  /data  xfs   defaults,nofail          0 0
UUID=xxx  /data  ext4  defaults,noexec,nosuid   0 0
UUID=xxx  /usb   vfat  defaults,uid=1000,gid=1000 0 0
server:/export /nfs nfs defaults,_netdev        0 0
```

**`nofail` is a safety net worth using on every non-critical mount.** With `nofail`, a missing device is skipped and the boot continues; without it, the boot stops in emergency mode. Use it for data mounts, removable media, and anything you are experimenting with.

**But read the task.** If it says "mount at boot", the entry must actually mount — `noauto` would fail the task, whereas `nofail` still mounts when the device is present.

### The verification ritual

**Run these two commands after every `/etc/fstab` change, without exception:**

```bash
sudo findmnt --verify
sudo mount -a
```

```text
$ sudo findmnt --verify
Success, no errors or warnings detected
```

`findmnt --verify` catches syntax errors, unknown filesystem types, missing mount points, and unresolvable UUIDs. `mount -a` proves every entry actually mounts.

```text
$ sudo findmnt --verify
/data: unreachable source: UUID=wrong-uuid-here
```

**If either fails, do not reboot.** Fix `/etc/fstab` first. This is the highest-value habit on the entire exam.

A fuller test:

```bash
sudo umount /data
sudo mount -a
findmnt /data
df -hT /data
```

**Unmounting first and then `mount -a` proves the fstab line works**, rather than merely that your earlier manual mount is still in place.

### Recovering from a bad fstab

If you do reboot with a broken `/etc/fstab`:

```text
[FAILED] Failed to mount /data.
[DEPEND] Dependency failed for Local File Systems.
Give root password for maintenance:
(or press Control-D to continue)
```

```bash
# Enter the root password, then:
mount -o remount,rw /            # the root fs is READ-ONLY in emergency mode
vim /etc/fstab                   # fix or comment out the bad line
findmnt --verify
mount -a
reboot
```

**`mount -o remount,rw /` first.** In emergency mode `/` is read-only, so `vim` cannot save and people panic. See `15-systemd-targets-boot.md` and `16-boot-interrupt-root-recovery.md`.

### Growing a filesystem

```bash
# XFS — the MOUNT POINT, and it must be mounted
sudo xfs_growfs /data
sudo xfs_growfs -D 1000000 /data           # to a specific block count

# ext4 — the DEVICE, mounted or not
sudo resize2fs /dev/sdb1
sudo resize2fs /dev/sdb1 2G

# LVM does both at once
sudo lvextend -r -L +500M /dev/vg01/lv01
```

| | XFS | ext4 |
| --- | --- | --- |
| Grow | **`xfs_growfs MOUNTPOINT`** | `resize2fs DEVICE` |
| Must be mounted to grow | **Yes** | No |
| Shrink | **Impossible** | Yes, unmounted, after `e2fsck -f` |

**The argument type is the thing people get wrong**: `xfs_growfs` takes a mount point, `resize2fs` takes a device.

### Checking and repairing

```bash
# ext4 — MUST be unmounted
sudo umount /data
sudo e2fsck -f /dev/sdb1
sudo fsck /dev/sdb1
sudo fsck -y /dev/sdb1

# XFS — MUST be unmounted
sudo umount /data
sudo xfs_repair /dev/sdb1
sudo xfs_repair -n /dev/sdb1               # -n = check only, change nothing
sudo xfs_info /data                        # info on a MOUNTED xfs
sudo xfs_db -c frag -r /dev/sdb1
```

**Never fsck or xfs_repair a mounted filesystem** — it corrupts it. Unmount first, always.

### Space and inodes

```bash
df -h
df -hT
df -i                                      # INODES
du -sh /data
du -sh /data/* | sort -h
du -h --max-depth=1 /var | sort -h
sudo du -sh /var/log
```

**"No space left on device" with `df -h` showing free space means inode exhaustion.** Check `df -i`:

```text
$ df -i /data
Filesystem                Inodes  IUsed  IFree IUse% Mounted on
/dev/sdb1                 524288 524288      0  100% /data
```

Millions of tiny files do this. XFS allocates inodes dynamically and is largely immune; ext4 fixes the count at `mkfs` time.

### Automatic mounting on access

```text
UUID=xxx  /data  xfs  defaults,x-systemd.automount,x-systemd.idle-timeout=60  0 0
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart local-fs.target
```

The filesystem is mounted on first access and unmounted after the idle timeout. **Useful for slow or removable devices.** For NFS this is usually done with autofs instead — see `32-nfs-autofs.md`.

### SELinux and mounting

```bash
ls -Zd /data
sudo restorecon -Rv /data
```

**A newly created filesystem mounted on a new directory gets a default context that may be wrong for a service.** If the mount is going to hold web content or similar:

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/data(/.*)?"
sudo restorecon -Rv /data
```

**A `mount` can also hide the context of the underlying directory.** After mounting, `ls -Zd /data` shows the mounted filesystem's root, not the original directory. See `27-selinux.md`.

### The full workflow

```bash
# 1. Identify (28-disks-partitions.md)
lsblk

# 2. Partition (28-disks-partitions.md)
sudo fdisk /dev/sdb          # n, Enter, Enter, +1G, w
sudo partprobe /dev/sdb

# 3. Filesystem
sudo mkfs.xfs /dev/sdb1

# 4. Mount point
sudo mkdir -p /data

# 5. Test mount
sudo mount /dev/sdb1 /data
df -hT /data

# 6. PERSIST
sudo blkid /dev/sdb1
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1)  /data  xfs  defaults  0 0" | sudo tee -a /etc/fstab

# 7. VERIFY — never skip
sudo findmnt --verify
sudo umount /data
sudo mount -a
df -hT /data

# 8. Prove it
sudo reboot
df -hT /data
```

**Steps 6 and 7 are where the marks are.**

## Tasks

**Task 1.** Report every mounted filesystem with its type, size, usage, and mount point, using three different commands.

**Task 2.** Create an XFS filesystem on a 1 GiB partition, mount it at `/data`, and confirm the type and size.

**Task 3.** Make that mount persistent using the UUID, then verify it without rebooting.

**Task 4.** Verify the mount survives a reboot.

**Task 5.** Create an ext4 filesystem with the label `archive`, mount it at `/archive` by label, and make it persistent by label.

**Task 6.** Create a vfat filesystem on a partition, mount it at `/removable`, and make it writable by the user `alice`.

**Task 7.** Add a mount that is defined in `/etc/fstab` but not mounted automatically at boot, then mount it by name.

**Task 8.** Add a data mount with an option that prevents a missing device from breaking the boot, and explain the difference from `noauto`.

**Task 9.** Mount a filesystem read-only, then convert it to read-write without unmounting.

**Task 10.** Mount a filesystem so binaries on it cannot be executed and SUID bits are ignored. Prove both.

**Task 11.** Report the UUID, label, and type of every block device on the system.

**Task 12.** Change the label of an existing XFS filesystem and of an ext4 filesystem.

**Task 13.** Grow an XFS filesystem after its underlying device has been enlarged, then do the same for ext4.

**Task 14.** Check and repair an unmounted ext4 filesystem, then an unmounted XFS filesystem.

**Task 15.** `umount /data` reports "target is busy". Diagnose and resolve it.

**Task 16.** Deliberately write a broken `/etc/fstab` entry, detect the problem before rebooting, and fix it.

**Task 17.** The system has booted into emergency mode because of a bad `/etc/fstab`. Recover it.

**Task 18.** A filesystem reports "No space left on device" but `df -h` shows free space. Diagnose it.

**Task 19.** Report the ten largest directories under `/var`.

**Task 20.** Configure a filesystem to be mounted automatically on first access rather than at boot.

**Task 21.** Verify every filesystem and `/etc/fstab` entry survives a reboot.

---

## Solutions

**Task 1.**

```bash
df -hT
```

```text
Filesystem              Type      Size  Used Avail Use% Mounted on
devtmpfs                devtmpfs  4.0M     0  4.0M   0% /dev
tmpfs                   tmpfs     892M     0  892M   0% /dev/shm
/dev/mapper/rhel-root   xfs        17G  2.1G   15G  13% /
/dev/sda1               xfs      1014M  247M  768M  25% /boot
tmpfs                   tmpfs     179M     0  179M   0% /run/user/1000
```

```bash
findmnt
findmnt -t xfs,ext4
findmnt --real                    # exclude pseudo-filesystems
```

```text
TARGET      SOURCE                FSTYPE OPTIONS
/           /dev/mapper/rhel-root xfs    rw,relatime,seclabel,attr2
├─/boot     /dev/sda1             xfs    rw,relatime,seclabel,attr2
└─/data     /dev/sdb1             xfs    rw,relatime,seclabel,attr2
```

```bash
lsblk -f
mount | column -t
cat /proc/mounts
```

Which to use when:

| Command | Best for |
| --- | --- |
| **`df -hT`** | **Sizes and usage.** `-T` adds the type |
| **`findmnt`** | **The mount tree, options, and filtering** |
| `lsblk -f` | Devices, UUIDs, and what is mounted where |
| `mount` | Everything, unfiltered and verbose |
| **`findmnt --verify`** | **Validating `/etc/fstab`** |

**`df -hT` and `findmnt` are the two to have in your fingers.** `findmnt --real` hides the dozens of pseudo-filesystems that clutter `mount` output.

**Task 2.**

```bash
lsblk
sudo mkfs.xfs /dev/sdb1
```

```text
meta-data=/dev/sdb1     isize=512    agcount=4, agsize=65536 blks
data     =              bsize=4096   blocks=262144, imaxpct=25
naming   =version 2     bsize=4096   ascii-ci=0, ftype=1
log      =internal log  bsize=4096   blocks=2560, version=2
```

```bash
sudo mkdir -p /data
sudo mount /dev/sdb1 /data
df -hT /data
findmnt /data
```

```text
Filesystem     Type  Size  Used Avail Use% Mounted on
/dev/sdb1      xfs  1014M   40M  975M   4% /data
```

**Note the usable size is 975 M, not 1024 M** — filesystem metadata and the journal account for the difference. Normal.

```bash
sudo blkid /dev/sdb1
lsblk -f /dev/sdb1
```

Points to note:

- **The mount point must exist.** `mount` fails with "mount point does not exist" otherwise.
- **`mkfs.xfs` destroys everything on the device**, with only a warning if a signature is present. Use `-f` to force:

```bash
sudo mkfs.xfs -f /dev/sdb1
```

- **This mount is not persistent.** A reboot loses it. Task 3.
- Test it works:

```bash
echo "hello" | sudo tee /data/test.txt
cat /data/test.txt
ls -Zd /data
```

**Task 3.**

```bash
sudo blkid /dev/sdb1
```

```text
/dev/sdb1: UUID="4b2c9e1f-3a8d-4e7f-9c1b-2d5a8f3e6b9c" TYPE="xfs" PARTUUID="..."
```

**Write the line without transcribing the UUID by hand:**

```bash
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1)  /data  xfs  defaults  0 0" | sudo tee -a /etc/fstab
```

```bash
tail -1 /etc/fstab
```

```text
UUID=4b2c9e1f-3a8d-4e7f-9c1b-2d5a8f3e6b9c  /data  xfs  defaults  0 0
```

**Now verify — and this is the part that matters:**

```bash
sudo findmnt --verify
```

```text
Success, no errors or warnings detected
```

```bash
sudo umount /data
findmnt /data                     # no output — confirmed unmounted
sudo mount -a
findmnt /data
df -hT /data
```

**Unmounting first is the real test.** It proves the `/etc/fstab` line works, rather than merely that your earlier manual mount is still there.

Why each part is as it is:

| Field | Value | Why |
| --- | --- | --- |
| Device | **`UUID=...`** | **Device names can change; UUIDs cannot.** The objective requires UUID or label |
| Mount point | `/data` | Must already exist |
| Type | `xfs` | Must match the actual filesystem. `auto` works but is vague |
| Options | `defaults` | `rw,suid,dev,exec,auto,nouser,async` |
| Dump | `0` | Obsolete |
| fsck | `0` | XFS journals; it ignores this field |

**The two failure modes:**

```bash
# A mistyped UUID
sudo findmnt --verify
# /data: unreachable source: UUID=4b2c9e1f-WRONG

# Using sudo echo >> instead of sudo tee -a
echo "..." >> /etc/fstab
# bash: /etc/fstab: Permission denied     ← redirection runs as YOU, not root
```

**Use `sudo tee -a`.** And note `-a`; without it `tee` truncates `/etc/fstab`, which is a catastrophe. See `02-redirection-pipes.md`.

**Task 4.**

```bash
sudo findmnt --verify
sudo mount -a && echo "mount -a OK"
grep data /etc/fstab
sudo reboot
```

After:

```bash
df -hT /data
findmnt /data
cat /data/test.txt
mount | grep data
```

```text
Filesystem     Type  Size  Used Avail Use% Mounted on
/dev/sdb1      xfs  1014M   40M  975M   4% /data
```

**Mounted, correct type, correct size, and the data is there.**

If it is not mounted:

```bash
grep data /etc/fstab              # is the line there at all?
sudo findmnt --verify             # is it valid?
sudo mount -a                     # what is the actual error?
sudo blkid /dev/sdb1              # does the UUID match?
systemctl --failed
journalctl -b | grep -i 'data\|mount'
systemctl status data.mount
```

**systemd turns each `/etc/fstab` line into a `.mount` unit**, so failures appear in `systemctl` and the journal:

```bash
systemctl list-units --type=mount
systemctl status data.mount
```

| Symptom | Cause |
| --- | --- |
| Not mounted, no error | **No `/etc/fstab` entry**, or `noauto` |
| Emergency mode at boot | **Bad entry** — wrong UUID, wrong type, missing mount point |
| Mounted read-only | `ro` in the options, or filesystem errors |
| Wrong size | Filesystem never grown after the device was enlarged |

**Task 5.**

```bash
sudo mkfs.ext4 -L archive /dev/sdb2
```

```text
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: 9c1b2d5a-...
```

Or label it afterwards:

```bash
sudo mkfs.ext4 /dev/sdb2
sudo e2label /dev/sdb2 archive
sudo e2label /dev/sdb2
```

```bash
sudo mkdir -p /archive
sudo mount LABEL=archive /archive
df -hT /archive
lsblk -f /dev/sdb2
```

```text
NAME   FSTYPE LABEL   UUID                                 MOUNTPOINTS
sdb2   ext4   archive 9c1b2d5a-...                         /archive
```

Persist it by label:

```bash
echo "LABEL=archive  /archive  ext4  defaults  0 2" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo umount /archive
sudo mount -a
df -hT /archive
```

**`LABEL=` is explicitly permitted by the objective** — "mount file systems at boot by universally unique ID (UUID) or label".

| | UUID | LABEL |
| --- | --- | --- |
| Uniqueness | **Guaranteed** | **You must ensure it** |
| Readability | Poor | **Good** |
| Changed by | `mkfs` | `mkfs`, `e2label`, `xfs_admin -L` |
| Risk | Typos | **Duplicate labels on two devices** |

**Duplicate labels are the danger** — two filesystems labelled `archive` means the mount is a coin toss. UUIDs cannot collide.

Note `0 2` in the last two fields here: **ext4 supports boot-time fsck**, and `2` means "check after the root filesystem". `0` also works. **XFS always uses `0`** because it recovers from its journal instead.

Label commands per filesystem:

```bash
sudo e2label /dev/sdb2 archive             # ext4 — works mounted or not
sudo xfs_admin -L archive /dev/sdb1        # XFS — must be UNMOUNTED
sudo fatlabel /dev/sdb3 ARCHIVE            # vfat — uppercase
lsblk -f
```

**Task 6.**

```bash
sudo dnf install -y dosfstools
sudo mkfs.vfat -n REMOVABLE /dev/sdb3
sudo mkdir -p /removable
id alice
```

vfat stores no ownership or permissions, so they are set at mount time:

```bash
sudo mount -o uid=$(id -u alice),gid=$(id -g alice),umask=022 /dev/sdb3 /removable
ls -ld /removable
sudo -u alice touch /removable/alice-file.txt
ls -l /removable
```

```text
drwxr-xr-x. 2 alice alice 4096 Aug 18 15:30 /removable
-rwxr-xr-x. 1 alice alice    0 Aug 18 15:31 /removable/alice-file.txt
```

Persist it:

```bash
ALICE_UID=$(id -u alice); ALICE_GID=$(id -g alice)
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb3)  /removable  vfat  defaults,uid=$ALICE_UID,gid=$ALICE_GID,umask=022  0 0" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo umount /removable
sudo mount -a
ls -ld /removable
```

**The key insight: vfat has no concept of Unix ownership or permissions.** `chown` and `chmod` on a vfat filesystem do nothing:

```bash
sudo chown alice /removable/alice-file.txt
ls -l /removable/alice-file.txt            # unchanged
```

Everything is controlled by mount options:

| Option | Effect |
| --- | --- |
| **`uid=1001`** | **Owner of every file** |
| **`gid=1001`** | **Group of every file** |
| `umask=022` | Permission mask for files and directories |
| `dmask=022` | Directories only |
| `fmask=133` | Files only |
| `shortname=winnt` | Filename handling |
| `utf8` | Unicode filenames |

**Use numeric IDs in `/etc/fstab`.** Names work on modern systems but numeric IDs are unambiguous and always work.

Other vfat quirks worth knowing:

- **Labels are uppercase, 11 characters maximum**, set with `-n`.
- **No symbolic links, no hard links, no SELinux labels.**
- The exam includes vfat because of EFI system partitions and USB media.
- `blkid` reports `TYPE="vfat"`; `mkfs.vfat` and `mkfs.fat` are the same tool.

**Task 7.**

```bash
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb4)  /manual  xfs  defaults,noauto  0 0" | sudo tee -a /etc/fstab
sudo mkdir -p /manual
sudo findmnt --verify
```

`mount -a` skips it:

```bash
sudo mount -a
findmnt /manual                   # no output
```

Mount it by name:

```bash
sudo mount /manual
findmnt /manual
df -hT /manual
```

```text
TARGET   SOURCE    FSTYPE OPTIONS
/manual  /dev/sdb4 xfs    rw,relatime,seclabel
```

**`mount /manual` works because `/etc/fstab` supplies the device, type, and options** — you only need to name either the mount point or the device:

```bash
sudo mount /manual
sudo mount /dev/sdb4              # equally valid
```

**`noauto` means "do not mount at boot or with `mount -a`, but remember how".** Useful for removable media and rarely-used filesystems.

**Careful on the exam:**

| Task wording | Option |
| --- | --- |
| "mount at boot" | **`defaults`** — do NOT use `noauto` |
| "available for manual mounting" | **`noauto`** |
| "do not break the boot if missing" | **`nofail`** |
| "mount on first access" | `x-systemd.automount` |

**`noauto` fails a task that says "mount at boot"**, because after the grader's reboot the filesystem is not mounted. Read the wording carefully.

**Task 8.**

```bash
sudo sed -i 's|\(UUID=.*/data.*\)defaults|\1defaults,nofail|' /etc/fstab
grep data /etc/fstab
```

Or write it directly:

```bash
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1)  /data  xfs  defaults,nofail  0 0" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo mount -a
```

Demonstrate the difference. Point an entry at a device that does not exist:

```bash
echo "UUID=00000000-0000-0000-0000-000000000000  /missing  xfs  defaults  0 0" | sudo tee -a /etc/fstab
sudo mkdir -p /missing
sudo findmnt --verify
```

```text
/missing: unreachable source: UUID=00000000-0000-0000-0000-000000000000
```

```bash
sudo mount -a
```

```text
mount: /missing: can't find UUID=00000000-....
```

**Rebooting with that entry lands you in emergency mode.** Add `nofail`:

```bash
sudo sed -i 's|/missing  xfs  defaults|/missing  xfs  defaults,nofail|' /etc/fstab
sudo mount -a && echo "mount -a OK"
```

**Now the missing device is skipped and the boot proceeds.**

| Option | Device missing at boot | Device present at boot | With `mount -a` |
| --- | --- | --- | --- |
| `defaults` | **BOOT FAILS — emergency mode** | Mounted | Error |
| **`nofail`** | **Skipped, boot continues** | **Mounted** | Silently skipped |
| `noauto` | Skipped | **NOT mounted** | Skipped |
| `nofail,noauto` | Skipped | NOT mounted | Skipped |

**`nofail` and `noauto` are completely different:**

- **`nofail`** — mount it if you can, do not fail the boot if you cannot. **The device is mounted when present.**
- **`noauto`** — do not mount it at boot at all. **The device is not mounted even when present.**

**So `nofail` is the safety net you want**, and `noauto` is a deliberate choice for manual mounting.

**Use `nofail` on every non-critical mount you add during the exam.** It cannot cost you a task that says "mount at boot" — the filesystem still mounts — and it protects you from the worst outcome. Do not put it on `/`, `/boot`, or `/usr`.

Remove the test entry:

```bash
sudo sed -i '/missing/d' /etc/fstab
sudo rmdir /missing
sudo findmnt --verify
```

**Task 9.**

```bash
sudo mount -o ro /dev/sdb1 /data
findmnt /data
```

```text
TARGET SOURCE    FSTYPE OPTIONS
/data  /dev/sdb1 xfs    ro,relatime,seclabel
```

```bash
sudo touch /data/newfile
```

```text
touch: cannot touch '/data/newfile': Read-only file system
```

Convert without unmounting:

```bash
sudo mount -o remount,rw /data
findmnt /data
sudo touch /data/newfile && echo "write OK"
```

```text
TARGET SOURCE    FSTYPE OPTIONS
/data  /dev/sdb1 xfs    rw,relatime,seclabel
```

**`mount -o remount,OPTIONS /mountpoint` changes options in place**, with no unmount and no interruption to open files.

```bash
sudo mount -o remount,ro /data
sudo mount -o remount,rw /data
sudo mount -o remount,noexec /data
sudo mount -o remount,rw,noatime /data
```

**The single most important use of this command is emergency-mode recovery:**

```bash
mount -o remount,rw /            # THE command when / is read-only
```

In emergency mode `/` is mounted read-only, so `vim /etc/fstab` cannot save. **Without this command you cannot repair a broken `/etc/fstab`.** See `16-boot-interrupt-root-recovery.md` and Task 17 below.

Note that `remount` does not change the device or mount point, only the options. And a filesystem may be remounted read-only automatically after I/O errors:

```bash
findmnt -o TARGET,OPTIONS | grep ro,
sudo dmesg | grep -i 'remount\|error'
journalctl -k | grep -i 'i/o error'
```

**An unexpectedly read-only filesystem usually means the kernel found errors**, not that someone set `ro`. Check `dmesg` and consider `xfs_repair`.

**Task 10.**

```bash
sudo mount -o remount,noexec,nosuid /data
findmnt /data
```

```text
TARGET SOURCE    FSTYPE OPTIONS
/data  /dev/sdb1 xfs    rw,nosuid,noexec,relatime,seclabel
```

Prove `noexec`:

```bash
sudo cp /bin/echo /data/
sudo chmod 755 /data/echo
/data/echo "hello"
```

```text
bash: /data/echo: Permission denied
```

```bash
ls -l /data/echo                  # the execute bit IS set
```

**The execute bit is present and the file still cannot run. That is the mount option, not the permissions** — a distinction worth recognising when diagnosing "permission denied" on a file that looks executable.

Prove `nosuid`:

```bash
sudo cp /bin/ping /data/
sudo chmod u+s /data/ping
ls -l /data/ping                  # -rwsr-xr-x
sudo -u alice /data/ping -c1 127.0.0.1
```

The SUID bit is ignored, so the binary runs as `alice` rather than `root`.

Persist it:

```bash
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1)  /data  xfs  defaults,nosuid,noexec,nodev  0 0" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo umount /data && sudo mount -a
findmnt /data
```

| Option | Blocks |
| --- | --- |
| **`noexec`** | **Executing any binary or script on the filesystem** |
| **`nosuid`** | **SUID and SGID bits taking effect** |
| `nodev` | Device files being honoured |
| `ro` | All writes |

**These three together are the standard hardening set** for `/tmp`, `/home`, and removable media. A task asking to "mount so that programs cannot be executed" means `noexec`.

**A "Permission denied" that `ls -l` cannot explain has three possible causes:** `noexec`, SELinux, or a missing execute bit on a parent directory. Check `findmnt`, `ausearch -m AVC`, and `namei -l` respectively.

**Task 11.**

```bash
lsblk -f
```

```text
NAME          FSTYPE      LABEL     UUID                                 MOUNTPOINTS
sda
├─sda1        xfs         boot      8f3a1c2d-...                         /boot
└─sda2        LVM2_member           Kx8Zq1-...
  ├─rhel-root xfs                   4b2c9e1f-...                         /
  └─rhel-swap swap                  7d5e3a8b-...                         [SWAP]
sdb
├─sdb1        xfs                   a1b2c3d4-...                         /data
├─sdb2        ext4        archive   9c1b2d5a-...                         /archive
└─sdb3        vfat        REMOVABLE 1A2B-3C4D                            /removable
```

```bash
sudo blkid
lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS
sudo blkid /dev/sdb1
sudo blkid -s UUID -o value /dev/sdb1
sudo blkid -s LABEL -o value /dev/sdb2
sudo blkid -s TYPE -o value /dev/sdb3
```

Note the vfat UUID format, `1A2B-3C4D` — **vfat uses a short 32-bit serial number, not a real UUID.** It still works in `/etc/fstab`.

Per-filesystem detail:

```bash
sudo xfs_info /data                        # mounted XFS
sudo tune2fs -l /dev/sdb2 | head -20       # ext4 superblock
sudo dumpe2fs -h /dev/sdb2                 # ext4 header
sudo fatlabel /dev/sdb3                    # vfat label
```

```bash
findmnt --fstab                            # what /etc/fstab says
findmnt --mtab                             # what is mounted
```

**`findmnt --fstab` versus `findmnt --mtab` is a useful comparison** — it shows configured mounts against actual mounts, and any difference means either something failed to mount or something was mounted manually and is not persistent.

**Task 12.**

XFS — **must be unmounted**:

```bash
sudo umount /data
sudo xfs_admin -L newdata /dev/sdb1
sudo xfs_admin -l /dev/sdb1
sudo mount /data
lsblk -f /dev/sdb1
```

```text
writing all SBs
new label = "newdata"
```

Attempting it while mounted:

```text
$ sudo xfs_admin -L newdata /dev/sdb1
xfs_admin: /dev/sdb1 contains a mounted filesystem
```

ext4 — **works either way**:

```bash
sudo e2label /dev/sdb2 newarchive
sudo e2label /dev/sdb2
sudo tune2fs -L newarchive /dev/sdb2       # equivalent
lsblk -f /dev/sdb2
```

vfat:

```bash
sudo fatlabel /dev/sdb3 NEWREMOV
sudo fatlabel /dev/sdb3
```

| Filesystem | Command | Unmounted required |
| --- | --- | --- |
| **XFS** | **`xfs_admin -L name`** | **Yes** |
| ext4 | `e2label` or `tune2fs -L` | No |
| vfat | `fatlabel` | No |

**Changing a label breaks any `/etc/fstab` entry that uses `LABEL=`:**

```bash
grep LABEL /etc/fstab
sudo sed -i 's/LABEL=archive/LABEL=newarchive/' /etc/fstab
sudo findmnt --verify
sudo mount -a
```

**Forgetting this is a boot failure waiting to happen.** It is also why `UUID=` is the safer default — `mkfs` is the only thing that changes a UUID.

**Task 13.**

XFS. Grow the device first — with LVM:

```bash
sudo lvextend -L +500M /dev/vg01/lv_data    # deliberately without -r
sudo lvs
df -h /data
```

```text
  LV      VG   LSize
  lv_data vg01 1.48g

Filesystem                Size  Used Avail Use% Mounted on
/dev/mapper/vg01-lv_data  1014M   40M  975M   4% /data
```

**The LV is 1.48 G, the filesystem still reports 1014 M.** Grow it:

```bash
sudo xfs_growfs /data
df -h /data
```

```text
data blocks changed from 262144 to 389120

Filesystem                Size  Used Avail Use% Mounted on
/dev/mapper/vg01-lv_data  1.5G   40M  1.5G   3% /data
```

ext4:

```bash
sudo lvextend -L +500M /dev/vg01/lv_arch
sudo resize2fs /dev/vg01/lv_arch
df -h /archive
```

```text
The filesystem on /dev/vg01/lv_arch is now 389120 (4k) blocks long.
```

**The argument types differ and this is what people get wrong:**

| | XFS | ext4 |
| --- | --- | --- |
| Command | **`xfs_growfs`** | **`resize2fs`** |
| Argument | **The MOUNT POINT** (`/data`) | **The DEVICE** (`/dev/vg01/lv_arch`) |
| Must be mounted | **Yes** | No |
| Shrink | **Impossible** | Yes, unmounted |

```bash
sudo xfs_growfs /dev/vg01/lv_data          # FAILS — wants the mount point
sudo resize2fs /archive                    # FAILS — wants the device
```

**Both errors are avoidable by using `lvextend -r`, which calls the right tool automatically:**

```bash
sudo lvextend -r -L +500M /dev/vg01/lv_data
```

For a plain partition rather than an LV:

```bash
sudo parted /dev/sdb resizepart 1 2GiB     # 28-disks-partitions.md
sudo partprobe /dev/sdb
sudo xfs_growfs /data
df -h /data
```

**Verify with `df -h`, not `lvs` or `lsblk`.** Those show the container; `df` shows what is usable.

**Task 14.**

ext4:

```bash
sudo umount /archive
sudo e2fsck -f /dev/sdb2
```

```text
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/sdb2: 11/65536 files (0.0% non-contiguous), 8896/262144 blocks
```

```bash
sudo fsck -y /dev/sdb2                     # answer yes to all repairs
sudo fsck -n /dev/sdb2                     # check only, no changes
sudo mount /archive
```

XFS:

```bash
sudo umount /data
sudo xfs_repair -n /dev/sdb1               # CHECK ONLY first
sudo xfs_repair /dev/sdb1
sudo mount /data
```

```text
Phase 1 - find and verify superblock...
Phase 2 - using internal log
Phase 3 - for each AG...
Phase 4 - check for duplicate blocks...
Phase 5 - rebuild AG headers and trees...
Phase 6 - check inode connectivity...
Phase 7 - verify and correct link counts...
done
```

**Both tools refuse to touch a mounted filesystem:**

```text
$ sudo xfs_repair /dev/sdb1
xfs_repair: /dev/sdb1 contains a mounted filesystem
xfs_repair: cannot continue
```

**That refusal is protecting you** — repairing a mounted filesystem corrupts it.

| | ext4 | XFS |
| --- | --- | --- |
| Check | `e2fsck -n`, `fsck -n` | **`xfs_repair -n`** |
| Repair | **`e2fsck -f`, `fsck -y`** | **`xfs_repair`** |
| Must be unmounted | **Yes** | **Yes** |
| Boot-time check | fstab field 6 | Journal recovery, field 6 ignored |
| Info | `tune2fs -l`, `dumpe2fs` | `xfs_info` (mounted) |

**Always `-n` first.** It reports the damage without changing anything, so you know what you are dealing with.

If `xfs_repair` cannot find a superblock:

```bash
sudo xfs_repair -L /dev/sdb1               # ZERO the log — LAST RESORT, loses data
```

**`-L` discards the journal and any unwritten transactions.** Only when nothing else works.

If the root filesystem needs checking, do it from rescue media or `rescue.target` — you cannot unmount `/` while running from it. See `15-systemd-targets-boot.md`.

**Task 15.**

```bash
sudo umount /data
```

```text
umount: /data: target is busy.
```

Find what is holding it:

```bash
sudo fuser -vm /data
```

```text
                     USER        PID ACCESS COMMAND
/data:               douglas    2345 ..c..  bash
                     root       3456 F....  tail
```

```bash
sudo lsof /data
sudo lsof +D /data
```

Reading the ACCESS column:

| Letter | Meaning |
| --- | --- |
| **`c`** | **The process's current directory is here** |
| `f` | An open file |
| `F` | An open file, being written |
| `r` | Root directory |
| `m` | A mapped file |

**`c` for your own bash is the most common cause. Your shell is sitting in the directory.**

```bash
pwd
cd /
sudo umount /data && echo "unmounted"
```

Other causes and their fixes:

```bash
# 1. Your own shell — check first, it costs nothing
cd /

# 2. Another user's shell or a process
sudo fuser -vm /data
sudo kill 3456
sudo fuser -km /data              # kill everything using it — CAREFUL

# 3. An NFS export of this path
sudo exportfs -ua
sudo systemctl stop nfs-server

# 4. Swap on the device
swapon --show
sudo swapoff /dev/sdb2

# 5. A nested mount below it
findmnt -R /data
sudo umount /data/sub

# 6. A loop device
losetup -a
sudo losetup -d /dev/loop0
```

Last resorts:

```bash
sudo umount -l /data              # LAZY: detach now, unmount when free
sudo umount -f /data              # FORCE: mainly for unreachable NFS
```

**`umount -l` returns immediately and completes when the last user releases it.** Convenient, but the filesystem may still be in use, so do not follow it immediately with `mkfs`.

**The order to try: `cd /`, then `fuser -vm`, then kill, then `-l`.** In practice `cd /` resolves it most of the time.

**Task 16.**

Write a broken entry:

```bash
sudo cp /etc/fstab /root/fstab.bak
echo "UUID=DEADBEEF-0000-0000-0000-000000000000  /broken  xfs  defaults  0 0" | sudo tee -a /etc/fstab
```

**Detect it before rebooting — this is the whole point:**

```bash
sudo findmnt --verify
```

```text
/broken
   [E] unreachable on boot required source: UUID=DEADBEEF-0000-0000-0000-000000000000
   [W] non-existent mountpoint: /broken
```

**Two problems reported, and neither required a reboot to find.**

```bash
sudo mount -a
```

```text
mount: /broken: can't find UUID=DEADBEEF-....
mount: /broken: mount point does not exist.
```

Fix it:

```bash
sudo sed -i '/broken/d' /etc/fstab
sudo findmnt --verify
sudo mount -a && echo "mount -a OK"
```

**`findmnt --verify` catches every common `/etc/fstab` error:**

| Error | Reported as |
| --- | --- |
| Mistyped UUID | `unreachable source` |
| Missing mount point | `non-existent mountpoint` |
| Wrong filesystem type | `unknown filesystem type` |
| Bad option syntax | Parse warnings |
| Too few fields | Parse error |
| Duplicate mount point | Warning |

**Run these two commands after every single `/etc/fstab` edit:**

```bash
sudo findmnt --verify
sudo mount -a && echo OK || echo "*** DO NOT REBOOT ***"
```

**If either fails, fix it before rebooting.** The exam is graded after a reboot; a machine in emergency mode scores nothing on any storage task and costs you the time to recover.

Keep a backup so recovery is trivial:

```bash
sudo cp /etc/fstab /root/fstab.bak
# if things go wrong:
sudo cp /root/fstab.bak /etc/fstab
```

**Task 17.**

The boot output:

```text
[FAILED] Failed to mount /data.
[DEPEND] Dependency failed for Local File Systems.
[DEPEND] Dependency failed for Mark the need to relabel after reboot.
You are in emergency mode. After logging in, type "journalctl -xb" to view
system logs, "systemctl reboot" to reboot, or "exit" to continue bootup.
Give root password for maintenance:
```

Recovery:

```bash
# 1. Enter the root password
# 2. THE CRITICAL STEP — / is read-only
mount -o remount,rw /

# 3. Find the problem
cat /etc/fstab
findmnt --verify
journalctl -xb | grep -i 'mount\|fail'
systemctl --failed
lsblk
blkid
```

```bash
# 4. Fix it — comment out or correct the offending line
vi /etc/fstab
#   or:
sed -i '/data/d' /etc/fstab
#   or add nofail:
sed -i 's|/data  xfs  defaults|/data  xfs  defaults,nofail|' /etc/fstab
```

```bash
# 5. Verify BEFORE rebooting
findmnt --verify
mount -a

# 6. Reboot
reboot
```

**`mount -o remount,rw /` is the command that makes this recoverable.** Without it:

```text
$ vi /etc/fstab
E212: Can't open file for writing
```

People then panic, reboot, and land back in emergency mode. **Memorise it.**

Diagnosing the specific cause:

```bash
blkid                             # what UUIDs actually exist
grep UUID /etc/fstab              # what fstab expects
lsblk                             # is the device even present
findmnt --verify                  # what is wrong with the file
```

| Cause | Fix |
| --- | --- |
| Mistyped UUID | Correct it from `blkid` |
| Device removed | Delete the line, or add `nofail` |
| Wrong filesystem type | Correct field 3 |
| Mount point missing | `mkdir -p /data` |
| Missing field | Rewrite the line |

**Three habits that avoid this entirely:**

1. **`findmnt --verify` and `mount -a` after every fstab edit.** If they fail, do not reboot.
2. **`nofail` on non-critical mounts.** A missing device is then skipped.
3. **`sudo cp /etc/fstab /root/fstab.bak` before editing.**

Related recovery topics: `15-systemd-targets-boot.md` for targets and emergency mode, `16-boot-interrupt-root-recovery.md` for `rd.break` and boot interruption.

**Task 18.**

```bash
sudo touch /data/newfile
```

```text
touch: cannot touch '/data/newfile': No space left on device
```

```bash
df -h /data
```

```text
Filesystem                Size  Used Avail Use% Mounted on
/dev/mapper/vg01-lv_data  1.5G  120M  1.4G   8% /data
```

**Plenty of space, yet writes fail. Check inodes:**

```bash
df -i /data
```

```text
Filesystem                 Inodes  IUsed IFree IUse% Mounted on
/dev/mapper/vg01-lv_data   524288 524288     0  100% /data
```

**`IUse% 100` — the filesystem is out of inodes.** Every file, directory, and symlink consumes one, regardless of size. Millions of tiny files exhaust the inode table long before the blocks.

Find the culprit:

```bash
sudo find /data -xdev -type f | wc -l
for d in /data/*; do echo "$(sudo find "$d" -type f 2>/dev/null | wc -l) $d"; done | sort -rn | head
sudo du --inodes -d1 /data 2>/dev/null | sort -rn | head
```

Fixes:

```bash
# a. Delete the files
sudo find /data/cache -type f -mtime +30 -delete

# b. Recreate with more inodes (ext4 only) — DESTROYS DATA
sudo umount /data
sudo mkfs.ext4 -N 2000000 /dev/vg01/lv_data
sudo mkfs.ext4 -i 4096 /dev/vg01/lv_data     # bytes per inode

# c. Use XFS, which allocates inodes dynamically
sudo mkfs.xfs /dev/vg01/lv_data
```

**ext4 fixes the inode count at `mkfs` time and it cannot be increased later. XFS allocates dynamically and is effectively immune.** That is one reason RHEL defaults to XFS.

The other two causes of the same symptom:

```bash
# Reserved blocks — ext4 keeps 5% for root by default
sudo tune2fs -l /dev/sdb2 | grep -i 'reserved block count'
sudo tune2fs -m 1 /dev/sdb2       # reduce the reservation to 1%
```

A non-root user sees "No space left" while `df` shows about 5 percent free.

```bash
# Deleted-but-open files: space not reclaimed until the process closes them
sudo lsof +L1
sudo lsof | grep deleted
```

**A deleted log file held open by a running daemon still occupies its blocks.** `df` shows the space used, `du` does not. Restart the process:

```bash
sudo systemctl restart rsyslog
df -h /var
```

**The diagnostic order for "No space left on device":**

```bash
df -h /path                       # 1. blocks actually full?
df -i /path                       # 2. inodes full?
sudo lsof +L1                     # 3. deleted files held open?
sudo tune2fs -l /dev/X | grep -i reserved   # 4. ext4 reserve?
```

**Task 19.**

```bash
sudo du -h --max-depth=1 /var | sort -h | tail -10
```

```text
16M	/var/tmp
28M	/var/cache
124M	/var/lib
340M	/var/log
512M	/var
```

Variations:

```bash
sudo du -sh /var/*| sort -h | tail -10
sudo du -h --max-depth=2 /var 2>/dev/null | sort -h | tail -20
sudo du -sh /var/* 2>/dev/null | sort -rh | head -10
sudo du -ah /var 2>/dev/null | sort -rh | head -20        # files too
```

```bash
sudo du -x --max-depth=1 /var | sort -n        # -x stays on one filesystem
sudo find /var -xdev -type f -size +50M -exec ls -lh {} \; 2>/dev/null
sudo find /var -xdev -type f -printf '%s %p\n' | sort -rn | head
```

Points worth knowing:

- **`sort -h`** sorts human-readable sizes correctly; **`sort -n`** does not understand `M` and `G`.
- **`sort -rh | head`** and **`sort -h | tail`** are equivalent.
- **`-x` / `--one-file-system`** keeps `du` from wandering into other mounts.
- **`2>/dev/null`** suppresses permission errors when not running as root.
- **`du` measures disk usage; `df` measures the filesystem.** They disagree when files are deleted but held open (Task 18) or when sparse files are involved.

The usual suspects on a RHEL system:

```bash
sudo du -sh /var/log/journal      # the systemd journal — often the largest
sudo journalctl --disk-usage
sudo journalctl --vacuum-size=200M
sudo journalctl --vacuum-time=7d

sudo du -sh /var/cache/dnf
sudo dnf clean all

sudo du -sh /var/lib/containers   # podman images
podman system prune -a
```

**`/var/log/journal` is very often the answer.** `journalctl --vacuum-size=200M` reclaims it immediately. See `18-logs-journald.md`.

**Task 20.**

```bash
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb4)  /ondemand  xfs  defaults,x-systemd.automount,x-systemd.idle-timeout=60  0 0" | sudo tee -a /etc/fstab
sudo mkdir -p /ondemand
sudo systemctl daemon-reload
sudo systemctl restart local-fs.target
```

```bash
findmnt /ondemand                 # not mounted yet
systemctl list-units --type=automount | grep ondemand
```

```text
ondemand.automount  loaded active waiting  ondemand.automount
```

Access it:

```bash
ls /ondemand
findmnt /ondemand
```

```text
TARGET     SOURCE    FSTYPE OPTIONS
/ondemand  /dev/sdb4 xfs    rw,relatime,seclabel
```

**The mount happened on access.** After 60 idle seconds it unmounts again:

```bash
sleep 70
findmnt /ondemand                 # no output
systemctl status ondemand.automount
```

Useful options:

| Option | Effect |
| --- | --- |
| **`x-systemd.automount`** | **Mount on first access** |
| `x-systemd.idle-timeout=60` | Unmount after 60 idle seconds |
| `x-systemd.device-timeout=10` | Give up waiting for the device after 10 s |
| `x-systemd.requires=` | Order after another unit |
| `_netdev` | Wait for the network |
| `noauto` | Implied by `x-systemd.automount` |

**`systemctl daemon-reload` is required** after editing `/etc/fstab` when using `x-systemd.*` options, because systemd generates the `.automount` and `.mount` units from the file.

```bash
systemctl cat ondemand.mount
systemctl cat ondemand.automount
systemctl list-units --type=mount
systemctl list-units --type=automount
```

**For NFS, autofs is the conventional and exam-expected answer** rather than `x-systemd.automount` — see `32-nfs-autofs.md`. This mechanism is worth knowing for local devices, particularly slow or removable ones.

**Task 21.**

Before the reboot:

```bash
grep -v '^#' /etc/fstab | grep -v '^$'
sudo findmnt --verify
sudo mount -a && echo "mount -a OK"
df -hT
findmnt --real
lsblk -f
```

Everything must be true:

- **`findmnt --verify` reports no errors.**
- **`mount -a` succeeds.**
- Every mount a task required is present in `/etc/fstab`.
- Entries use **`UUID=` or `LABEL=`**, as the objective requires.
- `df -hT` shows the expected types and sizes.

**The strongest possible test — unmount everything you added and remount from `/etc/fstab`:**

```bash
sudo umount /data /archive /removable
sudo mount -a
df -hT
```

If that works, the reboot will work.

```bash
sudo reboot
```

After:

```bash
df -hT
findmnt --real
lsblk -f
systemctl --failed
systemctl list-units --type=mount --state=failed
journalctl -b -p err
cat /data/test.txt
```

**`systemctl --failed` being empty and `df -hT` showing every filesystem is the confirmation.**

| Symptom | Cause |
| --- | --- |
| Filesystem absent from `df` | **No `/etc/fstab` entry**, or `noauto` |
| Emergency mode | **Bad `/etc/fstab` entry** |
| Present but wrong size | Filesystem never grown after the device was |
| Present but read-only | `ro` in the options, or filesystem errors |
| Wrong ownership on vfat | Missing `uid=`/`gid=` options |

```bash
# The storage pre-reboot check, in four lines
sudo findmnt --verify
sudo mount -a && echo OK || echo "*** FIX FSTAB — DO NOT REBOOT ***"
df -hT
grep -v '^#' /etc/fstab | grep -v '^$'
```

---

## Verify

```bash
df -hT
df -i
findmnt
findmnt --real
findmnt --verify
findmnt --fstab
findmnt /data
lsblk -f
sudo blkid
sudo blkid -s UUID -o value /dev/sdb1
grep -v '^#' /etc/fstab | grep -v '^$'
sudo mount -a
mount | grep /data
sudo xfs_info /data
sudo tune2fs -l /dev/sdb2 | head
systemctl list-units --type=mount
systemctl --failed
```

## Persistence Check

| Change | Persistent form | Also required |
| --- | --- | --- |
| Filesystem created | `mkfs` writes to the device | — |
| Label | `xfs_admin -L`, `e2label`, `fatlabel` | Update `LABEL=` in fstab |
| **Mount** | **An `/etc/fstab` entry** | **`findmnt --verify` + `mount -a`** |
| Mount options | The options field in `/etc/fstab` | `mount -o remount` for the current session |
| Filesystem grown | The filesystem itself | `xfs_growfs` / `resize2fs` / `lvextend -r` |
| `x-systemd.*` options | `/etc/fstab` | **`systemctl daemon-reload`** |

**`mount` on the command line never persists. `/etc/fstab` is the only thing that does.**

```bash
# The two commands to run after EVERY fstab change
sudo findmnt --verify
sudo mount -a && echo OK || echo "*** DO NOT REBOOT ***"
```

**The two failure modes point in opposite directions:**

1. **No `/etc/fstab` entry** — the filesystem is not mounted after the reboot and the task scores nothing.
2. **A bad `/etc/fstab` entry** — the machine boots into emergency mode and every storage task scores nothing.

**`nofail` protects against the second** without compromising the first, so use it on non-critical data mounts.

## Exam Tips

- **`/etc/fstab` is the most important file on this exam.** A wrong entry stops the boot, and grading happens after a reboot.
- **After every fstab edit: `sudo findmnt --verify` then `sudo mount -a`.** If either fails, **do not reboot**.
- **Use `UUID=` or `LABEL=`, never `/dev/sdb1`.** The objective says so explicitly.
- **Generate the line, do not type the UUID:** `echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1)  /data  xfs  defaults  0 0" | sudo tee -a /etc/fstab`.
- **`sudo tee -a`, never `sudo echo >>`.** And never forget `-a`, or you truncate `/etc/fstab`.
- **Six fields: device, mount point, type, options, 0, 0.** Fields 5 and 6 are `0 0` for anything you add.
- **`nofail` on every non-critical mount.** A missing device is skipped instead of breaking the boot.
- **`nofail` and `noauto` are not the same.** `nofail` still mounts when the device is present; `noauto` does not mount at all. **"Mount at boot" excludes `noauto`.**
- **The mount point must exist** before mounting: `mkdir -p /data`.
- **`mount -o remount,rw /` is the emergency-mode command.** In emergency mode `/` is read-only and you cannot edit `/etc/fstab` without it.
- **`umount` says busy? `cd /` first**, then `fuser -vm /data`, then `umount -l`.
- **XFS grows with `xfs_growfs MOUNTPOINT` and must be mounted. ext4 grows with `resize2fs DEVICE`.** `lvextend -r` does either for you.
- **XFS cannot shrink.** Ever.
- **`xfs_admin -L` needs the filesystem unmounted; `e2label` does not.**
- **vfat has no ownership or permissions** — use `uid=`, `gid=`, `umask=` mount options. Labels are uppercase, set with `-n`.
- **`fsck` and `xfs_repair` only on unmounted filesystems.** Run with `-n` first.
- **"No space left" with free space in `df -h` means inodes.** Check `df -i`. Also check `lsof +L1` for deleted-but-open files.
- **`df -hT` and `findmnt` are your inspection tools.** `findmnt --fstab` versus `findmnt --mtab` shows configured against actual.
- **`systemctl daemon-reload`** after using `x-systemd.*` options in `/etc/fstab`.
- **`sudo cp /etc/fstab /root/fstab.bak` before editing.** Recovery then takes one command.
- **Best test before rebooting: `umount` everything you added, then `mount -a`.** If that works, the reboot works.
