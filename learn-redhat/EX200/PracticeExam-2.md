# Practice Exam 2

**20 tasks. 3 hours. 300 points. Pass mark 210 (70%).**

Harder than Practice Exam 1. More troubleshooting, more tasks where something is already broken, and more tasks with a subtlety that separates "it works" from "it is what was asked for".

**Do Practice Exam 1 first.** This one assumes you can already do the straightforward version of each objective and tests whether you can do it when the system is not clean.

---

## Before you start

**Environment.** Two machines, as in `Lab-Setup.md`:

| Host | Address | Role |
| --- | --- | --- |
| **server1** | 192.168.56.11 | Primary |
| **server2** | 192.168.56.12 | Secondary, for NFS and remote tests |

**server1 needs two unused disks.** `/dev/sdb` and `/dev/sdc`, 5 GiB each.

**Snapshot both machines.**

**Then run the pre-exam sabotage below on server1.** Several tasks depend on it — this exam starts with a system that is already partly wrong, which is realistic.

```bash
# ===== RUN THIS ON server1 BEFORE STARTING THE TIMER =====
sudo dnf install -y httpd nfs-utils >/dev/null 2>&1

# For task 1
sudo systemctl enable --now httpd
sudo sed -i 's|^DocumentRoot .*|DocumentRoot "/srv/www"|' /etc/httpd/conf/httpd.conf
sudo mkdir -p /srv/www
echo '<h1>Broken site</h1>' | sudo tee /srv/www/index.html >/dev/null
sudo systemctl restart httpd 2>/dev/null

# For task 2
sudo systemctl disable --now firewalld 2>/dev/null
sudo firewall-cmd --permanent --remove-service=ssh 2>/dev/null

# For task 3
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# For task 4
sudo useradd -m -s /sbin/nologin brokenuser 2>/dev/null
echo 'RedHat123' | sudo passwd --stdin brokenuser >/dev/null
sudo chage -E 2020-01-01 brokenuser
sudo usermod -L brokenuser

# For task 5
sudo mkdir -p /opt/legacy
sudo chmod 700 /opt/legacy
sudo chown root:root /opt/legacy
echo "legacy data" | sudo tee /opt/legacy/data.txt >/dev/null

echo "Sabotage complete. Reboot, then start your timer."
sudo reboot
```

**Rules:**

1. **Three hours. Timer on.**
2. **No internet. No notes from this repository.** `man` only.
3. **Everything must survive a reboot.**
4. **Root password is `redhat`.**
5. **Read every task first.**

---

## The tasks

### Task 1 — Diagnose a failed web server (20 points)

The web server on **server1** is not serving pages. It should serve the content in **`/srv/www`** on the default HTTP port.

Diagnose and repair it. When you are done:

- `curl http://localhost` must return the page.
- `curl http://192.168.56.11` from **server2** must return the page.
- Apache must start at boot.
- SELinux must remain in enforcing mode (see task 3).

**Do not** move the content back to `/var/www/html`.

---

### Task 2 — Restore firewall service (10 points)

On **server1**, the firewall is not running and its configuration has been altered.

- `firewalld` must be running and enabled at boot.
- SSH must be permitted from everywhere.
- The default zone must be `public`.

---

### Task 3 — Restore SELinux enforcement (10 points)

On **server1**, SELinux is not enforcing. Set it to **enforcing** mode, both immediately and permanently, without rebooting into a broken state.

Confirm there are no outstanding denials once everything else is working.

---

### Task 4 — Repair a user account (15 points)

On **server1**, the user `brokenuser` cannot log in. Repair the account so that:

- `brokenuser` can log in with a bash shell.
- The password is `RedHat123`.
- The account does not expire.
- The password must be changed at the next login.

---

### Task 5 — Grant access without changing ownership (15 points)

On **server1**, the directory `/opt/legacy` is owned by `root:root` with mode `700` and must **keep** that owner, group, and mode.

The user `brokenuser` must be able to read `/opt/legacy/data.txt` and list the directory, but not write to it.

---

### Task 6 — Users, groups, and password policy (20 points)

On **server1**:

- Create groups `ops` (GID 7000) and `qa`.
- Create users:

| User | Primary group | Secondary | Shell | Notes |
| --- | --- | --- | --- | --- |
| `paul` | `ops` | `qa`, `wheel` | `/bin/bash` | |
| `mary` | `ops` | `qa` | `/bin/bash` | |
| `svcbot` | `ops` | — | `/sbin/nologin` | **System account, no home directory** |

- Passwords for `paul` and `mary`: `RedHat123`.
- **All existing regular users** (UID 1000 and above, excluding `nobody`) must have a maximum password age of **90 days** and a minimum of **2 days**.
- Any user created **in future** must default to a maximum password age of **90 days**.

---

### Task 7 — Restricted sudo (15 points)

On **server1**:

- Members of `ops` may run `/usr/bin/systemctl` with any arguments, and `/usr/bin/dnf`, as root. **They are prompted for a password.**
- Members of `qa` may run **only** `/usr/bin/systemctl status` — any other systemctl subcommand must be refused — **without a password prompt**.
- Neither group may run anything else.

---

### Task 8 — Storage: partition, LVM, and swap in one layout (30 points)

On **server1**, on the unused disks, build exactly this:

- A volume group `vgdata` with a **32 MiB** physical extent size.
- A logical volume `lvfiles` of **exactly 640 MiB**, formatted **xfs**, mounted persistently at `/files`.
- A logical volume `lvlogs` using **50% of the free space** in `vgdata` at creation time, formatted **ext4**, mounted persistently at `/logs` with the **`noexec`** and **`nosuid`** options.
- **1 GiB** of additional swap, on a logical volume named `lvswap` in `vgdata`.

All of it must be present and active after a reboot.

---

### Task 9 — Extend under pressure (20 points)

On **server1**, `/files` must be grown to **at least 1.5 GiB**.

The volume group does not have enough free space. Add capacity and grow the filesystem.

**Then**, separately: shrink `/logs` to **300 MiB**. If this is not possible with the filesystem you chose, explain in `/root/shrink-notes.txt` why not and what you would do instead.

---

### Task 10 — Recover a broken fstab (15 points)

On **server1**, run this and then repair the system:

```bash
echo "UUID=deadbeef-0000-0000-0000-000000000000  /recovery  ext4  defaults  0 2" \
  | sudo tee -a /etc/fstab
sudo reboot
```

Recover the system to a normal boot. Then **re-add an entry for a directory `/recovery`** that is backed by a real 200 MiB logical volume in `vgdata`, mounted persistently, formatted ext4.

---

### Task 11 — NFS server with restrictions (20 points)

On **server2**:

- Export `/export/public` **read-only** to everyone.
- Export `/export/private` **read-write** to **server1 only** (192.168.56.11).
- Remote root accessing `/export/private` must be mapped to an unprivileged user.
- Both exports must survive a reboot and be reachable through the firewall.

On **server1**:

- Mount `server2:/export/public` persistently at `/mnt/public` using `/etc/fstab`, in a way that **does not prevent the system booting** if server2 is unavailable.

---

### Task 12 — autofs with a wildcard map (20 points)

On **server2**, create `/export/home/paul` and `/export/home/mary`, each containing a file named after the user, and export `/export/home` read-write to 192.168.56.0/24.

On **server1**, configure `autofs` so that:

- `/nethome/paul` automatically mounts `server2:/export/home/paul`.
- `/nethome/mary` automatically mounts `server2:/export/home/mary`.
- **A single map entry must handle any username**, not one entry per user.
- Mounts must be read-write and unmount after 120 idle seconds.

---

### Task 13 — Networking with a second address (15 points)

On **server1**:

- Keep the existing address 192.168.56.11/24 with gateway 192.168.56.1.
- **Add** a second IPv4 address **10.10.10.11/24** to the same connection, without removing the first.
- Add an IPv6 address **2001:db8:1::11/64**.
- DNS must be **192.168.56.1**, then **1.1.1.1**.
- The connection must activate at boot.

---

### Task 14 — Firewall with zones (20 points)

On **server1**:

- Traffic from **10.10.10.0/24** must be placed in the **trusted** zone.
- In the default zone, **HTTPS** must be permitted from everywhere.
- Traffic from **192.168.56.99** must be **dropped** — not rejected.
- Incoming connections to port **9090/tcp** must be forwarded to port **8080/tcp** on the same host.
- All of this must survive a reboot, and SSH must remain reachable from 192.168.56.12.

---

### Task 15 — SELinux booleans and ports (20 points)

On **server1**:

- Configure Apache to **additionally** listen on port **8404/tcp** while keeping port 80.
- Apache must be able to serve users' `~/public_html` directories. Create `/home/paul/public_html/index.html` containing `paul page` and confirm that `curl http://localhost/~paul/` returns it.
- Apache must be permitted to make outbound network connections.
- All of this must survive a reboot with SELinux enforcing.

---

### Task 16 — Persistent journal and log analysis (15 points)

On **server1**:

- Configure the systemd journal to be **persistent across reboots**.
- Create `/root/boot-errors.txt` containing every message of priority **error or worse** from the **current** boot.
- Configure the journal to use no more than **200 MiB** of disk.

---

### Task 17 — systemd timer (20 points)

On **server1**, create a scheduled job using a **systemd timer**, not cron:

- A script `/usr/local/bin/logcount.sh` that writes the current date and the number of lines in `/var/log/messages` to `/var/log/logcount.log`.
- It must run every day at **03:15**.
- If the machine was off at 03:15, it must run when the machine next starts.
- The timer must be active after a reboot.

---

### Task 18 — Script with loops and file input (20 points)

On **server1**, create an executable script `/usr/local/bin/groupreport.sh` that:

- Takes **one or more** group names as arguments.
- For each group, prints one line per member in the form `GROUP:USERNAME`, including users whose **primary** group it is.
- Prints `GROUP:NONE` if a group exists but has no members.
- Prints `GROUP:NOTFOUND` to **stderr** and continues if a group does not exist.
- Exits **0** if every named group existed, **1** if any did not.

---

### Task 19 — Rootless container service (25 points)

On **server1**, as the user **paul**:

- Run a container named `paulweb` from `registry.access.redhat.com/ubi9/httpd-24`.
- It must serve content from `/home/paul/webroot`, containing an `index.html` with the text `paul container`.
- It must publish on host port **8081**.
- It must start automatically at boot **without paul logging in**.
- The page must be retrievable from **server2** at `http://192.168.56.11:8081`.

**It must be rootless.** A rootful container scores zero.

---

### Task 20 — Final verification (10 points)

Reboot **both** machines. Then, **without starting or mounting anything by hand**, confirm and record in `/root/final-check.txt`:

- The output of `systemctl --failed`
- The output of `findmnt --verify`
- The output of `getenforce`
- The output of `sudo firewall-cmd --list-all`
- The output of `df -hT` and `swapon --show`

Any failure visible in that file costs points on the task that caused it, as well as here.

---

## Stop here

**Reboot both machines and verify before reading on.**

---
---

# Solutions and Grading

---

## Task 1 — Failed web server (20 points)

**The diagnosis matters more than the fix.**

```bash
systemctl status httpd
sudo journalctl -xeu httpd | tail -20
curl -I http://localhost
```

**Two separate faults were introduced. Work through them:**

```bash
ls -Zd /srv/www
```

```text
system_u:object_r:var_t:s0  /srv/www
```

**Wrong label — `/srv` content is `var_t` by default, not web content.**

```bash
sudo ausearch -m AVC -ts recent
```

**Fix the label properly:**

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/srv/www(/.*)?"
sudo restorecon -Rv /srv/www
ls -Zd /srv/www
```

**And Apache needs a `<Directory>` block for the new root:**

```bash
sudo vim /etc/httpd/conf/httpd.conf
```

```text
DocumentRoot "/srv/www"

<Directory "/srv/www">
    AllowOverride None
    Require all granted
</Directory>
```

```bash
sudo httpd -t
sudo systemctl enable --now httpd
sudo systemctl restart httpd
curl http://localhost
```

**Then the firewall (task 2 restores firewalld; this needs the service opened):**

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
ssh server2 'curl -s http://192.168.56.11'
```

**Verification:**

```bash
curl http://localhost
systemctl is-enabled httpd
ls -Zd /srv/www
sudo semanage fcontext -l -C
sudo ausearch -m AVC -ts recent            # <no matches>
```

| Criterion | Points |
| --- | --- |
| **The SELinux label is correct via `semanage fcontext` + `restorecon`** | **8** |
| The `<Directory>` block permits access | 4 |
| httpd running and enabled | 4 |
| **Reachable from server2** | **4** |

**`chcon` scores 4 of the 8 labelling points.** Setting SELinux to permissive to make it work scores **zero for this task and zero for task 3.**

---

## Task 2 — Firewall service (10 points)

```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --set-default-zone=public
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

**Verification:**

```bash
systemctl is-enabled firewalld
systemctl is-active firewalld
sudo firewall-cmd --permanent --list-services      # ssh present
sudo firewall-cmd --get-default-zone
ssh server2 'ssh -o BatchMode=yes 192.168.56.11 hostname' 2>&1 | head -2
```

| Criterion | Points |
| --- | --- |
| `firewalld` enabled and active | 4 |
| **SSH permitted, permanently** | **4** |
| Default zone is `public` | 2 |

---

## Task 3 — SELinux enforcing (10 points)

```bash
getenforce
grep ^SELINUX= /etc/selinux/config
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
getenforce
sudo ausearch -m AVC -ts recent
```

**Verification:**

```bash
getenforce                                 # Enforcing
grep ^SELINUX= /etc/selinux/config         # SELINUX=enforcing
sestatus
sudo reboot
getenforce
sudo ausearch -m AVC -ts boot
```

| Criterion | Points |
| --- | --- |
| `getenforce` returns `Enforcing` | 4 |
| **`/etc/selinux/config` has `SELINUX=enforcing`** | **4** |
| No outstanding AVC denials once everything else works | 2 |

**Only one of the two commands scores 4 of 10.** The mode and its persistence are separate requirements.

**Note:** because the system was `permissive` rather than `disabled`, labelling continued to happen, so no relabel is needed. **From `disabled` you would need `touch /.autorelabel` and a reboot.**

---

## Task 4 — Repair the account (15 points)

```bash
sudo passwd -S brokenuser
sudo chage -l brokenuser
getent passwd brokenuser
```

```text
brokenuser LK 2026-08-18 0 99999 7 -1
Account expires : Jan 01, 2020
brokenuser:x:1004:1004::/home/brokenuser:/sbin/nologin
```

**Three faults: locked password, expired account, no shell.**

```bash
sudo usermod -U brokenuser
sudo usermod -s /bin/bash brokenuser
sudo chage -E -1 brokenuser
echo 'RedHat123' | sudo passwd --stdin brokenuser
sudo chage -d 0 brokenuser
```

**Verification:**

```bash
sudo passwd -S brokenuser                  # PS, not LK
sudo chage -l brokenuser
getent passwd brokenuser
su - brokenuser                            # must demand a password change
```

| Criterion | Points |
| --- | --- |
| **Password unlocked** | **4** |
| **Shell is `/bin/bash`** | **4** |
| **Account expiry removed** | **4** |
| `chage -d 0` set | 3 |

**All three faults must be found.** Fixing two of three and concluding it works is the common failure — `passwd -S` and `chage -l` show everything in two commands.

---

## Task 5 — Access without changing ownership (15 points)

**The mode must stay `700` and the owner `root:root`, so `chmod` and `chown` are both off the table. An ACL is the only answer.**

```bash
sudo setfacl -m u:brokenuser:rx /opt/legacy
sudo setfacl -m u:brokenuser:r  /opt/legacy/data.txt
```

**Verification:**

```bash
ls -ld /opt/legacy
getfacl /opt/legacy
getfacl /opt/legacy/data.txt
sudo -u brokenuser ls /opt/legacy                        # works
sudo -u brokenuser cat /opt/legacy/data.txt              # works
sudo -u brokenuser touch /opt/legacy/x                   # must FAIL
```

```text
drwx------+ 2 root root 24 /opt/legacy
             └─ the + means an ACL, and the mode is still 700
```

| Criterion | Points |
| --- | --- |
| **The owner, group, and mode are unchanged** | **5** |
| brokenuser can list the directory (`x` and `r` via ACL) | 4 |
| brokenuser can read the file | 4 |
| **brokenuser cannot write** | **2** |

**Zero for the first 5 points if you used `chmod 755`** — it grants the access and violates the stated constraint.

**Note `rx` on the directory, not `rwx`.** `x` is needed to enter it; `r` to list it; `w` would allow creation.

---

## Task 6 — Users and password policy (20 points)

```bash
sudo groupadd -g 7000 ops
sudo groupadd qa

sudo useradd -g ops -G qa,wheel -s /bin/bash paul
sudo useradd -g ops -G qa -s /bin/bash mary
sudo useradd -r -M -g ops -s /sbin/nologin svcbot

echo 'RedHat123' | sudo passwd --stdin paul
echo 'RedHat123' | sudo passwd --stdin mary

# Existing users
for u in $(awk -F: '$3>=1000 && $3<60000 {print $1}' /etc/passwd); do
    sudo chage -M 90 -m 2 "$u"
done

# Future users
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
grep ^PASS_MAX_DAYS /etc/login.defs
```

**Verification:**

```bash
getent group ops qa
id paul ; id mary ; id svcbot
getent passwd svcbot                       # UID below 1000, no home
ls /home/                                  # no svcbot directory
for u in $(awk -F: '$3>=1000 && $3<60000 {print $1}' /etc/passwd); do
    printf '%-12s ' "$u"; sudo chage -l "$u" | grep -i maximum
done
grep ^PASS_MAX_DAYS /etc/login.defs
sudo useradd -m tmptest && sudo chage -l tmptest | grep -i maximum
sudo userdel -r tmptest
```

| Criterion | Points |
| --- | --- |
| Both groups, `ops` with GID 7000 | 3 |
| `paul` and `mary` with correct groups and shells | 4 |
| **`svcbot` is a system account with no home directory (`-r -M`)** | **4** |
| Passwords set | 2 |
| **Every existing regular user has `-M 90 -m 2`** | **4** |
| **`/etc/login.defs` sets `PASS_MAX_DAYS 90` for future users** | **3** |

**"All existing users" and "any user created in future" are two different mechanisms**, and doing only one scores half. `chage` does not affect future accounts; `login.defs` does not affect existing ones.

---

## Task 7 — Restricted sudo (15 points)

```bash
sudo visudo -f /etc/sudoers.d/exam2
```

```text
%ops  ALL=(root)  /usr/bin/systemctl, /usr/bin/dnf
%qa   ALL=(root)  NOPASSWD: /usr/bin/systemctl status *
```

```bash
sudo visudo -c
sudo -l -U paul
sudo -l -U mary
```

**Verification:**

```bash
sudo -l -U paul
sudo -l -U mary
su - mary -c 'sudo systemctl status sshd'        # works, no password
su - mary -c 'sudo systemctl restart sshd'       # must be REFUSED
su - paul -c 'sudo -n systemctl restart sshd'    # -n: fails, needs a password
```

```text
User mary may run the following commands on server1:
    (root) NOPASSWD: /usr/bin/systemctl status *
```

| Criterion | Points |
| --- | --- |
| `ops` may run systemctl and dnf, **with** a password | 5 |
| **`qa` may run only `systemctl status`** | **5** |
| **`qa` is `NOPASSWD`** | **3** |
| `visudo -c` passes and a drop-in was used | 2 |

**`%qa ALL=(root) NOPASSWD: /usr/bin/systemctl` would allow every subcommand** and scores 0 of the 5 restriction points. The argument pattern is the point of the task.

**A caveat worth knowing and worth writing down if a task asks about security:** command-argument restrictions in sudo are not a strong boundary — `systemctl status` can invoke a pager, and a pager can spawn a shell. It satisfies the task; it is not real containment.

---

## Task 8 — Storage layout (30 points)

```bash
lsblk

# Partition for the VG
sudo fdisk /dev/sdb              # g, n, ⏎, ⏎, +4G, t, lvm, w
sudo partprobe /dev/sdb

sudo pvcreate /dev/sdb1
sudo vgcreate -s 32M vgdata /dev/sdb1
sudo vgdisplay vgdata | grep 'PE Size'

# 640 MiB = 20 extents of 32 MiB
sudo lvcreate -n lvfiles -L 640M vgdata
sudo mkfs.xfs /dev/vgdata/lvfiles
sudo mkdir -p /files
echo "UUID=$(sudo blkid -s UUID -o value /dev/vgdata/lvfiles)  /files  xfs  defaults  0 0" \
  | sudo tee -a /etc/fstab

# 50% of the free space AT THIS POINT
sudo vgs vgdata
sudo lvcreate -n lvlogs -l 50%FREE vgdata
sudo mkfs.ext4 /dev/vgdata/lvlogs
sudo mkdir -p /logs
echo "UUID=$(sudo blkid -s UUID -o value /dev/vgdata/lvlogs)  /logs  ext4  defaults,noexec,nosuid  0 0" \
  | sudo tee -a /etc/fstab

# Swap
sudo lvcreate -n lvswap -L 1G vgdata
sudo mkswap /dev/vgdata/lvswap
sudo swapon /dev/vgdata/lvswap
echo "/dev/vgdata/lvswap  none  swap  defaults  0 0" | sudo tee -a /etc/fstab

sudo findmnt --verify
sudo mount -a
sudo swapoff -a && sudo swapon -a
df -hT /files /logs
swapon --show
```

**Verification:**

```bash
sudo vgdisplay vgdata | grep 'PE Size'
sudo lvs vgdata
findmnt /files ; findmnt /logs
findmnt /logs -o OPTIONS
swapon --show
sudo reboot
df -hT /files /logs ; swapon --show
```

| Criterion | Points |
| --- | --- |
| **`vgdata` with a 32 MiB PE size** | **5** |
| `lvfiles` is 640 MiB, xfs, mounted at `/files` | 6 |
| `lvlogs` created with `-l 50%FREE`, ext4, mounted at `/logs` | 6 |
| **`/logs` mounted with `noexec,nosuid`** | **5** |
| `lvswap` is 1 GiB, `mkswap`, active | 5 |
| **Everything is in `/etc/fstab` and present after a reboot** | **3** |

**Order matters for `50%FREE`.** Creating `lvswap` before `lvlogs` changes what "50% of free space" means. **The task listed them in order; follow it.**

**`findmnt /logs -o OPTIONS` is how a grader checks the mount options** — the fstab line alone is not proof the mount actually took them.

---

## Task 9 — Extend and shrink (20 points)

**Extend `/files`:**

```bash
sudo vgs vgdata                            # not enough free space
sudo fdisk /dev/sdc                        # g, n, ⏎, ⏎, +3G, t, lvm, w
sudo partprobe /dev/sdc
sudo pvcreate /dev/sdc1
sudo vgextend vgdata /dev/sdc1
sudo vgs vgdata

sudo lvextend -r -L 1600M /dev/vgdata/lvfiles
df -h /files
```

**Shrink `/logs` — it is ext4, so it can be done:**

```bash
sudo umount /logs
sudo e2fsck -f /dev/vgdata/lvlogs
sudo resize2fs /dev/vgdata/lvlogs 300M
sudo lvreduce -L 300M /dev/vgdata/lvlogs
sudo mount -a
df -h /logs
```

**If you had made `/logs` xfs**, the answer is the note:

```bash
sudo tee /root/shrink-notes.txt >/dev/null <<'EOF'
/logs is an XFS filesystem. XFS cannot be shrunk by any tool; the only
supported route is to back up the data, recreate the filesystem at the
smaller size with mkfs.xfs, and restore. ext4 can be shrunk offline with
resize2fs followed by lvreduce.
EOF
```

**Verification:**

```bash
df -h /files                               # at least 1.5 GiB
df -h /logs                                # about 300 MiB
sudo lvs vgdata
sudo findmnt --verify
sudo reboot
df -hT /files /logs
```

| Criterion | Points |
| --- | --- |
| The volume group was extended with a new PV | 5 |
| **`df` shows `/files` at 1.5 GiB or more** | **7** |
| **`/logs` shrunk to ~300 MiB, filesystem first then `lvreduce`** | **6** |
| Both still mounted after a reboot | 2 |

**`lvreduce` before `resize2fs` destroys the filesystem.** If you did it in that order and had to recreate `/logs`, take 0 of the 6 shrink points.

**Full marks for the note instead of the shrink if you chose xfs for `/logs`** — but the task told you to use ext4, so choosing xfs was itself a misread.

---

## Task 10 — fstab recovery (15 points)

**The recovery:**

```text
1. Enter the root password at the emergency prompt
2. mount -o remount,rw /
3. vi /etc/fstab              → remove the bad line
4. systemctl daemon-reload
5. mount -a
6. findmnt --verify
7. reboot
```

**Then build the real thing:**

```bash
sudo lvcreate -n lvrecovery -L 200M vgdata
sudo mkfs.ext4 /dev/vgdata/lvrecovery
sudo mkdir -p /recovery
echo "UUID=$(sudo blkid -s UUID -o value /dev/vgdata/lvrecovery)  /recovery  ext4  defaults  0 2" \
  | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo mount -a
df -hT /recovery
```

**Verification:**

```bash
findmnt /recovery
df -hT /recovery
grep recovery /etc/fstab
sudo findmnt --verify
sudo reboot
findmnt /recovery
systemctl --failed
```

| Criterion | Points |
| --- | --- |
| **The system boots normally again** | **7** |
| A 200 MiB LV exists, ext4, mounted at `/recovery` | 5 |
| **Persistent and mounted after a reboot** | **3** |

**This is the drill that matters most.** If the recovery took more than ten minutes, redo drill 3 in `36-break-and-fix-drill.md` until it is automatic. **On the real exam, this is a self-inflicted wound you will need to fix under time pressure.**

---

## Task 11 — NFS with restrictions (20 points)

**On server2:**

```bash
sudo dnf install -y nfs-utils
sudo mkdir -p /export/public /export/private
echo "public data"  | sudo tee /export/public/pubfile
echo "private data" | sudo tee /export/private/privfile
sudo chmod 755 /export/public
sudo chmod 777 /export/private

sudo tee -a /etc/exports >/dev/null <<'EOF'
/export/public   *(ro,sync)
/export/private  192.168.56.11(rw,sync,root_squash)
EOF

sudo exportfs -rav
sudo exportfs -v
sudo systemctl enable --now nfs-server
sudo firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
sudo firewall-cmd --reload
```

**On server1:**

```bash
sudo dnf install -y nfs-utils
showmount -e server2
sudo mkdir -p /mnt/public

echo "server2:/export/public  /mnt/public  nfs  defaults,_netdev,nofail  0 0" \
  | sudo tee -a /etc/fstab

sudo findmnt --verify
sudo mount -a
ls /mnt/public
```

**Verification:**

```bash
# server2
sudo exportfs -v
systemctl is-enabled nfs-server

# server1
findmnt /mnt/public
grep public /etc/fstab                     # _netdev AND nofail
sudo mount -t nfs server2:/export/private /mnt/tmp && sudo umount /mnt/tmp
sudo touch /mnt/public/x                   # must FAIL — read-only
```

**Test the resilience requirement:**

```bash
ssh server2 'sudo systemctl stop nfs-server'
sudo reboot                                # must still boot
ssh server2 'sudo systemctl start nfs-server'
sudo mount -a
```

| Criterion | Points |
| --- | --- |
| `/export/public` exported `ro` to everyone | 4 |
| **`/export/private` exported `rw` to 192.168.56.11 only** | **5** |
| **`root_squash` in effect (it is the default, so not removing it counts)** | **2** |
| `nfs-server` enabled, firewall open | 4 |
| **server1's fstab entry has `_netdev`** | **3** |
| **`nofail` — the system boots with server2 down** | **2** |

**`no_root_squash` anywhere in this task costs the 2 squash points.** The default is what was asked for, so the correct action is not to override it.

---

## Task 12 — autofs wildcard (20 points)

**On server2:**

```bash
sudo mkdir -p /export/home/paul /export/home/mary
echo "paul home" | sudo tee /export/home/paul/paulfile
echo "mary home" | sudo tee /export/home/mary/maryfile
sudo chmod -R 777 /export/home

echo "/export/home  192.168.56.0/24(rw,sync)" | sudo tee -a /etc/exports
sudo exportfs -rav
```

**On server1:**

```bash
sudo dnf install -y autofs

echo "/nethome  /etc/auto.nethome  --timeout=120" \
  | sudo tee /etc/auto.master.d/nethome.autofs

echo "*  -rw,sync  server2:/export/home/&" | sudo tee /etc/auto.nethome

sudo systemctl enable --now autofs
sudo systemctl restart autofs

ls /nethome/paul
ls /nethome/mary
findmnt | grep nethome
```

**Verification:**

```bash
cat /etc/auto.master.d/nethome.autofs
cat /etc/auto.nethome
systemctl is-enabled autofs
ls /nethome/paul ; cat /nethome/paul/paulfile
ls /nethome/mary
touch /nethome/paul/writetest && rm /nethome/paul/writetest
grep -c nethome /etc/fstab                 # must be 0
sudo reboot
ls /nethome/mary                           # mounts on access
```

| Criterion | Points |
| --- | --- |
| server2 exports `/export/home` correctly | 4 |
| **The map uses `*` and `&` — one entry, any username** | **7** |
| The master map entry with `--timeout=120` | 4 |
| `autofs` enabled and both paths mount read-write | 5 |

**Two explicit entries, one for paul and one for mary, score 0 of the 7 wildcard points** even though both paths work. The task specified a single entry.

**`&` expands to whatever key was requested**, so `*  -rw  server2:/export/home/&` maps `/nethome/anything` to `server2:/export/home/anything`. **That is how network home directories are done and it is a standard exam pattern.**

---

## Task 13 — Networking with a second address (15 points)

```bash
sudo nmcli con mod ens160 +ipv4.addresses 10.10.10.11/24
sudo nmcli con mod ens160 ipv4.dns "192.168.56.1 1.1.1.1"
sudo nmcli con mod ens160 ipv6.method manual ipv6.addresses 2001:db8:1::11/64
sudo nmcli con mod ens160 connection.autoconnect yes
sudo nmcli con up ens160

ip -brief addr show ens160
ip -6 addr show ens160
cat /etc/resolv.conf
```

**Verification:**

```bash
ip -brief addr show ens160
nmcli con show ens160 | grep -E 'ipv4.addresses|ipv4.dns|ipv6.addresses'
nmcli -f NAME,AUTOCONNECT con show
cat /etc/resolv.conf
sudo reboot
ip -brief addr show ens160                 # BOTH IPv4 addresses and the IPv6 one
```

```text
ens160  UP  192.168.56.11/24 10.10.10.11/24 2001:db8:1::11/64 fe80::.../64
```

| Criterion | Points |
| --- | --- |
| **The original address is still present** | **4** |
| **10.10.10.11/24 added with `+ipv4.addresses`** | **4** |
| IPv6 address configured with `ipv6.method manual` | 3 |
| DNS servers in the correct order | 2 |
| Autoconnect and all of it present after a reboot | 2 |

**`nmcli con mod ens160 ipv4.addresses 10.10.10.11/24` without the `+` replaces the original** and scores 0 of the first 4 points. **The plus sign is the whole task.**

---

## Task 14 — Firewall zones (20 points)

```bash
sudo firewall-cmd --permanent --zone=trusted --add-source=10.10.10.0/24

sudo firewall-cmd --permanent --add-service=https

sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="192.168.56.99" drop'

sudo firewall-cmd --permanent --add-forward-port=port=9090:proto=tcp:toport=8080
sudo firewall-cmd --permanent --add-masquerade

sudo firewall-cmd --reload
```

**Verification:**

```bash
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=trusted --list-all
sudo firewall-cmd --list-all
sudo firewall-cmd --list-rich-rules
sudo firewall-cmd --list-forward-ports
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
sudo firewall-cmd --permanent --list-services      # ssh still present
ssh server2 'ssh -o BatchMode=yes 192.168.56.11 hostname' 2>&1 | head -2
sudo reboot
sudo firewall-cmd --list-all
```

| Criterion | Points |
| --- | --- |
| 10.10.10.0/24 bound to the `trusted` zone | 5 |
| HTTPS permitted in the default zone | 3 |
| **192.168.56.99 is `drop`, not `reject`** | **5** |
| Port forwarding 9090 → 8080 | 4 |
| **Everything permanent, SSH still reachable** | **3** |

**`reject` instead of `drop` scores 0 of those 5 points.** They are different actions: `reject` replies with an ICMP error and the client fails immediately; `drop` discards silently and the client times out. **The task named one of them.**

---

## Task 15 — SELinux booleans and ports (20 points)

```bash
# 1. Additional listening port in Apache's config
sudo sed -i '/^Listen 80$/a Listen 8404' /etc/httpd/conf/httpd.conf
grep ^Listen /etc/httpd/conf/httpd.conf

# 2. The SELinux port label
sudo semanage port -l | grep http_port_t
sudo semanage port -a -t http_port_t -p tcp 8404

# 3. User directories in Apache
sudo vim /etc/httpd/conf.d/userdir.conf
```

```text
UserDir public_html
# comment out or remove:  UserDir disabled
```

```bash
# 4. The content, with correct permissions all the way down
sudo mkdir -p /home/paul/public_html
echo 'paul page' | sudo tee /home/paul/public_html/index.html
sudo chown -R paul:ops /home/paul/public_html
sudo chmod 711 /home/paul
sudo chmod 755 /home/paul/public_html
sudo chmod 644 /home/paul/public_html/index.html

# 5. The SELinux booleans
sudo setsebool -P httpd_enable_homedirs on
sudo setsebool -P httpd_can_network_connect on

# 6. Labels and restart
sudo restorecon -Rv /home/paul/public_html
sudo httpd -t
sudo systemctl restart httpd

# 7. Firewall for the new port
sudo firewall-cmd --permanent --add-port=8404/tcp
sudo firewall-cmd --reload

curl http://localhost/~paul/
curl http://localhost:8404
```

**Verification:**

```bash
ss -tlnp | grep -E '(:80|:8404)'
sudo semanage port -l | grep 8404
sudo semanage boolean -l -C
getsebool httpd_enable_homedirs httpd_can_network_connect
curl http://localhost/~paul/
ls -Z /home/paul/public_html/index.html
namei -l /home/paul/public_html/index.html
sudo ausearch -m AVC -ts recent
sudo reboot
curl http://localhost/~paul/ ; curl http://localhost:8404
```

| Criterion | Points |
| --- | --- |
| Apache listens on both 80 and 8404 | 4 |
| **`semanage port -a -t http_port_t -p tcp 8404`** | **5** |
| **`setsebool -P httpd_enable_homedirs on`** | **4** |
| **`setsebool -P httpd_can_network_connect on`** | **3** |
| `curl http://localhost/~paul/` returns the page | 3 |
| Firewall permits 8404 | 1 |

**Missing `-P` on either boolean costs its full points** — it works now and reverts at reboot, which is precisely what is being tested.

**A subtlety worth noting: `chmod 711 /home/paul` is required.** Apache must traverse the home directory to reach `public_html`, and RHEL creates home directories as `700`. `namei -l` shows the block if you miss it.

---

## Task 16 — Persistent journal (15 points)

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo chown root:systemd-journal /var/log/journal
sudo chmod 2755 /var/log/journal

sudo vim /etc/systemd/journald.conf
```

```text
[Journal]
Storage=persistent
SystemMaxUse=200M
```

```bash
sudo systemctl restart systemd-journald
journalctl --list-boots
journalctl --disk-usage

sudo journalctl -b -p err > /root/boot-errors.txt
cat /root/boot-errors.txt
```

**Verification:**

```bash
ls -ld /var/log/journal
grep -E '^(Storage|SystemMaxUse)' /etc/systemd/journald.conf
journalctl --disk-usage
ls -l /root/boot-errors.txt
sudo reboot
journalctl --list-boots                    # MORE THAN ONE boot listed
```

```text
IDX BOOT ID                          FIRST ENTRY                 LAST ENTRY
 -1 3f2a...                          Tue 2026-08-18 17:00:12     Tue 2026-08-18 19:44:01
  0 8b1c...                          Tue 2026-08-18 19:45:33     Tue 2026-08-18 19:52:10
```

| Criterion | Points |
| --- | --- |
| **`/var/log/journal` exists with the right ownership** | **5** |
| **`journalctl --list-boots` shows more than one boot after a reboot** | **5** |
| `/root/boot-errors.txt` contains the current boot's errors | 3 |
| `SystemMaxUse=200M` configured | 2 |

**Creating the directory is enough on its own** — journald detects it and switches to persistent storage on restart. Setting `Storage=persistent` as well is belt and braces and equally correct.

**The `--list-boots` check after a reboot is the only real proof.** Before the reboot, everything looks the same either way.

---

## Task 17 — systemd timer (20 points)

```bash
sudo tee /usr/local/bin/logcount.sh >/dev/null <<'EOF'
#!/bin/bash
COUNT=$(wc -l < /var/log/messages 2>/dev/null || echo 0)
echo "$(date '+%F %T') /var/log/messages lines: $COUNT" >> /var/log/logcount.log
EOF
sudo chmod +x /usr/local/bin/logcount.sh
sudo /usr/local/bin/logcount.sh
cat /var/log/logcount.log

sudo tee /etc/systemd/system/logcount.service >/dev/null <<'EOF'
[Unit]
Description=Count lines in /var/log/messages

[Service]
Type=oneshot
ExecStart=/usr/local/bin/logcount.sh
EOF

sudo tee /etc/systemd/system/logcount.timer >/dev/null <<'EOF'
[Unit]
Description=Run logcount daily at 03:15

[Timer]
OnCalendar=*-*-* 03:15:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now logcount.timer
systemctl list-timers | grep logcount
sudo systemctl start logcount.service
sudo journalctl -u logcount.service -n 10
```

**Verification:**

```bash
ls -l /usr/local/bin/logcount.sh           # executable
systemctl is-enabled logcount.timer        # enabled
systemctl is-active logcount.timer
systemctl list-timers --all | grep logcount
systemd-analyze calendar '*-*-* 03:15:00'
cat /var/log/logcount.log
sudo reboot
systemctl is-active logcount.timer
```

```text
NEXT                        LEFT     LAST  PASSED  UNIT
Wed 2026-08-19 03:15:00 EAT 7h left  n/a   n/a     logcount.timer
```

| Criterion | Points |
| --- | --- |
| **The script exists and is executable** | **4** |
| The `.service` unit is correct with `Type=oneshot` | 4 |
| **`OnCalendar=*-*-* 03:15:00`** | **5** |
| **`Persistent=true` — catches up on missed runs** | **4** |
| **The TIMER is enabled, not the service** | **3** |

**Enabling `logcount.service` instead of `logcount.timer` scores 0 of the last 3 points** and produces a job that runs once at boot rather than daily.

**Zero for the whole task if you used cron.** The task named systemd timers specifically.

---

## Task 18 — Group report script (20 points)

```bash
sudo tee /usr/local/bin/groupreport.sh >/dev/null <<'EOF'
#!/bin/bash

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 GROUP [GROUP...]" >&2
    exit 1
fi

exitcode=0

for group in "$@"; do
    if ! getent group "$group" >/dev/null; then
        echo "${group}:NOTFOUND" >&2
        exitcode=1
        continue
    fi

    gid=$(getent group "$group" | cut -d: -f3)

    # Secondary members, from /etc/group
    secondary=$(getent group "$group" | cut -d: -f4 | tr ',' '\n' | grep -v '^$')

    # Primary members, from /etc/passwd
    primary=$(awk -F: -v g="$gid" '$4==g {print $1}' /etc/passwd)

    members=$(printf '%s\n%s\n' "$secondary" "$primary" | grep -v '^$' | sort -u)

    if [[ -z "$members" ]]; then
        echo "${group}:NONE"
    else
        while read -r m; do
            echo "${group}:${m}"
        done <<< "$members"
    fi
done

exit "$exitcode"
EOF

sudo chmod +x /usr/local/bin/groupreport.sh
bash -n /usr/local/bin/groupreport.sh
```

**Verification:**

```bash
/usr/local/bin/groupreport.sh ops
/usr/local/bin/groupreport.sh qa ops
/usr/local/bin/groupreport.sh ops nosuchgroup
echo "exit: $?"                            # expect 1
/usr/local/bin/groupreport.sh ops nosuchgroup 2>/dev/null   # NOTFOUND is hidden
/usr/local/bin/groupreport.sh ops
echo "exit: $?"                            # expect 0
sudo groupadd emptygrp
/usr/local/bin/groupreport.sh emptygrp      # expect emptygrp:NONE
```

```text
ops:mary
ops:paul
ops:svcbot
```

| Criterion | Points |
| --- | --- |
| **Executable** | **3** |
| Handles multiple group arguments | 3 |
| **Includes users whose PRIMARY group it is** | **6** |
| `GROUP:NONE` for an empty group | 3 |
| **`GROUP:NOTFOUND` on stderr, and processing continues** | **3** |
| **Correct exit status: 0 all found, 1 any missing** | **2** |

**Reading only `/etc/group` misses primary members and scores 0 of those 6 points.** A user's primary group membership is field 4 of their `/etc/passwd` line, not a name in `/etc/group`. **`svcbot`, `paul`, and `mary` all have `ops` as their primary group, so `getent group ops` alone returns almost nothing.**

---

## Task 19 — Rootless container (25 points)

```bash
su - paul
```

```bash
mkdir -p ~/webroot
echo 'paul container' > ~/webroot/index.html

podman pull registry.access.redhat.com/ubi9/httpd-24
podman images

podman run -d --name paulweb -p 8081:8080 \
  -v ~/webroot:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24

podman ps
curl http://localhost:8081

mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --new --name paulweb --files
systemctl --user daemon-reload
podman rm -f paulweb
systemctl --user enable --now container-paulweb
systemctl --user status container-paulweb
curl http://localhost:8081
exit
```

```bash
sudo loginctl enable-linger paul
loginctl show-user paul | grep -i Linger

sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --reload
```

**Verification:**

```bash
su - paul -c 'podman ps'
su - paul -c 'systemctl --user is-enabled container-paulweb'
loginctl show-user paul | grep -i Linger
ls -l /var/lib/systemd/linger/
ls -l /home/paul/.config/systemd/user/
sudo podman ps                             # must be EMPTY — it is rootless
curl http://localhost:8081
ssh server2 'curl -s http://192.168.56.11:8081'
sudo reboot
```

**After the reboot, without logging in as paul:**

```bash
curl -s http://localhost:8081
sudo loginctl list-users
systemctl status user@$(id -u paul).service
ps -u paul | grep -c conmon
```

| Criterion | Points |
| --- | --- |
| **The container is rootless — it appears in `podman ps` as paul, not under sudo** | **5** |
| Image pulled into paul's store, content directory correct | 3 |
| **Bind mount with `:Z`** | **3** |
| Published on host port 8081 | 3 |
| A user systemd unit in `~/.config/systemd/user/`, enabled | 5 |
| **`loginctl enable-linger paul`** | **4** |
| **Reachable from server2 after a reboot, with nobody logged in** | **2** |

**A rootful container scores 0 for the whole task** — the requirement was explicit.

**Missing lingering costs 4 points directly and the final 2 as well**, because the container is not running after the reboot. **That is 6 of 25 for one forgotten command.**

---

## Task 20 — Final verification (10 points)

```bash
sudo tee /root/final-check.txt >/dev/null <<EOF
===== systemctl --failed =====
$(systemctl --failed --no-pager)

===== findmnt --verify =====
$(sudo findmnt --verify)

===== getenforce =====
$(getenforce)

===== firewall-cmd --list-all =====
$(sudo firewall-cmd --list-all)

===== df -hT =====
$(df -hT)

===== swapon --show =====
$(swapon --show)
EOF

cat /root/final-check.txt
```

| Criterion | Points |
| --- | --- |
| The file exists with all six sections | 4 |
| **`systemctl --failed` shows zero failed units** | **3** |
| **`findmnt --verify` reports success** | **2** |
| `getenforce` returns `Enforcing` | 1 |

**A failed unit or a broken fstab visible here costs points twice** — here, and on whichever task caused it. **That is the point of the task: your final state is graded, not your intentions.**

---

## Scoring

```text
Task  1  Failed web server           20  ____
Task  2  Firewall service            10  ____
Task  3  SELinux enforcing           10  ____
Task  4  Repair the account          15  ____
Task  5  Access without chown        15  ____
Task  6  Users and password policy   20  ____
Task  7  Restricted sudo             15  ____
Task  8  Storage layout              30  ____
Task  9  Extend and shrink           20  ____
Task 10  fstab recovery              15  ____
Task 11  NFS with restrictions       20  ____
Task 12  autofs wildcard             20  ____
Task 13  Second address              15  ____
Task 14  Firewall zones              20  ____
Task 15  SELinux booleans and ports  20  ____
Task 16  Persistent journal          15  ____
Task 17  systemd timer               20  ____
Task 18  Group report script         20  ____
Task 19  Rootless container          25  ____
Task 20  Final verification          10  ____
                                    ────
                             TOTAL   300  ____   (of 355 available)

                             PASS = 210
```

**Note the totals do not match.** There are 355 points on offer and the pass mark is 210 — deliberately, because the real exam has more available than you need and finishing everything is not the goal. **Passing is.**

---

## Reviewing your result

**This exam's tasks were designed around specific traps. Check which ones caught you:**

| Task | The trap |
| --- | --- |
| 1 | **`chcon` instead of `semanage fcontext`**, or setting permissive to make it work |
| 4 | **Finding two of the three faults** and stopping |
| 5 | **`chmod 755`** when the mode had to stay `700` |
| 6 | **Doing `chage` or `login.defs`, not both** |
| 7 | **Not restricting the systemctl subcommand** |
| 8 | **The wrong order for `50%FREE`**, or missing `noexec,nosuid` |
| 9 | **`lvreduce` before `resize2fs`** |
| 11 | **Missing `nofail`**, or adding `no_root_squash` |
| 12 | **Two entries instead of one wildcard** |
| 13 | **`ipv4.addresses` without the `+`** |
| 14 | **`reject` where `drop` was specified** |
| 15 | **`setsebool` without `-P`**, or `/home/paul` still at mode 700 |
| 17 | **Enabling the service instead of the timer** |
| 18 | **Reading only `/etc/group`** and missing primary members |
| 19 | **Forgetting `loginctl enable-linger`** |

**Every one of these is a case where the obvious answer works and is not what was asked.** That is the difference between this exam and Practice Exam 1, and it is the difference between 210 and 260 on the real one.

**Read the task twice. The specifics are the grading criteria.**

**Restore your snapshots and move on to Practice Exam 3**, which is closest to the real thing in feel and pacing.
