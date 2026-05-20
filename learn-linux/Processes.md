Good — processes are where Linux stops being “files and permissions” and becomes a **running system**.

Let’s go clean and structured.

---

# ⚙️ 1. What is a process?

A **process** is simply:

> a running instance of a program

\text{process} ;=; \text{program in execution (with memory, CPU time, and state)}

---

# 🧠 Simple analogy

- Program = recipe
- Process = cooking that recipe right now

Same recipe can run multiple times → multiple processes.

---

# 🔢 2. How Linux identifies processes

Every process gets a:

> **PID (Process ID)**

Example:

```bash id="p1"
1234
```

That number uniquely identifies a running process.

---

# 📋 3. See processes

## Basic view:

```bash id="p2"
ps
```

---

## Full system view:

```bash id="p3"
ps aux
```

You’ll see:

```id="p4"
USER   PID  %CPU %MEM  COMMAND
root   1    0.1  0.3   systemd
doug   2345  0.0  0.1   bash
```

---

## Live view (VERY IMPORTANT):

```bash id="p5"
top
```

or better:

```bash id="p6"
htop
```

---

# 🧠 4. Where processes live in Linux

Linux exposes processes through:

```bash id="p7"
/proc
```

Example:

```bash id="p8"
/proc/1234
```

That folder represents process 1234.

Inside:

- memory info
- CPU usage
- command line
- environment

---

# 🔥 5. Start a process

Example:

```bash id="p9"
sleep 1000
```

This runs in foreground.

---

# ⏸ 6. Background process

```bash id="p10"
sleep 1000 &
```

Now shell is free.

---

# 🔄 7. Job control

```bash id="p11"
jobs
```

Bring back:

```bash id="p12"
fg
```

---

# 🧨 8. Kill a process

## By PID:

```bash id="p13"
kill 1234
```

Force kill:

```bash id="p14"
kill -9 1234
```

---

## By name:

```bash id="p15"
pkill sleep
```

---

# 🧠 9. Parent and child processes

Every process has:

- Parent (PPID)
- Children

Example:

```bash id="p16"
bash → python → script.py
```

Tree view:

```bash id="p17"
pstree
```

---

# ⚙️ 10. What happens when you run a command

Example:

```bash id="p18"
curl google.com
```

Linux does:

shell \rightarrow fork() \rightarrow exec() \rightarrow process runs

Steps:

1. shell reads command
2. creates process (fork)
3. replaces it with program (exec)
4. CPU runs it

---

# 🧠 11. Process states

A process can be:

| State    | Meaning                  |
| -------- | ------------------------ |
| Running  | actively using CPU       |
| Sleeping | waiting                  |
| Stopped  | paused                   |
| Zombie   | finished but not cleaned |

---

# 🧟 12. Zombie process (important concept)

A zombie is:

> a process that finished but still has an entry in process table

Not dangerous, but shows poor cleanup.

---

# ⚙️ 13. Process resources

Each process has:

- CPU time
- memory (RAM)
- file descriptors
- environment variables
- permissions (user identity)

---

# 🔐 14. Process ownership

Every process runs as a user:

```bash id="p19"
root process → full power
user process → limited access
```

Check:

```bash id="p20"
ps -u
```

---

# 🧠 15. Real admin use cases

## Find heavy CPU usage:

```bash id="p21"
top
```

---

## Kill broken service:

```bash id="p22"
kill -9 PID
```

---

## Check what is using port:

```bash id="p23"
lsof -i :8080
```

---

## Trace process tree:

```bash id="p24"
pstree -p
```

---

# 🧠 16. Mental model

Think:

```id="p25"
Linux = factory

process = worker
PID = worker ID badge
CPU = machine time
RAM = workspace
```

---

# 🧠 17. One-line memory

> A process is a running program with its own memory, CPU time, and identity (PID + user).

---

# 🚀 If you want next (VERY important)

We can go deeper into:

### 🔥 1. `/proc` deep dive (how processes actually appear as files)

### 🔥 2. threads vs processes (your earlier question revisited properly)

### 🔥 3. systemd (how Linux starts and manages processes)

### 🔥 4. CPU scheduling (why some processes “slow down” others)

Just tell me.
Good — logs are where Linux becomes “observable”. If processes are the _what is running_, logs are the _what actually happened_.

---

# 🧾 1. What are logs?

Logs are:

> time-stamped records of events produced by the system, services, or applications

\text{logs} ;=; \text{time-ordered event records from processes and the system}

---

# 🧠 2. Why logs exist

Linux logs everything important:

- service started/stopped
- errors
- crashes
- authentication attempts
- kernel events
- network activity

---

# 📍 3. Main log system in modern Linux

Most modern Linux (including WSL) uses:

> **systemd journal**

Tool:

```bash id="l1"
journalctl
```

---

# 📄 4. View all logs

```bash id="l2"
journalctl
```

This is EVERYTHING (huge output).

---

# ⏱ 5. View latest logs only

```bash id="l3"
journalctl -n 50
```

---

# 🔴 6. Follow logs live (VERY IMPORTANT)

```bash id="l4"
journalctl -f
```

Like:

> “tail - continuously watching system events”

---

# ⚙️ 7. View logs for a service

Example: nginx

```bash id="l5"
journalctl -u nginx
```

---

# 🧠 8. View logs for current boot

```bash id="l6"
journalctl -b
```

---

# 🔍 9. Filter by time

```bash id="l7"
journalctl --since "1 hour ago"
```

---

# 🧨 10. Kernel logs (low-level system)

```bash id="l8"
dmesg
```

Used for:

- hardware issues
- boot problems
- driver messages

---

# 📁 11. Traditional log files (still exist)

Some logs are still files:

```bash id="l9"
/var/log/
```

Examples:

| File     | Purpose             |
| -------- | ------------------- |
| syslog   | general system logs |
| auth.log | login/security      |
| kern.log | kernel messages     |

---

# 🔥 12. Real-world example (debugging service)

If nginx fails:

```bash id="l10"
systemctl status nginx
```

Then:

```bash id="l11"
journalctl -u nginx -xe
```

You immediately see:

- why it failed
- config error
- port conflict
- permission issue

---

# 🧠 13. Log flow model

\text{process} \rightarrow \text{event occurs} \rightarrow \text{systemd/journal records log entry} \rightarrow \text{stored and queryable}

---

# 🧠 14. Key mental model

Think:

```text id="l12"
Process = worker
Log = worker diary
journalctl = diary reader
```

---

# ⚠️ 15. Common mistake

People try:

```bash id="l13"
cat /var/log/nginx
```

But modern systems use:

```bash id="l14"
journalctl -u nginx
```

---

# 🧠 16. One-line memory

> Logs are time-stamped records of what processes and the system have done, viewable via journalctl or /var/log.

---

# 🚀 If you want next (VERY useful)

We can go deeper into:

- how to debug a broken service using logs step-by-step
- log levels (info, warning, error, critical)
- log rotation (why logs don’t fill your disk)
- building your own logs in apps (like .NET logging)

Just say 👍
