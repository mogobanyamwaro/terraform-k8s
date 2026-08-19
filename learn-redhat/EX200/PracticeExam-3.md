# Practice Exam 3

**20 tasks. 3 hours. 300 points. Pass mark 210 (70%).**

The closest of the three to the real exam in feel: a full spread across every objective, tasks phrased the way Red Hat phrases them, and no artificial sabotage. **Do this one last, ideally two or three days before your exam date.**

The wording here is deliberately terse. Real exam tasks do not explain themselves, do not tell you which commands to use, and do not say "remember to make this persistent". **Working out what is being asked for is part of the exercise.**

---

## Before you start

**Environment:**

| Host | Address | Root password |
| --- | --- | --- |
| **server1** | 192.168.56.11 | `redhat` |
| **server2** | 192.168.56.12 | `redhat` |

**server1 must have two unused disks.** `/dev/sdb` and `/dev/sdc`, 5 GiB each.

**Snapshot both machines.**

**Rules:**

1. **Three hours. Timer on. Stop when it goes off.**
2. **No internet, no notes.** `man`, `info`, `/usr/share/doc` only.
3. **All work must survive a reboot.** Grading is after one.
4. **Unless a task says otherwise, work on server1.**
5. **Read every task before touching anything.**

**Suggested opening:**

```bash
hostnamectl ; ip -brief addr ; lsblk ; getenforce
df -h ; free -h ; systemctl --failed
sudo firewall-cmd --list-all
```

---

## The tasks

### Task 1 (15 points)

Set the root password on **server1** to `redhat` by interrupting the boot process. Do not use an existing privileged session.

---

### Task 2 (10 points)

Configure `dnf` on **server1** to install packages from the installation media, mounted at `/mnt/repo`. Both `BaseOS` and `AppStream` must be available. The configuration must survive a reboot.

---

### Task 3 (20 points)

On **server1**, create the following, exactly:

| Item | Detail |
| --- | --- |
| Group `engineering` | GID `9000` |
| Group `contractors` | Any GID |
| User `andrew` | UID `4001`, primary group `engineering`, secondary `wheel` |
| User `susan` | UID `4002`, primary group `engineering` |
| User `temp01` | Primary group `contractors`, account expires `2027-06-30` |

All passwords: `RedHat123`. `andrew` and `susan` must change their password at first login. All three must have a maximum password age of 30 days.

---

### Task 4 (10 points)

On **server1**, members of `engineering` must be able to use `sudo` for all commands. Members of `contractors` must not be able to use `sudo` at all.

---

### Task 5 (20 points)

On **server1**, create `/srv/engineering` such that:

- It belongs to the `engineering` group.
- Files created in it belong to `engineering`.
- Group members may read and write each other's files.
- Only a file's owner may delete it.
- No access for anyone outside the group.

---

### Task 6 (15 points)

On **server1**:

- Create `/root/bigfiles.txt` listing the full path of every file under `/usr` larger than 20 MiB.
- Create `/root/nologin.txt` listing every username on the system whose login shell is `/sbin/nologin`, one per line, sorted.
- Create a compressed archive `/root/etc-backup.tar.gz` of `/etc`, preserving SELinux contexts.

---

### Task 7 (15 points)

On **server1**:

- The default boot target must be text mode.
- Add the kernel argument `audit=1` so that it applies to every installed kernel and persists across reboots.
- The GRUB menu must wait **10 seconds** before booting.

---

### Task 8 (15 points)

On **server1**, configure time services:

- The timezone must be `Africa/Nairobi`.
- The system must synchronise its clock with **server2**.
- The service must be running and start at boot.

---

### Task 9 (25 points)

On **server1**, build this storage layout on the unused disks:

- Volume group `vgapp`, physical extent size **8 MiB**.
- Logical volume `lvapp`, **exactly 100 extents**, xfs, mounted at `/app`.
- Logical volume `lvcache`, **1 GiB**, ext4, mounted at `/cache` with the `noexec` option.
- Both mounts must use **UUIDs** in `/etc/fstab`.

---

### Task 10 (20 points)

On **server1**:

- Extend `/app` so that the filesystem is **at least 2 GiB**.
- Add **768 MiB** of swap on a logical volume in `vgapp`, active at boot.

---

### Task 11 (20 points)

On **server2**, export `/export/shared` read-write to the `192.168.56.0/24` network. Ensure it is available after a reboot and through the firewall.

On **server1**, configure `autofs` so that `/data/shared` mounts it automatically on access, read-write, unmounting after 90 idle seconds. Do not use `/etc/fstab`.

---

### Task 12 (15 points)

On **server1**:

- Static address `192.168.56.11/24`, gateway `192.168.56.1`.
- DNS: `192.168.56.1`.
- Search domain `lab.example.com`.
- Hostname `server1.lab.example.com`.
- `server2.lab.example.com` must resolve to `192.168.56.12` without a DNS server.
- The connection must activate at boot.

---

### Task 13 (20 points)

On **server1**, configure the firewall so that:

- `firewalld` is running and enabled.
- HTTP and HTTPS are permitted from anywhere.
- Port `9200/tcp` is permitted **only** from `192.168.56.12`.
- All ICMP echo requests are blocked.
- SSH remains available.

---

### Task 14 (25 points)

On **server1**, deploy a web server:

- SELinux must be enforcing.
- `DocumentRoot` must be `/srv/website`.
- `/srv/website/index.html` must contain `Exam 3 website`.
- Apache must listen on the default port **and** on port `8888/tcp`.
- The site must be retrievable from **server2** on both ports.
- Apache must start at boot.

---

### Task 15 (15 points)

On **server1**, configure Apache so that the user `andrew` can publish a page at `http://server1/~andrew/`. Create `/home/andrew/public_html/index.html` containing `andrew page`. It must work with SELinux enforcing.

---

### Task 16 (15 points)

On **server1**:

- Make the systemd journal persistent across reboots.
- Limit the journal to **500 MiB**.
- Write every message of priority `warning` or worse from the **previous** boot to `/root/prev-warnings.txt`.

---

### Task 17 (15 points)

On **server1**, schedule a job that runs as the user `susan` at **23:45 every Friday**, executing `/bin/date`. Use cron.

---

### Task 18 (20 points)

On **server1**, create an executable script `/usr/local/bin/diskcheck.sh` that:

- Accepts an optional single argument, a percentage threshold, defaulting to **75**.
- Exits with status `2` and a message on stderr if the argument is not a positive integer.
- For each mounted local filesystem above the threshold, prints `WARN <mountpoint> <percent>`.
- Prints nothing for filesystems at or below the threshold.
- Exits `1` if any filesystem exceeded the threshold, `0` otherwise.

---

### Task 19 (25 points)

On **server1**, deploy a container:

- Image `registry.access.redhat.com/ubi9/httpd-24`.
- Container name `appweb`.
- Content served from `/srv/appdata`, containing `index.html` with the text `Exam 3 container`.
- Published on host port `8082`.
- Must start automatically at boot as a systemd service.
- Must be retrievable from **server2** at `http://192.168.56.11:8082`.

---

### Task 20 (10 points)

On **server1**:

- Set the `tuned` profile to `virtual-guest`.
- Ensure the `kdump` service is **disabled** and cannot be started.
- Set `vm.swappiness` to `20`, persistently.

---

## Stop here

**Reboot both machines. Verify everything with no manual intervention. Only then read on.**

---
---

# Solutions and Grading

---

## Task 1 (15 points)

```text
1. Reboot; at GRUB press  e
2. Append  rd.break  to the linux line
3. Ctrl-x
4. mount -o remount,rw /sysroot
5. chroot /sysroot
6. passwd root
7. touch /.autorelabel
8. exit
9. exit
```

```bash
ls -Z /etc/shadow
getenforce
```

| Criterion | Points |
| --- | --- |
| Root login works | 10 |
| **`/etc/shadow` correctly labelled, SELinux enforcing** | **5** |

---

## Task 2 (10 points)

```bash
sudo mkdir -p /mnt/repo
echo "/dev/sr0  /mnt/repo  iso9660  ro,nofail  0 0" | sudo tee -a /etc/fstab
sudo findmnt --verify && sudo mount -a

sudo tee /etc/yum.repos.d/media.repo >/dev/null <<'EOF'
[media-baseos]
name=Media BaseOS
baseurl=file:///mnt/repo/BaseOS
enabled=1
gpgcheck=0

[media-appstream]
name=Media AppStream
baseurl=file:///mnt/repo/AppStream
enabled=1
gpgcheck=0
EOF

sudo dnf clean all
dnf repolist
```

| Criterion | Points |
| --- | --- |
| Both repositories in `dnf repolist` | 5 |
| **The mount is in `/etc/fstab`** | **3** |
| A package installs | 2 |

---

## Task 3 (20 points)

```bash
sudo groupadd -g 9000 engineering
sudo groupadd contractors

sudo useradd -u 4001 -g engineering -G wheel andrew
sudo useradd -u 4002 -g engineering susan
sudo useradd -g contractors temp01

for u in andrew susan temp01; do
    echo 'RedHat123' | sudo passwd --stdin "$u"
    sudo chage -M 30 "$u"
done

sudo chage -d 0 andrew
sudo chage -d 0 susan
sudo chage -E 2027-06-30 temp01
```

**Verification:**

```bash
getent group engineering contractors
id andrew ; id susan ; id temp01
for u in andrew susan temp01; do echo "== $u"; sudo chage -l "$u"; done
```

| Criterion | Points |
| --- | --- |
| Groups exist, `engineering` GID 9000 | 3 |
| Correct UIDs for andrew and susan | 4 |
| Correct primary groups | 4 |
| andrew in `wheel` | 2 |
| Passwords set | 2 |
| **`-M 30` on all three** | **3** |
| **`chage -d 0` on andrew and susan; `-E` on temp01** | **2** |

---

## Task 4 (10 points)

```bash
sudo visudo -f /etc/sudoers.d/engineering
```

```text
%engineering  ALL=(ALL)  ALL
```

```bash
sudo visudo -c
sudo -l -U andrew
sudo -l -U temp01
```

**Verification:**

```bash
sudo -l -U andrew                          # (ALL) ALL
sudo -l -U temp01                          # "not allowed to run sudo"
grep -r contractors /etc/sudoers /etc/sudoers.d/    # nothing
```

| Criterion | Points |
| --- | --- |
| `engineering` members have full sudo | 5 |
| **`contractors` members have none** | **3** |
| `visudo -c` passes | 2 |

**The second requirement is satisfied by doing nothing** — no rule means no sudo. **Do not add a `!ALL` rule; it is unnecessary and easy to get wrong.**

---

## Task 5 (20 points)

```bash
sudo mkdir -p /srv/engineering
sudo chown root:engineering /srv/engineering
sudo chmod 3770 /srv/engineering
sudo setfacl -m  g:engineering:rwx /srv/engineering
sudo setfacl -m d:g:engineering:rwx /srv/engineering
ls -ld /srv/engineering
```

**Verification:**

```bash
ls -ld /srv/engineering                    # drwxrws--T+
sudo -u andrew touch /srv/engineering/a.txt
sudo -u susan bash -c 'echo x >> /srv/engineering/a.txt'   # must WORK
sudo -u susan rm -f /srv/engineering/a.txt                 # must FAIL
sudo -u temp01 ls /srv/engineering                         # must FAIL
ls -l /srv/engineering/
```

| Criterion | Points |
| --- | --- |
| **SGID — files get the `engineering` group** | **5** |
| Group members can create and read | 3 |
| **Members can modify each other's files** | **5** |
| **Sticky bit — only the owner may delete** | **5** |
| No access for others | 2 |

---

## Task 6 (15 points)

```bash
sudo find /usr -type f -size +20M > /root/bigfiles.txt

awk -F: '$7=="/sbin/nologin" {print $1}' /etc/passwd | sort > /root/nologin.txt

sudo tar --xattrs --selinux -czf /root/etc-backup.tar.gz /etc
```

**Verification:**

```bash
wc -l /root/bigfiles.txt ; head -3 /root/bigfiles.txt
cat /root/nologin.txt
ls -lh /root/etc-backup.tar.gz
tar -tzf /root/etc-backup.tar.gz | head -5
```

| Criterion | Points |
| --- | --- |
| `/root/bigfiles.txt` uses `-size +20M` | 5 |
| `/root/nologin.txt` is correct and sorted | 5 |
| **The archive was created with `--selinux` (or `--xattrs`)** | **5** |

**A plain `tar -czf` scores 2 of 5 for the archive.** The task specified preserving contexts, which needs the flag.

---

## Task 7 (15 points)

```bash
sudo systemctl set-default multi-user.target

sudo grubby --update-kernel=ALL --args="audit=1"
sudo sed -i 's/^GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 audit=1"/' /etc/default/grub

sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

**Verification:**

```bash
systemctl get-default
sudo grubby --info=ALL | grep args
grep -E 'GRUB_TIMEOUT|GRUB_CMDLINE' /etc/default/grub
sudo reboot
cat /proc/cmdline | grep audit=1
systemctl get-default
```

| Criterion | Points |
| --- | --- |
| Default target is `multi-user.target` | 5 |
| **`audit=1` present in `/proc/cmdline` after a reboot** | **6** |
| **`GRUB_TIMEOUT=10` and `grub2-mkconfig` was run** | **4** |

**Editing `/etc/default/grub` without running `grub2-mkconfig` scores 0 for the timeout.** The generated file is what GRUB reads.

---

## Task 8 (15 points)

```bash
sudo timedatectl set-timezone Africa/Nairobi

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
timedatectl
```

**Verification:**

```bash
timedatectl                                # Time zone: Africa/Nairobi
grep -E '^(server|pool)' /etc/chrony.conf
chronyc sources
systemctl is-enabled chronyd
```

| Criterion | Points |
| --- | --- |
| Timezone is `Africa/Nairobi` | 5 |
| **`/etc/chrony.conf` names server2** | **5** |
| **`chronyd` enabled and active** | **5** |

**`iburst` is not graded but include it** — without it the first synchronisation takes minutes and your `chronyc sources` check looks like a failure.

---

## Task 9 (25 points)

```bash
sudo fdisk /dev/sdb              # g, n, ⏎, ⏎, +4G, t, lvm, w
sudo partprobe /dev/sdb

sudo pvcreate /dev/sdb1
sudo vgcreate -s 8M vgapp /dev/sdb1
sudo vgdisplay vgapp | grep 'PE Size'

sudo lvcreate -n lvapp -l 100 vgapp                   # 100 × 8 MiB = 800 MiB
sudo mkfs.xfs /dev/vgapp/lvapp
sudo mkdir -p /app
echo "UUID=$(sudo blkid -s UUID -o value /dev/vgapp/lvapp)  /app  xfs  defaults  0 0" \
  | sudo tee -a /etc/fstab

sudo lvcreate -n lvcache -L 1G vgapp
sudo mkfs.ext4 /dev/vgapp/lvcache
sudo mkdir -p /cache
echo "UUID=$(sudo blkid -s UUID -o value /dev/vgapp/lvcache)  /cache  ext4  defaults,noexec  0 0" \
  | sudo tee -a /etc/fstab

sudo findmnt --verify
sudo mount -a
df -hT /app /cache
findmnt /cache -o OPTIONS
```

**Verification:**

```bash
sudo vgdisplay vgapp | grep 'PE Size'      # 8.00 MiB
sudo lvdisplay /dev/vgapp/lvapp | grep 'Current LE'    # 100
df -hT /app /cache
findmnt /cache -o OPTIONS                  # noexec present
grep -E '/app|/cache' /etc/fstab           # UUID= on both
sudo reboot
df -hT /app /cache
```

| Criterion | Points |
| --- | --- |
| **`vgapp` with an 8 MiB PE size** | **5** |
| **`lvapp` is exactly 100 extents (`-l 100`)** | **6** |
| xfs on `/app`, ext4 on `/cache` | 4 |
| **`/cache` mounted with `noexec`** | **4** |
| **Both fstab entries use `UUID=`** | **3** |
| Both mounted after a reboot | 3 |

---

## Task 10 (20 points)

```bash
sudo vgs vgapp
sudo fdisk /dev/sdc              # g, n, ⏎, ⏎, +3G, t, lvm, w
sudo partprobe /dev/sdc
sudo pvcreate /dev/sdc1
sudo vgextend vgapp /dev/sdc1

sudo lvextend -r -L 2G /dev/vgapp/lvapp
df -h /app

sudo lvcreate -n lvswap -L 768M vgapp
sudo mkswap /dev/vgapp/lvswap
sudo swapon /dev/vgapp/lvswap
echo "/dev/vgapp/lvswap  none  swap  defaults  0 0" | sudo tee -a /etc/fstab
sudo swapoff -a && sudo swapon -a
swapon --show
```

**Verification:**

```bash
df -h /app                                 # at least 2 GiB
swapon --show                              # lvswap present
grep swap /etc/fstab
sudo reboot
df -h /app ; swapon --show
```

| Criterion | Points |
| --- | --- |
| The volume group was extended | 4 |
| **`df` shows `/app` at 2 GiB or more** | **7** |
| 768 MiB swap LV created and active | 5 |
| **In `/etc/fstab` and active after a reboot** | **4** |

**`lvextend` without `-r` scores 0 of the 7.** The task is about the filesystem size, and `df` is what proves it.

**Note the device path rather than a UUID for swap.** `mkswap` generates a new UUID each run, so an LVM device path is more robust — and both are accepted.

---

## Task 11 (20 points)

**server2:**

```bash
sudo dnf install -y nfs-utils
sudo mkdir -p /export/shared
echo "shared" | sudo tee /export/shared/sharedfile
sudo chmod 777 /export/shared
echo "/export/shared  192.168.56.0/24(rw,sync)" | sudo tee -a /etc/exports
sudo exportfs -rav
sudo systemctl enable --now nfs-server
sudo firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
sudo firewall-cmd --reload
```

**server1:**

```bash
sudo dnf install -y nfs-utils autofs
showmount -e server2

echo "/data  /etc/auto.data  --timeout=90" | sudo tee /etc/auto.master.d/data.autofs
echo "shared  -rw,sync  server2:/export/shared" | sudo tee /etc/auto.data

sudo systemctl enable --now autofs
sudo systemctl restart autofs
ls /data/shared
findmnt /data/shared
```

**Verification:**

```bash
cat /etc/auto.master.d/data.autofs /etc/auto.data
systemctl is-enabled autofs
ls /data/shared
touch /data/shared/t && rm /data/shared/t
grep -c /data /etc/fstab                   # must be 0
sudo reboot
ls /data/shared
```

| Criterion | Points |
| --- | --- |
| server2 export correct, `nfs-server` enabled, firewall open | 7 |
| **The autofs master entry with `--timeout=90`** | **5** |
| The map entry is correct and read-write | 5 |
| **`autofs` enabled; mounts on access after a reboot; no fstab entry** | **3** |

---

## Task 12 (15 points)

```bash
sudo nmcli con mod ens160 \
  ipv4.method manual \
  ipv4.addresses 192.168.56.11/24 \
  ipv4.gateway 192.168.56.1 \
  ipv4.dns 192.168.56.1 \
  ipv4.dns-search lab.example.com \
  connection.autoconnect yes
sudo nmcli con up ens160

sudo hostnamectl set-hostname server1.lab.example.com
echo "192.168.56.12  server2.lab.example.com  server2" | sudo tee -a /etc/hosts
```

**Verification:**

```bash
ip -brief addr show ens160
nmcli -f NAME,AUTOCONNECT con show
cat /etc/resolv.conf
hostname -f ; cat /etc/hostname
getent hosts server2.lab.example.com
sudo reboot
hostname -f ; ip -brief addr
```

| Criterion | Points |
| --- | --- |
| Correct address and gateway | 4 |
| DNS server and search domain | 3 |
| **Autoconnect enabled** | **2** |
| **Hostname persistent** | **3** |
| `/etc/hosts` entry resolves | 3 |

---

## Task 13 (20 points)

```bash
sudo systemctl enable --now firewalld

sudo firewall-cmd --permanent --add-service={http,https}

sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="192.168.56.12/32" port port="9200" protocol="tcp" accept'

sudo firewall-cmd --permanent --add-icmp-block=echo-request

sudo firewall-cmd --reload
```

**Verification:**

```bash
sudo firewall-cmd --list-all
sudo firewall-cmd --list-rich-rules
sudo firewall-cmd --list-icmp-blocks
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
sudo firewall-cmd --permanent --list-services      # ssh present
ssh server2 'ping -c2 -W2 192.168.56.11'           # must FAIL
ssh server2 'nc -zv 192.168.56.11 9200'            # allowed from server2
```

| Criterion | Points |
| --- | --- |
| `firewalld` enabled and active | 3 |
| HTTP and HTTPS permitted | 4 |
| **9200/tcp restricted to 192.168.56.12 via a rich rule** | **6** |
| **ICMP echo requests blocked** | **4** |
| SSH remains available, everything permanent | 3 |

**Adding `--add-port=9200/tcp` as well as the rich rule opens it to everyone** and scores 0 of the 6 restriction points.

---

## Task 14 (25 points)

```bash
sudo dnf install -y httpd policycoreutils-python-utils

sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

sudo mkdir -p /srv/website
echo 'Exam 3 website' | sudo tee /srv/website/index.html

sudo vim /etc/httpd/conf/httpd.conf
```

```text
Listen 80
Listen 8888

DocumentRoot "/srv/website"

<Directory "/srv/website">
    AllowOverride None
    Require all granted
</Directory>
```

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/srv/website(/.*)?"
sudo restorecon -Rv /srv/website
ls -Zd /srv/website

sudo semanage port -a -t http_port_t -p tcp 8888

sudo httpd -t
sudo systemctl enable --now httpd
sudo systemctl restart httpd

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-port=8888/tcp
sudo firewall-cmd --reload

curl http://localhost
curl http://localhost:8888
sudo ausearch -m AVC -ts recent
```

**Verification:**

```bash
getenforce ; grep ^SELINUX= /etc/selinux/config
ss -tlnp | grep -E ':80|:8888'
ls -Zd /srv/website
sudo semanage fcontext -l -C
sudo semanage port -l | grep 8888
systemctl is-enabled httpd
ssh server2 'curl -s http://192.168.56.11 ; curl -s http://192.168.56.11:8888'
sudo reboot
curl http://localhost ; curl http://localhost:8888
```

| Criterion | Points |
| --- | --- |
| SELinux enforcing, now and persistently | 3 |
| `DocumentRoot` is `/srv/website` with a working `<Directory>` block | 4 |
| **`semanage fcontext` + `restorecon` on `/srv/website`** | **6** |
| **`semanage port -a` for 8888** | **5** |
| Apache listens on both ports and is enabled | 4 |
| **Both ports reachable from server2** | **3** |

**All three layers again: config, SELinux port label, firewall.** Missing the port label means httpd will not start at all; missing the firewall means it works locally and not from server2.

---

## Task 15 (15 points)

```bash
sudo vim /etc/httpd/conf.d/userdir.conf
```

```text
UserDir public_html
# ensure  UserDir disabled  is commented out
```

```bash
sudo mkdir -p /home/andrew/public_html
echo 'andrew page' | sudo tee /home/andrew/public_html/index.html
sudo chown -R andrew:engineering /home/andrew/public_html
sudo chmod 711 /home/andrew
sudo chmod 755 /home/andrew/public_html
sudo chmod 644 /home/andrew/public_html/index.html

sudo setsebool -P httpd_enable_homedirs on
sudo restorecon -Rv /home/andrew/public_html

sudo httpd -t
sudo systemctl restart httpd
curl http://localhost/~andrew/
```

**Verification:**

```bash
curl http://localhost/~andrew/
getsebool httpd_enable_homedirs            # on
sudo semanage boolean -l -C
namei -l /home/andrew/public_html/index.html
ls -Z /home/andrew/public_html/index.html
sudo ausearch -m AVC -ts recent
sudo reboot
curl http://localhost/~andrew/
```

| Criterion | Points |
| --- | --- |
| `UserDir public_html` configured | 4 |
| **`setsebool -P httpd_enable_homedirs on`** | **5** |
| **`/home/andrew` is traversable (mode 711 or 755)** | **4** |
| The page is returned | 2 |

**Without `-P` on the boolean it works until the reboot, and scores 0 of those 5.**

**Mode 711 on the home directory is the step people miss.** RHEL creates home directories at 700, and Apache cannot traverse them. `namei -l` shows the block immediately.

---

## Task 16 (15 points)

```bash
sudo mkdir -p /var/log/journal
sudo chown root:systemd-journal /var/log/journal
sudo chmod 2755 /var/log/journal

sudo vim /etc/systemd/journald.conf
```

```text
[Journal]
Storage=persistent
SystemMaxUse=500M
```

```bash
sudo systemctl restart systemd-journald
journalctl --list-boots
sudo reboot
```

**After the reboot — a previous boot now exists:**

```bash
journalctl --list-boots
sudo journalctl -b -1 -p warning > /root/prev-warnings.txt
wc -l /root/prev-warnings.txt
```

**Verification:**

```bash
ls -ld /var/log/journal
grep -E '^(Storage|SystemMaxUse)' /etc/systemd/journald.conf
journalctl --list-boots                    # more than one entry
journalctl --disk-usage
head -5 /root/prev-warnings.txt
```

| Criterion | Points |
| --- | --- |
| **`/var/log/journal` exists with correct ownership** | **5** |
| **More than one boot in `journalctl --list-boots`** | **5** |
| `SystemMaxUse=500M` | 2 |
| `/root/prev-warnings.txt` from the previous boot (`-b -1`) | 3 |

**The last part is impossible until you have rebooted at least once with persistence enabled** — which is the point. `journalctl -b -1` on a non-persistent journal returns "Data from the specified boot is not available".

---

## Task 17 (15 points)

```bash
sudo crontab -e -u susan
```

```text
45 23 * * 5 /bin/date
```

```bash
sudo systemctl enable --now crond
sudo crontab -l -u susan
```

**Verification:**

```bash
sudo crontab -l -u susan
systemctl is-enabled crond
sudo ls -l /var/spool/cron/susan
```

| Criterion | Points |
| --- | --- |
| **The schedule is `45 23 * * 5`** | **8** |
| **It runs as susan** | 4 |
| `crond` enabled | 3 |

**Friday is day 5.** Sunday is 0 (or 7). **And minute comes first — 23:45 is `45 23`.** Both inversions are common and both cost the full 8 points.

---

## Task 18 (20 points)

```bash
sudo tee /usr/local/bin/diskcheck.sh >/dev/null <<'EOF'
#!/bin/bash

THRESHOLD="${1:-75}"

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || (( THRESHOLD < 1 )); then
    echo "Error: threshold must be a positive integer" >&2
    exit 2
fi

exitcode=0

while read -r pct mount; do
    pct="${pct%\%}"
    if (( pct > THRESHOLD )); then
        echo "WARN $mount $pct"
        exitcode=1
    fi
done < <(df -P --output=pcent,target -x tmpfs -x devtmpfs | tail -n +2)

exit "$exitcode"
EOF

sudo chmod +x /usr/local/bin/diskcheck.sh
bash -n /usr/local/bin/diskcheck.sh
```

**Verification:**

```bash
ls -l /usr/local/bin/diskcheck.sh          # executable

/usr/local/bin/diskcheck.sh
echo "exit: $?"                            # 0 if nothing is over 75%

/usr/local/bin/diskcheck.sh 1
echo "exit: $?"                            # 1, with WARN lines

/usr/local/bin/diskcheck.sh abc
echo "exit: $?"                            # 2

/usr/local/bin/diskcheck.sh abc 2>/dev/null    # the message went to stderr
```

```text
WARN / 18
WARN /boot 24
exit: 1
```

| Criterion | Points |
| --- | --- |
| **Executable** | **3** |
| **Default of 75 when no argument (`${1:-75}`)** | **4** |
| **Validation, exit 2, message on stderr** | **5** |
| Correct `WARN <mount> <pct>` output format | 4 |
| Nothing printed for filesystems below the threshold | 2 |
| **Exit 1 if any exceeded, 0 otherwise** | **2** |

**A pipe into `while read` loses `exitcode`** and scores 0 of the last 2 points, because the loop ran in a subshell. **`< <(...)` is the fix.**

---

## Task 19 (25 points)

```bash
sudo dnf install -y container-tools
sudo podman pull registry.access.redhat.com/ubi9/httpd-24

sudo mkdir -p /srv/appdata
echo 'Exam 3 container' | sudo tee /srv/appdata/index.html
sudo semanage fcontext -a -t container_file_t "/srv/appdata(/.*)?"
sudo restorecon -Rv /srv/appdata

sudo podman run -d --name appweb -p 8082:8080 \
  -v /srv/appdata:/var/www/html:Z \
  registry.access.redhat.com/ubi9/httpd-24
curl http://localhost:8082

cd /etc/systemd/system
sudo podman generate systemd --new --name appweb --files
sudo systemctl daemon-reload
sudo podman rm -f appweb
sudo systemctl enable --now container-appweb
systemctl is-enabled container-appweb

sudo firewall-cmd --permanent --add-port=8082/tcp
sudo firewall-cmd --reload
```

**Or with Quadlet:**

```bash
sudo tee /etc/containers/systemd/appweb.container >/dev/null <<'EOF'
[Unit]
Description=Exam 3 container
After=network-online.target
Wants=network-online.target

[Container]
Image=registry.access.redhat.com/ubi9/httpd-24
ContainerName=appweb
PublishPort=8082:8080
Volume=/srv/appdata:/var/www/html:Z

[Service]
Restart=always

[Install]
WantedBy=multi-user.target default.target
EOF

sudo systemctl daemon-reload
sudo systemctl start appweb
```

**Verification:**

```bash
sudo podman ps
sudo podman port appweb
systemctl is-enabled container-appweb      # or: systemctl status appweb
curl http://localhost:8082
ssh server2 'curl -s http://192.168.56.11:8082'
ls -Zd /srv/appdata
sudo firewall-cmd --permanent --list-ports
sudo reboot
# starting NOTHING by hand:
sudo podman ps
curl http://localhost:8082
```

| Criterion | Points |
| --- | --- |
| Image in root's store, content directory correct | 4 |
| **Bind mount with `:Z` or `container_file_t`** | **4** |
| Published on host port 8082 | 3 |
| **A systemd unit exists** | **5** |
| **Enabled (or `[Install] WantedBy=`) and running after a reboot** | **7** |
| **Reachable from server2** | **2** |

---

## Task 20 (10 points)

```bash
sudo dnf install -y tuned
sudo systemctl enable --now tuned
sudo tuned-adm profile virtual-guest
tuned-adm active

sudo systemctl mask kdump
systemctl is-enabled kdump

echo 'vm.swappiness = 20' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl -p /etc/sysctl.d/99-swappiness.conf
sysctl vm.swappiness
```

**Verification:**

```bash
tuned-adm active
systemctl is-enabled kdump                 # masked
sudo systemctl start kdump                 # must refuse
cat /etc/sysctl.d/99-swappiness.conf
sysctl vm.swappiness
sudo reboot
tuned-adm active ; systemctl is-enabled kdump ; sysctl vm.swappiness
```

| Criterion | Points |
| --- | --- |
| tuned profile is `virtual-guest` | 3 |
| **`kdump` is `masked`, not merely disabled** | **4** |
| **`vm.swappiness=20` in `/etc/sysctl.d/` and active after a reboot** | **3** |

**"Cannot be started" means masked.** A disabled service still starts on request. **And `sysctl -w` alone scores 0 of the 3 swappiness points** — the file is the persistent form.

---

## Scoring

```text
Task  1  Root password              15  ____
Task  2  Local repository           10  ____
Task  3  Users and groups           20  ____
Task  4  sudo                       10  ____
Task  5  Collaborative directory    20  ____
Task  6  find, awk, tar             15  ____
Task  7  Boot target and GRUB       15  ____
Task  8  Time services              15  ____
Task  9  Storage layout             25  ____
Task 10  Extend and swap            20  ____
Task 11  NFS and autofs             20  ____
Task 12  Network                    15  ____
Task 13  Firewall                   20  ____
Task 14  Web server and SELinux     25  ____
Task 15  User directories           15  ____
Task 16  Persistent journal         15  ____
Task 17  cron                       15  ____
Task 18  Script                     20  ____
Task 19  Container service          25  ____
Task 20  tuned, mask, sysctl        10  ____
                                   ────
                            TOTAL   345  ____

                            PASS = 210 (61% of the available points)
```

---

## Reviewing your result

**Score by domain, not just in total** — the real exam is weighted and a single weak domain is a real risk:

```text
Essential tools        Tasks 2, 6                       25  ____ / 25
Users and groups       Tasks 3, 4, 5                    50  ____ / 50
Operate running        Tasks 1, 7, 16, 17, 20           65  ____ / 65
Deploy and maintain    Tasks 8, 2                       25  ____ / 25
Networking             Tasks 12, 13                     35  ____ / 35
Security (SELinux)     Tasks 14, 15                     40  ____ / 40
Storage                Tasks 9, 10, 11                  65  ____ / 65
Scripting              Task 18                          20  ____ / 20
Containers             Task 19                          25  ____ / 25
```

**A domain below 60% needs work before your exam date.** Go back to the numbered files for it and redo their tasks.

---

## The week before your exam

**If you scored 250 or more here, you are ready.** Do this and nothing more:

```text
Day -7   Practice Exam 3 again, from a clean snapshot. Target: under 2 hours.
Day -5   The break-and-fix drills in 36.md. All fifteen. Time each one.
Day -3   Re-read Persistence.md and Pitfalls.md. Do the drills you were slowest at.
Day -2   Flashcards.md, twice through. Practise the rd.break sequence three times.
Day -1   CheatSheet.md once. Nothing else. Sleep.
Day  0   Read CheatSheet.md in the morning. Nothing new.
```

**If you scored between 210 and 250**, add a full re-run of Practice Exam 2 and rework the domains you scored lowest in.

**If you scored below 210**, you have a specific gap rather than a general one. **Find it by category:**

| Where the points went | The fix |
| --- | --- |
| **Persistence** — it worked before the reboot | `Persistence.md`, and reboot after every block while practising |
| **Precision** — it worked but was not what was asked | Re-read each task after completing it. `Pitfalls.md` items 29-48 |
| **Speed** — you ran out of time | Practise the storage block alone until it takes 40 minutes |
| **Knowledge** — you did not know how | The numbered files for those domains |

**On the day itself, three habits carry the most weight:**

1. **`enable --now`, `--permanent` plus `--reload`, `lvextend -r`, `usermod -aG`.** Four flags that account for most lost marks.
2. **`findmnt --verify` and `mount -a` before every reboot.** The only mistake that can cost you everything.
3. **Reboot at the two-hour mark, not the last five minutes**, and verify without starting anything by hand. That is exactly what the grader does.

**Good luck.**
