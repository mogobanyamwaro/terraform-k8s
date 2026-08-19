# Persistence: The File That Decides Whether You Pass

Read this before anything else in this folder.

> As with all Red Hat performance-based exams, configurations must persist after reboot without intervention.
>
> — Red Hat, official EX200 exam page

Your machine is rebooted before it is graded. The grader does not see what you did. It sees what survived.

This is the difference between candidates who "knew everything" and failed, and candidates who pass. Almost every EX200 failure story is a persistence failure, not a knowledge failure.

## The Rule

**For every task, ask: what file on disk did this change?**

If the answer is "none", you have not finished the task.

| You typed | It works now | It survives a reboot | The persistent form |
| --- | --- | :---: | --- |
| `systemctl start httpd` | Yes | **No** | `systemctl enable --now httpd` |
| `mount /dev/vdb1 /mnt/data` | Yes | **No** | An `/etc/fstab` entry |
| `swapon /dev/vdb2` | Yes | **No** | An `/etc/fstab` entry with `swap swap` |
| `firewall-cmd --add-service=http` | Yes | **No** | `--permanent`, then `--reload` |
| `setenforce 1` | Yes | **No** | `SELINUX=enforcing` in `/etc/selinux/config` |
| `chcon -t httpd_sys_content_t /web` | Yes | **Survives a reboot but not a `restorecon`** | `semanage fcontext -a` then `restorecon` |
| `ip addr add 10.0.0.5/24 dev eth0` | Yes | **No** | `nmcli con mod` + `nmcli con up` |
| `hostname server1` | Yes | **No** | `hostnamectl set-hostname` |
| `sysctl -w net.ipv4.ip_forward=1` | Yes | **No** | A file in `/etc/sysctl.d/` |
| `export EDITOR=vim` | Yes | **No** | `/etc/profile.d/*.sh` or `~/.bashrc` |
| `tuned-adm profile virtual-guest` | Yes | Yes | Already persistent |
| `usermod`, `chage`, `useradd` | Yes | Yes | Writes `/etc/passwd`, `/etc/shadow` |
| `semanage port -a` | Yes | Yes | Writes the local policy store |
| `lvextend` + `resize2fs`/`xfs_growfs` | Yes | Yes | On-disk metadata |

The two rows that catch the most people are `systemctl start` without `enable`, and a mount without an `fstab` entry.

## The Eight Persistence Traps

### 1. Started but not enabled

```bash
# WRONG
sudo systemctl start httpd

# RIGHT
sudo systemctl enable --now httpd
```

Make `enable --now` your only muscle memory. There is no situation on this exam where you want `start` alone.

Verify:

```bash
systemctl is-enabled httpd    # must print: enabled
systemctl is-active httpd     # must print: active
```

Both. Every time.

### 2. Mounted but not in fstab

```bash
# WRONG
sudo mount /dev/vdb1 /mnt/data

# RIGHT
UUID=$(sudo blkid -s UUID -o value /dev/vdb1)
echo "UUID=$UUID  /mnt/data  xfs  defaults  0 0" | sudo tee -a /etc/fstab
sudo mount -a
```

And **never** put a device name in `fstab`:

```text
/dev/vdb1  /mnt/data  xfs  defaults  0 0      # WRONG. Device names are not stable
UUID=1a2b...  /mnt/data  xfs  defaults  0 0   # RIGHT
LABEL=data    /mnt/data  xfs  defaults  0 0   # ALSO RIGHT
```

The exam objective says "by universally unique ID (UUID) or label" explicitly. Using `/dev/vdb1` can be marked wrong even if it happens to mount.

### 3. A broken fstab makes the system unbootable

This is the one that turns a small mistake into a catastrophe. A typo in `fstab` drops the boot into emergency mode, and if you cannot recover it you lose every task on that machine.

**Always test before rebooting:**

```bash
sudo findmnt --verify          # checks fstab syntax and targets
sudo mount -a                  # actually mounts everything; must be silent
echo $?                        # must be 0
```

If `mount -a` prints anything, fix it before you reboot.

For anything optional or removable, add `nofail`:

```text
/dev/sr0  /mnt/iso  iso9660  ro,nofail  0 0
```

### 4. Firewall rules that only exist in runtime

```bash
# WRONG: gone on reload or reboot
sudo firewall-cmd --add-service=http

# WRONG: not active now, so a live test fails
sudo firewall-cmd --permanent --add-service=http

# RIGHT
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

Verify **both** views, because they can disagree:

```bash
sudo firewall-cmd --list-all                # runtime
sudo firewall-cmd --list-all --permanent    # what survives
```

### 5. SELinux mode set but not written

```bash
# WRONG: reverts on reboot
sudo setenforce 1

# RIGHT: both, so it is correct now and after reboot
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
```

Verify:

```bash
getenforce                          # Enforcing
grep '^SELINUX=' /etc/selinux/config
```

Note the direction that needs a reboot: going from **disabled** to **enforcing** requires a reboot and a full filesystem relabel. Going between permissive and enforcing does not.

### 6. `chcon` instead of `semanage fcontext`

```bash
# FRAGILE: survives a reboot, but any restorecon or relabel undoes it
sudo chcon -t httpd_sys_content_t -R /web

# DURABLE: changes what the policy says the context should be
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
sudo restorecon -Rv /web
```

Do the `semanage` line **then** `restorecon`. `semanage` records the rule; `restorecon` applies it. Neither alone is enough.

The regex form `"/web(/.*)?"` means "the directory itself and everything under it". Memorise that string; you will type it under pressure.

### 7. IP set with `ip` instead of `nmcli`

```bash
# WRONG: vanishes on reboot or NetworkManager restart
sudo ip addr add 192.168.56.11/24 dev eth0

# RIGHT
sudo nmcli con mod eth0 ipv4.addresses 192.168.56.11/24 \
  ipv4.gateway 192.168.56.1 ipv4.dns 192.168.56.1 ipv4.method manual
sudo nmcli con up eth0
```

`nmcli con mod` writes a keyfile under `/etc/NetworkManager/system-connections/`. That file is the persistent artifact. `nmcli con up` makes it live.

### 8. Unit files edited without a daemon-reload

```bash
sudo vim /etc/systemd/system/myapp.service
sudo systemctl daemon-reload          # REQUIRED after editing any unit
sudo systemctl enable --now myapp
```

Forgetting `daemon-reload` means systemd keeps running the old definition, so your change appears to do nothing.

## The Pre-Reboot Checklist

Run this before you reboot, and again after. Every line should come back clean.

```bash
#!/bin/bash
echo "=== 1. fstab parses and everything mounts ==="
sudo findmnt --verify
sudo mount -a && echo "  mount -a: OK" || echo "  *** MOUNT -A FAILED — DO NOT REBOOT ***"

echo "=== 2. swap is active and in fstab ==="
swapon --show
grep -i swap /etc/fstab

echo "=== 3. services: enabled AND active ==="
for s in sshd firewalld chronyd httpd nfs-server autofs; do
  systemctl list-unit-files "$s.service" &>/dev/null || continue
  printf "  %-14s enabled=%-10s active=%s\n" \
    "$s" "$(systemctl is-enabled $s 2>&1)" "$(systemctl is-active $s 2>&1)"
done

echo "=== 4. firewall runtime vs permanent ==="
echo "  runtime:   $(sudo firewall-cmd --list-services)"
echo "  permanent: $(sudo firewall-cmd --list-services --permanent)"
echo "  ports:     $(sudo firewall-cmd --list-ports --permanent)"

echo "=== 5. SELinux now and after reboot ==="
echo "  now:    $(getenforce)"
echo "  config: $(grep '^SELINUX=' /etc/selinux/config)"

echo "=== 6. network is persistent ==="
nmcli -t -f NAME,DEVICE,AUTOCONNECT con show
ip -brief addr show

echo "=== 7. hostname ==="
hostnamectl --static

echo "=== 8. default target ==="
systemctl get-default

echo "=== 9. any failed units ==="
systemctl --failed

echo "=== 10. LVM layout ==="
sudo pvs; sudo vgs; sudo lvs
lsblk
```

Save this as `~/precheck.sh` in your lab and run it constantly. On the exam, type the parts you need from memory.

## The Post-Reboot Verification

After the reboot, the questions are simpler:

```bash
systemctl --failed          # must be empty
findmnt                     # every required mount present?
swapon --show               # swap back?
getenforce                  # Enforcing?
sudo firewall-cmd --list-all
ip -brief addr show         # correct IP?
journalctl -p err -b        # anything angry this boot?
```

`systemctl --failed` and `journalctl -p err -b` are the two fastest ways to find out what the reboot broke.

## Reboot Timing Strategy

| Minute | Action |
| --- | --- |
| 0-5 | Read all tasks. Note dependencies |
| 5-140 | Do the work |
| **140-150** | Run the pre-reboot checklist. Fix everything it finds |
| **150** | **Reboot** |
| 150-165 | Post-reboot verification. Fix what broke |
| 165-180 | Buffer. Re-verify. Reboot again if you changed anything significant |

**Do not reboot at minute 175.** If the reboot exposes a broken `fstab`, you need time to boot into emergency mode, fix it, and reboot again. Candidates fail tasks they had genuinely completed because they discovered the problem with four minutes left.

If you have time, reboot **twice**. The second reboot proves the first one did not leave something in a state that only works once.

## Quick Recall

- The grader reboots the machine. **Only what is on disk counts.**
- **`systemctl enable --now`**, never `start` alone. Verify with `is-enabled` **and** `is-active`.
- Mounts go in **`/etc/fstab`**, by **UUID or LABEL**, never by device name.
- **`findmnt --verify` and `mount -a` before every reboot.** A bad `fstab` can cost you the whole machine.
- `nofail` on anything removable or optional.
- Firewall: **`--permanent` then `--reload`**. Check runtime and permanent separately.
- SELinux: **`setenforce` for now, `/etc/selinux/config` for later.** Do both.
- Contexts: **`semanage fcontext -a` then `restorecon -Rv`**. `chcon` alone is fragile.
- IPs come from **`nmcli con mod`** plus `nmcli con up`, never `ip addr add`.
- **`daemon-reload`** after touching any unit file.
- Reboot at **minute 150**, not minute 175.
