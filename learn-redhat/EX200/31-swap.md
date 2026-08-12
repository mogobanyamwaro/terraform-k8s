# 31. Swap

**Objective:** Create and configure swap space. Add new partitions and logical volumes, and swap to a system non-destructively.

A short topic with a small number of commands, and it appears on the exam regularly because it is quick to set and quick to grade. **The persistence trap is the same as everywhere else: `swapon` is temporary, an `/etc/fstab` entry is not.**

## Concept Refresher

### What swap is

Swap is disk space the kernel uses when physical memory is under pressure — inactive pages are written out to free RAM. It is also where a hibernation image is stored.

Three forms, all equally valid:

| Form | Created on | Typical use |
| --- | --- | --- |
| **Swap partition** | A partition with type 82/`swap` | The classic approach |
| **Swap logical volume** | An LVM LV | **Easy to resize** |
| **Swap file** | A file in a filesystem | Adding swap with no free partition |

```bash
swapon --show
swapon -s
free -h
cat /proc/swaps
```

```text
$ swapon --show
NAME      TYPE      SIZE USED PRIO
/dev/dm-1 partition   2G   0B   -2

$ free -h
               total        used        free      shared  buff/cache   available
Mem:           1.7Gi       456Mi       812Mi       9.0Mi       604Mi       1.3Gi
Swap:          2.0Gi          0B       2.0Gi
```

**`swapon --show` and `free -h` are the two verification commands.** `swapon --show` prints nothing at all when no swap is active, which is itself the answer.

### The three-step recipe

Whatever the underlying device, the sequence is identical:

```bash
# 1. Format it as swap
sudo mkswap /dev/sdb2

# 2. Activate it
sudo swapon /dev/sdb2

# 3. PERSIST it
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb2)  none  swap  defaults  0 0" | sudo tee -a /etc/fstab
sudo swapon --show
```

**`mkswap`, `swapon`, `/etc/fstab`. Three steps, and the third is where the marks are.**

### The fstab line

```text
UUID=7d5e3a8b-...  none  swap  defaults  0 0
        1            2      3      4     5 6
```

| # | Field | Value for swap |
| --- | --- | --- |
| 1 | Device | **`UUID=...`**, `LABEL=...`, `/dev/vg/lv`, or a file path |
| 2 | Mount point | **`none`** or `swap` — swap has no mount point |
| 3 | Type | **`swap`** |
| 4 | Options | **`defaults`**, or `pri=10`, or `noauto` |
| 5 | Dump | `0` |
| 6 | fsck | `0` |

**Field 2 is `none`.** Some documentation uses `swap`; both work and neither is a mount point. `0 0` for the last two fields.

```bash
grep -i swap /etc/fstab
```

### Swap partition

```bash
# Partition with type 82 / swap  (28-disks-partitions.md)
sudo fdisk /dev/sdb
#   n, Enter, Enter, +512M, t, <partition>, swap, w
sudo partprobe /dev/sdb
lsblk /dev/sdb

sudo mkswap /dev/sdb2
sudo swapon /dev/sdb2
swapon --show
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb2)  none  swap  defaults  0 0" | sudo tee -a /etc/fstab
```

**The type code `82` (MBR) or `swap`/`19` (GPT) is not required by `mkswap`**, but tasks ask for it and it documents intent.

### Swap logical volume

```bash
sudo lvcreate -n lv_swap -L 512M vg01
sudo mkswap /dev/vg01/lv_swap
sudo swapon /dev/vg01/lv_swap
swapon --show
echo "/dev/vg01/lv_swap  none  swap  defaults  0 0" | sudo tee -a /etc/fstab
```

**Resizing a swap LV requires deactivating it first** — there is no `swap_growfs`:

```bash
sudo swapoff /dev/vg01/lv_swap
sudo lvextend -L +512M /dev/vg01/lv_swap
sudo mkswap /dev/vg01/lv_swap             # RE-FORMAT — this generates a NEW UUID
sudo swapon /dev/vg01/lv_swap
swapon --show
```

**`mkswap` generates a new UUID every time.** If `/etc/fstab` refers to the old one, the next boot fails to activate swap:

```bash
sudo blkid /dev/vg01/lv_swap
grep swap /etc/fstab                      # do they match?
```

**Using the device path `/dev/vg01/lv_swap` in `/etc/fstab` avoids this entirely** for LVM swap, which is a good reason to prefer it here.

### Swap file

Useful when there is no free partition or disk.

```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=512 status=progress
# or
sudo fallocate -l 512M /swapfile           # instant, but see the note below

sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
swapon --show
echo "/swapfile  none  swap  defaults  0 0" | sudo tee -a /etc/fstab
```

**Two requirements that catch people:**

1. **`chmod 600` is mandatory.** `swapon` refuses a world-readable swap file, because its contents are memory:

```text
swapon: /swapfile: insecure permissions 0644, 0600 suggested.
```

2. **`fallocate` produces a sparse or preallocated file that XFS may reject.** `dd` always works:

```text
swapon: /swapfile: swapon failed: Invalid argument
```

**On XFS use `dd`, not `fallocate`.** It is slower but reliable, and on the exam reliability wins.

**A swap file is referenced by path in `/etc/fstab`, not by UUID.**

### Priority

```bash
sudo swapon --show
sudo swapon -p 10 /dev/sdb2
```

```text
NAME       TYPE      SIZE USED PRIO
/dev/dm-1  partition   2G   0B   -2
/dev/sdb2  partition 512M   0B   10
```

| Priority | Behaviour |
| --- | --- |
| Higher number | **Used first** |
| Equal numbers | **Used in parallel, round-robin** |
| Not specified | Negative, assigned automatically, decreasing |

```text
UUID=xxx  none  swap  pri=10  0 0
UUID=yyy  none  swap  pri=10  0 0        # these two are striped
UUID=zzz  none  swap  pri=1   0 0        # used only when the others are full
```

**Set equal priorities on devices of similar speed to get parallel use**, and a higher priority on faster storage. A task may ask for a specific priority; the option is `pri=N` in `/etc/fstab` and `-p N` on the command line.

### Deactivating and removing

```bash
sudo swapoff /dev/sdb2                     # one device
sudo swapoff -a                            # everything
sudo swapon -a                             # activate everything in fstab
```

Removing swap completely, in order:

```bash
# 1. Remove the fstab entry FIRST
sudo vim /etc/fstab
sudo findmnt --verify

# 2. Deactivate
sudo swapoff /dev/sdb2
swapon --show

# 3. Then remove the device
sudo lvremove /dev/vg01/lv_swap
# or delete the partition (28-disks-partitions.md)
# or: sudo rm -f /swapfile
```

**`swapoff` needs enough free RAM to hold the pages currently swapped out.** On a busy machine it can take a while or fail with "Cannot allocate memory":

```bash
free -h                                    # is there room for the swapped pages?
sudo swapoff /dev/sdb2
```

### Swappiness

```bash
cat /proc/sys/vm/swappiness
sudo sysctl vm.swappiness                  # read
sudo sysctl -w vm.swappiness=10            # RUNTIME ONLY
```

Persistent:

```bash
echo 'vm.swappiness = 10' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl -p /etc/sysctl.d/99-swappiness.conf
sudo sysctl vm.swappiness
```

**`sysctl -w` does not persist; a file in `/etc/sysctl.d/` does.** Same pattern as everything else on this exam. Values run 0 to 200, with 60 the RHEL default; lower means swap less eagerly.

Not a listed objective, but it is a plausible "configure swap" sub-task and the persistence mechanism is worth knowing.

### How much swap

Red Hat's recommendation for RHEL:

| RAM | Swap (no hibernation) | With hibernation |
| --- | --- | --- |
| ≤ 2 GB | **2× RAM** | 3× RAM |
| 2–8 GB | **Equal to RAM** | 2× RAM |
| 8–64 GB | **At least 4 GB** | 1.5× RAM |
| > 64 GB | **At least 4 GB** | Not recommended |

**Follow the task's stated size.** This table matters only if a task says "according to Red Hat's recommendation", which is unusual. If it says "add 512 MiB of swap", add 512 MiB.

### Verification

```bash
swapon --show
free -h
cat /proc/swaps
grep -i swap /etc/fstab
sudo blkid | grep -i swap
lsblk -f | grep -i swap
sudo findmnt --verify
sudo swapoff -a && sudo swapon -a && swapon --show    # the real test
```

**`swapoff -a` followed by `swapon -a` is the equivalent of `mount -a` for swap.** It proves the `/etc/fstab` entries work rather than that your manual `swapon` is still in effect.

## Tasks

**Task 1.** Report all currently active swap devices with their sizes, types, and priorities, and the total swap the kernel sees.

**Task 2.** Create a 512 MiB partition of type Linux swap, format it, activate it, and make it persistent.

**Task 3.** Verify the new swap survives a reboot.

**Task 4.** Create a 512 MiB swap logical volume, activate it, and make it persistent.

**Task 5.** Increase that swap logical volume to 1 GiB, non-destructively with respect to the rest of the system.

**Task 6.** Create a 512 MiB swap file at `/swapfile`, activate it, and make it persistent.

**Task 7.** Explain why `swapon` may refuse a swap file, and give two distinct causes.

**Task 8.** Configure two swap devices so that one is used before the other.

**Task 9.** Configure two swap devices of equal speed so the kernel uses them in parallel.

**Task 10.** Deactivate one swap device without rebooting, then reactivate it from `/etc/fstab`.

**Task 11.** Completely remove a swap logical volume, in the correct order.

**Task 12.** Set the kernel's swappiness to 10 persistently.

**Task 13.** Diagnose: after a reboot, `swapon --show` shows less swap than expected.

**Task 14.** Diagnose: `swapoff` fails with "Cannot allocate memory".

**Task 15.** Verify every swap change survives a reboot.

---

## Solutions

**Task 1.**

```bash
swapon --show
```

```text
NAME      TYPE      SIZE USED PRIO
/dev/dm-1 partition   2G   0B   -2
```

```bash
free -h
```

```text
               total        used        free      shared  buff/cache   available
Mem:           1.7Gi       456Mi       812Mi       9.0Mi       604Mi       1.3Gi
Swap:          2.0Gi          0B       2.0Gi
```

```bash
cat /proc/swaps
lsblk -f | grep -i swap
sudo blkid | grep -i swap
grep -i swap /etc/fstab
```

```text
$ cat /proc/swaps
Filename       Type       Size    Used  Priority
/dev/dm-1      partition  2097148 0     -2
```

Reading the output:

- **`TYPE partition`** — this is a partition or LV, not a file. A swap file shows `file`.
- **`/dev/dm-1`** is a device-mapper name, so this is an LVM logical volume. `lsblk` resolves it:

```bash
lsblk | grep -i swap
```

```text
  └─rhel-swap 253:1    0    2G  0 lvm  [SWAP]
```

- **`PRIO -2`** is auto-assigned. Explicit priorities are positive.
- **`USED 0B`** means nothing has been swapped out — the machine is not under memory pressure.

**`swapon --show` produces no output at all when no swap is active.** An empty response is the answer, not an error.

| Command | Shows |
| --- | --- |
| **`swapon --show`** | **Each device, size, priority, type** |
| **`free -h`** | **The total, and how much is in use** |
| `cat /proc/swaps` | The kernel's raw view |
| `lsblk` | `[SWAP]` in the mountpoint column |
| `grep swap /etc/fstab` | **What will be active after a reboot** |

**`swapon --show` and `grep swap /etc/fstab` together answer both halves of the question**: what is active now, and what will be active after a reboot. If they disagree, something is not persistent.

**Task 2.**

Partition it (see `28-disks-partitions.md`):

```bash
lsblk
sudo fdisk /dev/sdb
```

```text
Command (m for help): n
Partition number (2-128, default 2): <Enter>
First sector: <Enter>
Last sector, ...: +512M

Command (m for help): t
Partition number (1,2, default 2): 2
Partition type or alias (type L to list all): swap
Changed type of partition 'Linux filesystem' to 'Linux swap'.

Command (m for help): p
Device       Start     End Sectors  Size Type
/dev/sdb1     2048 2099199 2097152    1G Linux filesystem
/dev/sdb2  2099200 3147775 1048576  512M Linux swap

Command (m for help): w
```

```bash
sudo partprobe /dev/sdb
lsblk /dev/sdb
```

Format and activate:

```bash
sudo mkswap /dev/sdb2
```

```text
Setting up swapspace version 1, size = 512 MiB (536866816 bytes)
no label, UUID=7d5e3a8b-9c1b-4e2d-8a5f-3e6b9c1b2d5a
```

```bash
sudo swapon /dev/sdb2
swapon --show
free -h
```

```text
NAME      TYPE      SIZE USED PRIO
/dev/dm-1 partition   2G   0B   -2
/dev/sdb2 partition 512M   0B   -3
```

**Now persist it — this is the step that scores:**

```bash
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb2)  none  swap  defaults  0 0" | sudo tee -a /etc/fstab
tail -1 /etc/fstab
```

```text
UUID=7d5e3a8b-9c1b-4e2d-8a5f-3e6b9c1b2d5a  none  swap  defaults  0 0
```

Verify:

```bash
sudo findmnt --verify
sudo swapoff /dev/sdb2
sudo swapon -a
swapon --show
```

**`swapoff` then `swapon -a` is the real test** — it proves the `/etc/fstab` entry works rather than that your manual `swapon` is still in effect. **This is the swap equivalent of `mount -a`.**

Points to note:

- **Field 2 is `none`.** Swap has no mount point.
- **Field 3 is `swap`.**
- **The type code `swap`/`82` is not required by `mkswap`** but tasks ask for it.
- **Generate the UUID with `blkid -s UUID -o value`** rather than transcribing it.
- **Do not `mkfs` a swap partition.** `mkswap` is the tool; `mkfs.xfs` would make it a filesystem and `swapon` would refuse it.

**Task 3.**

```bash
swapon --show
grep -i swap /etc/fstab
sudo findmnt --verify
sudo swapoff -a && sudo swapon -a && swapon --show
sudo reboot
```

After:

```bash
swapon --show
free -h
cat /proc/swaps
```

```text
NAME      TYPE      SIZE USED PRIO
/dev/dm-1 partition   2G   0B   -2
/dev/sdb2 partition 512M   0B   -3
```

```text
Swap:          2.5Gi          0B       2.5Gi
```

**Both devices active and the total is 2.5 GiB. Confirmed.**

If the new swap is missing:

```bash
grep -i swap /etc/fstab                   # is the line there?
sudo blkid /dev/sdb2                      # what is the actual UUID?
sudo findmnt --verify
sudo swapon -a                            # what error does it give?
journalctl -b | grep -i swap
systemctl --failed
systemctl list-units --type=swap
```

**systemd creates a `.swap` unit from each `/etc/fstab` swap line**, so failures are visible:

```bash
systemctl list-units --type=swap
systemctl status 'dev-sdb2.swap'
```

| Symptom | Cause |
| --- | --- |
| Swap absent after reboot | **No `/etc/fstab` entry** |
| Absent, entry present | **UUID mismatch** — usually a re-run of `mkswap` |
| Absent, entry present | `noauto` in the options |
| System in emergency mode | A malformed swap line in `/etc/fstab` |

**A UUID mismatch is the commonest cause**, because `mkswap` generates a new UUID every time it runs. If you re-formatted after writing the fstab line, they no longer match:

```bash
sudo blkid /dev/sdb2
grep swap /etc/fstab
```

**Task 4.**

```bash
sudo vgs
sudo lvcreate -n lv_swap -L 512M vg01
sudo lvs
```

```text
  LV      VG   LSize
  lv_data vg01 500.00m
  lv_swap vg01 512.00m
```

```bash
sudo mkswap /dev/vg01/lv_swap
sudo swapon /dev/vg01/lv_swap
swapon --show
free -h
```

```text
NAME              TYPE      SIZE USED PRIO
/dev/dm-1         partition   2G   0B   -2
/dev/mapper/vg01-lv_swap partition 512M 0B  -3
```

Persist it:

```bash
echo "/dev/vg01/lv_swap  none  swap  defaults  0 0" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo swapoff /dev/vg01/lv_swap
sudo swapon -a
swapon --show
```

**For LVM swap, prefer the device path over the UUID.** Both work, but:

| Reference | Survives a reboot | Survives re-running `mkswap` |
| --- | --- | --- |
| **`/dev/vg01/lv_swap`** | **Yes** | **Yes** |
| `UUID=...` | Yes | **No — new UUID each time** |

**Resizing swap requires re-running `mkswap`, which changes the UUID.** Using the device path means the `/etc/fstab` line keeps working. LVM device paths are stable because LVM assembles volumes from metadata rather than detection order — unlike `/dev/sdb2`.

**Note the `TYPE` column says `partition` even for an LV.** The kernel does not distinguish; only a swap *file* shows as `file`.

**Task 5.**

There is no online resize for swap, so the sequence is deactivate, extend, re-format, reactivate:

```bash
free -h                                   # confirm there is RAM for the swapped pages
sudo swapoff /dev/vg01/lv_swap
swapon --show                             # the LV is gone from the list
```

```bash
sudo vgs                                  # is there free space?
sudo lvextend -L 1G /dev/vg01/lv_swap
sudo lvs
```

```text
  Size of logical volume vg01/lv_swap changed from 512.00 MiB to 1.00 GiB.
```

```bash
sudo mkswap /dev/vg01/lv_swap
sudo swapon /dev/vg01/lv_swap
swapon --show
free -h
```

```text
NAME                     TYPE      SIZE USED PRIO
/dev/dm-1                partition   2G   0B   -2
/dev/mapper/vg01-lv_swap partition   1G   0B   -3
```

Four things to get right:

- **`swapoff` first.** `lvextend` on active swap may succeed, but the kernel keeps using the old size and `mkswap` refuses:

```text
mkswap: /dev/vg01/lv_swap: insecure permissions... 
mkswap: error: /dev/vg01/lv_swap is mounted; will not make swapspace
```

- **`mkswap` must be re-run.** Extending the LV does not extend the swap header, and there is no `swap_growfs`. **This is unlike a filesystem, where `xfs_growfs` handles it.**

- **`mkswap` generates a new UUID.** If `/etc/fstab` uses `UUID=`, update it:

```bash
sudo blkid /dev/vg01/lv_swap
grep swap /etc/fstab
sudo sed -i "s|^UUID=.*none  swap|UUID=$(sudo blkid -s UUID -o value /dev/vg01/lv_swap)  none  swap|" /etc/fstab
sudo findmnt --verify
```

**With the device path in `/etc/fstab`, nothing needs updating.**

- **`-L 1G` sets the size; `-L +512M` adds to it.** Both give 1 GiB here from 512 MiB, but be deliberate:

```bash
sudo lvextend -L 1G /dev/vg01/lv_swap       # to 1 GiB
sudo lvextend -L +512M /dev/vg01/lv_swap    # add 512 MiB
```

**Do not use `-r` here.** `-r` resizes a *filesystem*, and swap is not one:

```text
$ sudo lvextend -r -L 1G /dev/vg01/lv_swap
  fsadm: Cannot get FSTYPE of "/dev/vg01/lv_swap"
```

Verify persistence:

```bash
sudo swapoff -a && sudo swapon -a
swapon --show
```

**Task 6.**

```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=512 status=progress
```

```text
536870912 bytes (537 MB, 512 MiB) copied, 1.5 s, 358 MB/s
512+0 records in
512+0 records out
```

```bash
ls -lh /swapfile
sudo chmod 600 /swapfile
ls -lh /swapfile
```

```text
-rw-------. 1 root root 512M Aug 18 16:20 /swapfile
```

```bash
sudo mkswap /swapfile
sudo swapon /swapfile
swapon --show
free -h
```

```text
NAME      TYPE      SIZE USED PRIO
/dev/dm-1 partition   2G   0B   -2
/swapfile file      512M   0B   -3
```

**Note `TYPE file`.** Persist it:

```bash
echo "/swapfile  none  swap  defaults  0 0" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo swapoff /swapfile
sudo swapon -a
swapon --show
```

**Four requirements, and two of them catch people:**

1. **`chmod 600` is mandatory.** Without it:

```text
swapon: /swapfile: insecure permissions 0644, 0600 suggested.
```

The contents of swap are memory pages, which may include passwords and keys. `swapon` warns, and on some configurations refuses. **Always `chmod 600`.**

2. **Use `dd`, not `fallocate`, on XFS.** `fallocate` is instant but produces an extent layout XFS swap cannot use:

```text
$ sudo fallocate -l 512M /swapfile2
$ sudo mkswap /swapfile2 && sudo swapon /swapfile2
swapon: /swapfile2: swapon failed: Invalid argument
```

**`dd if=/dev/zero` always works.** It is slower, and on the exam reliability is worth more than speed.

3. **The `/etc/fstab` reference is the path, not a UUID.** A file has no filesystem UUID of its own.

4. **The file must be on a mounted local filesystem**, and its own mount must come first in `/etc/fstab`. A swap file on `/data` requires `/data` to be mounted first — one more reason `/` is the simplest location.

Removing it:

```bash
sudo sed -i '/swapfile/d' /etc/fstab
sudo swapoff /swapfile
sudo rm -f /swapfile
swapon --show
```

**Swap files are the answer when there is no spare partition or disk**, and they are trivial to resize — `swapoff`, `dd` a bigger file, `mkswap`, `swapon`.

**Task 7.**

**Cause 1: permissions.**

```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=512
sudo mkswap /swapfile
sudo swapon /swapfile
```

```text
swapon: /swapfile: insecure permissions 0644, 0600 suggested.
```

```bash
ls -l /swapfile
sudo chmod 600 /swapfile
sudo swapon /swapfile
swapon --show
```

**Swap holds memory pages, which can contain anything the system has had in RAM.** A readable swap file is a serious disclosure, so `swapon` insists on `0600`.

**Cause 2: a sparse or preallocated file.**

```bash
sudo fallocate -l 512M /swapfile2
sudo chmod 600 /swapfile2
sudo mkswap /swapfile2
sudo swapon /swapfile2
```

```text
swapon: /swapfile2: swapon failed: Invalid argument
```

The kernel needs swap blocks to be fully allocated and contiguous enough to address directly. **`fallocate` on XFS produces an extent layout that does not satisfy this**, and a sparse file created by seeking is worse:

```bash
sudo truncate -s 512M /swapfile3          # SPARSE — definitely fails
du -h --apparent-size /swapfile3          # 512M
du -h /swapfile3                          # 0 — no blocks allocated
```

**`dd if=/dev/zero` writes every block, so it always works:**

```bash
sudo rm -f /swapfile2 /swapfile3
sudo dd if=/dev/zero of=/swapfile2 bs=1M count=512
sudo chmod 600 /swapfile2
sudo mkswap /swapfile2
sudo swapon /swapfile2                    # works
```

Other reasons `swapon` refuses:

| Error | Cause | Fix |
| --- | --- | --- |
| `insecure permissions` | Not `0600` | **`chmod 600`** |
| `swapon failed: Invalid argument` | **Sparse or `fallocate`d file** | **Recreate with `dd`** |
| `read swap header failed` | **`mkswap` never run** | `mkswap /swapfile` |
| `Device or resource busy` | Already active | `swapon --show` |
| `Invalid argument` on a device | Formatted as a filesystem | `mkswap`, not `mkfs` |
| `Cannot allocate memory` (on swapoff) | Not enough free RAM | Free memory first |

**On the exam: `dd`, then `chmod 600`, then `mkswap`, then `swapon`, then `/etc/fstab`.** In that order, and it always works.

**Task 8.**

```bash
sudo swapon --show
```

Set priorities in `/etc/fstab`:

```bash
sudo vim /etc/fstab
```

```text
UUID=7d5e3a8b-...       none  swap  pri=10  0 0
/dev/vg01/lv_swap       none  swap  pri=1   0 0
```

```bash
sudo swapoff -a
sudo swapon -a
swapon --show
```

```text
NAME                     TYPE      SIZE USED PRIO
/dev/sdb2                partition 512M   0B   10
/dev/mapper/vg01-lv_swap partition   1G   0B    1
```

**The higher number is used first.** `/dev/sdb2` at priority 10 fills before `lv_swap` at priority 1 is touched.

At runtime:

```bash
sudo swapoff /dev/sdb2
sudo swapon -p 10 /dev/sdb2
swapon --show
```

**`-p` on the command line, `pri=` in `/etc/fstab`.** The runtime form does not persist.

| Priority | Range | Behaviour |
| --- | --- | --- |
| Explicit | **0 to 32767** | **Higher is used first** |
| Auto-assigned | Negative, decreasing | First device gets `-2`, next `-3`, and so on |

```bash
sudo swapon --show
```

Why you would do this: **put high priority on fast storage** (NVMe or SSD) and low priority on slow storage, so the fast device absorbs normal pressure and the slow one is only a reserve.

A task saying "so that `/dev/sdb2` is used before the logical volume" means exactly this. Both devices must have explicit, different priorities — auto-assigned negatives depend on activation order and are not something to rely on.

**Task 9.**

**Give them equal priorities:**

```bash
sudo vim /etc/fstab
```

```text
UUID=7d5e3a8b-...       none  swap  pri=10  0 0
UUID=9c1b2d5a-...       none  swap  pri=10  0 0
```

```bash
sudo swapoff -a
sudo swapon -a
swapon --show
```

```text
NAME      TYPE      SIZE USED PRIO
/dev/sdb2 partition 512M   0B   10
/dev/sdc2 partition 512M   0B   10
```

**Equal priority makes the kernel stripe across both devices round-robin**, which roughly doubles swap throughput when the devices are independent — the same idea as RAID 0, for swap.

| Configuration | Behaviour |
| --- | --- |
| **Equal priorities** | **Used in parallel, round-robin. Faster** |
| Different priorities | Higher first, then the next when full |
| No priority | Auto-assigned negatives — sequential, order not guaranteed |

Two conditions for this to help:

- **The devices must be physically independent.** Two partitions on one disk gain nothing, since the head still seeks between them.
- **They should be similar in speed.** Striping an NVMe with a spinning disk drags throughput down to the slower device.

Verify with `swapon --show` — **the `PRIO` column must show the same number for both.** Under load, the `USED` column grows on both roughly equally:

```bash
swapon --show
cat /proc/swaps
```

A task phrased "configure both swap devices to be used simultaneously" or "with equal priority" means `pri=` set to the same value on both.

**Task 10.**

```bash
swapon --show
sudo swapoff /dev/sdb2
swapon --show
free -h
```

The device disappears from the list and the total in `free -h` drops.

Reactivate from `/etc/fstab`:

```bash
sudo swapon -a
swapon --show
```

Or by name:

```bash
sudo swapon /dev/sdb2
sudo swapon UUID=7d5e3a8b-...
```

| Command | Effect |
| --- | --- |
| `swapoff DEVICE` | Deactivate one |
| **`swapoff -a`** | **Deactivate everything** |
| `swapon DEVICE` | Activate one |
| **`swapon -a`** | **Activate everything in `/etc/fstab`** |
| `swapon --show` | List what is active |

**`swapoff -a` then `swapon -a` is the swap equivalent of `mount -a`**, and it is the strongest test short of rebooting:

```bash
sudo swapoff -a
swapon --show                             # empty
sudo swapon -a
swapon --show                             # everything back?
```

**If a device does not come back, its `/etc/fstab` entry is wrong or missing.** That is exactly what would happen at the next boot, discovered without rebooting.

Note `swapoff` can be slow or fail:

```bash
free -h
sudo swapoff /dev/sdb2
```

```text
swapoff: /dev/sdb2: swapoff failed: Cannot allocate memory
```

**The kernel must read every swapped-out page back into RAM**, so there has to be room for it. See Task 14.

**Task 11.**

```bash
# 1. What is there?
swapon --show
grep -i swap /etc/fstab
sudo lvs
```

```bash
# 2. Back up fstab and REMOVE THE ENTRY FIRST
sudo cp /etc/fstab /root/fstab.bak
sudo sed -i '\|/dev/vg01/lv_swap|d' /etc/fstab
grep -i swap /etc/fstab
sudo findmnt --verify
```

```bash
# 3. Deactivate
free -h
sudo swapoff /dev/vg01/lv_swap
swapon --show
```

```bash
# 4. Remove the LV
sudo lvremove /dev/vg01/lv_swap
sudo lvs
sudo vgs
```

```bash
# 5. Verify
swapon --show
free -h
sudo findmnt --verify
sudo swapon -a && swapon --show
sudo reboot
```

**Step 2 before step 4.** Removing the LV while `/etc/fstab` still refers to it means the next boot tries to activate a device that no longer exists:

```text
[FAILED] Failed to activate swap /dev/vg01/lv_swap.
[DEPEND] Dependency failed for Swaps.
```

**Swap failures are usually less catastrophic than filesystem failures** — the boot often continues with a warning rather than dropping to emergency mode, because `swap.target` is not required by `local-fs.target`. But it is still a failed unit and a failed task:

```bash
systemctl --failed
systemctl list-units --type=swap
```

The same order applies to a swap partition and a swap file:

```bash
# partition
sudo sed -i '/UUID=7d5e3a8b/d' /etc/fstab
sudo swapoff /dev/sdb2
sudo fdisk /dev/sdb                       # d, w
sudo partprobe /dev/sdb

# file
sudo sed -i '/swapfile/d' /etc/fstab
sudo swapoff /swapfile
sudo rm -f /swapfile
```

**Removal order, always: `/etc/fstab` → `swapoff` → remove the device.**

**Task 12.**

```bash
cat /proc/sys/vm/swappiness
sudo sysctl vm.swappiness
```

```text
60
```

Runtime only:

```bash
sudo sysctl -w vm.swappiness=10
sudo sysctl vm.swappiness
cat /proc/sys/vm/swappiness
```

**That reverts at the next reboot.** Persistent:

```bash
echo 'vm.swappiness = 10' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl -p /etc/sysctl.d/99-swappiness.conf
sudo sysctl vm.swappiness
```

```text
vm.swappiness = 10
```

Verify both halves:

```bash
sudo sysctl vm.swappiness                 # current value
cat /etc/sysctl.d/99-swappiness.conf      # persistent value
sudo sysctl --system | grep -i swappiness # what will load at boot
```

**Same runtime-versus-persistent split as everything else on this exam:**

| Method | Persists |
| --- | --- |
| `sysctl -w vm.swappiness=10` | **No** |
| `echo 10 > /proc/sys/vm/swappiness` | **No** |
| **A file in `/etc/sysctl.d/`** | **Yes** |
| `/etc/sysctl.conf` | Yes, but deprecated — prefer `/etc/sysctl.d/` |

**Prefer a drop-in file in `/etc/sysctl.d/` over editing `/etc/sysctl.conf`**, the same reasoning as `/etc/sudoers.d/` in `11-password-aging-sudo.md` and systemd drop-ins in `14-systemd-services.md`.

What the value means:

| Value | Behaviour |
| --- | --- |
| `0` | Swap only to avoid an out-of-memory condition |
| `1`–`10` | **Minimal swapping. Common on database servers** |
| **`60`** | **The RHEL default** |
| `100` | Swap as readily as reclaiming page cache |
| up to `200` | Even more aggressive (newer kernels) |

Not a listed objective, but "configure swap space" could reasonably include it, and the persistence mechanism generalises to every other kernel parameter.

**Task 13.**

```bash
swapon --show
free -h
```

```text
NAME      TYPE      SIZE USED PRIO
/dev/dm-1 partition   2G   0B   -2
```

**The 512 MiB device you added is missing.** Work through it:

```bash
# 1. Is there an fstab entry at all?
grep -i swap /etc/fstab
```

If not, that is the answer — you ran `swapon` and never wrote the entry.

```bash
# 2. Does the UUID in fstab match reality?
sudo blkid | grep -i swap
grep -i swap /etc/fstab
```

```text
$ sudo blkid /dev/sdb2
/dev/sdb2: UUID="a9f3c1e7-..." TYPE="swap"

$ grep swap /etc/fstab
UUID=7d5e3a8b-...  none  swap  defaults  0 0
```

**Mismatch. This is the most common cause**, and it happens whenever you re-run `mkswap` after writing the fstab line — resizing swap, for instance. **`mkswap` generates a new UUID every time.**

```bash
sudo sed -i "s|^UUID=7d5e3a8b.*|UUID=$(sudo blkid -s UUID -o value /dev/sdb2)  none  swap  defaults  0 0|" /etc/fstab
sudo findmnt --verify
sudo swapon -a
swapon --show
```

```bash
# 3. What error does swapon -a report?
sudo swapon -a
```

```bash
# 4. What did systemd say at boot?
systemctl list-units --type=swap
systemctl --failed
journalctl -b | grep -i swap
```

The full list of causes:

| Cause | Detect with | Fix |
| --- | --- | --- |
| **No fstab entry** | `grep swap /etc/fstab` | **Add it** |
| **UUID mismatch** | `blkid` vs `/etc/fstab` | **Update the entry, or use the device path** |
| `noauto` in the options | `grep swap /etc/fstab` | Remove `noauto` |
| Device removed | `lsblk` | Remove the entry |
| Never `mkswap`ed | `blkid` shows no `TYPE="swap"` | `mkswap` |
| Swap file deleted | `ls -l /swapfile` | Recreate it |
| Swap file wrong permissions | `ls -l /swapfile` | `chmod 600` |
| Swap file's filesystem not mounted | `df -h` | Fix the mount ordering |

**Two defences against the UUID problem:**

```bash
# 1. For LVM swap, use the device path — immune to mkswap
/dev/vg01/lv_swap  none  swap  defaults  0 0

# 2. Always test with swapoff -a; swapon -a before rebooting
sudo swapoff -a && sudo swapon -a && swapon --show
```

**Task 14.**

```bash
sudo swapoff /dev/sdb2
```

```text
swapoff: /dev/sdb2: swapoff failed: Cannot allocate memory
```

**`swapoff` must read every swapped-out page back into RAM.** If there is not enough free memory to hold them, it cannot finish:

```bash
free -h
swapon --show
```

```text
               total        used        free      shared  buff/cache   available
Mem:           1.7Gi       1.5Gi       102Mi       9.0Mi       180Mi       120Mi
Swap:          2.5Gi       800Mi       1.7Gi

NAME      TYPE      SIZE  USED PRIO
/dev/sdb2 partition 512M  400M   -3
```

**400 MiB is swapped out on that device and only 120 MiB of RAM is available.** It cannot be done as things stand.

Free some memory first:

```bash
# a. What is using it?
ps aux --sort=-%mem | head -10
top -o %MEM

# b. Stop or restart something large
sudo systemctl stop <some-service>

# c. Drop caches (safe, but only reclaims cache)
sudo sync
sudo sysctl -w vm.drop_caches=3
free -h

# d. Retry
sudo swapoff /dev/sdb2
```

Other approaches:

```bash
# Move the pages to another swap device instead of to RAM:
# ensure another swap device with enough room is active, then
swapon --show
sudo swapoff /dev/sdb2                    # the kernel migrates pages there
```

```bash
# Or add swap first, then remove the old device
sudo dd if=/dev/zero of=/tmpswap bs=1M count=1024
sudo chmod 600 /tmpswap
sudo mkswap /tmpswap && sudo swapon /tmpswap
sudo swapoff /dev/sdb2                    # now there is somewhere for the pages
sudo swapoff /tmpswap && sudo rm -f /tmpswap
```

```bash
# Or, if the system permits it, just reboot with the fstab entry removed
sudo sed -i '/UUID=7d5e3a8b/d' /etc/fstab
sudo findmnt --verify
sudo reboot                               # swap is simply never activated
```

**On the exam this is unlikely** — the VMs are lightly loaded and `USED` is almost always `0B`. But recognise the error and know that the fix is freeing memory, not forcing the command. **`swapoff` has no `--force`, by design: forcing it would mean discarding memory pages.**

Related symptoms:

| Message | Meaning |
| --- | --- |
| `swapoff failed: Cannot allocate memory` | **Not enough free RAM for the swapped pages** |
| `swapoff` takes minutes | Working, but a lot to read back. Wait |
| `swapoff: not found` | The device is not active. `swapon --show` |

**Task 15.**

Before the reboot:

```bash
swapon --show
free -h
grep -i swap /etc/fstab
sudo blkid | grep -i swap
sudo findmnt --verify
sudo swapoff -a && sudo swapon -a && swapon --show
```

Everything must hold:

- **`swapon --show` lists every device the tasks required, with the right sizes.**
- **`/etc/fstab` has an entry for each.**
- **The UUIDs in `/etc/fstab` match `blkid`.**
- **`swapoff -a` then `swapon -a` brings everything back.**
- `findmnt --verify` reports no errors.
- A swap file, if any, is `0600`.

```bash
sudo reboot
```

After:

```bash
swapon --show
free -h
cat /proc/swaps
systemctl list-units --type=swap
systemctl --failed
journalctl -b | grep -i swap
```

```text
NAME                     TYPE      SIZE USED PRIO
/dev/dm-1                partition   2G   0B   -2
/dev/sdb2                partition 512M   0B   10
/dev/mapper/vg01-lv_swap partition   1G   0B    1
/swapfile                file      512M   0B   -5
```

**Every device active with the expected sizes and priorities. That is the confirmation.**

```bash
# The pre-reboot swap check, in three lines
swapon --show
grep -i swap /etc/fstab
sudo swapoff -a && sudo swapon -a && swapon --show
```

**`swapoff -a; swapon -a` is the whole test.** If a device does not come back, it will not come back after a reboot either — and you have found out without rebooting.

---

## Verify

```bash
swapon --show
swapon -s
free -h
cat /proc/swaps
grep -i swap /etc/fstab
sudo blkid | grep -i swap
lsblk -f | grep -i swap
ls -l /swapfile
sudo findmnt --verify
sudo swapoff -a && sudo swapon -a && swapon --show
systemctl list-units --type=swap
sudo sysctl vm.swappiness
```

## Persistence Check

| Change | Non-persistent | **Persistent** |
| --- | --- | --- |
| Swap active | **`swapon /dev/sdb2`** | **An `/etc/fstab` entry, type `swap`** |
| Swap formatted | — | `mkswap` writes a header to the device |
| Priority | `swapon -p 10 DEV` | **`pri=10` in the options field** |
| Swappiness | `sysctl -w vm.swappiness=10` | **A file in `/etc/sysctl.d/`** |
| Swap file exists | — | The file on disk, `0600` |

**The `/etc/fstab` line is the only thing that makes swap persistent:**

```text
UUID=7d5e3a8b-...  none  swap  defaults  0 0
/dev/vg01/lv_swap  none  swap  defaults  0 0
/swapfile          none  swap  defaults  0 0
```

**Two traps specific to swap:**

1. **`mkswap` generates a new UUID every time it runs.** Re-format a swap device and any `UUID=` entry in `/etc/fstab` is stale. **Use the device path for LVM swap**, or update the entry.
2. **A swap file must be `0600`** or `swapon` complains, and must be created with `dd` rather than `fallocate` on XFS.

```bash
# The pre-reboot swap check
swapon --show
grep -i swap /etc/fstab
sudo swapoff -a && sudo swapon -a && swapon --show
```

## Exam Tips

- **Three steps: `mkswap`, `swapon`, `/etc/fstab`.** The third is where the marks are.
- **The fstab line is `<device>  none  swap  defaults  0 0`.** Field 2 is `none` — swap has no mount point.
- **`swapon --show` and `free -h`** are the verification commands. `swapon --show` prints nothing when no swap is active.
- **`swapoff -a` then `swapon -a` is the swap equivalent of `mount -a`.** Run it before every reboot; if a device does not come back, its fstab entry is wrong.
- **`mkswap` generates a new UUID each time it runs.** Re-formatting swap invalidates a `UUID=` entry. **Prefer the device path for LVM swap.**
- **Partition type `swap` (82 MBR / 19 GPT)** is what tasks ask for, even though `mkswap` does not need it.
- **Do not `mkfs` a swap device.** `mkswap` is the tool.
- **Swap file: `dd`, then `chmod 600`, then `mkswap`, then `swapon`, then fstab.** In that order.
- **`fallocate` fails on XFS for swap files.** Use `dd if=/dev/zero`.
- **`chmod 600` on a swap file is mandatory** — its contents are memory pages.
- **Resizing swap: `swapoff` → `lvextend` → `mkswap` → `swapon`.** There is no online grow, and **do not use `lvextend -r`** — swap is not a filesystem.
- **`pri=N` in fstab, `-p N` on the command line.** Higher is used first; equal values are used in parallel.
- **Removal order: `/etc/fstab` first, then `swapoff`, then remove the device.**
- **`swapoff` failing with "Cannot allocate memory"** means there is not enough free RAM for the swapped-out pages. Free memory, or add swap elsewhere first.
- **Swappiness persists via `/etc/sysctl.d/99-*.conf`**, not `sysctl -w`.
- **`systemctl list-units --type=swap`** shows systemd's view, useful when swap fails to activate at boot.
