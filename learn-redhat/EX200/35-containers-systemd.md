# 35. Containers As systemd Services

**Objective:** Configure a container to start automatically as a systemd service.

**This is the objective the containers domain exists for.** Podman has no daemon, so `podman run -d` is the equivalent of `systemctl start` without `enable` — the container is gone after a reboot. A systemd unit is what makes it persistent, and persistence is what is graded.

## Concept Refresher

### Why a unit is required

```bash
podman run -d --name web -p 8080:8080 <image>
curl http://localhost:8080                     # works
sudo reboot
podman ps                                      # EMPTY
curl http://localhost:8080                     # connection refused
```

**Podman is not a daemon.** A container is a child of the `podman` process that started it, and nothing brings it back at boot. systemd is the supervisor.

```text
   podman run -d          ≈  systemctl start    (now, but not after a reboot)
   a systemd unit + enable ≈  systemctl enable  (after every reboot)
```

### Two mechanisms

| | **`podman generate systemd`** | **Quadlet (`.container` files)** |
| --- | --- | --- |
| Available since | Podman 3 | **Podman 4.4+** |
| Status | **Deprecated in Podman 5** | **The current approach** |
| How it works | Generates a `.service` file from a container | systemd generator reads a `.container` file |
| File written | `container-web.service` | `web.container` |
| RHEL 9 | **Yes** | Yes (4.4+) |
| RHEL 10 | Deprecated but present | **Yes, preferred** |

**Learn both.** `generate systemd` is what most study material and older exam objectives describe; Quadlet is what RHEL 10 prefers. A task will accept either as long as the container starts at boot.

### Rootful units

```bash
sudo podman run -d --name web -p 8080:8080 registry.access.redhat.com/ubi9/httpd-24

cd /etc/systemd/system
sudo podman generate systemd --new --name web --files
sudo systemctl daemon-reload
sudo podman rm -f web                          # remove the manual container
sudo systemctl enable --now container-web
systemctl status container-web
```

| Element | Detail |
| --- | --- |
| Unit directory | **`/etc/systemd/system/`** |
| Unit name | **`container-<name>.service`** |
| Enable | `sudo systemctl enable --now container-web` |
| Runs as | root |
| Starts at | **Boot** |

**`--new` is important.** Without it the unit starts and stops the *existing* container; with it, the unit creates a fresh container each time from the recorded `podman run` command line. **`--new` is what you want** — it survives `podman rm` and is self-contained.

### Rootless units

```bash
podman run -d --name web -p 8080:8080 registry.access.redhat.com/ubi9/httpd-24

mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --new --name web --files
systemctl --user daemon-reload
podman rm -f web
systemctl --user enable --now container-web
systemctl --user status container-web

# THE STEP EVERYONE FORGETS
loginctl enable-linger $(whoami)
loginctl show-user $(whoami) | grep -i linger
```

| Element | Detail |
| --- | --- |
| Unit directory | **`~/.config/systemd/user/`** |
| Commands | **`systemctl --user`** |
| Enable | `systemctl --user enable --now container-web` |
| **Required extra step** | **`loginctl enable-linger USER`** |

**Without lingering, a rootless user unit stops when the user logs out and does not start at boot.** systemd tears down the user's session manager on logout. `enable-linger` keeps it alive:

```bash
loginctl enable-linger alice
sudo loginctl enable-linger alice              # from another account
loginctl show-user alice | grep -i linger
ls /var/lib/systemd/linger/
```

```text
Linger=yes
```

**`loginctl enable-linger` is the single most commonly missed step in this objective.** A rootless container unit without it appears to work perfectly and is dead after the reboot.

### Quadlet

```bash
# Rootful
sudo mkdir -p /etc/containers/systemd
sudo tee /etc/containers/systemd/web.container >/dev/null <<'EOF'
[Unit]
Description=httpd container
After=network-online.target
Wants=network-online.target

[Container]
Image=registry.access.redhat.com/ubi9/httpd-24
ContainerName=web
PublishPort=8080:8080
Volume=/srv/webcontent:/var/www/html:Z

[Service]
Restart=always

[Install]
WantedBy=multi-user.target default.target
EOF

sudo systemctl daemon-reload
sudo systemctl start web
systemctl status web
```

```bash
# Rootless
mkdir -p ~/.config/containers/systemd
vim ~/.config/containers/systemd/web.container
systemctl --user daemon-reload
systemctl --user start web
loginctl enable-linger $(whoami)
```

| | Rootful | Rootless |
| --- | --- | --- |
| Directory | **`/etc/containers/systemd/`** | **`~/.config/containers/systemd/`** |
| Reload | `sudo systemctl daemon-reload` | `systemctl --user daemon-reload` |
| Unit name | **`web.service`** from `web.container` | Same |
| Lingering | Not needed | **Required** |

**Quadlet units are generated at `daemon-reload`, not installed.** So:

- **There is no `systemctl enable`.** `WantedBy=` in the `[Install]` section does the enabling when the unit is generated.
- **`daemon-reload` after every edit**, or systemd does not see the change.
- **The service name drops `.container`**: `web.container` becomes `web.service`.

```bash
systemctl cat web.service                      # see the generated unit
/usr/lib/systemd/system-generators/podman-system-generator --dryrun
```

Common `[Container]` keys:

| Key | Equivalent |
| --- | --- |
| **`Image=`** | The image |
| **`ContainerName=`** | `--name` |
| **`PublishPort=8080:8080`** | `-p` |
| **`Volume=/host:/ctr:Z`** | `-v` |
| **`Environment=KEY=value`** | `-e` |
| `EnvironmentFile=` | `--env-file` |
| `Exec=` | The command to run |
| `User=`, `Group=` | `-u` |
| `Network=` | `--network` |
| `AutoUpdate=registry` | `--label io.containers.autoupdate` |

### The complete rootful workflow

```bash
# 1. Pull as root — rootful storage
sudo podman pull registry.access.redhat.com/ubi9/httpd-24

# 2. Prepare persistent storage
sudo mkdir -p /srv/webcontent
echo "<h1>Container as a service</h1>" | sudo tee /srv/webcontent/index.html
sudo semanage fcontext -a -t container_file_t "/srv/webcontent(/.*)?"
sudo restorecon -Rv /srv/webcontent

# 3. Test the container by hand first
sudo podman run -d --name web -p 8080:8080 \
  -v /srv/webcontent:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24
curl http://localhost:8080

# 4. Generate the unit
cd /etc/systemd/system
sudo podman generate systemd --new --name web --files
sudo systemctl daemon-reload

# 5. Remove the manual container and let systemd own it
sudo podman rm -f web
sudo systemctl enable --now container-web
systemctl status container-web
sudo podman ps

# 6. Firewall
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# 7. Verify
curl http://localhost:8080
systemctl is-enabled container-web
sudo reboot
```

### The complete rootless workflow

```bash
# As the user
podman pull registry.access.redhat.com/ubi9/httpd-24
mkdir -p ~/webcontent
echo "<h1>Rootless container service</h1>" > ~/webcontent/index.html

podman run -d --name web -p 8080:8080 -v ~/webcontent:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24
curl http://localhost:8080

mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --new --name web --files
systemctl --user daemon-reload

podman rm -f web
systemctl --user enable --now container-web
systemctl --user status container-web

# CRITICAL
loginctl enable-linger $(whoami)
loginctl show-user $(whoami) | grep -i linger

sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### Verification checklist

```bash
# Rootful
systemctl is-enabled container-web
systemctl is-active container-web
sudo podman ps
curl http://localhost:8080

# Rootless
systemctl --user is-enabled container-web
systemctl --user is-active container-web
loginctl show-user $(whoami) | grep -i linger
podman ps
curl http://localhost:8080

# Quadlet
systemctl status web.service
systemctl cat web.service
```

**And the only test that matters:**

```bash
sudo reboot
# then check the container is running WITHOUT starting it by hand
```

### Restart policy

```text
[Service]
Restart=always
RestartSec=5
```

| Value | Behaviour |
| --- | --- |
| `no` | Never restart |
| `on-failure` | Restart on a non-zero exit |
| **`always`** | **Always restart** |
| `on-abnormal` | On a signal or timeout |

**`podman generate systemd --new` writes `Restart=on-failure` by default**, which is usually fine. `--restart-policy=always` changes it:

```bash
sudo podman generate systemd --new --restart-policy=always --name web --files
```

**Do not use `podman run --restart=always` as a substitute for a unit** — without a daemon there is nothing to honour it at boot.

## Tasks

**Task 1.** Demonstrate that a container started with `podman run -d` does not survive a reboot.

**Task 2.** Create a rootful systemd unit for a container so it starts automatically at boot, using `podman generate systemd`.

**Task 3.** Verify the rootful container service survives a reboot.

**Task 4.** Explain the difference between `podman generate systemd` with and without `--new`, and show why `--new` is preferred.

**Task 5.** Create a rootless systemd unit for a container run by the user `alice`, so it starts at boot.

**Task 6.** Explain and configure the one additional step a rootless container service requires, and prove it is necessary.

**Task 7.** Verify the rootless container service survives a reboot and a logout.

**Task 8.** Configure the same container using a Quadlet `.container` file, rootful.

**Task 9.** Configure a Quadlet container rootless, and show where the generated unit comes from.

**Task 10.** Create a container service with persistent storage, a published port, and environment variables, all defined in the unit.

**Task 11.** Configure a container service with a restart policy so it recovers from a crash.

**Task 12.** Stop, start, and check the status of a container service, and show why `podman stop` is the wrong tool once systemd owns it.

**Task 13.** Read the logs of a container service two different ways.

**Task 14.** Diagnose: `systemctl status container-web` reports the unit failed at boot.

**Task 15.** Diagnose: a rootless container service works, but after a reboot the container is not running.

**Task 16.** Diagnose: a Quadlet unit does not appear in `systemctl` at all.

**Task 17.** Remove a container service completely.

**Task 18.** Verify every container service configuration survives a reboot.

---

## Solutions

**Task 1.**

```bash
sudo podman pull registry.access.redhat.com/ubi9/httpd-24
sudo podman run -d --name web -p 8080:8080 registry.access.redhat.com/ubi9/httpd-24
sudo podman ps
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080
```

```text
200
```

```bash
sudo reboot
```

After the reboot:

```bash
sudo podman ps
```

```text
CONTAINER ID  IMAGE  COMMAND  CREATED  STATUS  PORTS  NAMES
```

```bash
sudo podman ps -a
```

```text
CONTAINER ID  IMAGE                     COMMAND             CREATED    STATUS                     NAMES
9c1b2d5a8f3e  .../ubi9/httpd-24:latest  /usr/bin/run-httpd  5 min ago  Exited (255) 2 minutes ago web
```

```bash
curl http://localhost:8080
```

```text
curl: (7) Failed to connect to localhost port 8080: Connection refused
```

**The container definition survived; the running process did not.**

**Podman has no daemon.** The container was a child of the `podman` process that started it. When the machine shut down, the process ended, and nothing at boot brings it back:

```bash
systemctl list-units | grep -i podman
```

There is no `podman.service` supervising containers. Contrast with Docker, where `dockerd` starts at boot and honours `--restart=always`.

**And `--restart=always` does not help:**

```bash
sudo podman run -d --restart=always --name web2 -p 8081:8080 <image>
sudo reboot
sudo podman ps                             # STILL empty
```

**`--restart=always` only applies while podman is watching.** At boot there is nothing to watch.

```text
   podman run -d                    ≈  systemctl start   (not enable)
   a systemd unit + enable          ≈  systemctl enable  (survives a reboot)
```

**So every container task that mentions boot, "as a service", or "automatically" needs a systemd unit.** That is the whole point of this file.

```bash
sudo podman start web                      # a manual restart works
curl http://localhost:8080
sudo podman rm -f web web2
```

**Task 2.**

```bash
# 1. Pull as root — rootful storage
sudo podman pull registry.access.redhat.com/ubi9/httpd-24

# 2. Run it once, to establish the configuration
sudo podman run -d --name web -p 8080:8080 registry.access.redhat.com/ubi9/httpd-24
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080
```

```bash
# 3. Generate the unit, in the right directory
cd /etc/systemd/system
sudo podman generate systemd --new --name web --files
```

```text
/etc/systemd/system/container-web.service
```

```bash
sudo cat /etc/systemd/system/container-web.service
```

```ini
# container-web.service
# autogenerated by Podman 5.2.2

[Unit]
Description=Podman container-web.service
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon \
    --rm --sdnotify=conmon -d --replace --name web -p 8080:8080 \
    registry.access.redhat.com/ubi9/httpd-24
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=default.target
```

```bash
# 4. Reload, remove the manual container, hand it to systemd
sudo systemctl daemon-reload
sudo podman rm -f web
sudo systemctl enable --now container-web
```

```text
Created symlink /etc/systemd/system/default.target.wants/container-web.service → /etc/systemd/system/container-web.service.
```

```bash
# 5. Verify
systemctl status container-web
systemctl is-enabled container-web
systemctl is-active container-web
sudo podman ps
curl http://localhost:8080
```

```text
enabled
active
```

```bash
# 6. Firewall
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

**Five details that decide whether this scores:**

1. **`cd /etc/systemd/system` first.** `--files` writes into the current directory. Running it from your home directory leaves the unit where systemd will not find it:

```bash
sudo podman generate systemd --new --name web > /etc/systemd/system/container-web.service   # alternative
```

2. **`--new`.** Without it the unit starts an existing container, which breaks the moment that container is removed. See Task 4.

3. **`daemon-reload` after writing the unit.** systemd does not notice new files by itself.

4. **`enable`, not just `start`.** `enable` is what creates the boot-time symlink. `enable --now` does both.

5. **Remove the manual container first.** The `--new` unit creates its own, and `--replace` in the generated `ExecStart` handles a name clash, but removing it is cleaner.

**Note `WantedBy=default.target`** rather than `multi-user.target`. Both work for a rootful unit, since `default.target` is normally a symlink to `multi-user.target`:

```bash
systemctl get-default
```

**Task 3.**

Before the reboot:

```bash
systemctl is-enabled container-web
systemctl is-active container-web
sudo podman ps
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080
sudo firewall-cmd --permanent --list-ports
```

```text
enabled
active
200
8080/tcp
```

```bash
sudo reboot
```

After — and **do not start anything by hand:**

```bash
systemctl status container-web
sudo podman ps
curl http://localhost:8080
```

```text
● container-web.service - Podman container-web.service
     Loaded: loaded (/etc/systemd/system/container-web.service; enabled)
     Active: active (running) since Tue 2026-08-18 18:05:12 EAT; 45s ago
```

```text
CONTAINER ID  IMAGE                     STATUS         PORTS                   NAMES
7f3a9c2b1d4e  .../ubi9/httpd-24:latest  Up 40 seconds  0.0.0.0:8080->8080/tcp  web
```

**Note the container ID differs from before the reboot.** With `--new`, systemd creates a *fresh* container each start rather than restarting the old one. That is correct and expected.

If it is not running:

```bash
systemctl status container-web
systemctl is-enabled container-web             # 'disabled' means you never enabled it
journalctl -u container-web -b
journalctl -xeu container-web
sudo podman ps -a
sudo podman logs web
systemctl --failed
```

| Symptom | Cause |
| --- | --- |
| `is-enabled: disabled` | **`enable` was never run** |
| Unit not found | **Unit file in the wrong directory, or no `daemon-reload`** |
| `Active: failed` | The container itself failed — check `podman logs` |
| Active but unreachable remotely | **Firewall rule not `--permanent`** |
| Active but the port is wrong | Wrong `-p` in the generated `ExecStart` |

**`systemctl is-enabled` is the check that predicts the reboot.** `is-active` only tells you about now.

**Task 4.**

Without `--new`:

```bash
sudo podman run -d --name web1 -p 8081:8080 registry.access.redhat.com/ubi9/httpd-24
cd /etc/systemd/system
sudo podman generate systemd --name web1 --files
sudo grep -E 'ExecStart|ExecStop' container-web1.service
```

```text
ExecStart=/usr/bin/podman start web1
ExecStop=/usr/bin/podman stop -t 10 web1
```

With `--new`:

```bash
sudo podman run -d --name web2 -p 8082:8080 registry.access.redhat.com/ubi9/httpd-24
sudo podman generate systemd --new --name web2 --files
sudo grep -E 'ExecStart|ExecStop' container-web2.service
```

```text
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon --rm \
    --sdnotify=conmon -d --replace --name web2 -p 8082:8080 \
    registry.access.redhat.com/ubi9/httpd-24
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
```

**Now break both by removing the containers:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable container-web1 container-web2
sudo podman rm -f web1 web2

sudo systemctl start container-web1
```

```text
Job for container-web1.service failed because the control process exited with error code.
```

```bash
sudo journalctl -u container-web1 -n 5
```

```text
podman[3421]: Error: no container with name or ID "web1" found: no such container
```

```bash
sudo systemctl start container-web2
sudo podman ps
```

```text
CONTAINER ID  IMAGE                     STATUS        PORTS                   NAMES
8a2b3c4d5e6f  .../ubi9/httpd-24:latest  Up 3 seconds  0.0.0.0:8082->8080/tcp  web2
```

**The `--new` unit recreated the container from scratch. The other one could not.**

| | **Without `--new`** | **With `--new`** |
| --- | --- | --- |
| `ExecStart` | `podman start <name>` | **`podman run ...` with the full command line** |
| Requires the container to exist | **Yes** | **No** |
| Survives `podman rm` | **No** | **Yes** |
| Self-contained | No | **Yes** |
| Fresh container each start | No | **Yes** |
| Portable to another host | No | **Yes** |
| **Recommended** | No | **Yes** |

**Always use `--new`.** The unit then records the entire `podman run` command — image, ports, volumes, environment — so it is a complete description that does not depend on any pre-existing container.

**And `--new` makes the unit editable.** To change a port or add a volume, edit `ExecStart`:

```bash
sudo vim /etc/systemd/system/container-web2.service
sudo systemctl daemon-reload
sudo systemctl restart container-web2
```

Clean up:

```bash
sudo systemctl disable --now container-web1 container-web2
sudo rm -f /etc/systemd/system/container-web{1,2}.service
sudo systemctl daemon-reload
sudo podman rm -f web1 web2 2>/dev/null
```

**Task 5.**

```bash
sudo useradd alice 2>/dev/null
sudo passwd alice
su - alice
```

**Everything from here runs as alice, in her own session:**

```bash
whoami
podman info --format '{{.Host.Security.Rootless}}'
podman pull registry.access.redhat.com/ubi9/httpd-24

mkdir -p ~/webcontent
echo "<h1>Rootless service for alice</h1>" > ~/webcontent/index.html

podman run -d --name web -p 8080:8080 -v ~/webcontent:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24
podman ps
curl -s http://localhost:8080
```

Generate the user unit:

```bash
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --new --name web --files
ls -l ~/.config/systemd/user/
```

```text
/home/alice/.config/systemd/user/container-web.service
```

```bash
systemctl --user daemon-reload
podman rm -f web
systemctl --user enable --now container-web
systemctl --user status container-web
podman ps
curl -s http://localhost:8080
```

**And the step this task exists to teach:**

```bash
loginctl enable-linger alice
loginctl show-user alice | grep -i linger
```

```text
Linger=yes
```

**Every difference from the rootful case:**

| | Rootful | **Rootless** |
| --- | --- | --- |
| Unit directory | `/etc/systemd/system/` | **`~/.config/systemd/user/`** |
| Commands | `sudo systemctl` | **`systemctl --user`** |
| Reload | `sudo systemctl daemon-reload` | **`systemctl --user daemon-reload`** |
| Enable | `sudo systemctl enable --now` | **`systemctl --user enable --now`** |
| **Lingering** | **Not applicable** | **`loginctl enable-linger USER` — REQUIRED** |
| Storage | `/var/lib/containers` | `~/.local/share/containers` |
| Ports < 1024 | Allowed | **Refused** |
| `WantedBy` | `default.target` | `default.target` |

**Three things that trip people up:**

1. **Use `su - alice`, not `sudo -u alice`.** The `-` gives a full login session with `XDG_RUNTIME_DIR` set, which `systemctl --user` needs:

```bash
sudo -u alice systemctl --user status container-web
# Failed to connect to bus: No medium found
```

```bash
su - alice -c 'systemctl --user status container-web'      # works
```

2. **Never `sudo systemctl --user`.** It targets root's user manager, not alice's.

3. **`loginctl enable-linger` requires root** if run for another user:

```bash
sudo loginctl enable-linger alice                # from your own account
loginctl enable-linger                           # as alice, for herself
```

**Task 6.**

The additional step is **lingering**.

```bash
loginctl show-user alice | grep -i linger
```

```text
Linger=no
```

**Prove it is necessary.** With `Linger=no`, log alice out:

```bash
su - alice -c 'systemctl --user is-active container-web'
```

```text
active
```

```bash
# End every session alice has
sudo loginctl terminate-user alice
sleep 3
sudo podman ps -a                                # nothing here (rootful store)
sudo -u alice podman ps 2>/dev/null
ps -u alice
```

```text
(no podman processes)
```

**The container stopped when the last session ended.** And after a reboot it never starts at all.

```bash
sudo loginctl enable-linger alice
loginctl show-user alice | grep -i linger
ls -l /var/lib/systemd/linger/
```

```text
Linger=yes
-rw-r--r--. 1 root root 0 Aug 18 18:20 alice
```

```bash
su - alice -c 'systemctl --user start container-web'
sudo loginctl terminate-user alice
sleep 3
ps -u alice | grep -c conmon                     # the container is STILL running
curl -s http://localhost:8080
```

**Why it works this way.** systemd starts a per-user manager, `user@UID.service`, when a user logs in and stops it when the last session ends — taking every user unit with it. **Lingering tells systemd to start that manager at boot and keep it running regardless of sessions:**

```bash
systemctl status user@$(id -u alice).service
loginctl list-users
loginctl user-status alice 2>/dev/null
```

```text
● user@1001.service - User Manager for UID 1001
     Loaded: loaded (/usr/lib/systemd/system/user@.service; static)
     Active: active (running)
```

| Command | Effect |
| --- | --- |
| **`loginctl enable-linger USER`** | **The user manager starts at boot and persists after logout** |
| `loginctl disable-linger USER` | Revert |
| `loginctl show-user USER \| grep Linger` | Check |
| `ls /var/lib/systemd/linger/` | **The persistent marker files** |

**`/var/lib/systemd/linger/<username>` is the on-disk artifact**, so this is genuinely persistent.

**This is the most commonly missed step in the whole objective.** The symptom is cruel: everything works while you are logged in, verification passes, and the container is dead after the grader's reboot.

```bash
# Do this for EVERY rootless container service
sudo loginctl enable-linger alice
loginctl show-user alice | grep -i linger        # must say yes
```

**Task 7.**

Before the reboot, as root:

```bash
su - alice -c 'systemctl --user is-enabled container-web'
su - alice -c 'systemctl --user is-active container-web'
loginctl show-user alice | grep -i linger
ls -l /var/lib/systemd/linger/
ls -l /home/alice/.config/systemd/user/
sudo firewall-cmd --permanent --list-ports
```

```text
enabled
active
Linger=yes
```

All four must hold:

- The user unit exists in `~/.config/systemd/user/`.
- **`systemctl --user is-enabled` says `enabled`.**
- **`Linger=yes`.**
- The firewall port is in the permanent set.

```bash
sudo reboot
```

After the reboot, **without logging in as alice:**

```bash
sudo loginctl list-users
systemctl status user@$(id -u alice).service
ps -u alice
curl -s http://localhost:8080
```

```text
UID USER  LINGER STATE
1001 alice yes    lingering

● user@1001.service - User Manager for UID 1001
     Active: active (running)

<h1>Rootless service for alice</h1>
```

**The container is running and nobody has logged in.** Lingering did its job.

Confirm from alice's own view:

```bash
su - alice -c 'podman ps'
su - alice -c 'systemctl --user status container-web'
```

Test the logout case as well:

```bash
sudo loginctl terminate-user alice
sleep 3
curl -s http://localhost:8080                    # still responds
ps -u alice | grep conmon
```

If it is not running after the reboot, check in this order:

```bash
loginctl show-user alice | grep -i linger        # 1. lingering — the usual cause
su - alice -c 'systemctl --user is-enabled container-web'   # 2. enabled?
ls -l /home/alice/.config/systemd/user/          # 3. is the unit there?
su - alice -c 'journalctl --user -u container-web -b'       # 4. what happened?
systemctl status user@$(id -u alice).service     # 5. is her manager running?
```

| Symptom | Cause |
| --- | --- |
| **`Linger=no`** | **`loginctl enable-linger` never run** — the commonest |
| `is-enabled: disabled` | `systemctl --user enable` never run |
| Unit not found | Wrong directory, or no `--user daemon-reload` |
| `user@UID.service` inactive | Lingering off |
| Runs but unreachable | Firewall, or a port below 1024 attempted |

**Task 8.**

```bash
sudo mkdir -p /etc/containers/systemd
sudo mkdir -p /srv/webcontent
echo "<h1>Quadlet rootful container</h1>" | sudo tee /srv/webcontent/index.html

sudo semanage fcontext -a -t container_file_t "/srv/webcontent(/.*)?"
sudo restorecon -Rv /srv/webcontent
ls -Zd /srv/webcontent
```

```bash
sudo tee /etc/containers/systemd/web.container >/dev/null <<'EOF'
[Unit]
Description=httpd container managed by Quadlet
After=network-online.target
Wants=network-online.target

[Container]
Image=registry.access.redhat.com/ubi9/httpd-24
ContainerName=web
PublishPort=8080:8080
Volume=/srv/webcontent:/var/www/html:Z

[Service]
Restart=always
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target default.target
EOF
```

```bash
sudo systemctl daemon-reload
sudo systemctl start web
systemctl status web
sudo podman ps
curl http://localhost:8080
```

```text
● web.service - httpd container managed by Quadlet
     Loaded: loaded (/etc/containers/systemd/web.container; generated)
     Active: active (running)
```

**Note `Loaded: ... ; generated`.** The unit was produced from your `.container` file by a systemd generator:

```bash
systemctl cat web.service
ls -l /run/systemd/generator/web.service
/usr/lib/systemd/system-generators/podman-system-generator --dryrun
```

```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
sudo reboot
# after:
systemctl status web
curl http://localhost:8080
```

**Four things that differ from `podman generate systemd`:**

1. **The file goes in `/etc/containers/systemd/`, not `/etc/systemd/system/`.**

2. **The service name drops `.container`.** `web.container` produces `web.service`, so all systemctl commands use `web`:

```bash
sudo systemctl start web
systemctl status web
```

3. **There is no `systemctl enable`.** The unit is generated at each `daemon-reload`, and **`WantedBy=` in `[Install]` does the enabling:**

```bash
sudo systemctl enable web
# Failed to enable unit: Unit file /run/systemd/generator/web.service is transient or generated.
```

**That error is expected and is not a problem.** Omitting `WantedBy=` is the actual mistake — the unit then exists but never starts at boot.

4. **`daemon-reload` after every edit**, or the generator does not re-run.

| | `podman generate systemd` | **Quadlet** |
| --- | --- | --- |
| File | `/etc/systemd/system/container-web.service` | **`/etc/containers/systemd/web.container`** |
| Written by | podman, from a running container | **You, by hand** |
| Service name | `container-web.service` | **`web.service`** |
| `systemctl enable` | **Required** | **Not possible — use `WantedBy=`** |
| Needs an existing container | For generation, yes | **No** |
| Status in Podman 5 | **Deprecated** | **Preferred** |

**Quadlet is declarative** — the `.container` file is the configuration, editable directly, with no need to run a container first.

**Task 9.**

```bash
su - alice
mkdir -p ~/.config/containers/systemd
mkdir -p ~/webcontent
echo "<h1>Rootless Quadlet</h1>" > ~/webcontent/index.html

tee ~/.config/containers/systemd/web.container >/dev/null <<'EOF'
[Unit]
Description=Rootless httpd container via Quadlet
After=network-online.target

[Container]
Image=registry.access.redhat.com/ubi9/httpd-24
ContainerName=web
PublishPort=8080:8080
Volume=%h/webcontent:/var/www/html:Z

[Service]
Restart=always

[Install]
WantedBy=default.target
EOF
```

```bash
systemctl --user daemon-reload
systemctl --user start web
systemctl --user status web
podman ps
curl -s http://localhost:8080
```

Where the generated unit lives:

```bash
systemctl --user cat web.service
ls -l /run/user/$(id -u)/systemd/generator/
```

```text
# /run/user/1001/systemd/generator/web.service
[Unit]
Description=Rootless httpd container via Quadlet
SourcePath=/home/alice/.config/containers/systemd/web.container
...
[Service]
ExecStart=/usr/bin/podman run --name=web --cidfile=... \
  --publish 8080:8080 --volume /home/alice/webcontent:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24
```

```bash
/usr/libexec/podman/quadlet -user -dryrun 2>/dev/null || \
  /usr/lib/systemd/user-generators/podman-user-generator --dryrun
```

**And lingering, still required:**

```bash
exit
sudo loginctl enable-linger alice
loginctl show-user alice | grep -i linger
```

**Rootless Quadlet in summary:**

| Element | Value |
| --- | --- |
| Source file | **`~/.config/containers/systemd/web.container`** |
| Generated unit | `/run/user/UID/systemd/generator/web.service` |
| Reload | **`systemctl --user daemon-reload`** |
| Start | `systemctl --user start web` |
| Enable | **Not possible — `WantedBy=default.target`** |
| **Lingering** | **`loginctl enable-linger alice` — REQUIRED** |

**`%h` expands to the user's home directory**, which keeps the file portable:

```text
Volume=%h/webcontent:/var/www/html:Z
```

Other specifiers: `%t` runtime directory, `%n` unit name, `%u` user name, `%U` UID.

**Note the generated unit lives in `/run`, which is a tmpfs**, so it is recreated at every boot from your `.container` file. Editing the generated file achieves nothing:

```bash
# WRONG
sudo vim /run/user/1001/systemd/generator/web.service

# RIGHT
vim ~/.config/containers/systemd/web.container
systemctl --user daemon-reload
systemctl --user restart web
```

**Task 10.**

With Quadlet, all in one declarative file:

```bash
sudo mkdir -p /etc/containers/systemd
sudo mkdir -p /srv/dbdata
sudo semanage fcontext -a -t container_file_t "/srv/dbdata(/.*)?"
sudo restorecon -Rv /srv/dbdata

sudo tee /etc/containers/systemd/db.container >/dev/null <<'EOF'
[Unit]
Description=MariaDB container
After=network-online.target
Wants=network-online.target

[Container]
Image=registry.redhat.io/rhel9/mariadb-105
ContainerName=db
PublishPort=3306:3306
Volume=/srv/dbdata:/var/lib/mysql/data:Z
Environment=MYSQL_ROOT_PASSWORD=redhat123
Environment=MYSQL_DATABASE=appdb
Environment=MYSQL_USER=appuser
Environment=MYSQL_PASSWORD=apppass

[Service]
Restart=always
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target default.target
EOF

sudo systemctl daemon-reload
sudo systemctl start db
systemctl status db
```

Verify all three aspects:

```bash
sudo podman ps
sudo podman port db
sudo podman exec db env | grep -i mysql
sudo podman exec db mysql -uroot -predhat123 -e 'SHOW DATABASES;'
sudo ls -lZ /srv/dbdata/
```

```bash
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload
```

The equivalent with `podman generate systemd`:

```bash
sudo podman run -d --name db \
  -p 3306:3306 \
  -v /srv/dbdata:/var/lib/mysql/data:Z \
  -e MYSQL_ROOT_PASSWORD=redhat123 \
  -e MYSQL_DATABASE=appdb \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=apppass \
  registry.redhat.io/rhel9/mariadb-105

cd /etc/systemd/system
sudo podman generate systemd --new --name db --files
sudo systemctl daemon-reload
sudo podman rm -f db
sudo systemctl enable --now container-db
```

**`--new` records the entire command line into `ExecStart`**, including every `-e`, `-v`, and `-p`:

```bash
sudo grep ExecStart /etc/systemd/system/container-db.service
```

**Prove persistence properly — data, port, and environment must all survive:**

```bash
sudo podman exec db mysql -uroot -predhat123 -e \
  'CREATE TABLE appdb.t (id INT); INSERT INTO appdb.t VALUES (42);'
sudo reboot
```

```bash
systemctl status db
sudo podman exec db mysql -uroot -predhat123 -e 'SELECT * FROM appdb.t;'
```

```text
+------+
| id   |
+------+
|   42 |
+------+
```

**The data survived because it is in `/srv/dbdata` on the host, not in the container.** Without the volume, `Restart=always` recreating the container would lose the database every time.

The Quadlet keys for each requirement:

| Requirement | Quadlet key | `podman run` flag |
| --- | --- | --- |
| Persistent storage | **`Volume=/host:/ctr:Z`** | `-v /host:/ctr:Z` |
| Published port | **`PublishPort=3306:3306`** | `-p 3306:3306` |
| Environment | **`Environment=KEY=value`** | `-e KEY=value` |
| From a file | `EnvironmentFile=/etc/db.env` | `--env-file` |
| Name | `ContainerName=db` | `--name db` |

**Keep secrets out of a world-readable unit:**

```bash
sudo tee /etc/containers/db.env >/dev/null <<'EOF'
MYSQL_ROOT_PASSWORD=redhat123
MYSQL_DATABASE=appdb
EOF
sudo chmod 600 /etc/containers/db.env
```

```text
[Container]
EnvironmentFile=/etc/containers/db.env
```

**Task 11.**

Quadlet:

```text
[Service]
Restart=always
RestartSec=5
```

```bash
sudo sed -i 's/^Restart=.*/Restart=always/' /etc/containers/systemd/web.container
grep -A3 '\[Service\]' /etc/containers/systemd/web.container
sudo systemctl daemon-reload
sudo systemctl restart web
systemctl show web -p Restart
```

```text
Restart=always
```

For `podman generate systemd`:

```bash
sudo podman generate systemd --new --restart-policy=always --name web --files
sudo grep '^Restart=' /etc/systemd/system/container-web.service
```

Or by editing:

```bash
sudo systemctl edit container-web
```

```ini
[Service]
Restart=always
RestartSec=5
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart container-web
systemctl show container-web -p Restart
```

**Test it by killing the container out from under systemd:**

```bash
sudo podman ps
sudo systemctl status web | grep -i active
sudo podman kill web
sleep 8
sudo podman ps
systemctl status web
```

```text
Active: active (running) since ...; 3s ago
```

**systemd noticed the container died and restarted it.** The journal records it:

```bash
sudo journalctl -u web -n 20
```

```text
systemd[1]: web.service: Main process exited, code=exited, status=137
systemd[1]: web.service: Scheduled restart job, restart counter is at 1.
systemd[1]: Started httpd container managed by Quadlet.
```

| `Restart=` | Restarts after |
| --- | --- |
| `no` | Never |
| `on-success` | A clean exit only |
| **`on-failure`** | **A non-zero exit, signal, or timeout. The `generate systemd` default** |
| `on-abnormal` | A signal or timeout |
| **`always`** | **Any exit, clean or not** |

**`always` for a service that must always run; `on-failure` if a clean exit is meaningful.** For a web server, `always`.

Rate limiting protects against a crash loop:

```ini
[Unit]
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Restart=always
RestartSec=10
```

```text
Failed to start web.service: Unit web.service is not active, cannot reload.
web.service: Start request repeated too quickly.
```

```bash
sudo systemctl reset-failed web
sudo systemctl start web
```

**`systemctl reset-failed` clears the counter** when a unit has hit its start limit — worth knowing, because otherwise the unit refuses to start with a confusing message.

**And do not use `podman run --restart=always` as a substitute:**

```bash
sudo podman run -d --restart=always --name web <image>
sudo reboot
sudo podman ps                                   # empty
```

**There is no daemon to honour it at boot.** Only a systemd unit works.

**Task 12.**

```bash
sudo systemctl status web
sudo systemctl stop web
sudo podman ps                                   # gone
systemctl status web
sudo systemctl start web
sudo podman ps                                   # back
sudo systemctl restart web
systemctl is-active web
systemctl is-enabled web 2>&1
```

**Now the wrong way:**

```bash
sudo systemctl status web | grep -i active
sudo podman stop web
sleep 8
sudo podman ps
systemctl status web
```

```text
Active: active (running) since ...; 5s ago
```

**The container came straight back**, because `Restart=always` means systemd treats your `podman stop` as a failure and restarts it. With `Restart=no` you get the opposite problem:

```text
● web.service - httpd container
     Active: failed (Result: exit-code)
```

**systemd now believes the service has failed**, when in fact you stopped it deliberately. Its state and reality have diverged.

**Once systemd owns a container, manage it through systemd:**

| Intent | **Correct** | Wrong |
| --- | --- | --- |
| Stop | **`systemctl stop web`** | `podman stop web` |
| Start | **`systemctl start web`** | `podman start web` |
| Restart | **`systemctl restart web`** | `podman restart web` |
| Status | **`systemctl status web`** | `podman ps` alone |
| Remove | **`systemctl disable --now`** then delete the unit | `podman rm` |
| Logs | **`journalctl -u web`** | `podman logs` (still useful) |

**`podman` commands remain fine for inspection:**

```bash
sudo podman ps
sudo podman logs web
sudo podman exec -it web /bin/bash
sudo podman inspect web
sudo podman stats --no-stream web
```

**Inspect with podman; control with systemctl.**

Repairing a divergence:

```bash
systemctl status web                             # what systemd thinks
sudo podman ps -a                                # what is actually there
sudo systemctl reset-failed web
sudo systemctl restart web
systemctl status web
sudo podman ps
```

For rootless, the same logic with `--user`:

```bash
su - alice -c 'systemctl --user stop web'
su - alice -c 'systemctl --user start web'
su - alice -c 'systemctl --user status web'
```

**Task 13.**

**Through the journal — the systemd view:**

```bash
sudo journalctl -u web
sudo journalctl -u web -n 30
sudo journalctl -u web -f
sudo journalctl -xeu web
sudo journalctl -u web -b
sudo journalctl -u web --since '10 min ago'
sudo journalctl -u web -p err
```

```text
systemd[1]: Starting httpd container managed by Quadlet...
podman[2341]: 9c1b2d5a8f3e...
systemd[1]: Started httpd container managed by Quadlet.
web[2350]: => sourcing 10-set-mpm.sh ...
web[2350]: AH00558: httpd: Could not reliably determine the server's FQDN
web[2350]: [core:notice] AH00094: Command line: 'httpd -D FOREGROUND'
```

**Through podman — the container's own output:**

```bash
sudo podman logs web
sudo podman logs -f web
sudo podman logs --tail 20 web
sudo podman logs --since 10m web
sudo podman logs -t web
```

| | **`journalctl -u web`** | **`podman logs web`** |
| --- | --- | --- |
| Shows | **systemd events AND container output** | **Only the container's stdout/stderr** |
| Start and stop events | **Yes** | No |
| Restart and failure records | **Yes** | No |
| History across restarts | **Yes** | Only the current container |
| Survives `podman rm` | **Yes** | **No** |
| Needs the container to exist | No | Yes |

**Use `journalctl -xeu UNIT` when the service will not start** — it shows why systemd gave up, which `podman logs` cannot:

```bash
sudo journalctl -xeu web
```

```text
podman[3421]: Error: statfs /srv/nonexistent: no such file or directory
systemd[1]: web.service: Main process exited, code=exited, status=125
systemd[1]: web.service: Failed with result 'exit-code'.
```

**Use `podman logs` when the container starts but the application misbehaves:**

```bash
sudo podman logs web | grep -i error
```

Rootless:

```bash
su - alice -c 'journalctl --user -u web -n 30'
su - alice -c 'podman logs web'
```

**`journalctl --user` for a user unit.** Without `--user` you search the system journal and find nothing.

**The rule: `journalctl -xeu` for "it will not start"; `podman logs` for "it started but does not work".**

**Task 14.**

```bash
systemctl status container-web
```

```text
● container-web.service - Podman container-web.service
     Loaded: loaded (/etc/systemd/system/container-web.service; enabled)
     Active: failed (Result: exit-code) since Tue 2026-08-18 18:40:02 EAT
    Process: 3421 ExecStart=/usr/bin/podman run ... (code=exited, status=125)
```

```bash
sudo journalctl -xeu container-web
```

Read the actual error. The common ones:

**Cause 1 — the volume path does not exist:**

```text
Error: statfs /srv/webcontent: no such file or directory
```

```bash
sudo mkdir -p /srv/webcontent
sudo semanage fcontext -a -t container_file_t "/srv/webcontent(/.*)?"
sudo restorecon -Rv /srv/webcontent
sudo systemctl restart container-web
```

**Cause 2 — the port is already taken:**

```text
Error: rootlessport listen tcp 0.0.0.0:8080: bind: address already in use
```

```bash
ss -tlnp | grep 8080
sudo podman ps -a
sudo podman rm -f web                            # a leftover manual container
sudo systemctl restart container-web
```

**Cause 3 — the image is not present in the right store:**

```text
Error: short-name resolution enforced but cannot prompt without a TTY
Error: initializing source docker://...: pinging container registry: dial tcp: lookup ... no such host
```

```bash
sudo podman images                               # ROOT's store, for a rootful unit
sudo podman pull registry.access.redhat.com/ubi9/httpd-24
sudo systemctl restart container-web
```

**A rootful unit needs the image in root's store.** Pulling as your user does not help — see `34-podman-images-running.md`.

**Cause 4 — a name clash:**

```text
Error: creating container storage: the container name "web" is already in use
```

```bash
sudo podman ps -a
sudo podman rm -f web
sudo systemctl restart container-web
```

`--new` units include `--replace`, which handles this, but a unit generated without it does not.

**Cause 5 — SELinux on a bind mount:**

```bash
sudo ausearch -m AVC -ts recent
ls -Zd /srv/webcontent
sudo grep Volume /etc/containers/systemd/web.container
```

Add `:Z`, or set the label persistently:

```bash
sudo semanage fcontext -a -t container_file_t "/srv/webcontent(/.*)?"
sudo restorecon -Rv /srv/webcontent
```

**Cause 6 — the container starts and immediately exits:**

```bash
sudo podman logs web
```

```text
You must either specify the following environment variables: MYSQL_USER ...
```

Add the missing `Environment=` lines.

**The diagnostic sequence:**

```bash
# 1. What does systemd say?
systemctl status container-web
sudo journalctl -xeu container-web | tail -30

# 2. Does the exact podman command work by hand?
sudo grep ExecStart /etc/systemd/system/container-web.service
sudo podman run --rm -it <the same arguments>     # run it manually

# 3. What did the container itself say?
sudo podman logs web

# 4. Prerequisites
sudo podman images                               # image present, right store?
ls -Zd /srv/webcontent                           # volume path and label?
ss -tlnp | grep 8080                             # port free?
sudo ausearch -m AVC -ts recent                  # SELinux?

# 5. Retry
sudo systemctl reset-failed container-web
sudo systemctl restart container-web
```

**Step 2 is the most productive.** Copy the `ExecStart` command out of the unit and run it by hand — the error is usually immediate and obvious, and you avoid guessing.

**Task 15.**

```bash
su - alice -c 'systemctl --user status container-web'
```

Before the reboot it was `active`. After the reboot:

```bash
su - alice -c 'systemctl --user status container-web'
```

```text
● container-web.service
     Loaded: loaded (/home/alice/.config/systemd/user/container-web.service; enabled)
     Active: inactive (dead)
```

**Enabled, but never started. That is the signature of missing lingering.**

```bash
loginctl show-user alice | grep -i linger
```

```text
Linger=no
```

```bash
sudo loginctl list-users
systemctl status user@$(id -u alice).service
```

```text
UID  USER  LINGER STATE
1001 alice no     closing

● user@1001.service - User Manager for UID 1001
     Active: inactive (dead)
```

**Her user manager never started at boot, so none of her units could start.** The fix:

```bash
sudo loginctl enable-linger alice
loginctl show-user alice | grep -i linger
ls -l /var/lib/systemd/linger/
```

```text
Linger=yes
-rw-r--r--. 1 root root 0 Aug 18 18:50 alice
```

```bash
su - alice -c 'systemctl --user start container-web'
su - alice -c 'systemctl --user is-active container-web'
sudo reboot
# after, without logging in as alice:
curl -s http://localhost:8080
ps -u alice | grep -c conmon
```

**Why the symptom is so misleading.** systemd runs a per-user manager, `user@UID.service`, only while that user has a session. At boot nobody is logged in, so with `Linger=no` the manager is absent and every user unit stays dead — while `is-enabled` still reports `enabled`, because the enablement symlink is perfectly valid.

**So `systemctl --user is-enabled` returning `enabled` is not sufficient for a rootless service.** You must also check lingering:

```bash
su - alice -c 'systemctl --user is-enabled container-web'    # enabled
loginctl show-user alice | grep -i linger                    # Linger=yes
```

**Both, every time.**

The other causes to rule out:

| Symptom | Cause |
| --- | --- |
| **`Linger=no`** | **`loginctl enable-linger` missing — nearly always this** |
| `is-enabled: disabled` | `systemctl --user enable` never run |
| Unit not found | Wrong directory, or no `systemctl --user daemon-reload` |
| Active but failed | Image missing from the *user's* store, or a port conflict |
| Port bind refused | A port below 1024 attempted rootless (`34-podman-images-running.md`) |

```bash
su - alice -c 'journalctl --user -u container-web -b'
su - alice -c 'podman images'
su - alice -c 'podman ps -a'
```

**And the exam habit: for any rootless container service, run `sudo loginctl enable-linger USER` immediately after enabling the unit.** Make the two commands a single reflex.

**Task 16.**

```bash
sudo systemctl status web
```

```text
Unit web.service could not be found.
```

**Cause 1 — no `daemon-reload`.** Quadlet units are generated, not read on demand:

```bash
ls -l /etc/containers/systemd/
sudo systemctl daemon-reload
systemctl status web
```

**This is the commonest cause. `daemon-reload` after every edit.**

**Cause 2 — wrong directory:**

```bash
ls -l /etc/containers/systemd/                   # rootful
ls -l ~/.config/containers/systemd/              # rootless
```

| | Correct | Frequently mistaken for |
| --- | --- | --- |
| Rootful Quadlet | **`/etc/containers/systemd/`** | `/etc/systemd/system/` |
| Rootless Quadlet | **`~/.config/containers/systemd/`** | `~/.config/systemd/user/` |

**Putting a `.container` file in `/etc/systemd/system/` does nothing** — the generator does not look there.

```bash
sudo mv /etc/systemd/system/web.container /etc/containers/systemd/
sudo systemctl daemon-reload
systemctl status web
```

**Cause 3 — wrong file extension:**

```bash
ls -l /etc/containers/systemd/
```

Valid Quadlet extensions:

| Extension | Produces |
| --- | --- |
| **`.container`** | **`NAME.service`** |
| `.volume` | `NAME-volume.service` |
| `.network` | `NAME-network.service` |
| `.pod` | `NAME-pod.service` |
| `.kube` | `NAME.service` from a Kubernetes YAML |
| `.image` | `NAME-image.service` |

**A file named `web.conf` or `web.service` in that directory is ignored.** It must be `web.container`.

```bash
sudo mv /etc/containers/systemd/web.conf /etc/containers/systemd/web.container
sudo systemctl daemon-reload
```

**Cause 4 — a syntax error in the file.** Run the generator by hand:

```bash
/usr/lib/systemd/system-generators/podman-system-generator --dryrun
```

```text
converting "web.container": unsupported key 'Ports' in group 'Container' in ...
```

```bash
sudo sed -i 's/^Ports=/PublishPort=/' /etc/containers/systemd/web.container
sudo systemctl daemon-reload
systemctl status web
```

**The `--dryrun` generator output names the offending key and line.** It is the best Quadlet diagnostic:

```bash
/usr/lib/systemd/system-generators/podman-system-generator --dryrun | head -40
# rootless:
/usr/lib/systemd/user-generators/podman-user-generator --dryrun
```

**Cause 5 — a missing `[Container]` section**, or `Image=` absent:

```bash
sudo cat /etc/containers/systemd/web.container
```

**`[Container]` with `Image=` is the minimum.** Without `Image=` the generator refuses the file.

**Cause 6 — Quadlet is not supported.** It needs Podman 4.4 or later:

```bash
podman --version
ls /usr/lib/systemd/system-generators/ | grep -i podman
```

```text
podman version 5.2.2
podman-system-generator
```

If the generator is absent, use `podman generate systemd` instead.

**The diagnostic sequence:**

```bash
podman --version                                          # 4.4+?
ls -l /etc/containers/systemd/                            # right place, right extension?
sudo cat /etc/containers/systemd/web.container            # [Container] and Image=?
/usr/lib/systemd/system-generators/podman-system-generator --dryrun   # syntax
sudo systemctl daemon-reload                              # regenerate
systemctl status web                                      # does it exist now?
systemctl cat web.service                                 # what was generated?
```

**And remember: `systemctl enable` on a Quadlet unit is expected to fail.** Enabling is done by `WantedBy=` in `[Install]`:

```text
[Install]
WantedBy=multi-user.target default.target
```

**Omitting `[Install]` gives a unit that starts manually but never at boot** — which passes your check and fails the grader's.

**Task 17.**

Rootful, `podman generate systemd`:

```bash
sudo systemctl disable --now container-web
sudo rm -f /etc/systemd/system/container-web.service
sudo systemctl daemon-reload
sudo systemctl reset-failed 2>/dev/null

sudo podman ps -a
sudo podman rm -f web 2>/dev/null
sudo podman rmi registry.access.redhat.com/ubi9/httpd-24 2>/dev/null

systemctl status container-web
```

```text
Unit container-web.service could not be found.
```

Rootful Quadlet:

```bash
sudo systemctl stop web
sudo rm -f /etc/containers/systemd/web.container
sudo systemctl daemon-reload
systemctl status web
sudo podman rm -f web 2>/dev/null
```

**No `disable` for a Quadlet unit** — deleting the file and reloading removes it entirely, because the unit only exists as generated output.

Rootless:

```bash
su - alice
systemctl --user disable --now container-web
rm -f ~/.config/systemd/user/container-web.service
rm -f ~/.config/containers/systemd/web.container
systemctl --user daemon-reload
podman rm -f web 2>/dev/null
podman rmi registry.access.redhat.com/ubi9/httpd-24 2>/dev/null
exit

sudo loginctl disable-linger alice
loginctl show-user alice | grep -i linger
```

Also tidy up the supporting configuration:

```bash
sudo firewall-cmd --permanent --remove-port=8080/tcp
sudo firewall-cmd --reload

sudo semanage fcontext -d "/srv/webcontent(/.*)?"
sudo restorecon -Rv /srv/webcontent
sudo rm -rf /srv/webcontent

sudo podman volume ls
sudo podman volume rm webdata
sudo podman system prune -a --volumes -f
```

**Removal order, and why:**

| Step | Command | If skipped |
| --- | --- | --- |
| 1 | **`systemctl disable --now UNIT`** | **The boot symlink remains and systemd tries to start a missing unit** |
| 2 | **Delete the unit file** | The unit still exists |
| 3 | **`systemctl daemon-reload`** | systemd still knows about it |
| 4 | `podman rm -f` | The container lingers, holding its name and port |
| 5 | `podman rmi` | Disk space |
| 6 | `loginctl disable-linger` | The user manager keeps running |
| 7 | `firewall-cmd --permanent --remove-port` | The port stays open |

**`disable` before deleting the file.** Deleting first leaves a dangling symlink in `default.target.wants/`:

```bash
ls -l /etc/systemd/system/default.target.wants/
sudo systemctl daemon-reload                     # systemd prunes dangling symlinks
```

Verify nothing remains:

```bash
systemctl list-units | grep -i -E 'container|web'
sudo podman ps -a
sudo podman images
sudo podman volume ls
loginctl show-user alice | grep -i linger
sudo firewall-cmd --list-ports
sudo reboot
# after: nothing should be running
```

**Task 18.**

**Rootful services:**

```bash
systemctl is-enabled container-web
systemctl is-active container-web
ls -l /etc/systemd/system/container-*.service
sudo grep ExecStart /etc/systemd/system/container-web.service
sudo podman images                               # image in ROOT's store
sudo podman ps
```

**Quadlet services:**

```bash
ls -l /etc/containers/systemd/
sudo cat /etc/containers/systemd/*.container
grep -A2 '\[Install\]' /etc/containers/systemd/*.container    # WantedBy present?
/usr/lib/systemd/system-generators/podman-system-generator --dryrun >/dev/null && echo "syntax OK"
systemctl status web
systemctl cat web.service
```

**Rootless services:**

```bash
ls -l /home/alice/.config/systemd/user/
ls -l /home/alice/.config/containers/systemd/ 2>/dev/null
su - alice -c 'systemctl --user is-enabled container-web'
su - alice -c 'systemctl --user is-active container-web'
loginctl show-user alice | grep -i linger
ls -l /var/lib/systemd/linger/
su - alice -c 'podman images'                    # image in ALICE's store
```

**Supporting configuration:**

```bash
sudo firewall-cmd --permanent --list-ports
diff <(sudo firewall-cmd --list-ports) <(sudo firewall-cmd --permanent --list-ports)
ls -Zd /srv/webcontent
sudo semanage fcontext -l -C | grep container_file_t
sudo systemctl --failed
```

**Everything must hold:**

- Rootful units: **`is-enabled` says `enabled`.**
- Quadlet units: the file is in **`/etc/containers/systemd/`** with a **`[Install] WantedBy=`** section.
- Rootless units: **`--user is-enabled` says `enabled`** AND **`Linger=yes`.**
- The image is present in the **matching** store — root's for rootful, the user's for rootless.
- Firewall ports are in the **permanent** set and the runtime/permanent diff is empty.
- Bind-mount directories exist with **`container_file_t`**.

```bash
sudo reboot
```

After the reboot, **without starting anything by hand:**

```bash
systemctl status container-web
systemctl status web
sudo podman ps
curl -s -o /dev/null -w 'rootful: %{http_code}\n' http://localhost:8080

sudo loginctl list-users
systemctl status user@$(id -u alice).service
su - alice -c 'podman ps'
su - alice -c 'systemctl --user status container-web'

systemctl --failed
sudo journalctl -b -p err | grep -i -E 'podman|container'
```

And from server2, the test the grader actually performs:

```bash
curl http://192.168.56.11:8080
```

**The five ways this objective fails after a reboot:**

| Cause | Check |
| --- | --- |
| **`enable` never run (rootful)** | `systemctl is-enabled container-web` |
| **`loginctl enable-linger` never run (rootless)** | `loginctl show-user USER \| grep Linger` |
| **No `[Install] WantedBy=` in a Quadlet file** | `grep -A2 '\[Install\]' *.container` |
| **Image in the wrong store** | `sudo podman images` versus `podman images` |
| **Firewall rule not `--permanent`** | `firewall-cmd --permanent --list-ports` |

```bash
# The container-service pre-reboot check
systemctl is-enabled container-web 2>/dev/null
grep -A2 '\[Install\]' /etc/containers/systemd/*.container 2>/dev/null
loginctl show-user alice 2>/dev/null | grep -i linger
sudo firewall-cmd --permanent --list-ports
```

---

## Verify

```bash
# Rootful, generate systemd
systemctl is-enabled container-web
systemctl is-active container-web
systemctl status container-web
ls -l /etc/systemd/system/container-*.service
sudo grep ExecStart /etc/systemd/system/container-web.service

# Quadlet
ls -l /etc/containers/systemd/
systemctl status web.service
systemctl cat web.service
/usr/lib/systemd/system-generators/podman-system-generator --dryrun

# Rootless
su - USER -c 'systemctl --user is-enabled container-web'
su - USER -c 'systemctl --user is-active container-web'
loginctl show-user USER | grep -i linger
ls -l /var/lib/systemd/linger/
systemctl status user@$(id -u USER).service

# The container and its supports
sudo podman ps
sudo podman logs web
journalctl -u container-web -b
journalctl -xeu web
sudo firewall-cmd --permanent --list-ports
ls -Zd /srv/webcontent
systemctl --failed
```

## Persistence Check

| Item | Persistent form | Also required |
| --- | --- | --- |
| Rootful unit | `/etc/systemd/system/container-NAME.service` | **`systemctl enable`** + `daemon-reload` |
| Rootful Quadlet | `/etc/containers/systemd/NAME.container` | **`[Install] WantedBy=`** + `daemon-reload` |
| Rootless unit | `~/.config/systemd/user/container-NAME.service` | **`systemctl --user enable`** AND **`loginctl enable-linger`** |
| Rootless Quadlet | `~/.config/containers/systemd/NAME.container` | **`[Install] WantedBy=`** AND **`loginctl enable-linger`** |
| Container data | A volume or bind mount | `:Z` for SELinux |
| Image | In the store of the matching user | Pull as root for a rootful unit |
| Firewall port | **`firewall-cmd --permanent`** | **`--reload`** |
| Lingering | **`/var/lib/systemd/linger/USER`** | — |

**The two failures that account for nearly every lost mark here:**

1. **A rootful unit that was started but never enabled.** `systemctl is-enabled` catches it.
2. **A rootless service without lingering.** `loginctl show-user USER | grep Linger` catches it.

```bash
# The three-line check
systemctl is-enabled container-web
loginctl show-user alice | grep -i linger
sudo firewall-cmd --permanent --list-ports
```

**Then reboot and verify without touching anything by hand.** That is exactly what the grader does.

## Exam Tips

- **`podman run -d` does not survive a reboot.** Podman has no daemon. Any task mentioning boot or "as a service" needs a systemd unit.
- **`podman run --restart=always` does not help at boot.** There is nothing to honour it.
- **Rootful: `cd /etc/systemd/system` then `sudo podman generate systemd --new --name web --files`, `daemon-reload`, `enable --now container-web`.**
- **`--files` writes into the current directory.** `cd` there first.
- **Always use `--new`.** The unit then records the whole `podman run` command and survives `podman rm`.
- **The generated unit is `container-<name>.service`.**
- **`daemon-reload` after writing or editing any unit.**
- **`enable`, not just `start`.** `systemctl is-enabled` is the check that predicts the reboot.
- **Rootless: units in `~/.config/systemd/user/`, commands with `systemctl --user`.**
- **`loginctl enable-linger USER` for every rootless service.** Without it the unit is enabled and still dead after a reboot. **This is the most commonly missed step in the objective.**
- **Use `su - USER`, not `sudo -u USER`,** for `systemctl --user`. The dash gives a login session with `XDG_RUNTIME_DIR`.
- **Never `sudo systemctl --user`** — that targets root's user manager.
- **Quadlet: `/etc/containers/systemd/NAME.container` (rootful) or `~/.config/containers/systemd/` (rootless), then `daemon-reload`.**
- **A `.container` file produces `NAME.service`** — drop the extension in systemctl commands.
- **There is no `systemctl enable` for a Quadlet unit.** `[Install] WantedBy=multi-user.target default.target` does the enabling. **Omitting `[Install]` means it never starts at boot.**
- **`/usr/lib/systemd/system-generators/podman-system-generator --dryrun`** is the best Quadlet diagnostic.
- **`.container` must be the extension.** `.conf` or `.service` in that directory is ignored.
- **Quadlet keys: `Image=`, `ContainerName=`, `PublishPort=`, `Volume=`, `Environment=`.**
- **The image must be in the matching store.** Rootful units need `sudo podman pull`.
- **Once systemd owns a container, use `systemctl`, not `podman stop`.** `podman stop` under `Restart=always` triggers an immediate restart; under `Restart=no` it leaves the unit marked failed.
- **`journalctl -xeu UNIT` for "it will not start"; `podman logs NAME` for "it started but does not work".**
- **`systemctl reset-failed UNIT`** clears a start-limit condition.
- **Open the firewall with `--permanent` and `--reload`.**
- **`:Z` on bind mounts**, and create the directory before starting the service or the unit fails with `statfs: no such file or directory`.
- **Reboot and verify without starting anything by hand.** That is how it is graded.
