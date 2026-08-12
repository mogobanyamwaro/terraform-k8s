# 32. NFS And autofs

**Objectives:** Mount and unmount network file systems using NFS. Configure autofs.

**This is the only objective that needs two machines**, which is why the exam gives you a second host or a prepared NFS server. It also combines with almost every other domain — firewall, SELinux, `/etc/fstab`, and systemd services all appear here.

## Concept Refresher

### Client and server

The RHCSA objective says **"mount and unmount network file systems using NFS"** — the client side. Configuring a server is not strictly required, but you need one to practise against and tasks sometimes provide one for you to set up.

```text
   ┌─────────────────────────────┐         ┌──────────────────────────────┐
   │  server2 (NFS SERVER)       │         │  server1 (NFS CLIENT)        │
   │                             │         │                              │
   │  /etc/exports               │◄────────┤  mount server2:/export /nfs  │
   │  nfs-server.service         │  2049   │  /etc/fstab  (_netdev)       │
   │  firewall: nfs, mountd,     │         │  or autofs                   │
   │            rpc-bind         │         │  nfs-utils                   │
   └─────────────────────────────┘         └──────────────────────────────┘
```

### Client: packages and discovery

```bash
sudo dnf install -y nfs-utils
rpm -q nfs-utils

# What does the server export?
showmount -e server2.lab.example.com
showmount -e 192.168.56.12
showmount -a server2                       # who has it mounted
sudo rpcinfo -p server2                    # RPC services (NFSv3)
```

```text
$ showmount -e server2.lab.example.com
Export list for server2.lab.example.com:
/export/shared 192.168.56.0/24
/export/home   *
```

**`showmount -e SERVER` is the first command of any NFS task.** It tells you what exists, and whether the server is reachable at all.

**`nfs-utils` is required on the client, not just the server.** Without it, `mount -t nfs` fails with "wrong fs type" — a confusing error for a missing package.

### Client: mounting

```bash
sudo mkdir -p /nfs
sudo mount -t nfs server2:/export/shared /nfs
sudo mount server2:/export/shared /nfs                 # -t nfs is inferred
sudo mount -t nfs -o vers=4.2 server2:/export/shared /nfs
sudo mount -t nfs -o ro server2:/export/shared /nfs
sudo mount -t nfs -o soft,timeo=100 server2:/export/shared /nfs

findmnt /nfs
df -hT /nfs
sudo umount /nfs
```

**Note the colon: `server:/path`, not `server/path`.**

Persisting it in `/etc/fstab`:

```text
server2:/export/shared  /nfs  nfs  defaults,_netdev  0 0
```

| Field | Value |
| --- | --- |
| Device | **`server:/export/path`** |
| Mount point | `/nfs` |
| Type | **`nfs`** or `nfs4` |
| Options | **`defaults,_netdev`** |
| Dump / fsck | `0 0` |

**`_netdev` is essential.** It tells systemd this mount needs the network, so the boot waits for networking instead of trying to mount before an interface is up:

```bash
echo "server2:/export/shared  /nfs  nfs  defaults,_netdev  0 0" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo mount -a
```

**Without `_netdev`, the mount fails at boot** and can drop the machine into emergency mode. Consider adding `nofail` as well for a non-critical mount.

Useful NFS mount options:

| Option | Effect |
| --- | --- |
| **`_netdev`** | **Wait for the network. Required in `/etc/fstab`** |
| `nofail` | Do not fail the boot if the server is unreachable |
| `ro` / `rw` | Read-only / read-write |
| `vers=4.2`, `vers=3` | Protocol version |
| **`soft`** | **Fail I/O after retries. Prevents indefinite hangs** |
| `hard` | Retry forever. The default |
| `timeo=100` | Timeout in tenths of a second |
| `retrans=3` | Retries before reporting an error |
| `intr` | Allow interrupting (ignored on modern kernels) |
| `noatime` | Reduce access-time traffic |
| `sync` / `async` | Write behaviour |
| `x-systemd.automount` | Mount on first access |

**`hard` is the default and means a process blocks forever if the server disappears** — including `df`, which then hangs your terminal. `soft` returns an error instead. For exam practice, `soft,timeo=100` makes a broken server much less painful.

### Server: exporting

```bash
sudo dnf install -y nfs-utils
sudo mkdir -p /export/shared
sudo chmod 777 /export/shared
```

`/etc/exports`:

```text
/export/shared  192.168.56.0/24(rw,sync,no_root_squash)
/export/home    *(rw,sync)
/export/ro      192.168.56.11(ro)
/export/multi   server1(rw) server3(ro)
```

```bash
sudo systemctl enable --now nfs-server
sudo exportfs -rav                         # re-read /etc/exports
sudo exportfs -v                           # show active exports
sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --permanent --add-service=mountd
sudo firewall-cmd --permanent --add-service=rpc-bind
sudo firewall-cmd --reload
```

Export options:

| Option | Meaning |
| --- | --- |
| `rw` / `ro` | Read-write / read-only |
| **`sync`** | **Commit writes before replying. The safe default** |
| `async` | Faster, risks data loss on a crash |
| **`root_squash`** | **Map remote root to `nobody`. The default** |
| `no_root_squash` | Remote root is real root. **Dangerous** |
| `all_squash` | Map every user to `nobody` |
| `anonuid=`, `anongid=` | The identity to squash to |
| `no_subtree_check` | Slight performance gain |

**No space between the host and the parentheses.** `192.168.56.0/24(rw)` is correct; `192.168.56.0/24 (rw)` exports read-only to that host *and* read-write to the world — a classic and serious mistake.

**`exportfs -rav` after every `/etc/exports` change**, the same way `firewall-cmd --reload` follows a permanent firewall change.

Firewall for NFS:

```bash
firewall-cmd --info-service=nfs            # 2049/tcp
firewall-cmd --info-service=mountd
firewall-cmd --info-service=rpc-bind
```

**NFSv4 needs only `nfs` (port 2049). NFSv3 also needs `mountd` and `rpc-bind`.** Adding all three is harmless and safer.

### autofs

autofs mounts on access and unmounts after an idle period. It avoids boot-time dependencies on a server and stops idle mounts hanging the system.

```text
   /etc/auto.master           the MASTER map
       │
       │  /shares   /etc/auto.shares   --timeout=60
       │      │            │
       │  mount point   map file
       ▼
   /etc/auto.shares          the MAP file
       │
       │  data  -rw,sync  server2:/export/shared
       │   │       │            │
       │  key   options      location
```

```bash
sudo dnf install -y autofs
sudo systemctl enable --now autofs
systemctl status autofs
```

**Indirect map** — the usual form:

```bash
# /etc/auto.master  (or a file in /etc/auto.master.d/)
/shares  /etc/auto.shares  --timeout=60
```

```bash
# /etc/auto.shares
data   -rw,sync  server2:/export/shared
home   -rw       server2:/export/home
docs   -ro       server2:/export/docs
```

```bash
sudo systemctl restart autofs
ls /shares/data                            # mounts on access
findmnt /shares/data
```

**Do not create the subdirectory under `/shares` yourself** — autofs manages it. Creating `/shares/data` by hand actually breaks it.

**Direct map** — an absolute mount point:

```bash
# /etc/auto.master
/-  /etc/auto.direct
```

```bash
# /etc/auto.direct
/mnt/shared  -rw  server2:/export/shared
```

**`/-` in the master map signals a direct map.** The map file then contains absolute paths.

**Wildcard map** — the classic home-directory case:

```bash
# /etc/auto.master
/home/guests  /etc/auto.guests
```

```bash
# /etc/auto.guests
*  -rw  server2:/export/home/&
```

**`*` is the requested key and `&` substitutes it.** So `cd /home/guests/alice` mounts `server2:/export/home/alice`. **This exact pattern is a favourite exam task.**

Drop-in master entries:

```bash
sudo mkdir -p /etc/auto.master.d
echo "/shares  /etc/auto.shares  --timeout=60" | sudo tee /etc/auto.master.d/shares.autofs
sudo systemctl restart autofs
```

**Files in `/etc/auto.master.d/` must end in `.autofs`.** This is cleaner than editing `/etc/auto.master`, the same reasoning as `/etc/sudoers.d/` and systemd drop-ins.

**`systemctl restart autofs` after every map change.** `reload` is unreliable for map changes.

### autofs versus /etc/fstab

| | **`/etc/fstab`** | **autofs** |
| --- | --- | --- |
| Mounted | **At boot** | **On first access** |
| Unmounted | Never, automatically | **After the idle timeout** |
| Server unreachable at boot | **Boot delayed or fails** | **No effect** |
| Server unreachable later | Processes hang (`hard`) | Access fails, others unaffected |
| Wildcards | No | **Yes** |
| Needs a service | No | **`autofs` must be enabled** |
| Requires `_netdev` | **Yes** | No |

**A task that says "mount at boot" means `/etc/fstab`. A task that says "on demand", "when accessed", or "using autofs" means autofs.** Read the wording.

### Troubleshooting

```bash
# 1. Is the server reachable?
ping -c2 server2
getent hosts server2

# 2. What does it export?
showmount -e server2

# 3. Is nfs-utils installed here?
rpm -q nfs-utils

# 4. Try mounting by hand
sudo mount -t nfs -v server2:/export/shared /nfs

# 5. Server side: is it running and exporting?
systemctl status nfs-server
sudo exportfs -v

# 6. Server side: firewall
sudo firewall-cmd --list-services

# 7. SELinux, on both ends
sudo ausearch -m AVC -ts recent
getsebool -a | grep nfs

# 8. autofs
systemctl status autofs
sudo automount -f -v                       # run in the foreground, verbose
journalctl -u autofs -n 30
```

| Symptom | Likely cause |
| --- | --- |
| `mount: wrong fs type` | **`nfs-utils` not installed on the client** |
| `No route to host` | **Firewall on the server** |
| `access denied by server` | **`/etc/exports` does not permit this client** |
| `Connection refused` | **`nfs-server` not running** |
| Hangs forever | Server unreachable with `hard` — use `soft` |
| Mounts by hand, not at boot | **`_netdev` missing**, or the entry is absent |
| autofs directory empty | **Do not `ls` the parent; access the subdirectory directly** |
| Permission denied writing | `ro` export, or `root_squash`, or UID mismatch |

**`sudo automount -f -v` is the best autofs diagnostic** — stop the service, run it in the foreground, and watch it parse your maps and attempt mounts.

## Tasks

**Task 1.** Discover what NFS exports a remote server offers, and confirm it is reachable.

**Task 2.** Install the client package and mount `server2:/export/shared` at `/nfs` manually. Verify the type and that it is writable.

**Task 3.** Make that NFS mount persistent so it is available after a reboot, with the option that makes it network-aware.

**Task 4.** Verify the NFS mount survives a reboot.

**Task 5.** Mount an NFS export read-only, and confirm writes are refused.

**Task 6.** Mount an export with options that prevent the client hanging indefinitely if the server disappears.

**Task 7.** Configure the second machine as an NFS server exporting `/export/shared` read-write to the `192.168.56.0/24` network, addressing every layer.

**Task 8.** On the server, add a read-only export for one specific client only, and reload the exports without restarting the service.

**Task 9.** Install and enable autofs, then configure an indirect map so that `/shares/data` mounts `server2:/export/shared` on access, unmounting after 60 idle seconds.

**Task 10.** Verify the autofs mount happens on access and disappears after the timeout.

**Task 11.** Configure a direct autofs map so that `/mnt/shared` mounts the same export.

**Task 12.** Configure a wildcard autofs map so that `/home/guests/<username>` mounts `server2:/export/home/<username>`.

**Task 13.** Use a drop-in file rather than editing `/etc/auto.master`, and explain why.

**Task 14.** Diagnose: `mount -t nfs server2:/export/shared /nfs` reports "wrong fs type, bad option, bad superblock".

**Task 15.** Diagnose: the NFS mount works when run by hand but is absent after a reboot.

**Task 16.** Diagnose: an autofs directory appears empty and nothing mounts.

**Task 17.** Diagnose: the NFS mount succeeds but writing a file is denied.

**Task 18.** Verify all NFS and autofs configuration survives a reboot.

---

## Solutions

**Task 1.**

```bash
ping -c2 server2.lab.example.com
getent hosts server2.lab.example.com
```

If the name does not resolve, fix that first — see `25-hostnames-dns.md`:

```bash
echo "192.168.56.12  server2.lab.example.com server2" | sudo tee -a /etc/hosts
getent hosts server2
```

```bash
sudo dnf install -y nfs-utils
showmount -e server2.lab.example.com
```

```text
Export list for server2.lab.example.com:
/export/shared 192.168.56.0/24
/export/home   *
/export/docs   192.168.56.11
```

**Each line is an export path and the hosts permitted to mount it.** `*` means anyone.

```bash
showmount -e 192.168.56.12                 # by IP, bypassing DNS
showmount -a server2                       # who currently has it mounted
showmount -d server2                       # directories currently mounted
sudo rpcinfo -p server2                    # RPC programs (NFSv3)
ss -tlnp | grep 2049                       # on the SERVER
```

**`showmount -e` is the first command of any NFS task**, because it answers three things at once: the server is up, NFS is running on it, and these are the paths available.

If it fails:

```text
$ showmount -e server2
clnt_create: RPC: Unable to receive
```

```bash
ping -c2 server2                           # network?
getent hosts server2                       # name resolution?
# on the server:
systemctl status nfs-server                # service running?
sudo firewall-cmd --list-services          # firewall?
sudo exportfs -v                           # anything exported?
```

**`showmount` needs `rpcbind` on the server, which is present with NFSv3 support.** An NFSv4-only server may refuse `showmount` while mounting works perfectly. So a `showmount` failure is a hint, not a verdict:

```bash
sudo mount -t nfs server2:/export/shared /mnt      # try it anyway
```

**Task 2.**

```bash
sudo dnf install -y nfs-utils
rpm -q nfs-utils
sudo mkdir -p /nfs
sudo mount -t nfs server2:/export/shared /nfs
```

Verify:

```bash
findmnt /nfs
df -hT /nfs
mount | grep nfs
```

```text
$ findmnt /nfs
TARGET SOURCE                 FSTYPE OPTIONS
/nfs   server2:/export/shared nfs4   rw,relatime,vers=4.2,rsize=262144,...
```

```text
$ df -hT /nfs
Filesystem             Type  Size  Used Avail Use% Mounted on
server2:/export/shared nfs4   17G  2.1G   15G  13% /nfs
```

**`FSTYPE nfs4` and `vers=4.2` show the negotiated protocol version** even though you asked for `nfs`. NFSv4 is the default on RHEL 9 and 10.

Test writability:

```bash
sudo touch /nfs/testfile
ls -l /nfs/
echo "hello from server1" | sudo tee /nfs/hello.txt
cat /nfs/hello.txt
```

Four things to note:

- **`nfs-utils` is needed on the client, not just the server.** Without it the mount fails with the misleading "wrong fs type" — see Task 14.
- **The syntax is `server:/path`** with a colon.
- **The mount point must exist:** `mkdir -p /nfs`.
- **This mount is not persistent.** A reboot loses it. Task 3.

Explicit variations:

```bash
sudo mount -t nfs -o vers=4.2 server2:/export/shared /nfs
sudo mount -t nfs4 server2:/export/shared /nfs
sudo mount -t nfs -o vers=3 server2:/export/shared /nfs
sudo mount -t nfs -v server2:/export/shared /nfs        # -v shows the negotiation
```

**Task 3.**

```bash
echo "server2.lab.example.com:/export/shared  /nfs  nfs  defaults,_netdev  0 0" | sudo tee -a /etc/fstab
tail -1 /etc/fstab
```

Verify without rebooting:

```bash
sudo findmnt --verify
sudo umount /nfs
findmnt /nfs                               # no output
sudo mount -a
findmnt /nfs
df -hT /nfs
```

**`_netdev` is the option this task is about.** It marks the mount as requiring the network, so:

- systemd orders it after `network-online.target`.
- It is not attempted before an interface is configured.
- It is unmounted before the network goes down at shutdown.

**Without `_netdev`, the boot tries to mount before the network is up:**

```text
[FAILED] Failed to mount /nfs.
[DEPEND] Dependency failed for Remote File Systems.
```

| Options | Server up at boot | Server down at boot |
| --- | --- | --- |
| `defaults` | **May fail — race with the network** | **Boot delayed or fails** |
| **`defaults,_netdev`** | **Mounted** | Boot delayed, then fails |
| **`defaults,_netdev,nofail`** | **Mounted** | **Skipped, boot continues** |
| `defaults,noauto` | Not mounted | Not mounted |

**`_netdev,nofail` is the robust combination** for a mount whose server might be unavailable. But **read the task**: if it says "mount at boot", `noauto` fails it, whereas `nofail` still mounts when the server is present.

Add `soft` for practice safety:

```bash
echo "server2:/export/shared  /nfs  nfs  defaults,_netdev,soft,timeo=100  0 0" | sudo tee -a /etc/fstab
```

**Use the same server name the task uses.** If it says `server2.lab.example.com`, use that, and make sure it resolves (`25-hostnames-dns.md`) — an unresolvable name in `/etc/fstab` is a boot failure.

**Task 4.**

```bash
sudo findmnt --verify
sudo mount -a && echo "mount -a OK"
grep nfs /etc/fstab
getent hosts server2.lab.example.com
sudo reboot
```

After:

```bash
findmnt /nfs
df -hT /nfs
cat /nfs/hello.txt
systemctl --failed
systemctl list-units --type=mount | grep nfs
```

```text
TARGET SOURCE                 FSTYPE OPTIONS
/nfs   server2:/export/shared nfs4   rw,relatime,vers=4.2,_netdev
```

If it is not mounted:

```bash
grep nfs /etc/fstab                        # entry present?
sudo findmnt --verify
sudo mount -a                              # what is the error?
getent hosts server2.lab.example.com       # does the name resolve?
ping -c2 server2                           # is the server up?
showmount -e server2                       # is it still exporting?
journalctl -b | grep -i nfs
systemctl status nfs.mount 2>/dev/null
systemctl status remote-fs.target
```

| Symptom | Cause |
| --- | --- |
| Not mounted, no error | **No `/etc/fstab` entry**, or `noauto` |
| Failed at boot, works with `mount -a` | **`_netdev` missing** |
| `Name or service not known` | **The server name does not resolve** (`25-hostnames-dns.md`) |
| `No route to host` | **Firewall on the server** |
| `access denied` | `/etc/exports` on the server |
| Boot hung for 90 seconds | Server unreachable; add `nofail` |

**"Works with `mount -a` but not at boot" is almost always a missing `_netdev`**, because `mount -a` runs when the network is already up while the boot sequence does not have that luxury.

**Task 5.**

```bash
sudo umount /nfs
sudo mount -t nfs -o ro server2:/export/shared /nfs
findmnt /nfs
```

```text
TARGET SOURCE                 FSTYPE OPTIONS
/nfs   server2:/export/shared nfs4   ro,relatime,vers=4.2
```

```bash
sudo touch /nfs/newfile
```

```text
touch: cannot touch '/nfs/newfile': Read-only file system
```

```bash
cat /nfs/hello.txt                         # reading still works
```

Persist it:

```bash
echo "server2:/export/shared  /nfs  nfs  ro,_netdev  0 0" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo umount /nfs && sudo mount -a
findmnt /nfs
```

**Read-only can be imposed at either end**, and the distinction matters:

| Where | How | Effect |
| --- | --- | --- |
| **Client** | **`-o ro` or `ro` in fstab** | This client cannot write |
| **Server** | **`ro` in `/etc/exports`** | **No client can write** |

```bash
# On the server
sudo vim /etc/exports
#   /export/docs  192.168.56.0/24(ro)
sudo exportfs -rav
sudo exportfs -v
```

**A server-side `ro` overrides a client-side `rw`:**

```bash
sudo mount -t nfs -o rw server2:/export/docs /mnt
findmnt /mnt                               # shows rw
sudo touch /mnt/x                          # still Read-only file system
```

The client requested read-write, the server refused, and the error appears at write time rather than mount time. **When diagnosing "cannot write to NFS", check `exportfs -v` on the server, not just the client mount options.**

```bash
# On the server
sudo exportfs -v
```

```text
/export/shared 192.168.56.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash)
/export/docs   192.168.56.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,ro,secure,root_squash)
```

**Task 6.**

```bash
sudo umount /nfs
sudo mount -t nfs -o soft,timeo=100,retrans=3 server2:/export/shared /nfs
findmnt /nfs
```

```text
TARGET SOURCE                 FSTYPE OPTIONS
/nfs   server2:/export/shared nfs4   rw,relatime,vers=4.2,soft,timeo=100,retrans=3
```

Persist it:

```bash
echo "server2:/export/shared  /nfs  nfs  defaults,_netdev,soft,timeo=100,retrans=3,nofail  0 0" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo umount /nfs && sudo mount -a
```

| Option | Behaviour when the server is unreachable |
| --- | --- |
| **`hard`** (the default) | **Retry forever. Processes block indefinitely, unkillable** |
| **`soft`** | **Return an I/O error after `retrans` attempts** |
| `timeo=100` | Wait 10 seconds per attempt (tenths of a second) |
| `retrans=3` | Three retries before giving up |

**`hard` is the default and it is genuinely painful in a lab.** Stop the NFS server with a `hard` mount in place and:

```bash
df -h                                      # HANGS, and Ctrl-C does not help
ls /nfs                                    # HANGS
sudo umount /nfs                           # "device is busy" or hangs
```

The blocked process sits in uninterruptible sleep (state `D` — see `13-processes.md`) and cannot be killed:

```bash
ps aux | awk '$8 ~ /D/'
```

The only ways out are bringing the server back or a forced unmount:

```bash
sudo umount -f /nfs
sudo umount -l /nfs
```

**With `soft`, the same situation produces an error after about 30 seconds** and everything else keeps working:

```text
$ ls /nfs
ls: cannot access '/nfs': Input/output error
```

Trade-off:

- **`hard` never loses data** — a write eventually completes when the server returns. Correct for critical data.
- **`soft` can lose data** if a write fails, but it never wedges the machine.

**Use `soft,timeo=100` for lab practice**, so a stopped server does not cost you a reboot. On the exam, follow whatever the task specifies; if it says "the client must not hang if the server is unavailable", that is `soft`.

**And prefer autofs for anything intermittent** — it does not mount until accessed, so an unreachable server affects only the process that touched it. Tasks 9 to 13.

**Task 7.**

On **server2**, four layers, and missing any one means the client fails.

```bash
# 1. Package and directory
sudo dnf install -y nfs-utils
sudo mkdir -p /export/shared
sudo chmod 777 /export/shared
echo "shared from server2" | sudo tee /export/shared/readme.txt
```

```bash
# 2. The export definition
echo "/export/shared  192.168.56.0/24(rw,sync)" | sudo tee -a /etc/exports
cat /etc/exports
sudo exportfs -rav
sudo exportfs -v
```

```text
exporting 192.168.56.0/24:/export/shared

/export/shared 192.168.56.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash)
```

```bash
# 3. The service
sudo systemctl enable --now nfs-server
systemctl status nfs-server
systemctl is-enabled nfs-server
ss -tlnp | grep 2049
```

```bash
# 4. The firewall
sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --permanent --add-service=mountd
sudo firewall-cmd --permanent --add-service=rpc-bind
sudo firewall-cmd --reload
firewall-cmd --list-services
```

Test from **server1**:

```bash
showmount -e server2
sudo mkdir -p /nfs
sudo mount -t nfs server2:/export/shared /nfs
cat /nfs/readme.txt
sudo touch /nfs/from-client.txt
```

**The four layers, and how each one fails:**

| Layer | Command | Failure symptom on the client |
| --- | --- | --- |
| Directory | `mkdir`, `chmod` | `access denied` or permission errors |
| **Export** | **`/etc/exports` + `exportfs -rav`** | **`access denied by server`** |
| **Service** | **`systemctl enable --now nfs-server`** | **`Connection refused`** |
| **Firewall** | **`firewall-cmd --permanent --add-service=nfs`** | **`No route to host`** |

**Learn to read the client error backwards to the server-side cause.** "No route to host" is the firewall; "Connection refused" is the service; "access denied by server" is `/etc/exports`.

The `/etc/exports` syntax trap:

```text
/export/shared  192.168.56.0/24(rw,sync)      ← CORRECT
/export/shared  192.168.56.0/24 (rw,sync)     ← WRONG
```

**The space means two separate specifications**: read-only default access for `192.168.56.0/24`, and read-write for *everyone*. A security hole and a failed task.

Host specification forms:

```text
/export/a  192.168.56.11(rw)                  a single host by IP
/export/b  server1.lab.example.com(rw)        by name
/export/c  192.168.56.0/24(rw)                a subnet
/export/d  *.lab.example.com(rw)              a wildcard domain
/export/e  *(ro)                              everyone
/export/f  server1(rw) server3(ro)            different options per host
```

`root_squash` is the default and maps remote root to `nobody`:

```bash
# On server1, as root:
sudo touch /nfs/roottest
ls -l /nfs/roottest
```

```text
-rw-r--r--. 1 nobody nobody 0 Aug 18 16:45 /nfs/roottest
```

**That is `root_squash` working.** `no_root_squash` disables it and is a real security risk — only use it if a task explicitly asks.

SELinux on the server, if needed:

```bash
getsebool -a | grep nfs_export
sudo setsebool -P nfs_export_all_rw on
sudo ausearch -m AVC -ts recent
```

**Task 8.**

```bash
sudo mkdir -p /export/docs
echo "read only content" | sudo tee /export/docs/manual.txt
sudo tee -a /etc/exports >/dev/null <<'EOF'
/export/docs  192.168.56.11(ro,sync)
EOF
cat /etc/exports
```

**Reload without restarting the service:**

```bash
sudo exportfs -rav
sudo exportfs -v
```

```text
exporting 192.168.56.11:/export/docs

/export/docs  192.168.56.11(sync,wdelay,hide,no_subtree_check,sec=sys,ro,secure,root_squash)
```

```bash
systemctl status nfs-server                # still running, never restarted
```

**`exportfs -rav` re-reads `/etc/exports` and applies the changes with no interruption to existing mounts.** Restarting `nfs-server` would work but would disconnect every current client — the same relationship as `firewall-cmd --reload` versus restarting firewalld, or `systemctl reload httpd` versus `restart` (`14-systemd-services.md`).

The `exportfs` flags:

| Flag | Effect |
| --- | --- |
| **`-r`** | **Re-export everything, syncing with `/etc/exports`** |
| `-a` | All directories |
| `-v` | Verbose |
| **`-rav`** | **The combination to use** |
| `-u` | Unexport |
| `-ua` | Unexport everything |
| `-o` | Export with options, ad hoc, without editing the file |

```bash
sudo exportfs -o rw,sync 192.168.56.11:/export/temp     # temporary, not in the file
sudo exportfs -u 192.168.56.11:/export/temp
sudo exportfs -ua                                        # unexport everything
sudo exportfs -rav                                       # back to what the file says
```

**`exportfs -o` does not persist** — it is absent from `/etc/exports`, so a restart loses it. Another instance of the runtime-versus-file pattern: **`/etc/exports` is the persistence, `exportfs -rav` is the activation.**

Verify from server1:

```bash
showmount -e server2
sudo mount -t nfs server2:/export/docs /mnt
cat /mnt/manual.txt
sudo touch /mnt/x                          # Read-only file system
sudo umount /mnt
```

From any other host, the mount is refused:

```text
mount.nfs: access denied by server while mounting server2:/export/docs
```

**Task 9.**

```bash
sudo dnf install -y autofs
rpm -q autofs
```

The master map entry — use a drop-in:

```bash
sudo mkdir -p /etc/auto.master.d
echo "/shares  /etc/auto.shares  --timeout=60" | sudo tee /etc/auto.master.d/shares.autofs
```

The map file:

```bash
sudo tee /etc/auto.shares >/dev/null <<'EOF'
data  -rw,sync  server2:/export/shared
EOF
cat /etc/auto.shares
```

```bash
sudo systemctl enable --now autofs
sudo systemctl restart autofs
systemctl status autofs
systemctl is-enabled autofs
```

Test:

```bash
ls /shares/data
findmnt /shares/data
df -hT /shares/data
cat /shares/data/readme.txt
```

```text
$ findmnt /shares/data
TARGET       SOURCE                 FSTYPE OPTIONS
/shares/data server2:/export/shared nfs4   rw,relatime,sync,vers=4.2
```

**Reading the configuration:**

```text
/etc/auto.master.d/shares.autofs
   /shares          /etc/auto.shares      --timeout=60
      │                    │                   │
   mount point        the map file       idle seconds before unmounting
```

```text
/etc/auto.shares
   data       -rw,sync      server2:/export/shared
    │             │                    │
   key         options            what to mount
 (becomes /shares/data)
```

**Four things that go wrong:**

1. **Do not create `/shares/data` yourself.** autofs creates and removes it. A pre-existing directory there prevents the mount:

```bash
sudo rmdir /shares/data 2>/dev/null
sudo systemctl restart autofs
```

`/shares` itself is created by autofs too, so you need not `mkdir` anything.

2. **`systemctl restart autofs` after every map change.** `reload` does not reliably pick up map edits.

3. **`enable` as well as `start`.** Without `enable`, nothing works after the reboot:

```bash
systemctl is-enabled autofs                # must say 'enabled'
```

4. **`ls /shares` may look empty** before the first access, because autofs mounts on access to the *subdirectory*, not the parent:

```bash
ls /shares                                 # possibly empty
ls /shares/data                            # this triggers the mount
findmnt | grep shares
```

**Access the full path directly.** This confuses people into thinking autofs is broken. See Task 16.

**Task 10.**

```bash
findmnt /shares/data                       # not mounted yet
mount | grep shares
```

Access triggers the mount:

```bash
ls /shares/data
findmnt /shares/data
df -hT /shares/data
```

```text
TARGET       SOURCE                 FSTYPE OPTIONS
/shares/data server2:/export/shared nfs4   rw,relatime,sync,vers=4.2
```

Wait out the timeout:

```bash
sleep 70
findmnt /shares/data                       # no output — unmounted
mount | grep shares
```

Watch it live:

```bash
sudo journalctl -u autofs -f
# in another terminal:
ls /shares/data
```

```text
automount[1234]: mounting /shares/data
automount[1234]: expiring /shares/data
```

**The mechanism:**

```text
   access /shares/data
           │
           ▼
   autofs intercepts (via the autofs filesystem on /shares)
           │
           ▼
   mounts server2:/export/shared on /shares/data
           │
           ▼
   60 seconds with no access
           │
           ▼
   unmounts automatically
```

```bash
findmnt -t autofs
```

```text
TARGET  SOURCE  FSTYPE OPTIONS
/shares /etc/auto.shares autofs rw,relatime,fd=7,pgrp=1234,timeout=60
```

**`/shares` itself is always mounted as type `autofs`** — that is what makes the interception possible. The NFS mount appears and disappears underneath it.

Timeout settings:

```bash
# Per master-map entry
/shares  /etc/auto.shares  --timeout=60
/shares  /etc/auto.shares  --timeout=0      # never expire

# Global default
grep -i timeout /etc/autofs.conf
```

```bash
sudo systemctl restart autofs
```

**Why autofs rather than `/etc/fstab`:**

| | `/etc/fstab` | **autofs** |
| --- | --- | --- |
| Server down at boot | **Boot delayed or fails** | **No effect at all** |
| Server down later | Processes hang (`hard`) | Only that access fails |
| Idle mounts | Held open forever | **Released automatically** |
| Wildcards | No | **Yes** |

**A task saying "mount on demand", "when accessed", or "automatically unmount when idle" means autofs.**

**Task 11.**

```bash
echo "/-  /etc/auto.direct" | sudo tee /etc/auto.master.d/direct.autofs
sudo tee /etc/auto.direct >/dev/null <<'EOF'
/mnt/shared  -rw  server2:/export/shared
EOF
sudo mkdir -p /mnt
sudo systemctl restart autofs
```

Test:

```bash
ls /mnt/shared
findmnt /mnt/shared
df -hT /mnt/shared
```

**`/-` is the key.** It tells autofs "this map contains absolute paths, not keys relative to a parent":

| | **Indirect map** | **Direct map** |
| --- | --- | --- |
| Master entry | `/shares  /etc/auto.shares` | **`/-  /etc/auto.direct`** |
| Map entry | `data  -rw  server:/export` | **`/mnt/shared  -rw  server:/export`** |
| Result | `/shares/data` | **`/mnt/shared`** |
| Parent managed by autofs | **Yes** (`/shares`) | No — `/mnt` is a normal directory |
| Wildcards possible | **Yes** | No |
| `findmnt -t autofs` shows | `/shares` | **Each mount point individually** |

```bash
findmnt -t autofs
```

```text
TARGET      SOURCE           FSTYPE OPTIONS
/shares     /etc/auto.shares autofs rw,relatime,timeout=60
/mnt/shared /etc/auto.direct autofs rw,relatime,timeout=300
```

**When to use which:**

- **Indirect** for several related mounts under one parent, and whenever you need wildcards. This is the usual choice.
- **Direct** when the mount point must be at a specific existing path that other directories share — `/mnt/shared` alongside a normal `/mnt/local`.

**The parent of a direct mount point must exist** (`/mnt` here), unlike an indirect map where autofs creates the parent. Do not create the final component (`/mnt/shared`) — autofs does that.

**Task 12.**

```bash
echo "/home/guests  /etc/auto.guests" | sudo tee /etc/auto.master.d/guests.autofs
sudo tee /etc/auto.guests >/dev/null <<'EOF'
*  -rw,sync  server2:/export/home/&
EOF
sudo systemctl restart autofs
```

Test:

```bash
ls /home/guests/alice
findmnt /home/guests/alice
ls /home/guests/bob
findmnt | grep guests
```

```text
TARGET             SOURCE                      FSTYPE OPTIONS
/home/guests/alice server2:/export/home/alice  nfs4   rw,sync,vers=4.2
/home/guests/bob   server2:/export/home/bob    nfs4   rw,sync,vers=4.2
```

**`*` matches whatever key was requested and `&` substitutes it:**

```text
   *  -rw,sync  server2:/export/home/&
   │                                 │
   │                                 └── replaced by the matched key
   └── matches ANY subdirectory name

   access /home/guests/alice  →  mount server2:/export/home/alice
   access /home/guests/bob    →  mount server2:/export/home/bob
```

**This is the classic NFS home-directory pattern and a favourite exam task**, because one two-line configuration serves any number of users without naming them.

The server side:

```bash
# On server2
sudo mkdir -p /export/home/{alice,bob,carol}
echo "/export/home  *(rw,sync)" | sudo tee -a /etc/exports
sudo exportfs -rav
sudo exportfs -v
```

**NFSv4 requires the parent to be exported, and each subdirectory is reached through it.** With NFSv3 you would export each one, or use `crossmnt`.

Wildcard rules:

- **`*` matches any key**, so a wildcard entry must be the *last* line in the map — earlier specific entries take precedence:

```text
special  -rw  server2:/export/special
*        -rw  server2:/export/home/&
```

- **`&` is only meaningful with `*`.**
- **`ls /home/guests` shows nothing** until something is accessed, because autofs cannot enumerate every possible key. Access the full path.
- **`/home/guests` must not contain real subdirectories.** They shadow the automounts.

Verify:

```bash
sudo automount -f -v &
ls /home/guests/alice
findmnt | grep guests
sleep 65 && findmnt | grep guests          # expired
```

**Task 13.**

```bash
sudo mkdir -p /etc/auto.master.d
echo "/shares  /etc/auto.shares  --timeout=60" | sudo tee /etc/auto.master.d/shares.autofs
sudo systemctl restart autofs
```

Confirm the master map picks it up:

```bash
grep -n 'auto.master.d' /etc/auto.master
ls -l /etc/auto.master.d/
findmnt -t autofs
```

```text
$ grep auto.master.d /etc/auto.master
+dir:/etc/auto.master.d
```

**`+dir:/etc/auto.master.d` in `/etc/auto.master` is what includes the directory.** It is there by default on RHEL.

**The filename must end in `.autofs`:**

```bash
sudo mv /etc/auto.master.d/shares /etc/auto.master.d/shares.autofs    # if named wrongly
sudo systemctl restart autofs
```

A file without that suffix is silently ignored — no error, nothing mounts, and nothing tells you why.

**Why drop-ins are better than editing `/etc/auto.master`:**

| | Editing `/etc/auto.master` | **A drop-in in `/etc/auto.master.d/`** |
| --- | --- | --- |
| Survives a package update | **May conflict** | **Yes, untouched** |
| Adding or removing config | Edit a shared file | **Add or delete one file** |
| Risk of breaking other entries | **Yes** | **No** |
| Easy to see what you changed | No | **Yes** |

**This is the same pattern as everywhere else on this exam:**

| Purpose | Drop-in location | Chapter |
| --- | --- | --- |
| sudo | `/etc/sudoers.d/` | `11-password-aging-sudo.md` |
| systemd units | `/etc/systemd/system/UNIT.d/` | `14-systemd-services.md` |
| sysctl | `/etc/sysctl.d/` | `31-swap.md` |
| NetworkManager | `/etc/NetworkManager/conf.d/` | `25-hostnames-dns.md` |
| **autofs** | **`/etc/auto.master.d/*.autofs`** | this file |

**Prefer a drop-in whenever one exists.** It is cleaner, safer, and trivially reversible:

```bash
sudo rm /etc/auto.master.d/shares.autofs
sudo systemctl restart autofs
findmnt -t autofs                          # the entry is gone
```

**Task 14.**

```bash
sudo mount -t nfs server2:/export/shared /nfs
```

```text
mount: /nfs: wrong fs type, bad option, bad superblock on server2:/export/shared,
       missing codepage or helper program, or other error.
```

**The message mentions "helper program", and that is the clue: `nfs-utils` is missing.**

```bash
rpm -q nfs-utils
```

```text
package nfs-utils is not installed
```

```bash
sudo dnf install -y nfs-utils
sudo mount -t nfs server2:/export/shared /nfs
findmnt /nfs
```

**`mount` needs `/sbin/mount.nfs`, provided by `nfs-utils`, to handle NFS.** Without it the kernel cannot interpret the filesystem type and produces this generic error.

```bash
ls -l /sbin/mount.nfs /sbin/mount.nfs4
rpm -qf /sbin/mount.nfs
```

**`nfs-utils` is required on the client as well as the server**, which surprises people — the package name suggests server tooling.

The same generic error has other causes, in rough order of likelihood:

| Cause | Check | Fix |
| --- | --- | --- |
| **`nfs-utils` missing** | `rpm -q nfs-utils` | **`dnf install nfs-utils`** |
| Typo in the type | `mount -t nfs` not `-t nfts` | Correct it |
| **Missing colon in the source** | `server2:/export` not `server2/export` | **Add the colon** |
| Bad option | `mount -v` for detail | Remove suspect options |
| Wrong protocol version | `mount -o vers=3` | Try another version |
| Path does not exist on the server | `showmount -e server2` | Correct the path |

```bash
sudo mount -t nfs -v server2:/export/shared /nfs
```

`-v` shows the negotiation and usually names the real problem:

```text
mount.nfs: timeout set for ...
mount.nfs: trying text-based options 'vers=4.2,addr=192.168.56.12'
mount.nfs: mount(2): Permission denied
mount.nfs: access denied by server while mounting server2:/export/shared
```

**Learn to distinguish the four common NFS mount errors:**

| Error | Cause | Where to fix |
| --- | --- | --- |
| **`wrong fs type`** | **`nfs-utils` not installed** | **The client** |
| **`No route to host`** | **Firewall** | **The server** |
| **`Connection refused`** | **`nfs-server` not running** | **The server** |
| **`access denied by server`** | **`/etc/exports`** | **The server** |

**Task 15.**

```bash
sudo mount -t nfs server2:/export/shared /nfs      # works
sudo reboot
findmnt /nfs                                        # nothing
```

```bash
# 1. Is there an fstab entry at all?
grep nfs /etc/fstab
```

If not, that is the answer — you mounted by hand and never wrote the entry. **A command-line `mount` never persists.**

```bash
echo "server2:/export/shared  /nfs  nfs  defaults,_netdev  0 0" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo mount -a
```

```bash
# 2. Entry present but it failed at boot
sudo journalctl -b | grep -i nfs
systemctl --failed
systemctl status remote-fs.target
sudo mount -a                              # does it work NOW?
```

**If `mount -a` works now but the boot failed, the cause is `_netdev`:**

```bash
grep nfs /etc/fstab
```

```text
server2:/export/shared  /nfs  nfs  defaults  0 0        ← no _netdev
```

```bash
sudo sed -i 's|\(server2:/export/shared.*nfs.*\)defaults|\1defaults,_netdev|' /etc/fstab
grep nfs /etc/fstab
sudo findmnt --verify
```

**The reason:** without `_netdev`, systemd treats it as a local filesystem and orders it in `local-fs.target`, which runs before networking. The mount is attempted with no network and fails. `_netdev` moves it to `remote-fs.target`, after `network-online.target`.

```bash
systemctl list-dependencies remote-fs.target
systemctl status remote-fs.target
```

```bash
# 3. Does the server name resolve at boot?
getent hosts server2.lab.example.com
grep server2 /etc/hosts
```

**A name resolved by DNS may not be resolvable early in the boot.** An `/etc/hosts` entry always is — see `25-hostnames-dns.md`:

```bash
echo "192.168.56.12  server2.lab.example.com server2" | sudo tee -a /etc/hosts
```

```bash
# 4. Is the server actually up?
ping -c2 server2
showmount -e server2
```

The full checklist:

| Cause | Fix |
| --- | --- |
| **No `/etc/fstab` entry** | **Add one** |
| **`_netdev` missing** | **Add it** |
| `noauto` in the options | Remove it |
| Server name unresolvable | `/etc/hosts` entry |
| Server down | `nofail`, or use autofs |
| NetworkManager not enabled | `systemctl enable NetworkManager` |
| `autoconnect no` on the interface | `nmcli con mod ... autoconnect yes` (`24-network-nmcli.md`) |

**The robust combination:**

```text
server2:/export/shared  /nfs  nfs  defaults,_netdev,nofail  0 0
```

**Or sidestep the whole problem with autofs**, which does not mount at boot at all and therefore cannot fail at boot.

**Task 16.**

```bash
ls /shares
```

```text
(empty)
```

**This is usually not a fault.** autofs mounts on access to the *subdirectory*, and it cannot list keys it has not been asked for:

```bash
ls /shares/data                            # access the FULL path
findmnt /shares/data
```

**In most cases that is the entire answer.** If it still does not mount:

```bash
# 1. Is autofs running and enabled?
systemctl status autofs
systemctl is-enabled autofs
sudo systemctl enable --now autofs
```

```bash
# 2. Are the maps syntactically right?
cat /etc/auto.master
ls -l /etc/auto.master.d/
cat /etc/auto.master.d/*.autofs
cat /etc/auto.shares
```

```bash
# 3. Does the drop-in filename end in .autofs?
ls -l /etc/auto.master.d/
```

**A file not ending in `.autofs` is silently ignored.** No error, nothing mounted:

```bash
sudo mv /etc/auto.master.d/shares /etc/auto.master.d/shares.autofs
sudo systemctl restart autofs
```

```bash
# 4. Did you restart autofs after editing the maps?
sudo systemctl restart autofs
findmnt -t autofs
```

```bash
# 5. Does a real directory shadow the automount?
ls -la /shares/
sudo rmdir /shares/data                    # if you created it by hand
sudo systemctl restart autofs
ls /shares/data
```

**A hand-created `/shares/data` prevents autofs from mounting there.** Remove it.

```bash
# 6. The best diagnostic: run automount in the foreground
sudo systemctl stop autofs
sudo automount -f -v
# in another terminal:  ls /shares/data
```

```text
Starting automounter version 5.1.7
lookup_read_master: lookup(file): read master map /etc/auto.master
mounted indirect on /shares with timeout 60, freq 15 seconds
attempting to mount entry /shares/data
mount(nfs): mounted server2:/export/shared on /shares/data
```

**That output tells you exactly which maps were read and what happened**, which no other tool does. Ctrl-C when done, then:

```bash
sudo systemctl start autofs
```

```bash
# 7. The logs
sudo journalctl -u autofs -n 50
sudo journalctl -u autofs -f
```

```bash
# 8. Is the underlying NFS mount even possible?
showmount -e server2
sudo mount -t nfs server2:/export/shared /mnt
sudo umount /mnt
```

**Always test the plain NFS mount by hand first.** If that fails, autofs cannot succeed, and you are debugging the wrong layer.

The checklist:

| Cause | Fix |
| --- | --- |
| **Listed the parent instead of the full path** | **`ls /shares/data`** |
| autofs not enabled or not started | `systemctl enable --now autofs` |
| **Not restarted after a map change** | **`systemctl restart autofs`** |
| **Drop-in not named `*.autofs`** | **Rename it** |
| **A real directory shadows the mount point** | **`rmdir` it** |
| Map syntax error | `automount -f -v` |
| The NFS export itself is unreachable | Fix NFS first |
| Missing `/-` for a direct map | Add it |

**Task 17.**

```bash
sudo touch /nfs/newfile
```

```text
touch: cannot touch '/nfs/newfile': Permission denied
```

Note this is **Permission denied**, not **Read-only file system** — different causes.

```bash
# 1. Is the mount read-only?
findmnt /nfs
```

`ro` in the options would give "Read-only file system" instead. So it is not that.

```bash
# 2. Is the EXPORT read-only? Check on the server
sudo exportfs -v
```

```text
/export/shared 192.168.56.0/24(sync,...,ro,secure,root_squash)
```

A server-side `ro` also produces "Read-only file system". Not this either.

```bash
# 3. Permissions on the exported directory — the usual answer
ls -ld /nfs
```

```text
drwxr-xr-x. 2 root root 4096 Aug 18 16:00 /nfs
```

**`755` owned by root, so only root can write — and root is squashed.**

```bash
# On the server
sudo chmod 777 /export/shared
# or, better, give it to a group
sudo chgrp developers /export/shared
sudo chmod 2775 /export/shared             # collaborative dir (12-special-permissions-acls.md)
```

```bash
# 4. root_squash — root is mapped to nobody
sudo touch /nfs/roottest
ls -l /nfs/roottest
```

```text
-rw-r--r--. 1 nobody nobody 0 Aug 18 16:50 /nfs/roottest
```

**Root's writes land as `nobody`, so a directory not writable by `nobody`/`other` refuses them.** That is the default and it is deliberate:

```bash
# On the server, only if a task requires it:
sudo vim /etc/exports
#   /export/shared  192.168.56.0/24(rw,sync,no_root_squash)
sudo exportfs -rav
```

```bash
# 5. UID mismatch between client and server
id alice                                   # on the client
# on the server:
id alice
ls -ln /nfs
```

**NFSv3 and NFSv4 with `sec=sys` pass numeric UIDs and GIDs, not names.** If `alice` is UID 1001 on the client and 1005 on the server, her files appear owned by whoever is 1001 there — and permissions are enforced by number:

```bash
ls -ln /nfs                                # numeric IDs
```

The fix is consistent UIDs on both machines:

```bash
sudo usermod -u 1005 alice
```

```bash
# 6. SELinux
sudo ausearch -m AVC -ts recent
getsebool -a | grep nfs
sudo setsebool -P use_nfs_home_dirs on     # home directories on NFS
sudo setsebool -P httpd_use_nfs on         # httpd serving from NFS
```

**The diagnostic table:**

| Error | Cause | Where to fix |
| --- | --- | --- |
| **`Read-only file system`** | `ro` on the client, or **`ro` in `/etc/exports`** | Client options, or the server |
| **`Permission denied`** | **Directory permissions**, `root_squash`, or **UID mismatch** | **The server** |
| `Permission denied` with AVC logged | **SELinux** | `setsebool -P` |
| Owner shows as `nobody` | **`root_squash` (normal)** | `no_root_squash`, if required |
| Owner shows as the wrong user | **UID mismatch** | Align UIDs |

**Check in this order: mount options, `exportfs -v`, then `ls -ld` on the exported directory.** The third is the answer most of the time.

**Task 18.**

Before the reboot, on the **client**:

```bash
grep nfs /etc/fstab
sudo findmnt --verify
sudo mount -a && echo "mount -a OK"
findmnt -t nfs4,nfs
systemctl is-enabled autofs
cat /etc/auto.master.d/*.autofs
cat /etc/auto.shares
findmnt -t autofs
getent hosts server2.lab.example.com
```

On the **server**:

```bash
systemctl is-enabled nfs-server
systemctl is-active nfs-server
sudo exportfs -v
cat /etc/exports
sudo firewall-cmd --permanent --list-services
diff <(sudo firewall-cmd --list-services) <(sudo firewall-cmd --permanent --list-services)
```

Everything must hold:

- **`/etc/fstab` NFS entries include `_netdev`.**
- **`mount -a` succeeds.**
- **`autofs` is enabled**, not merely started.
- **`nfs-server` is enabled** on the server.
- **`/etc/exports` contains the exports** and `exportfs -v` shows them.
- **The firewall permanent set includes `nfs`** and the runtime/permanent diff is empty.
- The server name resolves, ideally from `/etc/hosts`.

```bash
sudo reboot
```

After, on the client:

```bash
findmnt -t nfs4,nfs
df -hT | grep -i nfs
ls /shares/data                            # trigger the automount
findmnt /shares/data
findmnt -t autofs
systemctl status autofs
systemctl --failed
journalctl -b | grep -i -E 'nfs|autofs'
```

**Verify the server independently:**

```bash
# On server2 after ITS reboot
systemctl is-active nfs-server
sudo exportfs -v
firewall-cmd --list-services
```

| Symptom after reboot | Cause |
| --- | --- |
| fstab NFS mount absent | **No entry, or `_netdev` missing** |
| Boot delayed then failed | Server unreachable; add `nofail` |
| autofs path does not mount | **`autofs` not enabled** |
| autofs mounts nothing at all | Map file or drop-in naming problem |
| Client cannot mount at all | **`nfs-server` not enabled on the server** |
| `No route to host` | **Firewall rule not `--permanent`** |

**Both machines must be checked.** A perfect client configuration fails if the server's `nfs-server` was started but never enabled, or its firewall rule was added without `--permanent` — the two most common ways an NFS task fails after a reboot.

```bash
# The pre-reboot NFS check
# client:
grep nfs /etc/fstab; sudo mount -a && echo OK; systemctl is-enabled autofs
# server:
systemctl is-enabled nfs-server; sudo exportfs -v; sudo firewall-cmd --permanent --list-services
```

---

## Verify

```bash
# Client
rpm -q nfs-utils autofs
showmount -e server2
findmnt -t nfs4,nfs
findmnt -t autofs
df -hT | grep -i nfs
grep nfs /etc/fstab
sudo findmnt --verify
sudo mount -a
systemctl is-enabled autofs
cat /etc/auto.master
ls -l /etc/auto.master.d/
cat /etc/auto.shares
sudo automount -f -v
journalctl -u autofs -n 30

# Server
systemctl is-enabled nfs-server
systemctl is-active nfs-server
cat /etc/exports
sudo exportfs -v
sudo firewall-cmd --list-services
sudo firewall-cmd --permanent --list-services
ss -tlnp | grep 2049
```

## Persistence Check

**Client:**

| Change | Persistent form | Also required |
| --- | --- | --- |
| NFS mount | **`/etc/fstab` with `_netdev`** | **`findmnt --verify` + `mount -a`** |
| autofs maps | `/etc/auto.master.d/*.autofs` and the map file | **`systemctl enable --now autofs`** |
| autofs service | **`systemctl enable autofs`** | `restart` after map changes |
| Server name | `/etc/hosts` or DNS | — |

**Server:**

| Change | Persistent form | Also required |
| --- | --- | --- |
| Export | **`/etc/exports`** | **`exportfs -rav`** |
| NFS service | **`systemctl enable --now nfs-server`** | — |
| Firewall | **`firewall-cmd --permanent --add-service=nfs`** | **`--reload`** |
| Ad-hoc export | **`exportfs -o` does NOT persist** | Put it in `/etc/exports` |

**The five things that cost marks after a reboot:**

1. **`_netdev` missing** from an `/etc/fstab` NFS entry.
2. **`autofs` started but not enabled.**
3. **`nfs-server` started but not enabled.**
4. **Firewall rules added without `--permanent`.**
5. **`exportfs -o` used instead of editing `/etc/exports`.**

```bash
# The pre-reboot check, both machines
# client
grep nfs /etc/fstab && sudo mount -a && systemctl is-enabled autofs
# server
systemctl is-enabled nfs-server && sudo exportfs -v && sudo firewall-cmd --permanent --list-services
```

## Exam Tips

- **`showmount -e SERVER` first.** It proves reachability and lists the exports.
- **`nfs-utils` is needed on the CLIENT too.** Without it, `mount -t nfs` gives the misleading "wrong fs type".
- **The syntax is `server:/path`** — with a colon.
- **`_netdev` in `/etc/fstab` is mandatory for NFS.** Without it the boot mounts before the network is up and fails. "Works with `mount -a` but not at boot" is always this.
- **Add `nofail`** if the server might be unavailable. Do not use `noauto` when a task says "mount at boot".
- **`soft,timeo=100`** stops the client hanging forever when the server disappears. The default `hard` blocks processes unkillably.
- **The four client errors map to four server-side causes:** `wrong fs type` = missing package on the client; `No route to host` = firewall; `Connection refused` = service not running; `access denied by server` = `/etc/exports`.
- **Server side needs all four layers**: the directory, `/etc/exports`, `systemctl enable --now nfs-server`, and `firewall-cmd --permanent --add-service=nfs` (plus `mountd` and `rpc-bind` for NFSv3).
- **No space before the parentheses in `/etc/exports`.** `192.168.56.0/24(rw)`. A space exports read-write to the world.
- **`exportfs -rav` after every `/etc/exports` change.** It applies changes without disconnecting clients. `exportfs -o` does not persist.
- **`root_squash` is the default**, so root's files on an NFS mount are owned by `nobody`. That is correct behaviour.
- **"Permission denied" is usually the directory permissions or a UID mismatch. "Read-only file system" is `ro` on the client or in the export.**
- **autofs: master map → map file.** `/shares  /etc/auto.shares  --timeout=60`, then `data  -rw  server2:/export/shared`.
- **Use `/etc/auto.master.d/name.autofs`.** The `.autofs` suffix is required, or the file is silently ignored.
- **`systemctl enable --now autofs`, and `restart` after every map change.**
- **Do not create the automount subdirectory yourself.** A real directory shadows the mount.
- **`ls /shares` looks empty. `ls /shares/data` mounts it.** Access the full path.
- **`/-` in the master map means a direct map**, with absolute paths in the map file.
- **`*` and `&`** give wildcard maps: `*  -rw  server2:/export/home/&` mounts `/home/guests/alice` from `server2:/export/home/alice`. A classic exam task.
- **`sudo automount -f -v` is the best autofs diagnostic.** Stop the service and run it in the foreground.
- **"mount at boot" means `/etc/fstab`; "on demand" or "when accessed" means autofs.**
- **Check both machines before the reboot.** `is-enabled` on `nfs-server` and `autofs`, and `--permanent` on the firewall.
