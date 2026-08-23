# 18. Logs: journald And rsyslog

**Objectives:** Locate and interpret system log files and journals. Preserve system journals.

"Preserve system journals" is a specific, commonly asked task with a specific answer. Learn it exactly.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Reading every journalctl flag upfront feels like learning. Typing them one at a time actually is.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. The two text logs you will use most

```bash
sudo tail -20 /var/log/messages
sudo tail -20 /var/log/secure
```

**You should see** recent system messages in `/var/log/messages` and authentication-related lines in `/var/log/secure`.

**`/var/log/messages`** is the general-purpose log. **`/var/log/secure`** is where SSH failures, sudo denials, and login attempts appear.

Search a rotated log with `zgrep`:

```bash
sudo zgrep -i error /var/log/messages-*.gz 2>/dev/null | tail
```

**You should see** matching lines from compressed archives, or nothing if no rotated files exist yet.

### 2. The journal: last lines and follow mode

```bash
journalctl -n 30 --no-pager
journalctl -e
```

**You should see** the last 30 journal entries, then (with `-e`) the pager jumps to the **end** of the full journal.

Follow live:

```bash
journalctl -f
```

**You should see** new entries appear as they happen. Press `Ctrl+c` to stop.

### 3. Filter by systemd unit

```bash
journalctl -u sshd -n 20 --no-pager
journalctl -xeu sshd | tail -30
```

**You should see** only `sshd` entries. The `-xeu` form adds explanatory help text and jumps to the end — **the fastest route from "service failed" to "here is why".**

### 4. Filter by priority and time

```bash
journalctl -p err --since today --no-pager | head
journalctl -p warning..err --since "1 hour ago" --no-pager | head
```

**You should see** error-level entries from today. `-p err` includes err **and everything more severe** (crit, alert, emerg). Lower number = more serious.

Priority names and numbers are interchangeable: `-p 3` equals `-p err`.

### 5. Filter by boot and kernel messages

```bash
journalctl --list-boots
journalctl -b -1 -n 10 --no-pager    # may be empty if journal is volatile
journalctl -k -b | tail -20
dmesg -T | tail -20
```

**You should see** boot indices in `--list-boots`. If only boot `0` exists, the journal is **not persistent yet** — it lives in memory and was wiped at the last reboot.

`-k` shows kernel messages (same content as `dmesg`). **`dmesg -T`** adds human-readable timestamps; raw `dmesg` shows seconds since boot.

### 6. Structured metadata filters

```bash
PID=$(systemctl show -p MainPID --value sshd)
journalctl _PID=$PID -n 10 --no-pager
journalctl -o verbose -n 1 --no-pager | head -30
```

**You should see** entries from the running sshd process, then a dump of every metadata field available for filtering (`_COMM=`, `_UID=`, `_SYSTEMD_UNIT=`, and more).

### 7. Preserve the journal across reboots

**This is the "preserve system journals" objective.**

```bash
sudo mkdir -p /var/log/journal
sudo sed -i 's/^#\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
grep -E '^Storage' /etc/systemd/journald.conf
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

**You should see** `Storage=persistent` in the config, and a machine-id directory under `/var/log/journal/`:

```bash
ls -ld /var/log/journal
ls /var/log/journal/
journalctl --disk-usage
```

After a reboot, **`journalctl --list-boots` showing more than one boot is the proof.**

### 8. Limit and shrink journal disk use

```bash
journalctl --disk-usage
sudo journalctl --vacuum-size=100M
journalctl --disk-usage
```

**You should see** disk usage before and after vacuuming. **`--vacuum-*` acts immediately** on existing data; `SystemMaxUse=` in config governs future growth.

To set a persistent ceiling:

```bash
sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/size.conf <<'EOF'
[Journal]
Storage=persistent
SystemMaxUse=500M
EOF
sudo systemctl restart systemd-journald
systemd-analyze cat-config systemd/journald.conf | grep -E 'Storage|SystemMaxUse'
```

### 9. rsyslog: add a rule and prove it works

```bash
sudo tee /etc/rsyslog.d/mydebug.conf <<'EOF'
*.debug    /var/log/mydebug.log
EOF
sudo rsyslogd -N1
sudo systemctl restart rsyslog
logger -p user.debug "EX200 debug test message"
sudo tail -5 /var/log/mydebug.log
```

**You should see** your test message in `/var/log/mydebug.log`. **`rsyslogd -N1`** validates syntax before restart. **`logger`** generates test messages — indispensable for proving a logging task works.

Exact priority with `=`:

```bash
sudo tee /etc/rsyslog.d/local7.conf <<'EOF'
local7.=info    /var/log/local7.log
EOF
sudo rsyslogd -N1 && sudo systemctl restart rsyslog
logger -p local7.info "should appear"
logger -p local7.err  "should NOT appear"
sudo cat /var/log/local7.log
```

**You should see** only the `info` line. **`local7.=info`** means exactly info; plain `local7.info` would match info and everything more severe.

### 10. Find authentication failures in both systems

```bash
journalctl -u sshd | grep -iE 'fail|invalid|denied' | tail
sudo grep -iE 'fail|invalid' /var/log/secure | tail
sudo lastb | head
```

**You should see** failed login attempts. The journal and `/var/log/secure` contain the same events; the text log survives even if the journal was volatile.

### 11. Log rotation preview

```bash
sudo ls -l /var/log/messages*
sudo logrotate -d /etc/logrotate.conf 2>&1 | head -20
systemctl list-timers | grep logrotate
```

**You should see** what logrotate would do in debug mode (`-d`) without changing anything. Use `-f` to force rotation now.

### Mini checkpoint

Before the practice tasks, you should be able to explain:

| Command / concept | Does |
| --- | --- |
| `journalctl -u UNIT` | filter by systemd unit |
| `journalctl -xeu UNIT` | explain + end + unit — debugging command |
| `journalctl -p err` | err and worse |
| `journalctl -b -1` | previous boot (needs persistent journal) |
| `mkdir /var/log/journal` + `Storage=persistent` | preserve journals |
| `journalctl --list-boots` | proof of persistence (>1 boot) |
| `/var/log/messages` | general problems |
| `/var/log/secure` | authentication |
| `rsyslogd -N1` | syntax check |
| `logger -p fac.pri "msg"` | generate a test message |

If any row is blank in your head, re-run the step above that covers it.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Show the last 30 lines of the system journal.

> Hint: `-n` and optionally `--no-pager`.

**Task 2.** Follow the journal for the `sshd` unit in real time, then generate a login attempt from another terminal to see it appear.

> Hint: `-u sshd -f` from follow-along step 3.

**Task 3.** Show all journal entries of priority `err` or worse from today.

> Hint: `-p err --since today`.

**Task 4.** Configure the system so that the journal is preserved across reboots. Verify after rebooting that the previous boot's log is readable.

> Hint: follow-along step 7; proof is `journalctl --list-boots`.

**Task 5.** Determine how much disk space the journal is currently using.

> Hint: `--disk-usage`.

**Task 6.** Limit the journal to a maximum of 500 MB of disk, persistently.

> Hint: `SystemMaxUse=500M` in journald.conf or a drop-in; restart journald.

**Task 7.** Reduce the existing journal to no more than 100 MB immediately.

> Hint: `--vacuum-size=` acts now; config settings govern future growth.

**Task 8.** Find all authentication failures recorded on the system, using both the journal and the traditional log file.

> Hint: follow-along step 10; `/var/log/secure` for auth.

**Task 9.** Show all kernel messages from the current boot with human-readable timestamps.

> Hint: `journalctl -k -b` or `dmesg -T`.

**Task 10.** Configure rsyslog so that all messages of priority `debug` and above are additionally written to `/var/log/mydebug.log`. Validate the configuration and prove it works with a test message.

> Hint: follow-along step 9; `rsyslogd -N1` then `logger`.

**Task 11.** Configure rsyslog so that only `local7` facility messages at exactly `info` priority go to `/var/log/local7.log`.

> Hint: `local7.=info` — the `=` means exactly that priority.

**Task 12.** Show every journal entry produced by the process ID of the running sshd.

> Hint: `_PID=` metadata filter from step 6.

**Task 13.** Show all journal entries between 09:00 and 10:00 today for the `httpd` unit.

> Hint: `-u httpd --since "09:00" --until "10:00"`.

**Task 14.** List every boot recorded in the journal and show the errors from two boots ago.

> Hint: `--list-boots` then `-b -2 -p err`; requires persistent journal.

**Task 15.** Force an immediate log rotation and confirm that `/var/log/messages` was rotated.

> Hint: `logrotate -f`; compare `ls /var/log/messages*` before and after.

---

## Solutions

**Task 1.**

```bash
journalctl -n 30
```

`-n` without a number defaults to 10. Add `--no-pager` if you want it to print straight out:

```bash
journalctl -n 30 --no-pager
```

**Task 2.**

```bash
journalctl -u sshd -f
```

From another terminal:

```bash
ssh localhost         # or a deliberately failed attempt
ssh baduser@localhost
```

You will see the accepted or failed authentication appear live. `Ctrl+c` to stop following.

`-f` is the journal's equivalent of `tail -f`, and combining it with `-u` is how you watch one service while you provoke it.

**Task 3.**

```bash
journalctl -p err --since today
```

`-p err` includes err, crit, alert, and emerg — priority 3 and lower numbers. To see only errors and nothing more severe:

```bash
journalctl -p err..err --since today
```

Useful post-reboot variant:

```bash
journalctl -p err -b
```

**Task 4.**

```bash
sudo mkdir -p /var/log/journal
sudo sed -i 's/^#\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
grep '^Storage' /etc/systemd/journald.conf
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

Verify immediately:

```bash
ls -ld /var/log/journal
ls /var/log/journal/            # a machine-id subdirectory appears
journalctl --disk-usage
```

Then the real test:

```bash
sudo reboot
```

After the reboot:

```bash
journalctl --list-boots         # MORE THAN ONE entry
journalctl -b -1 -p err         # the previous boot's errors are readable
```

**`journalctl --list-boots` showing two or more boots is the proof.** Before this change it shows exactly one, because the journal was wiped.

Creating the directory alone would be enough, since the default is `Storage=auto`. Setting `Storage=persistent` explicitly is better on an exam because it is unambiguous to a grader inspecting the config, and it does not depend on the default.

**Task 5.**

```bash
journalctl --disk-usage
```

```text
Archived and active journals take up 96.0M in the file system.
```

Also:

```bash
du -sh /var/log/journal/
du -sh /run/log/journal/ 2>/dev/null      # if still volatile
```

**Task 6.**

```bash
sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/size.conf <<'EOF'
[Journal]
Storage=persistent
SystemMaxUse=500M
EOF
sudo systemctl restart systemd-journald
```

Or edit the main file:

```bash
sudo sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=500M/' /etc/systemd/journald.conf
grep SystemMaxUse /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
```

Verify:

```bash
systemd-analyze cat-config systemd/journald.conf | grep -E 'Storage|SystemMaxUse'
journalctl --disk-usage
```

`systemd-analyze cat-config` shows the merged configuration including drop-ins, which is the equivalent of `systemctl cat` for config files. Very useful for proving a setting is in effect.

Note that `SystemMaxUse` is a ceiling for the persistent journal; the volatile equivalent is `RuntimeMaxUse`.

**Task 7.**

```bash
sudo journalctl --vacuum-size=100M
```

```text
Deleted archived journal /var/log/journal/.../system@....journal (48.0M).
Vacuuming done, freed 48.0M of archived journals.
```

```bash
journalctl --disk-usage
```

The other vacuum forms:

```bash
sudo journalctl --vacuum-time=2weeks
sudo journalctl --vacuum-files=3
```

**`--vacuum-*` acts immediately on existing data; `SystemMaxUse` governs future growth.** A task saying "reduce the journal to X" means vacuum; "limit the journal to X" means the config setting. Read the wording.

**Task 8.**

Via the journal:

```bash
journalctl -u sshd | grep -i -E 'fail|invalid|denied'
journalctl _COMM=sshd -p warning
journalctl SYSLOG_FACILITY=10          # authpriv
```

Via the text log:

```bash
sudo grep -i -E 'fail|invalid' /var/log/secure
sudo grep -i 'authentication failure' /var/log/secure
sudo lastb | head                       # failed login attempts
```

**`/var/log/secure` is the authentication log.** It is where you look for SSH key permission problems (`09-ssh.md`), sudo denials, and failed logins. The journal has the same content, but `/var/log/secure` survives even if the journal was volatile.

**Task 9.**

```bash
journalctl -k -b
```

Or via `dmesg`:

```bash
dmesg -T
dmesg -T | grep -i -E 'error|fail|warn'
```

`-k` filters the journal to kernel messages; `dmesg -T` reads the ring buffer with real timestamps. Raw `dmesg` shows seconds since boot, which is hard to correlate with anything else.

**Task 10.**

```bash
sudo tee /etc/rsyslog.d/mydebug.conf <<'EOF'
*.debug    /var/log/mydebug.log
EOF

sudo rsyslogd -N1
sudo systemctl restart rsyslog
```

Prove it:

```bash
logger -p user.debug "EX200 debug test message"
sudo tail -5 /var/log/mydebug.log
```

You should see your message. Also check the file was created with a sensible context:

```bash
ls -lZ /var/log/mydebug.log
```

**`rsyslogd -N1` is the syntax check** — run it before restarting, the same discipline as `sshd -t` and `visudo -c`. And **`logger` is how you generate a test message**; without it you would be waiting for the system to produce one naturally.

Be aware that `*.debug` is extremely verbose and this file will grow quickly. In practice you would add a `logrotate` entry for it.

**Task 11.**

```bash
sudo tee /etc/rsyslog.d/local7.conf <<'EOF'
local7.=info    /var/log/local7.log
EOF

sudo rsyslogd -N1
sudo systemctl restart rsyslog
```

Test all three cases:

```bash
logger -p local7.info "should appear"
logger -p local7.err  "should NOT appear"
logger -p local7.debug "should NOT appear"
sudo cat /var/log/local7.log
```

Only the `info` line appears.

**The `=` means exactly that priority.** Without it, `local7.info` would match info **and everything more severe**. That distinction is the point of this task:

| Rule | Matches |
| --- | --- |
| `local7.info` | info, notice, warning, err, crit, alert, emerg |
| **`local7.=info`** | **info only** |
| `local7.!info` | everything except info and above |

**Task 12.**

```bash
PID=$(systemctl show -p MainPID --value sshd)
journalctl _PID=$PID
```

The `_PID=` form uses journald's structured metadata fields, which is more precise than grepping text. Related fields:

```bash
journalctl _COMM=sshd            # by command name
journalctl _UID=1001             # by user ID
journalctl _SYSTEMD_UNIT=sshd.service
journalctl -o verbose -n1        # see EVERY available field
```

`journalctl -o verbose` is how you discover which fields exist for filtering. This structured metadata is journald's main advantage over plain text logs.

**Task 13.**

```bash
journalctl -u httpd --since "09:00" --until "10:00"
```

Times without a date mean today. Fuller forms:

```bash
journalctl -u httpd --since "2026-08-18 09:00:00" --until "2026-08-18 10:00:00"
journalctl -u httpd --since "1 hour ago"
journalctl -u httpd --since yesterday --until today
```

The time parser accepts `today`, `yesterday`, `tomorrow`, `now`, and relative forms like `-1h` or `"30 min ago"`.

**Task 14.**

```bash
journalctl --list-boots
```

```text
IDX BOOT ID     FIRST ENTRY                 LAST ENTRY
 -2 abc123...   Tue 2026-08-18 09:00:00     Tue 2026-08-18 12:00:00
 -1 def456...   Tue 2026-08-18 12:05:00     Tue 2026-08-18 16:00:00
  0 ghi789...   Tue 2026-08-18 16:05:00     Tue 2026-08-18 18:30:00
```

```bash
journalctl -b -2 -p err
```

**This only works with a persistent journal** (Task 4). Without it, only boot `0` exists.

**Task 15.**

```bash
sudo ls -l /var/log/messages*
sudo logrotate -f /etc/logrotate.conf
sudo ls -l /var/log/messages*
```

You should now see `/var/log/messages-YYYYMMDD` alongside a fresh, small `/var/log/messages`.

To see what logrotate *would* do without doing it:

```bash
sudo logrotate -d /etc/logrotate.conf 2>&1 | head -40
```

`-d` is debug mode: it explains its decisions and changes nothing. Use it before `-f` when you are unsure.

Check the timer that runs it:

```bash
systemctl list-timers logrotate.timer
```

---

## Verify

```bash
ls -ld /var/log/journal
journalctl --list-boots                # more than one entry
journalctl --disk-usage
grep -E '^(Storage|SystemMaxUse)' /etc/systemd/journald.conf
systemd-analyze cat-config systemd/journald.conf | grep -E 'Storage|MaxUse'
sudo rsyslogd -N1 && echo "rsyslog config OK"
ls -l /var/log/mydebug.log /var/log/local7.log
sudo tail -3 /var/log/secure
```

## Persistence Check

| Change | Persistent artifact | Also needs |
| --- | --- | --- |
| **`/var/log/journal` exists** | The directory itself | `systemctl restart systemd-journald` |
| `Storage=persistent` | `/etc/systemd/journald.conf` or a drop-in | Restart journald |
| `SystemMaxUse=500M` | Same | Restart journald |
| rsyslog rules | `/etc/rsyslog.d/*.conf` | `systemctl restart rsyslog` |
| `journalctl --vacuum-*` | Immediate, one-off | Nothing |
| logrotate rules | `/etc/logrotate.d/*` | Nothing; the timer runs it |

**The whole point of this file's main objective is persistence**, so verify it properly:

```bash
sudo reboot
journalctl --list-boots           # must show at least 2 entries
journalctl -b -1 | head -5        # the previous boot must be readable
ls /var/log/journal/              # a machine-id directory must exist
```

Also confirm the services are enabled, since a stopped rsyslog writes nothing:

```bash
systemctl is-enabled rsyslog systemd-journald
systemctl is-active rsyslog systemd-journald
```

`systemd-journald` is `static` — it cannot be enabled or disabled because it is always required. That is expected, not a problem.

## Quick Reference

Come back here when you need a command you forgot — not before your first pass through Follow Along.

### Two logging systems, side by side

RHEL runs both:

| | **systemd-journald** | **rsyslog** |
| --- | --- | --- |
| Reads with | `journalctl` | `cat`, `less`, `grep`, `tail` |
| Format | Binary, indexed, structured | Plain text |
| Default storage | **`/run/log/journal`** — memory, **lost on reboot** | `/var/log/*` — on disk |
| Persistent storage | `/var/log/journal` — you must create it | Always |
| Config | `/etc/systemd/journald.conf` | `/etc/rsyslog.conf`, `/etc/rsyslog.d/*.conf` |
| Strength | Metadata, per-unit filtering, priorities | Simple text, remote forwarding, custom files |

`rsyslog` receives its messages from journald, which is why the same events appear in both.

### The text log files

```bash
/var/log/messages        # most system messages. THE general-purpose log
/var/log/secure          # authentication, sudo, sshd. THE security log
/var/log/maillog         # mail
/var/log/cron            # cron job execution
/var/log/boot.log        # boot messages
/var/log/dmesg           # kernel ring buffer at boot
/var/log/audit/audit.log # SELinux and audit events (auditd, not rsyslog)
/var/log/httpd/          # per-application directories
/var/log/lastlog         # binary; read with `lastlog`
/var/log/wtmp            # binary; read with `last`
/var/log/btmp            # binary; read with `lastb`
```

**The two to remember: `/var/log/messages` for general problems, `/var/log/secure` for authentication.** When SSH key authentication fails, the reason is in `/var/log/secure` (see `09-ssh.md`). When a service misbehaves, `/var/log/messages` or the journal.

```bash
sudo tail -f /var/log/messages
sudo tail -50 /var/log/secure
sudo grep -i fail /var/log/secure
sudo zgrep -i error /var/log/messages-*.gz    # rotated logs are gzipped
```

### journalctl

```bash
journalctl                          # everything, oldest first, in a pager
journalctl -e                       # jump to the END
journalctl -f                       # FOLLOW, like tail -f
journalctl -n 50                    # last 50 lines
journalctl -r                       # reverse: newest first
journalctl --no-pager
journalctl -o verbose               # all metadata fields
journalctl -o json-pretty

# By unit
journalctl -u sshd
journalctl -u sshd -f
journalctl -xeu httpd               # THE debugging command

# By boot
journalctl -b                       # this boot
journalctl -b -1                    # previous boot
journalctl --list-boots

# By time
journalctl --since "2026-08-18 10:00:00"
journalctl --since today
journalctl --since yesterday --until today
journalctl --since "1 hour ago"
journalctl --since "10 min ago"
journalctl --since "09:00" --until "10:00"

# By priority
journalctl -p err                   # err and worse
journalctl -p warning..err          # a range
journalctl -p 3

# By other fields
journalctl _UID=1001
journalctl _PID=1234
journalctl _COMM=sshd
journalctl /usr/sbin/httpd          # by executable path
journalctl -k                       # KERNEL messages only (= dmesg)
journalctl --user                   # the current user's session units

# Combining
journalctl -u httpd -p err --since today --no-pager
```

**`journalctl -xeu UNIT` is the command to internalise:** `-x` adds explanatory help text, `-e` jumps to the end, `-u` filters to one unit. It is the fastest route from "the service failed" to "here is why".

### Priority levels

```text
0  emerg     system is unusable
1  alert     action must be taken immediately
2  crit      critical
3  err       error
4  warning   warning
5  notice    normal but significant
6  info      informational
7  debug     debug
```

`journalctl -p err` shows priority 3 **and everything more severe** (2, 1, 0). Lower number means more serious. The names and numbers are interchangeable: `-p 3` equals `-p err`.

### Making the journal persistent

**This is the "preserve system journals" objective.** By default the journal lives in `/run/log/journal`, which is a tmpfs, so **it is erased at every reboot**. That is why `journalctl -b -1` often returns nothing.

Three ways to fix it. Any of them is acceptable, but know at least one cold.

**Method 1 — create the directory (simplest):**

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

journald's default `Storage=auto` means "persistent if `/var/log/journal` exists, volatile otherwise". Creating the directory is genuinely sufficient.

**Method 2 — set it explicitly in the config (most explicit, best for the exam):**

```bash
sudo mkdir -p /var/log/journal
sudo sed -i 's/^#\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
grep -E '^Storage' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
```

**Method 3 — a drop-in file (cleanest):**

```bash
sudo mkdir -p /etc/systemd/journald.conf.d /var/log/journal
sudo tee /etc/systemd/journald.conf.d/persistent.conf <<'EOF'
[Journal]
Storage=persistent
EOF
sudo systemctl restart systemd-journald
```

Verify it worked:

```bash
ls -ld /var/log/journal
ls /var/log/journal/                # a machine-id directory should appear
journalctl --disk-usage
sudo reboot
journalctl --list-boots             # after the reboot, MORE THAN ONE entry
journalctl -b -1 | head             # the previous boot is readable
```

**`journalctl --list-boots` showing more than one boot is the proof.** If it still shows one, the journal is not persistent.

The `Storage=` values:

| Value | Meaning |
| --- | --- |
| `volatile` | Memory only, always |
| `persistent` | On disk, creating `/var/log/journal` if needed |
| **`auto`** | **The default.** Persistent if `/var/log/journal` exists, else volatile |
| `none` | Discard everything |

### Limiting journal size

```bash
sudo vi /etc/systemd/journald.conf
```

```text
[Journal]
Storage=persistent
SystemMaxUse=500M          # total disk the journal may use
SystemKeepFree=1G          # leave at least this much free
SystemMaxFileSize=100M     # per journal file
MaxRetentionSec=1month     # discard entries older than this
MaxFileSec=1week           # rotate files at least this often
```

```bash
sudo systemctl restart systemd-journald
journalctl --disk-usage
```

Manual cleanup:

```bash
sudo journalctl --vacuum-size=200M      # shrink to 200 MB
sudo journalctl --vacuum-time=2weeks    # drop entries older than 2 weeks
sudo journalctl --vacuum-files=5        # keep at most 5 journal files
sudo journalctl --rotate                # rotate now
sudo journalctl --verify                # integrity check
```

### rsyslog configuration

Useful when a task says "send messages of type X to file Y".

```bash
cat /etc/rsyslog.conf
ls /etc/rsyslog.d/
```

The rule syntax is `facility.priority   destination`:

```text
*.info;mail.none;authpriv.none;cron.none    /var/log/messages
authpriv.*                                  /var/log/secure
mail.*                                      -/var/log/maillog
cron.*                                      /var/log/cron
*.emerg                                     :omusrmsg:*
local7.*                                    /var/log/boot.log
```

Facilities: `auth`, `authpriv`, `cron`, `daemon`, `kern`, `lpr`, `mail`, `news`, `syslog`, `user`, `uucp`, `local0`-`local7`.

Priorities, least to most severe: `debug`, `info`, `notice`, `warning`, `err`, `crit`, `alert`, `emerg`.

Modifiers worth knowing:

| Syntax | Meaning |
| --- | --- |
| `mail.info` | mail facility, info **and above** |
| `mail.=info` | **exactly** info, nothing else |
| `mail.!info` | everything **except** info and above |
| `mail.none` | exclude mail entirely from this rule |
| `*.info` | any facility, info and above |
| `-/var/log/maillog` | The leading `-` means **do not sync after each write** (faster) |

Adding a custom rule:

```bash
sudo tee /etc/rsyslog.d/custom.conf <<'EOF'
# All debug-level and above messages to a dedicated file
*.debug    /var/log/mydebug.log
EOF

sudo rsyslogd -N1                        # SYNTAX CHECK
sudo systemctl restart rsyslog
logger -p user.debug "test message"      # generate a message
sudo tail /var/log/mydebug.log
```

**`rsyslogd -N1` validates the configuration**, analogous to `sshd -t`. And **`logger` is how you generate a test message** — indispensable for proving a logging task actually works.

```bash
logger "a plain message"                       # facility user, priority notice
logger -p local7.err "an error"
logger -t myapp "tagged message"
logger -p authpriv.info "auth test"
```

### Log rotation

`logrotate` prevents logs consuming the disk. Runs daily via a systemd timer.

```bash
cat /etc/logrotate.conf
ls /etc/logrotate.d/
sudo logrotate -d /etc/logrotate.conf         # DEBUG: show what it would do
sudo logrotate -f /etc/logrotate.conf         # FORCE a rotation now
systemctl list-timers | grep logrotate
```

A typical entry:

```text
/var/log/myapp.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
```

`rotate 4` keeps four old copies; `compress` gzips them, which is why you need `zgrep` for older logs.

### Reading the kernel ring buffer

```bash
dmesg
dmesg -T                     # human-readable timestamps
dmesg -l err,warn            # by level
dmesg | grep -i error
dmesg -w                     # follow
journalctl -k                # the same content, via the journal
journalctl -k -b -1          # kernel messages from the previous boot
```

**`dmesg -T`** is the one to remember; raw `dmesg` timestamps are seconds since boot, which are hard to correlate with anything.

## Exam Tips

- **"Preserve system journals" means `mkdir -p /var/log/journal`** plus `Storage=persistent` and a journald restart. This is a specific, predictable task.
- **The proof is `journalctl --list-boots` showing more than one boot.**
- By default the journal is in **`/run/log/journal`** — memory-backed and **wiped every reboot**.
- **`journalctl -xeu UNIT`** is the debugging command: explain, jump to end, filter by unit.
- **`-b`** this boot, **`-b -1`** previous, **`--list-boots`** all.
- **`-p err`** shows err **and worse**. Priorities: 0 emerg, 3 err, 4 warning, 6 info, 7 debug. Lower is more severe.
- **`--since` / `--until`** accept `today`, `yesterday`, `"1 hour ago"`, and absolute timestamps.
- **`journalctl -f`** follows; **`-n`** limits; **`-k`** is kernel only; **`-o verbose`** reveals all filterable fields.
- **`_PID=`, `_COMM=`, `_UID=`, `_SYSTEMD_UNIT=`** are structured filters, more precise than grep.
- **`journalctl --disk-usage`**, **`--vacuum-size=`**, **`--vacuum-time=`** manage space now; **`SystemMaxUse=`** governs future growth.
- **`/var/log/messages`** for general problems, **`/var/log/secure`** for authentication. Memorise these two.
- Rotated logs are gzipped, so use **`zgrep`** and **`zcat`**.
- rsyslog syntax is **`facility.priority  destination`**. **`=info` means exactly info**; plain `info` means info and above; `none` excludes.
- **`rsyslogd -N1`** validates rsyslog config before you restart it.
- **`logger -p facility.priority "message"`** generates a test message. Essential for proving a logging task works.
- **`dmesg -T`** for readable kernel timestamps. Raw `dmesg` shows seconds since boot.
- **`logrotate -d`** to preview, **`-f`** to force.
- `systemd-analyze cat-config systemd/journald.conf` shows the merged config including drop-ins.
