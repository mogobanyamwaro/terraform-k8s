# systemd Deep Dive

systemd is the thread running through most of the exam. Services, targets, boot, timers, mount units, container units, and user units are all the same mechanism. Understanding it once means understanding all of them.

Step-by-step tasks are in `14-systemd-services.md`, `15-systemd-targets-boot.md`, and `19-scheduling-cron-at.md`.

---

## Unit types

| Extension | What it manages | You will write |
| --- | --- | --- |
| **`.service`** | A process | **Yes** |
| **`.target`** | A grouping and synchronisation point | Rarely |
| **`.timer`** | A schedule for another unit | **Yes** |
| **`.mount`** | A mount point | **Generated from `/etc/fstab`** |
| `.automount` | On-demand mounting | Via `x-systemd.automount` |
| `.swap` | Swap | Generated from `/etc/fstab` |
| `.socket` | Socket activation | No |
| `.path` | Filesystem watch | No |
| `.slice` | Resource grouping | No |
| `.device` | udev device | Automatic |

```bash
systemctl list-units --type=service
systemctl list-units --type=target
systemctl list-units --type=mount
systemctl list-unit-files
```

**`/etc/fstab` is converted into `.mount` and `.swap` units at every boot and at every `daemon-reload`.** That is why editing fstab needs a `daemon-reload`, and why a bad line becomes a failed unit rather than a silent skip.

```bash
systemctl list-units --type=mount
systemctl status data.mount              # the unit for /data
```

**Unit names escape path separators.** `/data` becomes `data.mount`, `/var/log` becomes `var-log.mount`:

```bash
systemd-escape -p --suffix=mount /var/log
```

---

## Where units live, and who wins

```text
Highest precedence
   /etc/systemd/system/            ← YOUR units and overrides
   /run/systemd/system/            ← runtime, transient
   /usr/lib/systemd/system/        ← package-provided; DO NOT EDIT
Lowest precedence
```

```bash
systemctl cat httpd                     # the effective unit, including drop-ins
systemctl show httpd                    # every resolved property
systemctl show httpd -p Restart -p ExecStart
```

**Three ways to change a package's unit:**

| Method | Result |
| --- | --- |
| Edit `/usr/lib/systemd/system/httpd.service` | **Wrong — a package update overwrites it** |
| **`systemctl edit httpd`** | **A drop-in in `/etc/systemd/system/httpd.service.d/override.conf`. Correct** |
| `systemctl edit --full httpd` | A complete copy in `/etc/systemd/system/`. Also correct, more to maintain |

```bash
sudo systemctl edit httpd
```

```ini
[Service]
Restart=always
RestartSec=5
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart httpd
systemctl cat httpd                     # shows the base unit AND the drop-in
```

**A drop-in only needs the section and the settings you are changing.** Everything else is inherited.

**One exception worth knowing:** list-valued settings like `ExecStart` are not replaced by a drop-in, they are appended — which fails, because a service may have only one `ExecStart`. Clear it first:

```ini
[Service]
ExecStart=
ExecStart=/usr/sbin/httpd -D FOREGROUND -f /etc/httpd/conf/alt.conf
```

---

## Anatomy of a service unit

```ini
[Unit]
Description=My application
Documentation=man:myapp(8)
After=network-online.target
Wants=network-online.target
Requires=postgresql.service
Before=nginx.service
Conflicts=myapp-legacy.service
ConditionPathExists=/etc/myapp.conf

[Service]
Type=simple
ExecStartPre=/usr/local/bin/myapp-check
ExecStart=/usr/local/bin/myapp --config /etc/myapp.conf
ExecStop=/usr/local/bin/myapp-stop
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
User=myapp
Group=myapp
WorkingDirectory=/var/lib/myapp
Environment=LOG_LEVEL=info
EnvironmentFile=/etc/myapp.env
TimeoutStartSec=90
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### `[Unit]` dependencies

| Directive | Meaning |
| --- | --- |
| **`After=`** | **Ordering only. Start after that unit** |
| `Before=` | Ordering only. Start before that unit |
| **`Wants=`** | **Try to start it too. Failure is tolerated** |
| **`Requires=`** | **Must start it. If it fails, this unit fails** |
| `BindsTo=` | Like `Requires=`, and stops if the other stops |
| `Conflicts=` | Cannot run at the same time |
| `PartOf=` | Restart and stop propagate downward |

**`After=` and `Requires=` are independent.** `Requires=` without `After=` starts both simultaneously, which is usually a bug. The normal pair is:

```ini
After=network-online.target
Wants=network-online.target
```

**`network.target` is not the same as `network-online.target`.** The first means "networking is being configured"; the second means "an address is actually configured". For anything that binds an address or reaches out, you want `network-online.target`.

### `[Service] Type=`

| `Type=` | systemd considers the service started when |
| --- | --- |
| **`simple`** | **`ExecStart` has been executed. The default** |
| `exec` | The binary has been executed successfully |
| **`forking`** | **The parent exits and a child continues. Needs `PIDFile=`** |
| **`oneshot`** | **The process exits. Use for scripts and timer jobs** |
| `notify` | The service tells systemd via `sd_notify`. Podman units use this |
| `dbus` | The service takes its D-Bus name |
| `idle` | Like simple, delayed until other jobs finish |

**`Type=oneshot` for a script that runs and exits** — a timer job, a boot-time fix-up. Add `RemainAfterExit=yes` if you want `systemctl status` to show it as active after it finishes.

### `[Service] Restart=`

| Value | Restarts on |
| --- | --- |
| `no` | Never. Default |
| `on-success` | A clean exit only |
| **`on-failure`** | **Non-zero exit, signal, timeout, or watchdog** |
| `on-abnormal` | Signal, timeout, or watchdog |
| `on-watchdog` | Watchdog timeout only |
| `on-abort` | An uncaught signal |
| **`always`** | **Any exit at all** |

```ini
[Unit]
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Restart=always
RestartSec=10
```

**When a unit exceeds the start limit it refuses to start with a confusing message:**

```text
Failed to start myapp.service: Start request repeated too quickly.
```

```bash
sudo systemctl reset-failed myapp
sudo systemctl start myapp
```

**`systemctl reset-failed` is the fix, and it is worth remembering** because the message does not tell you.

### `[Install]`

```ini
[Install]
WantedBy=multi-user.target
```

**This section is what `systemctl enable` acts on.** Enabling creates a symlink:

```bash
sudo systemctl enable myapp
ls -l /etc/systemd/system/multi-user.target.wants/
```

```text
myapp.service -> /etc/systemd/system/myapp.service
```

**A unit with no `[Install]` section cannot be enabled** — `is-enabled` reports `static`. That is correct for a `.service` driven by a `.timer`, and a bug for anything that should start at boot.

| `WantedBy=` | Starts at |
| --- | --- |
| `multi-user.target` | Normal boot |
| `graphical.target` | Graphical boot only |
| `default.target` | Whatever the default is |
| `timers.target` | For a `.timer` unit |
| `sockets.target` | For a `.socket` unit |

---

## Service management

```bash
sudo systemctl start httpd
sudo systemctl stop httpd
sudo systemctl restart httpd
sudo systemctl reload httpd                   # re-read config without stopping
sudo systemctl reload-or-restart httpd        # reload if supported, else restart
sudo systemctl enable httpd
sudo systemctl disable httpd
sudo systemctl enable --now httpd             # THE exam command
sudo systemctl disable --now httpd
sudo systemctl mask httpd
sudo systemctl unmask httpd
sudo systemctl kill httpd
sudo systemctl kill -s SIGKILL httpd
```

**`enable` and `start` are orthogonal:**

```text
                  running now?   after reboot?
start                 yes            no
enable                no             yes
enable --now          yes            yes
```

**`enable --now` is the answer to almost every service task, because the exam grades after a reboot but you also want to verify now.**

### mask

```bash
sudo systemctl mask httpd
```

```text
Created symlink /etc/systemd/system/httpd.service → /dev/null.
```

**Masking makes a unit unstartable, even as a dependency of something else.** It is stronger than `disable`, which only removes the boot-time symlink. Use it when a task says "ensure X can never start" or when a service keeps being pulled in by another.

```bash
systemctl is-enabled httpd                    # masked
sudo systemctl start httpd                    # Unit httpd.service is masked.
sudo systemctl unmask httpd
```

### Status output, read properly

```bash
systemctl status httpd
```

```text
● httpd.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; preset: disabled)
     Active: active (running) since Tue 2026-08-18 18:05:12 EAT; 2min ago
       Docs: man:httpd.service(8)
   Main PID: 3421 (httpd)
     Status: "Total requests: 0; Idle/Busy workers 100/0"
      Tasks: 213 (limit: 11048)
     CGroup: /system.slice/httpd.service
             ├─3421 /usr/sbin/httpd -DFOREGROUND
             └─3422 /usr/sbin/httpd -DFOREGROUND
```

| Line | What to read |
| --- | --- |
| **`Loaded: ... ; enabled;`** | **The persistence answer. `enabled` means it starts at boot** |
| `Active: active (running)` | Running now |
| `Active: inactive (dead)` | Stopped |
| **`Active: failed`** | **It tried and failed — read the journal** |
| `Active: activating` | Still starting |
| `Loaded: masked` | Cannot be started |
| `Loaded: not-found` | **No such unit — wrong name, or no `daemon-reload`** |
| `CGroup:` | Every process the unit owns |

**The scriptable forms:**

```bash
systemctl is-enabled httpd                    # enabled | disabled | masked | static
systemctl is-active httpd                     # active | inactive | failed
systemctl is-failed httpd
```

**`is-enabled` is the check that predicts the reboot.** Make it a reflex after every service task.

### Investigating a failure

```bash
systemctl status httpd
sudo journalctl -xeu httpd                    # the most useful single command
sudo journalctl -u httpd -n 50 --no-pager
sudo journalctl -u httpd -b
systemctl --failed
sudo systemctl reset-failed
```

```text
Symptom                                Likely cause
────────────────────────────────────────────────────────────────────
"Unit X could not be found"             Wrong name, or missing daemon-reload
"Unit X is masked"                      systemctl unmask
Active: failed, status=1                Read the journal; usually config
Active: failed, status=13/PERM          Permissions or SELinux
"could not bind to address"             Port in use, or a missing SELinux
                                        port label
"Start request repeated too quickly"    systemctl reset-failed
Starts, then immediately exits          Type= is wrong (simple vs forking)
```

---

## Targets

A target is a synchronisation point, not a runlevel — but it fills the same role.

| Target | Old runlevel | Meaning |
| --- | --- | --- |
| `poweroff.target` | 0 | Halt |
| **`rescue.target`** | 1 | **Single-user, root filesystem mounted, root password required** |
| `multi-user.target` | 2, 3, 4 | **Text mode, full networking** |
| **`graphical.target`** | 5 | **GUI** |
| `reboot.target` | 6 | Reboot |
| **`emergency.target`** | — | **Minimal shell, `/` read-only, almost nothing started** |

```bash
systemctl get-default
sudo systemctl set-default multi-user.target        # PERSISTENT
sudo systemctl set-default graphical.target
sudo systemctl isolate multi-user.target           # NOW, reverts at reboot
systemctl list-units --type=target
systemctl list-dependencies multi-user.target
systemctl list-dependencies graphical.target --all
```

**`set-default` writes a symlink:**

```bash
ls -l /etc/systemd/system/default.target
```

```text
default.target -> /usr/lib/systemd/system/multi-user.target
```

**`isolate` versus `set-default` is a persistence trap.** A task saying "boot into text mode" means `set-default`. A task saying "switch to text mode now" means `isolate`. When in doubt, do both.

Selecting a target for one boot only, at the GRUB menu:

```text
systemd.unit=multi-user.target
systemd.unit=rescue.target
systemd.unit=emergency.target
```

---

## Boot sequence

```text
   Firmware (BIOS/UEFI)
        ▼
   GRUB 2                          /boot/grub2/grub.cfg  ← press e to edit
        ▼
   Kernel + initramfs              kernel arguments apply here
        ▼
   systemd (PID 1)                 /sbin/init → systemd
        ▼
   default.target                  systemctl get-default
        ▼
   ├─ sysinit.target               local filesystems, swap, udev
   ├─ basic.target                 sockets, timers, paths
   └─ multi-user.target            your services
```

```bash
systemd-analyze                               # total boot time
systemd-analyze blame                         # slowest units
systemd-analyze critical-chain                # the ordering path that mattered
systemd-analyze plot > boot.svg
journalctl -b                                 # this boot's log
journalctl -b -1                              # the previous boot
```

**`systemd-analyze blame` is how you find a unit that adds ninety seconds to boot** — usually a mount waiting for a device that is not there, which `nofail` fixes.

---

## Timers

Timers replace cron for anything that needs systemd's features: dependency ordering, resource control, journal integration, and catching up on missed runs.

### The pair

A timer always drives a service. You write both.

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Nightly backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Run the nightly backup at 02:00

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer      # THE TIMER, not the service
systemctl list-timers | grep backup
systemctl status backup.timer
sudo systemctl start backup.service           # test the job right now
sudo journalctl -u backup.service -n 30
```

**Three rules:**

1. **Enable the `.timer`, never the `.service`.** Enabling the service makes it run once at boot, which is not a schedule.
2. **The `.service` should have no `[Install]` section.** The timer is what activates it. `is-enabled` reporting `static` for the service is correct.
3. **The names must match** — `backup.timer` drives `backup.service` automatically. Use `Unit=` in `[Timer]` if they differ.

### `OnCalendar` syntax

```text
DayOfWeek Year-Month-Day Hour:Minute:Second
```

| Expression | Meaning |
| --- | --- |
| `hourly` | `*-*-* *:00:00` |
| `daily` | `*-*-* 00:00:00` |
| `weekly` | `Mon *-*-* 00:00:00` |
| `monthly` | `*-*-01 00:00:00` |
| `*-*-* 02:00:00` | Every day at 02:00 |
| `Mon..Fri 09:00` | Weekdays at 09:00 |
| `Sat,Sun 10:00` | Weekends |
| `*-*-01 00:00:00` | The first of each month |
| `*-*-* *:00/15:00` | Every 15 minutes |
| `*-*-* 09..17:00:00` | Hourly, 09:00 to 17:00 |
| `2026-12-25 00:00:00` | Once, on a date |

```bash
systemd-analyze calendar 'Mon..Fri 09:00'
systemd-analyze calendar '*-*-* 02:00:00' --iterations=5
```

**`systemd-analyze calendar` validates the expression and shows the next runs.** Use it rather than guessing — the syntax is unforgiving.

### Timer directives

| Directive | Effect |
| --- | --- |
| **`OnCalendar=`** | **Wall-clock schedule** |
| `OnBootSec=5min` | Relative to boot |
| `OnUnitActiveSec=1h` | Relative to the last run — for simple intervals |
| `OnStartupSec=` | Relative to systemd start |
| **`Persistent=true`** | **Run a missed occurrence when the machine comes back. This is what `anacron` did** |
| `RandomizedDelaySec=300` | Jitter, to spread load |
| `AccuracySec=1s` | Tighter than the default one minute |
| `Unit=other.service` | Drive a differently-named unit |

```bash
systemctl list-timers --all
```

```text
NEXT                        LEFT      LAST                        PASSED  UNIT
Wed 2026-08-19 02:00:00 EAT 7h left   Tue 2026-08-18 02:00:00 EAT 16h ago backup.timer
```

### Timers versus cron

| | cron | systemd timer |
| --- | --- | --- |
| Simpler to write | **Yes** | No — two files |
| On the exam | **Explicitly listed** | Mentioned for RHEL 10 |
| Catch up on missed runs | Only via `anacron` | **`Persistent=true`** |
| Logging | Mail, or a log file | **The journal, per unit** |
| Dependencies and ordering | No | **Yes** |
| Resource limits | No | Yes |
| Randomised delay | No | **Yes** |

**For the exam, use cron when the task says cron and a timer when the task says timer.** If a task just says "schedule this", cron is faster to write and easier to verify.

---

## User units

```bash
systemctl --user status
systemctl --user list-units
mkdir -p ~/.config/systemd/user
vim ~/.config/systemd/user/myapp.service
systemctl --user daemon-reload
systemctl --user enable --now myapp
systemctl --user status myapp
journalctl --user -u myapp
```

| | System units | User units |
| --- | --- | --- |
| Directory | `/etc/systemd/system/` | **`~/.config/systemd/user/`** |
| Commands | `sudo systemctl` | **`systemctl --user`** |
| Journal | `journalctl -u X` | **`journalctl --user -u X`** |
| Runs as | The `User=` in the unit, or root | **The owning user** |
| `WantedBy=` | `multi-user.target` | **`default.target`** |
| **Starts at boot** | **When enabled** | **Only with lingering** |

### Lingering

```bash
loginctl enable-linger alice
sudo loginctl enable-linger alice             # for another user
loginctl show-user alice | grep -i Linger
ls -l /var/lib/systemd/linger/
loginctl list-users
systemctl status user@$(id -u alice).service
```

```text
Linger=yes
```

**Without lingering, a user's systemd manager (`user@UID.service`) starts when they log in and stops when their last session ends — taking every user unit with it.** So at boot, with nobody logged in, no user unit runs.

**And `systemctl --user is-enabled` still reports `enabled`**, because the symlink is perfectly valid. That is what makes this trap so effective: every check passes and the service is dead after the reboot.

```bash
# For EVERY user service, both commands:
systemctl --user enable --now myapp
loginctl enable-linger $(whoami)
```

**Two mechanical points:**

```bash
sudo -u alice systemctl --user status myapp
# Failed to connect to bus: No medium found
```

**Use `su - alice` instead.** The dash creates a login session with `XDG_RUNTIME_DIR` set, which the user bus needs.

```bash
su - alice -c 'systemctl --user status myapp'
```

**And never `sudo systemctl --user`** — that talks to root's user manager, not alice's.

---

## Container units

Two mechanisms, both covered in `35-containers-systemd.md`.

```bash
# podman generate systemd — deprecated in Podman 5 but still present
cd /etc/systemd/system
sudo podman generate systemd --new --name web --files
sudo systemctl daemon-reload
sudo systemctl enable --now container-web
```

```bash
# Quadlet — the current approach
sudo vim /etc/containers/systemd/web.container
sudo systemctl daemon-reload
sudo systemctl start web
```

**The systemd-relevant differences:**

| | `generate systemd` | Quadlet |
| --- | --- | --- |
| Unit file | A real file in `/etc/systemd/system/` | **Generated into `/run/systemd/generator/`** |
| Source | `container-web.service` | **`/etc/containers/systemd/web.container`** |
| Unit name | `container-web.service` | **`web.service`** |
| `systemctl enable` | **Required** | **Impossible — it is a generated unit** |
| Enabling mechanism | The symlink `enable` creates | **`[Install] WantedBy=`** |
| After an edit | `daemon-reload` | **`daemon-reload` regenerates it** |

```bash
systemctl cat web.service                     # see what was generated
ls -l /run/systemd/generator/
/usr/lib/systemd/system-generators/podman-system-generator --dryrun
```

**A generated unit lives on tmpfs and is recreated at every boot from your source file. Editing the generated file achieves nothing.**

```bash
sudo systemctl enable web
```

```text
Failed to enable unit: Unit /run/systemd/generator/web.service is transient or generated.
```

**That error is expected.** The bug to look for is a missing `[Install]` section in the `.container` file, which means it never starts at boot.

---

## `daemon-reload`: when and why

```bash
sudo systemctl daemon-reload
```

Required after:

- creating or editing any unit in `/etc/systemd/system/`
- `systemctl edit` (which does it for you)
- `podman generate systemd`
- creating or editing a Quadlet `.container` file
- **editing `/etc/fstab`** — systemd generates mount units from it

**Symptoms of forgetting it:**

```text
Unit myapp.service could not be found.
```

or your edits appear to have no effect, or `systemctl status` shows the old `ExecStart`.

**`daemon-reload` re-reads unit files. It does not restart anything.** After it, restart the affected units:

```bash
sudo systemctl daemon-reload
sudo systemctl restart myapp
```

**`daemon-reexec` re-executes systemd itself** — needed only after a systemd package update, and rarely on the exam.

---

## Complete worked examples

### A service from a script

```bash
sudo tee /usr/local/bin/monitor.sh >/dev/null <<'EOF'
#!/bin/bash
while true; do
    echo "$(date '+%F %T') load: $(cut -d' ' -f1 /proc/loadavg)"
    sleep 60
done
EOF
sudo chmod +x /usr/local/bin/monitor.sh

sudo tee /etc/systemd/system/monitor.service >/dev/null <<'EOF'
[Unit]
Description=Load monitor
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/monitor.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now monitor
systemctl status monitor
sudo journalctl -u monitor -f
systemctl is-enabled monitor
sudo reboot
systemctl is-active monitor
```

**Note `echo` inside the script goes to the journal** because `StandardOutput=journal` is the default. That is free logging with no file to rotate.

### A scheduled job with a timer

```bash
sudo tee /usr/local/bin/diskcheck.sh >/dev/null <<'EOF'
#!/bin/bash
THRESHOLD=${1:-80}
df -h --output=pcent,target -x tmpfs -x devtmpfs | tail -n +2 | \
while read -r pct mount; do
    pct=${pct%\%}; pct=${pct// /}
    if (( pct > THRESHOLD )); then
        echo "WARNING: $mount is ${pct}% full"
    fi
done
EOF
sudo chmod +x /usr/local/bin/diskcheck.sh
sudo /usr/local/bin/diskcheck.sh 10          # test it produces output

sudo tee /etc/systemd/system/diskcheck.service >/dev/null <<'EOF'
[Unit]
Description=Disk usage check

[Service]
Type=oneshot
ExecStart=/usr/local/bin/diskcheck.sh 80
EOF

sudo tee /etc/systemd/system/diskcheck.timer >/dev/null <<'EOF'
[Unit]
Description=Run the disk usage check hourly

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now diskcheck.timer
systemctl list-timers | grep diskcheck
sudo systemctl start diskcheck.service       # run it now
sudo journalctl -u diskcheck.service -n 20
```

### Overriding a package unit

**Task: make sshd restart automatically if it ever exits.**

```bash
sudo systemctl edit sshd
```

```ini
[Service]
Restart=always
RestartSec=5
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart sshd
systemctl show sshd -p Restart
cat /etc/systemd/system/sshd.service.d/override.conf
systemctl cat sshd
```

```text
Restart=always
```

**The package's own file is untouched, so a package update keeps your change.**

---

## Verification

```bash
# Per unit
systemctl is-enabled UNIT                     # the persistence answer
systemctl is-active UNIT
systemctl status UNIT
systemctl cat UNIT                            # the effective configuration
systemctl show UNIT -p Restart -p ExecStart

# System-wide
systemctl --failed
systemctl list-unit-files --state=enabled
systemctl get-default
systemctl list-timers --all
systemd-analyze blame | head

# User units
su - USER -c 'systemctl --user is-enabled UNIT'
loginctl show-user USER | grep -i Linger

# The journal
journalctl -xeu UNIT
journalctl -b -p err
```

**A sweep of everything you touched:**

```bash
for s in httpd sshd firewalld chronyd nfs-server autofs crond atd tuned NetworkManager; do
  printf '%-16s %-10s %s\n' "$s" \
    "$(systemctl is-enabled "$s" 2>/dev/null || echo -)" \
    "$(systemctl is-active  "$s" 2>/dev/null || echo -)"
done
```

**Then reboot and run it again.** Any line that changed is a persistence bug.

---

## The five things to take away

1. **`enable --now`, always.** `start` alone is the most common way to lose marks.
2. **`systemctl is-enabled` is the check that predicts the reboot.** `is-active` only describes now.
3. **`daemon-reload` after any unit file change, including `/etc/fstab`.**
4. **`systemctl edit` for overrides.** Never edit anything in `/usr/lib/systemd/system/`.
5. **Enable the timer, not the service.** And for user units, `loginctl enable-linger` as well as `enable`.
