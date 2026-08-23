# 09. SSH: Remote Access, Key Authentication, And Secure File Transfer

**Objectives:** Access remote systems using SSH. Configure key-based authentication for SSH. Securely transfer files between systems.

Three objectives in one file, and key-based authentication is a near-certain exam task. It is also the one most often failed on permissions.

## Before You Start

You need a running lab VM with a second host. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

Tasks in this file assume **`server1`** and **`server2`** from the lab setup.

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Key authentication fails silently when permissions are wrong. These steps show you what correct looks like.

---

## Follow Along

Work from **server1** unless a step says otherwise. After each step, compare your output to **You should see**.

### 1. Connect and run one command

```bash
ssh server2 hostname
```

**You should see** server2's hostname printed, then return to your prompt — no interactive shell.

Providing a command after the host runs it and exits. For commands that need a TTY (like `sudo` prompts), use `ssh -t server2 'command'`.

### 2. Generate an ed25519 key pair

```bash
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
ls -l ~/.ssh/
```

**You should see:**

```text
-rw-------.  ... id_ed25519       (private, 600)
-rw-r--r--.  ... id_ed25519.pub   (public, 644)
```

`-N ''` sets an empty passphrase (no prompts). `-t ed25519` is the modern default. The private key **must** be mode 600 or ssh refuses to use it.

### 3. Copy the public key with ssh-copy-id

```bash
ssh-copy-id $(whoami)@server2
ssh server2 hostname
```

**You should see** a password prompt once during `ssh-copy-id`, then **no password prompt** on the second connection.

`ssh-copy-id` creates `~/.ssh`, appends to `authorized_keys`, and sets permissions correctly. Use it whenever you can.

### 4. Verify server-side permissions

On **server2**:

```bash
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

**You should see** `.ssh` at mode **700** (`drwx------`) and `authorized_keys` at **600** (`-rw-------`).

These permissions are not optional. sshd **silently refuses** keys when they are too open.

### 5. Break permissions and watch it fail

On **server2**:

```bash
chmod 777 ~/.ssh
```

From **server1**:

```bash
ssh -v $(whoami)@server2 hostname 2>&1 | tail -15
```

**You should see** the client fall back to password authentication. On **server2**, check the log:

```bash
sudo tail -5 /var/log/secure
```

**You should see** something like `Authentication refused: bad ownership or modes for directory`.

Fix on server2:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

This is the single most valuable troubleshooting exercise in this file.

### 6. Copy a file with scp

From **server1**:

```bash
scp /etc/hosts $(whoami)@server2:/tmp/
ssh server2 'ls -l /tmp/hosts'
```

**You should see** the file on server2. `scp` is simple one-shot copy over SSH.

Note: **`scp` uses `-P` (capital) for port**; `ssh` uses `-p` (lowercase).

### 7. Copy a directory with rsync

From **server1**:

```bash
rsync -av /etc/ssh/ $(whoami)@server2:/tmp/ssh-copy/
ssh server2 'ls /tmp/ssh-copy/ | head -5'
```

**You should see** ssh config files mirrored on server2. `-a` archive mode preserves times and permissions; `-v` verbose.

**Trailing slash rule:** `/etc/ssh/` copies the **contents**; `/etc/ssh` copies the **directory itself** into the destination.

### 8. Client config shortcut

On **server1**:

```bash
cat >> ~/.ssh/config <<EOF

Host s2
    HostName server2
    User $(whoami)
    IdentityFile ~/.ssh/id_ed25519
EOF
chmod 600 ~/.ssh/config
ssh s2 hostname
```

**You should see** the hostname without typing the full connection details. `~/.ssh/config` must not be group- or world-writable.

### 9. Validate sshd config before restart

On **server2**:

```bash
sudo sshd -t
echo $?
sudo sshd -T | grep -i permitrootlogin
```

**You should see** exit status **0** from `sshd -t` (silence means OK), and the effective value of `PermitRootLogin`.

**Always `sshd -t` before `systemctl restart sshd`.** A syntax error can lock you out. **`sshd -T`** shows the fully resolved config — trust it over grepping files.

### 10. Harden sshd with a drop-in

On **server2** — **keep your current SSH session open** and test in a second terminal:

```bash
sudo tee /etc/ssh/sshd_config.d/50-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
EOF
sudo sshd -t && sudo systemctl restart sshd
```

From **server1**, verify key login still works:

```bash
ssh server2 hostname
```

**You should see** the hostname with no password prompt. Key auth must still work after disabling passwords.

### 11. Check SELinux context on .ssh

On **server2**:

```bash
ls -ldZ ~/.ssh
ls -lZ ~/.ssh/authorized_keys
```

**You should see** `ssh_home_t` in the context. If wrong:

```bash
restorecon -Rv ~/.ssh
```

Wrong SELinux context causes key auth to fail with no useful client-side message.

### 12. Resolve a changed host key

If you rebuilt server2 and get `REMOTE HOST IDENTIFICATION HAS CHANGED`:

```bash
ssh-keygen -R server2
ssh-keygen -R server2.lab.example.com 2>/dev/null || true
ssh server2    # accept the new key
```

**You should see** the warning gone after `-R` removes the old entry from `known_hosts`.

### Mini checkpoint

Before the practice tasks, you should know:

| Path | Required mode |
| --- | --- |
| `~/.ssh` | **700** |
| `~/.ssh/authorized_keys` | **600** |
| private key | **600** |
| `~/.ssh/config` | **600** |

If any row is blank, re-run the step above that covers it.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

Tasks assume `server1` and `server2` from `Lab-Setup.md`.

**Task 1.** From `server1`, connect to `server2` and display its hostname without starting an interactive shell.

> Hint: `ssh server2 hostname` from follow-along step 1.

**Task 2.** As user `alice` on `server1`, generate an ed25519 key pair with no passphrase.

> Hint: `ssh-keygen -t ed25519 -N ''` from step 2; use `su - alice` first.

**Task 3.** Configure key-based authentication so `alice` on `server1` can log in to `alice` on `server2` without a password. Verify no password is requested.

> Hint: `ssh-copy-id` from step 3.

**Task 4.** Set up key-based authentication manually, without using `ssh-copy-id`.

> Hint: pipe the `.pub` file over ssh with `mkdir`, `chmod`, and `>>` — see Quick Reference.

**Task 5.** Deliberately set `~/.ssh` on `server2` to mode `777` and confirm key authentication now fails. Find the server-side log message that explains why, then fix it.

> Hint: the break-and-fix exercise from step 5; check `/var/log/secure`.

**Task 6.** Configure `server2` to refuse root logins over SSH and to disallow password authentication entirely. Validate the configuration before applying it.

> Hint: drop-in file and `sshd -t` from steps 9–10.

**Task 7.** Copy `/etc/hosts` from `server1` to `/tmp/` on `server2`, preserving its timestamps and permissions.

> Hint: `scp -p` from step 6.

**Task 8.** Copy the entire `/etc/ssh` directory from `server2` to `/tmp/server2-ssh/` on `server1`.

> Hint: `scp -r` or tar-over-ssh for root-owned files — Quick Reference.

**Task 9.** Mirror `/var/log` from `server1` to `/tmp/logmirror/` on `server2` so the destination contains exactly the same files, compressing during transfer.

> Hint: `rsync -avz --delete` from step 7.

**Task 10.** Create a client configuration entry so that `ssh s2` connects to `server2` as `alice` using the key you generated.

> Hint: `~/.ssh/config` from step 8.

**Task 11.** Configure `server2` to listen on port `2222` in addition to port 22, including everything RHEL requires for that to work.

> Hint: Port in sshd config plus SELinux and firewall — Quick Reference.

**Task 12.** `server2` has been rebuilt and now presents a different host key. Resolve the resulting warning.

> Hint: `ssh-keygen -R` from step 12.

**Task 13.** Determine, from `server2`, which SSH configuration settings are actually in effect for `PermitRootLogin` and `PasswordAuthentication`.

> Hint: `sshd -T` from step 9.

**Task 14.** Verify the SELinux context of `alice`'s `~/.ssh` directory on `server2` and correct it if wrong.

> Hint: `ls -ldZ` and `restorecon` from step 11.

---

## Solutions

**Task 1.**

```bash
ssh server2 hostname
```

Providing a command runs it and exits without an interactive shell. For a command needing a TTY, such as anything that prompts:

```bash
ssh -t server2 'sudo systemctl restart httpd'
```

**Task 2.**

```bash
su - alice
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
ls -l ~/.ssh/
```

`-N ''` gives an empty passphrase and suppresses the prompts, `-f` names the output file. Result:

```text
-rw-------. 1 alice alice 399 Aug 18 16:00 id_ed25519       <- private, 600
-rw-r--r--. 1 alice alice  94 Aug 18 16:00 id_ed25519.pub   <- public, 644
```

`ssh-keygen` sets these permissions correctly by itself. If you ever see the private key at `644`, key auth will refuse to use it.

**Task 3.**

```bash
# as alice on server1
ssh-copy-id alice@server2          # prompts for alice's password on server2, once
ssh alice@server2 hostname         # must NOT prompt
```

Verify on `server2`:

```bash
ls -ld /home/alice/.ssh                     # drwx------ (700)
ls -l /home/alice/.ssh/authorized_keys      # -rw------- (600)
cat /home/alice/.ssh/authorized_keys
```

`alice` must already exist on `server2` with a known password for `ssh-copy-id` to authenticate the first time.

**Task 4.**

```bash
# as alice on server1
cat ~/.ssh/id_ed25519.pub | ssh alice@server2 \
  "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && restorecon -Rv ~/.ssh"
```

Then test:

```bash
ssh alice@server2 hostname
```

Note `>>` rather than `>`. Using `>` would wipe any keys already authorised for that account, which on a shared system would lock other people out.

The four things this command gets right, all of which are required: the directory exists, `.ssh` is `700`, `authorized_keys` is `600`, and the SELinux context is correct.

**Task 5.**

Break it:

```bash
# on server2, as alice
chmod 777 ~/.ssh
```

Try from `server1`:

```bash
ssh -v alice@server2
```

The client falls back to a password prompt. The client-side verbose output shows the key being offered and refused, but not the reason. The reason is server-side:

```bash
# on server2
sudo journalctl -u sshd -n 20 --no-pager
sudo tail -20 /var/log/secure
```

```text
Authentication refused: bad ownership or modes for directory /home/alice/.ssh
```

Fix:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
ssh alice@server2 hostname      # works again
```

**This is the single most valuable troubleshooting exercise in this file.** Whenever key auth "just does not work", the answer is almost always permissions or SELinux context, and `/var/log/secure` on the server names it precisely.

**Task 6.**

```bash
# on server2
sudo cp /etc/ssh/sshd_config{,.bak}
sudo tee /etc/ssh/sshd_config.d/50-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
EOF

sudo sshd -t                       # MUST be silent
sudo systemctl restart sshd
```

Verify without locking yourself out — **keep your existing session open** and test in a second terminal:

```bash
ssh root@server2                   # must be refused
ssh alice@server2 hostname         # must still work via the key
```

Confirm what is in effect:

```bash
sudo sshd -T | grep -Ei 'permitrootlogin|passwordauthentication'
```

If the drop-in directory is not honoured on your build, check that the main file contains the include line:

```bash
grep -i include /etc/ssh/sshd_config
```

If it does not, edit `/etc/ssh/sshd_config` directly instead.

**Order matters in OpenSSH: the first occurrence of a keyword wins.** If `PasswordAuthentication yes` appears earlier in the main file than your drop-in is included, your setting is ignored. `sshd -T` is the authoritative check.

**Task 7.**

```bash
scp -p /etc/hosts alice@server2:/tmp/
ssh alice@server2 'ls -l /tmp/hosts'
```

`-p` preserves modification times and modes, mirroring `cp -p`. Note that `scp` cannot preserve ownership unless you are root on both ends.

**Task 8.**

```bash
mkdir -p /tmp/server2-ssh
sudo scp -r alice@server2:/etc/ssh/* /tmp/server2-ssh/
```

`/etc/ssh` contains root-owned host keys that `alice` cannot read, so some files will be denied. To get everything you need root on the remote side, which SSH does not allow directly if `PermitRootLogin no`. The realistic approach:

```bash
ssh alice@server2 'sudo tar -czf /tmp/etcssh.tar.gz /etc/ssh'
scp alice@server2:/tmp/etcssh.tar.gz /tmp/
tar -xzf /tmp/etcssh.tar.gz -C /tmp/server2-ssh/
```

This tar-over-ssh pattern is the standard way to move root-owned trees between hosts without enabling root login.

**Task 9.**

```bash
sudo rsync -avz --delete /var/log/ alice@server2:/tmp/logmirror/
```

Verify:

```bash
ssh alice@server2 'ls /tmp/logmirror | head'
```

Three flags doing the work: `-a` archive (recursive, preserving times, modes, symlinks), `-z` compress in transit, `--delete` remove destination files that no longer exist in the source, which is what makes it a mirror rather than a merge.

**The trailing slash on `/var/log/` is essential.** Without it you would get `/tmp/logmirror/log/...`.

**Task 10.**

```bash
mkdir -p ~/.ssh
cat >> ~/.ssh/config <<'EOF'

Host s2
    HostName server2.lab.example.com
    User alice
    IdentityFile ~/.ssh/id_ed25519
EOF
chmod 600 ~/.ssh/config
ssh s2 hostname
```

`~/.ssh/config` must not be group- or world-writable, or ssh refuses to use it. `600` is correct.

**Task 11.**

Three changes are needed, and missing any one leaves it broken:

```bash
# 1. Tell sshd to listen on the port
sudo tee /etc/ssh/sshd_config.d/60-port.conf <<'EOF'
Port 22
Port 2222
EOF

# 2. Tell SELinux the port is a legitimate ssh port
sudo semanage port -a -t ssh_port_t -p tcp 2222

# 3. Open the firewall
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload

sudo sshd -t && sudo systemctl restart sshd
```

Verify each layer:

```bash
sudo ss -tlnp | grep -E ':22$|:2222'                  # sshd is listening
sudo semanage port -l | grep ssh_port_t               # 2222 is labelled
sudo firewall-cmd --list-ports                        # 2222/tcp is open
ssh -p 2222 alice@server2 hostname                    # end to end
```

If you skip the `semanage` step, `sshd` fails to bind 2222 and `journalctl -u sshd` shows a bind permission error. That is a textbook SELinux port-label task and it appears on real exams. See `27-selinux.md`.

**Task 12.**

```bash
ssh-keygen -R server2
ssh-keygen -R server2.lab.example.com
ssh-keygen -R 192.168.56.12
ssh server2                    # accept the new key
```

`-R` removes all entries for that host from `known_hosts`. Remove the short name, the FQDN, and the IP, because each is stored separately.

**Task 13.**

```bash
sudo sshd -T | grep -Ei 'permitrootlogin|passwordauthentication|^port'
```

`sshd -T` dumps the **fully resolved effective configuration**, including drop-ins and defaults. This is far more reliable than grepping `sshd_config`, which shows you what is written but not what wins.

Compare:

```bash
grep -ri permitrootlogin /etc/ssh/          # what is written where
sudo sshd -T | grep -i permitrootlogin      # what is actually in effect
```

When those two disagree, trust `sshd -T`.

**Task 14.**

```bash
# on server2
ls -ldZ /home/alice/.ssh
ls -lZ /home/alice/.ssh/authorized_keys
```

Correct output contains `ssh_home_t`:

```text
unconfined_u:object_r:ssh_home_t:s0 /home/alice/.ssh
```

If it shows something else, such as `user_home_t` or `admin_home_t`, fix it:

```bash
sudo restorecon -Rv /home/alice/.ssh
```

`restorecon` resets the context to what policy specifies for that path, which for `~/.ssh` is `ssh_home_t`. No `semanage fcontext` is needed here because the default policy is already correct — the file just has the wrong label, usually because it was created by an unusual route such as `mv` from elsewhere or a tar extraction without `--selinux`.

---

## Verify

```bash
# From server1
ssh alice@server2 hostname             # no password prompt
ssh -p 2222 alice@server2 hostname     # if Task 11 done
ssh s2 hostname                        # if Task 10 done

# On server2
sudo sshd -T | grep -Ei 'permitrootlogin|passwordauthentication|^port'
ls -ldZ /home/alice/.ssh
sudo semanage port -l | grep ssh
sudo firewall-cmd --list-all
systemctl is-enabled sshd; systemctl is-active sshd
```

## Persistence Check

| Item | Persistent artifact |
| --- | --- |
| Key pair | `~/.ssh/id_ed25519` and `.pub` — on disk, persists |
| Authorised key | `~/.ssh/authorized_keys` on the **server** |
| Permissions on `.ssh` | Inode metadata, persists |
| SELinux context | Persists, but `restorecon` may reset a `chcon`-only change |
| `sshd_config` changes | `/etc/ssh/sshd_config` or `sshd_config.d/*.conf` |
| sshd enabled | **`systemctl enable --now sshd`** |
| Non-default port label | `semanage port -a` — writes the local policy store, persists |
| Firewall port | **`--permanent` then `--reload`** |
| Client config | `~/.ssh/config`, mode `600` |

After the reboot:

```bash
systemctl is-enabled sshd && systemctl is-active sshd
sudo sshd -T | grep -i '^port'
sudo firewall-cmd --list-ports
ssh alice@server2 hostname             # still passwordless?
```

The two things that most often fail to persist here: a firewall port added without `--permanent`, and a config change made only in a shell variable or by editing the wrong file (client vs server).

## Quick Reference

Come back here when you need a fact you forgot — not before your first pass through Follow Along.

### Connecting

```bash
ssh server2                          # as your current user
ssh alice@server2                    # as a specific user
ssh -p 2222 alice@server2            # non-default port
ssh -i ~/.ssh/mykey alice@server2    # a specific private key
ssh -v alice@server2                 # verbose: essential for debugging
ssh -vvv alice@server2               # very verbose

ssh server2 hostname                 # run one command and exit
ssh server2 'systemctl is-active httpd'
ssh -t server2 'sudo systemctl restart httpd'    # -t allocates a TTY, needed for sudo prompts

ssh -X server2                       # X11 forwarding
exit                                 # or Ctrl+d to disconnect
```

**`ssh -v` is the debugging tool.** When key authentication silently fails, the verbose output tells you exactly which key was offered and why it was rejected.

### Host keys and `known_hosts`

The first connection prompts you to accept the server's host key, which is then stored in `~/.ssh/known_hosts`.

```bash
ssh-keyscan server2 >> ~/.ssh/known_hosts       # pre-accept a host key
ssh-keygen -R server2                           # REMOVE a host key entry
ssh -o StrictHostKeyChecking=no server2         # skip the prompt (scripts only)
```

If you rebuild a VM, you get:

```text
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```

That is `ssh-keygen -R server2` to fix. This happens constantly in a lab where you revert snapshots, so learn it now.

### Key-based authentication

The concept: you hold a **private** key, the server holds your **public** key. The server challenges you, you prove you hold the private key, no password crosses the network.

```text
CLIENT                                    SERVER
~/.ssh/id_ed25519       (private, 600)
~/.ssh/id_ed25519.pub   (public)   ────►  ~/.ssh/authorized_keys  (600)
                                          owned by the target user
                                          ~/.ssh must be 700
```

**Step 1: generate a key pair** (on the client, as the user who will connect):

```bash
ssh-keygen                                        # interactive, accepts defaults
ssh-keygen -t ed25519                             # modern, preferred
ssh-keygen -t rsa -b 4096                         # if RSA is required
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519  # no passphrase, no prompts
ssh-keygen -t ed25519 -C "alice@server1"          # with a comment
```

`-N ''` sets an empty passphrase, which is what you want for exam tasks that must work without interaction. If a task explicitly asks for a passphrase, supply it.

**Step 2: copy the public key to the server:**

```bash
ssh-copy-id alice@server2                         # the easy, correct way
ssh-copy-id -i ~/.ssh/mykey.pub alice@server2     # a specific key
```

`ssh-copy-id` creates `~/.ssh`, creates `authorized_keys`, appends the key, and **sets the permissions correctly**. Use it whenever you can.

The manual equivalent, for when `ssh-copy-id` is unavailable or the task forbids it:

```bash
# From the client
cat ~/.ssh/id_ed25519.pub | ssh alice@server2 \
  "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

**Step 3: test:**

```bash
ssh alice@server2 hostname        # must NOT prompt for a password
```

### The permissions that break key authentication

This is where most people fail this task. sshd **refuses** to use keys if the permissions are too open, and it does so silently from the client's point of view.

| Path | Required | Owner |
| --- | --- | --- |
| `~` (the home directory) | **not group- or world-writable** (`755` or `700`) | the user |
| **`~/.ssh`** | **`700`** | the user |
| **`~/.ssh/authorized_keys`** | **`600`** (`644` usually works, `600` is correct) | the user |
| `~/.ssh/id_ed25519` (private) | **`600`** | the user |
| `~/.ssh/id_ed25519.pub` | `644` | the user |

```bash
# The fix-everything sequence
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chown -R alice:alice /home/alice/.ssh
restorecon -Rv ~/.ssh                  # SELinux context: ssh_home_t
```

**Note `restorecon -Rv ~/.ssh`.** If you created `.ssh` in an unusual way — for example by copying a home directory or extracting a tar archive — the SELinux context may be wrong and key authentication fails with no useful client-side message. The correct type is `ssh_home_t`.

```bash
ls -ldZ ~/.ssh
ls -lZ ~/.ssh/authorized_keys
# should show ...:ssh_home_t:...
```

Diagnosing from the server side is definitive:

```bash
sudo journalctl -u sshd -f              # watch while the client connects
sudo tail -f /var/log/secure
```

You will see messages like `Authentication refused: bad ownership or modes for directory /home/alice/.ssh`, which names the problem exactly.

### The SSH agent

Avoids retyping a passphrase repeatedly in one session.

```bash
eval $(ssh-agent)          # start it and export its variables
ssh-add ~/.ssh/id_ed25519  # load a key, prompting once for the passphrase
ssh-add -l                 # list loaded keys
ssh-add -D                 # remove all keys
```

This is convenience, not persistence — the agent dies with your session.

### Server configuration

`/etc/ssh/sshd_config` controls the **server** (`sshd`). `/etc/ssh/ssh_config` and `~/.ssh/config` control the **client** (`ssh`). Mixing these up is a common error.

```bash
sudo vim /etc/ssh/sshd_config
```

The settings that appear in exam tasks:

```text
Port 22
PermitRootLogin no                # or 'yes', 'prohibit-password'
PasswordAuthentication no         # force key-only authentication
PubkeyAuthentication yes
AllowUsers alice bob
DenyUsers carol
AllowGroups sysadmin
X11Forwarding yes
MaxAuthTries 3
ClientAliveInterval 300
```

**Always validate before restarting:**

```bash
sudo sshd -t                      # syntax check. Silence means OK
sudo systemctl restart sshd
```

`sshd -t` is important. A syntax error plus a restart can leave you unable to reconnect, and on a remote exam that could be catastrophic. Keep an existing session open while you test a new one.

On RHEL 9 and later, drop-in files are the preferred mechanism:

```bash
sudo tee /etc/ssh/sshd_config.d/50-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
EOF
sudo sshd -t && sudo systemctl restart sshd
```

Note the include line near the top of the main `sshd_config`, and that **the first occurrence of a setting wins** in OpenSSH — which is why the include sits at the top and why numbered drop-ins are named `50-`.

Two more RHEL-specific gotchas:

```bash
# Non-default port: SELinux must be told, and the firewall opened
sudo semanage port -a -t ssh_port_t -p tcp 2222
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload
```

Changing `Port` alone is not enough on RHEL. SELinux blocks sshd from binding an unlabelled port, and firewalld blocks the traffic. A task that says "move sshd to port 2222" requires all three changes. See `26-firewalld.md` and `27-selinux.md`.

### The client config file

Saves typing and is a legitimate answer to "make connecting to server2 as alice easy".

```bash
cat >> ~/.ssh/config <<'EOF'
Host s2
    HostName server2.lab.example.com
    User alice
    Port 22
    IdentityFile ~/.ssh/id_ed25519
EOF
chmod 600 ~/.ssh/config
```

Then `ssh s2` is enough.

### Secure file transfer

**`scp`** — simple copies:

```bash
scp file.txt alice@server2:/tmp/                  # local -> remote
scp alice@server2:/etc/hosts /tmp/                # remote -> local
scp -r mydir alice@server2:/tmp/                  # recursive
scp -p file.txt alice@server2:/tmp/               # preserve times and modes
scp -P 2222 file.txt alice@server2:/tmp/          # NOTE: capital P for port
scp file.txt server2:                             # to the remote home directory
```

**`scp` uses `-P` for the port; `ssh` uses `-p`.** That inconsistency is a classic trip-up.

**`rsync`** — better for directories and repeat transfers:

```bash
rsync -av /source/ alice@server2:/dest/           # archive, verbose
rsync -avz /source/ alice@server2:/dest/          # -z compresses in transit
rsync -av --delete /source/ alice@server2:/dest/  # exact mirror
rsync -av -e 'ssh -p 2222' /source/ server2:/dest/
rsync -avAX /source/ /dest/                       # ACLs and xattrs (incl. SELinux)
```

The trailing slash rule: **`/source/` copies the contents; `/source` copies the directory itself** into the destination. Getting this wrong gives you `/dest/source/...` instead of `/dest/...`.

`rsync` only transfers differences, so re-running it is cheap. Prefer it over `scp` for anything more than a single file.

**`sftp`** — interactive:

```bash
sftp alice@server2
> ls
> cd /tmp
> put localfile
> get remotefile
> lcd /tmp          # change the LOCAL directory
> lls
> bye
```

## Exam Tips

- **`ssh-keygen` then `ssh-copy-id`** is the whole key-auth task. `ssh-copy-id` sets permissions correctly for you.
- **`ssh-keygen -t ed25519 -N ''`** for a no-passphrase key without prompts.
- **Permissions: `~/.ssh` is 700, `authorized_keys` is 600, private key is 600, and the home directory must not be group-writable.** This is the number-one cause of failure.
- **`restorecon -Rv ~/.ssh`** if the context is wrong. The correct type is **`ssh_home_t`**.
- When key auth fails, read **`/var/log/secure`** or `journalctl -u sshd` **on the server**. It names the exact problem.
- **`ssh -v`** on the client to see which keys are offered.
- **`sudo sshd -t`** validates config. **`sudo sshd -T`** shows the fully resolved effective config — trust it over grepping files.
- **The first occurrence of a keyword wins** in OpenSSH config. Drop-ins in `/etc/ssh/sshd_config.d/` are included at the top.
- **`sshd_config` is the server; `ssh_config` and `~/.ssh/config` are the client.** Do not mix them up.
- **A non-default SSH port needs three changes:** `Port` in config, **`semanage port -a -t ssh_port_t -p tcp N`**, and a `--permanent` firewall port.
- **`scp -P` for the port, `ssh -p`.** Capital P for scp.
- **`rsync -avz`**, and **`--delete`** to mirror. A **trailing slash on the source copies contents**, without it copies the directory.
- Use **tar over ssh** to move root-owned trees when root login is disabled.
- **`ssh-keygen -R host`** clears a changed host key. Remove the short name, FQDN, and IP.
- **Keep one session open** while testing an sshd change, so a mistake does not lock you out.
