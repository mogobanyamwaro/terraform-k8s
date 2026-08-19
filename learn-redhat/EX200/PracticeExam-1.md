# Practice Exam 1

**18 tasks. 3 hours. 300 points. Pass mark 210 (70%).**

The first of three. This one covers the objective spread evenly and is deliberately close to the real exam in difficulty. Do it after you have worked through `01.md` to `35.md` at least once.

---

## Before you start

**Environment.** Two machines, as built in `Lab-Setup.md`:

| Host | Address | Role |
| --- | --- | --- |
| **server1** | 192.168.56.11 | Where almost everything happens |
| **server2** | 192.168.56.12 | The second host, for NFS and remote tests |

**server1 needs at least two unused disks** (`/dev/sdb` and `/dev/sdc`, 5 GiB each is plenty).

**Take a snapshot of both machines before you start.** You will want to repeat this exam.

**Rules, and take these seriously — they are what make the practice worth doing:**

1. **Three hours. Set a timer and stop when it goes off.** Score what you have.
2. **No internet.** `man`, `info`, and `/usr/share/doc` only. Close the browser.
3. **No notes from this repository.** That includes `CheatSheet.md`.
4. **Everything must survive a reboot.** Grading happens after one.
5. **The root password is `redhat` on both machines** unless a task changes it.
6. **Read every task before starting.** Note the dependencies and which host each one is on.

**Suggested pacing:**

```text
0:00 - 0:10   Read everything. Note dependencies. Check lsblk, ip a, hostnamectl.
0:10 - 1:00   Storage (tasks 9-13). Longest, riskiest, do it early.
1:00 - 1:40   Users, permissions, services (tasks 3-8).
1:40 - 2:20   Networking, SELinux, containers (tasks 14-18).
2:20 - 2:35   Tasks 1-2, and anything skipped.
2:35 - 2:50   REBOOT. Verify everything. Fix what broke.
2:50 - 3:00   Second reboot if you changed anything.
```

**Do not leave the reboot to the last five minutes.** It is the only test that matters and it always finds something.

---

## The tasks

### Task 1 — Reset the root password (15 points)

The root password on **server1** has been lost. Regain access and set it to `redhat`.

**You must do this by interrupting the boot process, not by using an existing session.** If you currently have a root shell, close it and reboot first.

---

### Task 2 — Configure a local repository (15 points)

On **server1**, configure `dnf` to use the repositories on the installation media, which is available at `/dev/sr0` (or as an ISO file at `/root/rhel.iso` if your lab has no virtual optical drive).

- The media must be mounted at `/mnt/iso`, **persistently**.
- Two repositories must be configured: `BaseOS` and `AppStream`.
- GPG checking may be disabled.
- `dnf repolist` must show both, and `dnf install -y httpd` must succeed.

---

### Task 3 — Users and groups (20 points)

On **server1**:

- Create a group `sysadmins` with GID **6000**.
- Create a group `developers`.
- Create these users:

| User | UID | Primary group | Secondary groups | Shell |
| --- | --- | --- | --- | --- |
| `natasha` | 3001 | `sysadmins` | `wheel` | `/bin/bash` |
| `harry` | 3002 | `sysadmins` | — | `/bin/bash` |
| `sarah` | 3003 | `developers` | — | `/sbin/nologin` |

- All three passwords must be `RedHat123`.
- `natasha` and `harry` must be required to change their password at their next login.
- All three passwords must expire after **60 days**, with **7 days'** warning.
- `sarah`'s account must expire on **2026-12-31**.

---

### Task 4 — Configure sudo (10 points)

On **server1**, members of the `sysadmins` group must be able to run **any** command with `sudo` **without being prompted for a password**.

Do not modify `/etc/sudoers` directly.

---

### Task 5 — Collaborative directory (20 points)

On **server1**, create a directory `/srv/devshare` for the `developers` group:

- Files created inside it must belong to the `developers` group.
- Members of `developers` must be able to read, write, and delete **their own** files, and read and **modify** each other's files.
- Members must **not** be able to delete files belonging to other members.
- Users outside `developers` must have no access at all.
- The user `natasha` must have read-only access to the directory and to everything created in it, now and in the future.

---

### Task 6 — Find and copy files (10 points)

On **server1**:

- Find every file on the system owned by the user `harry` and copy it to `/root/harry-files/`, preserving nothing in particular.
- Find every file under `/usr` with the SUID bit set and write the list of their full paths to `/root/suid-list.txt`, one per line.
- Create `/root/sync.log` containing every line from `/var/log/messages` that contains the string `error`, case-insensitively.

---

### Task 7 — Services and boot target (10 points)

On **server1**:

- The system must boot into **multi-user** (text) mode by default.
- `chronyd` must be running and start at boot, synchronising with **server2** (192.168.56.12).
- The `atd` service must be **masked** so it can never be started.
- The `tuned` profile must be set to `virtual-guest`.

---

### Task 8 — Scheduled task (15 points)

On **server1**, create a job that runs as the user **harry** every day at **14:23**, executing:

```bash
/bin/echo hello
```

It must be scheduled with cron and must survive a reboot.

---

### Task 9 — Add a partition and filesystem (20 points)

On **server1**, using the free space on `/dev/sdb`:

- Create a **1 GiB** partition.
- Format it with **xfs**.
- Mount it **persistently** at `/data`, **by UUID**.
- It must be mounted after a reboot with no manual intervention.

---

### Task 10 — Logical volumes (25 points)

On **server1**:

- Create a volume group named `vgprod` with a physical extent size of **16 MiB**, using free space on `/dev/sdb` or `/dev/sdc`.
- Create a logical volume named `lvweb` in `vgprod`, **exactly 20 extents** in size.
- Format `lvweb` with **ext4** and mount it persistently at `/web`.

---

### Task 11 — Extend a logical volume (20 points)

On **server1**, extend the logical volume `lvweb` and its filesystem so that the mounted filesystem at `/web` is **at least 800 MiB**.

You may need to add capacity to the volume group first.

---

### Task 12 — Add swap (15 points)

On **server1**, add **512 MiB** of additional swap space:

- It must be on a new partition, not a file.
- It must be active after a reboot.
- The existing swap must not be disturbed.

---

### Task 13 — NFS and autofs (25 points)

**On server2:** export the directory `/export/team` read-write to the `192.168.56.0/24` network. Create it if it does not exist and put a file called `teamfile` in it. The export must survive a reboot and be reachable through the firewall.

**On server1:** configure `autofs` so that accessing `/shares/team` automatically mounts `server2:/export/team`.

- The mount must be read-write.
- It must work after a reboot with no manual intervention.
- Do **not** use `/etc/fstab` for this.

---

### Task 14 — Network configuration (15 points)

On **server1**:

- The static IPv4 address must be **192.168.56.11/24**, gateway **192.168.56.1**.
- DNS servers must be **192.168.56.1** and **8.8.8.8**, in that order.
- The search domain must be **lab.example.com**.
- The connection must come up automatically at boot.
- The hostname must be **server1.lab.example.com**, persistently.
- `server2.lab.example.com` must resolve to **192.168.56.12** without DNS.

---

### Task 15 — Firewall (15 points)

On **server1**:

- The `firewalld` service must be running and enabled.
- **HTTP** must be permitted from the **192.168.56.0/24** network only. Requests from any other source must be **rejected**.
- Port **8090/tcp** must be open to everyone.
- SSH must remain available from everywhere.

---

### Task 16 — SELinux (25 points)

On **server1**:

- SELinux must be in **enforcing** mode, now and after a reboot.
- Configure Apache so that its `DocumentRoot` is **`/web/html`** instead of `/var/www/html`.
- Create `/web/html/index.html` containing the text `Practice Exam 1`.
- Apache must serve this page on the default port and must start at boot.
- Requesting the page from **server2** must return it successfully.
- There must be no SELinux denials.

---

### Task 17 — Shell script (20 points)

On **server1**, create an executable script at **`/usr/local/bin/userinfo.sh`** that:

- Takes **exactly one** argument, a username.
- Exits with status **1** and prints a usage message to **stderr** if the number of arguments is not one.
- Exits with status **2** and prints an error to **stderr** if the user does not exist.
- Otherwise prints three lines to stdout, exactly:

```text
USER: <username>
UID: <uid>
GROUPS: <comma-separated list of the user's groups>
```

- Exits with status **0** on success.

---

### Task 18 — Container as a service (25 points)

On **server1**:

- Pull the image `registry.access.redhat.com/ubi9/httpd-24`. If your lab has no internet access, use any locally available image and adapt the paths.
- Create the directory `/srv/container-web` containing an `index.html` file with the text `Container Exam 1`.
- Run a container named `webapp` that:
  - serves that directory as its web content,
  - publishes container port **8080** on host port **8080**,
  - starts automatically at boot as a **systemd service**.
- The page must be retrievable from **server2** at `http://192.168.56.11:8080`.

---

## Stop here

**Reboot both machines and verify everything before reading on.**

```bash
sudo /usr/local/bin/precheck.sh        # if you created it from 36.md
sudo findmnt --verify && sudo mount -a
sudo reboot
```

---
---

# Solutions and Grading

Each task lists the commands, the verification, and the points. **Grade yourself honestly, after a reboot, with no manual intervention.** Partial credit is noted where it applies.

---

## Task 1 — Root password (15 points)

```text
1. Reboot; at the GRUB menu press  e
2. Append  rd.break  to the line beginning with 'linux'
3. Ctrl-x
4. mount -o remount,rw /sysroot
5. chroot /sysroot
6. passwd root          → redhat
7. touch /.autorelabel
8. exit
9. exit
```

Wait for the relabel and the automatic reboot.

**Verification:**

```bash
ls -Z /etc/shadow
getenforce
sudo ausearch -m AVC -ts boot
```

```text
system_u:object_r:shadow_t:s0 /etc/shadow
Enforcing
```

| Criterion | Points |
| --- | --- |
| Root login works with the new password | 10 |
| **SELinux enforcing and `/etc/shadow` correctly labelled** | **5** |

**Zero for the whole task if you cannot log in as root.** If you skipped `/.autorelabel` and had to recover with `enforcing=0`, take 10 of 15 — you got there, but the sequence is not yet automatic.

---

## Task 2 — Local repository (15 points)

```bash
sudo mkdir -p /mnt/iso

# From a virtual optical drive:
echo "/dev/sr0  /mnt/iso  iso9660  ro,nofail  0 0" | sudo tee -a /etc/fstab

# Or from an ISO file:
echo "/root/rhel.iso  /mnt/iso  iso9660  loop,ro,nofail  0 0" | sudo tee -a /etc/fstab

sudo findmnt --verify
sudo mount -a
ls /mnt/iso

sudo tee /etc/yum.repos.d/local.repo >/dev/null <<'EOF'
[local-baseos]
name=Local BaseOS
baseurl=file:///mnt/iso/BaseOS
enabled=1
gpgcheck=0

[local-appstream]
name=Local AppStream
baseurl=file:///mnt/iso/AppStream
enabled=1
gpgcheck=0
EOF

sudo dnf clean all
dnf repolist
sudo dnf install -y httpd
```

**Verification:**

```bash
dnf repolist
findmnt /mnt/iso
grep iso /etc/fstab
sudo reboot
dnf repolist                           # still works
```

| Criterion | Points |
| --- | --- |
| Both repositories listed by `dnf repolist` | 6 |
| A package installs successfully | 4 |
| **The mount is in `/etc/fstab` and survives a reboot** | **5** |

**The mount is the part people miss.** A repository pointing at `/mnt/iso` is worthless if `/mnt/iso` is empty after a reboot.

---

## Task 3 — Users and groups (20 points)

```bash
sudo groupadd -g 6000 sysadmins
sudo groupadd developers

sudo useradd -u 3001 -g sysadmins -G wheel -s /bin/bash natasha
sudo useradd -u 3002 -g sysadmins -s /bin/bash harry
sudo useradd -u 3003 -g developers -s /sbin/nologin sarah

for u in natasha harry sarah; do
    echo 'RedHat123' | sudo passwd --stdin "$u"
    sudo chage -M 60 -W 7 "$u"
done

sudo chage -d 0 natasha
sudo chage -d 0 harry
sudo chage -E 2026-12-31 sarah
```

**Verification:**

```bash
getent group sysadmins developers
id natasha ; id harry ; id sarah
sudo chage -l natasha ; sudo chage -l harry ; sudo chage -l sarah
getent passwd natasha harry sarah
```

```text
sysadmins:x:6000:
uid=3001(natasha) gid=6000(sysadmins) groups=6000(sysadmins),10(wheel)
Last password change : password must be changed
Maximum number of days between password change : 60
Number of days of warning before password expires : 7
Account expires : Dec 31, 2026
```

| Criterion | Points |
| --- | --- |
| Both groups exist, `sysadmins` has GID 6000 | 3 |
| All three users exist with the correct UIDs | 4 |
| Correct primary groups | 3 |
| `natasha` is in `wheel` | 2 |
| Correct shells, including `sarah`'s `nologin` | 3 |
| Passwords set | 2 |
| **Aging: `-M 60 -W 7` for all three** | **2** |
| **`chage -d 0` for natasha and harry; `-E` for sarah** | **1** |

**Common losses:** using `-G` instead of `-g` for the primary group; forgetting `chage -d 0`; setting `-E` on the wrong user.

---

## Task 4 — sudo (10 points)

```bash
sudo visudo -f /etc/sudoers.d/sysadmins
```

```text
%sysadmins  ALL=(ALL)  NOPASSWD: ALL
```

```bash
sudo visudo -c
sudo -l -U natasha
```

**Verification:**

```bash
sudo -l -U natasha
sudo -l -U harry
su - harry -c 'sudo id'                # must NOT prompt for a password
```

```text
User natasha may run the following commands on server1:
    (ALL) NOPASSWD: ALL
```

| Criterion | Points |
| --- | --- |
| `sysadmins` members can run any command with sudo | 5 |
| **`NOPASSWD` — no password prompt** | **3** |
| **A drop-in file was used, and `visudo -c` passes** | **2** |

**Zero if `visudo -c` reports a syntax error**, even if the rule looks right — a broken sudoers file is worse than no rule.

---

## Task 5 — Collaborative directory (20 points)

```bash
sudo mkdir -p /srv/devshare
sudo chown root:developers /srv/devshare
sudo chmod 3770 /srv/devshare                     # SGID + sticky + group rwx

sudo setfacl -m  g:developers:rwx /srv/devshare
sudo setfacl -m d:g:developers:rwx /srv/devshare

sudo setfacl -m  u:natasha:rx /srv/devshare
sudo setfacl -m d:u:natasha:rx /srv/devshare
```

**Verification:**

```bash
ls -ld /srv/devshare
getfacl /srv/devshare
```

```text
drwxrws--T+ 2 root developers 6 /srv/devshare
```

**Behavioural test — this is what is actually graded:**

```bash
sudo useradd -m testdev -G developers            # if you need a second member
su - sarah -c 'touch /srv/devshare/sarah.txt' 2>/dev/null || \
  sudo -u sarah touch /srv/devshare/sarah.txt    # sarah has nologin
ls -l /srv/devshare/
sudo -u testdev bash -c 'echo edit >> /srv/devshare/sarah.txt'   # must WORK
sudo -u testdev rm -f /srv/devshare/sarah.txt                    # must FAIL
sudo -u natasha cat /srv/devshare/sarah.txt                      # must WORK
sudo -u natasha touch /srv/devshare/x                            # must FAIL
```

| Criterion | Points |
| --- | --- |
| **SGID set — new files get the `developers` group** | **5** |
| Group members can create and read | 3 |
| **Group members can modify each other's files (default ACL, or a suitable umask)** | **4** |
| **Sticky bit — members cannot delete others' files** | **4** |
| No access for others (`o` bits are zero) | 2 |
| **`natasha` has read-only access, including a default ACL for future files** | **2** |

**The subtlety: `3770` alone gives the right group but files are `-rw-r--r--` under the default umask, so members cannot modify each other's files.** The default ACL is what completes the requirement.

---

## Task 6 — Find and copy (10 points)

```bash
sudo mkdir -p /root/harry-files
sudo find / -user harry -exec cp {} /root/harry-files/ \; 2>/dev/null

sudo find /usr -perm /4000 -type f > /root/suid-list.txt

sudo grep -i error /var/log/messages > /root/sync.log
```

**Verification:**

```bash
ls /root/harry-files/
wc -l /root/suid-list.txt
head -3 /root/suid-list.txt
wc -l /root/sync.log
```

| Criterion | Points |
| --- | --- |
| `/root/harry-files/` contains harry's files | 4 |
| **`/root/suid-list.txt` uses `-perm /4000`, not `-perm 4000`** | **3** |
| `/root/sync.log` contains case-insensitive matches | 3 |

**`find /usr -perm 4000` matches almost nothing** because it means "exactly mode 4000". **`/4000` means "any of these bits", which is what SUID means.**

**If `/var/log/messages` has no matching lines, an empty file is still correct** — the command was right.

---

## Task 7 — Services and boot target (10 points)

```bash
sudo systemctl set-default multi-user.target

sudo dnf install -y chrony
sudo vim /etc/chrony.conf
```

```text
server 192.168.56.12 iburst
```

```bash
sudo systemctl enable --now chronyd
sudo systemctl restart chronyd
chronyc sources -v

sudo systemctl mask atd

sudo dnf install -y tuned
sudo systemctl enable --now tuned
sudo tuned-adm profile virtual-guest
```

**Verification:**

```bash
systemctl get-default
systemctl is-enabled chronyd ; systemctl is-active chronyd
grep -E '^(server|pool)' /etc/chrony.conf
chronyc sources
systemctl is-enabled atd                # masked
sudo systemctl start atd                # must refuse
tuned-adm active
```

| Criterion | Points |
| --- | --- |
| Default target is `multi-user.target` | 3 |
| **`chronyd` enabled and configured for server2** | **3** |
| **`atd` is `masked`, not merely `disabled`** | **2** |
| tuned profile is `virtual-guest` | 2 |

**`disable` is not `mask`.** A disabled unit can still be started by hand or pulled in as a dependency; a masked one cannot.

---

## Task 8 — Scheduled task (15 points)

```bash
sudo crontab -e -u harry
```

```text
23 14 * * * /bin/echo hello
```

**Or equivalently:**

```bash
echo '23 14 * * * harry /bin/echo hello' | sudo tee /etc/cron.d/harryjob
```

```bash
sudo systemctl enable --now crond
```

**Verification:**

```bash
sudo crontab -l -u harry
systemctl is-enabled crond
sudo ls -l /var/spool/cron/harry
```

| Criterion | Points |
| --- | --- |
| **The schedule is correct: `23 14 * * *`, minute first** | **6** |
| **It runs as harry** | 5 |
| `crond` is enabled | 4 |

**The field order is minute, hour — so 14:23 is `23 14`, not `14 23`.** That single inversion is the most common way to lose this task.

**If you used `/etc/cron.d/`, the user field is required.** If you used `crontab -e -u harry`, there must be no user field.

---

## Task 9 — Partition and filesystem (20 points)

```bash
lsblk
sudo fdisk /dev/sdb
#   g (if the disk has no label), n, ⏎, ⏎, +1G, w
sudo partprobe /dev/sdb
lsblk /dev/sdb

sudo mkfs.xfs /dev/sdb1
sudo mkdir -p /data

echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1)  /data  xfs  defaults  0 0" \
  | sudo tee -a /etc/fstab

sudo findmnt --verify
sudo mount -a
df -hT /data
```

**Verification:**

```bash
lsblk -f /dev/sdb
grep data /etc/fstab
findmnt /data
df -hT /data
sudo reboot
findmnt /data
```

| Criterion | Points |
| --- | --- |
| A ~1 GiB partition exists on `/dev/sdb` | 5 |
| xfs filesystem created | 5 |
| Mounted at `/data` | 4 |
| **The fstab entry uses `UUID=`** | **3** |
| **It is mounted after a reboot** | **3** |

**Using `/dev/sdb1` in fstab instead of the UUID costs 3 points** even though it works — the task specified UUID.

---

## Task 10 — Logical volumes (25 points)

```bash
sudo fdisk /dev/sdc              # g, n, ⏎, ⏎, +2G, t, lvm, w
sudo partprobe /dev/sdc

sudo pvcreate /dev/sdc1
sudo vgcreate -s 16M vgprod /dev/sdc1
sudo vgdisplay vgprod | grep 'PE Size'

sudo lvcreate -n lvweb -l 20 vgprod
sudo lvs vgprod

sudo mkfs.ext4 /dev/vgprod/lvweb
sudo mkdir -p /web

echo "UUID=$(sudo blkid -s UUID -o value /dev/vgprod/lvweb)  /web  ext4  defaults  0 0" \
  | sudo tee -a /etc/fstab

sudo findmnt --verify
sudo mount -a
df -hT /web
```

**Verification:**

```bash
sudo vgdisplay vgprod | grep -E 'PE Size|VG Name'
sudo lvdisplay /dev/vgprod/lvweb | grep -E 'LV Name|Current LE|LV Size'
df -hT /web
```

```text
PE Size               16.00 MiB
Current LE            20
LV Size               320.00 MiB
```

| Criterion | Points |
| --- | --- |
| Volume group `vgprod` exists | 5 |
| **Physical extent size is 16 MiB (`vgcreate -s 16M`)** | **6** |
| **`lvweb` is exactly 20 extents (`lvcreate -l 20`)** | **6** |
| ext4 filesystem | 4 |
| Mounted persistently at `/web` | 4 |

**"Exactly 20 extents" means `-l 20`, not `-L 320M`.** They happen to give the same size here, but the task tested whether you know the difference. **`vgcreate -s 16M` is the only way to get a non-default extent size and it cannot be changed afterwards** — creating the VG with defaults and then trying to fix it means starting over.

---

## Task 11 — Extend the logical volume (20 points)

```bash
sudo vgs                         # is there free space?
```

If not:

```bash
sudo fdisk /dev/sdc              # n, ⏎, ⏎, +1G, t, lvm, w
sudo partprobe /dev/sdc
sudo pvcreate /dev/sdc2
sudo vgextend vgprod /dev/sdc2
sudo vgs
```

Then:

```bash
sudo lvextend -r -L 800M /dev/vgprod/lvweb
df -h /web
```

**Verification:**

```bash
df -h /web                       # ← THE check
sudo lvs vgprod
findmnt /web
```

```text
Filesystem                 Size  Used Avail Use% Mounted on
/dev/mapper/vgprod-lvweb   777M   24K  733M   1% /web
```

| Criterion | Points |
| --- | --- |
| The logical volume is at least 800 MiB | 8 |
| **The FILESYSTEM is at least 800 MiB — `df` shows it** | **8** |
| The volume group was extended if it needed to be | 4 |

**`lvextend` without `-r` scores 8 of 20.** The LV is bigger and the filesystem — which is what the task asked about — is not. **Check `df -h`, never `lvs`.**

**A note on "at least 800 MiB":** `df` reports slightly less than the raw size because of filesystem overhead, so `-L 800M` may show as 777M. **Target a little above the requirement — `-L 850M` — when a task says "at least".**

---

## Task 12 — Swap (15 points)

```bash
sudo fdisk /dev/sdb              # n, ⏎, ⏎, +512M, t, <partition>, swap, w
sudo partprobe /dev/sdb
lsblk /dev/sdb

sudo mkswap /dev/sdb2
sudo swapon /dev/sdb2

echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb2)  none  swap  defaults  0 0" \
  | sudo tee -a /etc/fstab

sudo findmnt --verify
sudo swapoff -a && sudo swapon -a
swapon --show
free -h
```

**Verification:**

```bash
swapon --show
grep swap /etc/fstab
sudo fdisk -l /dev/sdb | grep -i swap
sudo reboot
swapon --show
```

```text
NAME           TYPE      SIZE USED PRIO
/dev/dm-1      partition   2G   0B   -2
/dev/sdb2      partition 512M   0B   -3
```

| Criterion | Points |
| --- | --- |
| A ~512 MiB partition formatted with `mkswap` | 5 |
| Active now | 3 |
| **In `/etc/fstab` with type `swap` and mount point `none`** | **4** |
| **Active after a reboot** | **3** |

**The partition type code (`t` → `swap`) is not strictly required for it to work**, but set it — `lsblk` and `fdisk -l` are how a grader checks, and it costs one keystroke.

---

## Task 13 — NFS and autofs (25 points)

**On server2:**

```bash
sudo dnf install -y nfs-utils
sudo mkdir -p /export/team
echo "team content" | sudo tee /export/team/teamfile
sudo chmod 777 /export/team

echo "/export/team  192.168.56.0/24(rw,sync)" | sudo tee -a /etc/exports
sudo exportfs -rav
sudo exportfs -v

sudo systemctl enable --now nfs-server
sudo firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
sudo firewall-cmd --reload
```

**On server1:**

```bash
sudo dnf install -y nfs-utils autofs
showmount -e server2                       # confirm the export is visible

echo "/shares  /etc/auto.team" | sudo tee /etc/auto.master.d/team.autofs
echo "team  -rw,sync  server2:/export/team" | sudo tee /etc/auto.team

sudo systemctl enable --now autofs
sudo systemctl restart autofs

ls /shares/team                            # triggers the mount
cat /shares/team/teamfile
findmnt /shares/team
```

**Verification:**

```bash
# server2
sudo exportfs -v
systemctl is-enabled nfs-server
sudo firewall-cmd --permanent --list-services

# server1
systemctl is-enabled autofs
cat /etc/auto.master.d/team.autofs /etc/auto.team
ls /shares/team
touch /shares/team/writetest && rm /shares/team/writetest    # rw works
grep -c shares /etc/fstab                  # must be 0
sudo reboot
ls /shares/team                            # mounts on access, no intervention
```

| Criterion | Points |
| --- | --- |
| **server2:** the export exists in `/etc/exports` with the correct network and `rw` | 6 |
| **server2:** `nfs-server` enabled and the firewall permits NFS | 5 |
| **server1:** the autofs master and map files are correct | 6 |
| **server1:** `autofs` is enabled | 3 |
| **Accessing `/shares/team` mounts it, read-write, after a reboot** | **5** |

**Zero for the server1 half if you used `/etc/fstab`** — the task explicitly forbade it.

**Do not create `/shares` or `/shares/team` yourself.** autofs manages them, and a pre-existing directory can prevent the automount. If `ls /shares` looks empty, that is normal for an indirect map — access `/shares/team` by name.

---

## Task 14 — Network (15 points)

```bash
nmcli device status
sudo nmcli con mod ens160 \
  ipv4.method manual \
  ipv4.addresses 192.168.56.11/24 \
  ipv4.gateway 192.168.56.1 \
  ipv4.dns "192.168.56.1 8.8.8.8" \
  ipv4.dns-search lab.example.com \
  connection.autoconnect yes

sudo nmcli con up ens160

sudo hostnamectl set-hostname server1.lab.example.com

echo "192.168.56.12  server2.lab.example.com  server2" | sudo tee -a /etc/hosts
```

**Verification:**

```bash
ip -brief addr show ens160
ip route
cat /etc/resolv.conf
nmcli -f NAME,DEVICE,AUTOCONNECT con show
hostnamectl
cat /etc/hostname
getent hosts server2.lab.example.com
ping -c2 server2
sudo reboot
ip -brief addr ; hostname -f
```

| Criterion | Points |
| --- | --- |
| Correct static address and gateway | 4 |
| **DNS servers in the correct order, and the search domain** | **3** |
| **`connection.autoconnect yes`** | **2** |
| **Hostname is persistent (`/etc/hostname` contains it)** | **3** |
| `/etc/hosts` entry resolves server2 | 3 |

**Editing `/etc/resolv.conf` directly scores zero for the DNS part** — NetworkManager regenerates it. **`hostname server1` scores zero for the hostname part** — it is runtime only.

---

## Task 15 — Firewall (15 points)

```bash
sudo systemctl enable --now firewalld

sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="192.168.56.0/24" service name="http" accept'

sudo firewall-cmd --permanent --add-port=8090/tcp

sudo firewall-cmd --reload
```

**Verification:**

```bash
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --list-all
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
sudo firewall-cmd --list-rich-rules
sudo firewall-cmd --permanent --list-services      # ssh must still be there
systemctl is-enabled firewalld
```

**From server2:**

```bash
curl -m5 http://192.168.56.11                      # should work
```

| Criterion | Points |
| --- | --- |
| `firewalld` running and enabled | 3 |
| **HTTP permitted from 192.168.56.0/24 via a rich rule** | **5** |
| **Other sources are rejected — i.e. `http` was NOT added as a plain service** | **3** |
| Port 8090/tcp open | 2 |
| **The configuration is permanent — the runtime/permanent diff is empty** | **2** |

**Adding `--add-service=http` as well as the rich rule fails the "only from that network" requirement**, because the plain service allows everyone. **The rich rule alone is the answer.**

---

## Task 16 — SELinux and Apache (25 points)

```bash
sudo dnf install -y httpd policycoreutils-python-utils

# 1. SELinux mode
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
getenforce

# 2. Content
sudo mkdir -p /web/html
echo 'Practice Exam 1' | sudo tee /web/html/index.html

# 3. Apache configuration
sudo vim /etc/httpd/conf/httpd.conf
```

```text
DocumentRoot "/web/html"

<Directory "/web/html">
    AllowOverride None
    Require all granted
</Directory>
```

```bash
sudo httpd -t                              # syntax check

# 4. SELinux labels — the two-command pattern
sudo semanage fcontext -a -t httpd_sys_content_t "/web/html(/.*)?"
sudo restorecon -Rv /web/html
ls -Zd /web/html
ls -Z /web/html/index.html

# 5. Service and firewall
sudo systemctl enable --now httpd
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

curl http://localhost
sudo ausearch -m AVC -ts recent
```

**Verification:**

```bash
getenforce
grep ^SELINUX= /etc/selinux/config
ls -Zd /web/html
sudo semanage fcontext -l -C
systemctl is-enabled httpd
curl http://localhost
ssh server2 'curl -s http://192.168.56.11'
sudo ausearch -m AVC -ts recent            # <no matches>
sudo reboot
curl http://localhost
```

| Criterion | Points |
| --- | --- |
| **SELinux enforcing, now and in `/etc/selinux/config`** | **4** |
| `DocumentRoot` changed to `/web/html` | 4 |
| The page exists with the correct content | 2 |
| **`semanage fcontext -a` recorded — verifiable with `-l -C`** | **6** |
| **`restorecon` applied — `ls -Z` shows `httpd_sys_content_t`** | **4** |
| httpd enabled and serving | 3 |
| **Retrievable from server2 (firewall)** | **2** |

**`chcon` instead of `semanage fcontext` scores 4 of the 10 labelling points.** It works right now and does not survive a relabel, which is exactly what the objective is testing.

**A common trap:** the rich rule from task 15 permits HTTP from 192.168.56.0/24, so server2 can reach it. **If you added the rich rule and then also needed `--add-service=http` here, re-read task 15** — the rich rule already covers it, and adding the plain service breaks task 15's requirement.

---

## Task 17 — Shell script (20 points)

```bash
sudo tee /usr/local/bin/userinfo.sh >/dev/null <<'EOF'
#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 USERNAME" >&2
    exit 1
fi

USERNAME="$1"

if ! id "$USERNAME" &>/dev/null; then
    echo "Error: user $USERNAME does not exist" >&2
    exit 2
fi

echo "USER: $USERNAME"
echo "UID: $(id -u "$USERNAME")"
echo "GROUPS: $(id -nG "$USERNAME" | tr ' ' ',')"

exit 0
EOF

sudo chmod +x /usr/local/bin/userinfo.sh
bash -n /usr/local/bin/userinfo.sh
```

**Verification:**

```bash
ls -l /usr/local/bin/userinfo.sh           # look for x

/usr/local/bin/userinfo.sh
echo "exit: $?"                            # expect 1

/usr/local/bin/userinfo.sh a b
echo "exit: $?"                            # expect 1

/usr/local/bin/userinfo.sh nosuchuser
echo "exit: $?"                            # expect 2

/usr/local/bin/userinfo.sh natasha
echo "exit: $?"                            # expect 0

/usr/local/bin/userinfo.sh natasha 2>/dev/null    # errors go to stderr
```

```text
USER: natasha
UID: 3001
GROUPS: sysadmins,wheel
```

| Criterion | Points |
| --- | --- |
| **The script is executable (`chmod +x`)** | **4** |
| Correct path and shebang | 2 |
| **Argument count check, exit 1, message on stderr** | **4** |
| **Nonexistent user check, exit 2, message on stderr** | **4** |
| Correct output format for a valid user | 4 |
| Exit 0 on success | 2 |

**Zero for the whole task without `chmod +x`.** The grader runs `/usr/local/bin/userinfo.sh alice`, not `bash userinfo.sh alice`.

**`>&2` on the error messages is worth 2 of the 8 error-handling points** and is easy to forget.

---

## Task 18 — Container as a service (25 points)

```bash
sudo dnf install -y container-tools
sudo podman pull registry.access.redhat.com/ubi9/httpd-24

sudo mkdir -p /srv/container-web
echo 'Container Exam 1' | sudo tee /srv/container-web/index.html
sudo semanage fcontext -a -t container_file_t "/srv/container-web(/.*)?"
sudo restorecon -Rv /srv/container-web

# Test by hand first
sudo podman run -d --name webapp -p 8080:8080 \
  -v /srv/container-web:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24
curl http://localhost:8080
sudo podman logs webapp

# Hand it to systemd
cd /etc/systemd/system
sudo podman generate systemd --new --name webapp --files
sudo systemctl daemon-reload
sudo podman rm -f webapp
sudo systemctl enable --now container-webapp
systemctl status container-webapp

# Firewall
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

**Or with Quadlet:**

```bash
sudo tee /etc/containers/systemd/webapp.container >/dev/null <<'EOF'
[Unit]
Description=Exam 1 web container
After=network-online.target
Wants=network-online.target

[Container]
Image=registry.access.redhat.com/ubi9/httpd-24
ContainerName=webapp
PublishPort=8080:8080
Volume=/srv/container-web:/var/www/html:Z

[Service]
Restart=always

[Install]
WantedBy=multi-user.target default.target
EOF

sudo systemctl daemon-reload
sudo systemctl start webapp
```

**Verification:**

```bash
systemctl is-enabled container-webapp      # or: systemctl status webapp
sudo podman ps
sudo podman port webapp
curl http://localhost:8080
ssh server2 'curl -s http://192.168.56.11:8080'
sudo firewall-cmd --permanent --list-ports
ls -Zd /srv/container-web
sudo reboot
# WITHOUT starting anything by hand:
sudo podman ps
curl http://localhost:8080
```

| Criterion | Points |
| --- | --- |
| The image is present **in root's store** | 3 |
| The content directory exists with the right file | 2 |
| **Bind mount with `:Z` or a `container_file_t` label** | **4** |
| Port 8080 published | 3 |
| **A systemd unit exists** | **5** |
| **It is enabled (or has `[Install] WantedBy=` for Quadlet) and starts at boot** | **6** |
| **Reachable from server2 — firewall permanent** | **2** |

**The reboot is the whole test.** If the container is not running after a reboot without you starting it, take 0 for the last 11 points regardless of how good the unit file looks.

**Common losses:** pulling the image as your user and running the unit as root; forgetting `:Z`; a Quadlet file with no `[Install]` section; forgetting the firewall port.

---

## Scoring

```text
Task  1  Root password                15  ____
Task  2  Local repository             15  ____
Task  3  Users and groups             20  ____
Task  4  sudo                         10  ____
Task  5  Collaborative directory      20  ____
Task  6  Find and copy                10  ____
Task  7  Services and target          10  ____
Task  8  Scheduled task               15  ____
Task  9  Partition and filesystem     20  ____
Task 10  Logical volumes              25  ____
Task 11  Extend the LV                20  ____
Task 12  Swap                         15  ____
Task 13  NFS and autofs               25  ____
Task 14  Network                      15  ____
Task 15  Firewall                     15  ____
Task 16  SELinux and Apache           25  ____
Task 17  Shell script                 20  ____
Task 18  Container service            25  ____
                                     ────
                              TOTAL   300  ____

                              PASS = 210
```

**Grade after a reboot, and grade honestly.** A task that needed you to type `systemctl start` after the reboot scores zero for its persistence points.

---

## Reviewing your result

| Score | Reading |
| --- | --- |
| **270+** | Comfortably ready. Move to Practice Exam 2 for the harder material |
| **210-269** | Passing, with no margin. Identify which domains lost points and redo those files |
| **150-209** | Close. The gap is usually persistence, not knowledge — review `Persistence.md` and `Pitfalls.md` |
| **Under 150** | Go back through the numbered files for the domains you scored lowest in |

**Then do the more valuable analysis: for every point you lost, decide which category it was in.**

| Category | What to do about it |
| --- | --- |
| **I did not know how** | Re-read the relevant numbered file and redo its tasks |
| **I knew, and I forgot a step** | **`Pitfalls.md` and `Flashcards.md`. This is the biggest category and the easiest to fix** |
| **I knew, and it did not persist** | **`Persistence.md`. Reboot more often while working** |
| **I ran out of time** | Practise the storage block until it takes 40 minutes, not 70 |
| **I misread the task** | Re-read each task after finishing it, before moving on |

**The second category is where most people's missing 40 points live.** They are not knowledge gaps; they are `enable --now` instead of `start`, `--permanent` without `--reload`, `lvextend` without `-r`, and `usermod -G` instead of `-aG`.

**Restore your snapshots and do this exam again in a week.** A second run should take half the time. If it does not, the problem is not knowledge.
