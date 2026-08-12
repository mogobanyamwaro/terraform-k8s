# Podman Deep Dive

Six container objectives, and the whole domain reduces to three ideas that catch people out: **rootful and rootless are separate worlds**, **bind mounts need `:Z`**, and **`podman run -d` does not survive a reboot**.

Step-by-step tasks are in `34-podman-images-running.md` and `35-containers-systemd.md`.

**A caveat on exam scope.** Containers were part of RHCSA for RHEL 8 and 9. Red Hat's published RHEL 9 and RHEL 10 objective lists have varied on whether the container section is included. Prepare it — it is a small, self-contained domain and the cost of being wrong the other way is high.

---

## Podman versus Docker

| | Docker | **Podman** |
| --- | --- | --- |
| Daemon | **`dockerd`, runs as root** | **None** |
| Containers are children of | The daemon | **The invoking process** |
| Rootless | Added later, awkward | **The default** |
| **Survives a reboot via** | **`--restart=always`, honoured by the daemon** | **A systemd unit. Nothing else** |
| systemd integration | Poor | **`generate systemd`, Quadlet** |
| Command syntax | — | **Deliberately identical** |
| On RHEL | Not shipped | **The supported option** |

```bash
sudo dnf install -y container-tools
podman --version
podman info
alias docker=podman                          # exists on many systems
```

**The one difference that matters for the exam: with no daemon, nothing restarts your containers at boot.**

```text
   podman run -d              ≈  systemctl start   (now, not after a reboot)
   a systemd unit + enable    ≈  systemctl enable  (after every reboot)
```

**So any task mentioning boot, "as a service", or "automatically" is a systemd task, not a `podman run` task.**

---

## Rootful versus rootless

**This is the distinction that produces the most confusing failures.**

```bash
podman info --format '{{.Host.Security.Rootless}}'
id -u
```

| | Rootless (`podman ...`) | Rootful (`sudo podman ...`) |
| --- | --- | --- |
| **Image store** | **`~/.local/share/containers/storage`** | **`/var/lib/containers/storage`** |
| **Container store** | The same, per user | `/var/lib/containers` |
| Configuration | `~/.config/containers/` | `/etc/containers/` |
| **Ports below 1024** | **Refused** | Allowed |
| Runtime state | `/run/user/UID/` | `/run/` |
| Network | slirp4netns or pasta | CNI or netavark |
| systemd units | `~/.config/systemd/user/` | `/etc/systemd/system/` |
| **Needs lingering** | **Yes** | No |
| Container root maps to | **Your UID on the host** | **Real root** |
| Security | **Better** | Worse |

```bash
podman images                                # YOUR images
sudo podman images                           # ROOT's images
podman ps -a
sudo podman ps -a
```

**These are entirely separate lists.** The two most common consequences:

**1. A rootful systemd unit cannot see an image you pulled as your user:**

```bash
podman pull registry.access.redhat.com/ubi9/httpd-24     # your store
sudo systemctl start container-web                        # fails
sudo journalctl -xeu container-web
```

```text
Error: initializing source docker://...: pinging container registry: dial tcp: lookup ... no such host
```

**The unit runs as root, root's store is empty, and it tried to pull — with no network, or no credentials.**

```bash
sudo podman pull registry.access.redhat.com/ubi9/httpd-24
sudo systemctl restart container-web
```

**Pull with the same privilege level as the thing that will run it.**

**2. "The container I created has disappeared":**

```bash
sudo podman run -d --name web ...
podman ps                                    # empty — you are looking at YOUR store
sudo podman ps                               # there it is
```

**Decide at the start of each task whether you are working rootful or rootless and stay consistent.** If the task names a user, work as that user. If it does not, rootful is simpler — no lingering, no port restriction.

### Privileged ports

```bash
podman run -d -p 80:80 IMAGE
```

```text
Error: rootlessport cannot expose privileged port 80
```

```bash
podman run -d -p 8080:80 IMAGE               # map high on the host
sudo podman run -d -p 80:80 IMAGE            # or run rootful
```

**The container-side port can be anything; only the host-side port below 1024 is restricted.** `-p 8080:80` is a rootless web server.

**The system-wide alternative, if a task insists on rootless port 80:**

```bash
echo 'net.ipv4.ip_unprivileged_port_start=80' | sudo tee /etc/sysctl.d/99-ports.conf
sudo sysctl -p /etc/sysctl.d/99-ports.conf
```

**Mention it only if asked. Mapping to a high port is the expected answer.**

### User namespaces

```bash
podman run --rm registry.access.redhat.com/ubi9/ubi id
```

```text
uid=0(root) gid=0(root) groups=0(root)
```

**Root inside a rootless container is your UID on the host.** That is why a rootless container can write to your files and not to `/etc`:

```bash
grep "$(whoami)" /etc/subuid /etc/subgid
podman unshare cat /proc/self/uid_map
```

```text
alice:100000:65536
```

**The container's UID 0 is your UID; its UIDs 1-65536 map to 100000 upward.** A consequence worth knowing: files a rootless container creates as a non-root internal user appear on the host owned by a high, unfamiliar UID.

```bash
podman unshare chown 1001:1001 ~/data        # fix ownership in the container's view
```

---

## Registries and images

```bash
cat /etc/containers/registries.conf
cat ~/.config/containers/registries.conf 2>/dev/null
```

```text
unqualified-search-registries = ["registry.access.redhat.com", "registry.redhat.io", "docker.io"]

[[registry]]
location = "docker.io"
blocked = false

[[registry]]
location = "myregistry.lab.example.com:5000"
insecure = true
```

| Registry | Contents | Login |
| --- | --- | --- |
| **`registry.access.redhat.com`** | **UBI images. No login needed** | No |
| `registry.redhat.io` | The full Red Hat catalogue | **Yes** |
| `docker.io` | Docker Hub | For rate limits |
| `quay.io` | Red Hat's public registry | For private repos |

```bash
podman login registry.redhat.io
podman login --username user --password-stdin registry.redhat.io < /tmp/pw
podman logout registry.redhat.io
podman logout --all
cat ${XDG_RUNTIME_DIR}/containers/auth.json
```

**Always use a fully qualified image name:**

```bash
podman pull registry.access.redhat.com/ubi9/httpd-24     # correct
podman pull httpd-24                                      # a short name
```

```text
Error: short-name "httpd-24" did not resolve to an alias and no unqualified-search
registries are defined in "/etc/containers/registries.conf"
```

or worse, an interactive prompt to choose a registry — **which fails inside a systemd unit, because there is no TTY:**

```text
Error: short-name resolution enforced but cannot prompt without a TTY
```

**Fully qualified names everywhere, and especially in a unit file.**

### Searching and inspecting

```bash
podman search httpd
podman search --limit 5 nginx
podman search --filter is-official=true nginx
podman search registry.access.redhat.com/ubi9
podman search --list-tags registry.access.redhat.com/ubi9/httpd-24
```

```bash
podman pull registry.access.redhat.com/ubi9/httpd-24
podman pull registry.access.redhat.com/ubi9/httpd-24:latest
podman images
podman images --format '{{.Repository}}:{{.Tag}} {{.Size}}'
podman image ls --digests
```

```bash
podman inspect registry.access.redhat.com/ubi9/httpd-24
podman inspect -f '{{.Config.Env}}' IMAGE
podman inspect -f '{{.Config.ExposedPorts}}' IMAGE
podman inspect -f '{{.Config.Cmd}}' IMAGE
podman inspect -f '{{.Config.User}}' IMAGE
podman inspect -f '{{range .Config.Env}}{{println .}}{{end}}' IMAGE
podman history IMAGE
```

**`podman inspect` on an image tells you what you need before running it: the exposed port, the environment variables it expects, and the user it runs as.**

```bash
podman inspect -f '{{.Config.ExposedPorts}}' registry.access.redhat.com/ubi9/httpd-24
```

```text
map[8080/tcp:{} 8443/tcp:{}]
```

**Note that UBI httpd exposes 8080, not 80** — so the mapping is `-p 8080:8080`. Guessing port 80 is a common mistake with UBI images.

### skopeo

```bash
skopeo inspect docker://registry.access.redhat.com/ubi9/httpd-24
skopeo inspect --config docker://registry.access.redhat.com/ubi9/httpd-24
skopeo list-tags docker://registry.access.redhat.com/ubi9/httpd-24
skopeo copy docker://IMAGE dir:/tmp/imagedir
skopeo copy docker://IMAGE docker-archive:/tmp/image.tar
skopeo copy docker://IMAGE containers-storage:localhost/myimage
skopeo delete docker://myregistry/image:tag
```

**`skopeo inspect` reads a remote image without pulling it**, which is faster and does not consume disk. It is the answer to "inspect a container image" when the image is large or the task says "without downloading".

```bash
podman save -o /tmp/image.tar IMAGE
podman load -i /tmp/image.tar
podman tag IMAGE localhost/myimage:v1
podman rmi IMAGE ; podman rmi -a ; podman image prune -a
```

---

## Running containers

```bash
podman run -d --name web -p 8080:8080 registry.access.redhat.com/ubi9/httpd-24
podman run -it --rm registry.access.redhat.com/ubi9/ubi /bin/bash
podman run --rm registry.access.redhat.com/ubi9/ubi cat /etc/os-release
podman run -d --name db \
  -p 3306:3306 \
  -v /srv/dbdata:/var/lib/mysql/data:Z \
  -e MYSQL_ROOT_PASSWORD=secret \
  -e MYSQL_DATABASE=appdb \
  registry.redhat.io/rhel9/mariadb-105
```

| Flag | Meaning |
| --- | --- |
| **`-d`** | **Detached. For anything long-running** |
| **`--name`** | **Name it. Otherwise you get `nervous_einstein`** |
| **`-p host:container`** | Publish a port |
| **`-v /host:/ctr:Z`** | **Bind mount, SELinux-relabelled** |
| `-v name:/ctr` | Named volume |
| **`-e KEY=value`** | Environment variable |
| `--env-file /path` | Environment from a file |
| `-it` | Interactive with a TTY |
| `--rm` | Remove when it exits |
| `-u 1001` | Run as a UID |
| `-w /path` | Working directory |
| `--restart=always` | **Restart policy — only while podman is running** |
| `--network host` | Share the host's network namespace |
| `--replace` | Replace an existing container of the same name |
| `--memory 512m`, `--cpus 1.5` | Resource limits |

```bash
podman ps
podman ps -a
podman ps --format '{{.Names}} {{.Status}} {{.Ports}}'
podman stop web ; podman stop -t 2 web
podman start web ; podman restart web
podman kill web ; podman pause web ; podman unpause web
podman rm web ; podman rm -f web ; podman rm -a -f
podman container prune -f
podman logs web ; podman logs -f web ; podman logs --tail 20 web
podman logs --since 10m web ; podman logs -t web
podman exec -it web /bin/bash
podman exec web cat /etc/os-release
podman exec -u root web whoami
podman inspect web ; podman port web ; podman top web
podman stats --no-stream ; podman diff web
podman cp file web:/tmp/ ; podman cp web:/tmp/file .
podman rename web web-old
```

### `podman logs` is the first debugging step

**A container that exits immediately has almost always printed why:**

```bash
podman run -d --name db registry.redhat.io/rhel9/mariadb-105
podman ps                                    # empty
podman ps -a                                 # Exited (1)
podman logs db
```

```text
You must either specify the following environment variables:
  MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE
Or the following environment variable:
  MYSQL_ROOT_PASSWORD
```

**The image told you exactly what was missing.** Check `podman logs` before anything else.

**And `podman inspect` on the image tells you in advance:**

```bash
podman inspect -f '{{range .Config.Env}}{{println .}}{{end}}' IMAGE
podman run --rm IMAGE cat /help.1 2>/dev/null | head -40
```

---

## Persistent storage

**Container filesystems are ephemeral. Anything written inside a container is gone when it is removed — and a `--new` systemd unit removes and recreates the container at every restart.**

### Bind mounts

```bash
sudo mkdir -p /srv/webcontent
echo '<h1>Served from the host</h1>' | sudo tee /srv/webcontent/index.html

sudo podman run -d --name web -p 8080:8080 \
  -v /srv/webcontent:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24

curl http://localhost:8080
ls -Zd /srv/webcontent
```

```text
system_u:object_r:container_file_t:s0 /srv/webcontent
```

**`:Z` is what makes this work.** Without it:

```bash
sudo podman run -d --name web2 -p 8081:8080 \
  -v /srv/webcontent:/var/www/html \
  registry.access.redhat.com/ubi9/httpd-24
curl http://localhost:8081
```

```text
403 Forbidden
```

```bash
sudo ausearch -m AVC -ts recent
```

```text
avc: denied { read } for pid=... comm="httpd" name="index.html"
  scontext=...container_t tcontext=...var_t tclass=file
```

| Suffix | Effect |
| --- | --- |
| **`:Z`** | **Relabel to `container_file_t` with a PRIVATE category. One container only** |
| **`:z`** | **Relabel with a SHARED label. Several containers can use it** |
| `:ro` | Read-only |
| `:rw` | Read-write, the default |
| `:Z,ro` | Both |
| **(none)** | **SELinux denies access** |

**`:Z` writes a private MCS category, so a second container cannot read the same directory. Use `:z` when two containers share one directory.**

**A warning about `:Z` on a system directory.** It relabels recursively and permanently:

```bash
sudo podman run -v /etc:/host-etc:Z ...       # DO NOT — relabels all of /etc
sudo podman run -v /etc:/host-etc:ro ...      # read-only, no relabel
```

**Only use `:Z` on a directory created for the container.**

**The persistent alternative, when the label must survive independently:**

```bash
sudo semanage fcontext -a -t container_file_t "/srv/webcontent(/.*)?"
sudo restorecon -Rv /srv/webcontent
ls -Zd /srv/webcontent
sudo semanage fcontext -l -C
```

**This is the more robust answer for a systemd-managed container**, because the label is recorded in policy and survives a relabel. Doing both is harmless.

**Ownership inside the container matters too:**

```bash
podman inspect -f '{{.Config.User}}' registry.access.redhat.com/ubi9/httpd-24
```

```text
1001
```

```bash
sudo chown -R 1001:0 /srv/webcontent          # for a rootful container
podman unshare chown -R 1001:0 ~/webcontent   # for a rootless one
```

**`podman unshare` runs a command inside the user namespace**, so the UID you give is the container's view. It is the correct way to set ownership for a rootless bind mount.

### Named volumes

```bash
podman volume create webdata
podman volume ls
podman volume inspect webdata
podman run -d --name web -v webdata:/var/www/html registry.access.redhat.com/ubi9/httpd-24
podman volume rm webdata
podman volume prune -f
```

```bash
podman volume inspect webdata -f '{{.Mountpoint}}'
```

```text
/var/lib/containers/storage/volumes/webdata/_data
```

| | Bind mount | Named volume |
| --- | --- | --- |
| Location | **You choose** | Managed by podman |
| SELinux | **Needs `:Z`** | **Handled automatically** |
| Host access | **Easy — a normal path** | Through the storage path |
| Portable | Less | More |
| Exam tasks | **Usually this** | Sometimes |

**A task saying "the content must be in `/srv/web` on the host" means a bind mount. A task saying "the data must persist" accepts either.**

---

## As a systemd service

**Covered fully in `35-containers-systemd.md`. The essentials:**

### Rootful

```bash
sudo podman pull registry.access.redhat.com/ubi9/httpd-24
sudo podman run -d --name web -p 8080:8080 \
  -v /srv/webcontent:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24
curl http://localhost:8080

cd /etc/systemd/system
sudo podman generate systemd --new --name web --files
sudo systemctl daemon-reload
sudo podman rm -f web
sudo systemctl enable --now container-web
systemctl is-enabled container-web

sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

| Element | Value |
| --- | --- |
| Directory | **`/etc/systemd/system/`** — `cd` there, `--files` writes to the cwd |
| Unit name | **`container-web.service`** |
| **`--new`** | **`ExecStart` becomes the full `podman run`; survives `podman rm`** |
| Enable | **`sudo systemctl enable --now container-web`** |

### Rootless

```bash
podman pull registry.access.redhat.com/ubi9/httpd-24
podman run -d --name web -p 8080:8080 IMAGE

mkdir -p ~/.config/systemd/user && cd ~/.config/systemd/user
podman generate systemd --new --name web --files
systemctl --user daemon-reload
podman rm -f web
systemctl --user enable --now container-web

loginctl enable-linger $(whoami)              # ← WITHOUT THIS IT DIES AT REBOOT
loginctl show-user $(whoami) | grep -i Linger
```

**`loginctl enable-linger` is the most commonly missed step in the whole domain.** The unit is enabled, everything looks right, and the container is dead after the grader's reboot because the user's systemd manager never started.

### Quadlet

```bash
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
Environment=KEY=value

[Service]
Restart=always

[Install]
WantedBy=multi-user.target default.target
EOF

sudo systemctl daemon-reload
sudo systemctl start web
systemctl status web
```

| | `generate systemd` | **Quadlet** |
| --- | --- | --- |
| File | `/etc/systemd/system/container-web.service` | **`/etc/containers/systemd/web.container`** |
| Rootless | `~/.config/systemd/user/` | **`~/.config/containers/systemd/`** |
| Service name | `container-web.service` | **`web.service`** |
| `systemctl enable` | **Required** | **Impossible — use `[Install] WantedBy=`** |
| Podman version | 3+, **deprecated in 5** | **4.4+, preferred** |

**Omitting `[Install] WantedBy=` from a Quadlet file gives a unit that starts by hand and never at boot.** There is no `enable` to fall back on:

```text
Failed to enable unit: Unit /run/systemd/generator/web.service is transient or generated.
```

**That error is expected. The missing `[Install]` is the bug.**

```bash
/usr/lib/systemd/system-generators/podman-system-generator --dryrun
systemctl cat web.service
```

**`--dryrun` is the best Quadlet diagnostic** — it names the offending key and file when the unit fails to appear.

### Once systemd owns it

| Intent | **Correct** | Wrong |
| --- | --- | --- |
| Stop | **`systemctl stop web`** | `podman stop web` |
| Start | **`systemctl start web`** | `podman start web` |
| Logs (why it will not start) | **`journalctl -xeu web`** | — |
| Logs (application output) | **`podman logs web`** | — |
| Inspect | `podman ps`, `podman inspect` | — |

**`podman stop` on a unit with `Restart=always` triggers an immediate restart. With `Restart=no` it leaves the unit marked failed.** Either way, systemd's view and reality diverge.

```bash
sudo systemctl reset-failed web
sudo systemctl restart web
```

---

## Housekeeping

```bash
podman system df
podman system df -v
podman system prune                          # stopped containers, unused networks
podman system prune -a                       # and unused images
podman system prune -a --volumes -f
podman image prune -a
podman container prune -f
podman volume prune -f
podman system reset                          # DELETES EVERYTHING for this user
```

```bash
du -sh ~/.local/share/containers/
sudo du -sh /var/lib/containers/
```

**Rootless images live in your home directory, so they count against `/home` and can fill it.** Worth knowing if a storage task and a container task share a disk.

---

## Troubleshooting

```text
Symptom                                  Cause and fix
──────────────────────────────────────────────────────────────────────────────
"short-name did not resolve"              Use a fully qualified image name

"cannot expose privileged port"            Rootless with a host port below 1024;
                                           map high, or run rootful

Exits immediately                          podman logs NAME — usually a missing
                                           environment variable

403 / permission denied inside             Missing :Z on the bind mount;
                                           ausearch -m AVC -ts recent

"address already in use"                   ss -tlnp | grep PORT;
                                           podman ps -a for a leftover container

"container name already in use"             podman rm -f NAME, or use --replace

"statfs /path: no such file"                The bind-mount source does not exist;
                                           mkdir it before starting the unit

Works locally, not from the other host     firewall-cmd --permanent --add-port

Gone after a reboot (rootful)              systemctl is-enabled container-web

Gone after a reboot (rootless)              loginctl show-user USER | grep Linger

Unit fails, worked by hand                 Image in the wrong store —
                                           sudo podman images

Quadlet unit does not exist                daemon-reload; check the directory and
                                           the .container extension;
                                           podman-system-generator --dryrun

"No medium found" from systemctl --user     Use su - USER, not sudo -u USER
```

**The most productive single diagnostic for a failing container unit:**

```bash
sudo grep ExecStart /etc/systemd/system/container-web.service
# copy that podman run command and run it by hand
sudo podman run --rm -it <the same arguments>
```

**The error is usually immediate and obvious, and you stop guessing.**

---

## Worked example

**Task: run a web server in a container on server1, serving content from `/srv/webcontent`, on port 8080, started automatically at boot, reachable from server2.**

```bash
# 1. Tools and image, as root because the unit will be rootful
sudo dnf install -y container-tools
sudo podman pull registry.access.redhat.com/ubi9/httpd-24
sudo podman inspect -f '{{.Config.ExposedPorts}}' registry.access.redhat.com/ubi9/httpd-24

# 2. Persistent content, correctly labelled and owned
sudo mkdir -p /srv/webcontent
echo '<h1>server1 container</h1>' | sudo tee /srv/webcontent/index.html
sudo semanage fcontext -a -t container_file_t "/srv/webcontent(/.*)?"
sudo restorecon -Rv /srv/webcontent
sudo chown -R 1001:0 /srv/webcontent
ls -lZd /srv/webcontent

# 3. Test by hand FIRST
sudo podman run -d --name web -p 8080:8080 \
  -v /srv/webcontent:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24
sudo podman ps
curl http://localhost:8080
sudo podman logs web

# 4. Hand it to systemd
cd /etc/systemd/system
sudo podman generate systemd --new --name web --files
sudo systemctl daemon-reload
sudo podman rm -f web
sudo systemctl enable --now container-web
systemctl status container-web
systemctl is-enabled container-web
sudo podman ps

# 5. Firewall
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)

# 6. Verify locally, then from server2
curl http://localhost:8080
ssh server2 'curl -s http://192.168.56.11:8080'

# 7. THE test
sudo reboot
```

After the reboot, **without starting anything by hand:**

```bash
systemctl status container-web
sudo podman ps
curl http://localhost:8080
ssh server2 'curl -s http://192.168.56.11:8080'
```

**Six things had to be right: the image in root's store, the directory with a `container_file_t` label, the port mapping, the unit enabled, the firewall permanent, and the content owned so the container's user can read it.** Each is a separate way to score zero.

---

## Verification

```bash
# Images and containers, in the RIGHT store
sudo podman images ; podman images
sudo podman ps ; sudo podman ps -a
sudo podman port web
sudo podman logs web
sudo podman inspect web -f '{{.Mounts}}'

# The unit
systemctl is-enabled container-web
systemctl status container-web
ls -l /etc/systemd/system/container-*.service
sudo grep ExecStart /etc/systemd/system/container-web.service

# Quadlet
ls -l /etc/containers/systemd/
grep -A2 '\[Install\]' /etc/containers/systemd/*.container
systemctl cat web.service
/usr/lib/systemd/system-generators/podman-system-generator --dryrun

# Rootless
su - USER -c 'podman ps'
su - USER -c 'systemctl --user is-enabled container-web'
loginctl show-user USER | grep -i Linger
ls -l /var/lib/systemd/linger/

# Storage and SELinux
ls -Zd /srv/webcontent
sudo semanage fcontext -l -C
sudo ausearch -m AVC -ts recent
podman volume ls

# Network
ss -tlnp | grep 8080
curl http://localhost:8080
sudo firewall-cmd --permanent --list-ports
```

---

## The five things to take away

1. **Rootful and rootless have separate image stores.** Pull with the same privilege as the thing that will run it.
2. **`:Z` on every bind mount**, or SELinux denies the container access. `:z` when two containers share a directory.
3. **`podman run -d` does not survive a reboot, and neither does `--restart=always`.** Boot persistence means a systemd unit.
4. **`--new` on `podman generate systemd`**, and **`loginctl enable-linger`** for anything rootless.
5. **`podman logs` first when a container misbehaves; `journalctl -xeu` first when a unit will not start.**
