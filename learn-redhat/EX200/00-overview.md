# EX200 — Red Hat Certified System Administrator ([RHCSA](https://chatgpt.com/c/6a8f4724-6a20-83ea-ac2f-4a74e3f32cbf))

This folder mirrors the flat layout of `learn-kubernetes/kubernetes` (CKA), `kubernetes-security`, and `prometheus`, but the content targets **EX200**.

Objectives checked against the Red Hat EX200 exam page on 2026-08-18.

## Read This First: EX200 Is Not Like PCA

|                | PCA             | EX200 (RHCSA)                                                                     |
| -------------- | --------------- | --------------------------------------------------------------------------------- |
| Format         | Multiple choice | **Performance-based. You do real work on a real system**                          |
| Questions      | 60              | ~15-20 tasks                                                                      |
| Duration       | 90 minutes      | **3 hours**                                                                       |
| Passing        | 75%             | **210 of 300 (70%)** — widely reported, Red Hat does not publish it               |
| Docs allowed   | None            | **`man`, `info`, and `/usr/share/doc` on the exam system.** No internet, no notes |
| Graded by      | An answer key   | **A script that inspects the machine after a reboot**                             |
| Partial credit | Per question    | Per task, and many tasks are all-or-nothing                                       |

**The single most important sentence on the official exam page:**

> As with all Red Hat performance-based exams, configurations must persist after reboot without intervention.

The grader reboots your machine. Anything you did that only lived in RAM is worth zero. A mount that is not in `/etc/fstab`, a service you started but did not enable, a firewall rule you did not make permanent, an IP you set with `ip addr add` — all score nothing even though they worked when you left them.

Read `Persistence.md` before you do anything else. It is the checklist that separates a pass from a fail.

## Exam Version: RHEL 10

The current EX200 is based on **Red Hat Enterprise Linux 10**. This matters:

| Area                 | RHEL 9 era              | RHEL 10                                                                                 |
| -------------------- | ----------------------- | --------------------------------------------------------------------------------------- |
| Software management  | `dnf` / `rpm` only      | `dnf` / `rpm` **plus Flatpak**                                                          |
| Scheduling           | `cron`, `at`            | `cron`, `at`, **systemd timers explicitly listed**                                      |
| Default network tool | `nmcli`                 | `nmcli`, with keyfiles in `/etc/NetworkManager/system-connections/` as the only backend |
| `ifcfg` files        | Deprecated but readable | **Gone.** Keyfile format only                                                           |

**Two things to verify yourself before you book:**

1. **Whether containers are still graded.** The RHEL 9 objectives had a "Manage containers" domain covering `podman`. Reports on the RHEL 10 blueprint conflict, and Red Hat restructured its certification program in May 2026. This folder **covers Podman anyway** (`34-podman-images-running.md`, `35-containers-systemd.md`, `Podman.md`) because the cost of knowing it is low and the cost of being surprised is a fail. If the live objectives page does not list containers, deprioritise those three files.
2. **Which RHEL version your exam is booked against.** RHEL 9 sessions may still be available. Everything here works on both unless a file says otherwise; RHEL 9 differences are called out inline.

Every command here also works on **Rocky Linux**, **AlmaLinux**, and **CentOS Stream**, which is what you will most likely build your lab from. See `Lab-Setup.md`.

## Objective Domains And File Map

Red Hat does not publish per-domain weights for EX200. The task counts below are my estimate from the objective list and reported exam experiences, and they are there to guide your time, not to be quoted as fact.

| Domain                                                      |       Rough share | Files                                                                               |
| ----------------------------------------------------------- | ----------------: | ----------------------------------------------------------------------------------- |
| Understand and use essential tools                          |              ~15% | `01-shell-fundamentals.md` - `09-ssh.md`                                            |
| Manage users and groups                                     |              ~10% | `10-users-groups.md` - `12-special-permissions-acls.md`                             |
| Operate running systems                                     |              ~20% | `13-processes.md` - `20-tuned-profiles.md`                                          |
| Deploy, configure, and maintain systems                     |              ~12% | `21-time-chrony.md` - `23-flatpak.md`                                               |
| Manage basic networking                                     |              ~10% | `24-network-nmcli.md` - `26-firewalld.md`                                           |
| Manage security (SELinux, firewall, SSH keys, umask)        |              ~13% | `26-firewalld.md`, `27-selinux.md`, `09-ssh.md`, `06-standard-permissions-umask.md` |
| Configure local storage + create and configure file systems |              ~15% | `28-disks-partitions.md` - `32-nfs-autofs.md`                                       |
| Create simple shell scripts                                 |               ~5% | `33-shell-scripting.md`                                                             |
| Manage containers                                           | ~0-10%, see above | `34-podman-images-running.md`, `35-containers-systemd.md`                           |

### Official study points, mapped to files

**Understand and use essential tools**

| Objective                                                                            | File                                               |
| ------------------------------------------------------------------------------------ | -------------------------------------------------- |
| Access a shell prompt and issue commands with correct syntax                         | `01-shell-fundamentals.md`                         |
| Use input-output redirection (`>`, `>>`, `\|`, `2>`, etc.)                           | `02-redirection-pipes.md`                          |
| Use `grep` and regular expressions to analyze text                                   | `03-grep-regex.md`                                 |
| Access remote systems using SSH                                                      | `09-ssh.md`                                        |
| Log in and switch users in multiuser targets                                         | `10-users-groups.md`, `15-systemd-targets-boot.md` |
| Archive, compress, unpack, and uncompress files using `tar`, `gzip`, `bzip2`         | `04-archiving-compression.md`                      |
| Create and edit text files                                                           | `08-text-files.md`                                 |
| Create, delete, copy, and move files and directories                                 | `01-shell-fundamentals.md`                         |
| Create hard and soft links                                                           | `05-hard-soft-links.md`                            |
| List, set, and change standard `ugo/rwx` permissions                                 | `06-standard-permissions-umask.md`                 |
| Locate, read, and use system documentation including `man`, `info`, `/usr/share/doc` | `07-system-documentation.md`                       |

**Create simple shell scripts**

| Objective                                                              | File                                               |
| ---------------------------------------------------------------------- | -------------------------------------------------- |
| Conditionally execute code (`if`, `test`, `[]`)                        | `33-shell-scripting.md`                            |
| Use looping constructs (`for`) to process files and command line input | `33-shell-scripting.md`                            |
| Process script inputs (`$1`, `$2`)                                     | `33-shell-scripting.md`                            |
| Process output of shell commands within a script                       | `33-shell-scripting.md`, `02-redirection-pipes.md` |

**Operate running systems**

| Objective                                                       | File                                 |
| --------------------------------------------------------------- | ------------------------------------ |
| Boot, reboot, and shut down a system normally                   | `15-systemd-targets-boot.md`         |
| Boot systems into different targets manually                    | `15-systemd-targets-boot.md`         |
| Interrupt the boot process to gain access to a system           | `16-boot-interrupt-root-recovery.md` |
| Identify CPU and memory intensive processes, and kill processes | `13-processes.md`                    |
| Adjust process scheduling                                       | `13-processes.md`                    |
| Manage tuning profiles                                          | `20-tuned-profiles.md`               |
| Locate and interpret system log files and journals              | `18-logs-journald.md`                |
| Preserve system journals                                        | `18-logs-journald.md`                |
| Start, stop, and check the status of network services           | `14-systemd-services.md`             |
| Securely transfer files between systems                         | `09-ssh.md`                          |

**Configure local storage**

| Objective                                                        | File                                                |
| ---------------------------------------------------------------- | --------------------------------------------------- |
| List, create, delete partitions on MBR and GPT disks             | `28-disks-partitions.md`                            |
| Create and remove physical volumes                               | `29-lvm.md`                                         |
| Assign physical volumes to volume groups                         | `29-lvm.md`                                         |
| Create and delete logical volumes                                | `29-lvm.md`                                         |
| Configure systems to mount file systems at boot by UUID or label | `30-filesystems-fstab.md`                           |
| Add new partitions, logical volumes, and swap non-destructively  | `28-disks-partitions.md`, `29-lvm.md`, `31-swap.md` |

**Create and configure file systems**

| Objective                                                              | File                             |
| ---------------------------------------------------------------------- | -------------------------------- |
| Create, mount, unmount, and use `vfat`, `ext4`, and `xfs` file systems | `30-filesystems-fstab.md`        |
| Mount and unmount network file systems using NFS                       | `32-nfs-autofs.md`               |
| Configure `autofs`                                                     | `32-nfs-autofs.md`               |
| Extend existing logical volumes                                        | `29-lvm.md`                      |
| Create and configure set-GID directories for collaboration             | `12-special-permissions-acls.md` |
| Diagnose and correct file permission problems                          | `12-special-permissions-acls.md` |

**Deploy, configure, and maintain systems**

| Objective                                                                       | File                            |
| ------------------------------------------------------------------------------- | ------------------------------- |
| Schedule tasks using `at` and `cron`                                            | `19-scheduling-cron-at.md`      |
| Start and stop services, and configure services to start automatically at boot  | `14-systemd-services.md`        |
| Configure systems to boot into a specific target automatically                  | `15-systemd-targets-boot.md`    |
| Configure time service clients                                                  | `21-time-chrony.md`             |
| Install and update software packages from a repository or the local file system | `22-software-management-dnf.md` |
| Configure Flatpak repositories and manage Flatpak packages                      | `23-flatpak.md`                 |
| Modify the system bootloader                                                    | `17-bootloader.md`              |

**Manage basic networking**

| Objective                                                 | File                                            |
| --------------------------------------------------------- | ----------------------------------------------- |
| Configure IPv4 and IPv6 addresses                         | `24-network-nmcli.md`                           |
| Configure hostname resolution                             | `25-hostnames-dns.md`                           |
| Configure network services to start automatically at boot | `14-systemd-services.md`, `24-network-nmcli.md` |
| Restrict network access using `firewall-cmd` / firewalld  | `26-firewalld.md`                               |

**Manage users and groups**

| Objective                                                          | File                        |
| ------------------------------------------------------------------ | --------------------------- |
| Create, delete, and modify local user accounts                     | `10-users-groups.md`        |
| Change passwords and adjust password aging for local user accounts | `11-password-aging-sudo.md` |
| Create, delete, and modify local groups and group memberships      | `10-users-groups.md`        |
| Configure superuser access                                         | `11-password-aging-sudo.md` |

**Manage security**

| Objective                                                    | File                               |
| ------------------------------------------------------------ | ---------------------------------- |
| Configure firewall settings using `firewall-cmd` / firewalld | `26-firewalld.md`                  |
| Manage default file permissions                              | `06-standard-permissions-umask.md` |
| Configure key-based authentication for SSH                   | `09-ssh.md`                        |
| Set enforcing and permissive modes for SELinux               | `27-selinux.md`                    |
| List and identify SELinux file and process context           | `27-selinux.md`                    |
| Restore default file contexts                                | `27-selinux.md`                    |
| Manage SELinux port labels                                   | `27-selinux.md`                    |
| Use boolean settings to modify system SELinux settings       | `27-selinux.md`                    |
| Diagnose and address routine SELinux policy violations       | `27-selinux.md`                    |

**Manage containers** (verify this is still in scope)

| Objective                                                         | File                          |
| ----------------------------------------------------------------- | ----------------------------- |
| Find and retrieve container images from a remote registry         | `34-podman-images-running.md` |
| Inspect container images                                          | `34-podman-images-running.md` |
| Perform container management using `podman` and `skopeo`          | `34-podman-images-running.md` |
| Run, start, stop, and list running containers                     | `34-podman-images-running.md` |
| Run a service inside a container                                  | `34-podman-images-running.md` |
| Configure a container to start automatically as a systemd service | `35-containers-systemd.md`    |
| Attach persistent storage to a container                          | `35-containers-systemd.md`    |

## How Each Numbered File Is Structured

Because EX200 is hands-on, these are **not** multiple-choice questions. Each file gives:

- **Before you start** — lab requirement and how to work through the file.
- **Follow along** — one command at a time, on your VM, with expected output. **Do this first if you are new to RHEL.** This is how you build muscle memory without drowning in flags upfront.
- **Practice tasks** — worded the way the exam words them. Terse and specific; hints point back to the follow-along steps, not the full answer.
- **Solutions** — the full command sequence, why each step exists, and what the common wrong turn is.
- **Verify** — how to prove to yourself the task is actually done.
- **Quick reference** — flags, tables, and patterns for review **after** you have typed them once. Not a front-to-back read.
- **Persistence check** — what specifically must survive the reboot, and how to confirm it.
- **Exam tips** — the memory hooks and traps.

**Study order within each file:** Follow Along → Practice Tasks → Solutions only if stuck → Quick Reference for review.

**Do the practice tasks before reading the solutions.** Reading a solution feels like learning and is not. You are being graded on typing speed and muscle memory, not recognition.

All numbered files **`02` through `35`** use this layout. `01-shell-fundamentals.md` still uses the older format until it is converted.

## Recommended Study Order

1. `Lab-Setup.md`. Build the lab first. Two VMs and three spare disks. Nothing else here works without it.
2. `Persistence.md`. Ten minutes. It reframes everything that follows.
3. `01-shell-fundamentals.md` - `09-ssh.md`. Essential tools. Fast, but do not skip `02-redirection-pipes.md` and `03-grep-regex.md`; redirection and regex show up inside other tasks.
4. `10-users-groups.md` - `12-special-permissions-acls.md`. Users, groups, sudo, ACLs, set-GID collaboration.
5. `28-disks-partitions.md` - `32-nfs-autofs.md`. Storage. **Move this early.** It is the highest-value, highest-risk block, it takes the longest, and it is where people run out of time.
6. `13-processes.md` - `20-tuned-profiles.md`. Running systems, boot recovery, logs, scheduling.
7. `21-time-chrony.md` - `23-flatpak.md`. Time, software, Flatpak.
8. `24-network-nmcli.md` - `26-firewalld.md`. Networking and firewalld.
9. `27-selinux.md`. SELinux. Read it twice.
10. `33-shell-scripting.md`. Scripting.
11. `34-podman-images-running.md`, `35-containers-systemd.md`. Containers, if in scope for your exam version.
12. `36-break-and-fix-drill.md`. Mixed troubleshooting drill.
13. `PracticeExam-1.md` under a 3 hour timer, then reboot and grade yourself.
14. Rework your weak areas, then `PracticeExam-2.md`, then `PracticeExam-3.md`.
15. `Flashcards.md`, `CheatSheet.md`, `Pitfalls.md` the day before.

## Named Deep-Dive Files

| File              | Covers                                                               |
| ----------------- | -------------------------------------------------------------------- |
| `Persistence.md`  | **What must survive a reboot, and how to prove it. Read this first** |
| `CheatSheet.md`   | One-page final review                                                |
| `Commands.md`     | Command reference organised by objective                             |
| `Storage.md`      | Partitions, LVM, filesystems, swap, `fstab`, NFS, autofs             |
| `SELinux.md`      | Contexts, booleans, ports, `restorecon`, diagnosing denials          |
| `Systemd.md`      | Units, targets, dependencies, timers, overrides                      |
| `Networking.md`   | `nmcli`, keyfiles, resolution, firewalld                             |
| `Permissions.md`  | `ugo/rwx`, special bits, umask, ACLs, collaboration                  |
| `Users.md`        | Accounts, aging, sudo, `/etc/passwd` and `/etc/shadow` fields        |
| `Scripting.md`    | Bash constructs the exam actually asks for                           |
| `BootRecovery.md` | GRUB editing, `rd.break`, root password reset, rescue mode           |
| `Podman.md`       | Images, containers, volumes, systemd integration                     |
| `Vim.md`          | The 20 keystrokes you need and nothing more                          |
| `Pitfalls.md`     | The mistakes that fail candidates                                    |
| `Flashcards.md`   | Rapid recall drill                                                   |

## Practice Assets

| File                        | Use                                                                   |
| --------------------------- | --------------------------------------------------------------------- |
| `Lab-Setup.md`              | Build two RHEL-compatible VMs with spare disks                        |
| `PracticeExam-1.md`         | 18 tasks, 3 hour timer, graded solutions                              |
| `PracticeExam-2.md`         | 20 tasks, harder, more troubleshooting                                |
| `PracticeExam-3.md`         | 20 tasks, full-spread, closest to real exam feel                      |
| `36-break-and-fix-drill.md` | Break-and-fix drill: deliberately sabotage the system, then repair it |

## Exam Strategy

**Before you touch anything:**

1. Read **every** task first. Two minutes. Some tasks conflict, some depend on others, and some are much cheaper than they look.
2. Note which tasks are on which machine. The exam usually gives you more than one.
3. Do the **root password reset** first if it is asked, because everything else may depend on it.

**Ordering:**

| Do early                               | Why                                                                   |
| -------------------------------------- | --------------------------------------------------------------------- |
| Root password / boot recovery          | Blocks everything else                                                |
| Repository configuration               | You cannot install packages without it, and later tasks need packages |
| Networking and hostname                | Later tasks may need the network                                      |
| Storage: LVM, partitions, swap, mounts | Longest, most error-prone, most points                                |

| Do late                     | Why                                       |
| --------------------------- | ----------------------------------------- |
| SELinux contexts            | Do it after the files and services exist  |
| Tuned profile, time service | Fast, one command each                    |
| Scripting                   | Self-contained, easy to leave for the end |

**Ten minutes before the end, stop configuring and do this:**

```bash
# 1. Every unit you were asked to run must be enabled AND started
systemctl list-unit-files --state=enabled | grep -Ei 'httpd|nfs|autofs|chronyd|firewalld|sshd'

# 2. fstab must parse and every entry must mount
sudo findmnt --verify
sudo mount -a && echo "mount -a OK"

# 3. Firewall must be permanent
sudo firewall-cmd --list-all --permanent

# 4. SELinux must be enforcing if asked, and contexts correct
getenforce
grep '^SELINUX=' /etc/selinux/config

# 5. THEN REBOOT AND RE-CHECK EVERYTHING
sudo reboot
```

**Reboot with time to spare.** Rebooting at minute 175 of 180 and discovering `fstab` is broken means you fail tasks you had actually completed. Reboot at minute 150.

## Numbers And Paths To Know Cold

| Thing                                    | Value                                               |
| ---------------------------------------- | --------------------------------------------------- |
| Regular user UID range                   | **1000-60000** (`/etc/login.defs`)                  |
| System account UID range                 | 201-999                                             |
| root UID                                 | 0                                                   |
| Default `umask`, regular user            | **`0002`**                                          |
| Default `umask`, root                    | **`0022`**                                          |
| Resulting default dir / file perms, user | `775` / `664`                                       |
| Resulting default dir / file perms, root | `755` / `644`                                       |
| Password fields in `/etc/shadow`         | name:pass:lastchg:min:max:warn:inactive:expire      |
| Default `PASS_MAX_DAYS`                  | 99999                                               |
| Default `PASS_MIN_DAYS`                  | 0                                                   |
| Default `PASS_WARN_AGE`                  | 7                                                   |
| SSH port                                 | 22                                                  |
| HTTP / HTTPS                             | 80 / 443                                            |
| NFS                                      | 2049                                                |
| Default SELinux mode on RHEL             | **enforcing**, targeted policy                      |
| Sticky bit / SGID / SUID numeric         | **1** / **2** / **4**                               |
| Default target file                      | `/etc/systemd/system/default.target` (a symlink)    |
| GRUB config to edit                      | **`/etc/default/grub`**, then `grub2-mkconfig`      |
| Journal persistence directory            | **`/var/log/journal`**                              |
| NetworkManager keyfiles                  | `/etc/NetworkManager/system-connections/`           |
| Repo files                               | `/etc/yum.repos.d/*.repo`                           |
| `chrony` config                          | `/etc/chrony.conf`                                  |
| Autofs master map                        | `/etc/auto.master` or `/etc/auto.master.d/*.autofs` |
| Container systemd units (rootless)       | `~/.config/systemd/user/`                           |
| Container systemd units (root)           | `/etc/systemd/system/`                              |

## The Universal EX200 Reasoning Flow

When a task looks unfamiliar:

```text
1. What is the persistent artifact?
   A file, a unit enablement, a --permanent firewall rule, an fstab line,
   a semanage rule, a keyfile. If the task produced nothing on disk,
   it will not survive the reboot and it scores zero.

2. Is there a tool that writes the config for me?
   nmcli, firewall-cmd --permanent, semanage, authselect, timedatectl,
   tuned-adm, usermod, chage. Prefer the tool over hand-editing.
   Hand-editing is for /etc/fstab, /etc/default/grub, /etc/sudoers.d/*,
   /etc/chrony.conf, and scripts.

3. Does SELinux care?
   Any non-default path, any non-default port, any service reading files
   you created -> check the context and the port label.

4. Does the firewall care?
   Any service reachable from another machine -> add the service or port,
   --permanent, then --reload.

5. Did I enable AND start it?
   systemctl enable --now is one command. Use it every time.

6. Prove it. Then reboot and prove it again.
```

## RHEL Truths To Remember

- Configurations must **persist after reboot**. This is the whole exam.
- `systemctl enable --now` does both jobs. `start` alone is the most common silent failure.
- `firewall-cmd` changes are **runtime only** unless you pass `--permanent`, and `--permanent` does nothing until `--reload`.
- Mount by **UUID or label**, never by `/dev/sdb1`, because device names are not stable.
- **Test `/etc/fstab` with `mount -a` and `findmnt --verify` before rebooting.** A bad `fstab` line can leave the system unbootable.
- `restorecon` fixes contexts to match policy. `semanage fcontext` changes what the policy says they should be. You usually need **both, in that order**.
- Extending an LVM filesystem is **two** steps unless you use `lvextend -r`.
- `useradd` does not set a password. `passwd` does.
- On the exam, `man -k` and `man` are available and allowed. Use them instead of guessing flags.
- Reboot early enough to fix what the reboot breaks.
