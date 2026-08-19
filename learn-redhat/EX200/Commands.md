# Command Reference By Objective

Every command the exam can ask for, grouped by the official objective, with the flags that matter and what each one actually does. `CheatSheet.md` is for speed on exam morning; this file is for looking something up while you practise.

---

## Understand and use essential tools

### Navigation and files

| Command | What it does |
| --- | --- |
| `pwd` | Print the working directory |
| `cd -` | Return to the previous directory |
| `ls -l` | Long listing: type, permissions, links, owner, group, size, mtime, name |
| `ls -a` | Include dotfiles |
| `ls -h` | Human-readable sizes |
| `ls -t` | Sort by modification time, newest first |
| `ls -S` | Sort by size |
| `ls -R` | Recurse |
| `ls -i` | Show inode numbers — how you prove two files are hard links |
| `ls -d` | The directory itself, not its contents |
| `ls -Z` | **SELinux context** |
| `ls -ld dir` | The classic combination for checking directory permissions |
| `stat file` | Inode, size, blocks, permissions, all three timestamps |
| `file file` | Identify content type regardless of the name |
| `tree -L 2` | Directory tree, two levels (may need installing) |

| Command | What it does |
| --- | --- |
| `mkdir -p a/b/c` | **Create parents as needed, no error if it exists** |
| `mkdir -m 750 dir` | Create with explicit permissions |
| `rmdir dir` | Remove an empty directory only |
| `cp src dst` | Copy |
| `cp -r dir dst` | Recurse |
| `cp -p` | Preserve mode, ownership, timestamps |
| **`cp -a`** | **Archive: `-r` plus preserve everything, including SELinux context and links** |
| `cp -i` | Prompt before overwriting |
| `cp -u` | Only if the source is newer |
| `cp -v` | Verbose |
| `mv src dst` | Move or rename |
| `rm -r`, `rm -f`, `rm -rf` | Recurse, force, both |
| `touch file` | Create empty, or update timestamps |
| `touch -t 202601011200 file` | Set a specific timestamp |

**`cp` gets a fresh SELinux context from the destination's parent; `mv` keeps the original label.** That asymmetry is the cause of half of all SELinux problems — see `SELinux.md`.

### find

| Expression | Matches |
| --- | --- |
| `-name '*.conf'` | Name, case sensitive, quote the glob |
| `-iname` | Case insensitive |
| `-type f` / `d` / `l` / `b` / `c` | File, directory, symlink, block, character |
| `-user alice` / `-uid 1500` | Owner |
| `-group devs` / `-gid 5000` | Group |
| `-nouser` / `-nogroup` | **Orphaned files — an exam favourite** |
| `-size +10M` / `-10k` / `+1G` | Larger than, smaller than |
| `-mtime -7` / `+30` | Modified in the last 7 days / more than 30 days ago |
| `-mmin -60` | Modified in the last hour |
| `-newer file` | Newer than a reference file |
| `-perm 0644` | Exactly these bits |
| **`-perm /4000`** | **Any of these bits — the way to find SUID files** |
| `-perm -0644` | All of these bits, at least |
| `-maxdepth 2`, `-mindepth 1` | Limit recursion |
| `-empty` | Empty files and directories |
| `-regex` | Match the whole path with a regex |

| Action | Effect |
| --- | --- |
| `-print` | Default |
| `-ls` | Like `ls -l` |
| `-delete` | Remove — put it last |
| `-exec cmd {} \;` | Run once per file |
| `-exec cmd {} +` | Batch the arguments — much faster |
| `-exec cp {} /dest/ \;` | The exam's usual pattern |
| `-o`, `-a`, `!`, `\( \)` | or, and, not, grouping |

```bash
find /etc -name '*.conf' -type f -newermt '-10 min'
find /home -perm /4000 -type f 2>/dev/null
find /var/log -name '*.log' -mtime +30 -exec gzip {} +
find / -nouser -o -nogroup 2>/dev/null
sudo find / -name core -type f -delete
```

Related:

```bash
which command ; whereis command ; type command
locate pattern ; sudo updatedb            # needs mlocate
```

### Redirection and pipes

| Form | Meaning |
| --- | --- |
| `>` | stdout to a file, truncating |
| `>>` | stdout to a file, appending |
| `2>` | **stderr to a file** |
| `2>>` | stderr, appending |
| `&>` or `>&` | **Both streams** |
| `&>>` | Both, appending |
| `2>&1` | stderr into wherever stdout currently goes |
| `1>&2` or `>&2` | **stdout to stderr — for error messages in scripts** |
| `<` | stdin from a file |
| `<<EOF ... EOF` | Here-document |
| `<<'EOF'` | **Here-document with no variable expansion** |
| `<<<"string"` | Here-string |
| `\|` | stdout into the next command |
| `\|&` | Both streams into the next command |
| `2>/dev/null` | Discard errors |
| `&>/dev/null` | Discard everything |

```bash
command > out.txt 2> err.txt
command &> all.txt
command 2>&1 | tee log.txt          # order matters: redirect AFTER the pipe target
command | tee file | wc -l
command | tee -a file               # append
sudo tee /etc/x.conf <<'EOF'        # the way to write a root-owned file
content
EOF
```

**`cmd 2>&1 > file` does not do what you expect.** `2>&1` copies the *current* stdout, which is still the terminal. Write `cmd > file 2>&1`.

**`echo x | sudo tee /etc/file` is how you append as root.** `sudo echo x >> /etc/file` fails — the shell opens the file before `sudo` runs.

### grep and regular expressions

| Flag | Effect |
| --- | --- |
| `-i` | Case insensitive |
| `-v` | **Invert: lines that do not match** |
| `-n` | Line numbers |
| `-c` | Count matching lines |
| `-l` / `-L` | Files with / without matches |
| `-r` / `-R` | Recurse (`-R` follows symlinks) |
| `-w` | Whole word |
| `-x` | Whole line |
| `-q` | **Quiet: exit status only — for scripts** |
| `-o` | Print only the matched part |
| `-A3`, `-B3`, `-C3` | Lines after, before, around |
| `-E` | Extended regex (same as `egrep`) |
| `-F` | Fixed strings, no regex |
| `-e p1 -e p2` | Multiple patterns |
| `-f file` | Patterns from a file |
| `--color=auto` | Highlight |
| `-h` / `-H` | Suppress / force filenames |

| Regex | Matches |
| --- | --- |
| `^` / `$` | Start / end of line |
| `.` | Any single character |
| `*` | Zero or more of the previous |
| `\+` / `+` (with `-E`) | One or more |
| `\?` / `?` | Zero or one |
| `[abc]`, `[^abc]`, `[a-z]` | Character class, negated, range |
| `[[:digit:]]`, `[[:alpha:]]`, `[[:space:]]`, `[[:upper:]]` | POSIX classes |
| `\{3\}` / `{3}` | Exactly three |
| `\{2,4\}` / `{2,4}` | Between two and four |
| `\|` / `\|` (with `-E`) | Alternation |
| `\( \)` / `( )` | Grouping |
| `\<` `\>` or `\b` | Word boundaries |
| `\.` | A literal dot |

```bash
grep -E '^[[:digit:]]{3}-[[:digit:]]{4}$' file
grep -v '^\s*#' /etc/ssh/sshd_config | grep -v '^$'      # strip comments and blanks
grep -rn 'password' /etc 2>/dev/null
grep -c '' file                                          # count lines
if grep -q '^root' /etc/passwd; then echo found; fi
```

### Archiving and compression

| Command | Effect |
| --- | --- |
| `tar -cvf a.tar dir` | Create |
| `tar -xvf a.tar` | Extract |
| `tar -tvf a.tar` | **List without extracting** |
| `tar -rvf a.tar file` | Append to an uncompressed archive |
| **`-z`** | gzip (`.tar.gz`, `.tgz`) |
| **`-j`** | bzip2 (`.tar.bz2`) |
| **`-J`** | xz (`.tar.xz`) |
| `-C /dest` | **Change directory — extract or create relative to here** |
| `-p` | Preserve permissions |
| `--xattrs --selinux` | **Preserve SELinux context** |
| `--exclude='*.log'` | Skip matches |
| `-f -` | Use stdin/stdout |

```bash
tar -czvf /tmp/etc.tar.gz /etc
tar -tzvf /tmp/etc.tar.gz | head
tar -xzvf /tmp/etc.tar.gz -C /restore
tar -cJvf /tmp/home.tar.xz --exclude='*.cache' /home
sudo tar --xattrs --selinux -czvf web.tar.gz /var/www/html
```

| Command | Effect |
| --- | --- |
| `gzip file` / `gunzip file.gz` | Compress / decompress **replacing** the original |
| `gzip -k file` | Keep the original |
| `gzip -9` | Maximum compression |
| `zcat`, `bzcat`, `xzcat` | Read a compressed file without decompressing |
| `bzip2` / `bunzip2` | Smaller, slower |
| `xz` / `unxz` | Smallest, slowest |
| `zless`, `zgrep` | Page and grep compressed files |

**Extracting a tarball loses SELinux labels unless `--selinux` was used to create it.** After extracting into a labelled directory, run `restorecon -Rv`.

### Links

```bash
ln target hardlink                    # same inode, same filesystem only, files only
ln -s target symlink                 # a pointer; can cross filesystems; can dangle
ln -sf newtarget existinglink        # replace a symlink
ls -li                               # inode numbers: identical means hard-linked
stat file | grep Links               # link count
readlink -f symlink                  # the fully resolved target
find /path -inum 12345               # find every name for one inode
find / -xtype l                      # broken symlinks
```

| | Hard link | Symbolic link |
| --- | --- | --- |
| Inode | **Same** | Its own |
| Across filesystems | **No** | Yes |
| To a directory | **No** | Yes |
| Survives deleting the target | **Yes** | **No — dangles** |
| `ls -l` shows | A normal file | `link -> target` |

### Permissions

```bash
chmod 755 file ; chmod 0755 file
chmod u=rwx,g=rx,o= file
chmod u+x,g-w,o-rwx file
chmod a+r file
chmod -R g+rwX dir                   # X = directories and already-executable only
chmod --reference=file1 file2
chown alice file ; chown alice:devs file ; chown :devs file ; chown -R alice: dir
chown --reference=file1 file2
chgrp devs file
umask ; umask -S ; umask 0027
```

| Value | Meaning |
| --- | --- |
| `4` `2` `1` | read, write, execute |
| `7` `6` `5` `4` `0` | rwx, rw-, r-x, r--, --- |
| **`x` on a directory** | **Permission to enter it — without it, nothing inside is reachable** |
| **`w` on a directory** | **Permission to create and delete entries inside it** |

Default `umask`: `022` for root, `002` for regular users with a private group. New files never get execute permission from `umask`, so `666 - umask` for files and `777 - umask` for directories.

Persistent `umask`:

```bash
echo 'umask 0027' | sudo tee /etc/profile.d/custom-umask.sh
# or ~/.bashrc for one user, /etc/login.defs UMASK for login sessions
```

### Documentation

```bash
man command ; man 5 passwd ; man -a passwd
man -k keyword ; apropos keyword ; whatis command
man -f command
sudo mandb                           # rebuild the index if man -k finds nothing
info command ; pinfo command
ls /usr/share/doc/                   # per-package documentation and examples
ls /usr/share/doc/httpd/
rpm -qd httpd                        # documentation files in a package
command --help ; help builtin
```

| Section | Contents |
| --- | --- |
| 1 | User commands |
| 5 | **File formats — `man 5 fstab`, `man 5 crontab`, `man 5 sudoers`, `man 5 exports`** |
| 8 | **Administration commands** |

**The exam has no internet, so `man` is your only reference. Practise with it.** The highest-value pages: `man 5 fstab`, `man 5 crontab`, `man 5 exports`, `man 5 nfs`, `man 5 autofs`, `man nmcli-examples`, `man firewall-cmd`, `man semanage-fcontext`, `man podman-run`, `man 7 systemd.time`.

```bash
man -k . | grep -i selinux           # find SELinux pages
man semanage-fcontext                # per-subcommand pages exist
```

### vim

See `Vim.md`. The minimum: `i` insert, `Esc`, `:wq` write and quit, `:q!` discard, `dd` delete a line, `u` undo, `/text` search, `:%s/a/b/g` replace all, `:set nu`.

### SSH

```bash
ssh alice@server2
ssh -p 2222 alice@server2
ssh -i ~/.ssh/id_ed25519 alice@server2
ssh -v alice@server2                  # debug
ssh alice@server2 'hostname; uptime'  # run a command and exit
ssh-keygen -t ed25519 -C 'comment'
ssh-keygen -t rsa -b 4096 -N ''       # empty passphrase
ssh-copy-id alice@server2
ssh-copy-id -i ~/.ssh/id_ed25519.pub alice@server2
ssh-keyscan server2 >> ~/.ssh/known_hosts
```

| Path | Permissions |
| --- | --- |
| `~/.ssh` | **700** |
| `~/.ssh/authorized_keys` | **600** |
| `~/.ssh/id_ed25519` | **600** |
| `~/.ssh/id_ed25519.pub` | 644 |

**Wrong permissions make key authentication fail silently and fall back to a password.** `ssh-copy-id` sets them correctly.

Server side, `/etc/ssh/sshd_config`:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers alice bob
Port 2222
```

```bash
sudo sshd -t                          # syntax check — do this BEFORE reloading
sudo systemctl reload sshd
sudo semanage port -a -t ssh_port_t -p tcp 2222     # non-standard port
sudo firewall-cmd --permanent --add-port=2222/tcp && sudo firewall-cmd --reload
```

Transfer:

```bash
scp file alice@server2:/tmp/
scp alice@server2:/tmp/file .
scp -r dir alice@server2:/tmp/
scp -p file alice@server2:/tmp/       # preserve times and modes
rsync -av dir/ alice@server2:/dest/   # trailing slash = contents of dir
rsync -avz --delete dir/ alice@server2:/dest/
rsync -av --progress large alice@server2:/tmp/
sftp alice@server2
```

**A trailing slash on the rsync source copies the *contents*; without it you get the directory itself nested inside the destination.**

---

## Manage users and groups

```bash
sudo useradd alice
sudo useradd -u 1500 -g devs -G wheel,ops -c "Alice A" -s /bin/bash -m -d /home/alice alice
sudo useradd -r -s /sbin/nologin -M svcuser        # system account, no home
sudo useradd -e 2026-12-31 -f 14 tempuser          # expiry, inactive days
sudo usermod -aG wheel alice                       # APPEND
sudo usermod -G wheel alice                        # REPLACES every secondary group
sudo usermod -g newprimary alice
sudo usermod -l newname oldname
sudo usermod -d /new/home -m alice                 # -m moves the contents
sudo usermod -s /sbin/nologin alice
sudo usermod -L alice ; sudo usermod -U alice      # lock / unlock the password
sudo usermod -e 2026-12-31 alice
sudo userdel alice ; sudo userdel -r alice         # -r removes home and mail spool
```

| `useradd` flag | Meaning |
| --- | --- |
| `-u` | UID |
| `-g` | **Primary group** |
| `-G` | **Secondary groups, comma separated** |
| `-c` | Comment / full name |
| `-s` | Shell |
| `-m` / `-M` | Create / do not create the home directory |
| `-d` | Home directory path |
| `-r` | System account (UID below 1000, no home by default) |
| `-e` | Account expiry date |
| `-f` | Inactive days after password expiry |
| `-N` | Do not create a user private group |

```bash
sudo groupadd devs ; sudo groupadd -g 5000 devs ; sudo groupadd -r sysgrp
sudo groupmod -n newname oldname ; sudo groupmod -g 5001 devs
sudo groupdel devs
sudo gpasswd -a alice devs ; sudo gpasswd -d alice devs
sudo gpasswd -A alice devs                         # group administrator
id ; id alice ; id -u ; id -g ; id -G ; id -nG
groups ; groups alice
getent passwd alice ; getent group devs ; getent shadow alice
lslogins ; who ; w ; last ; lastlog ; lastb
su - alice ; su alice ; sudo -i ; sudo -u alice command ; sudo -i -u alice
```

**`su - alice` gives a full login environment; `su alice` keeps yours.** For `systemctl --user` you need the dash.

Files:

| File | Contents |
| --- | --- |
| `/etc/passwd` | `name:x:UID:GID:comment:home:shell` |
| `/etc/shadow` | `name:hash:lastchange:min:max:warn:inactive:expire:` |
| `/etc/group` | `name:x:GID:members` |
| `/etc/gshadow` | Group passwords and administrators |
| `/etc/login.defs` | Defaults for **new** accounts |
| `/etc/default/useradd` | `useradd` defaults |
| `/etc/skel/` | **Copied into every new home directory** |

```bash
sudo pwck ; sudo grpck                             # consistency check
sudo vipw ; sudo vigr                              # safe editing with locking
```

Passwords and aging:

```bash
sudo passwd alice
echo 'RedHat123' | sudo passwd --stdin alice
sudo passwd -l alice ; sudo passwd -u alice        # lock / unlock
sudo passwd -e alice                               # expire now
sudo passwd -S alice                               # status
sudo passwd -n 7 -x 60 -w 7 -i 14 alice            # same as chage
sudo chage -m 7 -M 60 -W 7 -I 14 -E 2026-12-31 alice
sudo chage -l alice
sudo chage -d 0 alice                              # must change at next login
sudo chage -E -1 alice                             # never expire
```

sudo:

```bash
sudo visudo                                        # /etc/sudoers, syntax-checked
sudo visudo -f /etc/sudoers.d/devs                 # a drop-in, the better way
sudo visudo -c                                     # verify all files
sudo -l ; sudo -l -U alice
sudo -v ; sudo -k                                  # refresh / invalidate the timestamp
```

```text
alice   ALL=(ALL)       ALL
%devs   ALL=(ALL)       ALL
%ops    ALL=(ALL)       NOPASSWD: ALL
alice   ALL=(root)      /usr/bin/systemctl restart httpd, /usr/bin/systemctl status httpd
alice   ALL=(ALL)       !/usr/bin/passwd root
Defaults:alice          timestamp_timeout=0
```

**Never edit `/etc/sudoers` with plain `vim`.** A syntax error there locks out all sudo access. `visudo` refuses to save a broken file.

Special permissions and ACLs:

```bash
chmod u+s file ; chmod 4755 file                   # SUID
chmod g+s dir  ; chmod 2775 dir                    # SGID — group inheritance
chmod +t dir   ; chmod 1777 dir                    # sticky — owner-only deletion
find / -perm /6000 -type f 2>/dev/null             # audit SUID and SGID
setfacl -m u:alice:rwx file
setfacl -m g:devs:rx file
setfacl -m o::--- file
setfacl -m m::rx file                              # the mask
setfacl -R -m u:alice:rX dir
setfacl -m d:u:alice:rwx dir                       # DEFAULT: applies to new entries
setfacl -x u:alice file
setfacl -b file                                    # remove all ACLs
setfacl --set-file=acl.txt file
getfacl file ; getfacl -R dir ; getfacl dir > acl.txt
```

**The collaborative directory recipe:**

```bash
sudo groupadd devs
sudo mkdir -p /shared/devs
sudo chown root:devs /shared/devs
sudo chmod 2770 /shared/devs                       # SGID + group rwx, nothing for others
sudo setfacl -m d:g:devs:rwx /shared/devs          # optional, belt and braces
ls -ld /shared/devs                                # drwxrws---
```

---

## Operate running systems

### Processes

```bash
ps aux ; ps -ef ; ps -eF ; ps -eo pid,ppid,user,%cpu,%mem,stat,comm
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10
ps -u alice ; ps -C httpd ; ps -p 1234 ; ps -ejH ; pstree -p
top       # then: P cpu, M memory, k kill, r renice, u user, 1 per-CPU, q quit
htop
uptime ; w ; free -h ; vmstat 1 5 ; iostat ; sar ; lscpu ; lsmem
pidof httpd ; pgrep httpd ; pgrep -u alice -a ; pgrep -f 'python script'
kill PID ; kill -15 PID ; kill -TERM PID          # polite
kill -9 PID ; kill -KILL PID                      # last resort
kill -1 PID ; kill -HUP PID                       # reload
kill -l                                            # list signals
killall httpd ; killall -9 httpd
pkill -u alice ; pkill -f pattern ; pkill -HUP rsyslogd
nice -n 10 command                                 # start with a nice value
sudo nice -n -5 command                            # negative needs root
sudo renice -n -5 -p 1234
sudo renice -n 10 -u alice
ps -eo pid,ni,comm | head
command & ; jobs ; fg %1 ; bg %1 ; Ctrl-Z ; Ctrl-C ; disown ; nohup cmd &
lsof -p 1234 ; lsof /path ; fuser -vm /mount
sudo systemd-cgtop
ulimit -a ; ulimit -n 4096
```

| Nice value | Meaning |
| --- | --- |
| **-20** | Highest priority, root only |
| 0 | Default |
| **+19** | Lowest priority |

### systemd services

```bash
systemctl status httpd ; systemctl status                  # whole system
sudo systemctl start/stop/restart/reload httpd
sudo systemctl reload-or-restart httpd
sudo systemctl enable httpd ; sudo systemctl disable httpd
sudo systemctl enable --now httpd                          # THE exam command
sudo systemctl disable --now httpd
systemctl is-enabled httpd ; systemctl is-active httpd ; systemctl is-failed httpd
sudo systemctl mask httpd ; sudo systemctl unmask httpd
sudo systemctl daemon-reload                               # after unit file changes
sudo systemctl reset-failed ; sudo systemctl reset-failed httpd
systemctl list-units ; systemctl list-units --type=service --state=running
systemctl list-unit-files --state=enabled
systemctl list-dependencies httpd ; systemctl list-dependencies --reverse httpd
systemctl --failed
systemctl cat httpd ; systemctl show httpd ; systemctl show httpd -p Restart
sudo systemctl edit httpd                                  # drop-in override
sudo systemctl edit --full httpd                           # copy and edit the whole unit
systemctl kill httpd ; systemctl kill -s SIGKILL httpd
```

| Unit directory | Purpose |
| --- | --- |
| `/usr/lib/systemd/system/` | **Package-provided — do not edit** |
| **`/etc/systemd/system/`** | **Your units and overrides — wins** |
| `/run/systemd/system/` | Runtime, transient |
| `~/.config/systemd/user/` | **User units** |
| `/etc/systemd/system/httpd.service.d/override.conf` | Drop-in |

| `is-enabled` output | Meaning |
| --- | --- |
| `enabled` | **Starts at boot** |
| `disabled` | Does not |
| **`masked`** | **Cannot be started at all** |
| `static` | No `[Install]` section; enabled by a dependency |
| `indirect` | Enabled through an alias |
| `enabled-runtime` | Only until reboot |

### Targets and boot

```bash
systemctl get-default
sudo systemctl set-default multi-user.target               # PERSISTENT
sudo systemctl set-default graphical.target
sudo systemctl isolate multi-user.target                  # NOW, not persistent
sudo systemctl isolate rescue.target
systemctl list-units --type=target
systemctl list-dependencies multi-user.target
sudo systemctl reboot ; sudo systemctl poweroff ; sudo systemctl halt
sudo systemctl suspend ; sudo systemctl hibernate
sudo shutdown -h now ; sudo shutdown -r +5 "Rebooting in 5" ; sudo shutdown -c
sudo reboot ; sudo poweroff
systemd-analyze ; systemd-analyze blame ; systemd-analyze critical-chain
who -r ; runlevel
```

| Target | Old runlevel |
| --- | --- |
| `poweroff.target` | 0 |
| `rescue.target` | 1, single user |
| `multi-user.target` | 3, text mode |
| `graphical.target` | 5 |
| `reboot.target` | 6 |
| `emergency.target` | Minimal, root filesystem read-only |

### Boot interruption and recovery

**Root password reset:**

```text
1. Reboot; at the GRUB menu press  e
2. Find the line starting  linux  and append:  rd.break
3. Ctrl-x
4. mount -o remount,rw /sysroot
5. chroot /sysroot
6. passwd root
7. touch /.autorelabel          ← REQUIRED
8. exit
9. exit
```

Alternatives to append at GRUB:

| Argument | Effect |
| --- | --- |
| **`rd.break`** | **Stop in the initramfs, before `/sysroot` is switched to** |
| `init=/bin/bash` | Boot straight to a shell as PID 1 |
| `systemd.unit=rescue.target` | Single-user mode, needs the root password |
| `systemd.unit=emergency.target` | Minimal shell |
| `systemd.debug-shell=1` | A debug shell on tty9 |
| `enforcing=0` | **Boot with SELinux permissive — use when a bad label blocks boot** |
| `3` or `1` | Legacy runlevel-style targets |

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grubby --update-kernel=ALL --args="console=ttyS0"
sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"
sudo grubby --info=ALL ; sudo grubby --default-kernel ; sudo grubby --set-default=...
sudo grub2-set-default 0 ; grub2-editenv list
sudo grub2-install /dev/sda                       # BIOS only
sudo dnf reinstall grub2-efi grub2-efi-modules shim   # UEFI repair
```

`/etc/default/grub`:

```text
GRUB_TIMEOUT=5
GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=rhel/root rhgb quiet"
GRUB_ENABLE_BLSCFG=true
GRUB_DEFAULT=saved
```

**After editing `/etc/default/grub` you must run `grub2-mkconfig`.** The file alone changes nothing.

### Logs

```bash
journalctl
journalctl -n 50 ; journalctl -f ; journalctl -r          # last 50, follow, reverse
journalctl -u httpd ; journalctl -u httpd -u sshd
journalctl -xeu httpd                                      # WHY it failed
journalctl -b ; journalctl -b -1 ; journalctl --list-boots
journalctl -k ; journalctl --dmesg
journalctl -p err ; journalctl -p 0..3 ; journalctl -p warning..err
journalctl --since '09:00' --until '10:00'
journalctl --since yesterday ; journalctl --since '2 hours ago'
journalctl _PID=1234 ; journalctl _UID=1000 ; journalctl _COMM=sshd
journalctl /usr/sbin/sshd ; journalctl /dev/sda
journalctl -o verbose ; journalctl -o json-pretty ; journalctl -o short-precise
journalctl --no-pager ; journalctl --disk-usage
sudo journalctl --vacuum-time=2weeks ; sudo journalctl --vacuum-size=500M
sudo journalctl --verify
```

| Priority | Number |
| --- | --- |
| emerg, alert, crit | 0, 1, 2 |
| **err** | **3** |
| warning | 4 |
| notice, info, debug | 5, 6, 7 |

**Persistent journal:**

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo chown root:systemd-journal /var/log/journal
sudo chmod 2755 /var/log/journal
sudo systemctl restart systemd-journald
journalctl --list-boots                                    # >1 boot proves it
```

Or in `/etc/systemd/journald.conf`:

```text
[Journal]
Storage=persistent
SystemMaxUse=500M
MaxRetentionSec=1month
```

rsyslog:

```bash
sudo vim /etc/rsyslog.conf ; ls /etc/rsyslog.d/
sudo rsyslogd -N1                                          # SYNTAX CHECK
sudo systemctl restart rsyslog
logger "test message" ; logger -p local0.info "test"
sudo tail -f /var/log/messages
```

```text
# facility.priority                    destination
*.info;mail.none;authpriv.none;cron.none   /var/log/messages
authpriv.*                                 /var/log/secure
*.emerg                                    :omusrmsg:*
local7.*                                   /var/log/boot.log
kern.*                                     /var/log/kern.log
*.*                                        @@loghost:514
```

| Log file | Contents |
| --- | --- |
| `/var/log/messages` | General system messages |
| **`/var/log/secure`** | **Authentication, sudo, SSH** |
| `/var/log/maillog` | Mail |
| `/var/log/cron` | cron |
| `/var/log/boot.log` | Boot |
| **`/var/log/audit/audit.log`** | **auditd — where SELinux AVC denials go** |
| `/var/log/dnf.log` | Package transactions |

Log rotation: `/etc/logrotate.conf`, `/etc/logrotate.d/`, `sudo logrotate -d /etc/logrotate.conf` for a dry run.

### Scheduling

```bash
crontab -e ; crontab -l ; crontab -r ; crontab -i -r
sudo crontab -e -u alice ; sudo crontab -l -u alice
sudo systemctl enable --now crond
```

```text
# ┌─ minute (0-59)
# │ ┌─ hour (0-23)
# │ │ ┌─ day of month (1-31)
# │ │ │ ┌─ month (1-12)
# │ │ │ │ ┌─ day of week (0-7, 0 and 7 = Sunday)
  30 2 * * *   /usr/local/bin/backup.sh
  */5 * * * *  /usr/local/bin/check.sh
  0 9 * * 1-5  /usr/local/bin/weekday.sh
  0 0 1 * *    /usr/local/bin/monthly.sh
  @daily       /usr/local/bin/daily.sh
  @reboot      /usr/local/bin/atboot.sh
```

| Location | Format |
| --- | --- |
| `crontab -e` | **No user field** |
| **`/etc/crontab`** | **Has a user field** |
| **`/etc/cron.d/name`** | **Has a user field — the best place for a system job** |
| `/etc/cron.hourly/`, `.daily/`, `.weekly/`, `.monthly/` | **Executable scripts, no schedule line, must be `chmod +x`** |
| `/var/spool/cron/USER` | Where `crontab -e` actually writes |

```bash
echo "/usr/local/bin/once.sh" | at 14:30
at now + 5 minutes ; at 10:00 tomorrow ; at 3:00 PM Friday
atq ; at -l ; atrm 3 ; at -c 3
sudo systemctl enable --now atd
```

Access control: `/etc/cron.allow` and `/etc/cron.deny`; `/etc/at.allow` and `/etc/at.deny`. **If `.allow` exists, only listed users may schedule and `.deny` is ignored.**

systemd timers:

```bash
systemctl list-timers ; systemctl list-timers --all
sudo systemctl enable --now backup.timer                  # the TIMER, not the service
systemctl status backup.timer ; systemctl cat backup.timer
sudo systemd-analyze calendar 'Mon *-*-* 02:00:00'
sudo systemctl start backup.service                       # test the job now
```

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Backup job
[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Run backup nightly
[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
RandomizedDelaySec=300
[Install]
WantedBy=timers.target
```

| `OnCalendar` | Meaning |
| --- | --- |
| `hourly`, `daily`, `weekly`, `monthly` | Shorthand |
| `*-*-* 02:00:00` | Every day at 02:00 |
| `Mon..Fri 09:00` | Weekdays |
| `*-*-01 00:00:00` | The first of every month |
| `Sat *-*-* 03:30:00` | Saturdays |

**`Persistent=true` runs a missed job after the machine comes back up.** That is the behaviour `anacron` gave you.

### tuned

```bash
sudo dnf install -y tuned
sudo systemctl enable --now tuned
tuned-adm active ; tuned-adm list ; tuned-adm recommend ; tuned-adm verify
sudo tuned-adm profile virtual-guest
sudo tuned-adm profile throughput-performance
sudo tuned-adm profile balanced powersave              # combined
sudo tuned-adm off
ls /usr/lib/tuned/ ; ls /etc/tuned/
```

| Profile | For |
| --- | --- |
| `balanced` | Default general purpose |
| `throughput-performance` | Maximum throughput |
| `latency-performance` | Low latency |
| `powersave` | Battery |
| **`virtual-guest`** | **A VM — the usual answer in a lab** |
| `virtual-host` | A hypervisor |

**`tuned-adm profile` is already persistent** — it writes `/etc/tuned/active_profile`. But `tuned` itself must be enabled.

---

## Deploy, configure, and maintain systems

### Time

```bash
timedatectl ; timedatectl status
timedatectl list-timezones ; timedatectl list-timezones | grep -i africa
sudo timedatectl set-timezone Africa/Nairobi
sudo timedatectl set-time '2026-08-18 12:00:00'
sudo timedatectl set-ntp true ; sudo timedatectl set-ntp false
sudo timedatectl set-local-rtc 0
date ; date +'%Y-%m-%d %H:%M:%S' ; hwclock ; sudo hwclock --systohc
chronyc sources ; chronyc sources -v ; chronyc tracking ; chronyc sourcestats
chronyc ntpdata ; sudo chronyc makestep
sudo systemctl enable --now chronyd
sudo vim /etc/chrony.conf
```

```text
server classroom.example.com iburst
pool 2.rhel.pool.ntp.org iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.56.0/24          # act as a server for this subnet
```

**`iburst` makes the first sync fast — always include it.** After editing, `sudo systemctl restart chronyd` then `chronyc sources -v`. The `^*` marker means synchronised.

### Software

```bash
sudo dnf install httpd ; sudo dnf install -y httpd vim
sudo dnf remove httpd ; sudo dnf autoremove
sudo dnf update ; sudo dnf update httpd ; sudo dnf upgrade
sudo dnf downgrade httpd ; sudo dnf reinstall httpd
dnf search web server ; dnf search all keyword
dnf info httpd ; dnf list installed ; dnf list available ; dnf list httpd
dnf provides /usr/sbin/httpd ; dnf provides '*/semanage'
dnf repoquery -l httpd ; dnf repoquery --requires httpd
dnf repolist ; dnf repolist --all ; dnf repolist -v
dnf group list ; dnf group info "Development Tools"
sudo dnf group install "Development Tools" ; sudo dnf group remove ...
dnf history ; dnf history info 5 ; sudo dnf history undo 5 ; sudo dnf history redo 5
sudo dnf clean all ; sudo dnf makecache
sudo dnf localinstall ./package.rpm ; sudo dnf install ./package.rpm
sudo dnf module list ; sudo dnf module list nodejs
sudo dnf module install nodejs:20 ; sudo dnf module reset nodejs
sudo dnf module enable nodejs:20 ; sudo dnf module switch-to nodejs:20
sudo dnf needs-restarting ; sudo dnf needs-restarting -r
```

**`dnf provides */filename` is how you find the package for a missing command.** Learn it — it is faster than guessing.

```bash
rpm -qa ; rpm -qa | grep httpd ; rpm -qa --last
rpm -qi httpd ; rpm -ql httpd ; rpm -qc httpd ; rpm -qd httpd
rpm -qf /etc/httpd/conf/httpd.conf                    # which package owns this file
rpm -q --changelog httpd ; rpm -q --scripts httpd
rpm -qp --qf '%{NAME} %{VERSION}\n' pkg.rpm
rpm -qpl pkg.rpm ; rpm -qpi pkg.rpm                   # inspect an uninstalled rpm
rpm -V httpd ; rpm -Va                                # verify against the database
sudo rpm -ivh pkg.rpm ; sudo rpm -Uvh pkg.rpm ; sudo rpm -e pkg
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
rpm2cpio pkg.rpm | cpio -idmv                         # extract without installing
```

| `rpm -V` output | Meaning |
| --- | --- |
| `S` | Size differs |
| `M` | **Mode (permissions) differs** |
| `5` | **MD5 checksum differs — the file was modified** |
| `T` | Timestamp |
| `U`, `G` | Owner, group |
| `c` | It is a config file (expected to change) |

Repositories — the persistent form is a file in `/etc/yum.repos.d/`:

```bash
sudo dnf config-manager --add-repo http://host/path      # RHEL 8/9
sudo dnf config-manager addrepo --from-repofile=http://... # RHEL 10
sudo dnf config-manager --set-enabled reponame
sudo dnf config-manager --set-disabled reponame
sudo dnf --disablerepo='*' --enablerepo=local install httpd
```

```ini
# /etc/yum.repos.d/local.repo
[local-baseos]
name=Local BaseOS
baseurl=file:///mnt/BaseOS
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[local-appstream]
name=Local AppStream
baseurl=file:///mnt/AppStream
enabled=1
gpgcheck=0
```

**Mounting the ISO persistently as a repository source:**

```bash
sudo mkdir /mnt/iso
echo "/root/rhel10.iso /mnt/iso iso9660 loop,ro,nofail 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo dnf clean all && dnf repolist
```

### Flatpak

```bash
sudo dnf install -y flatpak
flatpak remotes ; flatpak remotes -d
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-add --if-not-exists --no-gpg-verify local file:///srv/flatpak
sudo flatpak remote-delete flathub
sudo flatpak remote-modify --disable flathub
flatpak remote-ls flathub ; flatpak remote-ls flathub --app
flatpak search calculator
sudo flatpak install flathub org.gnome.Calculator         # SYSTEM-wide
flatpak install --user flathub org.gnome.Calculator       # THIS USER only
flatpak list ; flatpak list --app ; flatpak list --runtime
flatpak list --system ; flatpak list --user
flatpak info org.gnome.Calculator
flatpak run org.gnome.Calculator
sudo flatpak update ; sudo flatpak update org.gnome.Calculator
sudo flatpak uninstall org.gnome.Calculator
sudo flatpak uninstall --unused                           # remove orphaned runtimes
flatpak override --user --filesystem=home org.gnome.Calculator
flatpak permissions ; flatpak history
```

| | System | User |
| --- | --- | --- |
| Command | `sudo flatpak install` | `flatpak install --user` |
| Remotes | `/etc/flatpak/remotes.d/` | `~/.local/share/flatpak/repo/` |
| Apps | `/var/lib/flatpak/app/` | `~/.local/share/flatpak/app/` |
| Available to | **Everyone** | **That user only** |

**Read the task wording carefully: "for all users" means `sudo flatpak install`; "for user alice" means `flatpak install --user` as alice.**

---

## Manage basic networking

```bash
nmcli device status ; nmcli device show ; nmcli device show ens160
nmcli connection show ; nmcli con show --active ; nmcli con show ens160
nmcli -f NAME,UUID,TYPE,DEVICE,AUTOCONNECT con show
nmcli general status ; nmcli general hostname ; nmcli radio all
ip addr ; ip -brief addr ; ip -4 addr ; ip -6 addr
ip link ; ip route ; ip -6 route ; ip neigh
ss -tuln ; ss -tulnp ; ss -tan state established
ping -c3 host ; ping6 -c3 host ; traceroute host ; tracepath host
nmap -p 80 host                                    # if installed
curl -I http://host ; curl -v telnet://host:80
```

```bash
sudo nmcli con add type ethernet con-name static-ens160 ifname ens160 \
  ipv4.method manual ipv4.addresses 192.168.56.11/24 \
  ipv4.gateway 192.168.56.1 ipv4.dns "192.168.56.1 8.8.8.8" \
  ipv4.dns-search example.com autoconnect yes

sudo nmcli con mod ens160 ipv4.method manual
sudo nmcli con mod ens160 ipv4.addresses 192.168.56.11/24
sudo nmcli con mod ens160 +ipv4.addresses 10.0.0.5/24        # add a second address
sudo nmcli con mod ens160 -ipv4.addresses 10.0.0.5/24        # remove one
sudo nmcli con mod ens160 ipv4.gateway 192.168.56.1
sudo nmcli con mod ens160 ipv4.dns "8.8.8.8 8.8.4.4"
sudo nmcli con mod ens160 +ipv4.dns 1.1.1.1
sudo nmcli con mod ens160 ipv4.dns-search example.com
sudo nmcli con mod ens160 ipv4.never-default yes
sudo nmcli con mod ens160 connection.autoconnect yes
sudo nmcli con mod ens160 ipv4.method auto                    # back to DHCP
sudo nmcli con mod ens160 ipv6.method manual \
  ipv6.addresses 2001:db8::11/64 ipv6.gateway 2001:db8::1
sudo nmcli con up ens160 ; sudo nmcli con down ens160
sudo nmcli con reload                                          # re-read keyfiles
sudo nmcli device reapply ens160                               # apply without dropping
sudo nmcli con delete static-ens160
sudo nmcli device connect ens160 ; sudo nmcli device disconnect ens160
sudo nmtui                                                     # menu-driven fallback
sudo systemctl enable --now NetworkManager
```

| `ipv4.method` | Meaning |
| --- | --- |
| `auto` | DHCP |
| **`manual`** | **Static — required when you set an address** |
| `disabled` | No IPv4 |
| `link-local` | 169.254.x.x |

**`nmcli con mod` writes the keyfile; `nmcli con up` activates it. You need both.** Keyfiles live in `/etc/NetworkManager/system-connections/`.

Hostname and resolution:

```bash
hostnamectl ; hostnamectl status
sudo hostnamectl set-hostname server1.lab.example.com
sudo hostnamectl set-hostname --pretty "Lab Server 1"
hostname ; hostname -f ; hostname -I ; cat /etc/hostname
getent hosts server2 ; getent ahosts server2
dig server2.lab.example.com ; dig +short server2 ; dig -x 192.168.56.12
dig @8.8.8.8 example.com ; dig example.com MX ; dig example.com AAAA
host server2 ; host -t MX example.com ; nslookup server2
cat /etc/hosts ; cat /etc/resolv.conf ; grep hosts /etc/nsswitch.conf
resolvectl status                                    # if systemd-resolved is in use
```

**`/etc/resolv.conf` is generated by NetworkManager.** Editing it directly does not persist. Set DNS with `nmcli con mod ... ipv4.dns` instead. To take manual control:

```bash
sudo nmcli con mod ens160 ipv4.ignore-auto-dns yes
# or globally: dns=none in /etc/NetworkManager/NetworkManager.conf
```

**`getent hosts` consults `/etc/hosts` then DNS; `dig` and `host` query DNS only.** When `getent` works and `dig` does not, the answer came from `/etc/hosts`.

Firewalld:

```bash
sudo firewall-cmd --state ; sudo systemctl status firewalld
sudo firewall-cmd --get-default-zone ; --set-default-zone=public
sudo firewall-cmd --get-active-zones ; --get-zones ; --list-all-zones
sudo firewall-cmd --list-all ; sudo firewall-cmd --zone=public --list-all
sudo firewall-cmd --permanent --list-all
sudo firewall-cmd --get-services ; --info-service=http
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service={http,https,nfs}
sudo firewall-cmd --permanent --remove-service=http
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=6000-6010/udp
sudo firewall-cmd --permanent --zone=trusted --add-source=192.168.56.0/24
sudo firewall-cmd --permanent --zone=public --add-interface=ens160
sudo firewall-cmd --permanent --change-interface=ens160 --zone=internal
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.56.0/24" service name="http" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0/8" reject'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.56.10" port port="3306" protocol="tcp" accept'
sudo firewall-cmd --permanent --add-masquerade
sudo firewall-cmd --permanent --add-forward-port=port=8080:proto=tcp:toport=80
sudo firewall-cmd --permanent --add-icmp-block=echo-request
sudo firewall-cmd --reload
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --complete-reload
sudo firewall-cmd --query-service=http ; --query-port=8080/tcp
sudo firewall-cmd --panic-on ; --panic-off
sudo systemctl enable --now firewalld
```

**Zone selection order: an explicit interface assignment, then a source match, then the default zone.** A source-based zone wins over the interface's zone.

```bash
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
```

**An empty diff means runtime and permanent agree. Run this before every reboot.**

---

## Manage security

### SELinux

```bash
getenforce ; sestatus ; sestatus -v ; sudo setenforce 1 ; sudo setenforce 0
sudo vim /etc/selinux/config                     # SELINUX=enforcing|permissive|disabled
grep ^SELINUX= /etc/selinux/config
ls -Z /var/www/html ; ls -Zd /web ; ps -eZ ; ps -Z ; id -Z ; netstat -Z
sudo semanage fcontext -l ; sudo semanage fcontext -l -C
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
sudo semanage fcontext -a -e /var/www /web                  # equivalency rule
sudo semanage fcontext -m -t httpd_sys_content_t "/web(/.*)?"
sudo semanage fcontext -d "/web(/.*)?"
sudo restorecon -Rv /web ; sudo restorecon -RFv /web
sudo restorecon -Rv /                                        # full relabel
sudo touch /.autorelabel && sudo reboot                      # relabel at boot
sudo chcon -t httpd_sys_content_t /web/index.html            # TEMPORARY
sudo chcon -R --reference=/var/www/html /web
matchpathcon /web ; matchpathcon -V /web/index.html
getsebool -a ; getsebool -a | grep httpd ; getsebool httpd_enable_homedirs
sudo setsebool httpd_enable_homedirs on                      # runtime only
sudo setsebool -P httpd_enable_homedirs on                   # PERSISTENT
sudo semanage boolean -l ; sudo semanage boolean -l -C
sudo semanage port -l ; sudo semanage port -l | grep http
sudo semanage port -a -t http_port_t -p tcp 8090             # ADD a new label
sudo semanage port -m -t http_port_t -p tcp 8090             # MODIFY an existing one
sudo semanage port -d -t http_port_t -p tcp 8090
sudo semanage login -l ; sudo semanage user -l
sudo ausearch -m AVC -ts recent ; sudo ausearch -m AVC -ts today -i
sudo ausearch -m AVC,USER_AVC,SELINUX_ERR -ts recent
sudo aureport -a
sudo sealert -a /var/log/audit/audit.log                     # setroubleshoot-server
sudo journalctl -t setroubleshoot
sudo audit2allow -a ; sudo audit2allow -a -w ; sudo audit2why -a
sudo audit2allow -a -M mypolicy && sudo semodule -i mypolicy.pp
sudo semodule -l ; sudo semodule -d modulename
sudo dnf install -y policycoreutils-python-utils setroubleshoot-server
```

| Package | Provides |
| --- | --- |
| **`policycoreutils-python-utils`** | **`semanage`, `audit2allow`, `audit2why`** |
| `setroubleshoot-server` | `sealert` and friendly journal messages |
| `selinux-policy-doc` | `man httpd_selinux`, `man nfs_selinux`, and so on |

**`man -k _selinux` lists the per-service SELinux manual pages.** `man httpd_selinux` documents every httpd boolean and file type — invaluable with no internet.

Common file types:

| Type | Used for |
| --- | --- |
| `httpd_sys_content_t` | Web content, read-only |
| `httpd_sys_rw_content_t` | Web content the server may write |
| `public_content_t` | Shared read-only (FTP, NFS, Samba) |
| `public_content_rw_t` | Shared read-write |
| `samba_share_t` | Samba shares |
| `container_file_t` | **Podman bind mounts** |
| `user_home_t` | Home directory content |
| `default_t` | The label of an unlabelled new top-level directory |

### Others

`umask`, ACLs, SSH key authentication, and firewalld are all covered above.

---

## Configure local storage and file systems

### Inspection

```bash
lsblk ; lsblk -f ; lsblk -fp ; lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT
sudo blkid ; sudo blkid /dev/sdb1 ; sudo blkid -s UUID -o value /dev/sdb1
sudo fdisk -l ; sudo fdisk -l /dev/sdb
sudo parted -l ; sudo parted /dev/sdb print ; sudo parted /dev/sdb print free
sudo gdisk -l /dev/sdb ; sudo sgdisk -p /dev/sdb
df -h ; df -hT ; df -i ; du -sh /var/* ; du -h --max-depth=1 /var
findmnt ; findmnt /data ; findmnt -t xfs ; findmnt --verify
mount | column -t ; cat /proc/mounts
sudo xfs_info /data ; sudo tune2fs -l /dev/sdb1
lsblk -t ; cat /proc/partitions
```

### Partitioning

```bash
sudo fdisk /dev/sdb
```

| Key | Action |
| --- | --- |
| `m` | Help |
| `p` | Print the table |
| `n` | New partition |
| `d` | Delete |
| `t` | Change the type code |
| `l` | List type codes |
| `g` | **New empty GPT label** |
| `o` | New empty MBR/DOS label |
| `i` | Partition details |
| `F` | Free space |
| **`w`** | **Write and exit** |
| **`q`** | **Quit WITHOUT saving — your escape hatch** |

Type codes worth knowing: `linux` (default, 20 / 83), **`swap`** (19 / 82), **`lvm`** (30 / 8e), `efi` (1 / ef), `raid` (29 / fd).

```bash
sudo partprobe /dev/sdb ; sudo partprobe ; sudo partx -a /dev/sdb
sudo udevadm settle
```

```bash
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mklabel msdos
sudo parted /dev/sdb mkpart primary xfs 1MiB 1GiB
sudo parted /dev/sdb mkpart primary linux-swap 1GiB 2GiB
sudo parted /dev/sdb set 1 lvm on
sudo parted /dev/sdb rm 1
sudo parted /dev/sdb print free
sudo parted /dev/sdb unit MiB print
sudo parted -a optimal /dev/sdb mkpart primary 0% 100%
```

**`parted` writes immediately with no confirmation. `fdisk` writes only on `w`.** For the exam, `fdisk` is safer.

```bash
sudo wipefs -a /dev/sdb1                     # remove filesystem signatures
sudo sgdisk --zap-all /dev/sdb               # wipe both GPT and MBR structures
sudo dd if=/dev/zero of=/dev/sdb bs=1M count=10
```

### LVM

```bash
sudo pvcreate /dev/sdb1 ; sudo pvcreate /dev/sdb1 /dev/sdc1
pvs ; pvs -o+pv_used ; sudo pvdisplay ; sudo pvdisplay /dev/sdb1 ; sudo pvscan
sudo pvremove /dev/sdb1 ; sudo pvmove /dev/sdb1 ; sudo pvresize /dev/sdb1

sudo vgcreate vg01 /dev/sdb1
sudo vgcreate -s 8M vg01 /dev/sdb1           # physical extent size
vgs ; sudo vgdisplay vg01 ; sudo vgscan
sudo vgextend vg01 /dev/sdc1
sudo vgreduce vg01 /dev/sdc1                 # pvmove first if it is in use
sudo vgrename vg01 vgdata ; sudo vgremove vg01

sudo lvcreate -n lv_data -L 500M vg01
sudo lvcreate -n lv_data -L 1G vg01
sudo lvcreate -n lv_data -l 50%FREE vg01
sudo lvcreate -n lv_data -l 100%FREE vg01
sudo lvcreate -n lv_data -l 25 vg01          # 25 extents
sudo lvcreate -s -n lv_snap -L 200M /dev/vg01/lv_data     # snapshot
lvs ; lvs -a -o+devices ; sudo lvdisplay /dev/vg01/lv_data ; sudo lvscan
sudo lvrename vg01 lv_old lv_new
sudo lvremove /dev/vg01/lv_data
```

**Extending — the most-asked storage task:**

```bash
sudo vgs                                     # is there free space in the VG?
sudo vgextend vg01 /dev/sdc1                 # if not, add a PV first
sudo lvextend -r -L +400M /dev/vg01/lv_data
sudo lvextend -r -L 2G /dev/vg01/lv_data     # to an absolute size
sudo lvextend -r -l +100%FREE /dev/vg01/lv_data
```

**`-r` (`--resizefs`) grows the filesystem in the same command. Without it the LV grows and `df` shows no change.**

Manually, if you forget `-r`:

```bash
sudo xfs_growfs /data                        # MOUNT POINT; must be mounted
sudo resize2fs /dev/vg01/lv_data             # DEVICE; can be unmounted
```

Shrinking, ext4 only:

```bash
sudo umount /data
sudo e2fsck -f /dev/vg01/lv_data
sudo resize2fs /dev/vg01/lv_data 500M
sudo lvreduce -L 500M /dev/vg01/lv_data
sudo mount /data
```

**XFS cannot shrink. Ever.** The only route is backup, recreate smaller, restore.

Removal order:

```text
1. umount
2. remove the /etc/fstab line
3. lvremove
4. vgremove
5. pvremove
6. delete the partition
```

Sizes and paths:

| Suffix | Meaning |
| --- | --- |
| `-L 500M` | Megabytes (`M`, `G`, `T`) |
| `-l 25` | 25 physical extents |
| `-l 50%FREE` | Half the free space |
| `-l 100%FREE` | All of it |
| `-l 50%VG` | Half the volume group |

Both `/dev/vg01/lv_data` and `/dev/mapper/vg01-lv_data` refer to the same device.

### Filesystems

```bash
sudo mkfs.xfs /dev/sdb1 ; sudo mkfs.xfs -f /dev/sdb1 ; sudo mkfs.xfs -L data /dev/sdb1
sudo mkfs.ext4 /dev/sdb1 ; sudo mkfs.ext4 -L data /dev/sdb1
sudo mkfs.ext4 -b 4096 -m 1 /dev/sdb1
sudo mkfs.vfat /dev/sdb1 ; sudo mkfs.vfat -n DATA -F 32 /dev/sdb1
sudo mkfs -t xfs /dev/sdb1
sudo xfs_admin -L newlabel /dev/sdb1 ; sudo xfs_admin -l /dev/sdb1
sudo e2label /dev/sdb1 newlabel ; sudo e2label /dev/sdb1
sudo tune2fs -L newlabel /dev/sdb1 ; sudo tune2fs -l /dev/sdb1
sudo tune2fs -o acl,user_xattr /dev/sdb1
sudo fatlabel /dev/sdb1 NEWLABEL
```

| Filesystem | Notes |
| --- | --- |
| **xfs** | **The RHEL default. Grows only, never shrinks. `xfs_growfs`, `xfs_repair`** |
| **ext4** | Grows and shrinks. `resize2fs`, `e2fsck`, `tune2fs` |
| **vfat** | Cross-platform, no permissions, no ownership. Needs `uid=`/`gid=` mount options |

Checking and repair:

```bash
sudo xfs_repair /dev/sdb1                    # MUST be unmounted
sudo xfs_repair -n /dev/sdb1                 # dry run
sudo xfs_repair -L /dev/sdb1                 # zero the log — last resort
sudo e2fsck -f /dev/sdb1 ; sudo e2fsck -p /dev/sdb1 ; sudo e2fsck -y /dev/sdb1
sudo fsck -a /dev/sdb1 ; sudo fsck.vfat -a /dev/sdb1
sudo tune2fs -c 20 /dev/sdb1                 # check every 20 mounts
```

Mounting:

```bash
sudo mount /dev/sdb1 /data
sudo mount UUID=xxxx /data ; sudo mount LABEL=data /data
sudo mount -t xfs /dev/sdb1 /data
sudo mount -o ro,noexec /dev/sdb1 /data
sudo mount -o remount,rw /data
sudo mount -a ; sudo mount -av
sudo mount --bind /src /dst
sudo umount /data ; sudo umount /dev/sdb1
sudo umount -l /data                         # lazy: detach when no longer busy
sudo umount -f /data
sudo fuser -vm /data ; sudo fuser -km /data  # who is holding it; kill them
sudo lsof /data
```

`/etc/fstab` fields:

```text
# <device>        <mount point>  <type>  <options>          <dump>  <fsck>
UUID=xxxx-xxxx    /data          xfs     defaults           0       0
LABEL=data        /data          ext4    defaults,acl       0       0
/dev/vg01/lv_data /data          xfs     defaults           0       0
UUID=yyyy         none           swap    defaults           0       0
/swapfile         none           swap    defaults           0       0
server2:/export   /nfs           nfs     defaults,_netdev   0       0
/root/rhel.iso    /mnt/iso       iso9660 loop,ro,nofail     0       0
```

| Field | Notes |
| --- | --- |
| Device | **Prefer `UUID=` or `LABEL=`** — device names can change |
| Mount point | **`none` for swap** |
| Type | `xfs`, `ext4`, `vfat`, `swap`, `nfs`, `iso9660`, `auto` |
| Options | `defaults` unless told otherwise |
| Dump | Always `0` |
| fsck | **`0` for xfs and swap; `1` for the root filesystem; `2` for other ext4** |

```bash
sudo findmnt --verify ; sudo findmnt --verify --verbose
sudo mount -a
sudo systemctl daemon-reload                 # systemd re-reads fstab
```

**Verify, then reboot. Never reboot on an unverified `/etc/fstab`.**

Recovering from a bad fstab: boot to emergency mode, then

```bash
mount -o remount,rw /
vi /etc/fstab
systemctl daemon-reload
mount -a
reboot
```

Swap:

```bash
sudo mkswap /dev/sdb2 ; sudo mkswap -L swapdata /dev/sdb2
sudo swapon /dev/sdb2 ; sudo swapon -p 10 /dev/sdb2
swapon --show ; swapon -s ; cat /proc/swaps ; free -h
sudo swapoff /dev/sdb2 ; sudo swapoff -a ; sudo swapon -a
sudo dd if=/dev/zero of=/swapfile bs=1M count=512 status=progress
sudo chmod 600 /swapfile                     # REQUIRED or swapon refuses
sudo mkswap /swapfile && sudo swapon /swapfile
echo 'vm.swappiness = 10' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl -p /etc/sysctl.d/99-swappiness.conf ; sysctl vm.swappiness
```

**`sudo swapoff -a && sudo swapon -a` is the swap equivalent of `mount -a`** — it proves the fstab entries work.

NFS:

```bash
# Client
sudo dnf install -y nfs-utils
showmount -e server2 ; showmount -a server2
sudo mount -t nfs server2:/export/shared /nfs
sudo mount -t nfs -o vers=4.2,soft,timeo=100 server2:/export/shared /nfs
nfsstat -m ; mount | grep nfs
# Server
sudo dnf install -y nfs-utils
sudo vim /etc/exports
sudo exportfs -rav ; sudo exportfs -v ; sudo exportfs -s
sudo systemctl enable --now nfs-server
sudo firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
sudo firewall-cmd --reload
```

```text
# /etc/exports
/export/shared   192.168.56.0/24(rw,sync)
/export/ro       *(ro,sync)
/export/admin    192.168.56.10(rw,sync,no_root_squash)
```

| Export option | Meaning |
| --- | --- |
| `rw` / `ro` | Read-write / read-only |
| `sync` / `async` | Commit writes before replying / not |
| **`root_squash`** | **Default: remote root becomes `nfsnobody`** |
| `no_root_squash` | Remote root stays root — avoid unless asked |
| `all_squash` | Every user becomes `nfsnobody` |
| `sec=sys` / `sec=krb5p` | Security flavour |

autofs:

```bash
sudo dnf install -y autofs
sudo systemctl enable --now autofs
sudo systemctl restart autofs                # after EVERY map change
sudo automount -f -v                         # foreground debug
```

```text
# /etc/auto.master.d/shares.autofs
/shares   /etc/auto.shares   --timeout=60
/-        /etc/auto.direct
```

```text
# /etc/auto.shares  (indirect)
data   -rw,sync            server2:/export/shared
*      -rw,sync            server2:/export/&        # wildcard: & = the key

# /etc/auto.direct  (direct — absolute paths as keys)
/mnt/reports  -ro  server2:/export/reports
```

| | fstab | **autofs** |
| --- | --- | --- |
| Mounted | At boot, always | **On first access** |
| Unmounted | Manually | **Automatically after the timeout** |
| Mount point directory | **You create it** | **Do NOT create it — autofs manages it** |
| Both at once | — | **Never put an autofs path in fstab** |

---

## Create simple shell scripts

```bash
#!/bin/bash
set -e                     # exit on any error
set -u                     # error on an unset variable
set -o pipefail            # a pipeline fails if any element fails
set -euo pipefail          # all three
```

```bash
chmod +x script.sh         # WITHOUT THIS NOTHING RUNS
./script.sh ; bash script.sh ; . script.sh ; source script.sh
bash -n script.sh          # syntax check, no execution
bash -x script.sh          # trace every command
```

| Variable | Meaning |
| --- | --- |
| `$0` | The script's own name |
| `$1` ... `$9`, `${10}` | Positional parameters |
| **`$#`** | **The number of arguments** |
| **`"$@"`** | **All arguments, each separately quoted — what you want** |
| `"$*"` | All arguments as a single word |
| **`$?`** | **The exit status of the last command** |
| `$$` | The current PID |
| `$!` | The PID of the last background job |
| `${var:-default}` | `var`, or `default` if unset |
| `${var:?message}` | Error out if unset |
| `${#var}` | Length |
| `shift` | Discard `$1` and renumber |

Conditionals:

```bash
if [[ -f "$file" ]]; then ... elif [[ -d "$file" ]]; then ... else ... fi
[[ -f "$f" ]] && echo yes
[[ -f "$f" ]] || echo no
if command; then ... fi                        # test the exit status directly
if ! grep -q x file; then ... fi
(( count > 5 )) && echo big
case "$1" in
  start|begin) echo starting ;;
  stop)        echo stopping ;;
  *)           echo "usage: $0 {start|stop}" >&2; exit 1 ;;
esac
```

| Test | True when |
| --- | --- |
| `-f f` | Regular file exists |
| `-d d` | Directory exists |
| `-e p` | Path exists, any type |
| `-L p` | Symlink |
| `-r`, `-w`, `-x` | Readable, writable, executable |
| `-s f` | Exists and is non-empty |
| `-z "$s"` | String is empty |
| `-n "$s"` | String is non-empty |
| `"$a" = "$b"`, `!=` | **String comparison** |
| `-eq -ne -lt -le -gt -ge` | **Numeric comparison** |
| `&&`, `\|\|`, `!` | and, or, not |

**`=` for strings, `-eq` for numbers. Mixing them is the classic scripting bug.**

Loops:

```bash
for f in /etc/*.conf; do echo "$f"; done
for i in {1..10}; do echo "$i"; done
for i in $(seq 1 10); do echo "$i"; done
for ((i=0; i<10; i++)); do echo "$i"; done
for u in "$@"; do id "$u"; done
for u in alice bob carol; do sudo useradd "$u"; done

while read -r line; do echo "$line"; done < /etc/passwd
while read -r u _ uid _; do echo "$u $uid"; done < <(cut -d: -f1,3 /etc/passwd)
while IFS=: read -r user _ uid _; do echo "$user $uid"; done < /etc/passwd
while true; do ...; sleep 5; done
until [[ -f /tmp/ready ]]; do sleep 1; done

for f in *.txt; do
  [[ -e "$f" ]] || continue                    # handle "no matches"
  mv "$f" "${f%.txt}.bak"
done
```

**`cmd | while read` runs the loop in a subshell, so variables set inside are lost. Use `while read ... done < <(cmd)` instead.**

Substitution and arithmetic:

```bash
now=$(date +%F) ; count=$(grep -c x file) ; hosts=$(wc -l < file)
total=$(( a + b )) ; (( total++ )) ; pct=$(( used * 100 / size ))
avg=$(echo "scale=2; $a / $b" | bc)
usage=$(df -h /|awk 'NR==2{gsub(/%/,"",$5);print $5}')
mapfile -t lines < file
readarray -t users < <(cut -d: -f1 /etc/passwd)
```

Output and input:

```bash
echo "text" ; echo -n "no newline" ; echo -e "tab\there"
printf '%s %d\n' "$name" "$count"
printf '%-20s %5s\n' "$name" "$status"
echo "error" >&2                               # to stderr
read -p "Name: " name
read -s -p "Password: " pass
read -r line < file
exit 0 ; exit 1 ; exit "$?"
```

Text processing inside scripts:

```bash
cut -d: -f1 /etc/passwd ; cut -c1-5 file
awk -F: '{print $1, $3}' /etc/passwd
awk -F: '$3 >= 1000 {print $1}' /etc/passwd
awk '{sum+=$1} END {print sum}' file
awk 'NR==2 {print $5}' file
sed 's/old/new/' file ; sed 's/old/new/g' file
sed -i.bak 's/old/new/g' file                  # in place, with a backup
sed -n '5,10p' file ; sed '/^#/d' file ; sed '$d' file
sed -i '/pattern/d' file
tr 'a-z' 'A-Z' < file ; tr -d '\r' < file ; tr -s ' ' < file
sort file ; sort -n ; sort -r ; sort -u ; sort -k2 ; sort -t: -k3 -n
uniq ; uniq -c ; uniq -d ; sort file | uniq -c | sort -rn
wc -l ; wc -w ; wc -c ; wc -l < file
head -n5 ; tail -n5 ; tail -f ; tail -n +2         # skip the header
paste f1 f2 ; join f1 f2 ; column -t ; nl file ; tac file ; rev file
xargs ; xargs -I{} cmd {} ; xargs -n1 ; xargs -0
```

---

## Manage containers

```bash
sudo dnf install -y container-tools
podman --version ; podman info ; podman info --format '{{.Host.Security.Rootless}}'
podman login registry.redhat.io ; podman logout --all
podman search httpd ; podman search --limit 5 --filter is-official=true nginx
podman search --list-tags registry.access.redhat.com/ubi9/httpd-24
podman pull registry.access.redhat.com/ubi9/httpd-24
podman pull docker.io/library/nginx:1.25
podman images ; podman images -a ; podman image ls --format '{{.Repository}}:{{.Tag}}'
podman inspect IMAGE ; podman inspect -f '{{.Config.Env}}' IMAGE
podman inspect -f '{{.Config.ExposedPorts}}' IMAGE
podman image inspect IMAGE ; podman history IMAGE
skopeo inspect docker://registry.access.redhat.com/ubi9/httpd-24
skopeo inspect --config docker://IMAGE
skopeo copy docker://IMAGE dir:/tmp/image
skopeo copy docker://IMAGE docker-archive:/tmp/image.tar
podman save -o image.tar IMAGE ; podman load -i image.tar
podman tag IMAGE myimage:v1 ; podman rmi IMAGE ; podman rmi -a
podman image prune -a
```

```bash
podman run -d --name web -p 8080:8080 IMAGE
podman run -it --rm IMAGE /bin/bash
podman run -d --name web -p 8080:8080 \
  -v /srv/web:/var/www/html:Z \
  -e VAR=value --env-file /etc/x.env \
  --restart=on-failure IMAGE
podman run --rm IMAGE cat /etc/os-release
podman ps ; podman ps -a ; podman ps --format '{{.Names}} {{.Status}}'
podman stop web ; podman stop -t 2 web ; podman start web ; podman restart web
podman kill web ; podman pause web ; podman unpause web
podman rm web ; podman rm -f web ; podman rm -a -f ; podman container prune -f
podman logs web ; podman logs -f web ; podman logs --tail 20 web
podman exec -it web /bin/bash ; podman exec web cat /etc/os-release
podman inspect web ; podman port web ; podman top web ; podman stats --no-stream
podman cp file web:/tmp/ ; podman cp web:/tmp/file .
podman diff web ; podman rename web web2
podman volume create data ; podman volume ls ; podman volume inspect data
podman volume rm data ; podman volume prune -f
podman system df ; podman system prune -a --volumes ; podman system reset
```

| `podman run` flag | Meaning |
| --- | --- |
| `-d` | **Detached — for a service** |
| `--name` | **Name it; otherwise you get a random one** |
| `-p host:ctr` | Publish a port |
| **`-v /host:/ctr:Z`** | **Bind mount with SELinux relabelling** |
| `-v name:/ctr` | Named volume |
| `-e KEY=value` | Environment variable |
| `--env-file` | Environment from a file |
| `-it` | Interactive with a TTY |
| `--rm` | Remove on exit |
| `-u` | Run as a specific user |
| `--restart` | Restart policy (**only while podman is running**) |
| `--network host` | Share the host network namespace |

**`:Z` relabels the host directory to `container_file_t` privately for this container. `:z` shares it between containers. Without either, SELinux denies access.**

**Rootless containers cannot bind host ports below 1024.** Map to a high port instead, or use a rootful container.

**Rootful and rootless have entirely separate storage.** `sudo podman images` and `podman images` are different lists. A rootful systemd unit needs the image pulled with `sudo`.

As a systemd service:

```bash
# Rootful
cd /etc/systemd/system
sudo podman generate systemd --new --name web --files
sudo systemctl daemon-reload
sudo podman rm -f web
sudo systemctl enable --now container-web
systemctl status container-web

# Rootless
mkdir -p ~/.config/systemd/user && cd ~/.config/systemd/user
podman generate systemd --new --name web --files
systemctl --user daemon-reload
podman rm -f web
systemctl --user enable --now container-web
loginctl enable-linger $(whoami)                    # WITHOUT THIS IT DIES AT REBOOT
loginctl show-user $(whoami) | grep -i Linger
```

Quadlet:

```bash
sudo vim /etc/containers/systemd/web.container      # rootful
vim ~/.config/containers/systemd/web.container      # rootless
sudo systemctl daemon-reload
sudo systemctl start web                            # NOTE: web, not web.container
systemctl cat web.service
/usr/lib/systemd/system-generators/podman-system-generator --dryrun
```

```ini
[Unit]
Description=web container
After=network-online.target
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

**No `systemctl enable` for a Quadlet unit — `[Install] WantedBy=` does it.** Omitting `[Install]` gives a container that starts manually and never at boot.

Registries: `/etc/containers/registries.conf`, `~/.config/containers/registries.conf`.

```text
unqualified-search-registries = ["registry.access.redhat.com", "docker.io"]
```

**Always use a fully qualified image name** — `registry.access.redhat.com/ubi9/httpd-24`, not `httpd-24`. Short names fail without a TTY, which is exactly what happens inside a systemd unit.
