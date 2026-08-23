# 16. Interrupting The Boot Process And Root Password Recovery

**Objective:** Interrupt the boot process in order to gain access to a system.

**This is an almost-certain exam task**, and if it appears it is usually the *first* thing you must do, because every other task on that machine depends on having root. Practise it until it takes two minutes.

You must do this from a **console**, not SSH. Set up console access in your lab now (`virsh console`, the VirtualBox window, or the VMware console).

## Before You Start

You need a running lab VM with **console access**. If you have not built one yet, do `Lab-Setup.md` first. Take a snapshot before the password-reset tasks.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — work from the VM console. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

The six `rd.break` commands fit on an index card. Write them there and drill until they are muscle memory.

---

## Follow Along

Work from your **VM console**, not SSH. After each step, compare your output to **You should see**.

### 1. The three ways in

| Method | Use when | Reboots needed |
| --- | --- | :---: |
| **`rd.break`** | **Forgot the root password.** The standard RHEL answer | 2 |
| `init=/bin/bash` | `rd.break` is unavailable or you need the real root filesystem | 2 |
| `systemd.unit=rescue.target` | You know the root password but a service or target is broken | 1 |

Also relevant: emergency mode, which you land in involuntarily when `/etc/fstab` is broken.

**You should see** `rd.break` as the default answer for a forgotten root password. The other methods are fallbacks.

### 2. Where you interrupt — the GRUB menu

At the **GRUB menu**, which appears for a few seconds at boot:

```text
┌──────────────────────────────────────────────────────┐
│  Red Hat Enterprise Linux (5.14.0-...) 10.0          │  <- highlight this
│  Red Hat Enterprise Linux (0-rescue-...) 10.0        │
│                                                      │
│   Use the ↑ and ↓ keys to change the selection.      │
│   Press 'e' to edit the selected item, or 'c' for a  │
│   command prompt.                                    │
└──────────────────────────────────────────────────────┘
```

- **`e`** — edit the selected entry. This is what you want.
- `c` — a GRUB command prompt.
- `Esc` — back to the menu.

If the menu flashes past too fast, hold **`Shift`** during boot (BIOS) or press **`Esc`** repeatedly (UEFI). To make it stay longer for practice, see `17-bootloader.md`.

**You should see** the menu if `GRUB_TIMEOUT` is set high enough. If not, adjust it in `17-bootloader.md` first.

### 3. Edit the kernel line and boot once

Inside the editor, find the line beginning **`linux`** (older systems: `linux16` or `linuxefi`). It looks like:

```text
linux ($root)/vmlinuz-5.14.0-... root=/dev/mapper/rhel-root ro crashkernel=1G-4G:192M ...
```

You append your argument to **the end of that line**, then boot with **`Ctrl+x`**.

**`Ctrl+x` boots. `Ctrl+c` gives a GRUB prompt. `Esc` discards your edit.** Losing time here because you cannot remember how to boot is a real risk, so memorise `Ctrl+x`.

Edits made here are **temporary** — they apply to this boot only and are not written to disk. That is exactly what you want for a recovery.

**You should see** the kernel line with your appended argument when you press `e`. Nothing is saved to disk until you edit `/etc/default/grub` and run `grub2-mkconfig`.

### 4. `rd.break` — the standard answer

This is the method to learn. Memorise the six commands.

```text
1. Reboot. At the GRUB menu, press 'e'
2. Find the line starting with 'linux'
3. Go to the END of that line (Ctrl+e, or End)
4. Append:  rd.break
   Optionally also remove 'rhgb quiet' so you can see what happens
5. Press Ctrl+x to boot
```

You land at a shell that says:

```text
switch_root:/#
```

You are in the **initramfs**, before the real root filesystem has been switched to. Your real system is mounted at **`/sysroot`**, and it is mounted **read-only**.

Now the six commands:

```bash
# 1. Make the real root filesystem writable
mount -o remount,rw /sysroot

# 2. Make /sysroot appear as / so commands operate on the real system
chroot /sysroot

# 3. Change the password
passwd root

# 4. Tell SELinux to relabel everything on the next boot
touch /.autorelabel

# 5. Leave the chroot
exit

# 6. Reboot
exit
```

The final `exit` leaves the initramfs shell and continues the boot. You can also type `reboot`.

The system then boots, relabels the filesystem (this takes a minute or two and prints progress), and **reboots again automatically**. After that second reboot, log in with the new password.

**You should see** a relabel progress display after the first reboot, then a second automatic reboot. After that, the new root password works.

### 5. Why each `rd.break` step matters

**`mount -o remount,rw /sysroot`** — `/sysroot` is read-only by default at this stage. Without this, `passwd` fails with a read-only filesystem error. This is the most commonly forgotten step.

**`chroot /sysroot`** — without it, `passwd` would edit the initramfs's own `/etc/shadow`, which is discarded. Your change would silently do nothing. This is the second most commonly forgotten step, and it is worse because it *appears* to succeed.

**`touch /.autorelabel`** — this is the RHEL-specific step and the one that separates people who have practised from people who have read about it.

When you write `/etc/shadow` from inside the initramfs, SELinux is not enforcing, so the new file gets a **wrong or missing security context**. On the next normal boot, SELinux is enforcing, cannot read `/etc/shadow`, and **login fails even with the correct password**. You would be locked out again.

`/.autorelabel` triggers a full filesystem relabel on the next boot, fixing the context. The relabel then removes the flag file and reboots.

**If you forget `/.autorelabel`**, the recovery is to boot with SELinux disabled and fix it:

```text
At GRUB, press 'e' and append:  enforcing=0
Ctrl+x
```

Then once logged in:

```bash
sudo restorecon -v /etc/shadow
# or, more thoroughly
sudo touch /.autorelabel && sudo reboot
```

**You should see** `shadow_t` on `/etc/shadow` after a successful relabel:

```bash
ls -Z /etc/shadow
# system_u:object_r:shadow_t:s0 /etc/shadow
```

### 6. The whole sequence, condensed

Write this on a card and drill it:

```text
GRUB -> e -> append rd.break -> Ctrl+x

mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
exit
exit
```

**You should see** this sequence become automatic after a few practice runs from the console.

### 7. `init=/bin/bash` — the fallback

An alternative worth knowing, especially if `rd.break` is not available.

```text
At GRUB: press 'e', append to the linux line:

  rw init=/bin/bash

Ctrl+x
```

Note the **`rw`**: without it the root filesystem is read-only and `passwd` fails. You should also remove the existing `ro` if present, though adding `rw` after it usually wins.

You land directly at a bash prompt with the **real** root filesystem mounted at `/` — no chroot needed.

```bash
passwd root
touch /.autorelabel

# You cannot reboot normally: systemd is not running
exec /sbin/init
# or
/usr/sbin/reboot -f
# or, most reliably
mount -o remount,ro /
reboot -f
```

**The awkward part is exiting.** There is no init to ask for a clean shutdown, so you must force it. `exec /sbin/init` hands over to systemd and continues a normal boot, which is the tidiest option. Failing that, remount read-only and force a reboot so the filesystem is not left dirty.

`rd.break` is cleaner. Use `init=/bin/bash` as a fallback.

**You should see** `mount | grep ' / '` showing `rw` before you run `passwd`.

### 8. Boot to a different target from GRUB

When you know the root password but the system will not reach a usable state.

```text
At GRUB, press 'e' and append one of:

  systemd.unit=rescue.target       minimal services, filesystems mounted
  systemd.unit=emergency.target    only /, read-only
  systemd.unit=multi-user.target   skip a broken graphical target
  single                           equivalent to rescue

Ctrl+x
```

You will be prompted for the root password. Then fix whatever is broken:

```bash
systemctl --failed
journalctl -xb
vi /etc/fstab
systemctl daemon-reload
reboot
```

**You should see** a root password prompt, then a minimal shell. `systemctl default` continues the boot to the normal target without a reboot.

### 9. Kernel arguments worth knowing

| Argument | Effect |
| --- | --- |
| **`enforcing=0`** | Boot with SELinux permissive. Use when SELinux is blocking login |
| `selinux=0` | Disable SELinux entirely. Requires a relabel to re-enable |
| `rd.break` | Shell in the initramfs before switching root |
| `init=/bin/bash` | Replace init with a shell |
| `systemd.unit=X` | Boot to a specific target |
| `single`, `s`, `1` | Rescue mode |
| **`rw`** | Mount root read-write |
| `ro` | Mount root read-only (the default) |
| `nomodeset` | Skip KMS, for graphics problems |
| `systemd.debug-shell=1` | A root shell on tty9 |

**You should see** these as one-boot-only changes when typed at the GRUB menu. They are not written to disk.

### 10. Recovering from a broken `/etc/fstab`

This is the involuntary version, and it is the most likely way you will break your own exam machine.

**What you see:**

```text
[FAILED] Failed to mount /mnt/data.
[DEPEND] Dependency failed for Local File Systems.
You are in emergency mode. After logging in, type "journalctl -xb" to view
system logs, "systemctl reboot" to reboot, or "exit" to continue bootup.

Give root password for maintenance:
```

**The recovery:**

```bash
# 1. Log in with the root password

# 2. Find the offending entry
journalctl -xb | grep -i mount
systemctl --failed
cat /etc/fstab

# 3. ROOT IS READ-ONLY. Remount it writable first.
mount -o remount,rw /

# 4. Fix or comment out the bad line
vi /etc/fstab

# 5. VERIFY before rebooting
findmnt --verify
mount -a

# 6. Reload the generated mount units, then reboot
systemctl daemon-reload
reboot
```

**Step 3 is the step people miss**, and without it `vi` cannot save the file. If you find yourself unable to write, that is why.

**Prevention is much better than recovery:**

```bash
sudo cp /etc/fstab{,.bak}          # before editing
sudo findmnt --verify              # after editing
sudo mount -a && echo OK           # after editing
```

And use `nofail` for anything optional or removable:

```text
/dev/sr0  /mnt/iso  iso9660  ro,nofail  0 0
UUID=...  /mnt/data  xfs     defaults,nofail  0 0
```

`nofail` means a failed mount does not block the boot. Using it on a mount the grader checks is risky — the mount must still work — but on an ISO or a USB device it is correct practice.

**You should see** `findmnt --verify` report no errors and `mount -a` run silently before you reboot.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

Do all of these from a **VM console**. Take a snapshot first.

**Task 1.** Make the GRUB menu wait 10 seconds so you have time to interrupt it, and remove the graphical boot splash so you can see boot messages.

> Hint: edit `/etc/default/grub`, then regenerate `grub.cfg`. See `17-bootloader.md`.

**Task 2.** Reset the root password on `server1` using `rd.break`, including the SELinux relabel step. Verify you can log in afterwards.

> Hint: the six commands in order — `mount`, `chroot`, `passwd`, `touch`, `exit`, `exit`.

**Task 3.** Reset the root password using `init=/bin/bash` instead, and exit cleanly.

> Hint: append `rw init=/bin/bash` at GRUB; no chroot needed; use `exec /sbin/init` to hand over to systemd.

**Task 4.** Boot the system directly into `rescue.target` from the GRUB menu.

> Hint: append `systemd.unit=rescue.target` to the linux line.

**Task 5.** Boot the system with SELinux in permissive mode for one boot only, without changing any file.

> Hint: append `enforcing=0` at GRUB; check with `getenforce` after login.

**Task 6.** Deliberately break `/etc/fstab` with a nonexistent device, reboot, and recover from emergency mode.

> Hint: add a fake `/dev/sdzz` line, reboot, then `mount -o remount,rw /` before editing.

**Task 7.** Explain what happens if you reset the root password with `rd.break` but forget `touch /.autorelabel`, and how you would recover.

> Hint: SELinux context on `/etc/shadow`; boot with `enforcing=0`, then `restorecon`.

**Task 8.** Explain what happens if you forget `chroot /sysroot`, and how you would notice.

> Hint: `passwd` edits the initramfs copy; check `ls /sysroot/etc/shadow` before exiting.

**Task 9.** After an unexplained boot failure, find out from the logs what failed, using the previous boot's journal.

> Hint: `journalctl --list-boots`, then `-b -1`. Needs a persistent journal.

**Task 10.** Add `nofail` to an optional mount so a missing device cannot prevent the system booting, and prove it works by removing the device.

> Hint: add an ISO mount with `ro,nofail`; detach the ISO and reboot.

---

## Solutions

**Task 1.**

```bash
sudo cp /etc/default/grub{,.bak}
sudo vi /etc/default/grub
```

Set:

```text
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE=menu
GRUB_CMDLINE_LINUX="crashkernel=1G-4G:192M,4G-64G:256M resume=/dev/mapper/rhel-swap rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap"
```

Remove `rhgb quiet` from `GRUB_CMDLINE_LINUX` if present. `rhgb` is the graphical boot splash and `quiet` suppresses kernel messages; without them you can see what the boot is doing, which is what you want while practising.

Regenerate:

```bash
# BIOS
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# UEFI
sudo grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg

# Or, version-agnostic and safest:
sudo grub2-mkconfig -o "$(sudo find /boot -name grub.cfg | head -1)"
```

To determine which you are on:

```bash
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
```

Reboot and confirm the menu waits 10 seconds. Full detail in `17-bootloader.md`.

**Task 2.**

```text
sudo reboot

# At the GRUB menu:
e                                    edit the highlighted entry
                                     navigate to the line starting 'linux'
Ctrl+e  (or End)                     jump to the end of that line
 rd.break                            type a space then rd.break
Ctrl+x                               boot
```

At the `switch_root:/#` prompt:

```bash
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
# type the new password twice
touch /.autorelabel
exit
exit
```

The system relabels (a progress display appears) and reboots itself. Log in as root with the new password.

Verify afterwards:

```bash
sudo ls -Z /etc/shadow            # context should be shadow_t
getenforce                        # Enforcing
sudo ls /.autorelabel             # should NOT exist; the relabel removed it
```

Confirm the context is right:

```bash
ls -Z /etc/shadow
# system_u:object_r:shadow_t:s0 /etc/shadow
```

If that shows something else, the relabel did not happen. Run `sudo restorecon -v /etc/shadow`.

**Task 3.**

```text
At GRUB: e
On the linux line, append:  rw init=/bin/bash
Ctrl+x
```

At the bash prompt:

```bash
# no chroot needed: / IS the real root filesystem
mount | grep ' / '                # confirm rw
passwd root
touch /.autorelabel

# hand over to systemd for a normal boot
exec /sbin/init
```

If `exec /sbin/init` misbehaves:

```bash
sync
mount -o remount,ro /
reboot -f
```

**`rw` is essential.** Without it, `passwd` reports a read-only filesystem. And **`reboot` alone will not work** here because systemd is not running as PID 1 — you must force it or hand over with `exec`.

**Task 4.**

```text
At GRUB: e
Append:  systemd.unit=rescue.target
Ctrl+x
```

Enter the root password when prompted. You get a root shell with local filesystems mounted and almost no services.

```bash
systemctl list-units --type=service --state=running    # very short list
findmnt                                                # filesystems mounted
systemctl default                                      # continue to the default target
```

`systemctl default` continues the boot to the normal target without a reboot, which is quicker than rebooting.

**Task 5.**

```text
At GRUB: e
Append:  enforcing=0
Ctrl+x
```

After logging in:

```bash
getenforce            # Permissive
sestatus
```

**This changes no file.** The next boot returns to enforcing because `/etc/selinux/config` is untouched. That is exactly what you want when SELinux is preventing login and you need to get in to fix a context.

Contrast with the persistent version:

```bash
sudo setenforce 0                                                    # now only
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config  # persistent
```

See `27-selinux.md`.

**Task 6.**

Break it:

```bash
echo "/dev/sdzz  /mnt/broken  xfs  defaults  0 0" | sudo tee -a /etc/fstab
sudo reboot
```

You land in emergency mode:

```text
You are in emergency mode...
Give root password for maintenance:
```

Recover:

```bash
# log in as root

journalctl -xb | grep -i -A5 'failed to mount'
systemctl --failed

# root is READ-ONLY
mount -o remount,rw /

vi /etc/fstab                    # delete or comment the /dev/sdzz line

findmnt --verify                 # must be clean
mount -a                         # must be silent
systemctl daemon-reload
reboot
```

Then confirm you are back:

```bash
systemctl --failed
findmnt
```

**Do this once in the lab.** It is a five-minute exercise that removes the panic from a situation that otherwise costs candidates an entire machine.

Note `systemctl daemon-reload`: systemd generates `.mount` units from `/etc/fstab` at boot, so after editing the file you should reload so the generated units match. `mount -a` handles the immediate mounting; `daemon-reload` keeps systemd's view consistent.

**Task 7.**

**What happens:** the new password hash is written to `/etc/shadow` from inside the initramfs, where SELinux is not enforcing. The file ends up with an incorrect security context — typically `unlabeled_t` instead of `shadow_t`. On the next boot SELinux is enforcing, so the authentication stack **cannot read `/etc/shadow`**. Login fails with "incorrect password" even though the password is right. You appear to be locked out again, and the symptom is misleading because it looks like the password reset did not work.

**Recovery:**

```text
At GRUB: e
Append:  enforcing=0
Ctrl+x
```

Now SELinux is permissive, so login works. Then fix the context:

```bash
sudo restorecon -v /etc/shadow
ls -Z /etc/shadow          # should now be shadow_t
sudo reboot                # verify with SELinux enforcing again
```

Or relabel everything, which is slower but certain:

```bash
sudo touch /.autorelabel
sudo reboot
```

**Task 8.**

**What happens:** `passwd root` succeeds and reports "all authentication tokens updated successfully" — but it has edited the initramfs's own in-memory `/etc/shadow`, not your system's. The initramfs is discarded when the boot continues, so the change evaporates.

**How you notice:** the boot completes normally, you try the new password, and it does not work. Nothing warned you.

**Detection before rebooting:** while still at the `switch_root:#` prompt, check where you are:

```bash
ls /sysroot/etc/shadow     # if this path exists, you are NOT chrooted
pwd
```

If `/sysroot` still exists as a directory containing `etc`, you have not chrooted. After a successful `chroot /sysroot`, the real system is at `/` and there is no `/sysroot` inside it.

**The lesson:** run the six commands in order, every time, without improvising. `mount`, `chroot`, `passwd`, `touch`, `exit`, `exit`.

**Task 9.**

```bash
journalctl --list-boots
journalctl -b -1 -p err
journalctl -b -1 -xe
journalctl -b -1 | grep -i -E 'fail|error|dependency'
```

**This requires a persistent journal.** If `journalctl --list-boots` shows only one entry, the journal is memory-backed and the previous boot's log is gone. Fix that now, before you need it:

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
journalctl --list-boots
```

See `18-logs-journald.md`. Making the journal persistent is itself a plausible exam task, and it makes every subsequent troubleshooting task easier.

**Task 10.**

```bash
sudo mkdir -p /mnt/iso
echo '/dev/sr0  /mnt/iso  iso9660  ro,nofail  0 0' | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo mount -a
```

Now detach the ISO from the VM and reboot:

```bash
sudo reboot
```

The system boots normally. Confirm:

```bash
systemctl --failed            # nothing failed fatally
findmnt /mnt/iso              # not mounted, and that is fine
```

Without `nofail`, the same situation drops you into emergency mode. Compare by removing it:

```bash
sudo sed -i 's|ro,nofail|ro|' /etc/fstab
sudo reboot                   # now it fails to boot
```

**Use `nofail` for removable and optional devices.** Do not use it as a way to hide a mount that the grader expects to be working — the mount must still succeed, `nofail` only stops a *missing device* from blocking the boot.

---

## Verify

```bash
# After a password reset
ls -Z /etc/shadow                  # shadow_t
getenforce                         # Enforcing
ls /.autorelabel 2>/dev/null       # should not exist
su - root                          # new password works

# After an fstab recovery
sudo findmnt --verify
sudo mount -a && echo OK
systemctl --failed
grep -vE '^\s*#|^\s*$' /etc/fstab

# GRUB settings
grep -E 'TIMEOUT|CMDLINE' /etc/default/grub
```

## Persistence Check

| Change | Persists? |
| --- | :---: |
| A kernel argument typed at the GRUB menu | **No** — this boot only, by design |
| The new root password | **Yes** — written to `/etc/shadow` |
| `touch /.autorelabel` | Consumed by the next boot, then deleted |
| `/etc/default/grub` edits | **Yes**, but only after `grub2-mkconfig` |
| An `/etc/fstab` fix | **Yes** |
| `enforcing=0` at GRUB | **No** — one boot only |

**The temporary nature of GRUB edits is a feature.** You do not want a recovery argument baked into the boot configuration. If a task asks you to add a **permanent** kernel argument, that is `/etc/default/grub` plus `grub2-mkconfig`, or `grubby`. See `17-bootloader.md`.

After any recovery, verify with a **normal reboot** that the system is genuinely fixed and not just working because of a temporary kernel argument.

## Quick Reference

Come back here when you need a command you forgot — not before your first pass through Follow Along.

### The three ways in

| Method | Use when | Reboots needed |
| --- | --- | :---: |
| **`rd.break`** | **Forgot the root password.** The standard RHEL answer | 2 |
| `init=/bin/bash` | `rd.break` is unavailable or you need the real root filesystem | 2 |
| `systemd.unit=rescue.target` | You know the root password but a service or target is broken | 1 |

Also relevant: emergency mode, which you land in involuntarily when `/etc/fstab` is broken.

### GRUB menu

```text
┌──────────────────────────────────────────────────────┐
│  Red Hat Enterprise Linux (5.14.0-...) 10.0          │  <- highlight this
│  Red Hat Enterprise Linux (0-rescue-...) 10.0        │
│                                                      │
│   Use the ↑ and ↓ keys to change the selection.      │
│   Press 'e' to edit the selected item, or 'c' for a  │
│   command prompt.                                    │
└──────────────────────────────────────────────────────┘
```

- **`e`** — edit the selected entry. This is what you want.
- `c` — a GRUB command prompt.
- `Esc` — back to the menu.

If the menu flashes past too fast, hold **`Shift`** during boot (BIOS) or press **`Esc`** repeatedly (UEFI).

Inside the editor, find the line beginning **`linux`** (older systems: `linux16` or `linuxefi`):

```text
linux ($root)/vmlinuz-5.14.0-... root=/dev/mapper/rhel-root ro crashkernel=1G-4G:192M ...
```

Append your argument to **the end of that line**, then boot with **`Ctrl+x`**.

**`Ctrl+x` boots. `Ctrl+c` gives a GRUB prompt. `Esc` discards your edit.**

Edits made here are **temporary** — they apply to this boot only and are not written to disk.

### Method 1: rd.break — The Standard Answer

```text
1. Reboot. At the GRUB menu, press 'e'
2. Find the line starting with 'linux'
3. Go to the END of that line (Ctrl+e, or End)
4. Append:  rd.break
   Optionally also remove 'rhgb quiet' so you can see what happens
5. Press Ctrl+x to boot
```

At `switch_root:/#`:

```bash
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
exit
exit
```

Condensed card:

```text
GRUB -> e -> append rd.break -> Ctrl+x

mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
exit
exit
```

**Why each step matters:**

- **`mount -o remount,rw /sysroot`** — without this, `passwd` fails on read-only.
- **`chroot /sysroot`** — without this, `passwd` edits the initramfs copy and the change evaporates.
- **`touch /.autorelabel`** — without this, SELinux blocks login even with the correct password.

**If you forget `/.autorelabel`:** boot with `enforcing=0`, then `restorecon -v /etc/shadow`.

### Method 2: init=/bin/bash

```text
At GRUB: press 'e', append to the linux line:

  rw init=/bin/bash

Ctrl+x
```

```bash
passwd root
touch /.autorelabel
exec /sbin/init
# or: mount -o remount,ro / && reboot -f
```

### Method 3: Booting To A Different Target

```text
At GRUB, press 'e' and append one of:

  systemd.unit=rescue.target       minimal services, filesystems mounted
  systemd.unit=emergency.target    only /, read-only
  systemd.unit=multi-user.target   skip a broken graphical target
  single                           equivalent to rescue

Ctrl+x
```

```bash
systemctl --failed
journalctl -xb
vi /etc/fstab
systemctl daemon-reload
reboot
```

### Kernel arguments

| Argument | Effect |
| --- | --- |
| **`enforcing=0`** | Boot with SELinux permissive. Use when SELinux is blocking login |
| `selinux=0` | Disable SELinux entirely. Requires a relabel to re-enable |
| `rd.break` | Shell in the initramfs before switching root |
| `init=/bin/bash` | Replace init with a shell |
| `systemd.unit=X` | Boot to a specific target |
| `single`, `s`, `1` | Rescue mode |
| **`rw`** | Mount root read-write |
| `ro` | Mount root read-only (the default) |
| `nomodeset` | Skip KMS, for graphics problems |
| `systemd.debug-shell=1` | A root shell on tty9 |

### Recovering From A Broken /etc/fstab

```text
[FAILED] Failed to mount /mnt/data.
You are in emergency mode...
Give root password for maintenance:
```

```bash
journalctl -xb | grep -i mount
systemctl --failed
cat /etc/fstab
mount -o remount,rw /
vi /etc/fstab
findmnt --verify
mount -a
systemctl daemon-reload
reboot
```

**Prevention:**

```bash
sudo cp /etc/fstab{,.bak}
sudo findmnt --verify
sudo mount -a && echo OK
```

```text
/dev/sr0  /mnt/iso  iso9660  ro,nofail  0 0
UUID=...  /mnt/data  xfs     defaults,nofail  0 0
```

## Exam Tips

- **The six commands, in order:** `mount -o remount,rw /sysroot`, `chroot /sysroot`, `passwd root`, `touch /.autorelabel`, `exit`, `exit`. Drill them.
- **`e` at GRUB to edit, `Ctrl+x` to boot.** `Esc` discards. Do not lose time on this.
- **Append to the line starting `linux`.** Not `initrd`, not `insmod`.
- **`rd.break` puts your real system at `/sysroot`, mounted read-only.**
- **Forgetting `remount,rw`** means `passwd` fails on a read-only filesystem.
- **Forgetting `chroot /sysroot`** means `passwd` silently edits the wrong file and appears to succeed.
- **Forgetting `/.autorelabel`** leaves `/etc/shadow` with a bad SELinux context, and **login fails even with the right password.** Recover by booting with `enforcing=0` and running `restorecon -v /etc/shadow`.
- **`init=/bin/bash` needs `rw`**, gives you the real root at `/` with no chroot, and needs `exec /sbin/init` or a forced reboot to exit.
- **`systemd.unit=rescue.target`** when you know the root password but the system will not come up. `systemctl default` continues the boot.
- **`enforcing=0`** for one permissive boot without touching any file.
- **A bad `/etc/fstab` drops you into emergency mode.** First command: **`mount -o remount,rw /`**.
- **Always `findmnt --verify` and `mount -a` before rebooting.** This one habit prevents the worst failure mode on the exam.
- **`nofail`** for optional or removable mounts.
- Remove **`rhgb quiet`** while practising so you can see boot messages.
- Make the **journal persistent** (`/var/log/journal`) so `journalctl -b -1` works when you need it.
- **Practise on a snapshot, from a console, before exam day.** This task is fast if rehearsed and catastrophic if not.
