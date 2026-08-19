# Boot And Recovery Deep Dive

"Interrupt the boot process to gain access to a system" and "modify the system bootloader" are stated objectives. The root password reset is close to guaranteed on the exam. Recovering from your own bad `/etc/fstab` is not on the objective list and is the skill most likely to save your exam.

Step-by-step tasks are in `16.md` and `17.md`.

**Practise these in a VM with a snapshot until they are muscle memory.** They are the tasks where hesitation costs the most time.

---

## The boot chain

```text
   Firmware (BIOS or UEFI)
        │  finds a bootloader
        ▼
   GRUB 2                         /boot/grub2/grub.cfg
        │  ← PRESS 'e' HERE to edit a menu entry for one boot
        │  ← PRESS 'c' for a GRUB command line
        ▼
   Kernel + initramfs             kernel arguments take effect here
        │  ← rd.break stops HERE, in the initramfs
        ▼
   switch_root to the real /      the real root filesystem is mounted
        │
        ▼
   systemd (PID 1)
        │  ← systemd.unit=... selects a target here
        ▼
   default.target
        │
        ├─ sysinit.target         local filesystems, swap  ← a bad fstab FAILS HERE
        ├─ basic.target
        └─ multi-user.target      your services
```

**Which failure happens where determines which recovery you need:**

| Failure | Stops at | Recovery |
| --- | --- | --- |
| Forgotten root password | Boots fine, cannot log in | **`rd.break`** |
| Bad `/etc/fstab` | `sysinit.target` | **Emergency mode, root password required** |
| Broken SELinux labels | Various, often login | **`enforcing=0`, then relabel** |
| Damaged GRUB configuration | Before the kernel | **GRUB command line, or rescue media** |
| Corrupted root filesystem | Initramfs or `sysinit` | **Rescue media, `xfs_repair`** |
| A failed service | Boots, service down | **Normal login, `journalctl -xeu`** |

---

## Root password reset

**The procedure, exactly.**

```text
 1. Reboot the machine.

 2. At the GRUB menu, highlight the kernel entry and press  e
    (not Enter — 'e' edits)

 3. Find the line beginning with  linux  (it is long, and wraps).
    Move to the END of that line and append a space and:

        rd.break

 4. Press  Ctrl-x  to boot with that change.

 5. You land at a  switch_root:/#  prompt. The real root filesystem is
    mounted READ-ONLY at /sysroot.

        mount -o remount,rw /sysroot

 6. Make /sysroot the root of your view:

        chroot /sysroot

 7. Set the password:

        passwd root

 8. Schedule a full SELinux relabel — REQUIRED:

        touch /.autorelabel

 9. Leave the chroot:

        exit

10. Leave the initramfs shell:

        exit

11. The machine continues booting, relabels the filesystem (this is slow
    and it reboots itself once more), and then you can log in.
```

### Why each step

**`rd.break`** stops the initramfs before it hands control to the real system, so nothing on the real root filesystem is running — no password required, no services to fight.

**`mount -o remount,rw /sysroot`** — the initramfs mounts the real root read-only. `passwd` cannot write to a read-only filesystem.

```text
passwd: Authentication token manipulation error
```

**That error means you skipped the remount.**

**`chroot /sysroot`** — without it, `passwd` edits the initramfs's own tiny `/etc/shadow`, which is discarded. The password appears to be set and nothing changes.

**`touch /.autorelabel`** — this is the step people forget and it is the one that makes the difference between success and a mystifying failure.

```text
SELinux is not active in the initramfs.
    → passwd writes /etc/shadow with NO or WRONG SELinux label
    → after the reboot, with SELinux enforcing, the login process
      cannot read /etc/shadow
    → the new password does not work, and nor does the old one
```

**`/.autorelabel` triggers a full filesystem relabel at the next boot**, which fixes `/etc/shadow` along with everything else. The file is removed automatically afterwards.

**The relabel is slow** — several minutes on a small VM, with a progress display of asterisks — **and the machine reboots itself when it finishes. Do not interrupt it.**

### The narrower alternative

Instead of a full relabel, relabel just the file:

```text
 7. passwd root
 8. restorecon -v /etc/shadow      ← instead of touch /.autorelabel
```

**This is faster and works**, but only if nothing else needs relabelling. **`touch /.autorelabel` is the safer answer for the exam** because it cannot be incomplete.

### If you already rebooted without the relabel

```text
1. Reboot; press e at the GRUB menu
2. Append  enforcing=0  to the linux line
3. Ctrl-x
4. Log in as root with the new password — it works, because SELinux is permissive
5. sudo restorecon -v /etc/shadow
   or: sudo touch /.autorelabel && sudo reboot
6. Confirm: getenforce
```

**`enforcing=0` boots with SELinux permissive for one boot only.** It is the escape hatch for any SELinux problem that prevents login, and it is worth remembering independently of this procedure.

### `init=/bin/bash`

An alternative interruption point:

```text
1. At GRUB, press e
2. Append  init=/bin/bash  to the linux line
3. Ctrl-x
4. mount -o remount,rw /
5. passwd root
6. touch /.autorelabel
7. exec /usr/lib/systemd/systemd     (or force a reboot)
```

**Differences from `rd.break`:**

| | `rd.break` | `init=/bin/bash` |
| --- | --- | --- |
| Stops in | **The initramfs** | The real system, as PID 1 |
| Root filesystem at | **`/sysroot`, read-only** | **`/`, read-only** |
| Needs `chroot` | **Yes** | **No** |
| Remount command | `mount -o remount,rw /sysroot` | **`mount -o remount,rw /`** |
| Exiting | `exit` twice continues the boot | **Nothing continues — you must reboot** |
| **Recommended** | **Yes** | Works, less standard |

**`rd.break` is the documented Red Hat procedure. Use it.** But recognise `init=/bin/bash` because older material uses it, and because `reboot` may not work from it — you may need `exec /sbin/init` or a forced power cycle.

---

## Rescue and emergency modes

```text
At the GRUB menu, press e and append to the linux line:

    systemd.unit=rescue.target       ← more of the system started
    systemd.unit=emergency.target    ← the bare minimum
```

| | `rescue.target` | `emergency.target` |
| --- | --- | --- |
| Root filesystem | **Mounted read-write** | **Mounted READ-ONLY** |
| Other filesystems | Mounted | **Not mounted** |
| Basic services | Started | **Almost none** |
| **Root password** | **Required** | **Required** |
| Use for | General repair | **When even rescue fails** |

**Both require the root password.** They are not a way in when you have forgotten it — that is what `rd.break` is for.

From a running system:

```bash
sudo systemctl isolate rescue.target
sudo systemctl isolate emergency.target
sudo systemctl default                        # back to normal
```

**In emergency mode, remount read-write before editing anything:**

```bash
mount -o remount,rw /
```

Other GRUB arguments worth knowing:

| Argument | Effect |
| --- | --- |
| **`rd.break`** | **Stop in the initramfs** |
| `init=/bin/bash` | A shell as PID 1 |
| `systemd.unit=rescue.target` | Single-user |
| `systemd.unit=emergency.target` | Minimal |
| **`enforcing=0`** | **SELinux permissive for this boot** |
| `selinux=0` | SELinux off entirely — **avoid; it leaves files unlabelled** |
| `systemd.debug-shell=1` | A root shell on tty9 |
| `rd.shell` | A shell if the initramfs fails |
| `nomodeset` | Basic graphics |
| `single`, `1`, `3`, `5` | Legacy runlevel-style targets |
| `rhgb quiet` | Graphical boot, suppressed messages — remove these to see errors |

**`enforcing=0` versus `selinux=0`:** the first keeps SELinux loaded and permissive, so labelling still happens; the second disables it entirely, so new files get no labels and you will need a relabel afterwards. **Always prefer `enforcing=0`.**

---

## Recovering from a bad `/etc/fstab`

**This is the most likely emergency you will create yourself, and it is the fastest to fix once you have done it once.**

```text
Symptom:

  [DEPEND] Dependency failed for /data.
  [DEPEND] Dependency failed for Local File Systems.
  You are in emergency mode. After logging in, type "journalctl -xb" to view
  system logs...
  Give root password for maintenance (or press Control-D to continue):
```

```bash
# 1. Enter the root password

# 2. Find out what failed
systemctl --failed
journalctl -xb | grep -i -A5 fail
findmnt --verify

# 3. Make / writable
mount -o remount,rw /

# 4. Fix the file
vi /etc/fstab
#    Comment out the bad line with # or correct it.
#    If you are unsure, comment it out — a missing mount loses one task;
#    an unbootable system loses all of them.

# 5. Tell systemd to re-read it
systemctl daemon-reload

# 6. Prove it now works
mount -a
findmnt --verify

# 7. Reboot
reboot
```

**Step 4's advice matters under time pressure. Comment out, reboot, then fix properly with a working system.**

### The common causes

| Cause | Prevention |
| --- | --- |
| A mistyped UUID | **`echo "UUID=$(blkid -s UUID -o value /dev/sdb1) ..." \| sudo tee -a`** |
| A mount point that does not exist | `sudo mkdir -p /data` first |
| The wrong filesystem type | `lsblk -f` to check |
| A device that was later deleted | **Remove the fstab line BEFORE deleting a partition** |
| An NFS entry without `_netdev` | Always include it |
| A device that may be absent | **`nofail`** |
| The wrong field count | Six fields, whitespace separated |

**Every one of these is caught by two commands before rebooting:**

```bash
sudo findmnt --verify
sudo mount -a
```

**`nofail` is the safety net worth using freely:**

```text
UUID=xxxx  /data  xfs  defaults,nofail  0 0
```

**With `nofail`, a missing device means the mount is skipped and the boot continues.** You lose one task instead of the machine.

### If `/` itself will not mount

Boot the installation media:

```text
1. Boot the RHEL ISO
2. Troubleshooting → Rescue a Red Hat Enterprise Linux system
3. Continue (option 1) — this mounts your system at /mnt/sysroot
4. chroot /mnt/sysroot
5. vi /etc/fstab
6. exit
7. reboot
```

**Or repair the filesystem, unmounted:**

```bash
xfs_repair /dev/mapper/rhel-root
e2fsck -fy /dev/sdb1
```

---

## GRUB 2

### The files

| Path | Role |
| --- | --- |
| **`/etc/default/grub`** | **What you edit: timeout, default entry, kernel arguments** |
| `/etc/grub.d/` | Scripts that generate the configuration |
| **`/boot/grub2/grub.cfg`** | **GENERATED. Do not edit by hand** |
| `/boot/loader/entries/*.conf` | **BLS entries, one per kernel, on RHEL 8+** |
| `/boot/efi/EFI/redhat/grub.cfg` | UEFI location on older releases |
| `/boot/grub2/grubenv` | Saved default and one-shot settings |

```bash
cat /etc/default/grub
sudo cat /boot/grub2/grub.cfg | head -40
ls -l /boot/loader/entries/
cat /boot/loader/entries/*.conf
sudo grub2-editenv list
```

### `/etc/default/grub`

```text
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=rhel/root rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
GRUB_ENABLE_BLSCFG=true
```

| Setting | Effect |
| --- | --- |
| **`GRUB_TIMEOUT`** | **Menu countdown in seconds. `0` skips the menu, `-1` waits forever** |
| **`GRUB_CMDLINE_LINUX`** | **Kernel arguments for every entry** |
| `GRUB_DEFAULT=saved` | Use the saved entry |
| `GRUB_TERMINAL_OUTPUT="console"` | Text menu |
| `GRUB_ENABLE_BLSCFG=true` | Per-kernel entries in `/boot/loader/entries/` |
| `GRUB_DISABLE_SUBMENU=true` | Flat menu, no "Advanced options" submenu |

**Editing the file changes nothing on its own:**

```bash
sudo vim /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

**On RHEL 9 and 10 that single path works for both BIOS and UEFI systems.** Older documentation gives a separate `/boot/efi/EFI/redhat/grub.cfg` path for UEFI; on current releases it is a symlink or unnecessary.

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

```text
Generating grub configuration file ...
Adding boot menu entry for UEFI Firmware Settings ...
done
```

**Verify before rebooting:**

```bash
sudo grep -E 'linux|options' /boot/grub2/grub.cfg | head
cat /boot/loader/entries/*.conf
sudo grubby --info=ALL
```

### grubby

**`grubby` edits kernel arguments without touching `/etc/default/grub` or running `grub2-mkconfig`.** It is faster and harder to get wrong.

```bash
sudo grubby --info=ALL
sudo grubby --default-kernel
sudo grubby --default-index
sudo grubby --info=DEFAULT
sudo grubby --update-kernel=ALL --args="console=ttyS0"
sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"
sudo grubby --update-kernel=DEFAULT --args="audit=1"
sudo grubby --update-kernel=/boot/vmlinuz-5.14.0-427.el9.x86_64 --args="quiet"
sudo grubby --set-default=/boot/vmlinuz-5.14.0-427.el9.x86_64
sudo grubby --set-default-index=1
```

```bash
sudo grubby --info=DEFAULT
```

```text
index=0
kernel="/boot/vmlinuz-5.14.0-427.el9.x86_64"
args="ro crashkernel=1G-4G:192M rd.lvm.lv=rhel/root rhgb quiet"
root="/dev/mapper/rhel-root"
initrd="/boot/initramfs-5.14.0-427.el9.x86_64.img"
title="Red Hat Enterprise Linux (5.14.0-427.el9.x86_64) 9.4 (Plow)"
```

**`--update-kernel=ALL` applies to every installed kernel**, which is what you want so the change survives a kernel update. **But it does not update `/etc/default/grub`, so a *future* kernel installed later will not have it.** Belt and braces:

```bash
sudo grubby --update-kernel=ALL --args="audit=1"
sudo sed -i 's/^GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 audit=1"/' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
grep GRUB_CMDLINE /etc/default/grub
sudo grubby --info=ALL | grep args
```

### Default entry

```bash
sudo grubby --default-kernel
sudo grubby --info=ALL | grep -E '^index|^title'
sudo grub2-set-default 0
sudo grub2-set-default "Red Hat Enterprise Linux (5.14.0-427.el9.x86_64) 9.4 (Plow)"
sudo grub2-editenv list
sudo grub2-reboot 1                           # ONE boot only, then revert
```

**`grub2-reboot` is the safe way to test a different kernel** — if it does not boot, the next reboot goes back to the working one.

### The GRUB command line

Pressing `c` at the menu gives a GRUB prompt, for when the configuration is broken enough that no entry works:

```text
grub> ls
grub> ls (hd0,gpt2)/
grub> set root=(hd0,gpt2)
grub> linux /vmlinuz-5.14.0-427.el9.x86_64 root=/dev/mapper/rhel-root ro
grub> initrd /initramfs-5.14.0-427.el9.x86_64.img
grub> boot
```

**Unlikely on the exam, but knowing it exists means a corrupted `grub.cfg` is not fatal.** Once booted, regenerate:

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### Reinstalling GRUB

```bash
# BIOS
sudo grub2-install /dev/sda
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# UEFI — grub2-install is not used
sudo dnf reinstall -y grub2-efi-x64 grub2-efi-x64-modules shim-x64
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

```bash
[[ -d /sys/firmware/efi ]] && echo UEFI || echo BIOS
```

**Check which you are on before running either.** `grub2-install` on a UEFI system is wrong and can make things worse.

### Kernel management

```bash
uname -r
rpm -q kernel
sudo grubby --info=ALL | grep title
sudo dnf install -y kernel                     # installs alongside, keeps the old
sudo dnf remove kernel-5.14.0-360.el9.x86_64
grep installonly_limit /etc/dnf/dnf.conf       # how many kernels are kept
```

**RHEL keeps three kernels by default and each gets its own GRUB entry.** That is what makes booting an older kernel a viable recovery when a new one misbehaves.

---

## Diagnosing a boot failure

```bash
# From a booted system
journalctl -b                                  # this boot
journalctl -b -1                               # the previous boot — the one that failed
journalctl -b -1 -p err
journalctl --list-boots
systemctl --failed
systemd-analyze blame
systemd-analyze critical-chain
dmesg | tail -40
```

**`journalctl -b -1` only works with a persistent journal.** Set it up early:

```bash
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
journalctl --list-boots
```

**Without persistence, a failed boot leaves no evidence.** This is why "preserve system journals" is an objective.

**To see boot messages instead of the graphical splash:**

```bash
sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"
```

```text
Symptom                                         Likely cause
─────────────────────────────────────────────────────────────────────────────
"Dependency failed for Local File Systems"       /etc/fstab. Emergency mode
Emergency mode, asks for the root password       /etc/fstab, or a filesystem error
Hangs at "A start job is running for..."         A mount waiting for a device;
                                                 nofail, or _netdev for NFS
"Cannot open access to console"                  Root filesystem not found
Boots, cannot log in with a correct password     SELinux label on /etc/shadow;
                                                 enforcing=0 then restorecon
"Give root password for maintenance"             Any sysinit failure
No GRUB menu at all                              GRUB_TIMEOUT=0, or damaged GRUB
Kernel panic, "no init found"                    Wrong root=, damaged initramfs
Boots to a text prompt when you wanted GUI        systemctl get-default
Slow boot                                        systemd-analyze blame
```

**Rebuilding the initramfs, when a driver or LVM change breaks boot:**

```bash
sudo dracut -f
sudo dracut -f --regenerate-all
sudo lsinitrd | head -30
```

---

## Persistence in this domain

| Change | Persistent form |
| --- | --- |
| A GRUB argument added at the menu with `e` | **Not persistent — that boot only** |
| A kernel argument | **`/etc/default/grub` + `grub2-mkconfig`**, or `grubby --update-kernel=ALL` |
| Menu timeout | `GRUB_TIMEOUT` + `grub2-mkconfig` |
| Default kernel | `grub2-set-default` or `grubby --set-default` |
| Default target | **`systemctl set-default`** |
| A one-boot target via `systemd.unit=` | **Not persistent** |
| The root password | `passwd` writes `/etc/shadow` — persistent |
| SELinux relabel | `/.autorelabel` — consumed at the next boot |
| An fstab fix | The file itself — but run `findmnt --verify` |

**Anything typed at the GRUB menu applies to one boot only.** That is deliberate and it is what makes GRUB editing safe: a mistake is undone by rebooting.

**A task saying "the system must always boot with X" means `/etc/default/grub` plus `grub2-mkconfig`, or `grubby --update-kernel=ALL`.**

---

## Verification

```bash
# Kernel arguments — what is running, and what is configured
cat /proc/cmdline
sudo grubby --info=ALL | grep args
grep GRUB_CMDLINE /etc/default/grub
sudo grep -E '^\s+linux|options' /boot/grub2/grub.cfg | head
cat /boot/loader/entries/*.conf

# Default kernel and target
sudo grubby --default-kernel
systemctl get-default

# Boot health
systemctl --failed
journalctl -b -p err
systemd-analyze
findmnt --verify

# The root password
su - root                                      # or log in on the console
```

**`cat /proc/cmdline` shows what the running kernel actually received.** Comparing it with `grubby --info=ALL` tells you whether a change is active, configured, or both:

```bash
cat /proc/cmdline
sudo grubby --info=DEFAULT | grep args
```

| /proc/cmdline | grubby args | Meaning |
| --- | --- | --- |
| Has it | Has it | **Done** |
| Lacks it | **Has it** | **Configured; reboot to activate** |
| **Has it** | Lacks it | **Typed at GRUB; not persistent** |
| Lacks it | Lacks it | Not done |

---

## Practise drill

**Do this in a snapshotted VM until each step is automatic.**

```text
1. Snapshot.

2. Root password reset
   - passwd root; set it to something you will not remember
   - reboot
   - rd.break, remount, chroot, passwd, /.autorelabel, exit, exit
   - wait for the relabel
   - log in
   Target: under three minutes, no notes.

3. Bad fstab
   echo "UUID=00000000-0000-0000-0000-000000000000 /broken xfs defaults 0 0" \
     | sudo tee -a /etc/fstab
   sudo reboot
   - recover in emergency mode
   Then do it again with ,nofail on the end and observe that the boot succeeds.

4. Broken SELinux label
   sudo chcon -t user_home_t /etc/shadow
   sudo reboot
   - enforcing=0, log in, restorecon, reboot

5. A kernel argument, persistently
   sudo grubby --update-kernel=ALL --args="audit=1"
   sudo reboot
   grep audit /proc/cmdline

6. Boot to a different target
   sudo systemctl set-default multi-user.target
   sudo reboot
   systemctl get-default

7. Restore the snapshot.
```

---

## The five things to take away

1. **`rd.break`, `mount -o remount,rw /sysroot`, `chroot /sysroot`, `passwd root`, `touch /.autorelabel`, `exit`, `exit`.** Learn it as one sequence.
2. **`/.autorelabel` is not optional.** Without it the new password does not work.
3. **`enforcing=0` at GRUB is the escape hatch for any SELinux problem that blocks login.**
4. **`findmnt --verify` and `mount -a` before every reboot.** A bad fstab line is the only mistake that can cost you the whole exam, and `nofail` is the cheap insurance.
5. **Anything typed at the GRUB menu lasts one boot.** Persistence means `/etc/default/grub` plus `grub2-mkconfig`, or `grubby --update-kernel=ALL`.
