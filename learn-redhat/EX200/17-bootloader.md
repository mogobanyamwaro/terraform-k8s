# 17. Modifying The System Bootloader

**Objective:** Modify the system bootloader.

GRUB is the gatekeeper between firmware and the kernel. On the exam, "modify the bootloader" means editing `/etc/default/grub` or using `grubby`, then regenerating the config — not hand-editing `grub.cfg`. Knowing the difference between a one-boot GRUB edit and a permanent change is what separates a correct answer from one that looks right but does nothing.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Editing `/etc/default/grub` without running `grub2-mkconfig` is the classic trap. The file looks correct; the boot menu does not change.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Which files you edit versus which are generated

```text
/etc/default/grub                     <- YOU EDIT THIS
/etc/grub.d/                          <- scripts that generate the config
      ├── 00_header
      ├── 10_linux
      └── 40_custom                   <- for hand-written menu entries

/boot/grub2/grub.cfg                  <- GENERATED. BIOS systems. DO NOT EDIT
/boot/efi/EFI/redhat/grub.cfg         <- GENERATED. UEFI systems. DO NOT EDIT
/boot/loader/entries/*.conf           <- BLS entries, one per kernel (RHEL 8+)
/etc/grub2.cfg                        -> symlink to the real grub.cfg
/etc/grub2-efi.cfg                    -> symlink, UEFI
```

**The rule: edit `/etc/default/grub`, then regenerate `grub.cfg`.** Editing `grub.cfg` directly works until the next kernel update regenerates it and discards your change.

**You should see** `/etc/default/grub` as the only file you edit by hand for most tasks.

### 2. Determine BIOS versus UEFI

```bash
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
```

Then locate the config:

```bash
sudo find /boot -name grub.cfg
readlink -f /etc/grub2.cfg        # BIOS
readlink -f /etc/grub2-efi.cfg    # UEFI
```

**You should see** either `UEFI` or `BIOS`, and a path like `/boot/grub2/grub.cfg` or `/boot/efi/EFI/redhat/grub.cfg`.

Determine your firmware type first, because it decides the output path for `grub2-mkconfig`.

### 3. Regenerate the GRUB configuration

```bash
# BIOS
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# UEFI
sudo grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
```

If you are unsure, this works on either:

```bash
sudo grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg)"
```

**You should see** output like:

```text
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.14.0-427.el9.x86_64
Found initrd image: /boot/initramfs-5.14.0-427.el9.x86_64.img
done
```

**Forgetting `grub2-mkconfig` is the classic failure.** You edit `/etc/default/grub`, reboot, and nothing changed — because `grub.cfg` still holds the old values.

### 4. Read `/etc/default/grub`

```bash
cat /etc/default/grub
```

**You should see** settings like:

```text
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=1G-4G:192M rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
GRUB_ENABLE_BLSCFG=true
```

The ones that appear in tasks:

| Setting | Effect |
| --- | --- |
| **`GRUB_TIMEOUT`** | Seconds the menu waits. `0` hides it, `-1` waits forever |
| `GRUB_TIMEOUT_STYLE` | `menu` shows it, `hidden` or `countdown` do not |
| **`GRUB_CMDLINE_LINUX`** | **Kernel arguments appended to every entry** |
| `GRUB_DEFAULT` | `saved`, or an index like `0`, or an entry title |
| `GRUB_DISABLE_SUBMENU` | `true` flattens the menu |
| `GRUB_TERMINAL_OUTPUT` | `console`, or `serial` for a serial console |
| `GRUB_ENABLE_BLSCFG` | `true` uses BootLoaderSpec entries in `/boot/loader/entries/` |

Two arguments worth removing while you practise: **`rhgb`** (the graphical boot splash) and **`quiet`** (suppresses kernel messages). Without them you can see what the boot is actually doing, which makes `16-boot-interrupt-root-recovery.md` far easier.

### 5. Change the menu timeout permanently

```bash
sudo cp /etc/default/grub{,.bak}
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub
grep GRUB_TIMEOUT /etc/default/grub
sudo grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg)"
sudo grep -m1 'set timeout' "$(readlink -f /etc/grub2.cfg)"
```

**You should see** `GRUB_TIMEOUT=10` in `/etc/default/grub` and `set timeout=10` in the generated `grub.cfg`.

**Both steps are required.** Editing `/etc/default/grub` without regenerating changes nothing at boot.

Also ensure the menu is actually displayed:

```bash
grep GRUB_TIMEOUT_STYLE /etc/default/grub      # should be 'menu', not 'hidden'
```

### 6. Use `grubby` for kernel arguments

`grubby` edits the generated entries directly and correctly, without a full regeneration. On RHEL 8 and later with BLS enabled, this is often the preferred tool.

```bash
sudo grubby --info=ALL                          # every boot entry
sudo grubby --default-kernel                    # which kernel boots by default
sudo grubby --default-index
sudo grubby --info=DEFAULT                      # details of the default entry
```

Add or remove arguments:

```bash
# Add an argument to ALL entries
sudo grubby --update-kernel=ALL --args="audit=1"

# Remove an argument
sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"

sudo grubby --info=ALL | grep args
```

**You should see** the argument appear in every entry's `args=` line.

**`grubby --update-kernel=ALL --args="..."` is the fast, reliable way to add a persistent kernel argument.** It writes to `/boot/loader/entries/*.conf` and does not need `grub2-mkconfig`.

There is one caveat: `grubby` changes existing entries, but a **new kernel installed later** inherits its arguments from `GRUB_CMDLINE_LINUX` in `/etc/default/grub`. So for a change that must apply to future kernels too, do both:

```bash
sudo grubby --update-kernel=ALL --args="audit=1"
sudo sed -i 's/^GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 audit=1"/' /etc/default/grub
```

For the exam, `grubby --update-kernel=ALL` plus an edit to `/etc/default/grub` covers you either way.

### 7. Kernels and boot entries

```bash
rpm -q kernel
uname -r
ls /boot/vmlinuz-*
ls /boot/loader/entries/
sudo grubby --info=ALL | grep -E 'index|kernel|title'
```

**You should see** `rpm -q kernel` listing installed packages, `uname -r` showing what is running now, and `grubby --default-kernel` showing what will boot next time. Those three can legitimately differ — for example just after a kernel update, before you reboot.

RHEL keeps the last 3 kernels by default:

```bash
grep installonly /etc/dnf/dnf.conf
# installonly_limit=3
```

Change the default boot entry:

```bash
sudo grubby --default-index                   # note the current value
sudo grubby --set-default-index=1
sudo grubby --default-kernel                  # confirm it changed
sudo grubby --set-default-index=0             # change it back
```

You can also set it by kernel path, which is clearer and less fragile than an index:

```bash
sudo grubby --set-default=/boot/vmlinuz-$(uname -r)
```

### 8. Verify kernel arguments after reboot

The authoritative check is what the running kernel actually received:

```bash
cat /proc/cmdline
cat /proc/cmdline | tr ' ' '\n' | grep audit
```

Compare with what is configured:

```bash
sudo grubby --info=DEFAULT
```

**You should see** `/proc/cmdline` and `grubby --info=DEFAULT` agree. If `/proc/cmdline` lacks the argument but `grubby --info` shows it, you edited a non-default entry or forgot to regenerate.

### 9. Set and remove a GRUB password

Occasionally asked, since an unprotected GRUB menu means anyone with console access can reset the root password via `16-boot-interrupt-root-recovery.md`.

```bash
sudo grub2-setpassword
sudo ls -l /boot/grub2/user.cfg
sudo cat /boot/grub2/user.cfg
```

**You should see** something like:

```text
GRUB2_PASSWORD=grub.pbkdf2.sha512.10000.XXXX...
```

The password is stored as a PBKDF2 hash, not plaintext. Reboot and try pressing `e` at the menu — it now demands the username `root` and this password.

**This is the countermeasure to the root password reset in `16-boot-interrupt-root-recovery.md`.** With a GRUB password set, someone with console access can still boot the existing entries but cannot add `rd.break`.

Remove it in your lab when done:

```bash
sudo rm -f /boot/grub2/user.cfg
```

Do remove it in your lab, or you will be entering it every time you practise `16-boot-interrupt-root-recovery.md`.

### 10. Reinstall GRUB and recover a lost `grub.cfg`

If the bootloader itself is damaged, for example after a disk clone or an MBR overwrite:

```bash
# BIOS: install to the disk's MBR, not a partition
sudo grub2-install /dev/vda
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

**On BIOS, install to the whole disk (`/dev/vda`), not a partition (`/dev/vda1`).** The boot code goes in the MBR.

On UEFI there is no MBR stage; the firmware loads `shim` and `grubx64.efi` from the EFI System Partition:

```bash
sudo dnf reinstall grub2-efi-x64 shim-x64
sudo grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
sudo efibootmgr -v
```

Recovering a lost `grub.cfg` from a running system:

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

That regenerates it entirely from `/etc/default/grub`, `/etc/grub.d/`, and the installed kernels. Nothing needs to be preserved.

**You should see** `done` from `grub2-mkconfig`. `grub.cfg` holds nothing precious — it can be rebuilt at any time.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Determine whether this system boots via BIOS or UEFI, and identify the correct `grub.cfg` path.

> Hint: `[ -d /sys/firmware/efi ]` and `find /boot -name grub.cfg`.

**Task 2.** Change the GRUB menu timeout to 10 seconds and make the change permanent.

> Hint: edit `GRUB_TIMEOUT` in `/etc/default/grub`, then `grub2-mkconfig`.

**Task 3.** Remove the `rhgb` and `quiet` kernel arguments so boot messages are visible, applying the change to all existing boot entries and to future kernels.

> Hint: `grubby --remove-args` for existing entries; edit `GRUB_CMDLINE_LINUX` for future kernels.

**Task 4.** Add the kernel argument `audit=1` permanently to all boot entries.

> Hint: `grubby --update-kernel=ALL --args="audit=1"` plus `/etc/default/grub`.

**Task 5.** Verify that a kernel argument you added is actually in effect after a reboot.

> Hint: `cat /proc/cmdline` is the authoritative answer.

**Task 6.** List every installed kernel and identify which one boots by default.

> Hint: `rpm -q kernel`, `uname -r`, and `grubby --default-kernel`.

**Task 7.** Change the default boot entry to the second entry in the list, then change it back.

> Hint: `grubby --set-default-index=1`, then set it back to `0`.

**Task 8.** Show the full details of every GRUB boot entry.

> Hint: `grubby --info=ALL`, or read `/boot/loader/entries/*.conf` directly.

**Task 9.** Set a GRUB bootloader password, verify the file it created, and then remove it.

> Hint: `grub2-setpassword` writes `/boot/grub2/user.cfg`.

**Task 10.** Regenerate the GRUB configuration from scratch and confirm the new file contains your settings.

> Hint: `grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg)"`, then grep the output file.

**Task 11.** Reinstall the GRUB bootloader to the primary disk on a BIOS system.

> Hint: `grub2-install /dev/vda` — the whole disk, not a partition.

**Task 12.** Determine how many old kernels the system is configured to retain.

> Hint: `installonly_limit` in `/etc/dnf/dnf.conf`.

**Task 13.** Add the kernel argument `systemd.unit=multi-user.target` permanently, then explain why `systemctl set-default` is the better way to achieve the same result.

> Hint: compare where each change lives and whether new kernels inherit it.

---

## Solutions

**Task 1.**

```bash
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
```

Then locate the config:

```bash
sudo find /boot -name grub.cfg
readlink -f /etc/grub2.cfg        # BIOS
readlink -f /etc/grub2-efi.cfg    # UEFI
```

| Firmware | grub.cfg path |
| --- | --- |
| BIOS | `/boot/grub2/grub.cfg` |
| UEFI | `/boot/efi/EFI/redhat/grub.cfg` |

On Rocky or AlmaLinux the UEFI path uses the distribution name, for example `/boot/efi/EFI/rocky/grub.cfg`. That is why `find` or the `/etc/grub2*.cfg` symlinks are more reliable than typing the path from memory.

**Task 2.**

```bash
sudo cp /etc/default/grub{,.bak}
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub
grep GRUB_TIMEOUT /etc/default/grub
```

Regenerate:

```bash
sudo grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg)"
```

Verify the generated file picked it up:

```bash
sudo grep -m1 'set timeout' /boot/grub2/grub.cfg
# set timeout=10
```

**Both steps are required.** Editing `/etc/default/grub` without regenerating changes nothing at boot. Confirming the value landed in `grub.cfg` is the proof.

Also ensure the menu is actually displayed:

```bash
grep GRUB_TIMEOUT_STYLE /etc/default/grub      # should be 'menu', not 'hidden'
```

**Task 3.**

Two changes: existing entries, and the template for future kernels.

```bash
# existing entries
sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"

# future kernels
sudo cp /etc/default/grub{,.bak}
sudo sed -i 's/ rhgb//; s/ quiet//' /etc/default/grub
grep GRUB_CMDLINE_LINUX /etc/default/grub
sudo grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg)"
```

Verify:

```bash
sudo grubby --info=ALL | grep args
```

Reboot and you will see kernel and systemd messages scroll past instead of a splash. That visibility is worth having permanently in your lab.

**Task 4.**

```bash
sudo grubby --update-kernel=ALL --args="audit=1"
sudo grubby --info=ALL | grep args
```

And for future kernels:

```bash
sudo sed -i 's/^GRUB_CMDLINE_LINUX="\(.*\)"$/GRUB_CMDLINE_LINUX="\1 audit=1"/' /etc/default/grub
grep GRUB_CMDLINE_LINUX /etc/default/grub
sudo grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg)"
```

Check you have not accidentally added it twice:

```bash
grep -o 'audit=1' /etc/default/grub | wc -l      # should be 1
```

**Task 5.**

```bash
sudo reboot
```

After the reboot:

```bash
cat /proc/cmdline
```

That file shows **exactly** the arguments the running kernel received. It is the authoritative answer to "is my kernel argument in effect".

```bash
cat /proc/cmdline | tr ' ' '\n' | grep audit
```

Compare with what is configured:

```bash
sudo grubby --info=DEFAULT
```

If `/proc/cmdline` lacks the argument but `grubby --info` shows it, you edited a non-default entry or forgot to regenerate.

**Task 6.**

```bash
rpm -q kernel
uname -r
sudo grubby --default-kernel
sudo grubby --default-index
ls /boot/loader/entries/
```

`rpm -q kernel` lists installed kernel packages, `uname -r` is what is running now, and `grubby --default-kernel` is what will boot next time. Those three can legitimately differ — for example just after a kernel update, before you reboot.

**Task 7.**

```bash
sudo grubby --default-index                   # note the current value, e.g. 0
sudo grubby --info=ALL | grep -E '^index|^title'

sudo grubby --set-default-index=1
sudo grubby --default-kernel                  # confirm it changed
```

Change it back:

```bash
sudo grubby --set-default-index=0
sudo grubby --default-kernel
```

You can also set it by kernel path, which is clearer and less fragile than an index:

```bash
sudo grubby --set-default=/boot/vmlinuz-$(uname -r)
```

`GRUB_DEFAULT=saved` in `/etc/default/grub` makes GRUB remember the last successful choice, which is why `grubby --set-default` works persistently.

**Task 8.**

```bash
sudo grubby --info=ALL
```

Each entry shows:

```text
index=0
kernel="/boot/vmlinuz-5.14.0-427.el9.x86_64"
args="ro crashkernel=1G-4G:192M rd.lvm.lv=rhel/root audit=1"
root="/dev/mapper/rhel-root"
initrd="/boot/initramfs-5.14.0-427.el9.x86_64.img"
title="Red Hat Enterprise Linux (5.14.0-427.el9.x86_64) 9.4 (Plow)"
id="..."
```

Also readable directly:

```bash
sudo cat /boot/loader/entries/*.conf
```

Those BLS files are what `grubby` edits on RHEL 8+.

**Task 9.**

```bash
sudo grub2-setpassword
# Enter password:
# Confirm password:

sudo ls -l /boot/grub2/user.cfg
sudo cat /boot/grub2/user.cfg
```

```text
GRUB2_PASSWORD=grub.pbkdf2.sha512.10000.XXXX...
```

The password is stored as a PBKDF2 hash, not plaintext. Reboot and try pressing `e` at the menu — it now demands the username `root` and this password.

**This is the countermeasure to the root password reset in `16-boot-interrupt-root-recovery.md`.** With a GRUB password set, someone with console access can still boot the existing entries but cannot add `rd.break`.

Remove it:

```bash
sudo rm -f /boot/grub2/user.cfg
```

Do remove it in your lab, or you will be entering it every time you practise `16-boot-interrupt-root-recovery.md`.

**Task 10.**

```bash
sudo cp /boot/grub2/grub.cfg{,.bak}
sudo grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg)"
sudo grep -E 'set timeout|linux.*vmlinuz' /boot/grub2/grub.cfg | head
diff /boot/grub2/grub.cfg.bak /boot/grub2/grub.cfg
```

`grub2-mkconfig` rebuilds the file entirely from `/etc/default/grub`, the scripts in `/etc/grub.d/`, and the kernels present in `/boot`. Nothing in `grub.cfg` is precious, which is why hand-editing it is pointless.

Note that `grub2-mkconfig` prints its progress to stderr, so a normal run looks noisy:

```text
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.14.0-427.el9.x86_64
Found initrd image: /boot/initramfs-5.14.0-427.el9.x86_64.img
done
```

`done` is what you want to see.

**Task 11.**

```bash
lsblk                                       # identify the whole disk
sudo grub2-install /dev/vda
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

**Target the disk, not a partition.** `/dev/vda` is right; `/dev/vda1` is wrong, because the boot code goes in the MBR at the start of the disk.

On UEFI, `grub2-install` is not the mechanism. Instead:

```bash
sudo dnf reinstall -y grub2-efi-x64 shim-x64
sudo grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
sudo efibootmgr -v                          # inspect the firmware boot entries
```

If you attempt `grub2-install` on a UEFI system, modern RHEL warns you and declines, which is a helpful safety net.

**Task 12.**

```bash
grep installonly /etc/dnf/dnf.conf
```

```text
installonly_limit=3
```

Three kernels are retained; installing a fourth removes the oldest. To change it:

```bash
sudo sed -i 's/^installonly_limit=.*/installonly_limit=2/' /etc/dnf/dnf.conf
```

To clean up manually:

```bash
rpm -q kernel
sudo dnf remove kernel-5.14.0-70.el9
```

You cannot remove the running kernel. Check with `uname -r` first.

**Task 13.**

The literal answer:

```bash
sudo grubby --update-kernel=ALL --args="systemd.unit=multi-user.target"
sudo grubby --info=DEFAULT | grep args
```

**But this is the wrong tool for the job**, and knowing why matters more than the command.

| | `set-default` | A kernel argument |
| --- | --- | --- |
| Where it lives | A symlink in `/etc/systemd/system/` | The bootloader configuration |
| Applies to | Every boot | Only entries you updated |
| New kernels | Inherited automatically | **Not inherited** unless `/etc/default/grub` is also edited |
| Overridable at boot | Yes, by adding an argument at GRUB | Already an argument; harder to reason about |
| Reversible | `systemctl set-default X` | Requires editing the bootloader again |
| Risk | Low | You can hard-code a broken target into every entry |

So the correct answer to "the system should boot into multi-user.target" is:

```bash
sudo systemctl set-default multi-user.target
```

Remove the kernel argument you added:

```bash
sudo grubby --update-kernel=ALL --remove-args="systemd.unit=multi-user.target"
sudo grubby --info=DEFAULT | grep args
```

**Read task wording carefully.** "Modify the bootloader" means GRUB. "Boot into a specific target" means `systemctl set-default`. Two different objectives that people conflate. See `15-systemd-targets-boot.md`.

---

## Verify

```bash
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
grep -E 'GRUB_TIMEOUT|GRUB_CMDLINE' /etc/default/grub
sudo grep -m1 'set timeout' "$(readlink -f /etc/grub2.cfg)"
sudo grubby --info=DEFAULT
cat /proc/cmdline
sudo grubby --default-kernel
rpm -q kernel
ls /boot/loader/entries/
```

## Persistence Check

| Change | Persistent artifact | Requires |
| --- | --- | --- |
| `/etc/default/grub` edit | The file itself | **`grub2-mkconfig`** to take effect |
| `grubby --update-kernel=ALL` | `/boot/loader/entries/*.conf` | Nothing further |
| An argument typed at the GRUB menu | **None** | It is one boot only, by design |
| `grub2-setpassword` | `/boot/grub2/user.cfg` | Nothing further |
| `grubby --set-default` | GRUB environment / BLS | `GRUB_DEFAULT=saved` |

The trap is specific to this file: **`/etc/default/grub` is not read at boot.** `grub.cfg` is. Editing the former without regenerating the latter produces a file that looks correct and has no effect. This is exactly the kind of mistake the grader catches.

After the reboot, the authoritative check is:

```bash
cat /proc/cmdline
```

That is what the kernel actually received. If your argument is not there, the change did not take.

```bash
sudo grubby --info=DEFAULT       # what is configured
cat /proc/cmdline                # what is running
```

Those two agreeing is the definition of done.

## Quick Reference

Come back here when you need a command you forgot — not before your first pass through Follow Along.

### The files, and which one you edit

```text
/etc/default/grub                     <- YOU EDIT THIS
/etc/grub.d/                          <- scripts that generate the config
      ├── 00_header
      ├── 10_linux
      └── 40_custom                   <- for hand-written menu entries

/boot/grub2/grub.cfg                  <- GENERATED. BIOS systems. DO NOT EDIT
/boot/efi/EFI/redhat/grub.cfg         <- GENERATED. UEFI systems. DO NOT EDIT
/boot/loader/entries/*.conf           <- BLS entries, one per kernel (RHEL 8+)
/etc/grub2.cfg                        -> symlink to the real grub.cfg
/etc/grub2-efi.cfg                    -> symlink, UEFI
```

**The rule: edit `/etc/default/grub`, then regenerate `grub.cfg`.** Editing `grub.cfg` directly works until the next kernel update regenerates it and discards your change.

```bash
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
```

### Regenerating the configuration

```bash
# BIOS
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# UEFI
sudo grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg

# Either firmware:
sudo grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg)"
sudo find /boot -name grub.cfg
```

**Forgetting `grub2-mkconfig` is the classic failure.**

### /etc/default/grub settings

```bash
cat /etc/default/grub
```

| Setting | Effect |
| --- | --- |
| **`GRUB_TIMEOUT`** | Seconds the menu waits. `0` hides it, `-1` waits forever |
| `GRUB_TIMEOUT_STYLE` | `menu` shows it, `hidden` or `countdown` do not |
| **`GRUB_CMDLINE_LINUX`** | **Kernel arguments appended to every entry** |
| `GRUB_DEFAULT` | `saved`, or an index like `0`, or an entry title |
| `GRUB_DISABLE_SUBMENU` | `true` flattens the menu |
| `GRUB_TERMINAL_OUTPUT` | `console`, or `serial` for a serial console |
| `GRUB_ENABLE_BLSCFG` | `true` uses BootLoaderSpec entries in `/boot/loader/entries/` |

Remove **`rhgb`** and **`quiet`** while practising.

### grubby: the safer way to change kernel arguments

```bash
sudo grubby --info=ALL
sudo grubby --default-kernel
sudo grubby --default-index
sudo grubby --info=DEFAULT

sudo grubby --update-kernel=ALL --args="quiet"
sudo grubby --update-kernel=DEFAULT --args="audit=1"
sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"

sudo grubby --set-default=/boot/vmlinuz-5.14.0-427.el9.x86_64
sudo grubby --set-default-index=1
```

**`grubby --update-kernel=ALL --args="..."` is the fast, reliable way to add a persistent kernel argument.**

For full coverage on future kernels too:

```bash
sudo grubby --update-kernel=ALL --args="audit=1"
sudo sed -i 's/^GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 audit=1"/' /etc/default/grub
```

### Kernels and boot entries

```bash
rpm -q kernel
uname -r
ls /boot/vmlinuz-*
ls /boot/loader/entries/
sudo grubby --info=ALL | grep -E 'index|kernel|title'

sudo dnf install kernel
sudo dnf remove kernel-5.14.0-70.el9
```

```bash
grep installonly /etc/dnf/dnf.conf
# installonly_limit=3
```

### Reinstalling GRUB

```bash
# BIOS
sudo grub2-install /dev/vda
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# UEFI
sudo dnf reinstall grub2-efi-x64 shim-x64
sudo grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
sudo efibootmgr -v
```

**On BIOS, install to the whole disk (`/dev/vda`), not a partition (`/dev/vda1`).**

### Setting a GRUB password

```bash
sudo grub2-setpassword
sudo cat /boot/grub2/user.cfg          # GRUB2_PASSWORD=grub.pbkdf2...
sudo rm -f /boot/grub2/user.cfg        # remove
```

### Recovering a lost grub.cfg

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### Authoritative verification

```bash
cat /proc/cmdline
sudo grubby --info=DEFAULT
```

## Exam Tips

- **Edit `/etc/default/grub`, then run `grub2-mkconfig`.** Never edit `grub.cfg` directly; a kernel update overwrites it.
- **BIOS output: `/boot/grub2/grub.cfg`. UEFI output: `/boot/efi/EFI/<distro>/grub.cfg`.** Determine which with `[ -d /sys/firmware/efi ]`.
- **`grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg)"`** works regardless of firmware type and avoids typing the wrong path.
- **`grubby --update-kernel=ALL --args="..."`** is the fast way to add a persistent kernel argument. **`--remove-args`** to take one away.
- **`grubby` changes existing entries; `/etc/default/grub` governs future kernels.** For full coverage, do both.
- **`cat /proc/cmdline`** after a reboot is the authoritative proof that an argument is in effect.
- **`GRUB_TIMEOUT`** controls the menu delay; **`GRUB_TIMEOUT_STYLE=menu`** ensures it is shown at all.
- **Remove `rhgb quiet`** to see boot messages. Do this in your lab permanently.
- **`grubby --info=ALL`** lists every entry. **`--default-kernel`** and **`--set-default`** manage which boots.
- **BIOS `grub2-install /dev/vda`** — the whole disk, never a partition. On UEFI, reinstall `grub2-efi-x64` and `shim-x64` instead.
- **`grub2-setpassword`** writes `/boot/grub2/user.cfg` and blocks GRUB menu editing — the countermeasure to `16-boot-interrupt-root-recovery.md`.
- **`installonly_limit=3`** in `/etc/dnf/dnf.conf` controls how many kernels are kept.
- **"Modify the bootloader" means GRUB. "Boot into a target" means `systemctl set-default`.** Do not use a kernel argument for the latter.
- `grub.cfg` holds nothing precious — `grub2-mkconfig` rebuilds it completely at any time.
