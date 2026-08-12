# Storage Deep Dive

Storage is roughly a quarter of the exam across two objective domains, it takes the longest, and it is where a mistake can stop the machine from booting. This file is the mental model and the decision trees. The step-by-step tasks are in `28-disks-partitions.md` through `32-nfs-autofs.md`.

---

## The stack

```text
   Physical disk            /dev/sdb          lsblk
        │
        ▼
   Partition               /dev/sdb1          fdisk, parted, partprobe
        │
        ├──────────────────────────┐
        ▼                          ▼
   Physical volume            (direct use)    pvcreate
        │                          │
        ▼                          │
   Volume group               vgcreate        vgs
        │                          │
        ▼                          │
   Logical volume             lvcreate        lvs
        │                          │
        ├──────────────────────────┘
        ▼
   Filesystem or swap        mkfs.xfs, mkswap
        │
        ▼
   Mount point               mount, /etc/fstab
        │
        ▼
   Persistence               findmnt --verify, mount -a
```

**Every storage task is a walk up or down this stack.** When you are stuck, work out which layer you are at and which layer the error is coming from.

**Two layers are optional.** You can put a filesystem straight onto a partition and skip LVM entirely. The exam usually asks for LVM, because that is what makes "extend it later" possible.

---

## Where to start: `lsblk`

```bash
lsblk
lsblk -f
lsblk -o NAME,SIZE,TYPE,FSTYPE,UUID,MOUNTPOINT
```

```text
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda             8:0     0   20G  0 disk
├─sda1          8:1     0    1G  0 part /boot
└─sda2          8:2     0   19G  0 part
  ├─rhel-root 253:0     0   17G  0 lvm  /
  └─rhel-swap 253:1     0    2G  0 lvm  [SWAP]
sdb             8:16    0    5G  0 disk
sdc             8:32    0    5G  0 disk
sr0            11:0     1  9.5G  0 rom
```

Read it as a tree:

| Column value | Meaning |
| --- | --- |
| `disk` | A whole physical device |
| `part` | A partition |
| **`lvm`** | **A logical volume — so LVM is in use** |
| `rom` | Optical device |
| Empty `MOUNTPOINTS` | Not mounted |
| `[SWAP]` | Active swap |

**In the example, `sdb` and `sdc` are untouched spare disks.** That is what a storage task will use. `sda` is the system disk — leave it alone unless the task explicitly says otherwise.

**`lsblk -f` adds the filesystem type and UUID**, which tells you whether a device already has data on it:

```bash
lsblk -f
sudo blkid
```

```text
NAME   FSTYPE      LABEL  UUID                                 MOUNTPOINTS
sdb
sdb1   xfs         data   4f5c6a7b-...                          /data
sdc    LVM2_member        Ky3Jq1-...
```

---

## Partitioning

### MBR versus GPT

| | MBR (`msdos`, `dos`) | **GPT** |
| --- | --- | --- |
| Max disk size | 2 TiB | 8 ZiB |
| Max primary partitions | **4** (or 3 + extended) | **128** |
| Extended and logical partitions | Needed beyond 4 | **Not a concept** |
| Backup of the table | No | **Yes, at the end of the disk** |
| Type codes | Two hex digits (`83`, `82`, `8e`) | GUIDs, shown as short names |
| Tool | `fdisk`, `parted` | `fdisk`, `gdisk`, `parted` |
| **Use this** | Only if asked | **Default choice** |

```bash
sudo fdisk -l /dev/sdb | grep -i 'disklabel type'
sudo parted /dev/sdb print | grep -i 'partition table'
```

**Modern `fdisk` handles GPT perfectly.** You do not need `gdisk` unless you like it.

### fdisk

**`fdisk` is interactive and changes nothing until you press `w`.** That makes it the safe choice under exam pressure: if you get confused, `q` and start again.

```bash
sudo fdisk /dev/sdb
```

| Key | Action |
| --- | --- |
| `m` | Help — the full menu |
| `p` | Print the current table |
| `F` | Show free space |
| `n` | New partition |
| `d` | Delete a partition |
| `t` | Change a partition's type |
| `l` | List type codes |
| `i` | Details of one partition |
| `g` | **New empty GPT table (destroys everything)** |
| `o` | New empty MBR table |
| `v` | Verify |
| **`w`** | **Write and exit** |
| **`q`** | **Quit, discarding everything** |

A typical sequence, creating a 1 GiB LVM partition on a fresh disk:

```text
sudo fdisk /dev/sdb
Command: g                      ← new GPT label
Command: n
Partition number (1-128): ⏎     ← accept the default
First sector: ⏎                 ← accept: aligns automatically
Last sector: +1G                ← THE SIZE, with a leading +
Command: t
Partition type or alias: lvm    ← or 30, or 8e on MBR
Command: p                      ← CHECK before writing
Command: w
```

```bash
sudo partprobe /dev/sdb
lsblk /dev/sdb
```

**Three things to get right:**

1. **`+1G` for the last sector.** Typing `1G` means "end at the 1 GiB mark", which on a GPT disk with a 1 MiB offset gives you slightly less than 1 GiB. `+1G` means "one gibibyte from where we started".

2. **`t` then `lvm` or `swap` if the partition is for those.** The type code is metadata; Linux mostly ignores it, but the exam may check it, and `lsblk`/`fdisk -l` show it.

3. **`p` before `w`.** Ten seconds of checking against a table you cannot undo.

### parted

Non-interactive and scriptable, but **each command takes effect immediately**:

```bash
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary xfs 1MiB 1025MiB
sudo parted /dev/sdb set 1 lvm on
sudo parted /dev/sdb print
sudo parted /dev/sdb print free
sudo parted /dev/sdb rm 1
sudo parted -a optimal /dev/sdb mkpart primary 0% 100%
```

**`parted` takes start and end offsets, not sizes.** A 1 GiB partition starting at 1 MiB ends at 1025 MiB. This is the commonest `parted` mistake.

Interactive mode gives you unit control:

```bash
sudo parted /dev/sdb
(parted) unit MiB
(parted) print free
(parted) mkpart primary 1 1025
(parted) quit
```

### Making the kernel notice

```bash
sudo partprobe /dev/sdb
sudo partprobe                      # all disks
sudo partx -a /dev/sdb
sudo udevadm settle
lsblk /dev/sdb                      # verify the new node exists
ls -l /dev/sdb*
```

**Symptom of a missing `partprobe`:** `mkfs` says the device does not exist, or `lsblk` does not show the partition you just created. `parted` normally triggers this itself; `fdisk` sometimes does not, especially when another partition on the same disk is mounted.

### Wiping

```bash
sudo wipefs /dev/sdb1                 # show signatures
sudo wipefs -a /dev/sdb1              # remove filesystem signatures
sudo sgdisk --zap-all /dev/sdb        # remove both GPT and MBR structures
sudo dd if=/dev/zero of=/dev/sdb bs=1M count=10
```

**`wipefs -a` is the right tool when `mkfs` or `pvcreate` complains that the device already contains a signature.**

### Safe deletion order

```text
1. Is it mounted?             findmnt /data ; lsblk
2. Unmount it                 sudo umount /data
3. Is it in /etc/fstab?        grep data /etc/fstab
4. REMOVE THE FSTAB LINE FIRST
5. Is it swap?                 sudo swapoff /dev/sdb2
6. Is it a PV in a VG?         sudo pvs — if so, do the LVM removal first
7. Delete the partition        sudo fdisk /dev/sdb → d → w
8. sudo partprobe /dev/sdb
9. sudo findmnt --verify
```

**Step 4 is the one that matters.** A deleted partition still referenced in `/etc/fstab` sends the next boot to emergency mode.

---

## LVM

### Why

```text
Without LVM:  a partition is fixed at its boundaries on the disk.
              Growing it means free space must happen to be adjacent.

With LVM:     a logical volume is assembled from extents anywhere in the
              volume group, across any number of disks. Adding a disk adds
              capacity to every logical volume in the group.
```

**"Extend the filesystem" is the most common storage task, and LVM is what makes it answerable.**

### The three layers

```bash
# Physical volume: mark a partition or whole disk as LVM-usable
sudo pvcreate /dev/sdb1
pvs
sudo pvdisplay /dev/sdb1

# Volume group: a pool of extents from one or more PVs
sudo vgcreate vg01 /dev/sdb1
vgs
sudo vgdisplay vg01

# Logical volume: carved out of the pool
sudo lvcreate -n lv_data -L 500M vg01
lvs
sudo lvdisplay /dev/vg01/lv_data
```

```text
pvs → PV /dev/sdb1  VG vg01  Fmt lvm2  Attr a--  PSize 5.00g  PFree 4.50g
vgs → VG vg01  #PV 1  #LV 1  #SN 0  Attr wz--n-  VSize 5.00g  VFree 4.50g
lvs → LV lv_data  VG vg01  Attr -wi-ao----  LSize 500.00m
```

| Reading `lvs` attributes | |
| --- | --- |
| Position 1 `-` | Normal volume (`s` snapshot, `o` origin) |
| Position 2 `w` | Writable |
| Position 5 `a` | **Active** |
| Position 6 `o` | **Open (mounted)** |

### Extents

A volume group has a fixed **physical extent** size, 4 MiB by default. Every logical volume is a whole number of extents.

```bash
sudo vgdisplay vg01 | grep -E 'PE Size|Total PE|Free  PE'
sudo vgcreate -s 8M vg02 /dev/sdc1       # 8 MiB extents
```

**Consequence: sizes round up to the next extent.** `lvcreate -L 500M` with 4 MiB extents gives you 125 extents, exactly 500 MiB. `-L 510M` gives you 128 extents, 512 MiB. **If a task says "exactly 20 extents", use `-l 20`, not `-L`.**

| Flag | Takes |
| --- | --- |
| `-L 500M`, `-L 2G` | **An absolute size** |
| `-L +400M` | **A size increase** |
| `-l 25` | 25 extents |
| `-l +5` | 5 more extents |
| `-l 100%FREE` | **All remaining free space in the VG** |
| `-l 50%VG` | Half the total VG size |
| `-l +100%FREE` | Grow by all remaining free space |

### Extending: the decision tree

```text
Task: "extend /data to 2 GiB"

   1. Where is /data?
      findmnt /data ; lsblk ; df -hT /data
      │
      ├─ On a logical volume?  → LVM path below
      └─ On a plain partition? → you cannot extend in place.
                                 Add a new partition, or convert to LVM,
                                 or (if the task allows) recreate it.

   2. Is there free space in the volume group?
      sudo vgs
      │
      ├─ VFree is enough      → skip to step 4
      └─ VFree is too small   → step 3

   3. Add capacity to the volume group
      sudo fdisk /dev/sdc     (n, t → lvm, w)
      sudo partprobe /dev/sdc
      sudo pvcreate /dev/sdc1
      sudo vgextend vg01 /dev/sdc1
      sudo vgs                (VFree has grown)

   4. Extend the LV *and* the filesystem
      sudo lvextend -r -L 2G /dev/vg01/lv_data

   5. VERIFY WITH df, NOT lvs
      df -h /data
```

**Step 5 is the check that matters.** `lvs` shows the volume grew; `df` shows whether the *filesystem* grew, which is what the task asked for.

```bash
sudo lvextend -r -L 2G /dev/vg01/lv_data      # to an absolute size
sudo lvextend -r -L +400M /dev/vg01/lv_data   # by an amount
sudo lvextend -r -l +100%FREE /dev/vg01/lv_data
```

**`-r` (`--resizefs`) calls the right filesystem tool for you.** If you forget it:

| Filesystem | Command | Argument | Must be |
| --- | --- | --- | --- |
| **xfs** | `xfs_growfs` | **The mount point** | **Mounted** |
| **ext4** | `resize2fs` | **The device** | Either |

```bash
sudo xfs_growfs /data
sudo resize2fs /dev/vg01/lv_data
```

**Mixing these up produces baffling errors.** `xfs_growfs /dev/vg01/lv_data` fails; `resize2fs /data` fails.

### Shrinking

```text
xfs   → CANNOT SHRINK. Not with any tool, not ever.
        The only route is: back up, mkfs smaller, restore.

ext4  → can shrink, offline, filesystem first:
```

```bash
sudo umount /data
sudo e2fsck -f /dev/vg01/lv_data          # required before resize2fs shrinks
sudo resize2fs /dev/vg01/lv_data 500M     # FILESYSTEM first
sudo lvreduce -L 500M /dev/vg01/lv_data   # then the volume
sudo mount /data
df -h /data
```

**Order matters absolutely. Shrinking the LV before the filesystem destroys data.** `lvreduce` warns; take the warning seriously. `lvresize -r` handles the order for you, but doing it by hand is clearer.

### Removing

```text
1. sudo umount /data
2. Remove the /etc/fstab line              ← BEFORE anything else
3. sudo lvremove /dev/vg01/lv_data
4. sudo vgremove vg01
5. sudo pvremove /dev/sdb1
6. (optional) delete the partition
7. sudo findmnt --verify
```

Removing a disk from a live volume group:

```bash
sudo pvs -o+pv_used                       # is anything on this PV?
sudo pvmove /dev/sdc1                     # migrate extents elsewhere
sudo vgreduce vg01 /dev/sdc1
sudo pvremove /dev/sdc1
```

**`vgreduce` on a PV that still holds extents fails.** `pvmove` first — and it needs enough free space elsewhere in the group.

### Snapshots

```bash
sudo lvcreate -s -n lv_data_snap -L 200M /dev/vg01/lv_data
sudo mount /dev/vg01/lv_data_snap /mnt/snap -o ro,nouuid    # nouuid for xfs
lvs                                        # snapshots show 'Data%'
sudo lvconvert --merge /dev/vg01/lv_data_snap   # roll back
sudo lvremove /dev/vg01/lv_data_snap
```

**A snapshot that fills up becomes invalid and is dropped.** Watch `Data%` in `lvs`. Snapshots are not an EX200 objective, but they appear in `lvs` output and are worth recognising.

### Persistence

**LVM metadata lives on the disks themselves** — in the PV headers — so the whole stack reassembles at boot with no configuration file needed. `lvm2-monitor.service` handles activation and is enabled by default.

**The only part of an LVM setup that needs your attention for persistence is the `/etc/fstab` entry.**

---

## Filesystems

### Choosing

| | **xfs** | **ext4** | **vfat** |
| --- | --- | --- | --- |
| RHEL default | **Yes** | No | No |
| Grow | **Yes, online** | Yes | No |
| **Shrink** | **NO** | **Yes, offline** | No |
| POSIX permissions | Yes | Yes | **No** |
| Ownership | Yes | Yes | **No — set with mount options** |
| Label length | 12 | 16 | 11 |
| Grow tool | `xfs_growfs` | `resize2fs` | — |
| Repair | `xfs_repair` | `e2fsck` | `fsck.vfat` |
| Tune | `xfs_admin` | `tune2fs` | `fatlabel` |
| Use for | **Almost everything** | When shrinking may be needed | **EFI, USB, Windows interop** |

```bash
sudo mkfs.xfs /dev/sdb1
sudo mkfs.xfs -f /dev/sdb1                 # -f overwrites an existing filesystem
sudo mkfs.xfs -L mydata /dev/sdb1
sudo mkfs.ext4 -L mydata /dev/sdb1
sudo mkfs.vfat -F 32 -n MYDATA /dev/sdb1
```

**`mkfs.xfs` refuses to overwrite an existing filesystem without `-f`.** That is a safety feature, not an obstacle — read the message and be sure before adding `-f`.

Labels afterwards:

```bash
sudo xfs_admin -L mydata /dev/sdb1 ; sudo xfs_admin -l /dev/sdb1
sudo e2label /dev/sdb1 mydata ; sudo e2label /dev/sdb1
sudo tune2fs -L mydata /dev/sdb1
sudo fatlabel /dev/sdb1 MYDATA
```

**Changing an xfs label requires the filesystem to be unmounted.**

### `/etc/fstab`

```text
# <device>          <mount point>  <type>   <options>           <dump> <fsck>
UUID=4f5c6a7b-...   /data          xfs      defaults            0      0
LABEL=mydata        /data2         ext4     defaults,acl        0      2
/dev/vg01/lv_data   /data3         xfs      defaults            0      0
UUID=9a8b7c6d-...   none           swap     defaults            0      0
/swapfile           none           swap     defaults            0      0
server2:/export     /nfs           nfs      defaults,_netdev    0      0
/root/rhel10.iso    /mnt/iso       iso9660  loop,ro,nofail      0      0
```

**Field by field:**

| Field | Rules |
| --- | --- |
| Device | **`UUID=` is the safest.** `LABEL=` is fine. `/dev/sdb1` can change between boots when disks are added; `/dev/vg01/lv_x` is stable because LVM names are stable |
| Mount point | Must **exist** as a directory. **`none` for swap** |
| Type | `xfs`, `ext4`, `vfat`, `swap`, `nfs`, `iso9660`. `auto` works but is vague |
| Options | `defaults` unless the task says otherwise |
| Dump | **Always `0`** |
| fsck | **`0` for xfs, swap, and network filesystems. `1` for `/` only. `2` for other ext4** |

Get the UUID by substitution — never retype it:

```bash
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1)  /data  xfs  defaults  0 0" \
  | sudo tee -a /etc/fstab
```

### Mount options worth knowing

| Option | Effect |
| --- | --- |
| `defaults` | `rw,suid,dev,exec,auto,nouser,async` |
| **`nofail`** | **The boot continues if the device is absent — your safety net** |
| **`_netdev`** | **Wait for the network. Mandatory for NFS** |
| `noauto` | Not mounted by `mount -a` or at boot |
| `ro` | Read-only |
| `noexec` | No binaries may be executed |
| `nosuid` | SUID and SGID bits ignored |
| `nodev` | Device nodes ignored |
| `acl` | Enable ACLs (default on xfs; needed on some ext4) |
| `user_xattr` | Extended attributes on ext4 |
| `uid=1000,gid=1000,umask=022` | **Ownership for vfat, which has none of its own** |
| `x-systemd.automount` | Mount on first access, like autofs |
| `x-systemd.device-timeout=10` | Give up waiting sooner |
| `usrquota,grpquota` | Quotas |
| `nouuid` | Mount an xfs snapshot whose UUID duplicates the original |

**Hardening combination that appears in tasks:** `defaults,nosuid,noexec,nodev`.

### Verification, in order

```bash
sudo findmnt --verify                # 1. parse and sanity-check every line
sudo findmnt --verify --verbose      # what exactly it checked
sudo umount /data                    # 2. unmount what you mounted by hand
sudo mount -a                        # 3. mount everything from fstab
findmnt /data                        # 4. confirm it is actually mounted
df -hT /data                         # 5. confirm the size and type
sudo swapoff -a && sudo swapon -a    # 6. the same for swap
swapon --show
```

**Never reboot without steps 1 and 3.** They cost fifteen seconds and prevent the one mistake that can end the exam.

```text
findmnt --verify catches:
  ✓ a mount point that does not exist
  ✓ a UUID or LABEL with no matching device
  ✓ an unknown filesystem type
  ✓ a malformed line, wrong field count
  ✗ a WRONG-but-valid UUID pointing at the wrong device
  ✗ a filesystem type that is valid but wrong for the device
```

**So run `mount -a` as well.** It actually performs the mounts and reports what fails.

### Recovering from a bad fstab

```text
System boots to:  "You are in emergency mode"  and asks for the root password.

1. Enter the root password
2. mount -o remount,rw /
3. vi /etc/fstab            (fix, or comment out with #)
4. systemctl daemon-reload
5. mount -a                 (must succeed with no output)
6. reboot
```

**Practise this deliberately.** Break your own fstab in the lab, reboot, and recover. Doing it once removes all the panic from doing it under exam conditions.

If `/` itself will not mount, boot the installation media in rescue mode:

```text
Troubleshooting → Rescue a Red Hat Enterprise Linux system → Continue
chroot /mnt/sysroot
vi /etc/fstab
exit ; reboot
```

### Repair and inspection

```bash
sudo xfs_info /data                        # geometry of a mounted xfs
sudo xfs_repair -n /dev/sdb1               # dry run; must be UNMOUNTED
sudo xfs_repair /dev/sdb1
sudo xfs_repair -L /dev/sdb1               # zero the log — DATA LOSS, last resort
sudo e2fsck -f /dev/sdb1                   # force a check
sudo e2fsck -p /dev/sdb1                   # auto-repair safe problems
sudo tune2fs -l /dev/sdb1                  # every ext4 parameter
sudo dumpe2fs -h /dev/sdb1
```

**All repair tools require the filesystem to be unmounted.** For `/`, that means booting from other media or into rescue mode.

### Space and inodes

```bash
df -h                                      # space
df -hT                                     # with the filesystem type
df -i                                      # INODES
du -sh /var/*
du -h --max-depth=1 /var | sort -h
sudo du -sh /var/log/journal
```

**"Disk full" with free space in `df -h` means inode exhaustion:**

```bash
df -i
```

```text
Filesystem      Inodes  IUsed IFree IUse% Mounted on
/dev/sdb1        65536  65536     0  100% /data
```

**Many small files consumed every inode.** xfs allocates inodes dynamically so this is rare; ext4 fixes the count at `mkfs` time. The fix is to delete files or recreate the filesystem with `mkfs.ext4 -N` or a smaller `-i` bytes-per-inode ratio.

**Other causes of "full but not full":**

```bash
sudo lsof +L1                              # deleted files still held open
sudo systemctl restart rsyslog             # a common holder
```

**A deleted file whose file descriptor is still open keeps consuming space** until the holding process is restarted.

### SELinux and mounting

A newly created filesystem mounted at a new mount point gets a **default** context, usually not the one an application needs:

```bash
ls -Zd /data
```

```text
system_u:object_r:default_t:s0 /data
```

If a service will use it:

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/data(/.*)?"
sudo restorecon -Rv /data
```

Or an equivalency rule, which is cleaner when a whole tree mirrors a standard location:

```bash
sudo semanage fcontext -a -e /var/www /web
sudo restorecon -Rv /web
```

**The mount point's context applies to whatever is mounted over it in xfs and ext4** — the labels are stored in the filesystem itself. So label after mounting, not before.

---

## Swap

### The recipe

```text
1. mkswap DEVICE           format it as swap
2. swapon DEVICE           activate it now
3. /etc/fstab entry        activate it at every boot
```

Miss step 3 and the task scores zero.

### Three forms

**Partition:**

```bash
sudo fdisk /dev/sdb            # n, t → swap (19/82), w
sudo partprobe /dev/sdb
sudo mkswap /dev/sdb2
sudo swapon /dev/sdb2
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb2)  none  swap  defaults  0 0" \
  | sudo tee -a /etc/fstab
```

**Logical volume:**

```bash
sudo lvcreate -n lv_swap -L 512M vg01
sudo mkswap /dev/vg01/lv_swap
sudo swapon /dev/vg01/lv_swap
echo "/dev/vg01/lv_swap  none  swap  defaults  0 0" | sudo tee -a /etc/fstab
```

**Use the device path for LVM swap, not the UUID.** LVM paths are stable, and `mkswap` generates a **new UUID every time it runs** — so a UUID in fstab goes stale the moment you re-run `mkswap`.

**File:**

```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=512 status=progress
sudo chmod 600 /swapfile                  # BEFORE mkswap
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile  none  swap  defaults  0 0" | sudo tee -a /etc/fstab
```

**Two rules for swap files:**

1. **`chmod 600` first.** `swapon` warns about insecure permissions and on some configurations refuses.
2. **Use `dd`, not `fallocate`, for xfs.** A sparse or preallocated file can fail with `swapon: swapfile has holes`. `dd` writes real blocks.

### The `/etc/fstab` swap line

```text
UUID=xxxx-xxxx     none  swap  defaults  0 0
/dev/vg01/lv_swap  none  swap  defaults  0 0
/swapfile          none  swap  defaults  0 0
```

| Field | Value |
| --- | --- |
| Mount point | **`none`** (or `swap`; `none` is conventional) |
| Type | **`swap`** |
| Options | `defaults`, or `defaults,pri=10` |
| Dump, fsck | **`0 0`** |

### Verification

```bash
swapon --show
free -h
cat /proc/swaps
sudo swapoff -a && sudo swapon -a         # THE test — proves fstab works
swapon --show
```

**`swapoff -a && swapon -a` is the swap equivalent of `mount -a`.** If a device disappears from `swapon --show` after this, its fstab entry is wrong.

### Priority

```bash
sudo swapon -p 10 /dev/sdb2
```

```text
/dev/sdb2  none  swap  defaults,pri=10  0 0
```

**Higher priority is used first. Equal priorities are striped**, which is faster across separate physical disks. Default priority is negative and decreases with each device added.

### swappiness

```bash
cat /proc/sys/vm/swappiness              # default 30 on RHEL 9/10, 60 historically
sudo sysctl vm.swappiness=10             # runtime only
echo 'vm.swappiness = 10' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl -p /etc/sysctl.d/99-swappiness.conf
sysctl vm.swappiness
```

**`sysctl -w` is runtime; a file in `/etc/sysctl.d/` is persistent.** Higher values swap more eagerly; 0 means only under real memory pressure.

### Removing swap

```bash
sudo swapoff /dev/sdb2                    # 1. deactivate
sudo sed -i '\|/dev/sdb2|d' /etc/fstab    # 2. remove the fstab line
sudo lvremove /dev/vg01/lv_swap           # 3. remove the container
sudo rm -f /swapfile                      # (for a swap file)
swapon --show
```

**`swapoff` can take a long time or fail with `Cannot allocate memory`** if the swap in use will not fit in RAM. Free memory first.

---

## NFS

### Client

```bash
sudo dnf install -y nfs-utils
showmount -e server2                      # what does the server export
sudo mkdir -p /nfs
sudo mount -t nfs server2:/export/shared /nfs      # test by hand FIRST
ls /nfs
findmnt /nfs
```

Then persist:

```text
server2:/export/shared  /nfs  nfs  defaults,_netdev  0 0
```

```bash
sudo umount /nfs
sudo findmnt --verify
sudo mount -a
findmnt /nfs
```

| Client option | Why |
| --- | --- |
| **`_netdev`** | **Wait for the network. Without it, boot can hang or the mount fails** |
| `nofail` | Do not fail the boot if the server is down |
| `soft` | I/O errors out instead of hanging forever |
| `hard` | Retries indefinitely (the default; correct for data integrity) |
| `timeo=100` | Tenths of a second before a retransmission |
| `retrans=3` | Retries before reporting |
| `vers=4.2` | Pin the protocol version |
| `ro` | Read-only |
| `sec=sys` | Authentication flavour |

**`soft,timeo=100` makes a lab far less painful when a server is unreachable**, and is a sensible default for exam tasks unless told otherwise.

### Server

Four layers, and all four are needed:

```bash
# 1. The directory, with content and the right labels
sudo mkdir -p /export/shared
sudo chmod 777 /export/shared             # or a group-based scheme
echo test | sudo tee /export/shared/testfile

# 2. /etc/exports
echo "/export/shared  192.168.56.0/24(rw,sync)" | sudo tee -a /etc/exports
sudo exportfs -rav
sudo exportfs -v

# 3. The service
sudo dnf install -y nfs-utils
sudo systemctl enable --now nfs-server

# 4. The firewall
sudo firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
sudo firewall-cmd --reload
```

```text
# /etc/exports syntax
/path   client(option,option)  client2(option)

/export/shared   192.168.56.0/24(rw,sync)
/export/ro       *(ro,sync)
/export/admin    server1.lab.example.com(rw,sync,no_root_squash)
/export/multi    192.168.56.10(rw,sync) 192.168.56.11(ro,sync)
```

**No space between the client and its parenthesised options.** `192.168.56.0/24 (rw)` means "read-write for everyone, and default options for that subnet" — a security hole and a common typo.

| Export option | Meaning |
| --- | --- |
| `rw` / `ro` | Read-write / read-only |
| `sync` | Commit writes before replying. **Use this** |
| `async` | Faster, risks data on a crash |
| **`root_squash`** | **Default. Remote root is mapped to `nobody`** |
| `no_root_squash` | Remote root stays root. Only if explicitly asked |
| `all_squash` | Every remote user becomes `nobody` |
| `anonuid=`, `anongid=` | Which account squashed users become |
| `no_subtree_check` | Fewer permission checks, better performance |
| `sec=sys` / `sec=krb5` / `krb5i` / `krb5p` | Security flavour |

```bash
sudo exportfs -rav                        # re-export everything, verbosely
sudo exportfs -v                          # show current exports with options
sudo exportfs -s                          # show what would be in /etc/exports
sudo exportfs -u /export/shared           # unexport one
```

**`exportfs -rav` applies `/etc/exports` without restarting the service.** Restarting `nfs-server` also works and disconnects clients.

**SELinux for NFS:**

```bash
getsebool -a | grep nfs
sudo setsebool -P nfs_export_all_rw on    # if exporting read-write outside defaults
sudo semanage fcontext -a -t public_content_rw_t "/export(/.*)?"
sudo restorecon -Rv /export
```

### Troubleshooting NFS

```text
Symptom                                          Check
────────────────────────────────────────────────────────────────────────────
"No route to host" / "Connection timed out"      Firewall on the SERVER:
                                                 sudo firewall-cmd --list-all
                                                 (needs nfs, mountd, rpc-bind)

"access denied by server"                        /etc/exports client spec;
                                                 sudo exportfs -v
                                                 (is the client's IP in range?)

showmount works, mount fails                     Firewall allows rpc-bind but
                                                 not nfs/mountd

"mount: bad option"                              nfs-utils not installed on the
                                                 CLIENT

Mount works, writes fail with permission denied  root_squash, or directory
                                                 permissions, or SELinux;
                                                 ausearch -m AVC -ts recent

Boot hangs                                       Missing _netdev in fstab

Stale file handle                                The export was recreated;
                                                 umount -l and remount
```

```bash
# From the client
showmount -e server2
ping server2
nc -zv server2 2049
rpcinfo -p server2
sudo mount -v -t nfs server2:/export/shared /nfs
# On the server
sudo exportfs -v
sudo systemctl status nfs-server
sudo firewall-cmd --list-all
sudo journalctl -u nfs-server -n 30
sudo ausearch -m AVC -ts recent
```

---

## autofs

### Why

```text
fstab:   mounted at boot, stays mounted, fails the boot if the server is down.
autofs:  mounted on first access, unmounted after idling, absent server is harmless.
```

**Use autofs for user home directories and rarely-used shares. Use fstab for anything a service depends on.**

### Structure

```text
/etc/auto.master              (or a drop-in in /etc/auto.master.d/*.autofs)
        │
        ▼
   mount-point-base    map-file    options
   /shares             /etc/auto.shares   --timeout=60
        │
        ▼
   /etc/auto.shares
   key    options         location
   data   -rw,sync        server2:/export/shared
```

### Indirect map — the usual answer

```bash
sudo dnf install -y autofs
sudo mkdir -p /etc/auto.master.d

echo "/shares  /etc/auto.shares  --timeout=60" \
  | sudo tee /etc/auto.master.d/shares.autofs

sudo tee /etc/auto.shares >/dev/null <<'EOF'
data   -rw,sync   server2:/export/shared
docs   -ro        server2:/export/docs
EOF

sudo systemctl enable --now autofs
sudo systemctl restart autofs

ls /shares/data                       # THIS triggers the mount
findmnt /shares/data
```

**Do not create `/shares` or `/shares/data`.** autofs creates and manages them. A pre-existing `/shares/data` directory can prevent the automount.

**`ls /shares` may look empty before first access.** That is normal for an indirect map — the subdirectory appears when you reference it by name. Use `ls /shares/data` to trigger it.

### Direct map

```bash
echo "/-  /etc/auto.direct" | sudo tee /etc/auto.master.d/direct.autofs
echo "/mnt/reports  -ro  server2:/export/reports" | sudo tee /etc/auto.direct
sudo systemctl restart autofs
ls /mnt/reports
```

**The master-map field is `/-` and the map keys are absolute paths.** Use a direct map when the mount point must be at a specific existing path rather than under a shared parent.

### Wildcard map

```bash
sudo tee /etc/auto.master.d/home.autofs >/dev/null <<'EOF'
/nethome  /etc/auto.home
EOF

sudo tee /etc/auto.home >/dev/null <<'EOF'
*  -rw,sync  server2:/export/home/&
EOF

sudo systemctl restart autofs
ls /nethome/alice                     # mounts server2:/export/home/alice
```

**`*` is the key wildcard and `&` expands to whatever key was requested.** This is how network home directories are done, and it is a common exam task.

### Options

| Master map option | Effect |
| --- | --- |
| `--timeout=60` | Unmount after 60 idle seconds |
| `--timeout=0` | Never unmount |
| `--ghost` / `--browse` | Show the mount points before they are mounted |

Map file options are ordinary mount options prefixed with `-`: `-rw`, `-ro,soft`, `-rw,sync,vers=4.2`, `-fstype=nfs4`.

### Troubleshooting autofs

```bash
sudo systemctl status autofs
sudo systemctl restart autofs                 # after EVERY map change
sudo automount -f -v                          # foreground, verbose — the best tool
sudo journalctl -u autofs -n 40
findmnt | grep autofs
cat /etc/auto.master /etc/auto.master.d/*
```

```text
Symptom                                    Cause
──────────────────────────────────────────────────────────────────────────
Nothing mounts                             autofs not enabled, or no restart
                                           after editing a map

"No such file or directory" on the path    Wrong key name, or the map file
                                           path in auto.master is wrong

Directory exists but is empty               A REAL directory is shadowing
                                           the automount — remove it

Mounts, then vanishes                      The timeout expired. Normal

Works for fstab, not autofs                 Both are configured for the same
                                           path — remove the fstab line

/shares appears empty                      Normal for an indirect map. Access
                                           /shares/KEY directly
```

**`sudo automount -f -v` after `systemctl stop autofs` shows exactly what autofs does when you touch the path.** It is the fastest way to find a map typo.

---

## Complete worked example

**Task: add a 2 GiB xfs filesystem mounted at `/data`, on a new logical volume, persistently. Then extend it to 3 GiB.**

```bash
# 1. Survey
lsblk
sudo vgs

# 2. Partition the spare disk
sudo fdisk /dev/sdb
#   g, n, ⏎, ⏎, +2G, t, lvm, p, w
sudo partprobe /dev/sdb
lsblk /dev/sdb

# 3. LVM
sudo pvcreate /dev/sdb1
sudo vgcreate vg_data /dev/sdb1
sudo lvcreate -n lv_data -L 2G vg_data
lvs

# 4. Filesystem
sudo mkfs.xfs -L data /dev/vg_data/lv_data

# 5. Mount point and fstab
sudo mkdir -p /data
echo "UUID=$(sudo blkid -s UUID -o value /dev/vg_data/lv_data)  /data  xfs  defaults  0 0" \
  | sudo tee -a /etc/fstab

# 6. Verify BEFORE trusting it
sudo findmnt --verify
sudo mount -a
findmnt /data
df -hT /data

# 7. Reboot and confirm
sudo reboot
df -hT /data

# 8. Extend to 3 GiB
sudo vgs                                        # enough free space?
sudo lvextend -r -L 3G /dev/vg_data/lv_data
df -h /data                                     # ← the check that counts
```

**The verification pattern generalises to every storage task:**

1. **`lsblk`** — what exists.
2. Do the work, layer by layer, up the stack.
3. **`findmnt --verify` and `mount -a`** — will it boot.
4. **`df -hT`** — is the result what was asked for.
5. **Reboot, then check again without touching anything.**
