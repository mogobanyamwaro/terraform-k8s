# 34. Containers With Podman: Images And Running

**Objectives:**
- Find and retrieve container images from a remote registry
- Inspect container images
- Perform container management using commands such as podman and skopeo
- Run a service inside a container
- Attach persistent storage to a container

**A note on whether this is examinable.** Containers appeared in the RHEL 8 and RHEL 9 RHCSA objectives. Red Hat's published RHEL 10 objective list has varied on this point, and different sources disagree. **Prepare it.** It is a small number of commands, it overlaps heavily with systemd and SELinux, and being wrong about its absence is far more expensive than the hour it takes to learn.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Reading twenty podman flags upfront feels like learning. Typing them one at a time actually is.

---

## Follow Along

Work on your lab VM as your regular user (rootless podman). After each step, compare your output to **You should see**.

### 1. Install container tools and confirm podman

Podman is RHEL's supported container tool — no daemon, fork/exec model, Docker-compatible syntax.

```bash
sudo dnf install -y container-tools
podman --version
skopeo --version
```

Or install individually:

```bash
sudo dnf install -y podman skopeo buildah
rpm -q podman skopeo buildah
```

**You should see** version strings for podman and skopeo (for example `podman version 5.x` and `skopeo version 1.x`). `alias docker=podman` works because the command syntax is deliberately compatible.

| | Docker | **Podman** |
| --- | --- | --- |
| Daemon | **A root daemon** | **None. Fork/exec** |
| Rootless | Awkward | **Native and default** |
| systemd integration | Poor | **`podman generate systemd`, Quadlet** |
| Command syntax | `docker run` | **`podman run` — identical** |
| Available on RHEL 9/10 | No | **Yes, the supported tool** |

### 2. Confirm rootless mode and separate storage

```bash
podman info | grep -i rootless
podman info --format '{{.Host.Security.Rootless}}'
whoami
podman info --format '{{.Store.GraphRoot}}'
```

**You should see** `rootless: true` and a graph root under your home directory, such as `/home/you/.local/share/containers/storage`.

Compare with rootful:

```bash
sudo podman info --format '{{.Host.Security.Rootless}}'
sudo podman info --format '{{.Store.GraphRoot}}'
```

**You should see** `false` and `/var/lib/containers/storage`.

**`sudo podman ps` and `podman ps` show completely different worlds.** An image pulled as your user is invisible to root, and vice versa.

| | Rootless (`podman` as a user) | Rootful (`sudo podman`) |
| --- | --- | --- |
| Storage | **`~/.local/share/containers/`** | `/var/lib/containers/` |
| Images visible to | **That user only** | root only |
| Ports below 1024 | **Not allowed** | Allowed |
| systemd units | **`~/.config/systemd/user/`** | `/etc/systemd/system/` |
| Survives logout | **Only with `loginctl enable-linger`** | Yes |

```bash
podman images
sudo podman images
```

**You should see** two separate image lists — often one is empty if you have only pulled as one user.

### 3. Examine registry configuration

```bash
cat /etc/containers/registries.conf
grep -v '^#' /etc/containers/registries.conf | grep -v '^$'
podman info | grep -A5 -i registries
```

**You should see** `unqualified-search-registries` listing registries such as `registry.access.redhat.com`, `registry.redhat.io`, and `docker.io`.

| Registry | Content |
| --- | --- |
| `registry.access.redhat.com` | **Red Hat images, no login required** |
| `registry.redhat.io` | Red Hat images, **login required** |
| `docker.io` | Docker Hub |
| `quay.io` | Red Hat's Quay |

**Always use the fully qualified image name.** `podman pull nginx` depends on the search list; `podman pull docker.io/library/nginx:latest` is unambiguous.

Login where required:

```bash
podman login registry.redhat.io
podman logout registry.redhat.io
```

**You should see** login succeed or "Login Succeeded" when credentials are valid. Credentials are stored in `${XDG_RUNTIME_DIR}/containers/auth.json`.

### 4. Search for and pull an image

```bash
podman search httpd
podman search --limit 5 nginx
podman search --list-tags registry.access.redhat.com/ubi9/httpd-24

podman pull registry.access.redhat.com/ubi9/httpd-24
podman pull registry.access.redhat.com/ubi9/ubi:latest

podman images
podman images --format '{{.Repository}}:{{.Tag}} {{.Size}}'
```

**You should see** search results listing Red Hat and Docker Hub images, then pull progress, then the image in `podman images` with its size and ID.

```text
REPOSITORY                                    TAG      IMAGE ID      CREATED       SIZE
registry.access.redhat.com/ubi9/httpd-24      latest   3f8a2b91c4d5  2 weeks ago   462 MB
registry.access.redhat.com/ubi9/ubi           latest   a1b2c3d4e5f6  3 weeks ago   214 MB
```

**`podman search` needs network access, which the exam does not have.** Expect a local registry or pre-pulled images. Practise the syntax; do not count on Docker Hub.

### 5. Inspect a remote image without pulling (skopeo)

```bash
skopeo inspect docker://registry.access.redhat.com/ubi9/httpd-24
skopeo inspect --config docker://registry.access.redhat.com/ubi9/httpd-24 | head -30
skopeo list-tags docker://registry.access.redhat.com/ubi9/httpd-24
```

**You should see** JSON with image metadata — name, digest, tags, labels, and environment variables — without downloading the full image.

**The `docker://` transport prefix is required** for skopeo. Other transports: `dir:`, `containers-storage:`, `oci:`, `docker-archive:`.

| | `podman inspect` | **`skopeo inspect`** |
| --- | --- | --- |
| Target | **A LOCAL image or container** | **A REMOTE image in a registry** |
| Must pull first | **Yes** | **No** |
| Transport prefix | None | **`docker://` required** |

Now inspect the local copy:

```bash
podman inspect --format '{{.Config.Cmd}}' registry.access.redhat.com/ubi9/httpd-24
podman inspect --format '{{.Config.ExposedPorts}}' registry.access.redhat.com/ubi9/httpd-24
podman inspect --format '{{.Config.Volumes}}' registry.access.redhat.com/ubi9/httpd-24
podman history registry.access.redhat.com/ubi9/httpd-24
```

**You should see** the default command (`/usr/bin/run-httpd`), exposed ports (`8080/tcp`, `8443/tcp`), and layer history. Red Hat httpd images listen on **8080**, not 80.

### 6. Run a one-shot container and a detached service

```bash
podman run --rm registry.access.redhat.com/ubi9/ubi cat /etc/os-release
podman ps -a
```

**You should see** RHEL release information, then **nothing** in `podman ps -a` — `--rm` removes the container when it exits.

Run flags that matter:

| Flag | Meaning |
| --- | --- |
| **`-d`** | **Detached, in the background** |
| **`--name`** | **A name you can refer to** |
| **`-p host:container`** | **Publish a port** |
| **`-v host:container:Z`** | **Bind-mount, with SELinux relabelling** |
| **`-e KEY=value`** | **An environment variable** |
| `-it` | Interactive with a TTY |
| `--rm` | Delete the container when it exits |

```bash
podman run -d --name web -p 8080:8080 registry.access.redhat.com/ubi9/httpd-24
podman ps
```

**You should see** container `web` in `Up` status with `0.0.0.0:8080->8080/tcp` in the PORTS column.

**Always use `--name`.** Without it podman invents something like `nervous_einstein`, and every later command needs the ID.

### 7. Check logs and execute commands inside the container

```bash
podman logs web
podman logs --tail 20 web

podman exec web cat /etc/os-release
podman exec web id
podman exec -it web /bin/bash
```

**You should see** httpd startup messages in the logs, and `uid=1001` from `podman exec web id` — the container runs unprivileged.

Managing containers:

```bash
podman ps                        # running
podman ps -a                     # including stopped
podman stop web
podman start web
podman restart web
```

**You should see** status change from `Up` to `Exited` on stop, back to `Up` on start.

**`podman logs NAME` is the first command when a container will not work.** It shows the application's own stdout and stderr.

| Command | Effect |
| --- | --- |
| **`podman exec web CMD`** | **Runs `CMD` in the already-running `web`** |
| `podman run <image> CMD` | **Creates a NEW container** |

### 8. Publish ports and test connectivity

```bash
podman port web
curl http://localhost:8080
curl -sI http://localhost:8080 | head -1
ss -tlnp | grep 8080
```

**You should see** `8080/tcp -> 0.0.0.0:8080`, an HTTP response (often `HTTP/1.1 200 OK`), and podman listening on port 8080.

**Rootless podman cannot bind a host port below 1024:**

```bash
podman rm -f web
podman run -d --name web -p 80:8080 registry.access.redhat.com/ubi9/httpd-24
```

**You should see** an error like `rootlessport cannot expose privileged port 80`.

Fix with an unprivileged port:

```bash
podman rm -f web 2>/dev/null
podman run -d --name web -p 8080:8080 registry.access.redhat.com/ubi9/httpd-24
```

**Remember the firewall** for remote access — publishing a port makes podman listen, but firewalld still blocks external access:

```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### 9. Serve custom content with a bind mount and `:Z`

Container filesystems are ephemeral. Bind-mount a host directory to persist content.

```bash
mkdir -p ~/webcontent
echo "<h1>hello from the host</h1>" > ~/webcontent/index.html
ls -Zd ~/webcontent

podman rm -f web 2>/dev/null
podman run -d --name web   -p 8080:8080   -v ~/webcontent:/var/www/html:Z   registry.access.redhat.com/ubi9/httpd-24

curl http://localhost:8080
ls -Zd ~/webcontent
```

**You should see** your HTML served, and the directory relabelled to `container_file_t`.

**`:Z` on a bind mount is the most important detail in this entire file.**

| Suffix | Effect |
| --- | --- |
| **`:Z`** | **Relabel with a private SELinux label for this container** |
| `:z` | Relabel with a shared label, for several containers |
| `:ro` | Read-only |
| `:rw` | Read-write (the default) |
| **none** | **No relabelling — SELinux denies access** |

Without `:Z`, the container gets "Permission denied" or HTTP 403 — a MAC denial, not a chmod problem.

### 10. Pass environment variables to a container

```bash
podman run -d --name db \
  -e MYSQL_ROOT_PASSWORD=secret \
  -e MYSQL_DATABASE=appdb \
  registry.redhat.io/rhel9/mariadb-105 2>/dev/null || echo "(skip if image unavailable)"

podman exec db env 2>/dev/null | grep -i mysql || true
podman inspect --format '{{.Config.Env}}' registry.access.redhat.com/ubi9/httpd-24
```

**You should see** environment variables listed for the running container (if the mariadb image is available), and default env vars from the httpd image inspect.

**Read the image's documentation for the variables it needs:**

```bash
podman run --rm registry.access.redhat.com/ubi9/httpd-24 cat /help.1 2>/dev/null | head -20
```

A container that exits immediately usually reports a missing environment variable in `podman logs`.

### 11. Use a named volume for persistent storage

```bash
podman volume create webdata
podman volume ls
podman volume inspect webdata

podman rm -f web 2>/dev/null
podman run -d --name web -p 8080:8080 -v webdata:/var/www/html registry.access.redhat.com/ubi9/httpd-24
podman exec web bash -c 'echo "<h1>volume data</h1>" > /var/www/html/index.html'
curl http://localhost:8080

podman rm -f web
podman run -d --name web2 -p 8080:8080 -v webdata:/var/www/html registry.access.redhat.com/ubi9/httpd-24
curl http://localhost:8080
```

**You should see** the same content after removing and recreating the container. A named volume is created with `container_file_t` already — **no `:Z` needed**.

| | **Bind mount** | **Named volume** |
| --- | --- | --- |
| Location | **A path you choose** | Managed by podman |
| SELinux | **Needs `:Z`** | **Correct automatically** |
| Best for | **Content you edit on the host** | **Application data** |

### 12. See where things live and check disk usage

```bash
ls ~/.local/share/containers/storage/
ls ~/.config/containers/
podman info --format '{{.Store.GraphRoot}}'
podman system df
```

**You should see** storage paths under your home directory and a summary of images, containers, and volumes with sizes.

```bash
podman rm -f web2 2>/dev/null
podman container prune -f
podman system df
```

Reclaim space when needed:

```bash
podman system prune -a --volumes   # aggressive — deletes unused volumes too
```

**You should see** reclaimable space decrease after pruning. Use `skopeo copy` to move images between registries without a local pull — covered in the practice tasks.

### Mini checkpoint

Before the practice tasks, you should be able to explain:

| Concept | Key point |
| --- | --- |
| Rootless vs rootful | **Separate storage, images, and containers** |
| Fully qualified names | **`registry.access.redhat.com/ubi9/httpd-24`** |
| `skopeo inspect` | **Remote inspect without pull; `docker://` prefix required** |
| `-p HOST:CONTAINER` | **Host port first; Red Hat httpd uses 8080** |
| `--name` | **Always use it** |
| `:Z` on bind mounts | **Required for SELinux enforcing** |
| Named volumes | **No `:Z` needed** |
| `podman logs` | **First command when something fails** |
| `podman exec` vs `run` | **exec = existing container; run = new container** |
| Rootless ports | **Cannot bind host ports below 1024** |
| Persistence | **Container stops at reboot; need systemd unit** |

If any row is blank in your head, re-run the step above that covers it.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Install the container tools and confirm podman and skopeo are available. Report whether you are in rootless or rootful mode.

> Hint: `dnf install container-tools`; `podman info --format '{{.Host.Security.Rootless}}'`.

**Task 2.** Explain and demonstrate the difference between `podman images` and `sudo podman images`.

> Hint: pull an image as your user, then compare both commands and the two `GraphRoot` paths.

**Task 3.** Examine the registry configuration and list the registries searched for an unqualified image name.

> Hint: `/etc/containers/registries.conf` and `podman info | grep -i registries`.

**Task 4.** Search a registry for an httpd image and list its available tags.

> Hint: `podman search` and `podman search --list-tags`; `skopeo list-tags docker://...`.

**Task 5.** Inspect a remote image **without downloading it**, reporting its command, exposed ports, and environment variables.

> Hint: `skopeo inspect docker://...` and `skopeo inspect --config docker://...`.

**Task 6.** Pull the UBI 9 httpd image and confirm it is present locally, with its size and ID.

> Hint: fully qualified pull; `podman images` and `podman image exists`.

**Task 7.** Inspect the pulled image and report the default command, the exposed port, and any declared volumes.

> Hint: `podman inspect --format '{{.Config....}}'` for Cmd, ExposedPorts, and Volumes.

**Task 8.** Run a container from the UBI base image that prints the contents of `/etc/os-release` and then exits, leaving nothing behind.

> Hint: `--rm` flag; verify with `podman ps -a`.

**Task 9.** Run an interactive shell inside a container, create a file, exit, and demonstrate that the file is gone once the container is removed.

> Hint: `-it --name`; `podman rm` destroys the writable layer; compare stop vs rm.

**Task 10.** Run the httpd image detached, named `web`, publishing its port so it is reachable from the host, and verify with `curl`.

> Hint: check `ExposedPorts` first — 8080, not 80; `-d --name web -p 8080:8080`.

**Task 11.** Report the logs of the running container, then execute a command inside it without stopping it.

> Hint: `podman logs web`; `podman exec web ...` (not `podman run`).

**Task 12.** Serve custom content from a host directory using a bind mount, with SELinux enforcing.

> Hint: `-v ~/dir:/var/www/html:Z`; confirm with `curl` and `ls -Z`.

**Task 13.** Demonstrate what happens if you omit `:Z` on a bind mount, and diagnose the failure properly.

> Hint: expect 403 or Permission denied; check `podman logs`, `ausearch -m AVC`, and compare with `:Z` fix.

**Task 14.** Create a named volume, use it for persistent storage, and prove the data survives removing and recreating the container.

> Hint: `podman volume create`; mount with `-v volname:/path`; rm container, recreate, curl again.

**Task 15.** Run a database container passing the environment variables it requires, and verify they took effect.

> Hint: `-e MYSQL_ROOT_PASSWORD=...` etc.; `podman exec db env | grep MYSQL`; `podman logs` if it exits.

**Task 16.** Stop, start, restart, and remove containers. Show how to remove all stopped containers at once.

> Hint: `podman stop/start/restart`; `podman rm -a` or `podman container prune`.

**Task 17.** Attempt to publish port 80 as a rootless user, diagnose the error, and give two ways to solve it.

> Hint: rootless cannot bind ports < 1024; use 8080, rootful, sysctl, or firewalld forwarding.

**Task 18.** Make a containerised web server reachable from another machine.

> Hint: `-p 8080:8080` (not 127.0.0.1); `firewall-cmd --permanent --add-port=8080/tcp` + `--reload`.

**Task 19.** Report the disk space used by images, containers, and volumes, and reclaim it.

> Hint: `podman system df`; prune with `container prune`, `image prune`, `system prune -a --volumes`.

**Task 20.** Copy an image between registries, or export one to a local directory, using skopeo.

> Hint: `skopeo copy docker://src docker://dst` or `skopeo copy docker://img dir:/tmp/path`.

---

## Solutions

**Task 1.**

```bash
sudo dnf install -y container-tools
```

Or individually:

```bash
sudo dnf install -y podman skopeo buildah
rpm -q podman skopeo buildah
podman --version
skopeo --version
```

```text
podman version 5.2.2
skopeo version 1.16.1
```

```bash
podman info | grep -i rootless
podman info --format '{{.Host.Security.Rootless}}'
whoami
id
```

```text
  rootless: true
true
douglas
```

**`rootless: true` means containers run in your user namespace**, with storage under your home directory and no root privileges. Compare:

```bash
sudo podman info --format '{{.Host.Security.Rootless}}'
```

```text
false
```

More detail:

```bash
podman info
podman info --format '{{.Store.GraphRoot}}'
podman info --format '{{.Host.OS}} {{.Host.Arch}}'
```

```text
/home/douglas/.local/share/containers/storage
```

```bash
sudo podman info --format '{{.Store.GraphRoot}}'
```

```text
/var/lib/containers/storage
```

**Two completely separate storage trees.** That is the source of most podman confusion — see Task 2.

`container-tools` also provides `buildah` for building images, which is not an RHCSA objective but is worth recognising.

**Task 2.**

```bash
podman pull registry.access.redhat.com/ubi9/ubi
podman images
```

```text
REPOSITORY                            TAG     IMAGE ID      CREATED      SIZE
registry.access.redhat.com/ubi9/ubi   latest  a1b2c3d4e5f6  3 weeks ago  214 MB
```

```bash
sudo podman images
```

```text
REPOSITORY  TAG  IMAGE ID  CREATED  SIZE
```

**Empty.** The image you just pulled is invisible to root.

```bash
podman info --format '{{.Store.GraphRoot}}'
sudo podman info --format '{{.Store.GraphRoot}}'
```

```text
/home/douglas/.local/share/containers/storage
/var/lib/containers/storage
```

**Two entirely separate storage trees, two separate sets of images and containers.**

| | `podman` (rootless) | `sudo podman` (rootful) |
| --- | --- | --- |
| Storage | **`~/.local/share/containers/storage`** | **`/var/lib/containers/storage`** |
| Images | Yours only | root's only |
| Containers | Yours only | root's only |
| Volumes | `~/.local/share/containers/storage/volumes` | `/var/lib/containers/storage/volumes` |
| Ports < 1024 | **Refused** | Allowed |
| systemd units | **`~/.config/systemd/user/`** | **`/etc/systemd/system/`** |
| Survives logout | **Only with `loginctl enable-linger`** | Yes |
| Config | `~/.config/containers/` | `/etc/containers/` |

**And each user is separate from every other user:**

```bash
sudo -u alice podman images         # alice's own set, also empty
```

**Practical consequences on the exam:**

- **Be consistent.** If you pull as your user, run as your user. Mixing `podman pull` with `sudo podman run` gives "image not found".
- **"As the user alice" means rootless, as alice** — use `su - alice` and work in her session, not `sudo podman`.
- **A container as a system service usually means rootful**, or rootless with lingering. See `35-containers-systemd.md`.
- **`podman ps` showing nothing does not mean nothing is running.** Check both.

```bash
podman ps -a
sudo podman ps -a
```

**Task 3.**

```bash
cat /etc/containers/registries.conf
grep -v '^#' /etc/containers/registries.conf | grep -v '^$'
```

```ini
unqualified-search-registries = ["registry.access.redhat.com", "registry.redhat.io", "docker.io"]
short-name-mode = "enforcing"
```

```bash
podman info | grep -A6 -i 'registries'
ls /etc/containers/registries.conf.d/
```

**`unqualified-search-registries` is the search order** for an image name without a registry prefix:

```bash
podman pull ubi9/ubi
```

podman tries `registry.access.redhat.com/ubi9/ubi`, then `registry.redhat.io/...`, then `docker.io/...`.

**With `short-name-mode = "enforcing"`, podman prompts you to choose rather than guessing:**

```text
? Please select an image:
  ▸ registry.access.redhat.com/ubi9/ubi:latest
    registry.redhat.io/ubi9/ubi:latest
    docker.io/ubi9/ubi:latest
```

**Always use the fully qualified name.** It is unambiguous, it avoids the prompt, and it is what a grader expects:

```bash
podman pull registry.access.redhat.com/ubi9/ubi:latest       # good
podman pull ubi9/ubi                                          # ambiguous
```

The registries in order:

| Registry | Login | Content |
| --- | --- | --- |
| **`registry.access.redhat.com`** | **None** | **Free Red Hat images, including UBI** |
| `registry.redhat.io` | **Required** | The full Red Hat catalogue |
| `docker.io` | Optional | Docker Hub |
| `quay.io` | Optional | Red Hat's Quay |

Adding a local registry with a drop-in:

```bash
sudo mkdir -p /etc/containers/registries.conf.d
sudo tee /etc/containers/registries.conf.d/99-local.conf >/dev/null <<'EOF'
[[registry]]
location = "registry.lab.example.com:5000"
insecure = true
EOF

podman info | grep -A12 -i registries
podman pull registry.lab.example.com:5000/myimage:latest
```

**`insecure = true` permits plain HTTP or a self-signed certificate**, which a classroom registry usually needs. **Drop-ins in `registries.conf.d/` are preferred to editing `registries.conf`** — the same pattern as everywhere else on this exam.

Logging in where required:

```bash
podman login registry.redhat.io
podman login --get-login registry.redhat.io
podman logout --all
```

**Task 4.**

```bash
podman search httpd
podman search --limit 5 httpd
podman search registry.access.redhat.com/ubi9
podman search --filter is-official=true nginx
```

```text
NAME                                            DESCRIPTION
registry.access.redhat.com/ubi9/httpd-24        Apache HTTP 2.4 Server
registry.access.redhat.com/ubi8/httpd-24        Apache HTTP 2.4 Server
docker.io/library/httpd                         The Apache HTTP Server Project
```

Tags:

```bash
podman search --list-tags registry.access.redhat.com/ubi9/httpd-24
skopeo list-tags docker://registry.access.redhat.com/ubi9/httpd-24
```

```text
NAME                                      TAG
registry.access.redhat.com/ubi9/httpd-24  1-215
registry.access.redhat.com/ubi9/httpd-24  1-226
registry.access.redhat.com/ubi9/httpd-24  latest
```

**`skopeo list-tags` is the more reliable of the two**, and it works against any registry with the `docker://` prefix.

**The exam has no internet access**, so `podman search` against Docker Hub will fail:

```text
Error: no registries found in registries.conf, a registry must be provided
```

or a timeout. **Expect a local registry or pre-pulled images:**

```bash
podman images                              # what is already here?
sudo podman images
podman search registry.lab.example.com:5000/
skopeo list-tags docker://registry.lab.example.com:5000/httpd
```

**Practise the syntax; do not depend on the network.** And prefer a specific tag over `latest` when a task names a version:

```bash
podman pull registry.access.redhat.com/ubi9/httpd-24:1-226
```

**Task 5.**

```bash
skopeo inspect docker://registry.access.redhat.com/ubi9/httpd-24
```

```json
{
    "Name": "registry.access.redhat.com/ubi9/httpd-24",
    "Digest": "sha256:3f8a2b91...",
    "RepoTags": ["1-215", "1-226", "latest"],
    "Created": "2026-08-04T10:22:31Z",
    "Architecture": "amd64",
    "Os": "linux",
    "Labels": {
        "description": "Apache HTTP 2.4 Server",
        "io.openshift.expose-services": "8080:http,8443:https",
        "name": "ubi9/httpd-24",
        "version": "1"
    },
    "Env": [
        "PATH=/opt/rh/httpd24/root/usr/bin:...",
        "HTTPD_VERSION=2.4",
        "HTTPD_CONFIGURATION_PATH=/opt/app-root/etc/httpd.d"
    ]
}
```

The image's own configuration:

```bash
skopeo inspect --config docker://registry.access.redhat.com/ubi9/httpd-24
skopeo inspect --config docker://registry.access.redhat.com/ubi9/httpd-24 | \
  python3 -m json.tool | grep -A5 -i 'cmd\|exposedports'
```

Specific fields:

```bash
skopeo inspect docker://registry.access.redhat.com/ubi9/httpd-24 --format '{{.Env}}'
skopeo list-tags docker://registry.access.redhat.com/ubi9/httpd-24
```

**The point of `skopeo` is inspecting an image without pulling it.** A container image is hundreds of megabytes; `skopeo inspect` transfers only the manifest:

| | `podman inspect` | **`skopeo inspect`** |
| --- | --- | --- |
| Target | **A LOCAL image or container** | **A REMOTE image in a registry** |
| Must pull first | **Yes** | **No** |
| Transport prefix | None | **`docker://` required** |
| Speed | Instant | One small network request |

```bash
podman inspect registry.access.redhat.com/ubi9/httpd-24        # fails if not pulled
skopeo inspect docker://registry.access.redhat.com/ubi9/httpd-24   # works either way
```

**The `docker://` prefix is mandatory** and easy to forget:

```text
$ skopeo inspect registry.access.redhat.com/ubi9/httpd-24
FATA[0000] Invalid image name ..., unknown transport
```

Transports:

| Transport | Refers to |
| --- | --- |
| **`docker://`** | **A registry** |
| `containers-storage:` | Local podman storage |
| `dir:` | A directory on disk |
| `oci:` | An OCI layout directory |
| `docker-archive:` | A `docker save` tarball |

**`io.openshift.expose-services: 8080:http` in the labels tells you which port to publish** — 8080, not 80, for Red Hat's httpd images. That detail matters in Task 10.

**Task 6.**

```bash
podman pull registry.access.redhat.com/ubi9/httpd-24
```

```text
Trying to pull registry.access.redhat.com/ubi9/httpd-24:latest...
Getting image source signatures
Copying blob sha256:a1b2c3... done
Copying blob sha256:d4e5f6... done
Copying config sha256:3f8a2b... done
Writing manifest to image destination
3f8a2b91c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1
```

```bash
podman images
```

```text
REPOSITORY                                TAG     IMAGE ID      CREATED      SIZE
registry.access.redhat.com/ubi9/httpd-24  latest  3f8a2b91c4d5  2 weeks ago  462 MB
```

```bash
podman images --format '{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}'
podman image exists registry.access.redhat.com/ubi9/httpd-24 && echo "present"
podman image ls --filter reference='*httpd*'
```

**`podman image exists` returns an exit status with no output**, which makes it right for scripts:

```bash
if podman image exists registry.access.redhat.com/ubi9/httpd-24; then
    echo "already pulled"
fi
```

Where it went:

```bash
podman info --format '{{.Store.GraphRoot}}'
du -sh ~/.local/share/containers/storage
podman system df
```

```text
TYPE           TOTAL  ACTIVE  SIZE     RECLAIMABLE
Images         2      0       676 MB   676 MB (100%)
Containers     0      0       0B       0B
Local Volumes  0      0       0B       0B
```

Tags and digests:

```bash
podman pull registry.access.redhat.com/ubi9/httpd-24:1-226            # a specific tag
podman pull registry.access.redhat.com/ubi9/httpd-24@sha256:3f8a2b91  # a digest
podman tag registry.access.redhat.com/ubi9/httpd-24 myhttpd:v1
podman images
```

**`podman tag` creates a local alias** with no new download — the image ID is unchanged.

**And remember which user pulled it:**

```bash
podman images                    # yours
sudo podman images               # root's — this image is NOT here
```

**Task 7.**

```bash
podman inspect registry.access.redhat.com/ubi9/httpd-24 | less
```

The specific fields:

```bash
podman inspect --format '{{.Config.Cmd}}' registry.access.redhat.com/ubi9/httpd-24
podman inspect --format '{{.Config.ExposedPorts}}' registry.access.redhat.com/ubi9/httpd-24
podman inspect --format '{{.Config.Volumes}}' registry.access.redhat.com/ubi9/httpd-24
podman inspect --format '{{.Config.Env}}' registry.access.redhat.com/ubi9/httpd-24
podman inspect --format '{{.Config.WorkingDir}}' registry.access.redhat.com/ubi9/httpd-24
podman inspect --format '{{.Config.User}}' registry.access.redhat.com/ubi9/httpd-24
```

```text
[/usr/bin/run-httpd]
map[8080/tcp:{} 8443/tcp:{}]
map[]
[PATH=... HTTPD_VERSION=2.4 APP_ROOT=/opt/app-root ...]
/opt/app-root/src
1001
```

**Four things that determine how you run it:**

| Field | Value | Consequence |
| --- | --- | --- |
| **`Cmd`** | `/usr/bin/run-httpd` | **Runs automatically; no command argument needed** |
| **`ExposedPorts`** | **`8080/tcp`, `8443/tcp`** | **Publish 8080, not 80** |
| `Volumes` | empty | No declared volumes; bind-mount where the app expects content |
| **`User`** | **`1001`** | **Runs unprivileged, which is why it uses 8080** |

**`ExposedPorts 8080` is the detail people get wrong.** Red Hat images run as a non-root user inside the container, so they cannot bind 80 and use 8080 instead:

```bash
podman run -d --name web -p 8080:8080 <image>        # correct
podman run -d --name web -p 8080:80 <image>          # nothing listening on 80 inside
```

Human-readable documentation, if the image ships it:

```bash
podman run --rm registry.access.redhat.com/ubi9/httpd-24 cat /help.1 2>/dev/null | head -40
podman inspect --format '{{.Labels}}' registry.access.redhat.com/ubi9/httpd-24
podman inspect --format '{{index .Labels "io.openshift.expose-services"}}' registry.access.redhat.com/ubi9/httpd-24
```

```text
8080:http,8443:https
```

Layer history:

```bash
podman history registry.access.redhat.com/ubi9/httpd-24
podman history --no-trunc <image> | head
```

**Where the content directory is** matters for Task 12. For Red Hat's httpd-24, it is `/var/www/html`:

```bash
podman run --rm <image> ls -la /var/www/html
podman run --rm <image> cat /etc/httpd/conf/httpd.conf | grep -i documentroot
```

**Task 8.**

```bash
podman run --rm registry.access.redhat.com/ubi9/ubi cat /etc/os-release
```

```text
NAME="Red Hat Enterprise Linux"
VERSION="9.4 (Plow)"
ID="rhel"
PLATFORM_ID="platform:el9"
PRETTY_NAME="Red Hat Enterprise Linux 9.4 (Plow)"
```

```bash
podman ps -a
```

```text
CONTAINER ID  IMAGE  COMMAND  CREATED  STATUS  PORTS  NAMES
```

**Nothing left behind.** Compare without `--rm`:

```bash
podman run registry.access.redhat.com/ubi9/ubi cat /etc/os-release
podman ps -a
```

```text
CONTAINER ID  IMAGE                    COMMAND               CREATED         STATUS                    NAMES
7a8b9c0d1e2f  .../ubi9/ubi:latest      cat /etc/os-release   5 seconds ago   Exited (0) 4 seconds ago  vibrant_bohr
```

**The container persists in `Exited` state, with a random name, consuming disk.** Clean up:

```bash
podman rm 7a8b9c0d1e2f
podman rm -a                     # every stopped container
podman container prune -f
```

**`--rm` deletes the container as soon as its process exits**, which is what you want for a one-shot command:

| Usage | Flags |
| --- | --- |
| **A one-shot command** | **`--rm`** |
| **An interactive shell** | **`--rm -it`** |
| **A long-running service** | **`-d --name`** (no `--rm`) |

```bash
podman run --rm <image> command                      # one-shot
podman run --rm -it <image> /bin/bash                # throwaway shell
podman run -d --name web <image>                     # a service
```

**Note that a command argument overrides the image's `Cmd`:**

```bash
podman run --rm <image>                              # runs the default Cmd
podman run --rm <image> cat /etc/os-release          # runs this instead
podman run --rm <image> /bin/bash -c 'id; hostname'
```

**Task 9.**

```bash
podman run -it --name shelltest registry.access.redhat.com/ubi9/ubi /bin/bash
```

```text
[root@7a8b9c0d1e2f /]#
```

Inside:

```bash
echo "this will not survive" > /root/ephemeral.txt
cat /root/ephemeral.txt
ls -l /root/
id
hostname
exit
```

The container has stopped but still exists:

```bash
podman ps -a
```

```text
CONTAINER ID  IMAGE                COMMAND     CREATED  STATUS                   NAMES
7a8b9c0d1e2f  .../ubi9/ubi:latest  /bin/bash   1m ago   Exited (0) 5 seconds ago shelltest
```

**The file is still there, because the container's writable layer still exists:**

```bash
podman start shelltest
podman exec shelltest cat /root/ephemeral.txt
```

```text
this will not survive
```

```bash
podman diff shelltest
```

```text
A /root/ephemeral.txt
C /root
```

Now remove it:

```bash
podman stop shelltest
podman rm shelltest
podman ps -a
```

Start a fresh container from the same image:

```bash
podman run --rm registry.access.redhat.com/ubi9/ubi cat /root/ephemeral.txt
```

```text
cat: /root/ephemeral.txt: No such file or directory
```

**Gone.** The lifecycle:

```text
   IMAGE  (read-only, shared by every container)
     │
     │  podman run
     ▼
   CONTAINER = image + a writable layer
     │
     ├─ podman stop   → the writable layer SURVIVES
     ├─ podman start  → data is still there
     └─ podman rm     → the writable layer is DESTROYED
```

| Action | Data written inside |
| --- | --- |
| `podman stop` | **Survives** |
| `podman start` | Still there |
| `podman restart` | Still there |
| **`podman rm`** | **DESTROYED** |
| `podman run --rm` | Destroyed on exit |

**This is why persistent storage matters.** Any data that must outlive the container needs a bind mount or a named volume — Tasks 12 and 14.

**Task 10.**

```bash
podman inspect --format '{{.Config.ExposedPorts}}' registry.access.redhat.com/ubi9/httpd-24
```

```text
map[8080/tcp:{} 8443/tcp:{}]
```

```bash
podman run -d --name web -p 8080:8080 registry.access.redhat.com/ubi9/httpd-24
```

```text
9c1b2d5a8f3e4b7c1a2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b
```

```bash
podman ps
```

```text
CONTAINER ID  IMAGE                     COMMAND               STATUS         PORTS                   NAMES
9c1b2d5a8f3e  .../ubi9/httpd-24:latest  /usr/bin/run-httpd    Up 10 seconds  0.0.0.0:8080->8080/tcp  web
```

```bash
podman port web
ss -tlnp | grep 8080
curl http://localhost:8080
curl -sI http://localhost:8080 | head -1
```

```text
8080/tcp -> 0.0.0.0:8080
HTTP/1.1 200 OK
```

**The three flags that matter:**

| Flag | Purpose |
| --- | --- |
| **`-d`** | **Detached — returns immediately and keeps running** |
| **`--name web`** | **A name for every later command** |
| **`-p 8080:8080`** | **hostPort:containerPort** |

**`-p HOST:CONTAINER` — the host port is first.** And the container port must match what the application actually listens on:

```bash
podman run -d --name web -p 8080:8080 <image>        # correct for this image
podman run -d --name web -p 8080:80 <image>          # nothing on 80 inside → connection reset
```

**Always check `ExposedPorts` first.** Red Hat images use 8080 because they run as an unprivileged user inside the container.

**`--name` is worth insisting on.** Without it:

```bash
podman run -d <image>
podman ps                        # NAMES: nervous_einstein
podman logs nervous_einstein
```

Other port forms:

```bash
podman run -d --name web -p 8080:8080 <image>
podman run -d --name web -p 127.0.0.1:8080:8080 <image>    # localhost only
podman run -d --name web -P <image>                         # all exposed ports, random host ports
podman port web
```

If it does not respond:

```bash
podman ps -a                     # is it running or did it exit?
podman logs web                  # what did the application say?
podman port web                  # is the mapping there?
ss -tlnp | grep 8080             # is podman listening?
podman inspect web | grep -i -A5 state
```

**`podman logs web` is the first command when a container misbehaves.**

**Task 11.**

```bash
podman logs web
podman logs --tail 20 web
podman logs -f web               # follow; Ctrl-C to stop
podman logs --since 5m web
podman logs -t web               # with timestamps
```

```text
=> sourcing 10-set-mpm.sh ...
=> sourcing 20-copy-config.sh ...
=> sourcing 40-ssl-certs.sh ...
AH00558: httpd: Could not reliably determine the server's fully qualified domain name
[Mon Aug 18 17:30:12.123456 2026] [core:notice] [pid 1] AH00094: Command line: 'httpd -D FOREGROUND'
```

Executing commands inside the running container:

```bash
podman exec web cat /etc/os-release
podman exec web ls -la /var/www/html
podman exec web id
podman exec web env
podman exec web ps aux
podman exec -it web /bin/bash
```

```text
$ podman exec web id
uid=1001(default) gid=0(root) groups=0(root),1001
```

**`uid=1001`, not root.** That is why the image listens on 8080.

Inside the interactive shell:

```bash
podman exec -it web /bin/bash
```

```bash
cat /etc/httpd/conf/httpd.conf | grep -i documentroot
ls -la /var/www/html
curl http://localhost:8080
exit
```

**`exec` runs a new process in an existing container; `run` creates a new container.** Confusing them is common:

| Command | Effect |
| --- | --- |
| **`podman exec web CMD`** | **Runs `CMD` in the already-running `web`** |
| `podman run <image> CMD` | **Creates a NEW container** |
| `podman attach web` | Attaches to the main process's stdio |
| `podman logs web` | The main process's captured output |

**`podman exec` requires the container to be running:**

```text
$ podman exec web ls
Error: can only create exec sessions on running containers: container state improper
```

```bash
podman ps                        # running?
podman start web
podman exec web ls
```

Other inspection commands:

```bash
podman top web                   # processes inside
podman stats --no-stream web     # CPU and memory
podman inspect web | less
podman inspect --format '{{.State.Status}}' web
podman inspect --format '{{.NetworkSettings.IPAddress}}' web
podman diff web                  # filesystem changes since the image
podman healthcheck run web 2>/dev/null
```

**Task 12.**

```bash
mkdir -p ~/webcontent
echo "<h1>Served from a bind mount</h1>" > ~/webcontent/index.html
ls -Zd ~/webcontent
```

```text
unconfined_u:object_r:user_home_t:s0 /home/douglas/webcontent
```

```bash
podman rm -f web 2>/dev/null
podman run -d --name web \
  -p 8080:8080 \
  -v ~/webcontent:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24

podman ps
curl http://localhost:8080
```

```text
<h1>Served from a bind mount</h1>
```

Look at what `:Z` did:

```bash
ls -Zd ~/webcontent
ls -Z ~/webcontent/index.html
```

```text
unconfined_u:object_r:container_file_t:s0:c123,c456 /home/douglas/webcontent
unconfined_u:object_r:container_file_t:s0:c123,c456 /home/douglas/webcontent/index.html
```

**`:Z` relabelled the host directory to `container_file_t` with a category pair unique to this container.** Without that label, the container process cannot read the files at all — see Task 13.

Prove the persistence:

```bash
echo "<h1>Updated content</h1>" > ~/webcontent/index.html
curl http://localhost:8080                     # updated immediately

podman rm -f web
ls -l ~/webcontent/                            # still there
cat ~/webcontent/index.html

podman run -d --name web2 -p 8080:8080 -v ~/webcontent:/var/www/html:Z <image>
curl http://localhost:8080                     # same content
```

**The data lives on the host, so it survives the container entirely.**

| Suffix | Effect |
| --- | --- |
| **`:Z`** | **Relabel with a PRIVATE category — one container only** |
| `:z` | Relabel with a SHARED label — several containers |
| `:ro` | Read-only inside the container |
| `:Z,ro` | Both |
| **none** | **No relabelling — SELinux denies access** |

```bash
podman run -d --name web -v ~/webcontent:/var/www/html:Z <image>       # one container
podman run -d --name w1 -v /srv/shared:/data:z <image>                 # shared
podman run -d --name w2 -v /srv/shared:/data:z <image>                 # both can read
podman run -d --name web -v ~/webcontent:/var/www/html:Z,ro <image>    # read-only
```

**Be careful with `:Z` on a system directory.** It relabels recursively, so `-v /etc:/etc:Z` would relabel all of `/etc` to `container_file_t` and break the host. **Only use `:Z` on directories created for the container.**

Rootless ownership, if the container cannot write:

```bash
podman unshare chown -R 1001:1001 ~/webcontent
ls -ln ~/webcontent
```

**`podman unshare` runs a command inside the user namespace**, which is how you set an owner that matches the container's UID.

**Task 13.**

```bash
mkdir -p ~/badcontent
echo "<h1>test</h1>" > ~/badcontent/index.html
ls -Zd ~/badcontent
```

```text
unconfined_u:object_r:user_home_t:s0 /home/douglas/badcontent
```

```bash
podman rm -f web 2>/dev/null
podman run -d --name web -p 8080:8080 -v ~/badcontent:/var/www/html registry.access.redhat.com/ubi9/httpd-24
curl http://localhost:8080
```

```text
<!DOCTYPE HTML ...>
<title>403 Forbidden</title>
```

or the container fails outright. **Diagnose it properly rather than guessing.**

```bash
# 1. What does the container say?
podman logs web
```

```text
(13)Permission denied: AH00035: access to /index.html denied
```

```bash
# 2. Are there AVC denials?  (27-selinux.md)
sudo ausearch -m AVC -ts recent | tail -20
```

```text
avc: denied { read } for pid=4567 comm="httpd"
  name="index.html"
  scontext=system_u:system_r:container_t:s0:c123,c456
  tcontext=unconfined_u:object_r:user_home_t:s0
  tclass=file permissive=0
```

**Read the two contexts.** The process is `container_t`; the file is `user_home_t`. **A container process may only read `container_file_t`**, so the access is denied.

```bash
# 3. Confirm by testing in permissive mode — briefly
sudo setenforce 0
curl http://localhost:8080                     # now it works
sudo setenforce 1                              # PUT IT BACK
```

```bash
# 4. Look at the label
ls -Zd ~/badcontent
```

```text
unconfined_u:object_r:user_home_t:s0 /home/douglas/badcontent
```

**Two correct fixes.**

**Fix A — use `:Z`, which is the answer a task expects:**

```bash
podman rm -f web
podman run -d --name web -p 8080:8080 -v ~/badcontent:/var/www/html:Z <image>
ls -Zd ~/badcontent
curl http://localhost:8080
```

```text
unconfined_u:object_r:container_file_t:s0:c123,c456 /home/douglas/badcontent
```

**Fix B — set the label persistently with `semanage`**, which is right when several containers or a permanent directory are involved:

```bash
sudo semanage fcontext -a -t container_file_t "/srv/webcontent(/.*)?"
sudo restorecon -Rv /srv/webcontent
podman run -d --name web -p 8080:8080 -v /srv/webcontent:/var/www/html <image>
```

**What NOT to do:**

```bash
sudo setenforce 0                              # disables SELinux — fails the exam
podman run --privileged ...                    # disables the container's confinement
podman run --security-opt label=disable ...     # disables SELinux for the container
chmod 777 ~/badcontent                          # does not touch SELinux at all
```

**`chmod 777` does not help**, because this is a MAC denial, not a DAC one — both layers must allow. See `27-selinux.md`.

**The diagnostic pattern to remember:** a container that starts but reports "Permission denied" on a bind-mounted path is a missing `:Z`, essentially always.

| Symptom | Cause | Fix |
| --- | --- | --- |
| **`Permission denied` on a bind mount** | **Missing `:Z`** | **Add `:Z`** |
| 403 from a web container with a bind mount | Missing `:Z` | Add `:Z` |
| AVC with `tcontext=...user_home_t` | Missing `:Z` | Add `:Z` |
| Cannot **write** to a mount with `:Z` present | UID mismatch | `podman unshare chown` |
| `:Z` on `/etc` broke the host | Recursive relabel | `restorecon -Rv /etc` |

**Task 14.**

```bash
podman volume create webdata
podman volume ls
podman volume inspect webdata
```

```text
DRIVER  VOLUME NAME
local   webdata
```

```text
[
     {
          "Name": "webdata",
          "Driver": "local",
          "Mountpoint": "/home/douglas/.local/share/containers/storage/volumes/webdata/_data",
          "CreatedAt": "2026-08-18T17:45:00Z"
     }
]
```

```bash
podman rm -f web 2>/dev/null
podman run -d --name web -p 8080:8080 -v webdata:/var/www/html registry.access.redhat.com/ubi9/httpd-24
podman exec web bash -c 'echo "<h1>From a named volume</h1>" > /var/www/html/index.html'
curl http://localhost:8080
```

```text
<h1>From a named volume</h1>
```

**Now destroy the container and prove the data survives:**

```bash
podman rm -f web
podman ps -a                                   # gone
podman volume ls                               # the volume remains

podman run -d --name web-new -p 8080:8080 -v webdata:/var/www/html <image>
curl http://localhost:8080
```

```text
<h1>From a named volume</h1>
```

**Same data in a brand-new container.**

Where it lives:

```bash
podman volume inspect webdata --format '{{.Mountpoint}}'
ls -lZ $(podman volume inspect webdata --format '{{.Mountpoint}}')
```

```text
-rw-r--r--. 1 douglas douglas system_u:object_r:container_file_t:s0 index.html
```

**A named volume is created with `container_file_t` already, so no `:Z` is needed.** That is one of its advantages.

| | **Bind mount** (`-v /host/path:/ctr`) | **Named volume** (`-v name:/ctr`) |
| --- | --- | --- |
| Location | **A path you choose** | Managed by podman |
| SELinux | **Needs `:Z`** | **Correct automatically** |
| Host access | **Direct and easy** | Through the volume path |
| Portability | Tied to that path | **Portable** |
| Ownership issues | Common when rootless | Fewer |
| Best for | **Content you edit on the host** | **Application data** |

Managing volumes:

```bash
podman volume ls
podman volume inspect webdata
podman volume rm webdata                       # fails if a container uses it
podman volume rm -f webdata
podman volume prune                            # remove unused volumes
podman volume create --opt device=/dev/sdb1 --opt type=xfs mydata
```

```text
$ podman volume rm webdata
Error: volume webdata is being used by the following container(s): web-new
```

```bash
podman rm -f web-new
podman volume rm webdata
```

**Which to use on the exam:** a task saying "attach persistent storage" is satisfied by either. **A bind mount is usually clearer**, because the content is visible in an ordinary directory the grader can check — just remember `:Z`.

**Task 15.**

```bash
podman inspect --format '{{.Config.Env}}' registry.redhat.io/rhel9/mariadb-105 2>/dev/null
podman run --rm registry.redhat.io/rhel9/mariadb-105 cat /help.1 2>/dev/null | head -40
```

```bash
podman volume create dbdata

podman run -d --name db \
  -e MYSQL_ROOT_PASSWORD=redhat123 \
  -e MYSQL_DATABASE=appdb \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=apppass \
  -p 3306:3306 \
  -v dbdata:/var/lib/mysql/data \
  registry.redhat.io/rhel9/mariadb-105

podman ps
podman logs db
```

Verify the variables took effect:

```bash
podman exec db env | grep -i mysql
podman inspect --format '{{.Config.Env}}' db
```

```text
MYSQL_ROOT_PASSWORD=redhat123
MYSQL_DATABASE=appdb
MYSQL_USER=appuser
MYSQL_PASSWORD=apppass
```

And that the database was actually created:

```bash
podman exec db mysql -uroot -predhat123 -e 'SHOW DATABASES;'
podman exec -it db mysql -uappuser -papppass appdb -e 'SELECT 1;'
```

```text
+--------------------+
| Database           |
+--------------------+
| appdb              |
| information_schema |
| mysql              |
+--------------------+
```

**Environment variables are how you configure a container** — there is no configuration file to edit from outside:

```bash
podman run -e KEY=value <image>
podman run -e KEY1=v1 -e KEY2=v2 <image>
podman run --env-file /root/db.env <image>
podman run -e EXISTING_HOST_VAR <image>        # pass through from the host
```

An env file:

```bash
sudo tee /root/db.env >/dev/null <<'EOF'
MYSQL_ROOT_PASSWORD=redhat123
MYSQL_DATABASE=appdb
MYSQL_USER=appuser
MYSQL_PASSWORD=apppass
EOF
sudo chmod 600 /root/db.env
podman run -d --name db --env-file /root/db.env <image>
```

**An env file keeps passwords off the command line**, where they would otherwise appear in `ps` and shell history. `chmod 600` it.

**If a required variable is missing, the container exits immediately:**

```bash
podman run -d --name db2 registry.redhat.io/rhel9/mariadb-105
podman ps -a
podman logs db2
```

```text
STATUS: Exited (1) 2 seconds ago

You must either specify the following environment variables:
  MYSQL_USER  MYSQL_PASSWORD  MYSQL_DATABASE
Or the following environment variable:
  MYSQL_ROOT_PASSWORD
```

**`podman logs` tells you exactly what is missing.** A container that exits straight after starting is nearly always a configuration problem, and `podman logs` names it.

```bash
podman rm db2
```

**Task 16.**

```bash
podman ps
podman ps -a
podman ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'
podman ps -a --filter status=exited
podman ps -q                     # IDs only
```

Lifecycle:

```bash
podman stop web
podman ps -a                     # Exited
podman start web
podman ps                        # Up
podman restart web
podman stop -t 2 web             # SIGKILL after 2 seconds
podman kill web                  # SIGKILL immediately
podman pause web
podman unpause web
```

Removing:

```bash
podman rm web                    # must be stopped
podman rm -f web                 # force, even if running
podman rm web1 web2 web3
podman rm -a                     # every STOPPED container
podman rm -af                    # every container, running or not
```

```text
$ podman rm web
Error: cannot remove container ... as it is running - stop the container before removing
```

```bash
podman stop web && podman rm web
podman rm -f web                 # or in one step
```

Bulk cleanup:

```bash
podman container prune -f        # all stopped containers
podman rm $(podman ps -aq --filter status=exited)
podman stop $(podman ps -q)      # stop everything running
podman rm -af                    # everything
podman system prune -a --volumes # containers, images, volumes, networks
```

```bash
podman ps -a
podman system df
```

| Command | Effect |
| --- | --- |
| `stop` | **SIGTERM, then SIGKILL after 10 s. Data survives** |
| `kill` | **SIGKILL immediately** |
| `start` | Restart a stopped container, **data intact** |
| `restart` | stop then start |
| **`rm`** | **DELETE the container and its writable layer** |
| `rm -f` | Stop and delete |
| `container prune` | Delete all stopped containers |

**`stop` keeps the data; `rm` destroys it.** The distinction matters — see Task 9.

**Remember the rootless/rootful split here too:**

```bash
podman ps -a                     # yours
sudo podman ps -a                # root's
```

**`podman ps` showing nothing does not mean nothing is running on the machine.**

**Task 17.**

```bash
podman run -d --name web -p 80:8080 registry.access.redhat.com/ubi9/httpd-24
```

```text
Error: rootlessport cannot expose privileged port 80, you can add
'net.ipv4.ip_unprivileged_port_start=80' to /etc/sysctl.conf
(currently 1024), or choose a larger port number (>= 1024):
listen tcp 0.0.0.0:80: bind: permission denied
```

**Ports below 1024 are privileged, and a rootless container cannot bind them.** The error names both solutions.

**Solution A — use an unprivileged port. Simplest and usually correct:**

```bash
podman run -d --name web -p 8080:8080 registry.access.redhat.com/ubi9/httpd-24
curl http://localhost:8080
```

**Solution B — run rootful:**

```bash
sudo podman run -d --name web -p 80:8080 registry.access.redhat.com/ubi9/httpd-24
sudo podman ps
curl http://localhost:80
```

**Note this uses root's image store**, so pull as root first:

```bash
sudo podman pull registry.access.redhat.com/ubi9/httpd-24
```

**Solution C — lower the privileged-port threshold**, persistently:

```bash
echo 'net.ipv4.ip_unprivileged_port_start=80' | sudo tee /etc/sysctl.d/99-unprivileged-ports.conf
sudo sysctl -p /etc/sysctl.d/99-unprivileged-ports.conf
sudo sysctl net.ipv4.ip_unprivileged_port_start
podman run -d --name web -p 80:8080 <image>
curl http://localhost
```

**`sysctl -w` alone would not persist** — the file in `/etc/sysctl.d/` is what survives a reboot. Same pattern as `31-swap.md`.

**Solution D — forward with firewalld** (`26-firewalld.md`):

```bash
podman run -d --name web -p 8080:8080 <image>
sudo firewall-cmd --permanent --add-forward-port=port=80:proto=tcp:toport=8080
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
curl http://localhost:80
```

| Solution | Persistent | Notes |
| --- | --- | --- |
| **Use a port ≥ 1024** | **Yes** | **Simplest. Usually what a task means** |
| Run rootful | Yes | Separate image store; a unit in `/etc/systemd/system` |
| `ip_unprivileged_port_start` | **Only via `/etc/sysctl.d/`** | Lowers it system-wide |
| firewalld forwarding | **Only with `--permanent`** | Extra moving parts |

**On the exam, read the port the task specifies.** If it says 8080, use 8080 rootless. If it insists on 80, you need rootful or the sysctl change — and the sysctl change must go in `/etc/sysctl.d/` to persist.

**Task 18.**

```bash
podman run -d --name web -p 8080:8080 -v ~/webcontent:/var/www/html:Z registry.access.redhat.com/ubi9/httpd-24
curl http://localhost:8080                     # works locally
```

From server2:

```bash
curl http://192.168.56.11:8080
```

```text
curl: (7) Failed to connect to 192.168.56.11 port 8080: No route to host
```

**"No route to host" is the firewall** (`26-firewalld.md`):

```bash
# 1. Is podman listening on all interfaces, or only loopback?
ss -tlnp | grep 8080
```

```text
LISTEN 0 4096 0.0.0.0:8080 0.0.0.0:*
```

**`0.0.0.0:8080` is correct.** If it showed `127.0.0.1:8080`, you used `-p 127.0.0.1:8080:8080` and the firewall is not the problem.

```bash
# 2. Open the port — permanently
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
firewall-cmd --list-ports
```

```bash
# 3. Test from server2 again
curl http://192.168.56.11:8080
curl -sI http://192.168.56.11:8080 | head -1
```

```text
HTTP/1.1 200 OK
```

**The complete checklist for "the container works locally but not remotely":**

| Layer | Check | Fix |
| --- | --- | --- |
| Container running | `podman ps` | `podman start` |
| Port published | `podman port web` | `-p 8080:8080` |
| Listening on all interfaces | **`ss -tlnp \| grep 8080`** | Drop the `127.0.0.1:` prefix |
| **Firewall** | **`firewall-cmd --list-ports`** | **`--permanent --add-port=8080/tcp` + `--reload`** |
| Network path | `ping` from the other host | Networking (`24-network-nmcli.md`) |

**`--permanent` and `--reload`, both.** Without `--permanent` the rule vanishes at the next reboot; without `--reload` it is not active now. This is the most-failed detail on the whole exam — see `26-firewalld.md`.

**And a container is not restarted at boot by itself.** After a reboot:

```bash
sudo reboot
podman ps                                      # EMPTY
curl http://localhost:8080                     # connection refused
```

**A podman container has no daemon to restart it. You need a systemd unit — that is `35-containers-systemd.md`.**

```bash
podman ps -a                                   # the container exists but is stopped
podman start web                               # manual restart
```

**Task 19.**

```bash
podman system df
```

```text
TYPE           TOTAL  ACTIVE  SIZE     RECLAIMABLE
Images         4      1       1.4 GB   890 MB (63%)
Containers     3      1       12 MB    8 MB (66%)
Local Volumes  2      1       45 MB    22 MB (48%)
```

```bash
podman system df -v              # itemised
podman images
podman ps -a
podman volume ls
du -sh ~/.local/share/containers/storage
```

Reclaiming, in increasing order of aggression:

```bash
# Stopped containers
podman container prune -f

# Dangling images (untagged)
podman image prune -f

# Unused volumes
podman volume prune -f

# Everything unused: containers, unused images, networks
podman system prune -f

# Add unused images and volumes too — MOST AGGRESSIVE
podman system prune -a --volumes -f
```

```bash
podman system df
du -sh ~/.local/share/containers/storage
```

Selectively:

```bash
podman rmi registry.access.redhat.com/ubi9/ubi
podman rmi -f <image-id>
podman rmi $(podman images -q --filter dangling=true)
podman rm -a
podman volume rm webdata
```

```text
$ podman rmi registry.access.redhat.com/ubi9/httpd-24
Error: image used by 9c1b2d5a...: image is in use by a container
```

```bash
podman ps -a --filter ancestor=registry.access.redhat.com/ubi9/httpd-24
podman rm -f web
podman rmi registry.access.redhat.com/ubi9/httpd-24
```

| Command | Removes |
| --- | --- |
| `container prune` | Stopped containers |
| `image prune` | **Dangling (untagged) images only** |
| `image prune -a` | **Every image not used by a container** |
| `volume prune` | Unused volumes |
| `system prune` | Containers, dangling images, networks |
| **`system prune -a --volumes`** | **Everything unused, volumes included** |

**`system prune -a --volumes` deletes named volumes not attached to a container**, which is data loss if you were relying on one. Check first:

```bash
podman volume ls
podman system df -v
```

Also note the two stores:

```bash
podman system df
sudo podman system df
sudo du -sh /var/lib/containers/storage
```

**Task 20.**

Registry to registry, without pulling locally:

```bash
skopeo copy \
  docker://registry.access.redhat.com/ubi9/ubi:latest \
  docker://registry.lab.example.com:5000/ubi9/ubi:latest

skopeo copy --dest-tls-verify=false \
  docker://registry.access.redhat.com/ubi9/ubi:latest \
  docker://registry.lab.example.com:5000/ubi9/ubi:latest
```

To a local directory:

```bash
mkdir -p /tmp/ubi-image
skopeo copy docker://registry.access.redhat.com/ubi9/ubi:latest dir:/tmp/ubi-image
ls -la /tmp/ubi-image/
du -sh /tmp/ubi-image/
```

```text
manifest.json
version
a1b2c3d4e5f6...
d4e5f6a7b8c9...
```

Between local storage and a registry:

```bash
skopeo copy containers-storage:registry.access.redhat.com/ubi9/ubi:latest \
  docker://registry.lab.example.com:5000/ubi:latest

skopeo copy dir:/tmp/ubi-image containers-storage:localhost/ubi:restored
podman images
```

To an OCI archive, useful for offline transfer:

```bash
skopeo copy docker://registry.access.redhat.com/ubi9/ubi:latest oci-archive:/tmp/ubi.tar
ls -lh /tmp/ubi.tar
skopeo copy oci-archive:/tmp/ubi.tar containers-storage:localhost/ubi:offline
```

The transports:

| Transport | Meaning |
| --- | --- |
| **`docker://`** | **A container registry** |
| **`containers-storage:`** | **Local podman storage** |
| `dir:` | A directory of blobs and a manifest |
| `oci:` | An OCI layout directory |
| `oci-archive:` | An OCI tarball |
| `docker-archive:` | A `docker save` tarball |

**podman's own equivalents** for local export and import:

```bash
podman save -o /tmp/ubi.tar registry.access.redhat.com/ubi9/ubi:latest
podman load -i /tmp/ubi.tar
podman images

podman push localhost/myimage:v1 docker://registry.lab.example.com:5000/myimage:v1
podman pull registry.lab.example.com:5000/myimage:v1
```

| | **`skopeo copy`** | **`podman save`/`load`** |
| --- | --- | --- |
| Needs a local pull | **No** | Yes |
| Registry to registry | **Yes, directly** | No |
| Works with local storage | Yes, via `containers-storage:` | Yes |
| Transport prefixes | **Required** | Not applicable |

**The reason `skopeo` exists is registry-to-registry copying without a local pull**, which matters when the image is large and you only want to move it. That is why the objective names it alongside podman.

Useful with `inspect` for a pre-flight check:

```bash
skopeo inspect docker://registry.access.redhat.com/ubi9/ubi | grep -i digest
skopeo list-tags docker://registry.access.redhat.com/ubi9/ubi
skopeo delete docker://registry.lab.example.com:5000/old-image:v1
```

---

## Verify

```bash
podman --version
skopeo --version
podman info --format '{{.Host.Security.Rootless}}'
podman info --format '{{.Store.GraphRoot}}'
podman images
podman ps
podman ps -a
podman volume ls
podman port <name>
podman logs <name>
podman inspect --format '{{.State.Status}}' <name>
podman inspect --format '{{.Config.ExposedPorts}}' <image>
podman system df
ls -Zd /path/to/bind/mount
ss -tlnp | grep <port>
firewall-cmd --list-ports
skopeo inspect docker://<registry>/<image>
```

## Persistence Check

| Item | Persists across a reboot | What is needed |
| --- | --- | --- |
| Image pulled | **Yes** — on disk | — |
| Container created | **The definition yes; it is NOT running** | **A systemd unit — `35-containers-systemd.md`** |
| **Container running** | **NO** | **A systemd unit** |
| Data in the container | Yes, until `podman rm` | Use a volume or bind mount |
| Named volume | **Yes** | — |
| Bind-mounted data | **Yes** — an ordinary host directory | `:Z` for SELinux |
| Firewall port | Only with **`--permanent`** | `firewall-cmd --permanent` + `--reload` |
| `ip_unprivileged_port_start` | Only via **`/etc/sysctl.d/`** | — |
| Registry configuration | Yes — `/etc/containers/registries.conf.d/` | — |

**The headline: a running container does not survive a reboot.** Podman has no daemon, so nothing restarts it. `podman run -d` is the equivalent of `systemctl start` without `enable`.

```bash
sudo reboot
podman ps                        # empty
podman ps -a                     # the container exists, stopped
```

**Any task that says "the container must start at boot" or "run as a service" requires a systemd unit — that is `35-containers-systemd.md`, and it is where the marks are.**

## Quick Reference

Come back here when you need a command you forgot — not before your first pass through Follow Along.

### Install and verify

```bash
sudo dnf install -y container-tools
# or
sudo dnf install -y podman skopeo buildah
podman --version
skopeo --version
podman info | grep -i rootless
podman info --format '{{.Host.Security.Rootless}}'
podman info --format '{{.Store.GraphRoot}}'
```

### Podman versus Docker

| | Docker | **Podman** |
| --- | --- | --- |
| Daemon | **A root daemon** | **None. Fork/exec** |
| Rootless | Awkward | **Native and default** |
| systemd integration | Poor | **`podman generate systemd`, Quadlet** |
| Command syntax | `docker run` | **`podman run` — identical** |
| Available on RHEL 9/10 | No | **Yes, the supported tool** |

### Rootless versus rootful

| | Rootless (`podman` as a user) | Rootful (`sudo podman`) |
| --- | --- | --- |
| Storage | **`~/.local/share/containers/`** | `/var/lib/containers/` |
| Images visible to | **That user only** | root only |
| Ports below 1024 | **Not allowed** | Allowed |
| systemd units | **`~/.config/systemd/user/`** | `/etc/systemd/system/` |
| Survives logout | **Only with `loginctl enable-linger`** | Yes |

```bash
podman images                    # your images
sudo podman images               # root's images — a different set
```

### Registries

```bash
cat /etc/containers/registries.conf
grep -v '^#' /etc/containers/registries.conf | grep -v '^$'
podman info | grep -A5 -i registries
podman login registry.redhat.io
podman logout registry.redhat.io
```

| Registry | Content |
| --- | --- |
| `registry.access.redhat.com` | **Red Hat images, no login required** |
| `registry.redhat.io` | Red Hat images, **login required** |
| `docker.io` | Docker Hub |
| `quay.io` | Red Hat's Quay |

Adding a registry drop-in:

```bash
sudo tee /etc/containers/registries.conf.d/99-local.conf >/dev/null <<'EOF'
[[registry]]
location = "registry.lab.example.com:5000"
insecure = true
EOF
```

```bash
podman pull registry.access.redhat.com/ubi9/httpd-24
podman pull docker.io/library/nginx:latest
```

### Finding and pulling images

```bash
podman search httpd
podman search --limit 5 nginx
podman search registry.access.redhat.com/ubi
podman search --list-tags registry.access.redhat.com/ubi9/httpd-24

podman pull registry.access.redhat.com/ubi9/httpd-24
podman pull registry.access.redhat.com/ubi9/ubi:latest
podman pull docker.io/library/mariadb:10.5

podman images
podman images --format '{{.Repository}}:{{.Tag}} {{.Size}}'
podman image ls
podman image exists <image> && echo "present"
```

### Inspecting images

```bash
podman inspect <image>
podman inspect --format '{{.Config.Cmd}}' <image>
podman inspect --format '{{.Config.ExposedPorts}}' <image>
podman inspect --format '{{.Config.Env}}' <image>
podman inspect --format '{{.Config.Volumes}}' <image>
podman history <image>

skopeo inspect docker://registry.access.redhat.com/ubi9/httpd-24
skopeo inspect --config docker://registry.access.redhat.com/ubi9/ubi
skopeo list-tags docker://registry.access.redhat.com/ubi9/ubi
skopeo copy docker://registry.access.redhat.com/ubi9/ubi dir:/tmp/ubi
skopeo copy docker://src-registry/img docker://dst-registry/img
```

| Transport | Refers to |
| --- | --- |
| **`docker://`** | **A registry** |
| `containers-storage:` | Local podman storage |
| `dir:` | A directory on disk |
| `oci:` | An OCI layout directory |
| `docker-archive:` | A `docker save` tarball |

### Running containers

```bash
podman run registry.access.redhat.com/ubi9/ubi echo "hello"
podman run -it registry.access.redhat.com/ubi9/ubi /bin/bash
podman run -d --name web registry.access.redhat.com/ubi9/httpd-24
podman run -d --name web -p 8080:8080 <image>
podman run -d --name web -e VAR=value <image>
podman run -d --name web -v /host/path:/container/path:Z <image>
podman run --rm <image> command
```

| Flag | Meaning |
| --- | --- |
| **`-d`** | **Detached, in the background** |
| **`--name`** | **A name you can refer to** |
| **`-p host:container`** | **Publish a port** |
| **`-v host:container:Z`** | **Bind-mount, with SELinux relabelling** |
| **`-e KEY=value`** | **An environment variable** |
| `-it` | Interactive with a TTY |
| `--rm` | Delete the container when it exits |
| `-u` | Run as a given user |
| `--restart=always` | Restart policy |
| `--network` | Network mode |

### Managing containers

```bash
podman ps
podman ps -a
podman ps --format '{{.Names}} {{.Status}} {{.Ports}}'
podman stop web
podman start web
podman restart web
podman kill web
podman rm web
podman rm -f web
podman rm -a
podman logs web
podman logs -f web
podman logs --tail 20 web
podman exec -it web /bin/bash
podman exec web cat /etc/os-release
podman inspect web
podman top web
podman stats --no-stream
podman port web
podman diff web
podman container prune -f
```

### Ports

```bash
podman run -d --name web -p 8080:8080 <image>
podman run -d --name web -p 8080:80 <image>
podman run -d --name web -p 127.0.0.1:8080:8080 <image>
podman run -d --name web -P <image>
podman port web
curl http://localhost:8080
ss -tlnp | grep 8080
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

Rootless: use port ≥ 1024, or `sudo podman`, or sysctl `net.ipv4.ip_unprivileged_port_start=80` in `/etc/sysctl.d/`.

### Persistent storage

```bash
mkdir -p ~/webcontent
podman run -d --name web -v ~/webcontent:/var/www/html:Z <image>
podman volume create webdata
podman run -d --name web -v webdata:/var/www/html <image>
podman volume ls
podman volume inspect webdata
podman volume rm webdata
podman unshare chown -R 1001:1001 ~/webcontent
```

| Suffix | Effect |
| --- | --- |
| **`:Z`** | **Relabel with a private SELinux label for this container** |
| `:z` | Relabel with a shared label, for several containers |
| `:ro` | Read-only |
| `:rw` | Read-write (the default) |
| **none** | **No relabelling — SELinux denies access** |

### Environment variables

```bash
podman run -d --name db \
  -e MYSQL_ROOT_PASSWORD=secret \
  -e MYSQL_DATABASE=appdb \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=apppass \
  registry.redhat.io/rhel9/mariadb-105
podman exec db env
podman inspect --format '{{.Config.Env}}' db
podman run --env-file /root/db.env <image>
podman run --rm <image> cat /help.1 2>/dev/null
```

### Where things live and cleanup

```bash
ls ~/.local/share/containers/storage/
ls ~/.config/containers/
ls ~/.config/systemd/user/
sudo ls /var/lib/containers/storage/
ls /etc/containers/
podman system df
podman system prune -a
podman save -o /tmp/ubi.tar <image>
podman load -i /tmp/ubi.tar
```

---

## Exam Tips

- **`podman` and `sudo podman` are separate worlds** — separate images, containers, and volumes. Be consistent. "As user alice" means rootless as alice.
- **Use fully qualified image names**: `registry.access.redhat.com/ubi9/httpd-24`, not `httpd`.
- **`podman inspect --format '{{.Config.ExposedPorts}}' <image>` before running.** Red Hat images listen on **8080**, not 80.
- **`-p HOST:CONTAINER`** — the host port comes first.
- **Always use `--name`.** Every later command needs it.
- **`-d` to detach**, `--rm` for one-shot commands, `-it` for a shell.
- **`:Z` on every bind mount.** Without it, SELinux denies the container access and you get "Permission denied" or a 403. **`:z` for a directory shared between containers.**
- **Never `:Z` a system directory** like `/etc` — it relabels recursively.
- **A named volume needs no `:Z`** — it is created as `container_file_t`.
- **`podman logs NAME` is the first command when anything goes wrong.** A container that exits immediately usually reports a missing environment variable there.
- **`podman rm` destroys the container's data. `podman stop` does not.**
- **Rootless podman cannot bind ports below 1024.** Use 8080, run rootful, or set `net.ipv4.ip_unprivileged_port_start` in `/etc/sysctl.d/`.
- **Open the firewall**: `firewall-cmd --permanent --add-port=8080/tcp` then `--reload`. Local `curl` proves nothing about remote access.
- **`ss -tlnp | grep PORT`** distinguishes "not listening" from "firewalled".
- **`skopeo inspect docker://IMAGE` inspects without pulling.** The `docker://` prefix is mandatory. `skopeo copy` moves images between registries directly.
- **`podman exec` runs a command in an existing container; `podman run` creates a new one.**
- **`-e KEY=value` or `--env-file`** to configure a container. `chmod 600` an env file containing passwords.
- **`podman unshare chown -R 1001:1001 DIR`** fixes ownership for a rootless bind mount.
- **A running container does NOT survive a reboot.** You need a systemd unit — see `35-containers-systemd.md`.
- **`podman system df` and `podman system prune -a --volumes`** for disk usage. `--volumes` deletes data.
- **The exam has no internet.** Expect a local registry or pre-pulled images; practise the syntax, not the download.
