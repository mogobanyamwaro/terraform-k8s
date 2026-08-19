# EX200 Cheat Sheet

**Read this on the morning of the exam.** Everything here is a command you will type or a check you will run. No explanations — those are in the numbered files.

---

## The first five minutes

```bash
hostnamectl                          # who am I
ip -brief addr                       # what network do I have
lsblk                                # what disks exist
getenforce                           # SELinux mode
df -h; free -h                       # space and memory
sudo firewall-cmd --list-all         # firewall baseline
systemctl --failed                   # anything already broken
```

**Read every task first.** Note which ones need a spare disk, which need the second host, and which depend on each other. Storage tasks take longest — start them early.

---

## Persistence, in one table

| Action | Non-persistent | **Persistent** |
| --- | --- | --- |
| Service | `systemctl start X` | **`systemctl enable --now X`** |
| Default target | `systemctl isolate` | **`systemctl set-default`** |
| SELinux mode | `setenforce 1` | **`/etc/selinux/config`** |
| SELinux context | `chcon -t T path` | **`semanage fcontext -a -t T "path(/.*)?"` + `restorecon -Rv path`** |
| SELinux boolean | `setsebool X on` | **`setsebool -P X on`** |
| SELinux port | — | **`semanage port -a -t T -p tcp N`** |
| Firewall | `firewall-cmd --add-service=X` | **`firewall-cmd --permanent --add-service=X` + `--reload`** |
| IP address | `ip addr add` | **`nmcli con mod` + `nmcli con up`** |
| Hostname | `hostname X` | **`hostnamectl set-hostname X`** |
| Mount | `mount /dev/x /mnt` | **`/etc/fstab`** + `mount -a` |
| Swap | `swapon /dev/x` | **`/etc/fstab`** |
| Kernel parameter | `sysctl -w` | **`/etc/sysctl.d/99-x.conf`** |
| GRUB argument | `e` at the boot menu | **`/etc/default/grub` + `grub2-mkconfig`** |
| Container | `podman run -d` | **A systemd unit + `enable`** (+ **`enable-linger`** if rootless) |
| tuned profile | — | `tuned-adm profile X` (already persistent) |

**`systemctl is-enabled X` is the check that predicts the reboot. `is-active` only tells you about now.**

---

## Pre-reboot checklist

```bash
sudo findmnt --verify                # fstab is sane — DO THIS FIRST
sudo mount -a                        # every fstab entry mounts
sudo swapon -a && swapon --show      # swap activates
systemctl is-enabled <every service you touched>
sudo firewall-cmd --permanent --list-all
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
grep ^SELINUX= /etc/selinux/config
getenforce
nmcli -f NAME,AUTOCONNECT con show
systemctl get-default
sudo systemctl --failed
sudo journalctl -b -p err
```

**A bad `/etc/fstab` line is the only mistake that can cost you the whole exam.** `findmnt --verify` and `mount -a` before every reboot. Use `nofail` when in doubt.

---

## Users and groups

```bash
sudo useradd -u 1500 -g devs -G wheel,ops -c "Full Name" -s /bin/bash -m alice
sudo useradd -r -s /sbin/nologin svcacct        # system account, no login
sudo usermod -aG wheel alice                    # -aG APPEND. -G alone REPLACES
sudo usermod -L alice ; sudo usermod -U alice   # lock / unlock
sudo usermod -s /sbin/nologin alice             # deny shell
sudo userdel -r alice                           # -r removes the home directory
sudo groupadd -g 5000 devs
sudo groupmod -n newname oldname
sudo gpasswd -a alice devs ; sudo gpasswd -d alice devs
id alice ; groups alice ; getent passwd alice ; getent group devs
echo 'RedHat123' | sudo passwd --stdin alice
sudo passwd -e alice                            # expire now: change at next login
```

Aging:

```bash
sudo chage -m 7 -M 60 -W 7 -I 14 -E 2026-12-31 alice
sudo chage -l alice
sudo chage -d 0 alice                           # force change at next login
```

| `chage` | Meaning |
| --- | --- |
| `-m` | Minimum days between changes |
| `-M` | Maximum password age |
| `-W` | Warning days |
| `-I` | Inactive days after expiry |
| `-E` | Account expiry date |
| `-d 0` | Must change at next login |

Defaults for **new** users only: `/etc/login.defs`, `/etc/default/useradd`.

sudo:

```bash
sudo visudo -f /etc/sudoers.d/devs               # ALWAYS visudo — it syntax-checks
```

```text
%devs   ALL=(ALL)       ALL
%ops    ALL=(ALL)       NOPASSWD: ALL
alice   ALL=(ALL)       /usr/bin/systemctl restart httpd
```

```bash
sudo visudo -c                                   # verify syntax
sudo -l -U alice                                 # what can alice do
```

---

## Permissions

```bash
chmod 755 file ; chmod u+x,g-w,o= file ; chmod -R g+rwX dir
chown alice:devs file ; chown -R alice: dir ; chgrp devs file
umask 0027                                       # /etc/profile.d/umask.sh to persist
```

| Special bit | Numeric | Symbolic | Effect |
| --- | --- | --- | --- |
| SUID | **4**000 | `u+s` | Runs as the file's owner |
| SGID | **2**000 | `g+s` | **On a directory: new files inherit the group** |
| Sticky | **1**000 | `+t` | **Only the owner can delete** |

**Collaborative directory — the exam's favourite:**

```bash
sudo groupadd devs
sudo mkdir -p /shared/devs
sudo chgrp devs /shared/devs
sudo chmod 2770 /shared/devs                     # 2 = SGID
ls -ld /shared/devs                              # drwxrws--- 
```

ACLs:

```bash
sudo setfacl -m u:alice:rwx,g:devs:rx file
sudo setfacl -m d:u:alice:rwx dir                # DEFAULT ACL — inherited
sudo setfacl -R -m u:alice:rX dir
sudo setfacl -x u:alice file ; sudo setfacl -b file
getfacl file
```

**A `+` at the end of `ls -l` means an ACL is present.**

---

## Processes

```bash
ps aux ; ps -ef ; ps aux --sort=-%cpu | head ; ps aux --sort=-%mem | head
top ; uptime ; pidof httpd ; pgrep -u alice -a
kill -TERM PID ; kill -9 PID ; killall httpd ; pkill -u alice
nice -n 10 command ; sudo renice -n -5 -p PID
jobs ; bg ; fg %1 ; Ctrl-Z ; command &
```

---

## systemd

```bash
sudo systemctl enable --now httpd                # THE command
systemctl status/start/stop/restart/reload httpd
systemctl is-enabled httpd ; systemctl is-active httpd
sudo systemctl mask httpd ; sudo systemctl unmask httpd
systemctl list-units --type=service
systemctl list-unit-files --state=enabled
systemctl --failed
sudo systemctl daemon-reload                     # after ANY unit file change
sudo systemctl edit httpd                        # drop-in override
systemctl cat httpd ; systemctl show httpd -p Restart
```

Targets:

```bash
systemctl get-default
sudo systemctl set-default multi-user.target     # PERSISTENT
sudo systemctl isolate multi-user.target         # NOW, not persistent
sudo systemctl reboot / poweroff / halt
sudo shutdown -r +5 "message" ; sudo shutdown -c
```

Timers:

```bash
systemctl list-timers --all
sudo systemctl enable --now backup.timer         # enable the TIMER, not the service
```

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Nightly backup
[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
[Install]
WantedBy=timers.target
```

---

## Boot recovery

**Root password reset:**

1. Reboot, press **`e`** at the GRUB menu.
2. On the `linux` line, append **`rd.break`**.
3. **`Ctrl-x`** to boot.
4. Then:

```bash
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel                              # REQUIRED — SELinux relabel
exit
exit
```

**`touch /.autorelabel` is the step people forget.** Without it, `/etc/shadow` has the wrong label and the new password does not work.

**Reset when the filesystem is intact but you want a shell:** append `init=/bin/bash` instead of `rd.break` (then remount `/` rw and `chroot` is unnecessary).

**Emergency and rescue:**

```bash
systemd.unit=rescue.target                       # append at GRUB
systemd.unit=emergency.target
```

**GRUB, persistently:**

```bash
sudo vim /etc/default/grub                       # GRUB_CMDLINE_LINUX="... quiet"
sudo grub2-mkconfig -o /boot/grub2/grub.cfg      # BIOS and UEFI on RHEL 9/10
sudo grubby --update-kernel=ALL --args="quiet"
sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"
sudo grubby --default-kernel ; sudo grubby --info=ALL
sudo grub2-set-default 0
```

---

## Logs

```bash
journalctl -u httpd -n 50
journalctl -xeu httpd                            # WHY a unit failed
journalctl -f
journalctl -b ; journalctl -b -1 ; journalctl --list-boots
journalctl -p err ; journalctl -p warning..err
journalctl --since '2026-08-18 09:00' --until '10:00'
journalctl --since yesterday ; journalctl --since '1 hour ago'
journalctl _PID=1234 ; journalctl /usr/sbin/sshd ; journalctl -k
journalctl --disk-usage ; sudo journalctl --vacuum-time=2weeks
```

**Persistent journal — a stated objective:**

```bash
sudo mkdir -p /var/log/journal
sudo chown root:systemd-journal /var/log/journal
sudo chmod 2755 /var/log/journal
sudo systemctl restart systemd-journald
# or set Storage=persistent in /etc/systemd/journald.conf
journalctl --list-boots                          # more than one boot = it worked
```

Files: `/var/log/messages`, `/var/log/secure`, `/var/log/audit/audit.log`, `/var/log/boot.log`.

```bash
sudo rsyslogd -N1                                # syntax check after editing
```

---

## Scheduling

```bash
crontab -e ; crontab -l ; crontab -r
sudo crontab -e -u alice                         # another user's crontab
```

```text
# min hour dom mon dow  command
  30  2    *   *   *    /usr/local/bin/backup.sh
  */5 *    *   *   *    /usr/local/bin/check.sh
  0   9    *   *   1-5  /usr/local/bin/weekday.sh
```

System-wide files take a **user field**:

```text
# /etc/cron.d/mytask
30 2 * * *  root  /usr/local/bin/backup.sh
```

```bash
sudo systemctl enable --now crond
echo "/usr/local/bin/x.sh" | at 14:30 ; at now +5 min ; atq ; atrm 3
sudo systemctl enable --now atd
```

Access control: `/etc/cron.allow`, `/etc/cron.deny`, `/etc/at.allow`, `/etc/at.deny`.

---

## tuned, time, software

```bash
sudo dnf install -y tuned && sudo systemctl enable --now tuned
tuned-adm active ; tuned-adm list ; tuned-adm recommend
sudo tuned-adm profile virtual-guest
sudo tuned-adm off
```

```bash
timedatectl ; timedatectl list-timezones | grep -i nairobi
sudo timedatectl set-timezone Africa/Nairobi
sudo timedatectl set-ntp true
chronyc sources -v ; chronyc tracking ; chronyc sourcestats
sudo vim /etc/chrony.conf                        # server HOST iburst
sudo systemctl restart chronyd ; sudo systemctl enable --now chronyd
```

```bash
dnf install/remove/update/upgrade PKG
dnf search TERM ; dnf info PKG ; dnf provides */filename
dnf list installed ; dnf list available ; dnf repolist ; dnf repolist -v
dnf group list ; sudo dnf group install "Development Tools"
dnf history ; sudo dnf history undo LAST
sudo dnf module list ; sudo dnf module install nodejs:20
sudo dnf localinstall ./pkg.rpm
rpm -qa ; rpm -qi PKG ; rpm -ql PKG ; rpm -qf /path ; rpm -qc PKG ; rpm -qd PKG
rpm -qp --scripts pkg.rpm ; rpm -V PKG
```

**Adding a repository — persistent form is a file:**

```bash
sudo dnf config-manager --add-repo http://host/repo     # RHEL 9
sudo dnf config-manager addrepo --from-repofile=...     # RHEL 10 syntax
```

```ini
# /etc/yum.repos.d/local.repo
[local-baseos]
name=Local BaseOS
baseurl=file:///mnt/BaseOS
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
```

```bash
sudo dnf clean all ; dnf repolist
```

Flatpak:

```bash
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remotes ; flatpak remote-ls flathub
sudo flatpak install flathub org.gnome.Calculator   # system-wide
flatpak install --user flathub org.gnome.Calculator # this user only
flatpak list --app ; flatpak run org.gnome.Calculator
sudo flatpak update ; sudo flatpak uninstall org.gnome.Calculator
sudo flatpak uninstall --unused
```

---

## Networking

```bash
nmcli device status ; nmcli connection show ; nmcli con show NAME
ip -brief addr ; ip route ; ip -6 addr
```

**Create a static profile:**

```bash
sudo nmcli con add type ethernet con-name static-ens160 ifname ens160 \
  ipv4.method manual \
  ipv4.addresses 192.168.56.11/24 \
  ipv4.gateway 192.168.56.1 \
  ipv4.dns "192.168.56.1 8.8.8.8" \
  ipv4.dns-search example.com \
  autoconnect yes
sudo nmcli con up static-ens160
```

**Modify an existing one:**

```bash
sudo nmcli con mod ens160 ipv4.method manual ipv4.addresses 192.168.56.11/24
sudo nmcli con mod ens160 ipv4.gateway 192.168.56.1
sudo nmcli con mod ens160 ipv4.dns "8.8.8.8" ipv4.dns-search example.com
sudo nmcli con mod ens160 +ipv4.addresses 10.0.0.5/24          # ADD another
sudo nmcli con mod ens160 connection.autoconnect yes
sudo nmcli con up ens160                                       # APPLY
```

**`con mod` writes the file; `con up` applies it. Both are needed.**

IPv6:

```bash
sudo nmcli con mod ens160 ipv6.method manual \
  ipv6.addresses 2001:db8::11/64 ipv6.gateway 2001:db8::1
```

Keyfiles live in `/etc/NetworkManager/system-connections/`.

Hostname and resolution:

```bash
sudo hostnamectl set-hostname server1.lab.example.com
echo "192.168.56.12 server2.lab.example.com server2" | sudo tee -a /etc/hosts
getent hosts server2                            # uses /etc/hosts + DNS
dig +short server2.lab.example.com              # DNS ONLY
host server2 ; nslookup server2
cat /etc/resolv.conf                            # DO NOT EDIT — set via nmcli
cat /etc/nsswitch.conf | grep hosts
```

Firewalld:

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload                       # WITHOUT THIS, NOTHING HAPPENS
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --list-all
sudo firewall-cmd --get-default-zone ; --get-active-zones ; --get-services
sudo firewall-cmd --permanent --zone=trusted --add-source=192.168.56.0/24
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="192.168.56.0/24" service name="http" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="10.0.0.0/8" reject'
sudo firewall-cmd --runtime-to-permanent          # rescue an unsaved session
sudo firewall-cmd --permanent --add-forward-port=port=8080:proto=tcp:toport=80
sudo firewall-cmd --permanent --add-masquerade
sudo systemctl enable --now firewalld
```

**The pattern is always `--permanent` then `--reload`.** Verify with the diff:

```bash
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
```

---

## SELinux

```bash
getenforce ; sestatus ; sudo setenforce 1
sudo vim /etc/selinux/config                     # SELINUX=enforcing — PERSISTENT
ls -Z /path ; ps -Z ; id -Z ; sudo semanage port -l | grep http
```

**Context, persistently — the two-command pattern:**

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
sudo restorecon -Rv /web
```

**`chcon` is temporary; it is undone by the next `restorecon` or relabel.**

```bash
sudo restorecon -Rv /var/www/html                # restore defaults
sudo restorecon -RFv /var/www/html               # -F forces
sudo touch /.autorelabel && sudo reboot          # full relabel
matchpathcon /web ; sudo semanage fcontext -l -C # -C = local customisations
```

Booleans:

```bash
getsebool -a | grep httpd
sudo setsebool -P httpd_enable_homedirs on       # -P = PERSISTENT
sudo semanage boolean -l -C
```

Common ones: `httpd_enable_homedirs`, `httpd_can_network_connect`, `httpd_can_network_connect_db`, `ftpd_full_access`, `nfs_export_all_rw`, `samba_enable_home_dirs`, `use_nfs_home_dirs`.

Ports:

```bash
sudo semanage port -a -t http_port_t -p tcp 8090   # -a = add new
sudo semanage port -m -t http_port_t -p tcp 8090   # -m = modify existing
sudo semanage port -l | grep 8090
```

Denials:

```bash
sudo ausearch -m AVC -ts recent
sudo ausearch -m AVC,USER_AVC -ts today -i
sudo sealert -a /var/log/audit/audit.log         # needs setroubleshoot-server
sudo journalctl -t setroubleshoot
sudo audit2allow -a -w                           # explain
sudo audit2why -a
```

**The three-layer fix for a service on a non-standard port:**

```bash
# 1. The service's own config file
# 2. sudo semanage port -a -t http_port_t -p tcp 8090
# 3. sudo firewall-cmd --permanent --add-port=8090/tcp && sudo firewall-cmd --reload
```

---

## Storage

```bash
lsblk ; lsblk -f ; sudo blkid ; sudo fdisk -l ; sudo parted -l ; df -hT
```

**Partition:**

```bash
sudo fdisk /dev/sdb
#  g  = new GPT label      o = new MBR label
#  n  = new partition      p/l = print / list types
#  t  = change type        (lvm, swap, linux)
#  d  = delete             w = WRITE AND EXIT       q = QUIT WITHOUT SAVING
sudo partprobe /dev/sdb                          # make the kernel notice
```

**`q` is your escape hatch in `fdisk` — nothing is written until `w`.** `parted` writes immediately.

```bash
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary xfs 1MiB 1GiB
sudo parted /dev/sdb set 1 lvm on
sudo wipefs -a /dev/sdb1 ; sudo sgdisk --zap-all /dev/sdb
```

**LVM:**

```bash
sudo pvcreate /dev/sdb1 ; pvs ; sudo pvdisplay ; sudo pvremove /dev/sdb1
sudo vgcreate vg01 /dev/sdb1 ; vgs ; sudo vgdisplay vg01
sudo vgextend vg01 /dev/sdc1 ; sudo vgreduce vg01 /dev/sdc1 ; sudo vgremove vg01
sudo lvcreate -n lv_data -L 500M vg01
sudo lvcreate -n lv_data -l 100%FREE vg01
lvs ; sudo lvdisplay /dev/vg01/lv_data ; sudo lvremove /dev/vg01/lv_data
```

**Extend — the single most-asked storage task:**

```bash
sudo vgextend vg01 /dev/sdc1                     # only if the VG is full
sudo lvextend -r -L +400M /dev/vg01/lv_data      # -r resizes the FILESYSTEM too
sudo lvextend -r -l +100%FREE /dev/vg01/lv_data
```

**`-r` does the filesystem. Without it you have a bigger LV and the same size filesystem.**

Manually:

```bash
sudo xfs_growfs /data                            # MOUNT POINT, must be mounted
sudo resize2fs /dev/vg01/lv_data                 # DEVICE
```

**XFS cannot shrink. ext4 can (unmounted, `resize2fs` before `lvreduce`).**

**Filesystems and fstab:**

```bash
sudo mkfs.xfs /dev/sdb1 ; sudo mkfs.xfs -L mydata /dev/sdb1 ; sudo mkfs.xfs -f ...
sudo mkfs.ext4 -L mydata /dev/sdb1
sudo mkfs.vfat -n MYDATA /dev/sdb1
sudo xfs_admin -L newlabel /dev/sdb1 ; sudo e2label /dev/sdb1 newlabel
sudo mkdir -p /data
sudo blkid -s UUID -o value /dev/sdb1
```

```text
# /etc/fstab
UUID=xxxx-xxxx   /data   xfs   defaults        0 0
LABEL=mydata     /data   ext4  defaults        0 0
/dev/vg01/lv_x   /data   xfs   defaults        0 0
UUID=xxxx        none    swap  defaults        0 0
host:/export     /nfs    nfs   defaults,_netdev 0 0
/swapfile        none    swap  defaults        0 0
```

```bash
sudo findmnt --verify                            # VALIDATE BEFORE REBOOTING
sudo mount -a
findmnt /data ; df -hT /data
sudo umount /data ; sudo umount -l /data ; sudo fuser -vm /data
```

| Option | Use |
| --- | --- |
| `defaults` | rw, suid, dev, exec, auto, nouser, async |
| **`nofail`** | **Do not fail the boot if the device is missing — your safety net** |
| **`_netdev`** | **Required for NFS and any network device** |
| `noauto` | Do not mount at boot |
| `ro`, `noexec`, `nosuid`, `nodev` | Hardening |
| `acl`, `user_xattr` | ext4 features |
| `x-systemd.automount` | Mount on first access |

Swap:

```bash
sudo mkswap /dev/sdb2 ; sudo swapon /dev/sdb2 ; swapon --show ; free -h
sudo dd if=/dev/zero of=/swapfile bs=1M count=512
sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
sudo swapoff -a && sudo swapon -a                # THE verification
echo 'vm.swappiness = 10' | sudo tee /etc/sysctl.d/99-swap.conf
```

NFS and autofs:

```bash
# Client
sudo dnf install -y nfs-utils
showmount -e server2
sudo mount -t nfs server2:/export/shared /nfs
echo "server2:/export/shared /nfs nfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab

# Server
echo "/export/shared 192.168.56.0/24(rw,sync)" | sudo tee -a /etc/exports
sudo exportfs -rav ; sudo exportfs -v
sudo systemctl enable --now nfs-server
sudo firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
sudo firewall-cmd --reload

# autofs
sudo dnf install -y autofs
echo "/shares  /etc/auto.shares" | sudo tee /etc/auto.master.d/shares.autofs
echo "data -rw server2:/export/shared" | sudo tee /etc/auto.shares
echo "*    -rw server2:/export/&"      | sudo tee -a /etc/auto.shares   # wildcard
sudo systemctl enable --now autofs
sudo systemctl restart autofs                    # after ANY map change
```

**autofs mount points must NOT be pre-created and must NOT be in `/etc/fstab`.**

---

## Scripting

```bash
#!/bin/bash
[[ $# -ne 1 ]] && { echo "Usage: $0 FILE" >&2; exit 1; }
```

```bash
chmod +x script.sh                               # THE step people forget
bash -n script.sh                                # syntax check
bash -x script.sh                                # trace
```

| Test | Meaning |
| --- | --- |
| `-f`, `-d`, `-e` | Regular file, directory, exists |
| `-r`, `-w`, `-x` | Readable, writable, executable |
| `-s`, `-z`, `-n` | Non-empty file, empty string, non-empty string |
| `-eq -ne -lt -le -gt -ge` | **Numeric** |
| `= != < >` | **String** |

```bash
for f in /etc/*.conf; do echo "$f"; done
for i in {1..10}; do echo "$i"; done
for u in "$@"; do id "$u"; done
while read -r line; do echo "$line"; done < file
while read -r l; do echo "$l"; done < <(command)   # avoids the subshell
if grep -q root /etc/passwd; then echo yes; fi
if id "$u" &>/dev/null; then echo exists; fi
count=$(( count + 1 )) ; (( count > 5 )) && echo big
case "$1" in start) ;; stop) ;; *) ;; esac
```

**Always quote `"$@"`, `"$1"`, `"$var"`.**

---

## Containers

```bash
sudo dnf install -y container-tools
podman search httpd ; podman search --list-tags registry.../httpd-24
podman pull registry.access.redhat.com/ubi9/httpd-24
podman images ; podman inspect IMAGE ; skopeo inspect docker://IMAGE
podman run -d --name web -p 8080:8080 -v /srv/web:/var/www/html:Z \
  -e VAR=value IMAGE
podman ps ; podman ps -a ; podman stop web ; podman start web ; podman rm -f web
podman logs web ; podman exec -it web /bin/bash ; podman port web
podman volume create data ; podman volume ls ; podman volume inspect data
podman system df ; podman system prune -a
```

**`:Z` on every bind mount, or SELinux denies the container access.**

**Rootless cannot bind ports below 1024.** Map high: `-p 8080:80`.

**Rootful and rootless have separate image stores.** `sudo podman pull` for a rootful unit.

**As a systemd service — the whole point:**

```bash
# Rootful
cd /etc/systemd/system
sudo podman generate systemd --new --name web --files
sudo systemctl daemon-reload
sudo podman rm -f web
sudo systemctl enable --now container-web

# Rootless
mkdir -p ~/.config/systemd/user && cd ~/.config/systemd/user
podman generate systemd --new --name web --files
systemctl --user daemon-reload
podman rm -f web
systemctl --user enable --now container-web
loginctl enable-linger $(whoami)                 # ← WITHOUT THIS IT DIES AT REBOOT
```

Quadlet, `/etc/containers/systemd/web.container`:

```ini
[Unit]
Description=web
[Container]
Image=registry.access.redhat.com/ubi9/httpd-24
ContainerName=web
PublishPort=8080:8080
Volume=/srv/web:/var/www/html:Z
Environment=KEY=value
[Service]
Restart=always
[Install]
WantedBy=multi-user.target default.target
```

```bash
sudo systemctl daemon-reload && sudo systemctl start web
```

**No `systemctl enable` for Quadlet — `[Install] WantedBy=` does it. Omitting `[Install]` means no boot start.**

---

## Essential tools

```bash
find /etc -name '*.conf' -type f
find / -user alice -o -group devs
find /var -size +10M -mtime -7
find /home -perm /4000
find / -name '*.log' -exec rm {} \;
find / -name '*.log' -delete
grep -i -r -n -v -c -w -E -A3 -B3 pattern /path
grep -E '^root|nologin$' /etc/passwd
tar -czvf a.tar.gz /dir ; tar -xzvf a.tar.gz -C /dest ; tar -tzvf a.tar.gz
tar -cjvf a.tar.bz2 /dir ; tar -cJvf a.tar.xz /dir
gzip f ; gunzip f.gz ; bzip2 f ; xz f ; unxz f.xz
ln target hardlink ; ln -s target symlink ; ls -li ; readlink -f link
sort -n -r -k2 -u ; uniq -c ; wc -l ; cut -d: -f1,3 ; tr 'a-z' 'A-Z'
head -n5 ; tail -n5 ; tail -f ; sed -n '5,10p' ; sed 's/a/b/g' -i file
awk -F: '{print $1, $3}' ; awk '$3>1000 {print $1}' /etc/passwd
cmd > f ; cmd >> f ; cmd 2> f ; cmd &> f ; cmd 2>&1 ; cmd | tee f ; cmd < f
man -k keyword ; man 5 passwd ; apropos ; whatis ; info ; ls /usr/share/doc
```

vim, the minimum:

```text
i a o O    insert
Esc        command mode
:w :q :wq :q!  write, quit, both, discard
dd yy p u  delete line, yank, paste, undo
/text n    search, next
:%s/a/b/g  replace all
G gg :5    end, start, line 5
:set nu    line numbers
```

SSH:

```bash
ssh-keygen -t ed25519 -N ''
ssh-copy-id alice@server2
ssh -i ~/.ssh/id_ed25519 alice@server2
scp file alice@server2:/tmp/ ; scp -r dir alice@server2:/tmp/
rsync -av dir/ alice@server2:/dest/
sudo vim /etc/ssh/sshd_config                    # PermitRootLogin no
                                                 # PasswordAuthentication no
sudo sshd -t && sudo systemctl reload sshd
```

**`~/.ssh` must be 700 and `authorized_keys` 600, owned by the user.**

---

## The last five minutes

```bash
sudo findmnt --verify && sudo mount -a && sudo swapon -a
systemctl --failed
sudo firewall-cmd --permanent --list-all
grep ^SELINUX= /etc/selinux/config
for s in httpd sshd firewalld chronyd nfs-server autofs crond atd tuned; do
  printf '%-14s %s\n' "$s" "$(systemctl is-enabled $s 2>/dev/null)"
done
sudo reboot
```

**Then re-verify every task after the reboot, touching nothing by hand.** That is exactly how it is graded.
