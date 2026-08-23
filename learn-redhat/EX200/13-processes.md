# 13. Processes: Monitoring, Killing, And Scheduling Priority

**Objectives:** Identify CPU/memory intensive processes and kill processes. Adjust process scheduling.

Process management is how you answer "which process is hogging the CPU?" and "make it stop" on the exam. The two commands you will type most are `ps aux --sort=-%cpu` and `kill` — everything else supports those.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Nice values go up when priority goes down — counter-intuitive by design, and examinable.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. List processes with `ps aux`

```bash
ps aux | head -6
```

**You should see** a header row plus five processes, with columns for USER, PID, %CPU, %MEM, VSZ, RSS, STAT, and COMMAND.

`ps aux` shows **every** process on the system in BSD style. The two you will actually type under time pressure are sorted variants — coming next.

### 2. Find the CPU hogs

```bash
ps aux --sort=-%cpu | head -6
```

**You should see** the same header, then processes ranked by CPU usage, highest first.

The `-` in `--sort=-%cpu` means **descending**. Without it you get the least busy processes first — wrong for this question.

### 3. Find the memory hogs — read RSS, not VSZ

```bash
ps aux --sort=-%mem | head -6
ps -eo pid,rss,%mem,comm --sort=-rss | head -6
```

**You should see** processes ranked by memory. The second command shows **RSS** in kilobytes — actual RAM in use.

**`RSS` is the number that matters for real memory use.** `VSZ` includes address space that is mapped but not resident, so it is often misleadingly large.

### 4. Read process states

```bash
ps -eo pid,stat,comm | head -10
```

**You should see** single-letter states like `S`, `R`, and possibly `I`.

| Code | Meaning |
| --- | --- |
| **`R`** | Running or runnable |
| **`S`** | Interruptible sleep |
| **`D`** | **Uninterruptible sleep** — blocked on I/O, **cannot be killed** |
| **`Z`** | **Zombie** — finished, parent has not reaped it |

If `kill -9` does nothing, check the state. A `D`-state process is stuck in the kernel.

### 5. Use `top` interactively

```bash
top
```

Press **`P`** to sort by CPU, **`M`** by memory, then **`q`** to quit.

**You should see** the sort order change when you press `P` and `M`.

Inside `top`: **`P`** CPU, **`M`** memory, **`k`** kill, **`r`** renice, **`q`** quit. `htop` is friendlier but is **not installed by default** — do not rely on it.

For a one-shot snapshot:

```bash
top -b -n1 | head -20
```

### 6. Check load average and CPU count

```bash
uptime
nproc
```

**You should see** three load numbers (1-, 5-, 15-minute averages) and an integer CPU count.

Compare load to `nproc`: load equal to the CPU count means fully busy; sustained load well above it means processes are queuing.

### 7. Read memory with `free`

```bash
free -h
```

**You should see** columns including `total`, `used`, `free`, and **`available`**.

In `free -h`, read the **`available`** column, not `free`. Linux deliberately uses spare RAM for cache, so a small `free` value is normal and healthy.

### 8. Kill politely with SIGTERM

```bash
sleep 900 &
echo $!
kill $!
pgrep sleep
```

**You should see** a PID from `echo $!`, then no `sleep` processes after `kill`.

`kill` with no signal sends **SIGTERM (15)** — a polite request to exit. Always try this first.

### 9. Kill by name with `pkill` and `killall`

```bash
sleep 900 & sleep 901 &
pgrep -a sleep
pkill sleep
pgrep sleep
```

**You should see** two sleeps listed, then nothing after `pkill`.

`pkill` matches a pattern; `killall` requires an exact command name. Both send SIGTERM by default. Use **`pkill -f`** when the process name is generic — it matches the full command line.

### 10. Start a process with low priority — `nice`

```bash
nice -n 19 sleep 900 &
ps -eo pid,ni,comm | grep sleep
```

**You should see** `NI` of **19** — the lowest priority (most polite).

Nice values run from **-20 (highest priority) to +19 (lowest)**. Default is 0. A *higher* nice number means a *lower* priority — a common exam trap.

### 11. Change priority on a running process — `renice`

```bash
sleep 900 &
PID=$!
renice -n 15 -p $PID
ps -eo pid,ni,comm -p $PID
```

**You should see** `NI` change to 15. Increasing niceness (lowering priority) does **not** require root when done by the process owner.

```bash
kill $PID
```

### 12. Only root can raise priority

```bash
sleep 900 &
PID=$!
renice -n -5 -p $PID
```

**You should see** `Permission denied`.

**Only root can lower a nice value** (raise priority). With sudo it succeeds:

```bash
sudo renice -n -5 -p $PID
ps -eo pid,ni,comm -p $PID
kill $PID
```

### 13. Find PIDs three ways

```bash
pgrep sshd
pidof sshd
ps -C sshd -o pid,comm
```

**You should see** one or more PIDs for the SSH daemon from each command.

For a systemd-managed service, `systemctl show -p MainPID sshd` gives the main process rather than every child.

### 14. Reload a daemon without restarting it

```bash
systemctl show -p CanReload --value rsyslog
sudo systemctl reload rsyslog
```

**You should see** `yes` for CanReload, and the reload completes without error.

**SIGHUP (signal 1)** makes most daemons reload configuration. `systemctl reload` is preferred because the unit file knows the correct mechanism. Verify the PID did not change — that proves it was not restarted.

### 15. Job control and surviving logout

```bash
nohup sleep 60 &
jobs -l
disown
```

**You should see** the job listed with a PID. `nohup` makes the process ignore SIGHUP on logout.

For anything that must genuinely outlive your session, `systemd-run` is the modern approach — but for reboot-surviving work you need a **systemd unit** (`14-systemd-services.md`), not `nohup`.

```bash
pkill sleep
```

### Mini checkpoint

Before the practice tasks, you should be able to explain:

| Signal | Number | When to use |
| --- | --: | --- |
| SIGHUP | 1 | Reload config |
| SIGKILL | 9 | Last resort — uncatchable |
| SIGTERM | 15 | Default — polite termination |

And the nice range: **-20 (highest) to +19 (lowest), default 0**.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Display the five processes consuming the most CPU.

> Hint: `ps aux --sort=-%cpu | head -6` — the header line counts as one row.

**Task 2.** Display the five processes consuming the most memory, showing resident memory.

> Hint: `--sort=-%mem` or `--sort=-rss`; RSS is actual RAM, not VSZ.

**Task 3.** Start a background process that consumes CPU, find its PID, and terminate it politely.

> Hint: `yes > /dev/null &` and `$!`; `kill` with no flag sends SIGTERM.

**Task 4.** Start `sleep 900` in the background, then kill it using its name rather than its PID.

> Hint: `pkill sleep` or `killall sleep`.

**Task 5.** Start three `sleep` processes, then terminate all of them with a single command.

> Hint: one `pkill sleep` matches every instance.

**Task 6.** Start a process with the lowest possible scheduling priority.

> Hint: `nice -n 19 command` — highest nice number, lowest priority.

**Task 7.** Start `sleep 900`, then change its nice value to 15 while it is running.

> Hint: `renice -n 15 -p PID`.

**Task 8.** As a regular user, attempt to raise a process's priority to -5 and record what happens.

> Hint: `renice -n -5` without sudo — expect `Permission denied`.

**Task 9.** Show the current nice value of every process owned by user `alice`.

> Hint: `ps -u alice -o pid,ni,pri,comm`.

**Task 10.** Find the PID of the `sshd` process using three different commands.

> Hint: `pgrep`, `pidof`, and `ps -C` — follow-along step 13.

**Task 11.** Send a SIGHUP to the `rsyslog` service so it reloads its configuration, without restarting it.

> Hint: `systemctl reload rsyslog` or `kill -HUP` / `pkill -HUP`.

**Task 12.** Display the system load averages and state whether the system is overloaded, given its CPU count.

> Hint: `uptime` and `nproc` — compare load to CPU count.

**Task 13.** Identify any zombie processes on the system and explain how you would remove one.

> Hint: `ps` with `STAT` containing `Z`; kill the **parent**, not the zombie.

**Task 14.** Start a long-running command that will survive you logging out.

> Hint: `nohup command &` or `systemd-run --unit=...`.

**Task 15.** Kill every process owned by user `alice`.

> Hint: `pkill -u alice` or `killall -u alice`.

**Task 16.** A process named `runaway` is consuming all CPU and does not respond to a termination request. Demonstrate the escalation you would use.

> Hint: SIGTERM first, then `-9`; if still there, check `STAT` for `D` (uninterruptible).

---

## Solutions

**Task 1.**

```bash
ps aux --sort=-%cpu | head -6
```

`head -6` accounts for the header line. Alternatives:

```bash
top -b -n1 | head -12
ps -eo pid,ppid,%cpu,%mem,comm --sort=-%cpu | head -6
```

The `-` in `--sort=-%cpu` means descending. Without it you get the least busy first.

**Task 2.**

```bash
ps aux --sort=-%mem | head -6
ps -eo pid,rss,%mem,comm --sort=-rss | head -6
```

The second form shows **RSS** in kilobytes, which is actual physical memory. `%MEM` is RSS as a percentage of total RAM. **`VSZ` is virtual size and is not a measure of real consumption.**

In `top`, press **`M`**.

**Task 3.**

```bash
# a cheap CPU burner
yes > /dev/null &
echo $!                     # the PID of the most recent background job
```

Find and terminate it:

```bash
pgrep -a yes
kill $(pgrep yes)           # SIGTERM, the default
pgrep yes                   # no output: it is gone
```

`$!` holds the PID of the last background job, which is handy in scripts. `kill` with no signal sends **SIGTERM (15)**, the polite request.

**Task 4.**

```bash
sleep 900 &
pkill sleep
# or
killall sleep
```

Verify:

```bash
pgrep -a sleep
```

`pkill` matches a pattern; `killall` requires an exact command name. Both send SIGTERM by default.

**Task 5.**

```bash
sleep 900 & sleep 901 & sleep 902 &
pgrep -a sleep
pkill sleep
pgrep sleep      # empty
```

One `pkill` handles all matches. To be more precise about which sleeps:

```bash
pkill -f "sleep 901"
```

**Task 6.**

```bash
nice -n 19 sleep 900 &
ps -eo pid,ni,comm | grep sleep
```

Shows `NI` of 19, the lowest priority (most polite). The realistic use is a heavy backup:

```bash
nice -n 19 tar -czf /root/backup.tar.gz /home &
```

**Nice 19 is the lowest priority, -20 the highest.** The counter-intuitive direction is a common exam trap: a *higher* nice number means a *lower* priority.

**Task 7.**

```bash
sleep 900 &
PID=$!
sudo renice -n 15 -p $PID
ps -eo pid,ni,comm -p $PID
```

Output shows `NI` 15. Increasing niceness (lowering priority) does **not** require root when done by the process owner. Verify:

```bash
renice -n 15 -p $PID        # works without sudo, as the owner
```

**Task 8.**

```bash
sleep 900 &
PID=$!
renice -n -5 -p $PID
```

```text
renice: failed to set priority for 12345 (process ID): Permission denied
```

**Only root can lower a nice value.** With sudo it succeeds:

```bash
sudo renice -n -5 -p $PID
ps -eo pid,ni,comm -p $PID       # NI = -5
```

And note the one-way rule for regular users: once a user has niced their own process to 10, they cannot bring it back to 0 without root.

**Task 9.**

```bash
ps -u alice -o pid,ni,pri,comm
```

Or:

```bash
ps -eo pid,user,ni,comm | awk '$2=="alice"'
```

If alice has no processes, start one to test:

```bash
sudo -u alice sleep 900 &
ps -u alice -o pid,ni,comm
```

**Task 10.**

```bash
pgrep sshd
pidof sshd
ps -C sshd -o pid,comm
systemctl show -p MainPID sshd
```

Four ways. `pgrep` and `pidof` are the quickest. `systemctl show -p MainPID` is the right one for a systemd-managed service, because it gives you the main process rather than every child.

**Task 11.**

```bash
sudo systemctl reload rsyslog
```

Or by signal directly:

```bash
sudo pkill -HUP rsyslog
sudo kill -HUP $(pidof rsyslogd)
```

Verify it was reloaded rather than restarted:

```bash
systemctl status rsyslog | head -5
```

The PID should be unchanged and the uptime should not reset. **`systemctl reload` is preferred** because the unit file knows the correct reload mechanism for that service. `SIGHUP` is the traditional equivalent, and knowing that SIGHUP means "reload config" for most daemons is examinable.

Not every service supports reload:

```bash
sudo systemctl reload httpd        # supported
sudo systemctl reload sleep        # would fail
systemctl show -p CanReload rsyslog
```

**Task 12.**

```bash
uptime
nproc
```

Example:

```text
17:42:01 up 2:15, 2 users, load average: 0.52, 0.48, 0.44
$ nproc
2
```

Load 0.52 on 2 CPUs is roughly 26% utilised — not overloaded. The rule of thumb: **compare the load average to the CPU count.** Load equal to `nproc` means fully busy; sustained load well above it means processes are queuing.

The three numbers are 1-, 5-, and 15-minute averages. A high 1-minute with a low 15-minute is a spike; the reverse means the problem is easing.

**Task 13.**

```bash
ps aux | awk '$8 ~ /^Z/ {print}'
ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/'
top -b -n1 | grep -i zombie
```

To create one for practice:

```bash
bash -c 'sleep 1 & exec sleep 300' &
# briefly produces a zombie while the parent ignores it
```

**A zombie cannot be killed — it is already dead.** It is a process table entry retained so the parent can read its exit status. The fix is to make the **parent** reap it:

```bash
ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/'      # note the PPID
sudo kill -HUP <PPID>                            # ask the parent to clean up
sudo kill <PPID>                                 # or terminate the parent
```

When a parent dies, its zombie children are re-parented to PID 1 (systemd), which reaps them immediately. A handful of zombies is harmless; thousands indicate a buggy parent.

**Task 14.**

```bash
nohup sleep 3600 &
exit          # log out, then log back in
pgrep -a sleep      # still running
```

`nohup` makes the process ignore SIGHUP, which is what the shell sends to its children on logout. Output goes to `./nohup.out` unless redirected.

The systemd approach, which is cleaner and gives you management:

```bash
sudo systemd-run --unit=mylongtask sleep 3600
systemctl status mylongtask
sudo systemctl stop mylongtask
```

**Task 15.**

```bash
sudo pkill -u alice
```

Or:

```bash
sudo killall -u alice
```

To be forceful about it:

```bash
sudo pkill -9 -u alice
```

This is what you do before `userdel` if the user has live sessions, since `userdel` refuses to remove a logged-in account without `-f`.

Check first who is logged in:

```bash
who
w
sudo pgrep -au alice
```

**Task 16.**

The escalation, in order:

```bash
# 1. Identify it
pgrep -a runaway
ps aux --sort=-%cpu | head -3

# 2. Polite request first
kill $(pgrep runaway)
sleep 5
pgrep runaway                       # gone? done.

# 3. Still there: force it
kill -9 $(pgrep runaway)
sleep 2
pgrep runaway

# 4. STILL there: check the state
ps -o pid,stat,wchan,comm -p $(pgrep runaway)
```

If the state is **`D`** (uninterruptible sleep), `kill -9` will not work — the process is blocked in a kernel call, typically on failed I/O such as a hung NFS mount or a dying disk. The options then are to fix the underlying I/O problem or reboot. `wchan` names the kernel function it is stuck in, which tells you what kind of I/O.

If the state is **`Z`**, it is already dead; kill the parent instead.

A useful interim measure while you investigate is to stop it consuming CPU without killing it:

```bash
kill -STOP $(pgrep runaway)         # freeze it
kill -CONT $(pgrep runaway)         # resume it later
sudo renice -n 19 -p $(pgrep runaway)   # or just deprioritise it
```

---

## Verify

```bash
ps aux --sort=-%cpu | head -4
ps aux --sort=-%mem | head -4
ps -eo pid,ni,comm --sort=-ni | head -5
uptime; nproc; free -h
pgrep -a sleep
ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/'
```

## Persistence Check

**Almost nothing in this file persists, and that is the point to internalise.**

| Action | Survives a reboot? |
| --- | :---: |
| `kill`, `pkill`, `killall` | The process is gone, but a **service will restart if enabled** |
| `nice` / `renice` | **No.** The process is gone after the reboot |
| `nohup` background job | **No** |
| `systemd-run --unit=x` | **No**, unless you write a real unit file |
| A running process | **No** |

So if a task says "ensure this runs after a reboot", the answer is **never** `nohup` or `systemd-run`. It is a **systemd unit** (`14-systemd-services.md`), a **cron job or timer** (`19-scheduling-cron-at.md`), or a service you `enable` (`14-systemd-services.md`).

Conversely, if you kill a process belonging to an **enabled** service, it comes back on reboot:

```bash
systemctl is-enabled httpd
```

To stop something permanently you must `systemctl disable --now` it, not kill it. That distinction is examinable and is covered in `14-systemd-services.md`.

Note also that a nice value set in a unit file **does** persist, because it is configuration rather than runtime state:

```bash
# /etc/systemd/system/myapp.service
[Service]
Nice=10
```

## Quick Reference

Come back here when you need a command you forgot — not before your first pass through Follow Along.

### Listing processes

```bash
ps                        # your processes in this terminal only
ps -e                     # every process
ps -ef                    # every process, full format
ps aux                    # BSD style: every process with CPU and memory columns
ps -ely                   # includes the nice value and state

ps aux --sort=-%cpu       # sorted by CPU, highest first
ps aux --sort=-%mem       # sorted by memory, highest first
ps -eo pid,ppid,ni,pri,%cpu,%mem,stat,user,comm --sort=-%cpu

ps -u alice               # processes owned by alice
ps -C httpd               # by command name
ps -p 1234                # a specific PID
ps -ef --forest           # tree view showing parent/child
ps -eLf                   # include threads
```

The two you will actually type: **`ps aux --sort=-%cpu`** and **`ps aux --sort=-%mem`**. Those directly answer "identify the CPU-intensive process" and "identify the memory-intensive process".

Reading `ps aux` columns:

```text
USER  PID  %CPU  %MEM    VSZ   RSS TTY  STAT START TIME COMMAND
root  892   0.3   1.2 234567 24680 ?    Ss   10:15 0:04 /usr/sbin/httpd
                          │      │      │
                          │      │      └─ process state
                          │      └──────── RESIDENT memory: actual RAM used
                          └─────────────── VIRTUAL memory: address space reserved
```

**`RSS` is the number that matters for real memory use.** `VSZ` includes address space that is mapped but not resident, so it is often misleadingly large.

Process states (`STAT`):

| Code | Meaning |
| --- | --- |
| **`R`** | Running or runnable |
| **`S`** | Interruptible sleep, waiting for an event |
| **`D`** | **Uninterruptible sleep**, usually blocked on I/O. Cannot be killed |
| **`Z`** | **Zombie**: finished, but the parent has not reaped it |
| `T` | Stopped |
| `I` | Idle kernel thread |

Modifiers: `s` session leader, `l` multi-threaded, `+` in the foreground process group, `<` high priority, `N` low priority.

**A `D`-state process cannot be killed, not even with `-9`.** It is waiting on the kernel. That is a real diagnostic fact: if `kill -9` does nothing, check the state.

**A zombie cannot be killed either**, because it is already dead. You kill or restart its **parent** so the parent reaps it.

### Interactive monitors

```bash
top
```

Keys inside `top`:

| Key | Action |
| --- | --- |
| **`P`** | Sort by **CPU** |
| **`M`** | Sort by **Memory** |
| `T` | Sort by cumulative time |
| `N` | Sort by PID |
| **`k`** | **Kill** a process (prompts for PID and signal) |
| **`r`** | **Renice** a process |
| `u` | Filter by user |
| `1` | Show individual CPU cores |
| `c` | Toggle full command line |
| `H` | Show threads |
| `z` | Colour |
| `W` | Write your settings to `~/.toprc` |
| **`q`** | Quit |

`P` and `M` are the two to remember, plus `k` and `r` which let you fix things without leaving `top`.

```bash
top -b -n1 | head -20             # batch mode: one snapshot, scriptable
top -u alice                      # one user
top -p 1234                       # one PID
```

`htop` is friendlier but is **not installed by default** — do not rely on it.

### Load average and memory

```bash
uptime                            # load averages over 1, 5, 15 minutes
cat /proc/loadavg
nproc                             # how many CPUs, for interpreting load

free -h                           # memory, human readable
free -m
vmstat 1 5                        # 5 samples, 1 second apart
iostat                            # disk I/O (needs sysstat)
sar -u 1 3                        # CPU history (needs sysstat)
```

Interpreting load average: a load of 4.0 on a 4-CPU system means fully busy but not backed up. Compare against `nproc`.

Reading `free -h`: the **`available`** column is what matters, not `free`. Linux deliberately uses spare RAM for cache, so a small `free` value is normal and healthy.

### Signals and killing

```bash
kill 1234                    # sends SIGTERM (15) — polite request to exit
kill -15 1234                # the same, explicit
kill -TERM 1234              # the same, by name
kill -9 1234                 # SIGKILL — cannot be caught. LAST RESORT
kill -HUP 1234               # SIGHUP (1) — many daemons reload config
kill -l                      # list all signal names

killall httpd                # by process NAME, all matches
killall -9 httpd
killall -u alice             # every process owned by alice

pkill httpd                  # by name pattern
pkill -u alice               # by user
pkill -9 -f "python myapp"   # -f matches the FULL command line
pgrep httpd                  # find PIDs by name
pgrep -a httpd               # PIDs with the command line
pgrep -u alice               # by user
pgrep -l -f python           # list matching processes

pidof httpd                  # PIDs of a named binary
```

The signals worth knowing:

| Signal | Number | Effect | Catchable |
| --- | --: | --- | --- |
| **SIGHUP** | **1** | Hang up. Many daemons **reload configuration** | Yes |
| SIGINT | 2 | Interrupt, as from `Ctrl+c` | Yes |
| SIGQUIT | 3 | Quit with a core dump | Yes |
| **SIGKILL** | **9** | **Immediate termination. Cannot be caught or ignored** | **No** |
| **SIGTERM** | **15** | **Polite termination request. The default** | Yes |
| SIGCONT | 18 | Continue a stopped process | |
| SIGSTOP | 19 | Stop. Cannot be caught | **No** |
| SIGTSTP | 20 | Stop from the terminal, as from `Ctrl+z` | Yes |

**Always try SIGTERM (15) first.** It lets the process flush buffers and clean up. `-9` gives it no chance and can leave lock files, partial writes, and orphaned children behind. A task that says "terminate the process" means SIGTERM; only use `-9` if it refuses.

**`pkill -f` matters** when the process name is generic. `pkill python` kills every Python process; `pkill -f "python myapp.py"` kills only the one you meant.

### Job control

```bash
command &                    # run in the background
jobs                         # list this shell's jobs
jobs -l                      # with PIDs
fg                           # bring the most recent job to the foreground
fg %2                        # bring job 2 forward
bg %1                        # resume job 1 in the background
Ctrl+z                       # suspend the foreground job
Ctrl+c                       # terminate the foreground job

nohup command &              # survive logout, output to nohup.out
disown %1                    # detach a job from this shell
```

For anything that must genuinely outlive your session, `systemd-run` is the modern approach:

```bash
sudo systemd-run --unit=mytask sleep 3600
systemctl status mytask
```

### Nice and renice

**Nice values run from -20 (highest priority) to +19 (lowest).** Default is 0.

```bash
nice command                       # start with nice +10 (the default increment)
nice -n 10 command                 # start with nice +10
nice -n -5 command                 # HIGHER priority — requires root
nice -n 19 tar -czf big.tar.gz /   # be maximally polite

renice -n 10 -p 1234               # change a running process
renice -n 10 1234                  # older syntax, same effect
renice -n -5 -p 1234               # raise priority — requires root
renice -n 10 -u alice              # every process owned by alice
renice -n 10 -g devs               # every process in a group
```

**Only root can lower a nice value** (that is, raise priority). A regular user can only be more polite, never less, and cannot undo their own politeness.

```bash
$ renice -n -5 -p 1234
renice: failed to set priority for 1234 (process ID): Permission denied
```

Checking nice values:

```bash
ps -eo pid,ni,pri,comm | head
ps -l                              # NI column
top                                # NI column
ps -eo pid,ni,comm --sort=-ni      # least-favoured processes first
```

Note the difference between `NI` (the nice value you set, -20..19) and `PRI` (the kernel's computed priority). You control `NI`; the scheduler derives `PRI`.

### Real-time scheduling, briefly

Beyond RHCSA scope but recognise the tool:

```bash
chrt -p 1234                       # show scheduling policy
chrt -f -p 50 1234                 # SCHED_FIFO
```

## Exam Tips

- **`ps aux --sort=-%cpu`** and **`ps aux --sort=-%mem`** answer the "identify the intensive process" objective directly.
- In `top`: **`P`** sorts by CPU, **`M`** by memory, **`k`** kills, **`r`** renices, **`q`** quits.
- **`RSS` is real memory. `VSZ` is virtual and misleadingly large.**
- **Signals: 1 SIGHUP (reload), 9 SIGKILL (uncatchable), 15 SIGTERM (default, polite).**
- **Try SIGTERM first, `-9` only if it refuses.** A task saying "terminate" means SIGTERM.
- **SIGHUP makes most daemons reload configuration.** `systemctl reload` is the preferred route.
- **`pkill -f`** matches the full command line — essential when the process name is generic like `python`.
- **`pgrep -a`**, `pidof`, and `systemctl show -p MainPID` all find PIDs.
- **A `D`-state process cannot be killed at all**, not even with `-9`. It is blocked on I/O.
- **A zombie (`Z`) cannot be killed** — it is already dead. Kill or SIGHUP the **parent**.
- **Nice range is -20 (highest priority) to +19 (lowest). Default 0.** Higher number, lower priority.
- **Only root can lower a nice value.** Regular users can only increase niceness, and cannot reverse it.
- **`renice -n 10 -p PID`** for a running process; **`nice -n 10 command`** to start one.
- Compare **`uptime`** load average against **`nproc`** to judge overload.
- In `free -h`, read the **`available`** column, not `free`.
- **Nothing here persists.** For a reboot-surviving process you need a **systemd unit**, not `nohup`.
- Killing a process belonging to an **enabled** service does not stop it returning after a reboot; `systemctl disable --now` does.
