# 36. Break-And-Fix Drill

**Not an objective. The most valuable practice file here.**

The exam does not only ask you to configure things. It asks you to make a system that does not work, work. And it grades after a reboot, so your own mistakes become troubleshooting exercises whether you planned them or not.

This file gives you fifteen sabotage scripts. **Run one, then diagnose and repair the system as if you had walked into it cold.** Working out what is wrong from the symptom is a different skill from configuring something from a clean state, and it is the skill that decides whether you finish in three hours.

---

## How to use this

**Take a snapshot first. Every time.**

```bash
# In your hypervisor, snapshot server1 before each drill.
# Some of these deliberately prevent the machine from booting.
```

**The procedure:**

1. Run a sabotage block as root.
2. Reboot if the block says to.
3. **Stop. Do not read the diagnosis section.**
4. Work from the symptom: what is broken, what would cause that, how do you confirm it.
5. Fix it.
6. **Reboot and verify.**
7. Read the diagnosis section and compare it with what you did.
8. Restore the snapshot before the next drill.

**Time yourself.** A drill you cannot resolve in fifteen minutes is a topic to re-read.

**And resist checking the answer.** The value is entirely in the diagnosis, not the repair — the repair is usually one command you already know.

---

## Drill 1: A service that will not start

**Sabotage:**

```bash
sudo dnf install -y httpd
sudo systemctl enable --now httpd
sudo sed -i 's/^Listen 80$/Listen 8090/' /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd
```

**Symptom:** httpd fails to start.

**Requirement:** Apache must serve on port 8090, be reachable from server2, and start at boot.

<details>
<summary>Diagnosis and fix</summary>

```bash
systemctl status httpd
sudo journalctl -xeu httpd | tail -20
```

```text
(13)Permission denied: AH00072: make_sock: could not bind to address [::]:8090
```

**`Permission denied` binding a port is SELinux, not the firewall.** A firewall never stops a local process from binding.

```bash
sudo semanage port -l | grep http_port_t
```

```text
http_port_t   tcp   80, 81, 443, 488, 8008, 8009, 8443, 9000
```

**8090 is not there.**

```bash
sudo semanage port -a -t http_port_t -p tcp 8090
sudo systemctl restart httpd
ss -tlnp | grep 8090
curl http://localhost:8090
```

**Then the third layer — the firewall:**

```bash
sudo firewall-cmd --permanent --add-port=8090/tcp
sudo firewall-cmd --reload
ssh server2 'curl -s http://192.168.56.11:8090'
```

**Verify:**

```bash
systemctl is-enabled httpd
sudo semanage port -l -C
sudo firewall-cmd --permanent --list-ports
sudo reboot
```

**The lesson: a non-standard port always needs three changes** — the service's own config, the SELinux port label, and the firewall. **"Will not start" is SELinux. "Works locally, not remotely" is the firewall.**

</details>

---

## Drill 2: A web server returning 403

**Sabotage:**

```bash
sudo dnf install -y httpd
sudo systemctl enable --now httpd
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
echo '<h1>Test page</h1>' > /tmp/index.html
sudo mv /tmp/index.html /var/www/html/index.html
```

**Symptom:** `curl http://localhost` returns 403 Forbidden.

**Requirement:** The page must be served.

<details>
<summary>Diagnosis and fix</summary>

```bash
curl -I http://localhost
ls -l /var/www/html/index.html          # permissions look fine: -rw-r--r--
```

**Permissions are correct, so check the other layer:**

```bash
ls -Z /var/www/html/index.html
```

```text
unconfined_u:object_r:user_tmp_t:s0  index.html
```

**Wrong type.** `mv` preserved the label from `/tmp`. Confirm:

```bash
sudo ausearch -m AVC -ts recent
```

```text
avc: denied { read } for pid=... comm="httpd" name="index.html"
  scontext=...httpd_t tcontext=...user_tmp_t tclass=file
```

**Fix — the default rule for `/var/www/html` is already correct, so `restorecon` alone is enough:**

```bash
sudo restorecon -v /var/www/html/index.html
ls -Z /var/www/html/index.html
curl http://localhost
```

**The lesson: `mv` keeps the source label; `cp` takes the destination's.** After moving anything into a service's directory, `restorecon -Rv` it. **And `chmod 777` fixing nothing is the signature of an SELinux problem.**

</details>

---

## Drill 3: The system will not boot

**Sabotage:**

```bash
echo "UUID=00000000-1111-2222-3333-444444444444  /broken  xfs  defaults  0 0" \
  | sudo tee -a /etc/fstab
sudo reboot
```

**Symptom:** The boot stops and asks for the root password for maintenance.

**Requirement:** A working system. Then make the same mistake safe.

<details>
<summary>Diagnosis and fix</summary>

```text
[DEPEND] Dependency failed for /broken.
[DEPEND] Dependency failed for Local File Systems.
You are in emergency mode...
Give root password for maintenance:
```

**Enter the root password, then:**

```bash
systemctl --failed
journalctl -xb | grep -i -A3 broken
findmnt --verify
```

```bash
mount -o remount,rw /                  # / is read-only in emergency mode
vi /etc/fstab
# delete or comment out the bad line
systemctl daemon-reload
mount -a
findmnt --verify
reboot
```

**Then make it safe.** Add the line back with `nofail` and observe the difference:

```bash
echo "UUID=00000000-1111-2222-3333-444444444444  /broken  xfs  defaults,nofail  0 0" \
  | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo reboot
```

**The machine boots.** The mount is skipped and everything else works.

```bash
systemctl --failed
sudo sed -i '/broken/d' /etc/fstab
sudo findmnt --verify
```

**The lesson: `findmnt --verify` and `mount -a` before every reboot, and `nofail` when a device might be absent.** This is the only mistake that can cost you the entire exam, and the prevention takes fifteen seconds. **Do this drill until the recovery is automatic.**

</details>

---

## Drill 4: Forgotten root password

**Sabotage:**

```bash
sudo passwd root
# type something long and random; do not write it down
sudo reboot
```

**Requirement:** Regain root access.

<details>
<summary>Diagnosis and fix</summary>

```text
1. At the GRUB menu, press  e
2. Append  rd.break  to the line starting with 'linux'
3. Ctrl-x
4. mount -o remount,rw /sysroot
5. chroot /sysroot
6. passwd root
7. touch /.autorelabel
8. exit
9. exit
```

**Then wait.** The relabel takes several minutes and the machine reboots itself once more.

**If you skipped step 7**, the new password will not work. Recover:

```text
1. At GRUB, press e; append  enforcing=0
2. Ctrl-x; log in as root
3. sudo restorecon -v /etc/shadow
4. sudo reboot
```

**Verify:**

```bash
getenforce                             # must be Enforcing
sudo ausearch -m AVC -ts boot
ls -Z /etc/shadow
```

```text
system_u:object_r:shadow_t:s0 /etc/shadow
```

**The lesson: `/.autorelabel` is not optional**, and `enforcing=0` is the escape hatch for any SELinux problem that blocks login. **Do this drill three times.** It is close to guaranteed on the exam and the marks are free once the sequence is automatic.

</details>

---

## Drill 5: A user who cannot log in

**Sabotage:**

```bash
sudo useradd -m testuser
echo 'RedHat123' | sudo passwd --stdin testuser
sudo usermod -s /sbin/nologin testuser
sudo chage -E 2020-01-01 testuser
```

**Symptom:** testuser cannot log in.

**Requirement:** testuser must be able to log in with bash, with an account that does not expire, and must change their password at first login.

<details>
<summary>Diagnosis and fix</summary>

```bash
sudo passwd -S testuser
sudo chage -l testuser
getent passwd testuser
```

```text
testuser PS 2026-08-18 0 99999 7 -1
Account expires : Jan 01, 2020
testuser:x:1002:1002::/home/testuser:/sbin/nologin
```

**Two problems: the shell is `/sbin/nologin` and the account expired in 2020.**

```bash
sudo usermod -s /bin/bash testuser
sudo chage -E -1 testuser
sudo chage -d 0 testuser
```

**Verify:**

```bash
getent passwd testuser
sudo chage -l testuser
su - testuser                          # should demand a password change
```

**The lesson: four independent things stop a login** — the shell, the account expiry, the password lock (`usermod -L`), and password expiry with the inactive period elapsed. **`passwd -S` and `chage -l` show all of them in two commands.**

</details>

---

## Drill 6: A logical volume that will not extend

**Sabotage:**

```bash
sudo pvcreate /dev/sdb1 2>/dev/null || {
  sudo fdisk /dev/sdb <<'EOF'
g
n


+2G
t
lvm
w
EOF
  sudo partprobe /dev/sdb
  sudo pvcreate /dev/sdb1
}
sudo vgcreate vg_drill /dev/sdb1
sudo lvcreate -n lv_drill -l 100%FREE vg_drill
sudo mkfs.xfs /dev/vg_drill/lv_drill
sudo mkdir -p /drill
echo "/dev/vg_drill/lv_drill /drill xfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
df -h /drill
```

**Requirement:** `/drill` must be at least 3 GiB.

<details>
<summary>Diagnosis and fix</summary>

```bash
df -h /drill
sudo lvs
sudo vgs
```

```text
VG        #PV #LV VSize  VFree
vg_drill    1   1 <2.00g    0
```

**The volume group has no free space, so `lvextend` alone cannot work:**

```bash
sudo lvextend -r -L 3G /dev/vg_drill/lv_drill
```

```text
Insufficient free space: 256 extents needed, but only 0 available
```

**Add capacity to the volume group first:**

```bash
lsblk                                  # is there another disk or free space?
sudo fdisk /dev/sdc                    # g, n, ⏎, ⏎, +2G, t, lvm, w
sudo partprobe /dev/sdc
sudo pvcreate /dev/sdc1
sudo vgextend vg_drill /dev/sdc1
sudo vgs                               # VFree has grown
sudo lvextend -r -L 3G /dev/vg_drill/lv_drill
df -h /drill                           # ← THE check
```

**Now do it wrong on purpose, to see the symptom:**

```bash
sudo lvextend -L +500M /dev/vg_drill/lv_drill     # no -r
sudo lvs                               # the LV grew
df -h /drill                           # the FILESYSTEM did not
sudo xfs_growfs /drill                 # the repair
df -h /drill
```

**The lesson: the extend decision tree is `vgs` first, then `vgextend` if needed, then `lvextend -r`, then check `df` and not `lvs`.** And `xfs_growfs` takes the **mount point**; `resize2fs` takes the **device**.

</details>

---

## Drill 7: A service that vanishes after a reboot

**Sabotage:**

```bash
sudo dnf install -y httpd
sudo systemctl start httpd             # note: start, not enable --now
sudo firewall-cmd --add-service=http    # note: no --permanent
curl http://localhost
sudo reboot
```

**Symptom:** After the reboot, the web server is unreachable.

**Requirement:** httpd must serve on port 80, reachable from server2, after every reboot.

<details>
<summary>Diagnosis and fix</summary>

```bash
systemctl status httpd
systemctl is-enabled httpd
```

```text
Active: inactive (dead)
disabled
```

```bash
sudo firewall-cmd --list-services       # http is gone
sudo firewall-cmd --permanent --list-services
```

**Both changes were runtime only.**

```bash
sudo systemctl enable --now httpd
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

**Verify properly:**

```bash
systemctl is-enabled httpd              # enabled
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
sudo reboot
systemctl is-active httpd
ssh server2 'curl -s http://192.168.56.11'
```

**The lesson: this drill is the exam's most common failure in miniature.** `enable --now` rather than `start`, `--permanent` plus `--reload` rather than a bare `firewall-cmd`, and **`is-enabled` plus the firewall diff as the verification.**

</details>

---

## Drill 8: A cron job that never runs

**Sabotage:**

```bash
sudo tee /usr/local/bin/drilljob.sh >/dev/null <<'EOF'
#!/bin/bash
echo "$(date): drill job ran" >> /var/log/drilljob.log
EOF
sudo chmod 644 /usr/local/bin/drilljob.sh
echo '*/2 * * * * /usr/local/bin/drilljob.sh' | sudo tee /etc/cron.d/drilljob
sudo systemctl stop crond
sudo systemctl disable crond
```

**Symptom:** `/var/log/drilljob.log` is never created.

**Requirement:** The script must run every two minutes, persistently.

<details>
<summary>Diagnosis and fix</summary>

**Three separate faults. Work through them:**

```bash
systemctl status crond
```

```text
Active: inactive (dead)
```

```bash
sudo systemctl enable --now crond
sleep 130
ls -l /var/log/drilljob.log             # still nothing
sudo journalctl -u crond -n 20
```

```text
(root) CMD (/usr/local/bin/drilljob.sh)
(CRON) ERROR (Permission denied)
```

```bash
ls -l /usr/local/bin/drilljob.sh
```

```text
-rw-r--r--. 1 root root 74 /usr/local/bin/drilljob.sh
```

**Not executable:**

```bash
sudo chmod +x /usr/local/bin/drilljob.sh
```

**And the third fault — a file in `/etc/cron.d/` requires a user field:**

```bash
cat /etc/cron.d/drilljob
```

```text
*/2 * * * * /usr/local/bin/drilljob.sh
```

**`/usr/local/bin/drilljob.sh` is being read as the username.**

```bash
echo '*/2 * * * * root /usr/local/bin/drilljob.sh' | sudo tee /etc/cron.d/drilljob
sudo systemctl restart crond
sleep 130
cat /var/log/drilljob.log
sudo journalctl -u crond -n 10
```

**Verify:**

```bash
systemctl is-enabled crond
ls -l /usr/local/bin/drilljob.sh
sudo reboot
sleep 130 && cat /var/log/drilljob.log
```

**The lesson: three faults, each silent.** `crond` must be enabled; the script must be executable; **`/etc/cron.d/` and `/etc/crontab` take a user field and `crontab -e` does not.**

</details>

---

## Drill 9: NFS that mounts by hand but not at boot

**Sabotage — on server2:**

```bash
sudo dnf install -y nfs-utils
sudo mkdir -p /export/drill
echo "drill content" | sudo tee /export/drill/testfile
echo "/export/drill 192.168.56.0/24(rw,sync)" | sudo tee -a /etc/exports
sudo systemctl enable --now nfs-server
sudo exportfs -rav
sudo firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
sudo firewall-cmd --reload
```

**On server1:**

```bash
sudo dnf install -y nfs-utils
sudo mkdir -p /mnt/drill
echo "server2:/export/drill /mnt/drill nfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
ls /mnt/drill
sudo reboot
```

**Symptom:** The boot is very slow, or drops to emergency mode.

**Requirement:** The share must be mounted at boot without risking the boot.

<details>
<summary>Diagnosis and fix</summary>

```bash
systemd-analyze blame | head
systemctl --failed
journalctl -b | grep -i mnt-drill
```

```text
A start job is running for /mnt/drill (1min 30s / no limit)
```

**The mount is attempted before the network is available.**

```bash
sudo vim /etc/fstab
```

```text
server2:/export/drill  /mnt/drill  nfs  defaults,_netdev,nofail  0 0
```

```bash
sudo systemctl daemon-reload
sudo findmnt --verify
sudo umount /mnt/drill
sudo mount -a
findmnt /mnt/drill
sudo reboot
```

**Then test resilience — the situation `nofail` exists for:**

```bash
ssh server2 'sudo systemctl stop nfs-server'
sudo reboot
```

**The machine still boots.** `/mnt/drill` is empty and nothing else is affected.

```bash
ssh server2 'sudo systemctl start nfs-server'
sudo mount -a
ls /mnt/drill
```

**The lesson: `_netdev` on every NFS entry, and `nofail` when the server may be down.** Also worth noticing: `systemd-analyze blame` is how you find a mount that adds ninety seconds to every boot.

</details>

---

## Drill 10: A rootless container that dies at reboot

**Sabotage:**

```bash
sudo useradd -m drilluser
echo 'RedHat123' | sudo passwd --stdin drilluser
su - drilluser
```

```bash
podman pull registry.access.redhat.com/ubi9/httpd-24
podman run -d --name drillweb -p 8080:8080 registry.access.redhat.com/ubi9/httpd-24
mkdir -p ~/.config/systemd/user && cd ~/.config/systemd/user
podman generate systemd --new --name drillweb --files
systemctl --user daemon-reload
podman rm -f drillweb
systemctl --user enable --now container-drillweb
systemctl --user is-enabled container-drillweb
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080
exit
```

```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
sudo reboot
```

**Symptom:** After the reboot, port 8080 does not respond, but everything checked out beforehand.

<details>
<summary>Diagnosis and fix</summary>

```bash
curl http://localhost:8080              # connection refused
su - drilluser -c 'systemctl --user status container-drillweb'
```

```text
Loaded: loaded (/home/drilluser/.config/systemd/user/container-drillweb.service; enabled)
Active: inactive (dead)
```

**Enabled and not started. That is the signature.**

```bash
loginctl show-user drilluser | grep -i Linger
```

```text
Linger=no
```

```bash
sudo loginctl list-users
systemctl status user@$(id -u drilluser).service
```

```text
UID  USER      LINGER STATE
1003 drilluser no     closing

● user@1003.service - User Manager for UID 1003
     Active: inactive (dead)
```

**Her systemd manager never started at boot, so no user unit could run.**

```bash
sudo loginctl enable-linger drilluser
loginctl show-user drilluser | grep -i Linger
ls -l /var/lib/systemd/linger/
su - drilluser -c 'systemctl --user start container-drillweb'
curl http://localhost:8080
sudo reboot
```

After the reboot, **without logging in as drilluser:**

```bash
curl -s http://localhost:8080
sudo loginctl list-users
ps -u drilluser | grep -c conmon
```

**The lesson: `systemctl --user is-enabled` returning `enabled` is not sufficient for a rootless service.** Lingering is a separate, invisible requirement. **`systemctl --user enable --now X` and `loginctl enable-linger USER` are one reflex, not two commands.**

</details>

---

## Drill 11: Networking that reverts at reboot

**Sabotage:**

```bash
sudo ip addr add 192.168.56.99/24 dev ens160
sudo nmcli con mod ens160 connection.autoconnect no
ip -brief addr
sudo reboot
```

**Symptom:** After the reboot the machine has no address, or the wrong one.

**Requirement:** A static address of 192.168.56.11/24, gateway 192.168.56.1, DNS 192.168.56.1 and 8.8.8.8, applied at every boot.

<details>
<summary>Diagnosis and fix</summary>

**You may need console access — a network task can lock you out, which is itself the lesson.**

```bash
ip -brief addr
nmcli device status
nmcli -f NAME,DEVICE,AUTOCONNECT connection show
```

```text
NAME    DEVICE  AUTOCONNECT
ens160  --      no
```

**Two faults: `autoconnect no`, and the address was added with `ip addr add`, which never persists.**

```bash
sudo nmcli con mod ens160 \
  ipv4.method manual \
  ipv4.addresses 192.168.56.11/24 \
  ipv4.gateway 192.168.56.1 \
  ipv4.dns "192.168.56.1 8.8.8.8" \
  connection.autoconnect yes

sudo nmcli con up ens160
ip -brief addr show ens160
ip route
cat /etc/resolv.conf
```

**Verify the persistent form, on disk:**

```bash
nmcli -f NAME,DEVICE,AUTOCONNECT connection show
sudo cat /etc/NetworkManager/system-connections/*.nmconnection
systemctl is-enabled NetworkManager
sudo reboot
ip -brief addr
```

**The lesson: `ip addr add` is diagnostic only.** Configuration is `nmcli con mod` (writes the file) plus `nmcli con up` (applies it), and **`connection.autoconnect yes` is what makes it come up at boot.** Check that column before every reboot.

</details>

---

## Drill 12: Full disk with free space

**Sabotage:**

```bash
sudo mkdir -p /drill2
sudo dd if=/dev/zero of=/tmp/drillfs bs=1M count=100
sudo mkfs.ext4 -N 128 -F /tmp/drillfs
sudo mount -o loop /tmp/drillfs /drill2
sudo bash -c 'for i in $(seq 1 200); do touch /drill2/file$i 2>/dev/null; done'
sudo touch /drill2/onemore
```

**Symptom:** `No space left on device`, but `df -h` shows the filesystem is nearly empty.

<details>
<summary>Diagnosis and fix</summary>

```bash
df -h /drill2
```

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       93M   14K   86M   1% /drill2
```

**Plenty of space. So it is not space:**

```bash
df -i /drill2
```

```text
Filesystem     Inodes IUsed IFree IUse% Mounted on
/dev/loop0        128   128     0  100% /drill2
```

**Inode exhaustion.** Every inode is used, so no new file can be created regardless of free space.

```bash
sudo find /drill2 -type f | wc -l
sudo rm -f /drill2/file1*
df -i /drill2
sudo touch /drill2/onemore              # now works
```

**The permanent fix is recreating the filesystem with more inodes:**

```bash
sudo umount /drill2
sudo mkfs.ext4 -N 8192 -F /tmp/drillfs
sudo mount -o loop /tmp/drillfs /drill2
df -i /drill2
```

**Clean up:**

```bash
sudo umount /drill2 && sudo rm -f /tmp/drillfs && sudo rmdir /drill2
```

**The related fault worth knowing — a deleted file still held open:**

```bash
sudo lsof +L1
```

**A process holding a deleted file keeps its space allocated until the process is restarted.** `df` shows the space as used and `du` cannot find it.

**The lesson: "full but not full" has two causes — inode exhaustion (`df -i`) and deleted-but-open files (`lsof +L1`).** xfs allocates inodes dynamically so this is mostly an ext4 problem, but the diagnostic habit applies to both.

</details>

---

## Drill 13: A script that works by hand and not from cron

**Sabotage:**

```bash
sudo tee /usr/local/bin/drillreport.sh >/dev/null <<'EOF'
#!/bin/bash
COUNT=$(getent passwd | awk -F: '$3>=1000 && $3<60000' | wc -l)
echo "$(date): $COUNT regular users" >> /var/log/drillreport.log
lvs --noheadings -o lv_name >> /var/log/drillreport.log
EOF
sudo chmod +x /usr/local/bin/drillreport.sh
sudo /usr/local/bin/drillreport.sh
cat /var/log/drillreport.log             # works

echo '*/2 * * * * root /usr/local/bin/drillreport.sh' | sudo tee /etc/cron.d/drillreport
sudo systemctl enable --now crond
```

**Symptom:** Run by hand it works. From cron, the log gets a partial line and cron mails an error.

<details>
<summary>Diagnosis and fix</summary>

```bash
sleep 130
cat /var/log/drillreport.log
sudo journalctl -u crond -n 20
sudo cat /var/spool/mail/root | tail -20
```

```text
/usr/local/bin/drillreport.sh: line 4: lvs: command not found
```

**`lvs` lives in `/usr/sbin`, which is not on cron's `PATH`:**

```bash
which lvs
```

```text
/usr/sbin/lvs
```

```bash
echo '*/2 * * * * root echo "PATH is $PATH"' | sudo tee /etc/cron.d/pathtest
sleep 130
sudo journalctl -u crond -n 5
sudo rm /etc/cron.d/pathtest
```

**cron's `PATH` is minimal — typically `/usr/bin:/bin`.**

**Two fixes, either acceptable:**

```bash
# 1. Absolute paths in the script — the more robust habit
sudo sed -i 's|^lvs |/usr/sbin/lvs |' /usr/local/bin/drillreport.sh
```

```bash
# 2. Set PATH in the crontab file
sudo tee /etc/cron.d/drillreport >/dev/null <<'EOF'
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/2 * * * * root /usr/local/bin/drillreport.sh
EOF
```

```bash
sudo systemctl restart crond
sleep 130
cat /var/log/drillreport.log
```

**The lesson: cron runs with a minimal environment — no `PATH` additions, no shell profile, no aliases.** A script that works interactively can fail in cron for that reason alone. **Use absolute paths in anything scheduled**, and check `journalctl -u crond` and root's mail when a scheduled job misbehaves.

</details>

---

## Drill 14: Permissions that look right

**Sabotage:**

```bash
sudo groupadd drillgrp
sudo useradd -m -G drillgrp drilla
sudo useradd -m -G drillgrp drillb
sudo mkdir -p /srv/drillshare
sudo chown root:drillgrp /srv/drillshare
sudo chmod 770 /srv/drillshare
su - drilla -c 'touch /srv/drillshare/from-drilla.txt'
```

**Symptom:** drillb cannot edit `/srv/drillshare/from-drilla.txt`, even though both users are in `drillgrp` and the directory is `770`.

**Requirement:** Both users must be able to create and edit each other's files. Neither may delete files they do not own.

<details>
<summary>Diagnosis and fix</summary>

```bash
ls -ld /srv/drillshare
ls -l /srv/drillshare/
id drilla ; id drillb
```

```text
drwxrwx---. 2 root drillgrp 32 /srv/drillshare
-rw-r--r--. 1 drilla drilla  0 from-drilla.txt
                      └──┬──┘
                    the group is DRILLA, not drillgrp
```

**Two faults:**

**1. No SGID on the directory**, so new files get the creator's primary group.

**2. The creator's `umask` is 022**, so files are not group-writable even once the group is right.

```bash
sudo chmod 2770 /srv/drillshare
ls -ld /srv/drillshare                  # drwxrws---
su - drilla -c 'touch /srv/drillshare/test2.txt'
ls -l /srv/drillshare/
```

```text
-rw-r--r--. 1 drilla drillgrp 0 test2.txt
                     └── the group is right now...
    └── ...but still not group-writable
```

**SGID sets the group; it does not set group write. A default ACL does:**

```bash
sudo setfacl -m  g:drillgrp:rwx /srv/drillshare
sudo setfacl -m d:g:drillgrp:rwx /srv/drillshare
su - drilla -c 'touch /srv/drillshare/test3.txt'
ls -l /srv/drillshare/
getfacl /srv/drillshare/test3.txt
```

```text
-rw-rw----+ 1 drilla drillgrp 0 test3.txt
```

**And the deletion requirement — the sticky bit:**

```bash
sudo chmod 3770 /srv/drillshare
ls -ld /srv/drillshare                  # drwxrws--T+
```

**Fix the pre-existing files:**

```bash
sudo chgrp -R drillgrp /srv/drillshare
sudo chmod -R g+w /srv/drillshare
```

**Verify the behaviour, not the mode:**

```bash
su - drilla -c 'echo one > /srv/drillshare/a.txt'
su - drillb -c 'echo two >> /srv/drillshare/a.txt'     # must WORK
su - drillb -c 'rm -f /srv/drillshare/a.txt'           # must FAIL
cat /srv/drillshare/a.txt
```

**The lesson: `2770` is necessary and often not sufficient.** SGID fixes the group; a default ACL fixes group write; the sticky bit prevents cross-deletion. **And existing files are not retroactively fixed — SGID applies to new entries only.**

</details>

---

## Drill 15: Everything at once

**Sabotage — run all of it, then reboot:**

```bash
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
sudo systemctl disable --now firewalld
sudo systemctl disable --now chronyd
sudo systemctl set-default rescue.target
sudo nmcli con mod ens160 connection.autoconnect no
echo "/dev/sdz9 /nonexistent xfs defaults 0 0" | sudo tee -a /etc/fstab
sudo chmod 777 /etc/shadow
sudo sed -i 's/^%wheel/#%wheel/' /etc/sudoers
sudo reboot
```

**Symptom:** Everything is wrong.

**Requirement:** Return the system to a correct state: SELinux enforcing, firewall and time sync running at boot, normal multi-user boot, networking automatic, a valid fstab, correct permissions on `/etc/shadow`, and working sudo for the wheel group.

<details>
<summary>Diagnosis and fix</summary>

**This is a realistic end-of-exam state after a bad session, and the value is in having a systematic sweep rather than eight separate discoveries.**

**The boot fails first** — the fstab line sends you to emergency mode:

```bash
mount -o remount,rw /
vi /etc/fstab                           # remove the /nonexistent line
systemctl daemon-reload
mount -a
findmnt --verify
```

**Then you land in rescue mode, because of `set-default`:**

```bash
systemctl get-default
systemctl set-default multi-user.target
systemctl isolate multi-user.target
```

**Now sweep systematically:**

```bash
# 1. SELinux
getenforce
grep ^SELINUX= /etc/selinux/config
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# 2. Services
systemctl --failed
for s in firewalld chronyd sshd NetworkManager crond; do
  printf '%-16s %s\n' "$s" "$(systemctl is-enabled $s 2>/dev/null)"
done
sudo systemctl enable --now firewalld
sudo systemctl enable --now chronyd

# 3. Networking
nmcli -f NAME,DEVICE,AUTOCONNECT con show
sudo nmcli con mod ens160 connection.autoconnect yes
sudo nmcli con up ens160
ip -brief addr

# 4. fstab
sudo findmnt --verify
sudo mount -a

# 5. Permissions on a critical file
ls -l /etc/shadow
sudo chmod 000 /etc/shadow
sudo restorecon -v /etc/shadow
ls -lZ /etc/shadow

# 6. sudo
sudo visudo -c
grep wheel /etc/sudoers
sudo sed -i 's/^#%wheel\s*ALL=(ALL)\s*ALL/%wheel  ALL=(ALL)       ALL/' /etc/sudoers
sudo visudo -c
sudo -l -U <a wheel member>

# 7. Time
timedatectl
chronyc sources -v
```

**Then the full verification sweep and a reboot:**

```bash
sudo findmnt --verify && sudo mount -a
sudo swapoff -a && sudo swapon -a
systemctl get-default
getenforce ; grep ^SELINUX= /etc/selinux/config
nmcli -f NAME,AUTOCONNECT con show
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
systemctl --failed
sudo journalctl -b -p err
sudo visudo -c
ls -l /etc/shadow
sudo reboot
```

**After the reboot, run the whole sweep again.** Anything that changed is a persistence bug.

**The lesson: have a standard sweep and run it mechanically rather than reasoning from symptoms one at a time.** That sweep is in `Pitfalls.md` as a script, and it is what you should run in the last ten minutes of the exam.

</details>

---

## The sweep

**Keep this on the system and run it before every reboot, in practice and in the exam.**

```bash
sudo tee /usr/local/bin/precheck.sh >/dev/null <<'SCRIPT'
#!/bin/bash
echo "===== fstab ====="
sudo findmnt --verify && echo "  fstab parses OK" || echo "  *** FSTAB BROKEN ***"
sudo mount -a && echo "  mount -a OK" || echo "  *** MOUNT FAILED ***"

echo "===== swap ====="
sudo swapoff -a && sudo swapon -a && swapon --show

echo "===== services ====="
for s in sshd firewalld chronyd crond atd tuned NetworkManager httpd nfs-server autofs; do
    printf '  %-16s %-10s %s\n' "$s" \
      "$(systemctl is-enabled "$s" 2>/dev/null || echo -)" \
      "$(systemctl is-active  "$s" 2>/dev/null || echo -)"
done

echo "===== firewall runtime vs permanent ====="
diff <(sudo firewall-cmd --list-all 2>/dev/null) \
     <(sudo firewall-cmd --permanent --list-all 2>/dev/null) \
  && echo "  in sync"

echo "===== selinux ====="
echo "  current:    $(getenforce)"
echo "  configured: $(grep ^SELINUX= /etc/selinux/config)"
sudo semanage boolean -l -C 2>/dev/null | sed 's/^/  /'
sudo semanage fcontext -l -C 2>/dev/null | sed 's/^/  /'
sudo semanage port -l -C 2>/dev/null | sed 's/^/  /'

echo "===== network ====="
nmcli -f NAME,DEVICE,AUTOCONNECT con show | sed 's/^/  /'
ip -brief addr | sed 's/^/  /'

echo "===== default target ====="
echo "  $(systemctl get-default)"

echo "===== containers ====="
ls /var/lib/systemd/linger/ 2>/dev/null | sed 's/^/  linger: /'
systemctl list-units 'container-*' --no-legend 2>/dev/null | sed 's/^/  /'

echo "===== failures ====="
systemctl --failed --no-legend | sed 's/^/  /'
sudo journalctl -b -p err --no-pager 2>/dev/null | tail -10 | sed 's/^/  /'
SCRIPT

sudo chmod +x /usr/local/bin/precheck.sh
sudo /usr/local/bin/precheck.sh
```

**Run it, reboot, run it again, and diff the two outputs.** Anything that differs is something you thought you had configured and had not.

---

## What to take from these drills

| Drill | The habit it teaches |
| --- | --- |
| 1, 2 | **`ausearch -m AVC -ts recent` before doubting anything else** |
| 3, 9 | **`findmnt --verify` and `mount -a` before every reboot; `nofail` and `_netdev`** |
| 4 | **`rd.break` plus `/.autorelabel` as one sequence; `enforcing=0` as the escape hatch** |
| 5 | **`passwd -S` and `chage -l` show every reason a login fails** |
| 6 | **`vgs` → `vgextend` → `lvextend -r` → check `df`, not `lvs`** |
| 7 | **`enable --now`, `--permanent` plus `--reload`, and verify with `is-enabled` and the firewall diff** |
| 8, 13 | **cron needs the service enabled, `+x` on the script, the right file format, and absolute paths** |
| 10 | **`loginctl enable-linger` for every rootless service** |
| 11 | **`nmcli con mod` plus `con up` plus `autoconnect yes`; never `ip addr add`** |
| 12 | **`df -i` and `lsof +L1` when a disk is full but is not** |
| 14 | **SGID for the group, a default ACL for group write, sticky against deletion** |
| 15 | **Run a standard sweep rather than diagnosing one symptom at a time** |

**The single most transferable thing here: work from the symptom to the layer.**

```text
Will not start at all               → SELinux, or config, or a port in use
Works locally, not remotely         → the firewall
Works now, gone after a reboot      → persistence: enable, --permanent, fstab, linger
Works for root, not for a user      → permissions; namei -l
chmod 777 changes nothing           → SELinux
Works by hand, not from cron        → PATH, or +x, or the service is not enabled
Everything looks right and fails    → run the sweep and reboot
```
