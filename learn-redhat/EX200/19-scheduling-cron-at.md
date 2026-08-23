# 19. Scheduling Tasks: cron, at, And systemd Timers

**Objective:** Schedule tasks using `at` and `cron`. (RHEL 10 objectives also mention systemd timers.)

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Reading every cron field upfront feels like learning. Typing them one at a time actually is.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Which tool for which job

| Tool | Use for |
| --- | --- |
| **`crontab -e`** | **Recurring jobs owned by a user** — the usual exam answer |
| `/etc/cron.d/*` | Recurring jobs as files, with a user field |
| **`at`** | **A single job at a specific future time** |
| **systemd timers** | Modern equivalent of cron, with dependency handling |

**"Schedule a recurring job" means cron. "Schedule a one-off job" means `at`.**

Confirm cron is running:

```bash
systemctl is-active crond
sudo tail -5 /var/log/cron
```

**You should see** `active` and recent `(root) CMD (...)` lines if jobs have run.

### 2. Read the crontab time fields

```text
┌───────────── minute        (0-59)
│ ┌─────────── hour          (0-23)
│ │ ┌───────── day of month  (1-31)
│ │ │ ┌─────── month         (1-12)
│ │ │ │ ┌───── day of week   (0-7, 0 and 7 are Sunday)
│ │ │ │ │
* * * * *  command
```

Examples to read instantly:

```text
30 2 * * *          02:30 every day
*/15 * * * *        every 15 minutes
0 9 * * 1-5         09:00 Monday to Friday
0 0 1 * *           midnight on the 1st of each month
```

**Minute first, then hour.** `23 14 * * *` is 14:23, not 23:14.

### 3. User crontabs

```bash
crontab -l
sudo ls -l /var/spool/cron/
```

**You should see** your crontab (or "no crontab") and spool files under `/var/spool/cron/<username>`.

Add a test entry non-interactively:

```bash
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/bin/date >> /tmp/cron-test.log 2>&1") | crontab -
crontab -l
```

**You should see** the new line. **Always use absolute paths** and redirect output so failures are visible.

Remove it when done:

```bash
crontab -l | grep -v cron-test | crontab -
```

### 4. The user-field trap in system crontabs

`/etc/crontab` and `/etc/cron.d/*` add a **user** field between the schedule and the command:

```text
30 2 * * *  root  /usr/local/bin/backup.sh
```

User crontabs from `crontab -e` have **no user field**. Adding one to a personal crontab breaks it.

Deploy via `/etc/cron.d/`:

```bash
sudo tee /etc/cron.d/demo <<'EOF'
# Demo job every hour
0 * * * * root /usr/bin/logger "cron.d demo ran"
EOF
sudo chmod 644 /etc/cron.d/demo
```

**You should see** the file is mode `644`, owned by root, and **the filename has no dot** — `run-parts` silently skips `demo.cron`.

### 5. cron.daily: simplest scheduling

```bash
sudo tee /etc/cron.daily/demo-daily <<'EOF'
#!/bin/bash
/usr/bin/logger "cron.daily demo ran"
EOF
sudo chmod +x /etc/cron.daily/demo-daily
sudo run-parts --test /etc/cron.daily
```

**You should see** `demo-daily` listed. The file must be **executable** and have **no dot in the name**.

### 6. Escape percent signs in crontabs

In a crontab, `%` is special. This fails silently:

```text
0 2 * * * /usr/bin/tar -czf /backup/data-$(date +%F).tar.gz /home
```

This works:

```text
0 2 * * * /usr/bin/tar -czf /backup/data-$(date +\%F).tar.gz /home
```

**Prefer putting complex logic in a script** — no escaping needed, and you can test it by hand.

### 7. at: one-off jobs

```bash
sudo dnf install -y at
sudo systemctl enable --now atd
systemctl is-active atd
```

Schedule non-interactively:

```bash
echo "/usr/bin/touch /tmp/at-ran" | at now + 2 minutes
atq
```

**You should see** a queued job. **`atd` must be enabled and running** — without it, jobs queue but never execute.

After two minutes:

```bash
ls -l /tmp/at-ran
atq
```

Inspect and remove:

```bash
at -c $(atq | awk '{print $1}' | head -1) | tail -10
atrm $(atq | awk '{print $1}' | head -1)
```

### 8. Access control

```bash
ls /etc/cron.allow /etc/cron.deny 2>/dev/null
```

**If `/etc/cron.allow` exists, `/etc/cron.deny` is ignored entirely** and only listed users (plus root) may use cron.

### 9. systemd timers: service + timer

```bash
sudo tee /etc/systemd/system/demo.service <<'EOF'
[Unit]
Description=Demo oneshot service

[Service]
Type=oneshot
ExecStart=/usr/bin/logger "systemd timer demo ran"
EOF

sudo tee /etc/systemd/system/demo.timer <<'EOF'
[Unit]
Description=Run demo every 15 minutes

[Timer]
OnCalendar=*:0/15
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now demo.timer
systemctl list-timers demo.timer
```

**You should see** the next scheduled run. **Enable the `.timer`, not the `.service`.** Use **`WantedBy=timers.target`**, not `multi-user.target`.

Validate calendar syntax:

```bash
systemd-analyze calendar "*:0/15" --iterations=3
```

Clean up:

```bash
sudo systemctl disable --now demo.timer
sudo rm /etc/systemd/system/demo.{service,timer}
sudo systemctl daemon-reload
```

### 10. Debug a cron failure

```bash
sudo journalctl -u crond --since today | tail -10
sudo grep CMD /var/log/cron | tail -5
```

**You should see** that cron **ran** a job — but not its output unless you redirected it. The three fixes: absolute paths, explicit `cd` or absolute file references, and `>> /var/log/job.log 2>&1`.

### Mini checkpoint

| Concept | Remember |
| --- | --- |
| Field order | minute, hour, day-of-month, month, day-of-week |
| `*/15` | every 15 minutes |
| `/etc/cron.d/*` | has USER field; no dot in filename; mode 644 |
| `crontab -e` | no USER field |
| `\%` in crontab | escape percent signs |
| `atd` | must be enabled for `at` to work |
| systemd timer | enable `.timer`, `WantedBy=timers.target`, `Persistent=true` |

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** As user `alice`, schedule a job that writes the date to `/home/alice/date.log` every day at 14:23.

> Hint: `sudo -u alice crontab -e` or pipe to `crontab -`; minute 23, hour 14.

**Task 2.** List alice's scheduled jobs as root, without switching to her account.

> Hint: `crontab -l -u alice`.

**Task 3.** Schedule a job as root that runs `/usr/local/bin/cleanup.sh` every 15 minutes, discarding all output.

> Hint: `*/15` in the minute field; `> /dev/null 2>&1`.

**Task 4.** Schedule a job that runs at 03:00 on the first day of every month, logging its output to `/var/log/monthly.log`.

> Hint: `0 3 1 * *`; do not also set day-of-week.

**Task 5.** Schedule a job that creates a tar archive named with today's date, at 02:00 daily. The filename must include the date correctly.

> Hint: escape `\%F` in crontab, or use a script.

**Task 6.** Create a system-wide cron job as a file in `/etc/cron.d/` that runs a script hourly as the `apache` user.

> Hint: USER field between schedule and command; chmod 644; no dot in filename.

**Task 7.** Arrange for a script to run daily without specifying a time, using the simplest possible mechanism.

> Hint: executable script in `/etc/cron.daily/`, no dot in name.

**Task 8.** Schedule a one-off job to create `/tmp/at-test` five minutes from now. Verify it is queued, then verify it ran.

> Hint: install and enable `atd` first; `echo "cmd" | at now + 5 minutes`.

**Task 9.** List all pending `at` jobs, inspect the contents of one, then delete it.

> Hint: `atq`, `at -c N`, `atrm N`.

**Task 10.** Configure the system so that only users `alice` and `bob` may create cron jobs. Verify a third user is denied.

> Hint: `/etc/cron.allow` overrides `cron.deny`.

**Task 11.** Create a systemd timer that runs `/usr/local/bin/report.sh` every weekday at 09:00, and that catches up if the machine was off. Verify when it will next run.

> Hint: follow-along step 9; `OnCalendar=Mon..Fri 09:00`, `Persistent=true`.

**Task 12.** List every active systemd timer on the system with its next scheduled run.

> Hint: `systemctl list-timers`.

**Task 13.** A cron job appears in `crontab -l` but never produces output. Create this scenario with a script that works interactively but fails under cron, then diagnose and fix it.

> Hint: follow-along step 10; redirect output to see the error.

**Task 14.** Determine whether the `cron.daily` jobs ran today, and when.

> Hint: `/var/spool/anacron/cron.daily`, `journalctl -u crond`.

**Task 15.** Schedule a job to run once, at 22:00 tonight, using a script file rather than an inline command.

> Hint: `at -f /path/to/script.sh 22:00`.

---

## Solutions

**Task 1.**

```bash
sudo -u alice crontab -e
```

Add:

```text
23 14 * * * /usr/bin/date >> /home/alice/date.log 2>&1
```

Non-interactively, which is faster and scriptable:

```bash
sudo -u alice bash -c 'echo "23 14 * * * /usr/bin/date >> /home/alice/date.log 2>&1" | crontab -'
sudo -u alice crontab -l
```

**`crontab -` reads from stdin and replaces the whole crontab.** To *append* rather than replace:

```bash
sudo -u alice bash -c '(crontab -l 2>/dev/null; echo "23 14 * * * /usr/bin/date >> /home/alice/date.log") | crontab -'
```

Note the field order: **minute first, then hour.** `23 14` is 14:23, not 23:14. Reversing them is the single most common cron mistake.

**Task 2.**

```bash
sudo crontab -l -u alice
```

Or read the spool file:

```bash
sudo cat /var/spool/cron/alice
```

`crontab -l -u` is the correct tool; reading the spool file is for verification only.

**Task 3.**

```bash
sudo crontab -e
```

```text
*/15 * * * * /usr/local/bin/cleanup.sh > /dev/null 2>&1
```

`*/15` in the minute field means minutes 0, 15, 30, 45. Verify:

```bash
sudo crontab -l
```

`> /dev/null 2>&1` discards both stdout and stderr, which prevents cron generating mail every 15 minutes. If you want to keep the output, redirect to a log file instead.

**Task 4.**

```bash
sudo crontab -e
```

```text
0 3 1 * * /usr/local/bin/monthly.sh >> /var/log/monthly.log 2>&1
```

Reading it: minute 0, hour 3, day-of-month 1, any month, any weekday.

**Do not also set the day-of-week field**, because when both day fields are non-`*` cron runs on **either** match. `0 3 1 * 0` would run on the 1st *and* every Sunday.

**Task 5.**

```bash
sudo crontab -e
```

```text
0 2 * * * /usr/bin/tar -czf /backup/home-$(date +\%F).tar.gz /home >> /var/log/backup.log 2>&1
```

**The `%` must be escaped as `\%`.** In a crontab, an unescaped `%` terminates the command and everything after it becomes stdin for the command. Without the backslash, the command silently truncates to `tar -czf /backup/home-$(date +` and fails.

The more robust approach is to put the logic in a script, where no escaping is needed:

```bash
sudo tee /usr/local/bin/backup.sh <<'EOF'
#!/bin/bash
/usr/bin/tar -czf "/backup/home-$(date +%F).tar.gz" /home
EOF
sudo chmod +x /usr/local/bin/backup.sh
sudo mkdir -p /backup
```

```text
0 2 * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
```

**Prefer a script over a complex crontab line.** It is easier to test, needs no escaping, and you can run it by hand to verify.

**Task 6.**

```bash
sudo tee /etc/cron.d/apachejob <<'EOF'
# Run the apache maintenance script hourly
0 * * * * apache /usr/local/bin/apache-maint.sh >> /var/log/apache-maint.log 2>&1
EOF
sudo chmod 644 /etc/cron.d/apachejob
```

Verify:

```bash
sudo cat /etc/cron.d/apachejob
sudo journalctl -u crond --since "1 min ago"
```

Three requirements specific to `/etc/cron.d/`:

1. **The user field is mandatory** — `apache` sits between the schedule and the command. Omitting it makes cron treat `/usr/local/bin/...` as the username.
2. **Mode `644`, owned by root.**
3. **No dot in the filename.** `apachejob` is fine; `apachejob.cron` is ignored.

**Task 7.**

```bash
sudo tee /etc/cron.daily/mydailyjob <<'EOF'
#!/bin/bash
/usr/local/bin/mytask.sh >> /var/log/mytask.log 2>&1
EOF
sudo chmod +x /etc/cron.daily/mydailyjob
```

Verify:

```bash
ls -l /etc/cron.daily/
sudo run-parts --test /etc/cron.daily      # lists what WOULD run
sudo run-parts /etc/cron.daily             # actually run them, to test
```

Two requirements: **executable**, and **no dot in the filename**. `run-parts` silently skips `mydailyjob.sh`, which is a frustrating failure because the file looks perfectly correct.

This is the simplest scheduling mechanism available: no time syntax, no user field, just a script in a directory.

**Task 8.**

```bash
sudo dnf install -y at
sudo systemctl enable --now atd

echo "/usr/bin/touch /tmp/at-test" | at now + 5 minutes
atq
```

```text
3	Tue Aug 18 18:35:00 2026 a root
```

Wait, then verify:

```bash
ls -l /tmp/at-test
atq                       # the job is gone once it has run
sudo journalctl -u atd --since "10 min ago"
```

**`atd` must be enabled and active.** Without it, `at` accepts the job, `atq` shows it queued, and it never runs. Always check:

```bash
systemctl is-active atd
systemctl is-enabled atd
```

**Task 9.**

```bash
echo "/usr/bin/date >> /tmp/atlog" | at now + 1 hour
echo "/usr/bin/whoami >> /tmp/atlog" | at now + 2 hours

atq
```

```text
4	Tue Aug 18 19:30:00 2026 a root
5	Tue Aug 18 20:30:00 2026 a root
```

Inspect one:

```bash
at -c 4 | tail -20
```

This shows the full script `at` will execute, including the entire captured environment. **`at` preserves your environment at scheduling time**, which is why it is more forgiving than cron.

Delete it:

```bash
atrm 4
atq
```

`at -l` is a synonym for `atq`, and `at -d 4` for `atrm 4`.

**Task 10.**

```bash
sudo tee /etc/cron.allow <<'EOF'
alice
bob
EOF
sudo chmod 644 /etc/cron.allow
```

Verify:

```bash
sudo -u alice crontab -l                 # permitted (may be empty)
sudo -u carol crontab -l
```

```text
You (carol) are not allowed to use this program (crontab)
See crontab(1) for more information
```

**The precedence rule: once `/etc/cron.allow` exists, `/etc/cron.deny` is ignored completely**, and only the listed users (plus root) may use cron. If you only want to block one user, use `cron.deny` instead and do not create `cron.allow`:

```bash
sudo rm -f /etc/cron.allow
echo carol | sudo tee -a /etc/cron.deny
```

The same pair exists for `at`: `/etc/at.allow` and `/etc/at.deny`.

**Task 11.**

The service:

```bash
sudo tee /usr/local/bin/report.sh <<'EOF'
#!/bin/bash
echo "report generated $(date)" >> /var/log/report.log
EOF
sudo chmod +x /usr/local/bin/report.sh

sudo tee /etc/systemd/system/report.service <<'EOF'
[Unit]
Description=Generate the daily report

[Service]
Type=oneshot
ExecStart=/usr/local/bin/report.sh
EOF
```

The timer:

```bash
sudo tee /etc/systemd/system/report.timer <<'EOF'
[Unit]
Description=Run report.sh weekdays at 09:00

[Timer]
OnCalendar=Mon..Fri 09:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemd-analyze verify /etc/systemd/system/report.timer
sudo systemctl daemon-reload
sudo systemctl enable --now report.timer
```

Verify:

```bash
systemctl list-timers report.timer
```

```text
NEXT                        LEFT      LAST  PASSED  UNIT         ACTIVATES
Wed 2026-08-19 09:00:00 EAT 14h left  -     -       report.timer report.service
```

Validate the calendar expression independently:

```bash
systemd-analyze calendar "Mon..Fri 09:00" --iterations=5
```

Test the service without waiting:

```bash
sudo systemctl start report.service
sudo cat /var/log/report.log
journalctl -u report.service
```

Four things to get right, each of which is a way to fail:

1. **Enable the `.timer`, not the `.service`.** Enabling the service makes it run at boot instead.
2. **`WantedBy=timers.target`** in the timer's `[Install]`, not `multi-user.target`.
3. **`Type=oneshot`** in the service, since the script exits.
4. **`Persistent=true`** so a missed run happens after a reboot — that is what "catches up if the machine was off" means.

**Task 12.**

```bash
systemctl list-timers
systemctl list-timers --all              # including inactive
```

You will see `logrotate.timer`, `dnf-makecache.timer`, `fstrim.timer`, and any you created. The `NEXT` and `LEFT` columns tell you exactly when each fires, which is a real advantage over cron.

**Task 13.**

Create the scenario. A script that relies on `PATH` and on being run from a particular directory:

```bash
sudo tee /usr/local/bin/fragile.sh <<'EOF'
#!/bin/bash
# depends on PATH and on the working directory
tar -czf backup.tar.gz ./data
echo "done at $(date)"
EOF
sudo chmod +x /usr/local/bin/fragile.sh

sudo mkdir -p /opt/app/data
sudo touch /opt/app/data/file1

# works interactively
cd /opt/app && sudo /usr/local/bin/fragile.sh && ls -l backup.tar.gz
```

Now schedule it and watch it fail:

```bash
sudo crontab -e
```

```text
*/2 * * * * /usr/local/bin/fragile.sh
```

Diagnose:

```bash
sudo journalctl -u crond --since "5 min ago"
sudo grep CMD /var/log/cron | tail -3
```

The log shows the job **ran**, but nothing was produced. That is the signature of an environment problem. The output went to mail, which is not configured, so it vanished.

**Step one is always to capture the output:**

```bash
sudo crontab -e
```

```text
*/2 * * * * /usr/local/bin/fragile.sh >> /var/log/fragile.log 2>&1
```

Wait two minutes, then:

```bash
sudo cat /var/log/fragile.log
```

```text
tar: ./data: Cannot stat: No such file or directory
```

Now the cause is obvious: cron runs with the user's home as the working directory, not `/opt/app`.

Fix the script to be independent of environment:

```bash
sudo tee /usr/local/bin/fragile.sh <<'EOF'
#!/bin/bash
set -euo pipefail
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
cd /opt/app || exit 1
/usr/bin/tar -czf /opt/app/backup.tar.gz /opt/app/data
echo "done at $(date)"
EOF
sudo chmod +x /usr/local/bin/fragile.sh
```

Verify:

```bash
sudo cat /var/log/fragile.log
ls -l /opt/app/backup.tar.gz
```

Clean up:

```bash
sudo crontab -l | grep -v fragile | sudo crontab -
```

**The three fixes, which prevent nearly every cron failure:** absolute paths, an explicit `cd` or absolute file references, and redirected output so you can see the error at all. The redirect is the most important because without it you are debugging blind.

**Task 14.**

```bash
sudo journalctl -u crond --since today | grep -i daily
sudo grep -i 'cron.daily\|anacron' /var/log/cron | tail
sudo cat /var/spool/anacron/cron.daily
```

`/var/spool/anacron/cron.daily` holds the date the daily jobs last ran, which is how `anacron` knows whether a run was missed:

```text
20260818
```

Also:

```bash
systemctl list-timers | grep -i anacron
ls -l /etc/cron.daily/
```

**Task 15.**

```bash
sudo tee /usr/local/bin/tonight.sh <<'EOF'
#!/bin/bash
echo "ran at $(date)" >> /var/log/tonight.log
EOF
sudo chmod +x /usr/local/bin/tonight.sh

sudo at -f /usr/local/bin/tonight.sh 22:00
sudo atq
sudo at -c $(sudo atq | awk '{print $1}' | head -1) | tail -5
```

`-f` takes the commands from a file rather than stdin. The equivalents:

```bash
echo "/usr/local/bin/tonight.sh" | sudo at 22:00
sudo at 22:00 < /usr/local/bin/tonight.sh
```

Note that `at -f script` reads the **contents** of the script as the job body, so the script's shebang is not honoured the way it would be if executed. Piping the script's *path* to `at` is usually what you actually want, because then the shebang applies.

---

## Verify

```bash
sudo crontab -l
sudo crontab -l -u alice
sudo ls -l /etc/cron.d/ /etc/cron.daily/
sudo atq
systemctl list-timers
systemctl is-enabled crond atd
systemctl is-active crond atd
cat /etc/cron.allow 2>/dev/null
sudo grep CMD /var/log/cron | tail -5
```

## Persistence Check

| Item | Persistent artifact | Also required |
| --- | --- | --- |
| User crontab | `/var/spool/cron/<user>` | **`crond` enabled** |
| `/etc/cron.d/*` | The file, mode 644, root-owned, no dot in name | `crond` enabled |
| `/etc/cron.daily/*` | The file, **executable**, no dot in name | `crond` enabled |
| `at` job | `/var/spool/at/*` | **`atd` enabled** |
| systemd timer | Both unit files in `/etc/systemd/system/` | **The `.timer` enabled** |

**Two services must be enabled or none of this works:**

```bash
sudo systemctl enable --now crond
sudo systemctl enable --now atd
```

`crond` is enabled by default on RHEL; `atd` often is **not**, and `at` is sometimes not even installed. If a task involves `at`, install the package and enable the service — this is a very commonly missed step.

Post-reboot verification:

```bash
systemctl is-enabled crond atd
systemctl is-active crond atd
sudo crontab -l                        # still there
sudo atq                               # pending jobs survived
systemctl list-timers                  # timers still scheduled
```

`at` jobs do survive a reboot, because they are files in `/var/spool/at/`. A job whose scheduled time passed while the machine was off runs when `atd` starts.

## Quick Reference

Come back here when you need a command you forgot — not before your first pass through Follow Along.

### Which tool for which job

| Tool | Use for | Persistent |
| --- | --- | :---: |
| **`crontab -e`** | **Recurring jobs owned by a user.** The usual exam answer | Yes |
| `/etc/cron.d/*` | Recurring jobs deployed as files, with a user field | Yes |
| `/etc/crontab` | System-wide, but avoid editing it directly | Yes |
| `/etc/cron.{hourly,daily,weekly,monthly}/` | Drop a **script** in, no schedule syntax needed | Yes |
| **`at`** | **A single job at a specific future time** | Yes |
| `anacron` | Jobs that must run even if the machine was off | Yes |
| **systemd timers** | The modern equivalent of cron, with dependency handling | Yes |

### The crontab time fields

```text
┌───────────── minute        (0-59)
│ ┌─────────── hour          (0-23)
│ │ ┌───────── day of month  (1-31)
│ │ │ ┌─────── month         (1-12, or jan-dec)
│ │ │ │ ┌───── day of week   (0-7, 0 and 7 are Sunday, or sun-sat)
│ │ │ │ │
* * * * *  command to execute
```

Special characters:

| Syntax | Meaning |
| --- | --- |
| `*` | Every value |
| `5` | Exactly 5 |
| `1,15,30` | A list |
| `1-5` | A range |
| **`*/10`** | **Every 10 units** (step) |
| `0-30/5` | Every 5 within a range |

Examples worth being able to read and write instantly:

```text
30 2 * * *          02:30 every day
0 */2 * * *         every 2 hours, on the hour
*/15 * * * *        every 15 minutes
0 9 * * 1-5         09:00 Monday to Friday
0 0 1 * *           midnight on the 1st of each month
0 3 * * 0           03:00 every Sunday
45 23 * * 6         23:45 every Saturday
0 12 1,15 * *       noon on the 1st and 15th
15 14 1 * *         14:15 on the 1st of every month
0 22 * * 1-5        22:00 on weekdays
```

Special strings, which replace all five fields:

```text
@reboot        once, at boot
@yearly        0 0 1 1 *
@annually      same
@monthly       0 0 1 * *
@weekly        0 0 * * 0
@daily         0 0 * * *
@midnight      same
@hourly        0 * * * *
```

**One trap: if both day-of-month and day-of-week are specified (neither is `*`), cron runs when EITHER matches, not both.** So `0 0 13 * 5` runs on the 13th of every month **and** on every Friday. This is unintuitive and occasionally examined.

### User crontabs

```bash
crontab -e                    # edit YOUR crontab
crontab -l                    # list yours
crontab -r                    # REMOVE yours entirely. No confirmation
crontab -l -u alice           # list alice's         (root only)
crontab -e -u alice           # edit alice's         (root only)
crontab -r -u alice           # remove alice's       (root only)
crontab myfile                # INSTALL a file as your crontab (replaces it)
```

**`crontab -r` deletes the whole crontab with no prompt.** The keys `r` and `e` are adjacent. Back up first:

```bash
crontab -l > ~/crontab.bak
```

User crontabs are stored in `/var/spool/cron/<username>`:

```bash
sudo ls -l /var/spool/cron/
sudo cat /var/spool/cron/alice
```

**Do not edit those files directly** — `crontab -e` validates the syntax and signals crond. Reading them to verify is fine.

### System crontabs have an extra field

```text
# /etc/crontab and /etc/cron.d/*
30 2 * * *  root  /usr/local/bin/backup.sh
│                 │
└─ 5 time fields  └─ command
            └─ USER — present here, ABSENT in user crontabs
```

Deploying via `/etc/cron.d/`:

```bash
sudo tee /etc/cron.d/backup <<'EOF'
# Nightly backup at 02:30
30 2 * * * root /usr/local/bin/backup.sh
EOF
sudo chmod 644 /etc/cron.d/backup
```

Files in `/etc/cron.d/` must be mode `644` and owned by root, and **the filename must not contain a dot**.

### The cron environment

cron runs with a **minimal environment**:

```text
PATH=/sbin:/bin:/usr/sbin:/usr/bin     <- very short
SHELL=/bin/sh
HOME=the user's home
No .bashrc, no .bash_profile, no aliases, no functions
```

Three rules that avoid almost every cron failure:

1. **Use absolute paths for everything.**
2. **Capture the output:** `>> /var/log/job.log 2>&1`
3. **Escape percent signs:** `date +\%F` in crontab lines

### at: one-off jobs

```bash
sudo dnf install -y at
sudo systemctl enable --now atd          # REQUIRED, or nothing runs

at 14:30                                 # interactive; Ctrl+d to finish
at now + 5 minutes
echo "/usr/local/bin/task.sh" | at 14:30 # non-interactive. Easiest

atq                                      # list pending jobs (= at -l)
atrm 3                                   # remove job 3   (= at -d 3)
at -c 3                                  # show job 3's full contents
batch                                    # run when load average drops below 0.8
```

### systemd timers

A timer needs **two units**: a `.service` and a `.timer`.

```bash
sudo tee /etc/systemd/system/backup.service <<'EOF'
[Unit]
Description=Nightly backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
EOF

sudo tee /etc/systemd/system/backup.timer <<'EOF'
[Unit]
Description=Run backup daily at 02:30

[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer
```

**You enable the `.timer`, not the `.service`.** **`WantedBy=timers.target`**, not `multi-user.target`. **`Persistent=true`** catches up missed runs after downtime.

```bash
systemctl list-timers                    # all active timers, with next run time
systemd-analyze calendar "Mon..Fri 09:00" --iterations=3
```

### Access control

```bash
/etc/cron.allow      # if it EXISTS, only listed users may use cron
/etc/cron.deny       # listed users may not
/etc/at.allow
/etc/at.deny
```

**If `cron.allow` exists, `cron.deny` is ignored entirely.** root is always permitted.

## Exam Tips

- **Field order: minute, hour, day-of-month, month, day-of-week.** `23 14 * * *` is 14:23. Reversing minute and hour is the most common error.
- **`*/15`** in the minute field means every 15 minutes.
- **`/etc/crontab` and `/etc/cron.d/*` have a USER field; personal crontabs do not.** Getting this wrong breaks the job.
- **Files in `/etc/cron.d/` and `/etc/cron.daily/` must not contain a dot in the filename.** `run-parts` silently skips them.
- **Files in `/etc/cron.daily/` must be executable.**
- **Escape `%` as `\%`** in crontab commands. `date +\%F`.
- **cron has a minimal PATH and no shell startup files.** Use absolute paths for everything.
- **Always redirect output** (`>> /var/log/x.log 2>&1`), or errors go to mail and you debug blind.
- **Prefer putting logic in a script** over a complex crontab line. No escaping, and you can test it by hand.
- **`crontab -r` deletes everything with no prompt.** Back up with `crontab -l > file` first.
- **`at` requires `atd` to be installed, enabled, and running.** Very commonly missed.
- **`echo "cmd" | at now + 5 minutes`** is the fast non-interactive form. **`atq`** lists, **`atrm N`** removes, **`at -c N`** shows the job.
- **`at` captures your current environment; cron does not.**
- **If `/etc/cron.allow` exists, `cron.deny` is ignored** and only listed users may use cron.
- **systemd timers: enable the `.timer`, not the `.service`.** Use **`WantedBy=timers.target`** and **`Persistent=true`** for catch-up.
- **`systemctl list-timers`** shows the next run time. **`systemd-analyze calendar "expr"`** validates an `OnCalendar` expression.
- **`anacron`** runs missed jobs after downtime; plain cron does not.
- Debug with **`journalctl -u crond`** and **`/var/log/cron`**, which show that a job ran but not its output.
