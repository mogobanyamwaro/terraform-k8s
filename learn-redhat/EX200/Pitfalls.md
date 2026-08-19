# Pitfalls: The Mistakes That Fail Candidates

Every item here is a mistake where **the command succeeded and the task still scored zero**. That is what makes them dangerous — there is no error message to warn you.

Grouped by how much they cost.

---

## Catastrophic: these can cost you the whole exam

### 1. A broken `/etc/fstab` line

**The mistake:** a typo in a device name, UUID, filesystem type, or mount point.

**What happens:** the machine does not boot. It drops to emergency mode and asks for the root password. Every other task on that machine becomes unreachable.

```bash
# ALWAYS, before every reboot:
sudo findmnt --verify
sudo mount -a
```

```bash
# When unsure whether a device will be present, add nofail:
UUID=xxxx  /data  xfs  defaults,nofail  0 0
```

**Recovery**, if it has already happened:

```text
1. At the emergency prompt, enter the root password.
2. mount -o remount,rw /
3. vi /etc/fstab      (fix or comment out the bad line)
4. systemctl daemon-reload
5. mount -a
6. reboot
```

**Rules:**

- **`findmnt --verify` and `mount -a` after every fstab edit, without exception.**
- Get the UUID by command substitution, never by retyping it:

```bash
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1)  /data  xfs  defaults  0 0" \
  | sudo tee -a /etc/fstab
```

- **`_netdev` on every NFS entry**, or boot hangs waiting for the network.
- The fsck field is **`0` for xfs and swap**, `1` only for `/`, `2` for other ext4.

### 2. Locking yourself out of the network

**The mistake:** `nmcli con mod` with a wrong address, then `nmcli con up`, on the connection you are logged in through. Or applying a firewall change that drops SSH.

```bash
# Check before you commit
nmcli -f NAME,DEVICE,STATE con show
ip -brief addr

# Test a firewall change in runtime first, THEN persist it
sudo firewall-cmd --add-service=http
# still connected? good:
sudo firewall-cmd --runtime-to-permanent
```

**Never remove the ssh service from a zone** unless the task explicitly says so:

```bash
sudo firewall-cmd --permanent --list-services      # ssh should be there
```

### 3. Editing `/etc/sudoers` with `vim`

**The mistake:** a syntax error in `/etc/sudoers` disables **all** sudo access. If root login is also disabled, the machine is unrecoverable without a boot interruption.

```bash
sudo visudo                                  # syntax-checked on save
sudo visudo -f /etc/sudoers.d/devs           # for a drop-in
sudo visudo -c                               # verify everything
```

**Always `visudo`. Never `vim /etc/sudoers`.**

### 4. Forgetting `touch /.autorelabel` after a root password reset

**The mistake:** you complete the `rd.break` procedure, reset the password, reboot — and the new password does not work.

**Why:** `passwd` inside the chroot created `/etc/shadow` with the wrong SELinux label, because SELinux is not active in the initramfs. The login process cannot read it.

```text
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel          ← THIS
exit
exit
```

**The first boot after that is slow** — it relabels the whole filesystem. That is expected. Do not interrupt it.

**Alternative if you forgot:** boot again with `enforcing=0` appended at GRUB, log in, then:

```bash
sudo restorecon -v /etc/shadow
sudo touch /.autorelabel && sudo reboot
```

---

## Expensive: these silently zero one or more tasks

### 5. `systemctl start` instead of `enable --now`

**The single most common way to lose marks.** The service is running when you check and gone after the grader's reboot.

```bash
sudo systemctl enable --now httpd            # ALWAYS this form
systemctl is-enabled httpd                   # must say 'enabled'
```

**`is-active` tells you about now. `is-enabled` predicts the reboot.** Check the second one.

```bash
# Sweep every service you touched
for s in httpd sshd firewalld chronyd nfs-server autofs crond atd tuned; do
  printf '%-14s %s\n' "$s" "$(systemctl is-enabled $s 2>/dev/null)"
done
```

### 6. Firewall rules without `--permanent`, or without `--reload`

Two separate mistakes with the same result.

```bash
sudo firewall-cmd --add-service=http                     # runtime only — LOST at reboot
sudo firewall-cmd --permanent --add-service=http         # permanent but NOT ACTIVE YET
sudo firewall-cmd --permanent --add-service=http && sudo firewall-cmd --reload   # correct
```

**The check that catches both:**

```bash
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
```

**An empty diff means runtime and permanent agree.** Any output means one of them is wrong.

**Rescue for a session of runtime-only changes:**

```bash
sudo firewall-cmd --runtime-to-permanent
```

### 7. `chcon` instead of `semanage fcontext` + `restorecon`

**The mistake:** `chcon` fixes the label now. The next `restorecon`, filesystem relabel, or `/.autorelabel` reverts it. Graders often relabel.

```bash
# WRONG for a permanent requirement
sudo chcon -R -t httpd_sys_content_t /web

# RIGHT — two commands, always both
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
sudo restorecon -Rv /web
```

**`semanage fcontext` records the rule; `restorecon` applies it.** Doing only the first leaves the files with their old labels. Doing only the second restores them to the *default*, which is not what you wanted.

**Verify the rule is recorded, not just the current label:**

```bash
sudo semanage fcontext -l -C                 # -C shows local customisations
matchpathcon /web
ls -Zd /web
```

**Regex form matters.** `"/web(/.*)?"` covers the directory and everything under it. `"/web"` alone covers only the directory itself.

### 8. `setsebool` without `-P`

```bash
sudo setsebool httpd_enable_homedirs on       # runtime only
sudo setsebool -P httpd_enable_homedirs on    # PERSISTENT
```

**`-P` writes the policy to disk and takes a few seconds. If the command returns instantly, you forgot `-P`.**

```bash
sudo semanage boolean -l -C                   # what you have changed persistently
```

### 9. `setenforce` instead of `/etc/selinux/config`

```bash
sudo setenforce 1                             # now
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config    # after a reboot
grep ^SELINUX= /etc/selinux/config
getenforce
```

**Do both.** And note: **switching from `disabled` to `enforcing` requires a reboot with a full relabel:**

```bash
sudo touch /.autorelabel && sudo reboot
```

Going `disabled` → `permissive` → reboot → `enforcing` is the safe path.

### 10. `lvextend` without `-r`

**The mistake:** the logical volume grows, `lvs` confirms it, and `df -h` shows the old size. The filesystem was never resized.

```bash
sudo lvextend -r -L +400M /dev/vg01/lv_data   # -r resizes the filesystem too
```

**Always check `df -h`, not `lvs`.** The task asks for a bigger *filesystem*.

Recovery if you forgot:

```bash
sudo xfs_growfs /data                         # MOUNT POINT, mounted
sudo resize2fs /dev/vg01/lv_data              # DEVICE
```

**`xfs_growfs` takes a mount point and the filesystem must be mounted. `resize2fs` takes a device.** Mixing them up produces confusing errors.

### 11. Rootless containers without `loginctl enable-linger`

**The cruellest failure in the containers domain.** The unit is enabled, the container runs, every check passes — and after the reboot it is dead.

```bash
systemctl --user enable --now container-web
loginctl enable-linger alice                  # ← REQUIRED
loginctl show-user alice | grep -i Linger     # must be yes
```

**Why:** systemd runs a per-user manager only while that user has a session. At boot nobody is logged in, so with `Linger=no` no user unit can start — while `is-enabled` still cheerfully says `enabled`.

**Make the two commands one reflex:** `systemctl --user enable --now X` immediately followed by `loginctl enable-linger USER`.

### 12. `podman run -d` treated as persistent

Podman has no daemon. `podman run -d` is `systemctl start`, not `enable`.

```bash
podman run -d --name web ...                  # gone after a reboot
podman run -d --restart=always ...            # STILL gone after a reboot
```

**Any task mentioning boot, "as a service", or "automatically" needs a systemd unit.** See `35.md`.

### 13. A Quadlet file without `[Install] WantedBy=`

```ini
[Install]
WantedBy=multi-user.target default.target
```

**Without this the unit is generated and startable by hand, but never starts at boot.** And there is no `systemctl enable` to fall back on — Quadlet units are generated, so `enable` fails by design:

```text
Failed to enable unit: Unit /run/systemd/generator/web.service is transient or generated.
```

**That error is normal. The missing `[Install]` is the actual bug.**

### 14. Forgetting `systemctl daemon-reload`

Required after:

- creating or editing any unit file in `/etc/systemd/system/`
- `podman generate systemd`
- creating or editing any Quadlet `.container` file
- editing `/etc/fstab` (systemd generates mount units from it)

```bash
sudo systemctl daemon-reload
```

**Symptom without it:** `Unit X could not be found`, or your edits appear to have no effect.

### 15. Editing `/etc/resolv.conf` directly

NetworkManager regenerates it. Your changes vanish at the next connection change or reboot.

```bash
sudo nmcli con mod ens160 ipv4.dns "192.168.56.1 8.8.8.8"
sudo nmcli con mod ens160 ipv4.dns-search lab.example.com
sudo nmcli con up ens160
cat /etc/resolv.conf                          # now it reflects your setting
```

### 16. `nmcli con mod` without `nmcli con up`

**`con mod` writes the keyfile. `con up` applies it.** Without the second command the configuration is persistent but not active, so your own verification fails and you may "fix" a setting that was already correct.

```bash
sudo nmcli con mod ens160 ipv4.addresses 192.168.56.11/24
sudo nmcli con up ens160
ip -brief addr show ens160
```

Conversely, `ip addr add` is active and not persistent:

```bash
sudo ip addr add 192.168.56.11/24 dev ens160  # LOST at reboot
```

### 17. `usermod -G` instead of `-aG`

```bash
sudo usermod -aG wheel alice                  # APPEND to secondary groups
sudo usermod -G wheel alice                   # REPLACES all of them
```

**`-G` alone silently removes alice from every other secondary group.** If she was in `wheel` and you run `usermod -G devs alice`, she loses sudo access.

```bash
id alice                                      # verify AFTER, every time
```

### 18. Editing `/etc/default/grub` without `grub2-mkconfig`

```bash
sudo vim /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg   # THE step that applies it
```

**On RHEL 9 and 10 that single path works for both BIOS and UEFI.** Or skip both steps with `grubby`:

```bash
sudo grubby --update-kernel=ALL --args="quiet"
sudo grubby --info=ALL | grep args
```

### 19. Cron format mistakes

**A user field where there is none, or none where there should be one:**

```text
# crontab -e — NO user field
30 2 * * *  /usr/local/bin/backup.sh

# /etc/cron.d/mytask or /etc/crontab — HAS a user field
30 2 * * *  root  /usr/local/bin/backup.sh
```

**Getting this backwards means the job never runs, silently.**

Other cron traps:

- **`crond` must be enabled:** `sudo systemctl enable --now crond`
- **Scripts in `/etc/cron.daily/` must be executable and have no filename extension** (`run-parts` skips files with dots in some configurations)
- **cron's `PATH` is minimal.** Use absolute paths inside cron jobs.
- **`%` in a crontab command must be escaped as `\%`.**
- `at` needs `atd` enabled: `sudo systemctl enable --now atd`

### 20. `sudo echo x >> /etc/file`

The redirection is performed by *your* shell, before `sudo` runs, so it fails with permission denied.

```bash
echo x | sudo tee -a /etc/file                # append
echo x | sudo tee /etc/file                   # overwrite
sudo tee /etc/file >/dev/null <<'EOF'         # multi-line
line1
line2
EOF
sudo sh -c 'echo x >> /etc/file'              # also works
```

### 21. Missing `chmod +x` on a script

The most common scripting-task failure. The script is correct and the task scores zero.

```bash
chmod +x /usr/local/bin/myscript.sh
ls -l /usr/local/bin/myscript.sh              # look for x
./myscript.sh
```

**Also check the shebang is the first line with no leading spaces:** `#!/bin/bash`.

### 22. Bind mounts into a container without `:Z`

```bash
podman run -v /srv/web:/var/www/html:Z ...
```

**Without `:Z`, SELinux denies the container access and the application inside fails** with a permission error that looks like a filesystem problem.

```bash
sudo ausearch -m AVC -ts recent
ls -Zd /srv/web                               # should be container_file_t
```

Persistent alternative:

```bash
sudo semanage fcontext -a -t container_file_t "/srv/web(/.*)?"
sudo restorecon -Rv /srv/web
```

### 23. Rootful versus rootless image stores

```bash
podman pull IMAGE                             # goes to ~/.local/share/containers
sudo podman pull IMAGE                        # goes to /var/lib/containers
```

**They are separate. A rootful systemd unit cannot see an image you pulled as your user**, and fails at boot with a registry lookup error — often after your manual test worked.

```bash
sudo podman images                            # what a rootful unit can see
podman images                                 # what a rootless unit can see
```

### 24. autofs and fstab for the same path

**Pick one.** They fight, and the symptom is an intermittent mount.

Also:

- **Do not pre-create an autofs mount point.** autofs manages the directory; an existing directory can shadow it.
- **`systemctl restart autofs` after every map change.** A reload is not enough.
- Indirect map keys are relative; **direct map keys are absolute paths and the master-map field is `/-`**.

### 25. NFS without `_netdev`

```text
server2:/export/shared  /nfs  nfs  defaults,_netdev  0 0
```

**Without `_netdev` the boot may hang waiting for a filesystem that needs a network that is not up yet.** Add `nofail` too if the server may be absent.

### 26. `mkswap` on an LV changes the UUID

If you put the UUID in `/etc/fstab` and later re-run `mkswap`, the fstab entry becomes stale.

```bash
# Safer for LVM swap: use the device path, which never changes
/dev/vg01/lv_swap  none  swap  defaults  0 0
```

```bash
sudo swapoff -a && sudo swapon -a             # the verification
swapon --show
```

### 27. A swap file without `chmod 600`

```bash
sudo chmod 600 /swapfile                      # BEFORE mkswap
sudo mkswap /swapfile
sudo swapon /swapfile
```

```text
swapon: /swapfile: insecure permissions 0644, 0600 suggested.
```

**On some configurations `swapon` refuses outright.** Set the mode first.

### 28. Service on a non-standard port, only one of three layers fixed

Three things must change and people usually do one or two:

```bash
# 1. The service's own configuration
sudo sed -i 's/^Listen 80/Listen 8090/' /etc/httpd/conf/httpd.conf

# 2. The SELinux port label
sudo semanage port -a -t http_port_t -p tcp 8090

# 3. The firewall
sudo firewall-cmd --permanent --add-port=8090/tcp
sudo firewall-cmd --reload

sudo systemctl restart httpd
ss -tlnp | grep 8090
curl http://localhost:8090
```

**Symptom of missing layer 2:** the service refuses to start, and the journal shows `Permission denied` binding the port. **Symptom of missing layer 3:** it works locally and not from the other host.

**Use `-m` instead of `-a` if the port already has a label:**

```bash
sudo semanage port -a -t http_port_t -p tcp 8090
# ValueError: Port tcp/8090 already defined
sudo semanage port -m -t http_port_t -p tcp 8090
```

---

## Moderate: these cost part of a task

### 29. SGID directory without the group

A collaborative directory needs all of: the group, group ownership, group write, and the SGID bit.

```bash
sudo groupadd devs
sudo mkdir -p /shared/devs
sudo chown root:devs /shared/devs             # group ownership
sudo chmod 2770 /shared/devs                  # 2 = SGID, 770 = group rwx
ls -ld /shared/devs                           # drwxrws---
```

**Missing the leading `2` means new files get the creator's private group and colleagues cannot write to them.** Check for `s` in the group triad.

### 30. `find -perm` with the wrong form

```bash
find / -perm 4000                             # EXACTLY 4000 — almost nothing
find / -perm /4000                            # ANY of these bits — SUID files
find / -perm -4000                            # ALL of these bits
```

**`/4000` is what "find the SUID files" means.**

### 31. `chage` versus `login.defs`

`/etc/login.defs` sets defaults for **new** accounts only. It does not change existing users.

```bash
sudo chage -M 60 alice                        # this existing user
sudo vim /etc/login.defs                      # PASS_MAX_DAYS for future users
sudo chage -l alice                           # verify
```

**A task saying "for all existing users" needs a loop:**

```bash
for u in $(awk -F: '$3>=1000 && $3<65534 {print $1}' /etc/passwd); do
  sudo chage -M 60 -W 7 "$u"
done
```

### 32. `systemctl isolate` versus `set-default`

```bash
sudo systemctl isolate multi-user.target      # now, reverts at reboot
sudo systemctl set-default multi-user.target  # PERSISTENT
systemctl get-default
```

### 33. Timer enabled instead of service, or the reverse

```bash
sudo systemctl enable --now backup.timer      # enable the TIMER
systemctl list-timers | grep backup
```

**Enabling the `.service` makes it run once at boot, which is not a schedule.** The `.service` should have no `[Install]` section at all.

### 34. Repository added only on the command line

```bash
sudo dnf --repofrompath=tmp,http://host install pkg      # one transaction only
```

**Persistent repositories are files in `/etc/yum.repos.d/`.** Write the `.repo` file, or use `dnf config-manager`, then verify:

```bash
dnf repolist
ls /etc/yum.repos.d/
```

**And if the repository is a mounted ISO, the mount must be in `/etc/fstab` too**, or the repository breaks at the next boot:

```text
/root/rhel10.iso  /mnt/iso  iso9660  loop,ro,nofail  0 0
```

### 35. `flatpak install` system versus user

```bash
sudo flatpak install flathub app.id           # all users
flatpak install --user flathub app.id         # this user only
flatpak list --app --system
flatpak list --app --user
```

**Read the wording. "For all users" and "for user alice" are different tasks with different answers.**

### 36. Wrong SSH key permissions

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_ed25519
ls -ld ~/.ssh ; ls -l ~/.ssh
```

**Loose permissions make key authentication fail silently and fall back to a password prompt** — which looks like the key was never installed. `ssh-copy-id` gets this right; manual copying often does not.

**Also check ownership** — a key file owned by root in alice's `~/.ssh` will not work.

**And SELinux:**

```bash
sudo restorecon -Rv ~/.ssh
```

### 37. `parted` writing immediately

`fdisk` writes on `w` and discards on `q`. **`parted` applies each command as you type it.** There is no undo.

**For the exam, use `fdisk`** unless you need something it cannot do. `q` has saved many candidates.

### 38. Deleting a partition that is still in `/etc/fstab`

```text
1. sudo umount /data
2. Remove or comment the /etc/fstab line     ← FIRST
3. sudo fdisk /dev/sdb   (d, w)
4. sudo partprobe /dev/sdb
5. sudo findmnt --verify
```

**Deleting first leaves an fstab entry pointing at nothing, and the next boot goes to emergency mode.**

### 39. Forgetting `partprobe`

After `fdisk ... w`, the kernel may still hold the old partition table.

```bash
sudo partprobe /dev/sdb
lsblk                                         # the new partition should appear
```

**Symptom without it:** `mkfs` reports the device does not exist, or you write a filesystem to the wrong place.

### 40. `xfs_repair` on a mounted filesystem

```bash
sudo umount /data
sudo xfs_repair /dev/sdb1
```

```text
xfs_repair: /dev/sdb1 contains a mounted filesystem
```

**Unmount first.** And note `xfs_repair -L` zeroes the log and can lose data — last resort only.

### 41. Numeric versus string comparison in a script

```bash
[[ "$a" -eq "$b" ]]                           # numbers
[[ "$a" = "$b" ]]                             # strings
[[ "$count" -gt 5 ]]                          # correct
[[ "$count" > 5 ]]                            # STRING comparison — "10" > "5" is FALSE
```

### 42. `cmd | while read` losing variables

```bash
# WRONG — count is 0 after the loop
count=0
grep x file | while read -r l; do (( count++ )); done
echo "$count"

# RIGHT
count=0
while read -r l; do (( count++ )); done < <(grep x file)
echo "$count"
```

**The pipe puts the loop in a subshell.** Use process substitution or a here-string.

### 43. Unquoted variables

```bash
if [[ -f $file ]]                             # breaks on spaces or when empty
if [[ -f "$file" ]]                           # correct
for u in $@                                   # splits arguments containing spaces
for u in "$@"                                 # correct
rm -rf $dir/                                  # catastrophic if $dir is empty
rm -rf "${dir:?}"/                            # refuses if unset or empty
```

### 44. `mount -a` reported success but the mount is not there

```bash
findmnt /data
df -hT /data
mount | grep /data
```

**`mount -a` skips entries with `noauto`.** And a directory that already had content shows the *old* content when the mount silently failed. `findmnt` is the truth.

### 45. Working on the wrong host

Two-machine tasks are common: the NFS server on one, the client on the other; a firewall rule on one, tested from the other.

```bash
hostnamectl                                   # check before every task
```

**Put the hostname in your prompt if it is not there already.**

---

## Verification failures: the mistake of not checking

### 46. Not rebooting

**The exam reboots before grading. If you never reboot, you never test what is graded.**

Reboot after finishing each major block — storage, networking, services — not once at the end. A single reboot at the end leaves no time to fix what it reveals.

**And after the reboot, verify without starting anything by hand.** If you find yourself typing `systemctl start`, you have found a bug, not a solution.

### 47. Verifying the command instead of the result

| Do not check | Check |
| --- | --- |
| `systemctl start` succeeded | **`systemctl is-enabled`** |
| `lvextend` succeeded | **`df -h`** |
| `firewall-cmd` succeeded | **`firewall-cmd --permanent --list-all`** |
| `semanage fcontext -a` succeeded | **`ls -Z` and `semanage fcontext -l -C`** |
| `nmcli con mod` succeeded | **`ip -brief addr`** |
| The fstab line looks right | **`findmnt --verify` and `mount -a`** |
| The container is running | **`systemctl is-enabled` and `Linger=yes`** |
| The script exists | **`ls -l` for `x`, then run it** |
| `useradd` succeeded | **`id alice`** |

### 48. Not reading the task carefully

The specifics are the grading criteria:

- **Exact UID, GID, group name, path, filename, port number, size.**
- **"All users" versus "user alice".**
- **"Persistently" or "at boot" — always implied even when not written.**
- **Which host.**
- **Sizes:** "500 MiB" is `-L 500M` in LVM terms; check whether the task means the LV or the filesystem.
- **"Extend to 2 GiB" (`-L 2G`) versus "extend by 2 GiB" (`-L +2G`).**

**Re-read each task after finishing it, before moving on.** Most lost marks are answers to a slightly different question.

---

## The pre-reboot script

Run this before every reboot. It catches most of the above.

```bash
#!/bin/bash
echo "=== fstab ==="
sudo findmnt --verify && echo "fstab OK" || echo "*** FSTAB BROKEN ***"
sudo mount -a && echo "mount -a OK" || echo "*** MOUNT FAILED ***"

echo "=== swap ==="
sudo swapoff -a && sudo swapon -a && swapon --show

echo "=== services ==="
for s in httpd sshd firewalld chronyd nfs-server autofs crond atd tuned NetworkManager; do
  printf '%-16s %s\n' "$s" "$(systemctl is-enabled "$s" 2>/dev/null || echo -)"
done

echo "=== firewall runtime vs permanent ==="
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all) \
  && echo "firewall in sync"

echo "=== selinux ==="
getenforce
grep ^SELINUX= /etc/selinux/config
sudo semanage boolean -l -C 2>/dev/null
sudo semanage fcontext -l -C 2>/dev/null

echo "=== network ==="
nmcli -f NAME,DEVICE,AUTOCONNECT con show
ip -brief addr

echo "=== default target ==="
systemctl get-default

echo "=== containers ==="
systemctl is-enabled 'container-*' 2>/dev/null
ls /var/lib/systemd/linger/ 2>/dev/null

echo "=== failures ==="
systemctl --failed
sudo journalctl -b -p err --no-pager | tail -20
```

**Then reboot, and run the same script again.** Anything that changed is a persistence bug.
