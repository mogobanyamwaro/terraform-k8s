# 15. systemd Targets, Booting, And Shutdown

**Objectives:** Boot, reboot, and shut down a system normally. Boot systems into different targets manually. Configure systems to boot into a specific target automatically. Log in and switch users in multiuser targets.

These objectives cover how a RHEL system starts, stops, and switches between run states. You will use `systemctl` for almost everything — but the exam also expects you to know when `shutdown` still matters, what happens during the boot sequence, and the difference between `rescue.target` and `emergency.target`.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Targets look like runlevels with different names until you try `isolate rescue.target` over SSH and lose your session. Do that once from a console instead.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Targets replaced runlevels

A **target** is a named group of units that systemd brings up together. It plays the role SysV runlevels used to play, but targets can depend on each other and there is no single "current runlevel" number.

| Target | Old runlevel | Purpose |
| --- | --- | --- |
| `poweroff.target` | 0 | Halt and power off |
| **`rescue.target`** | **1, s, single** | **Single-user, minimal services, root shell.** Filesystems mounted |
| `multi-user.target` | 2, 3, 4 | **Full multi-user, networking, no GUI. The server default** |
| **`graphical.target`** | **5** | multi-user plus a display manager |
| `reboot.target` | 6 | Reboot |
| **`emergency.target`** | — | **Most minimal. Root filesystem mounted READ-ONLY, almost nothing else** |

The dependency chain, simplified:

```text
                                         graphical.target
                                                │ requires
                                         multi-user.target
                                                │ requires
                                           basic.target
                                                │ requires
                                          sysinit.target
                                            │        │
                                    local-fs.target  swap.target
```

Because `graphical.target` requires `multi-user.target`, everything in multi-user also runs in graphical.

**You should see** the table above as your mental map. On the exam, old runlevel numbers still appear in task wording — know the mapping.

### 2. Query the default boot target

```bash
systemctl get-default
```

**You should see** `multi-user.target` on a server install, or `graphical.target` if a desktop environment is installed.

This is the target the system will reach on the **next reboot**. It does not change what is running right now.

### 3. Set the default target persistently

```bash
sudo systemctl set-default multi-user.target
systemctl get-default
```

**You should see** output like:

```text
Removed /etc/systemd/system/default.target.
Created symlink /etc/systemd/system/default.target → /usr/lib/systemd/system/multi-user.target.
```

**`set-default` is persistent.** A task saying "the system should boot into X" means `set-default`, not `isolate`.

To set graphical instead:

```bash
sudo systemctl set-default graphical.target
```

Switch back for now:

```bash
sudo systemctl set-default multi-user.target
```

### 4. See what `set-default` actually modifies

```bash
ls -l /etc/systemd/system/default.target
readlink -f /etc/systemd/system/default.target
```

**You should see** a symlink pointing at something like `/usr/lib/systemd/system/multi-user.target`.

That is all it is. `systemctl get-default` reads that link, and `set-default` rewrites it. Consistent with `05-hard-soft-links.md`.

### 5. Switch the running target immediately (`isolate`)

```bash
sudo systemctl isolate multi-user.target
systemctl list-units --type=target
```

**You should see** several active targets at once — `basic.target`, `multi-user.target`, `sysinit.target`, and others. **Several targets are active simultaneously**, unlike SysV runlevels where exactly one was current.

**`isolate` switches now but does not persist.** After a reboot the system returns to whatever `get-default` says.

To try rescue mode (from a **VM console only**, not SSH):

```bash
sudo systemctl isolate rescue.target
# ... explore ...
sudo systemctl isolate multi-user.target
```

**Do not `isolate rescue.target` over SSH.** It stops `sshd`, so your session is cut off and you cannot get back. Use `virsh console` or the VirtualBox window.

### 6. Shorthand reboot, poweroff, and shutdown

```bash
sudo systemctl reboot                # = isolate reboot.target
sudo systemctl poweroff              # = isolate poweroff.target
sudo systemctl halt                  # stop the CPU without powering off
sudo systemctl suspend
sudo systemctl hibernate
sudo systemctl rescue                # = isolate rescue.target
sudo systemctl emergency
```

Traditional equivalents, all of which still work and are symlinks to `systemctl`:

```bash
sudo reboot
sudo poweroff
sudo shutdown -h now                 # halt now
sudo shutdown -r now                 # reboot now
sudo shutdown -h +10                 # halt in 10 minutes
sudo shutdown -r 23:30               # reboot at 23:30
sudo shutdown -h +5 "Maintenance in 5 minutes"
sudo shutdown -c                     # CANCEL a scheduled shutdown
```

**You should see** that `reboot` and `poweroff` are symlinks:

```bash
ls -l /usr/sbin/reboot
```

`shutdown` with a delay writes a message to all logged-in users and creates `/run/nologin` to prevent new logins. `shutdown -c` cancels it. Those two facts are the reason `shutdown` still exists alongside `systemctl poweroff`.

### 7. List targets and their dependencies

```bash
systemctl list-units --type=target
systemctl list-units --type=target --all
systemctl list-dependencies multi-user.target
```

**You should see** a tree of units that `multi-user.target` pulls in. Expand it fully:

```bash
systemctl list-dependencies multi-user.target --all
```

The reverse view is often more useful — what target wants a given service:

```bash
systemctl list-dependencies --reverse httpd
```

**You should see** that `httpd` is wanted by `multi-user.target`, which is exactly what `systemctl enable` arranged.

### 8. The boot sequence — where things go wrong

Knowing the order tells you where to intervene when something fails.

```text
1. Firmware (BIOS or UEFI)          POST, select the boot device
2. Boot loader (GRUB2)              /boot/grub2/grub.cfg  (BIOS)
                                    /boot/efi/EFI/redhat/grub.cfg  (UEFI)
   └─ press 'e' here to edit kernel arguments  <-- your intervention point
3. Kernel + initramfs               kernel unpacks initramfs, finds the root fs
   └─ rd.break here drops you to a shell before switching root
4. systemd (PID 1)                  reads default.target
5. sysinit.target                   mount local filesystems, activate swap, start udev
   └─ a bad /etc/fstab fails HERE  -> emergency.target
6. basic.target                     sockets, timers, paths
7. multi-user.target                all your enabled services
8. graphical.target                 display manager, if applicable
9. Login prompt
```

Where things go wrong, mapped to the fix:

| Symptom | Stage | Fix in |
| --- | --- | --- |
| No boot menu, no kernel | 2 | `17-bootloader.md` — reinstall GRUB |
| Forgot the root password | 3 | `16-boot-interrupt-root-recovery.md` — `rd.break` |
| "Cannot open root device" | 3 | `16-boot-interrupt-root-recovery.md` — wrong `root=` argument |
| Drops to emergency mode | 5 | **A broken `/etc/fstab`.** `16-boot-interrupt-root-recovery.md` |
| Boots but a service is dead | 7 | `14-systemd-services.md` — `systemctl --failed` |
| Boots to a text prompt when a GUI was wanted | 4 | `set-default graphical.target` |

**You should see** stage 5 as the fstab failure point. That is why emergency mode exists.

### 9. Inspect boot time

```bash
systemd-analyze
systemd-analyze blame | head -5
systemd-analyze critical-chain
```

**You should see** total boot time split into kernel, initrd, and userspace phases. Example:

```text
Startup finished in 1.234s (kernel) + 2.567s (initrd) + 8.901s (userspace) = 12.702s
multi-user.target reached after 8.756s in userspace
```

`blame` sorts by duration regardless of whether anything waited for the unit. `critical-chain` follows the dependency path that determined the total — for "why is my boot slow", `critical-chain` is the better answer.

### 10. Check failed units and boot logs

```bash
systemctl --failed
journalctl -b
journalctl -b -1
journalctl --list-boots
journalctl -p err -b
who -b
uptime -s
```

**You should see** `systemctl --failed` as the first command after any reboot — it shows units that did not start.

`-b` is this boot's log; `-b -1` is the previous boot. **This only works if the journal is persistent** (see `18-logs-journald.md`). If `journalctl --list-boots` shows only the current boot, the journal is memory-backed in `/run/log/journal` and previous boots are gone.

### 11. Multiuser login and switching users

The "log in and switch users in multiuser targets" objective:

```bash
who
w
tty
loginctl list-sessions
loginctl session-status 3
loginctl user-status alice
su - alice
sudo -i
exit
```

**You should see** `who` giving user, terminal, and login time. `w` adds load average and what each user is running. `loginctl list-sessions` is systemd's view, with session IDs you can act on.

To forcibly end a session:

```bash
sudo loginctl terminate-session 3
sudo loginctl terminate-user alice
```

`loginctl` is systemd's session manager and is the modern way to see and end sessions. `who` and `w` remain the quick answers.

Virtual consoles on physical or VM console: **Ctrl+Alt+F2 .. F6**.

### 12. `rescue` versus `emergency`

| | `rescue.target` | `emergency.target` |
| --- | --- | --- |
| Filesystems | All local filesystems **mounted** | **Only `/`, and read-only** |
| Services | Minimal set started | Essentially none |
| Use for | A broken service, a forgotten password | **A broken `/etc/fstab`** |
| To write files | Already writable | `mount -o remount,rw /` first |

**You should see** that a bad entry in `/etc/fstab` lands you in **`emergency.target`**, because mounting local filesystems happens during `sysinit.target`, before rescue mode's prerequisites are satisfied.

If you break `/etc/fstab` and the boot fails, you land in emergency mode, and the first thing you must do is remount root read-write. That is the single most valuable fact in this file. See `16-boot-interrupt-root-recovery.md`.

The recovery sequence, which is worth memorising:

```bash
# 1. Root is read-only, so you cannot edit anything yet
mount -o remount,rw /

# 2. Fix the offending line
vi /etc/fstab

# 3. Verify BEFORE rebooting
findmnt --verify
mount -a

# 4. Reload the generated mount units and reboot
systemctl daemon-reload
reboot
```

**Step 1 is the one people forget.** Without the remount, `vi` cannot save and you are stuck.

### 13. Broadcasting to users

```bash
wall "System going down in 10 minutes"
echo "message" | wall
sudo shutdown -r +10 "Rebooting for maintenance"
sudo shutdown -c
```

**You should see** the scheduled shutdown message on all logged-in terminals. Cancel with `shutdown -c` before the timer fires.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Determine the current default boot target.

> Hint: one `systemctl` subcommand, no `sudo`.

**Task 2.** Configure the system to boot into the text-based multi-user target by default, and confirm the change without rebooting.

> Hint: `set-default` for persistence; `get-default` to confirm.

**Task 3.** Show what file `systemctl set-default` actually modifies, and its current value.

> Hint: `ls -l` and `readlink -f` on the symlink under `/etc/systemd/system/`.

**Task 4.** Switch the running system to `rescue.target` without rebooting, then return to `multi-user.target`.

> Hint: `isolate`, from a **console** — not SSH. Return the same way.

**Task 5.** List every target currently active.

> Hint: `list-units` with `--type=target`.

**Task 6.** Show all units that `multi-user.target` pulls in.

> Hint: `list-dependencies`. Add `--all` to expand the full tree.

**Task 7.** Schedule a reboot for 10 minutes from now with a warning message to all users, then cancel it.

> Hint: `shutdown -r +10 "message"`, then `shutdown -c`.

**Task 8.** Reboot the system immediately using two different commands.

> Hint: `systemctl reboot` and one traditional equivalent.

**Task 9.** Determine how long the last boot took, broken down into kernel and userspace time.

> Hint: `systemd-analyze` with no arguments.

**Task 10.** Identify the three slowest units during the last boot.

> Hint: `systemd-analyze blame`, piped to `head`.

**Task 11.** Show the log from the previous boot, filtered to errors only.

> Hint: `journalctl -b -1 -p err`. Needs a persistent journal.

**Task 12.** Determine when the system last booted, using two different commands.

> Hint: `who -b` and `uptime -s`.

**Task 13.** Show all currently logged-in users and their sessions, using both traditional and systemd tools.

> Hint: `who`/`w` plus `loginctl list-sessions`.

**Task 14.** Forcibly end user `alice`'s login session.

> Hint: find her session ID with `loginctl list-sessions`, then `terminate-session` or `terminate-user`.

**Task 15.** Explain the practical difference between `rescue.target` and `emergency.target`, and state which one you would land in if `/etc/fstab` contained a bad entry.

> Hint: compare filesystem mount state and which stage of boot fails.

**Task 16.** Configure the system to boot into the graphical target, then revert it to multi-user.

> Hint: two `set-default` calls and `get-default` after each.

---

## Solutions

**Task 1.**

```bash
systemctl get-default
```

Typically `multi-user.target` on a server install, `graphical.target` if a desktop is installed.

**Task 2.**

```bash
sudo systemctl set-default multi-user.target
systemctl get-default
```

```text
Removed /etc/systemd/system/default.target.
Created symlink /etc/systemd/system/default.target → /usr/lib/systemd/system/multi-user.target.
```

The output tells you exactly what happened: a symlink was replaced. **This is persistent** — it is the answer to "the system should boot without a graphical interface".

To also switch immediately, without rebooting:

```bash
sudo systemctl isolate multi-user.target
```

**Task 3.**

```bash
ls -l /etc/systemd/system/default.target
readlink -f /etc/systemd/system/default.target
```

```text
lrwxrwxrwx. 1 root root 41 Aug 18 18:00 /etc/systemd/system/default.target
  -> /usr/lib/systemd/system/multi-user.target
```

`set-default` writes this symlink and nothing else. You could create it by hand:

```bash
sudo ln -sf /usr/lib/systemd/system/multi-user.target /etc/systemd/system/default.target
```

Use `set-default` on the exam — it is shorter and cannot be misspelled — but knowing the mechanism means you can verify and repair it.

**Task 4.**

```bash
sudo systemctl isolate rescue.target
```

You are dropped to a root prompt with most services stopped. Look around:

```bash
systemctl list-units --type=service --state=running    # very few
findmnt                                                # filesystems ARE mounted
systemctl is-active sshd                               # inactive
```

Return:

```bash
sudo systemctl isolate multi-user.target
systemctl is-active sshd                               # active again
```

**Do this from a VM console, not over SSH.** `isolate rescue.target` stops `sshd`, so an SSH session is cut off and you cannot get back. Use `virsh console` or the VirtualBox window.

**`isolate` is temporary.** After a reboot the system returns to whatever `get-default` says. Only `set-default` changes that.

**Task 5.**

```bash
systemctl list-units --type=target
```

You should see `basic.target`, `multi-user.target`, `sysinit.target`, `local-fs.target`, `sockets.target`, `timers.target`, `swap.target`, and others. Note that **several targets are active at once** — this is the key difference from SysV runlevels, where exactly one was current.

Add `--all` to include inactive targets.

**Task 6.**

```bash
systemctl list-dependencies multi-user.target
```

A tree. Expand it fully:

```bash
systemctl list-dependencies multi-user.target --all
```

And the reverse, which is often more useful:

```bash
systemctl list-dependencies --reverse httpd
```

That shows `httpd` is wanted by `multi-user.target`, which is exactly what `systemctl enable` arranged.

**Task 7.**

```bash
sudo shutdown -r +10 "Rebooting for maintenance"
```

All logged-in terminals receive the broadcast. Check what is scheduled:

```bash
ls -l /run/systemd/shutdown/scheduled 2>/dev/null
cat /run/nologin 2>/dev/null
```

Cancel it:

```bash
sudo shutdown -c
```

**`shutdown -c` is the cancel.** Two things `shutdown` with a delay does that `systemctl reboot` does not: it broadcasts a warning, and it creates `/run/nologin` to block new logins. That is why the old command still exists.

Time formats: `+10` for minutes from now, `23:30` for an absolute time, `now` for immediately.

**Task 8.**

```bash
sudo systemctl reboot
```

or

```bash
sudo reboot
sudo shutdown -r now
sudo systemctl isolate reboot.target
```

All equivalent. `reboot` and `poweroff` are symlinks to `systemctl`:

```bash
ls -l /usr/sbin/reboot
```

**Task 9.**

```bash
systemd-analyze
```

```text
Startup finished in 1.234s (kernel) + 2.567s (initrd) + 8.901s (userspace) = 12.702s
multi-user.target reached after 8.756s in userspace
```

The three phases are the kernel, the initramfs, and userspace (systemd starting your services). Userspace is usually the bulk and is where your own changes show up.

**Task 10.**

```bash
systemd-analyze blame | head -3
```

Then check whether those units actually mattered:

```bash
systemd-analyze critical-chain
```

`blame` sorts by duration regardless of whether anything waited for the unit. `critical-chain` follows the dependency path that determined the total, so a slow unit that nothing blocks on will not appear. For "why is my boot slow", `critical-chain` is the better answer.

**Task 11.**

```bash
journalctl -b -1 -p err
```

`-b -1` is the previous boot, `-b -2` the one before that. List what is available:

```bash
journalctl --list-boots
```

**This only works if the journal is persistent.** By default RHEL stores the journal in `/run/log/journal`, which is memory-backed and cleared on reboot, so `-b -1` returns nothing. Making it persistent is a task in `18-logs-journald.md`:

```bash
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
```

If `journalctl --list-boots` shows only the current boot, that is why.

**Task 12.**

```bash
who -b
uptime -s
```

```text
         system boot  2026-08-18 15:30
2026-08-18 15:30:12
```

Also:

```bash
uptime
last reboot | head -5
journalctl --list-boots
```

**Task 13.**

```bash
who
w
loginctl list-sessions
```

`who` gives user, terminal, and login time. `w` adds load average and what each user is running. `loginctl list-sessions` is systemd's view, with session IDs you can act on:

```bash
loginctl session-status 3
loginctl user-status alice
```

`loginctl` is the one that lets you do something about a session, which is Task 14.

**Task 14.**

```bash
loginctl list-sessions                  # find alice's session ID
sudo loginctl terminate-session 5
```

Or terminate every session she has:

```bash
sudo loginctl terminate-user alice
```

The blunter, pre-systemd approach also works:

```bash
sudo pkill -u alice
sudo pkill -9 -u alice
```

`loginctl terminate-user` is cleaner because it tears down the session properly rather than killing processes out from under the session manager. You need this before `userdel` if the user is logged in.

**Task 15.**

| | `rescue.target` | `emergency.target` |
| --- | --- | --- |
| Root filesystem | Mounted **read-write** | Mounted **READ-ONLY** |
| Other local filesystems | Mounted | **Not mounted** |
| Services | A minimal set | Essentially none |
| Networking | No | No |
| Shell | Root shell after the root password | Root shell after the root password |
| Typical cause of arriving here | You asked for it, or a service failure | **A failure mounting filesystems** |

**A bad entry in `/etc/fstab` lands you in `emergency.target`**, because mounting local filesystems happens during `sysinit.target`, before rescue mode's prerequisites are satisfied.

The recovery sequence, which is worth memorising:

```bash
# 1. Root is read-only, so you cannot edit anything yet
mount -o remount,rw /

# 2. Fix the offending line
vi /etc/fstab

# 3. Verify BEFORE rebooting
findmnt --verify
mount -a

# 4. Reload the generated mount units and reboot
systemctl daemon-reload
reboot
```

**Step 1 is the one people forget.** Without the remount, `vi` cannot save and you are stuck. This is why `Persistence.md` insists on `mount -a` before every reboot: a `nofail` option or a two-second check avoids this entire situation.

Practise it deliberately:

```bash
echo "/dev/sdzz /mnt/broken xfs defaults 0 0" | sudo tee -a /etc/fstab
sudo reboot          # you will land in emergency mode. Recover using the steps above.
```

Do that once in the lab, from a VM console, and the real thing will not frighten you.

**Task 16.**

```bash
sudo systemctl set-default graphical.target
systemctl get-default
```

Note that if no display manager is installed, the system reaches `graphical.target` but shows a text login anyway, because `graphical.target` requires `multi-user.target` and adds `display-manager.service` — which does not exist on a minimal install.

```bash
systemctl status display-manager 2>&1 | head -3
```

Revert:

```bash
sudo systemctl set-default multi-user.target
systemctl get-default
```

---

## Verify

```bash
systemctl get-default
ls -l /etc/systemd/system/default.target
systemctl list-units --type=target
systemd-analyze
systemctl --failed
journalctl --list-boots
who -b; uptime -s
loginctl list-sessions
```

## Persistence Check

| Action | Survives reboot? |
| --- | :---: |
| **`systemctl set-default X`** | **Yes** — rewrites `/etc/systemd/system/default.target` |
| `systemctl isolate X` | **No** — reverts to the default target |
| `shutdown -r +10` | Not applicable; cancel with `shutdown -c` |
| A `.wants` symlink from `enable` | **Yes** |

The check after reboot:

```bash
systemctl get-default                # the target you set
systemctl --failed                   # nothing broken
findmnt                              # every required mount present
journalctl -p err -b                 # errors this boot
```

**The persistence risk in this file is `/etc/fstab`.** A change that seems unrelated to targets can prevent the system reaching any target at all. Before every reboot:

```bash
sudo findmnt --verify
sudo mount -a && echo OK || echo "DO NOT REBOOT"
```

## Quick Reference

Come back here when you need a command you forgot — not before your first pass through Follow Along.

### Targets replaced runlevels

| Target | Old runlevel | Purpose |
| --- | --- | --- |
| `poweroff.target` | 0 | Halt and power off |
| **`rescue.target`** | **1, s, single** | **Single-user, minimal services, root shell.** Filesystems mounted |
| `multi-user.target` | 2, 3, 4 | **Full multi-user, networking, no GUI. The server default** |
| **`graphical.target`** | **5** | multi-user plus a display manager |
| `reboot.target` | 6 | Reboot |
| **`emergency.target`** | — | **Most minimal. Root filesystem mounted READ-ONLY, almost nothing else** |

```text
                                         graphical.target
                                                │ requires
                                         multi-user.target
                                                │ requires
                                           basic.target
                                                │ requires
                                          sysinit.target
                                            │        │
                                    local-fs.target  swap.target
```

**`rescue` versus `emergency`:**

| | `rescue.target` | `emergency.target` |
| --- | --- | --- |
| Filesystems | All local filesystems **mounted** | **Only `/`, and read-only** |
| Services | Minimal set started | Essentially none |
| Use for | A broken service, a forgotten password | **A broken `/etc/fstab`** |
| To write files | Already writable | `mount -o remount,rw /` first |

### Querying and changing targets

```bash
systemctl get-default                       # the boot target
sudo systemctl set-default multi-user.target
sudo systemctl set-default graphical.target

systemctl list-units --type=target          # active targets
systemctl list-units --type=target --all
systemctl list-dependencies multi-user.target

systemctl isolate multi-user.target         # switch NOW, without rebooting
systemctl isolate graphical.target
sudo systemctl isolate rescue.target
sudo systemctl isolate emergency.target
```

**`set-default` is persistent; `isolate` is immediate and temporary.** A task saying "the system should boot into X" means `set-default`. A task saying "switch the system to X now" means `isolate`.

```bash
ls -l /etc/systemd/system/default.target
# -> /usr/lib/systemd/system/multi-user.target
```

### Shorthand commands

```bash
sudo systemctl reboot                # = isolate reboot.target
sudo systemctl poweroff              # = isolate poweroff.target
sudo systemctl halt                  # stop the CPU without powering off
sudo systemctl suspend
sudo systemctl hibernate
sudo systemctl rescue                # = isolate rescue.target
sudo systemctl emergency
```

```bash
sudo reboot
sudo poweroff
sudo shutdown -h now                 # halt now
sudo shutdown -r now                 # reboot now
sudo shutdown -h +10                 # halt in 10 minutes
sudo shutdown -r 23:30               # reboot at 23:30
sudo shutdown -h +5 "Maintenance in 5 minutes"
sudo shutdown -c                     # CANCEL a scheduled shutdown
```

### The boot sequence

```text
1. Firmware (BIOS or UEFI)          POST, select the boot device
2. Boot loader (GRUB2)              /boot/grub2/grub.cfg  (BIOS)
                                    /boot/efi/EFI/redhat/grub.cfg  (UEFI)
   └─ press 'e' here to edit kernel arguments  <-- your intervention point
3. Kernel + initramfs               kernel unpacks initramfs, finds the root fs
   └─ rd.break here drops you to a shell before switching root
4. systemd (PID 1)                  reads default.target
5. sysinit.target                   mount local filesystems, activate swap, start udev
   └─ a bad /etc/fstab fails HERE  -> emergency.target
6. basic.target                     sockets, timers, paths
7. multi-user.target                all your enabled services
8. graphical.target                 display manager, if applicable
9. Login prompt
```

| Symptom | Stage | Fix in |
| --- | --- | --- |
| No boot menu, no kernel | 2 | `17-bootloader.md` — reinstall GRUB |
| Forgot the root password | 3 | `16-boot-interrupt-root-recovery.md` — `rd.break` |
| "Cannot open root device" | 3 | `16-boot-interrupt-root-recovery.md` — wrong `root=` argument |
| Drops to emergency mode | 5 | **A broken `/etc/fstab`.** `16-boot-interrupt-root-recovery.md` |
| Boots but a service is dead | 7 | `14-systemd-services.md` — `systemctl --failed` |
| Boots to a text prompt when a GUI was wanted | 4 | `set-default graphical.target` |

### Inspecting the boot

```bash
systemd-analyze                       # total boot time, split kernel/initrd/userspace
systemd-analyze blame                 # slowest units
systemd-analyze critical-chain        # what actually delayed the boot
systemctl --failed                    # what did not start
journalctl -b                         # this boot's log
journalctl -b -1                      # the PREVIOUS boot
journalctl --list-boots               # every recorded boot
journalctl -p err -b                  # errors this boot
who -b                                # last boot time
uptime -s                             # boot timestamp
```

### Multiuser login and switching users

```bash
# Virtual consoles: Ctrl+Alt+F2 .. F6 on physical or VM console
who                          # who is logged in and on which terminal
w                            # plus what they are doing
tty                          # which terminal am I on
loginctl list-sessions       # systemd's view of sessions
loginctl session-status 3
loginctl user-status alice
sudo loginctl terminate-session 3
sudo loginctl terminate-user alice

su - alice                   # login shell as alice
sudo -i                      # root login shell
exit                         # or Ctrl+d
```

### Broadcasting to users

```bash
wall "System going down in 10 minutes"
echo "message" | wall
sudo shutdown -r +10 "Rebooting for maintenance"
```

## Exam Tips

- **`systemctl get-default` / `set-default`.** `set-default` is persistent and is what "boot into X" means.
- **`systemctl isolate X` switches now but does not persist.** "Switch the system to X" means isolate; "boot into X" means set-default.
- **`multi-user.target` is text mode; `graphical.target` adds a display manager.** graphical requires multi-user.
- **`default.target` is just a symlink** in `/etc/systemd/system/`. That is the whole mechanism.
- **`rescue.target`: filesystems mounted, minimal services. `emergency.target`: only `/`, and READ-ONLY.**
- **A broken `/etc/fstab` drops you into emergency mode.** First command there is **`mount -o remount,rw /`**.
- Old runlevels map as: **0 poweroff, 1 rescue, 3 multi-user, 5 graphical, 6 reboot.**
- **`shutdown -h +10 "msg"`** warns users and blocks new logins; **`shutdown -c`** cancels.
- `reboot`, `poweroff`, and `shutdown` are all symlinks to `systemctl`.
- **`systemctl --failed`** is the first command after any reboot.
- **`journalctl -b -1`** needs a **persistent journal** (`/var/log/journal`), or there is no previous boot to show. See `18-logs-journald.md`.
- **`systemd-analyze blame`** for slow units; **`critical-chain`** for what actually delayed the boot.
- **`who`, `w`, `loginctl list-sessions`** to see logins. **`loginctl terminate-user alice`** to end them.
- **Do not `isolate rescue.target` over SSH.** It stops sshd and disconnects you. Use the console.
- **`who -b`** and **`uptime -s`** give the last boot time.
- Practise breaking `/etc/fstab` and recovering from emergency mode **once** in the lab. It converts a potential disaster into a two-minute fix.
