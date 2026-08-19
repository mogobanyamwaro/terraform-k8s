# Flashcards

Rapid recall drill. Cover the answer, say it out loud, then check. **If you cannot produce the command from memory in five seconds, it is not ready.**

Work through this the day before, and again on exam morning. Sections match the objective domains.

---

## Persistence

**Q. Which single check predicts whether a service will still be running after the grader's reboot?**

`systemctl is-enabled UNIT`. Not `is-active`.

**Q. Make a service run now and at every boot.**

```bash
sudo systemctl enable --now httpd
```

**Q. Make an SELinux mode change survive a reboot.**

`/etc/selinux/config`, `SELINUX=enforcing`. `setenforce` alone is runtime only.

**Q. Make an SELinux boolean survive a reboot.**

```bash
sudo setsebool -P boolean_name on
```

**Q. Make a file context change survive a relabel.**

```bash
sudo semanage fcontext -a -t TYPE "/path(/.*)?"
sudo restorecon -Rv /path
```

**Q. Make a firewall rule survive a reboot, and take effect now.**

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

**Q. You made a session of runtime-only firewall changes. Save them.**

```bash
sudo firewall-cmd --runtime-to-permanent
```

**Q. Make a mount survive a reboot, and prove it before rebooting.**

An `/etc/fstab` line, then `sudo findmnt --verify` and `sudo mount -a`.

**Q. Make a kernel parameter survive a reboot.**

A file in `/etc/sysctl.d/`, e.g. `99-swappiness.conf`, then `sudo sysctl -p /etc/sysctl.d/99-swappiness.conf`.

**Q. Make a rootless container start at boot. Two commands.**

```bash
systemctl --user enable --now container-web
loginctl enable-linger USER
```

**Q. Make a default target change survive a reboot.**

`sudo systemctl set-default multi-user.target`. `isolate` is runtime only.

---

## Users and groups

**Q. Create alice with UID 1500, primary group devs, also in wheel, shell bash, home created.**

```bash
sudo useradd -u 1500 -g devs -G wheel -s /bin/bash -m alice
```

**Q. Add bob to the wheel group without removing his other groups.**

```bash
sudo usermod -aG wheel bob
```

**Q. What does `usermod -G wheel bob` do that `-aG` does not?**

Replaces **all** of bob's secondary groups with just `wheel`.

**Q. Create a service account with no login shell and no home directory.**

```bash
sudo useradd -r -M -s /sbin/nologin svcuser
```

**Q. Delete alice and her home directory.**

```bash
sudo userdel -r alice
```

**Q. Set alice's password non-interactively.**

```bash
echo 'RedHat123' | sudo passwd --stdin alice
```

**Q. Force alice to change her password at next login.**

```bash
sudo chage -d 0 alice          # or: sudo passwd -e alice
```

**Q. Password must be changed every 60 days, with 7 days' warning, and cannot be changed more than once in 7 days.**

```bash
sudo chage -m 7 -M 60 -W 7 alice
```

**Q. Where do password aging defaults for new users live?**

`/etc/login.defs`. It does **not** affect existing users.

**Q. Show alice's aging settings.**

```bash
sudo chage -l alice
```

**Q. Lock alice's account.**

```bash
sudo usermod -L alice          # or: sudo passwd -l alice
```

**Q. Give the devs group full sudo, safely.**

```bash
sudo visudo -f /etc/sudoers.d/devs
```

```text
%devs   ALL=(ALL)       ALL
```

**Q. Give ops passwordless sudo.**

```text
%ops    ALL=(ALL)       NOPASSWD: ALL
```

**Q. Why never `vim /etc/sudoers`?**

A syntax error disables all sudo. `visudo` refuses to save a broken file.

**Q. What can alice run with sudo?**

```bash
sudo -l -U alice
```

**Q. The nine fields of `/etc/shadow`, first three.**

Username, password hash, days since epoch of the last change.

---

## Permissions

**Q. Numeric values for SUID, SGID, sticky.**

4000, 2000, 1000.

**Q. Create a collaborative directory `/shared/devs` for the devs group.**

```bash
sudo mkdir -p /shared/devs
sudo chown root:devs /shared/devs
sudo chmod 2770 /shared/devs
```

**Q. What does the SGID bit do on a directory?**

New files and subdirectories inherit the directory's group.

**Q. What does the sticky bit do?**

Only a file's owner (or root) can delete it, even in a world-writable directory. `/tmp` is the example.

**Q. Find all SUID files on the system.**

```bash
sudo find / -perm /4000 -type f 2>/dev/null
```

**Q. Why `/4000` and not `4000`?**

`4000` means exactly those bits and nothing else. `/4000` means any of those bits.

**Q. Give alice rwx on a file without changing its owner or group.**

```bash
sudo setfacl -m u:alice:rwx file
```

**Q. Make alice's ACL apply to files created in a directory later.**

```bash
sudo setfacl -m d:u:alice:rwx dir
```

**Q. How do you spot an ACL in `ls -l`?**

A `+` after the permission string.

**Q. Remove every ACL from a file.**

```bash
sudo setfacl -b file
```

**Q. Set a persistent umask of 027 for all users.**

```bash
echo 'umask 0027' | sudo tee /etc/profile.d/custom-umask.sh
```

**Q. With umask 027, what permissions does a new file get? A new directory?**

File 640, directory 750.

**Q. What does execute permission mean on a directory?**

Permission to enter it and reach its contents. Without it, nothing inside is accessible.

---

## Processes and systemd

**Q. Top ten processes by memory.**

```bash
ps aux --sort=-%mem | head -10
```

**Q. Kill every process owned by alice.**

```bash
sudo pkill -u alice
```

**Q. Change a running process's priority to -5.**

```bash
sudo renice -n -5 -p PID
```

**Q. Nice value range, and which end is high priority?**

-20 to +19. **-20 is highest priority** and requires root.

**Q. Start a command with the lowest priority.**

```bash
nice -n 19 command
```

**Q. Prevent a service from being started at all, even as a dependency.**

```bash
sudo systemctl mask httpd
```

**Q. Difference between `restart` and `reload`?**

`restart` stops and starts the process; `reload` tells it to re-read its configuration without stopping.

**Q. When must you run `systemctl daemon-reload`?**

After creating or editing any unit file, after `podman generate systemd`, after a Quadlet edit, and after editing `/etc/fstab`.

**Q. Where do your own unit files go, and where do package units live?**

Yours: `/etc/systemd/system/`. Package: `/usr/lib/systemd/system/` — do not edit those.

**Q. Override one setting in a package-provided unit without editing it.**

```bash
sudo systemctl edit httpd
```

**Q. What does `is-enabled` returning `static` mean?**

The unit has no `[Install]` section, so it cannot be enabled directly; it is pulled in by a dependency.

**Q. Boot to text mode permanently.**

```bash
sudo systemctl set-default multi-user.target
```

**Q. Switch to text mode right now without changing the default.**

```bash
sudo systemctl isolate multi-user.target
```

**Q. What replaced runlevel 3? Runlevel 5?**

`multi-user.target` and `graphical.target`.

**Q. Reboot in five minutes with a message, then cancel it.**

```bash
sudo shutdown -r +5 "Rebooting"
sudo shutdown -c
```

**Q. List every failed unit.**

```bash
systemctl --failed
```

---

## Boot recovery

**Q. Reset a forgotten root password. Every step.**

```text
1. Reboot; press e at the GRUB menu
2. Append  rd.break  to the linux line
3. Ctrl-x
4. mount -o remount,rw /sysroot
5. chroot /sysroot
6. passwd root
7. touch /.autorelabel
8. exit
9. exit
```

**Q. Why `touch /.autorelabel`, and what happens without it?**

`/etc/shadow` gets the wrong SELinux label because SELinux is inactive in the initramfs. Without the relabel, the new password does not work.

**Q. You forgot `/.autorelabel` and cannot log in. Recover.**

Boot with `enforcing=0` appended at GRUB, log in, then `sudo restorecon -v /etc/shadow`, or `sudo touch /.autorelabel && sudo reboot`.

**Q. Boot into a minimal single-user environment.**

Append `systemd.unit=rescue.target` at GRUB. `emergency.target` for the most minimal.

**Q. Persistently add a kernel argument.**

Edit `GRUB_CMDLINE_LINUX` in `/etc/default/grub`, then:

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

**Q. The same thing in one command, without editing a file.**

```bash
sudo grubby --update-kernel=ALL --args="quiet"
```

**Q. Remove `rhgb quiet` from every kernel entry.**

```bash
sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"
```

**Q. Set the GRUB menu timeout to 10 seconds, persistently.**

`GRUB_TIMEOUT=10` in `/etc/default/grub`, then `grub2-mkconfig -o /boot/grub2/grub.cfg`.

**Q. A bad `/etc/fstab` line has dropped you to emergency mode. Recover.**

```bash
mount -o remount,rw /
vi /etc/fstab
systemctl daemon-reload
mount -a
reboot
```

---

## Logs

**Q. Why did httpd fail to start?**

```bash
journalctl -xeu httpd
```

**Q. Logs from the previous boot only.**

```bash
journalctl -b -1
```

**Q. Errors and worse, since 09:00.**

```bash
journalctl -p err --since '09:00'
```

**Q. Kernel messages from this boot.**

```bash
journalctl -k
```

**Q. Make the journal persistent across reboots. Two ways.**

```bash
sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald
```

or `Storage=persistent` in `/etc/systemd/journald.conf`.

**Q. Prove the journal is now persistent.**

```bash
journalctl --list-boots        # more than one boot listed
```

**Q. Which log file holds authentication and sudo events?**

`/var/log/secure`.

**Q. Which log file holds SELinux AVC denials?**

`/var/log/audit/audit.log`.

**Q. Syntax-check an rsyslog configuration before restarting.**

```bash
sudo rsyslogd -N1
```

**Q. Send a test message into the system log.**

```bash
logger -p local0.info "test message"
```

**Q. Trim the journal to two weeks.**

```bash
sudo journalctl --vacuum-time=2weeks
```

---

## Scheduling

**Q. Run `/root/backup.sh` at 02:30 every day, as root.**

```bash
sudo crontab -e
```

```text
30 2 * * * /root/backup.sh
```

**Q. Every five minutes.**

```text
*/5 * * * * /usr/local/bin/check.sh
```

**Q. 09:00 Monday to Friday.**

```text
0 9 * * 1-5 /usr/local/bin/weekday.sh
```

**Q. The five time fields, in order.**

minute, hour, day of month, month, day of week.

**Q. Which cron locations take a user field?**

`/etc/crontab` and `/etc/cron.d/*`. A user's own `crontab -e` does **not**.

**Q. Edit alice's crontab as root.**

```bash
sudo crontab -e -u alice
```

**Q. Which service must be enabled for cron? For at?**

`crond` and `atd`.

**Q. Run a command once, in five minutes.**

```bash
echo "/usr/local/bin/x.sh" | at now + 5 minutes
```

**Q. List and remove pending `at` jobs.**

```bash
atq
atrm 3
```

**Q. Deny alice the use of cron.**

Add `alice` to `/etc/cron.deny`. If `/etc/cron.allow` exists, `cron.deny` is ignored and only listed users may schedule.

**Q. A systemd timer to run a service daily at 02:00, catching up on missed runs.**

```ini
[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
[Install]
WantedBy=timers.target
```

**Q. Which unit do you enable, the timer or the service?**

**The timer.** `sudo systemctl enable --now backup.timer`.

**Q. List all timers with their next run time.**

```bash
systemctl list-timers --all
```

---

## Software and time

**Q. Which package provides the `semanage` command?**

`policycoreutils-python-utils`.

**Q. Find the package that provides a missing command.**

```bash
dnf provides */semanage
```

**Q. Which package owns `/etc/httpd/conf/httpd.conf`?**

```bash
rpm -qf /etc/httpd/conf/httpd.conf
```

**Q. List the configuration files a package installs.**

```bash
rpm -qc httpd
```

**Q. List a package's files without installing it.**

```bash
rpm -qpl package.rpm
```

**Q. Check whether a package's installed files have been modified.**

```bash
rpm -V httpd
```

**Q. Undo the last dnf transaction.**

```bash
sudo dnf history undo last
```

**Q. Add a repository at `http://host/repo`, persistently.**

Write `/etc/yum.repos.d/x.repo` with `[id]`, `name=`, `baseurl=`, `enabled=1`, `gpgcheck=0`. Then `dnf repolist` to verify.

**Q. A repository from a locally mounted ISO. Two things must persist.**

The `.repo` file with `baseurl=file:///mnt/iso/BaseOS`, **and** the mount in `/etc/fstab` with `loop,ro,nofail`.

**Q. Install a group of packages.**

```bash
sudo dnf group install "Development Tools"
```

**Q. Install a specific module stream.**

```bash
sudo dnf module install nodejs:20
```

**Q. Set the timezone to Africa/Nairobi.**

```bash
sudo timedatectl set-timezone Africa/Nairobi
```

**Q. Configure an NTP client for classroom.example.com.**

Add `server classroom.example.com iburst` to `/etc/chrony.conf`, then:

```bash
sudo systemctl restart chronyd
sudo systemctl enable chronyd
chronyc sources -v
```

**Q. What does `iburst` do?**

Sends a burst of initial requests so the first synchronisation happens in seconds rather than minutes.

**Q. Which `chronyc sources` marker means "synchronised to this source"?**

`^*`.

**Q. Enable NTP synchronisation via timedatectl.**

```bash
sudo timedatectl set-ntp true
```

**Q. Add the Flathub remote and install a Flatpak for all users.**

```bash
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install flathub org.gnome.Calculator
```

**Q. Install a Flatpak for the current user only.**

```bash
flatpak install --user flathub org.gnome.Calculator
```

**Q. List only applications, not runtimes.**

```bash
flatpak list --app
```

**Q. Remove orphaned Flatpak runtimes.**

```bash
sudo flatpak uninstall --unused
```

---

## Networking

**Q. Configure ens160 with a static address 192.168.56.11/24, gateway 192.168.56.1, DNS 8.8.8.8, persistently.**

```bash
sudo nmcli con mod ens160 ipv4.method manual \
  ipv4.addresses 192.168.56.11/24 ipv4.gateway 192.168.56.1 ipv4.dns 8.8.8.8
sudo nmcli con up ens160
```

**Q. Why do you need both `con mod` and `con up`?**

`con mod` writes the keyfile; `con up` activates it.

**Q. What must `ipv4.method` be for a static address?**

`manual`.

**Q. Add a second IP address to an existing profile.**

```bash
sudo nmcli con mod ens160 +ipv4.addresses 10.0.0.5/24
```

**Q. Where are NetworkManager connection profiles stored?**

`/etc/NetworkManager/system-connections/`.

**Q. Make a connection come up automatically at boot.**

```bash
sudo nmcli con mod ens160 connection.autoconnect yes
```

**Q. Set the hostname persistently.**

```bash
sudo hostnamectl set-hostname server1.lab.example.com
```

**Q. Why not `hostname server1`?**

Runtime only; lost at reboot.

**Q. Add a static host entry for 192.168.56.12 as server2.**

```bash
echo "192.168.56.12 server2.lab.example.com server2" | sudo tee -a /etc/hosts
```

**Q. Why not edit `/etc/resolv.conf` directly?**

NetworkManager regenerates it. Use `nmcli con mod ... ipv4.dns` instead.

**Q. Difference between `getent hosts` and `dig`?**

`getent hosts` follows `/etc/nsswitch.conf` — `/etc/hosts` first, then DNS. `dig` queries DNS only.

**Q. Open HTTP permanently and apply it now.**

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

**Q. Open TCP port 8080.**

```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

**Q. Confirm runtime and permanent firewall configurations agree.**

```bash
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
```

**Q. Allow HTTP only from 192.168.56.0/24.**

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="192.168.56.0/24" service name="http" accept'
sudo firewall-cmd --reload
```

**Q. Reject everything from 10.0.0.0/8.**

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="10.0.0.0/8" reject'
```

**Q. Put a whole subnet in the trusted zone.**

```bash
sudo firewall-cmd --permanent --zone=trusted --add-source=192.168.56.0/24
```

**Q. Forward incoming port 8080 to port 80.**

```bash
sudo firewall-cmd --permanent --add-forward-port=port=8080:proto=tcp:toport=80
sudo firewall-cmd --add-masquerade --permanent
```

**Q. Which zone applies to a packet?**

An explicit interface assignment, then a source match, then the default zone. A source match beats the interface's zone.

**Q. Show listening ports with the owning process.**

```bash
ss -tulnp
```

---

## SELinux

**Q. Current mode, and the persistent setting.**

```bash
getenforce
grep ^SELINUX= /etc/selinux/config
```

**Q. Set enforcing now and after reboot.**

```bash
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
```

**Q. Show a file's, a process's, and your own SELinux context.**

```bash
ls -Z file ; ps -Z ; id -Z
```

**Q. The four parts of a context.**

user:role:type:level. **Type is what matters for file access.**

**Q. Label `/web` as web content, permanently.**

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
sudo restorecon -Rv /web
```

**Q. Why is `chcon` not enough?**

The next `restorecon` or filesystem relabel reverts it.

**Q. What does `(/.*)?` mean in the fcontext path?**

The directory itself and everything under it, recursively.

**Q. Restore default contexts on a directory tree.**

```bash
sudo restorecon -Rv /var/www/html
```

**Q. Relabel the entire filesystem at the next boot.**

```bash
sudo touch /.autorelabel && sudo reboot
```

**Q. You copied files into `/var/www/html` and Apache returns 403. Why, and fix it.**

The files kept the source directory's label (`mv`) or got the wrong one. Fix:

```bash
sudo restorecon -Rv /var/www/html
```

**Q. Which is safe for labels, `cp` or `mv`?**

`cp` gets a fresh label from the destination's parent. **`mv` keeps the original label** — that is the dangerous one.

**Q. Enable a boolean permanently.**

```bash
sudo setsebool -P httpd_enable_homedirs on
```

**Q. List booleans you have changed from the default.**

```bash
sudo semanage boolean -l -C
```

**Q. Which boolean lets Apache make outbound network connections?**

`httpd_can_network_connect`.

**Q. Let httpd listen on port 8090.**

```bash
sudo semanage port -a -t http_port_t -p tcp 8090
```

**Q. The port already has a label and `-a` fails. Now what?**

Use `-m` instead of `-a`.

**Q. See the SELinux denials from the last few minutes.**

```bash
sudo ausearch -m AVC -ts recent
```

**Q. Get a human-readable explanation with a suggested fix.**

```bash
sudo sealert -a /var/log/audit/audit.log
```

**Q. Which two packages give you `semanage` and `sealert`?**

`policycoreutils-python-utils` and `setroubleshoot-server`.

**Q. Where do you read about httpd's booleans with no internet?**

```bash
man httpd_selinux        # from selinux-policy-doc; man -k _selinux lists them all
```

**Q. Three layers to fix when moving a service to a non-standard port.**

The service's own config, `semanage port -a`, and `firewall-cmd --permanent --add-port`.

**Q. SELinux type for a Podman bind mount.**

`container_file_t`. Or just use `:Z` on the `-v` flag.

---

## Storage

**Q. First command for any storage task.**

```bash
lsblk
```

**Q. Show filesystem types and UUIDs for every block device.**

```bash
lsblk -f          # or: sudo blkid
```

**Q. In `fdisk`, which key writes and which discards?**

`w` writes and exits. **`q` quits without saving.**

**Q. In `fdisk`, create a GPT label. Set a partition type to LVM.**

`g` for a GPT label. `t` then `lvm`.

**Q. Partition type codes for swap and LVM.**

swap `82` / `19`, LVM `8e` / `30`. Or type the names: `swap`, `lvm`.

**Q. Make the kernel see a new partition table.**

```bash
sudo partprobe /dev/sdb
```

**Q. Which of `fdisk` and `parted` writes immediately?**

`parted`. `fdisk` waits for `w`.

**Q. Get just the UUID of /dev/sdb1.**

```bash
sudo blkid -s UUID -o value /dev/sdb1
```

**Q. The three LVM layers, bottom to top.**

Physical volume, volume group, logical volume.

**Q. Create a PV, a VG named vg01, and a 500 MiB LV named lv_data.**

```bash
sudo pvcreate /dev/sdb1
sudo vgcreate vg01 /dev/sdb1
sudo lvcreate -n lv_data -L 500M vg01
```

**Q. Create an LV using all remaining free space.**

```bash
sudo lvcreate -n lv_data -l 100%FREE vg01
```

**Q. Difference between `-L` and `-l`?**

`-L` takes a size (500M, 2G). `-l` takes extents or a percentage (`100%FREE`).

**Q. Extend lv_data by 400 MiB **and** its filesystem, in one command.**

```bash
sudo lvextend -r -L +400M /dev/vg01/lv_data
```

**Q. You forgot `-r`. Grow an XFS filesystem. An ext4 one.**

```bash
sudo xfs_growfs /data                # MOUNT POINT, must be mounted
sudo resize2fs /dev/vg01/lv_data     # DEVICE
```

**Q. Add more space to a full volume group.**

```bash
sudo vgextend vg01 /dev/sdc1
```

**Q. Can XFS shrink?**

**No. Never.** ext4 can, unmounted, with `resize2fs` before `lvreduce`.

**Q. Order for removing an LVM stack.**

umount → remove the fstab line → `lvremove` → `vgremove` → `pvremove`.

**Q. Create an XFS filesystem with the label "mydata".**

```bash
sudo mkfs.xfs -L mydata /dev/sdb1
```

**Q. The six `/etc/fstab` fields.**

device, mount point, type, options, dump, fsck order.

**Q. fstab entry for /dev/sdb1 mounted at /data as xfs, by UUID.**

```text
UUID=xxxx-xxxx  /data  xfs  defaults  0 0
```

**Q. fstab entry for swap.**

```text
UUID=xxxx  none  swap  defaults  0 0
```

**Q. Validate `/etc/fstab` before rebooting. Two commands.**

```bash
sudo findmnt --verify
sudo mount -a
```

**Q. Which mount option stops a missing device from breaking the boot?**

`nofail`.

**Q. Which option is mandatory for an NFS entry in fstab?**

`_netdev`.

**Q. The fsck field value for xfs and for swap?**

`0`. `1` only for `/`, `2` for other ext4 filesystems.

**Q. Three steps to add swap.**

```bash
sudo mkswap DEVICE
sudo swapon DEVICE
# then an /etc/fstab entry
```

**Q. Create a 512 MiB swap file and activate it.**

```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=512
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

**Q. Why `chmod 600` on a swap file?**

`swapon` warns or refuses on insecure permissions.

**Q. Prove every swap entry in fstab works.**

```bash
sudo swapoff -a && sudo swapon -a && swapon --show
```

**Q. Set swappiness to 10 persistently.**

```bash
echo 'vm.swappiness = 10' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl -p /etc/sysctl.d/99-swappiness.conf
```

**Q. List a server's NFS exports from a client.**

```bash
showmount -e server2
```

**Q. Persistently mount server2:/export/shared at /nfs.**

```text
server2:/export/shared  /nfs  nfs  defaults,_netdev  0 0
```

**Q. Export /export/shared read-write to 192.168.56.0/24.**

`/etc/exports`:

```text
/export/shared  192.168.56.0/24(rw,sync)
```

```bash
sudo exportfs -rav
sudo systemctl enable --now nfs-server
sudo firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
sudo firewall-cmd --reload
```

**Q. Reload exports without restarting the NFS service.**

```bash
sudo exportfs -rav
```

**Q. What does `root_squash` do?**

Maps a remote root user to an unprivileged account. It is the default.

**Q. autofs: indirect map for /shares/data pointing at server2:/export/shared.**

```text
# /etc/auto.master.d/shares.autofs
/shares  /etc/auto.shares
```

```text
# /etc/auto.shares
data  -rw  server2:/export/shared
```

```bash
sudo systemctl enable --now autofs
```

**Q. What must you do after every autofs map change?**

```bash
sudo systemctl restart autofs
```

**Q. Should you create an autofs mount point directory?**

**No.** autofs manages it. And never also put it in `/etc/fstab`.

**Q. What is the `&` in a wildcard autofs map?**

It expands to the key that was requested, so `*  -rw  server2:/export/&` maps `/shares/anything` to `server2:/export/anything`.

**Q. The master-map field for a direct map.**

`/-`.

---

## Scripting

**Q. First line of every script, and the step people forget.**

`#!/bin/bash`, and `chmod +x script.sh`.

**Q. Syntax-check a script without running it. Trace it while running.**

```bash
bash -n script.sh
bash -x script.sh
```

**Q. Number of arguments. All arguments, safely quoted. Exit status of the last command.**

`$#`, `"$@"`, `$?`.

**Q. Exit with an error if there is not exactly one argument.**

```bash
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 FILE" >&2
    exit 1
fi
```

**Q. Test that a path is a regular file. A directory. Exists at all.**

`-f`, `-d`, `-e`.

**Q. String equality. Numeric greater-than.**

`=` and `-gt`. Mixing them is the classic bug.

**Q. Loop over every `.conf` file in /etc.**

```bash
for f in /etc/*.conf; do echo "$f"; done
```

**Q. Loop over the numbers 1 to 10.**

```bash
for i in {1..10}; do echo "$i"; done
```

**Q. Read a file line by line.**

```bash
while read -r line; do echo "$line"; done < file
```

**Q. Why not `cmd | while read`?**

The pipe puts the loop in a subshell, so variables set inside are lost after it. Use `while read ... done < <(cmd)`.

**Q. Capture a command's output into a variable.**

```bash
now=$(date +%F)
```

**Q. Integer arithmetic.**

```bash
total=$(( a + b ))
```

**Q. Print an error message to stderr.**

```bash
echo "error" >&2
```

**Q. Test whether a user exists, quietly.**

```bash
if id "$user" &>/dev/null; then echo exists; fi
```

**Q. Test whether a pattern is in a file, quietly.**

```bash
if grep -q pattern file; then echo found; fi
```

**Q. Exit immediately on any error, and on any unset variable.**

```bash
set -euo pipefail
```

**Q. Extract the first and third colon-separated fields from /etc/passwd.**

```bash
cut -d: -f1,3 /etc/passwd
# or: awk -F: '{print $1, $3}' /etc/passwd
```

**Q. Print the usernames of all accounts with UID 1000 or more.**

```bash
awk -F: '$3 >= 1000 {print $1}' /etc/passwd
```

**Q. Replace every occurrence of old with new in a file, in place, with a backup.**

```bash
sed -i.bak 's/old/new/g' file
```

**Q. Delete every commented line from a file.**

```bash
sed -i '/^#/d' file
```

---

## Containers

**Q. Which package group gives you podman and skopeo?**

`container-tools`.

**Q. Pull the UBI 9 httpd image.**

```bash
podman pull registry.access.redhat.com/ubi9/httpd-24
```

**Q. Inspect a remote image without pulling it.**

```bash
skopeo inspect docker://registry.access.redhat.com/ubi9/httpd-24
```

**Q. List the available tags for an image.**

```bash
podman search --list-tags registry.access.redhat.com/ubi9/httpd-24
```

**Q. Run a detached, named container publishing 8080, with a bind mount and an environment variable.**

```bash
podman run -d --name web -p 8080:8080 \
  -v /srv/web:/var/www/html:Z -e KEY=value \
  registry.access.redhat.com/ubi9/httpd-24
```

**Q. What does `:Z` do, and what happens without it?**

Relabels the host directory to `container_file_t` privately for the container. Without it, SELinux denies access.

**Q. Why can't a rootless container publish port 80?**

Ports below 1024 are privileged. Map to a high port, e.g. `-p 8080:80`.

**Q. Why can a rootful systemd unit fail to find an image you just pulled?**

Rootful and rootless have separate image stores. Pull with `sudo` for a rootful unit.

**Q. Run a command inside a running container.**

```bash
podman exec -it web /bin/bash
```

**Q. See a container's output.**

```bash
podman logs web
```

**Q. Does `podman run -d` survive a reboot? Does `--restart=always`?**

**No, and no.** Podman has no daemon. Only a systemd unit does.

**Q. Generate and enable a rootful systemd unit for the container "web".**

```bash
cd /etc/systemd/system
sudo podman generate systemd --new --name web --files
sudo systemctl daemon-reload
sudo podman rm -f web
sudo systemctl enable --now container-web
```

**Q. What does `--new` change, and why does it matter?**

`ExecStart` becomes the full `podman run` command instead of `podman start NAME`, so the unit recreates the container and survives `podman rm`.

**Q. What is the generated unit called?**

`container-<name>.service`.

**Q. Where do rootless units go, and which two commands enable one at boot?**

`~/.config/systemd/user/`:

```bash
systemctl --user enable --now container-web
loginctl enable-linger USER
```

**Q. What breaks without lingering, and how do you check it?**

The unit is enabled but does not start at boot, because the user's systemd manager is not running.

```bash
loginctl show-user USER | grep -i Linger
```

**Q. Why `su - alice` and not `sudo -u alice` for `systemctl --user`?**

The dash gives a login session with `XDG_RUNTIME_DIR`, which the user bus needs.

**Q. Where do Quadlet files go, rootful and rootless?**

`/etc/containers/systemd/` and `~/.config/containers/systemd/`.

**Q. What service name does `web.container` produce?**

`web.service`.

**Q. How do you enable a Quadlet unit at boot?**

You do not use `systemctl enable`. Put `WantedBy=multi-user.target default.target` in `[Install]`, then `systemctl daemon-reload`.

**Q. The five Quadlet `[Container]` keys you must know.**

`Image=`, `ContainerName=`, `PublishPort=`, `Volume=`, `Environment=`.

**Q. Best diagnostic for a Quadlet file that produces no unit.**

```bash
/usr/lib/systemd/system-generators/podman-system-generator --dryrun
```

**Q. Once systemd owns a container, how do you stop it?**

```bash
sudo systemctl stop web
```

Not `podman stop` — under `Restart=always` it comes straight back, and under `Restart=no` the unit is marked failed.

**Q. Which tool for "it will not start"? For "it started but does not work"?**

`journalctl -xeu UNIT`, then `podman logs NAME`.

---

## Final sweep

**Q. The four commands you run before every reboot.**

```bash
sudo findmnt --verify && sudo mount -a
sudo swapoff -a && sudo swapon -a
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
systemctl --failed
```

**Q. The one habit that matters most.**

**Reboot, then re-verify every task without starting anything by hand.** That is exactly what the grader does.
