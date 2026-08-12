# SELinux Deep Dive

SELinux has seven listed objectives, appears as a hidden cause inside other tasks, and is the topic candidates most often work around instead of fixing. This file is the model and the diagnostic flow. Step-by-step tasks are in `27-selinux.md`.

**The single most important habit: when something that should work does not, check SELinux before you doubt anything else.**

---

## The model

### Two layers of permission

```text
   Request: httpd wants to read /web/index.html
        │
        ▼
   ┌─────────────────────────────────────────┐
   │ 1. DAC — Discretionary Access Control   │  ls -l
   │    Owner, group, other; rwx; ACLs       │
   │    "Does the UID have permission?"      │
   └─────────────────────────────────────────┘
        │  allowed
        ▼
   ┌─────────────────────────────────────────┐
   │ 2. MAC — Mandatory Access Control       │  ls -Z
   │    SELinux policy: type enforcement     │
   │    "Does httpd_t may read default_t?"   │
   └─────────────────────────────────────────┘
        │  allowed
        ▼
   Access granted
```

**Both must allow. DAC first, then SELinux.** So `chmod 777` fixing nothing is the classic sign that the problem is SELinux, not permissions.

### Contexts

```bash
ls -Z /var/www/html/index.html
```

```text
system_u:object_r:httpd_sys_content_t:s0   index.html
   │         │            │              │
   user     role        TYPE           level
```

| Part | Matters for EX200 |
| --- | --- |
| user (`system_u`, `unconfined_u`) | Rarely |
| role (`object_r`, `system_r`) | Rarely |
| **type (`httpd_sys_content_t`)** | **This is what you work with** |
| level (`s0`) | Only with MLS/MCS |

**Everything the exam asks about is the type.** Processes have a type (called a *domain*); files have a type; policy rules say which domains may do what to which types.

```bash
ls -Z file          # a file's context
ps -Z               # your shell's context
ps -eZ | grep httpd # a process's domain
id -Z               # your SELinux user
sudo semanage port -l | grep http   # port labels
```

```text
system_u:system_r:httpd_t:s0  1234 ? Ss 0:00 /usr/sbin/httpd
                    │
                    └─ the DOMAIN httpd runs in
```

**So the question SELinux answers is always of the form: "may `httpd_t` read `default_t`?"** If the policy has no rule allowing it, the answer is no, and an AVC denial is logged.

### Modes

| Mode | Behaviour |
| --- | --- |
| **`enforcing`** | **Policy is applied. Denials block and are logged** |
| **`permissive`** | **Policy is not applied. Denials are logged only** |
| `disabled` | SELinux is off; no labelling happens at all |

```bash
getenforce
sestatus
sudo setenforce 1                # enforcing, NOW
sudo setenforce 0                # permissive, NOW
grep ^SELINUX= /etc/selinux/config
```

```text
# /etc/selinux/config
SELINUX=enforcing
SELINUXTYPE=targeted
```

**`setenforce` is runtime; `/etc/selinux/config` is persistent. A task about SELinux mode almost always means both.**

```bash
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
getenforce
grep ^SELINUX= /etc/selinux/config
```

**Three transitions to be careful about:**

| From → to | Needs |
| --- | --- |
| enforcing ↔ permissive | **`setenforce`, no reboot** |
| **anything → disabled** | **A reboot** |
| **disabled → enforcing or permissive** | **A reboot, and a full relabel** |

**Going from `disabled` to `enforcing` without a relabel can make the machine unbootable**, because while SELinux was off, new files got no labels at all.

```bash
# The safe path out of disabled
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
sudo touch /.autorelabel
sudo reboot
# then, once the relabel has finished and nothing is broken:
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
```

**`permissive` is a diagnostic tool, not an answer.** Use it to confirm SELinux is the cause, then put it back:

```bash
sudo setenforce 0
# does the problem disappear? then it IS SELinux
sudo setenforce 1
# now fix it properly
```

**Never leave the system permissive or disabled at the end of a task** unless that is literally what was asked.

---

## File contexts

### The three ways to change a label

| Command | Persistence | Use for |
| --- | --- | --- |
| **`chcon -t TYPE path`** | **Temporary — lost at the next relabel** | Quick testing only |
| **`semanage fcontext -a` + `restorecon`** | **Permanent** | **Every real task** |
| `restorecon` alone | Restores the *default* for that path | Fixing a label that got wrong |

```bash
# TESTING ONLY
sudo chcon -t httpd_sys_content_t /web/index.html
sudo chcon -R -t httpd_sys_content_t /web
sudo chcon -R --reference=/var/www/html /web

# THE REAL ANSWER — two commands, always both
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
sudo restorecon -Rv /web

# FIXING a label that drifted from the default
sudo restorecon -Rv /var/www/html
```

**Why `chcon` is not enough:** it writes the label onto the file but records nothing in policy. The next `restorecon -R`, `/.autorelabel`, or package update reverts it. Graders relabel.

**Why `semanage fcontext -a` alone is not enough:** it records the rule for *future* labelling but does not touch existing files. `restorecon` is what applies it.

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
ls -Zd /web                         # STILL the old label
sudo restorecon -Rv /web
ls -Zd /web                         # now correct
```

### The path regex

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
```

| Pattern | Matches |
| --- | --- |
| **`"/web(/.*)?"`** | **`/web` itself and everything beneath it, recursively** |
| `"/web"` | Only the directory `/web` |
| `"/web/.*"` | Everything beneath, **but not `/web` itself** |
| `"/web(/.*)?\.html"` | Only `.html` files |
| `"/srv/[^/]*/data(/.*)?"` | One directory level wildcard |

**Use `"(/.*)?"` unless you have a reason not to.** Quote it — the shell would otherwise expand the parentheses and asterisk.

**Absolute paths only, and no trailing slash.**

### Equivalency rules

When a whole tree mirrors a standard location, one rule covers everything:

```bash
sudo semanage fcontext -a -e /var/www /web
sudo restorecon -Rv /web
```

**This says "label `/web` exactly as `/var/www` would be labelled".** It picks up the full set of subdirectory rules — `html`, `cgi-bin`, and so on — instead of flattening everything to one type. It is the right answer when a task moves `DocumentRoot` to a new location.

```bash
sudo semanage fcontext -l | grep -i equiv
```

### Inspecting and undoing

```bash
sudo semanage fcontext -l                    # every rule (thousands)
sudo semanage fcontext -l -C                 # ONLY your local customisations
sudo semanage fcontext -m -t newtype "/web(/.*)?"   # modify an existing rule
sudo semanage fcontext -d "/web(/.*)?"       # delete YOUR rule
matchpathcon /web                            # what SHOULD /web be labelled?
matchpathcon -V /web/index.html               # verify: does it match the default?
```

**`semanage fcontext -l -C` is the verification command for this objective.** It proves the rule is on disk, not just that the current label happens to look right.

```bash
sudo semanage fcontext -l -C
```

```text
SELinux fcontext          type       Context
/web(/.*)?                all files  system_u:object_r:httpd_sys_content_t:s0
```

### restorecon

```bash
sudo restorecon -v /path/file                # one file, verbose
sudo restorecon -Rv /path                    # recursive
sudo restorecon -RFv /path                   # -F FORCE: reset user and role too
sudo restorecon -Rn /path                    # -n dry run: show, change nothing
sudo restorecon -Rv /                        # the whole filesystem, slow
```

**`-F` matters when the user or role part is wrong**, not just the type — which happens after a `tar` extraction or restore from a backup.

Full relabel at next boot:

```bash
sudo touch /.autorelabel
sudo reboot
```

**The next boot will be slow and the file is removed automatically.** This is what fixes a system whose labels are broadly wrong, and it is a required step after a root password reset via `rd.break`.

### Why labels go wrong

```text
Operation                          Resulting label
──────────────────────────────────────────────────────────────────────
cp file /var/www/html/             Inherits from the DESTINATION parent  ✓
cp -a file /var/www/html/          PRESERVES the source label            ✗
cp -p file /var/www/html/          Preserves mode/time, label from dest  ✓
mv file /var/www/html/             KEEPS THE ORIGINAL LABEL              ✗
tar -xf archive.tar                Label from the destination parent     ✓
tar --xattrs --selinux -xf ...     Labels from the archive               depends
Creating a file with > or touch    From the parent directory             ✓
A new top-level directory          default_t                             ✗
A new filesystem mounted           default_t on the mount point          ✗
rsync -a                           Preserves labels if -X is used        depends
```

**`mv` is the dangerous one, and it is the single most common cause of SELinux problems in practice.**

```bash
# The classic failure
echo '<h1>hello</h1>' > ~/index.html          # labelled user_home_t
sudo mv ~/index.html /var/www/html/           # STILL user_home_t
sudo systemctl restart httpd
curl http://localhost                          # 403 Forbidden
```

```bash
ls -Z /var/www/html/index.html
```

```text
unconfined_u:object_r:user_home_t:s0  index.html      ← wrong
```

```bash
sudo restorecon -v /var/www/html/index.html
ls -Z /var/www/html/index.html
curl http://localhost                          # works
```

**The reflex: after any `mv`, `tar -x`, `cp -a`, or restore into a service's directory, run `restorecon -Rv` on that directory.** It costs a second and prevents a whole class of failure.

### Common types

| Type | For |
| --- | --- |
| `httpd_sys_content_t` | Web content Apache reads |
| `httpd_sys_rw_content_t` | Web content Apache may write |
| `httpd_sys_script_exec_t` | CGI scripts |
| `httpd_log_t` | Apache logs |
| `httpd_config_t` | Apache configuration |
| `public_content_t` | Shared read-only across FTP, NFS, Samba, httpd |
| `public_content_rw_t` | Shared read-write |
| `samba_share_t` | Samba-only shares |
| `nfs_t` | NFS-mounted content |
| **`container_file_t`** | **Podman bind mounts** |
| `user_home_t`, `user_home_dir_t` | Home directory content |
| `ssh_home_t` | `~/.ssh` |
| `tmp_t`, `tmpfs_t` | Temporary |
| `var_log_t` | Logs generally |
| **`default_t`** | **The label of an unlabelled new top-level directory — almost always wrong** |
| `etc_t` | `/etc` content |
| `bin_t` | Executables in `/usr/bin` |
| `admin_home_t` | `/root` |

**Seeing `default_t` in `ls -Z` is a strong hint you created a directory outside the standard tree and never labelled it.**

Finding the right type when you do not know it:

```bash
ls -Zd /var/www/html                   # what does the standard location use?
matchpathcon /var/www/html
sudo semanage fcontext -l | grep -i httpd | head -30
man httpd_selinux                      # from selinux-policy-doc
seinfo -t | grep httpd                 # from setools-console
```

**`man -k _selinux` lists every per-service SELinux manual page.** With no internet, `man httpd_selinux`, `man nfs_selinux`, `man samba_selinux`, and `man container_selinux` are the reference. Each one documents the types and booleans for that service.

---

## Booleans

Booleans are switches the policy authors provided for common variations, so you do not have to write policy.

```bash
getsebool -a                                  # all of them, hundreds
getsebool -a | grep httpd
getsebool httpd_enable_homedirs
sudo semanage boolean -l                      # with descriptions
sudo semanage boolean -l | grep -i home
sudo semanage boolean -l -C                   # ONLY what you have changed
```

```text
httpd_enable_homedirs   (off  ,  off)  Allow httpd to enable homedirs
                          │       │
                       current  persistent
```

**When the two values differ, you set it without `-P`.**

```bash
sudo setsebool httpd_enable_homedirs on       # runtime only
sudo setsebool -P httpd_enable_homedirs on    # PERSISTENT
```

**`-P` writes the policy to disk and takes a few seconds. An instant return means you forgot it.**

Booleans that appear in tasks:

| Boolean | Allows |
| --- | --- |
| `httpd_enable_homedirs` | Apache to serve `~user/public_html` |
| **`httpd_can_network_connect`** | **Apache to make outbound connections — reverse proxy, app backends** |
| `httpd_can_network_connect_db` | Apache to reach a database port |
| `httpd_use_nfs` | Apache to serve content from an NFS mount |
| `httpd_enable_cgi` | CGI execution |
| `httpd_anon_write` | Apache to write to `public_content_rw_t` |
| `ftpd_full_access` | vsftpd to read and write everywhere |
| `ftpd_anon_write` | Anonymous FTP uploads |
| `nfs_export_all_rw` | Exporting anything read-write |
| `nfs_export_all_ro` | Exporting anything read-only |
| `use_nfs_home_dirs` | Home directories over NFS |
| `samba_enable_home_dirs` | Samba to share home directories |
| `samba_export_all_rw` | Samba to share anything read-write |
| `ssh_sysadm_login` | Certain SSH login roles |
| `container_manage_cgroup` | Containers running systemd inside |

**The pattern for finding one:**

```bash
sudo semanage boolean -l | grep -i <the thing you want to do>
sudo semanage boolean -l | grep -i nfs
getsebool -a | grep -i home
```

**And `sealert` and `audit2why` usually name the boolean for you** — which is why the diagnostic step comes before the fix.

---

## Port labels

SELinux restricts which ports a domain may bind. Moving a service to a non-standard port needs a label.

```bash
sudo semanage port -l                         # every labelled port
sudo semanage port -l | grep http
sudo semanage port -l -C                      # your customisations
```

```text
http_port_t   tcp   80, 81, 443, 488, 8008, 8009, 8443, 9000
ssh_port_t    tcp   22
```

```bash
sudo semanage port -a -t http_port_t -p tcp 8090     # ADD a new port
sudo semanage port -m -t http_port_t -p tcp 8090     # MODIFY an existing label
sudo semanage port -d -t http_port_t -p tcp 8090     # delete yours
sudo semanage port -a -t ssh_port_t -p tcp 2222
```

**`-a` fails if the port already has any label:**

```text
ValueError: Port tcp/8090 already defined
```

```bash
sudo semanage port -m -t http_port_t -p tcp 8090     # use -m instead
```

**Symptom of a missing port label:** the service refuses to start, and the journal shows a permission error binding the port:

```bash
sudo systemctl status httpd
sudo journalctl -xeu httpd
```

```text
(13)Permission denied: AH00072: make_sock: could not bind to address [::]:8090
```

**That is SELinux, not the firewall.** A firewall blocks *remote* connections; it never stops a local process from binding a port.

### The three-layer rule

Moving a service to a non-standard port needs three changes, and candidates routinely make one or two:

```bash
# 1. The service's own configuration
sudo sed -i 's/^Listen 80$/Listen 8090/' /etc/httpd/conf/httpd.conf

# 2. The SELinux port label
sudo semanage port -a -t http_port_t -p tcp 8090

# 3. The firewall
sudo firewall-cmd --permanent --add-port=8090/tcp
sudo firewall-cmd --reload

sudo systemctl restart httpd
ss -tlnp | grep 8090
curl http://localhost:8090                    # tests layers 1 and 2
# from the other host:
curl http://192.168.56.11:8090                # tests layer 3
```

| Missing layer | Symptom |
| --- | --- |
| 1 | The service listens on the old port |
| **2** | **The service will not start: `Permission denied` binding** |
| **3** | **Works locally, times out from the other host** |

**"Works locally but not remotely" is always the firewall. "Will not start at all" is usually SELinux.**

---

## Diagnosing denials

### The flow

```text
Something does not work as expected
        │
        ▼
 1. Is SELinux the cause?
    sudo setenforce 0    → does it work now?
    sudo setenforce 1    → put it back either way
        │
        ├─ No  → it is DAC permissions, configuration, firewall, or the service
        │
        ▼ Yes
 2. What was denied?
    sudo ausearch -m AVC -ts recent
    sudo journalctl -t setroubleshoot
    sudo sealert -a /var/log/audit/audit.log
        │
        ▼
 3. Which kind of denial?
        │
        ├─ WRONG FILE LABEL     → semanage fcontext -a + restorecon
        │  (comm=httpd, path=/web, tcontext=...default_t)
        │
        ├─ POLICY OPTION        → setsebool -P
        │  (denial mentions a boolean, or sealert suggests one)
        │
        ├─ PORT NOT LABELLED    → semanage port -a
        │  (name_bind on tcp_socket)
        │
        └─ GENUINELY NEW        → audit2allow -M, semodule -i
           (rare on the exam)
        │
        ▼
 4. Apply the fix, retry, and confirm the denial is gone
    sudo ausearch -m AVC -ts recent
```

### Reading an AVC

```bash
sudo ausearch -m AVC -ts recent
sudo ausearch -m AVC -ts today -i            # -i makes it human-readable
sudo ausearch -m AVC,USER_AVC,SELINUX_ERR -ts recent
sudo ausearch -m AVC -c httpd
sudo aureport -a
```

```text
type=AVC msg=audit(1755530000.123:456): avc:  denied  { read } for  pid=3421
  comm="httpd" name="index.html" dev="dm-0" ino=1234
  scontext=system_u:system_r:httpd_t:s0
  tcontext=unconfined_u:object_r:user_home_t:s0
  tclass=file permissive=0
```

Read it in this order:

| Field | Question it answers |
| --- | --- |
| **`comm="httpd"`** | **Who was blocked** |
| **`{ read }`** | **What it tried to do** |
| **`name=` / `path=`** | **What it tried to do it to** |
| **`scontext=...httpd_t`** | **The SOURCE domain — the process** |
| **`tcontext=...user_home_t`** | **The TARGET type — usually where the problem is** |
| `tclass=file` | The kind of object: `file`, `dir`, `tcp_socket`, `unix_stream_socket` |
| `permissive=0` | 0 means it was blocked; 1 means only logged |

**In this example `tcontext` is `user_home_t` on a file Apache should serve.** That is a wrong label, so the fix is `restorecon`:

```bash
sudo restorecon -Rv /var/www/html
```

**`tclass=tcp_socket` with `{ name_bind }` means a port label is missing:**

```text
avc: denied { name_bind } for pid=3500 comm="httpd"
  src=8090 scontext=system_u:system_r:httpd_t:s0
  tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket
```

```bash
sudo semanage port -a -t http_port_t -p tcp 8090
```

**`{ name_connect }` on a `tcp_socket` usually means a boolean:**

```bash
sudo setsebool -P httpd_can_network_connect on
```

### sealert

```bash
sudo dnf install -y setroubleshoot-server
sudo sealert -a /var/log/audit/audit.log
sudo journalctl -t setroubleshoot
sudo journalctl -f -t setroubleshoot          # watch live while you reproduce
```

```text
SELinux is preventing /usr/sbin/httpd from read access on the file index.html.

*****  Plugin restorecon (99.5 confidence) suggests  *********************
If you want to fix the label,
/var/www/html/index.html default label should be httpd_sys_content_t.
Then you can run restorecon. The access attempt may have been stopped due
to insufficient permissions to access a parent directory.
Do
# /sbin/restorecon -v /var/www/html/index.html
```

**`sealert` names the fix and the confidence.** Follow the highest-confidence suggestion — it is right the great majority of the time.

**But read it critically.** `sealert` sometimes suggests generating a custom policy module when the real answer is a label or a boolean. **Prefer, in order: fix the label → set a boolean → label the port → custom policy.**

### audit2why and audit2allow

```bash
sudo audit2why -a                             # explain every recent denial
sudo audit2allow -a                           # show the rules that would allow it
sudo audit2allow -a -w                        # why, in words
```

```text
        Was caused by:
        Missing type enforcement (TE) allow rule.

        You can use audit2allow to generate a loadable module to allow this access.
```

or, more usefully:

```text
        Was caused by:
        One of the following booleans was set incorrectly.
        Allow httpd to can network connect
        Allow access by executing:
        # setsebool -P httpd_can_network_connect 1
```

**`audit2why` telling you a boolean is the answer is the best possible outcome.** Set it and move on.

Custom modules, when nothing else fits:

```bash
sudo ausearch -m AVC -ts recent | audit2allow -M mypolicy
cat mypolicy.te                               # READ IT before loading
sudo semodule -i mypolicy.pp
sudo semodule -l | grep mypolicy
sudo semodule -r mypolicy                     # remove
```

**Treat this as a last resort.** On EX200, a denial that genuinely needs a custom module is unlikely; a denial that has a label, boolean, or port answer is very likely. Blanket-allowing everything `audit2allow` suggests can also mask the real problem and cost you a different task.

### When there is no denial logged

```bash
sudo ausearch -m AVC -ts recent
```

```text
<no matches>
```

**Possibilities:**

1. **It is not SELinux.** Check DAC permissions, the service configuration, and the firewall.
2. **`auditd` is not running:**

```bash
sudo systemctl status auditd
sudo systemctl enable --now auditd
```

3. **The denial is a "dontaudit" rule** — the policy deliberately silences it:

```bash
sudo semodule -DB                             # disable dontaudit, rebuild
sudo ausearch -m AVC -ts recent               # now you see everything
sudo semodule -B                              # restore normal behaviour
```

4. **You are looking at the wrong time window:**

```bash
sudo ausearch -m AVC -ts today
sudo ausearch -m AVC -ts boot
sudo grep -i denied /var/log/audit/audit.log | tail -20
```

---

## The playbook

Six scenarios cover almost everything the exam can ask.

### 1. A service cannot read files in a non-standard location

```bash
# Symptom: 403, or "permission denied" in the service log
ls -Zd /web
sudo ausearch -m AVC -ts recent

# Fix
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
sudo restorecon -Rv /web

# Verify
ls -Zd /web
sudo semanage fcontext -l -C
curl http://localhost
```

### 2. Files were moved in and are now unreadable

```bash
ls -Z /var/www/html/
sudo restorecon -Rv /var/www/html
```

**No `semanage` needed — the default rule for that path is already correct; the files just did not have it.**

### 3. A service needs a capability it does not have by default

```bash
sudo ausearch -m AVC -ts recent | audit2why
sudo semanage boolean -l | grep -i <capability>
sudo setsebool -P httpd_can_network_connect on
sudo semanage boolean -l -C
```

### 4. A service must listen on a non-standard port

```bash
sudo semanage port -l | grep http_port_t
sudo semanage port -a -t http_port_t -p tcp 8090     # or -m if already defined
sudo systemctl restart httpd
ss -tlnp | grep 8090
```

**Plus the service config and the firewall — the three layers.**

### 5. A new filesystem or directory has the wrong label

```bash
ls -Zd /data
matchpathcon /data
sudo semanage fcontext -a -t httpd_sys_content_t "/data(/.*)?"
sudo restorecon -Rv /data
```

Or, for a tree mirroring a standard location:

```bash
sudo semanage fcontext -a -e /var/www /web
sudo restorecon -Rv /web
```

### 6. A container cannot read a bind mount

```bash
sudo ausearch -m AVC -ts recent
ls -Zd /srv/webcontent
```

```bash
# Quick: let podman relabel it
podman run -v /srv/webcontent:/var/www/html:Z ...

# Persistent, if the label must survive independently
sudo semanage fcontext -a -t container_file_t "/srv/webcontent(/.*)?"
sudo restorecon -Rv /srv/webcontent
```

---

## Verification

```bash
# Mode, both now and after reboot
getenforce
grep ^SELINUX= /etc/selinux/config
sestatus

# Everything you have customised
sudo semanage fcontext -l -C
sudo semanage boolean -l -C
sudo semanage port -l -C
sudo semodule -l | grep -v '^selinux-policy'

# Current labels
ls -Zd /web /data
matchpathcon -V /web

# No outstanding denials
sudo ausearch -m AVC -ts recent
sudo journalctl -b -t setroubleshoot

# And the real test
sudo reboot
getenforce
sudo ausearch -m AVC -ts boot
curl http://localhost
```

**The three `-C` commands are the persistence proof for this whole domain.** They show what is recorded in policy on disk, as opposed to what happens to be true right now.

---

## Packages and documentation

```bash
sudo dnf install -y policycoreutils-python-utils setroubleshoot-server selinux-policy-doc
```

| Package | Gives you |
| --- | --- |
| `policycoreutils` | `restorecon`, `setsebool`, `semodule`, `sestatus` |
| **`policycoreutils-python-utils`** | **`semanage`, `audit2allow`, `audit2why`, `chcat`** |
| **`setroubleshoot-server`** | **`sealert`, and friendly journal messages** |
| **`selinux-policy-doc`** | **`man httpd_selinux` and every other per-service page** |
| `setools-console` | `seinfo`, `sesearch` for querying policy |

**If `semanage: command not found`, that is the missing package, and `dnf provides */semanage` finds it.**

```bash
sudo dnf provides */semanage
man -k _selinux                    # every per-service page
man httpd_selinux
man nfs_selinux
man samba_selinux
man container_selinux
man semanage-fcontext
man semanage-port
man semanage-boolean
```

**`man semanage-fcontext` has the exact syntax with examples**, which is what you want at 90 minutes in when you cannot remember whether it is `-a -t` or `-t -a`.

---

## The five things to take away

1. **`ls -Z` and `ps -Z` are the first commands.** You cannot reason about SELinux without seeing the labels.
2. **`semanage fcontext -a` plus `restorecon` — both, always, for anything permanent.** `chcon` is for testing.
3. **`setsebool` needs `-P`.** No `-P`, no persistence.
4. **`ausearch -m AVC -ts recent` then `sealert` before you guess.** The tools name the fix.
5. **`setenforce 0` is a diagnostic, never a solution.** Confirm the cause, set it back to 1, fix it properly.
