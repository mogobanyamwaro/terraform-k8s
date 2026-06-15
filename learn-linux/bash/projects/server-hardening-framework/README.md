# Ultimate Capstone Project: **Production-Grade Automated Server Hardening & Compliance Framework**

This single project touches **every single concept** from all 5 phases. It's a real-world tool that security teams and DevOps engineers actually use.

## Project Overview

Build a **CIS Benchmark Compliance Framework** that automatically:

- Audits server security posture against industry standards
- Hardens systems based on findings
- Maintains state and can rollback changes
- Runs as a production service with monitoring

**Why this project?** It forces you to use EVERYTHING: file operations, text processing, process management, arrays, functions, error handling, logging, locking, scheduling, and self-healing.

---

## Core Architecture

```
server-hardening-framework/
├── bin/
│   ├── hardening-framework.sh      # Main orchestration script
│   ├── audit-module.sh              # Compliance checking
│   ├── apply-module.sh              # Remediation engine
│   └── rollback-module.sh           # State restoration
├── lib/
│   ├── logging.sh                   # Phase 4 & 5 logging system
│   ├── locking.sh                   # Phase 5 lock management
│   └── validation.sh                # Phase 5 validation functions
├── config/
│   ├── hardening.conf               # Main configuration
│   ├── profiles/                    # Different compliance levels
│   │   ├── production.conf
│   │   ├── development.conf
│   │   └── dmz.conf
│   └── exceptions.conf              # Allow-list for false positives
├── modules/
│   ├── 01-ssh-security.sh           # SSH hardening
│   ├── 02-firewall-rules.sh         # iptables/nftables config
│   ├── 03-file-permissions.sh       # Critical file permissions
│   ├── 04-user-policies.sh          # Password & account policies
│   ├── 05-kernel-params.sh          # sysctl hardening
│   ├── 06-audit-logging.sh          # Auditd configuration
│   ├── 07-package-security.sh       # Unused packages removal
│   └── 08-process-monitoring.sh     # Unexpected processes
├── state/
│   ├── original_state.tar.gz        # Pre-hardening backup (Phase 3)
│   ├── applied_checks.txt           # What was applied (Phase 1 & 2)
│   └── rollback_points/             # Timestamped states (Phase 3 find)
├── reports/
│   ├── audit-$(date).html           # HTML report (Phase 4 heredoc)
│   ├── compliance-$(date).csv       # CSV for monitoring (Phase 2 loops)
│   └── drift-$(date).json           # Changes since last audit
├── templates/
│   ├── sshd_config.tmpl             # Here document templates (Phase 4)
│   ├── sysctl.conf.tmpl
│   └── audit.rules.tmpl
├── tests/
│   ├── test-audit.sh                # Unit tests (Phase 2 functions)
│   ├── test-apply.sh
│   └── test-rollback.sh
└── cron.d/
    └── hardening-cron               # Scheduled jobs (Phase 3 cron)
```

---

## What Each Phase Contributes to This Project

### Phase 1 Commands Used:

- `ls -la`, `find`, `grep` - Finding world-writable files, SUID binaries
- `cut`, `sort`, `uniq`, `wc` - Parsing `/etc/passwd`, `/etc/group`
- `ps aux`, `kill` - Process auditing
- `tail -f` - Real-time log monitoring during apply
- `tee` - Capturing output to logs and console
- Pipes everywhere - Chaining discovery commands

### Phase 2 Scripting Used:

- **Variables**: Config paths, thresholds, state directories
- **Command substitution**: `$(date +%Y%m%d)`, `$(which command)`
- **Exit codes & `$?`**: Check if remediation succeeded
- **Conditionals**: `if [[ -f "$file" ]]`, `case "$os" in`
- **Loops**: `for module in modules/*.sh`, `while read -r line`
- **Arrays**: `declare -a FAILED_CHECKS`, `services_to_restart=()`
- **Associative arrays**: `declare -A CIS_CONTROLS`, severity mapping

### Phase 3 Toolkit Used:

- **find**: Locate world-writable files, SUID binaries, modified files
- **xargs**: `find / -perm -4000 -print0 | xargs -0 ls -l`
- **sed**: In-place config file editing, templating
- **awk**: Parse `sshd -T`, `sysctl -a`, log analysis
- **cron**: Daily audit, weekly deep scan, monthly reports

### Phase 4 Bash Features Used:

- **Arrays**: Store list of checks, modules, failed items
- **Associative arrays**: Map check IDs to descriptions, severities
- **Functions**: Modular design with local variables
- **Parameter expansion**: `${var:-default}`, `${file##*/}`, `${line// /_}`
- **Here documents**: Generate HTML reports, config templates
- **Debugging**: `set -x` in test mode, custom debug function

### Phase 5 Error Handling Used:

- **Traps**: Cleanup on interrupt, rollback on fatal error
- **Lock files**: Prevent concurrent runs
- **Syslog logging**: Send events to `/var/log/hardening.log`
- **Retry logic**: Network operations, service restarts
- **Self-healing**: Detect and fix common issues
- **Graceful degradation**: Skip modules if dependencies missing
- **State management**: Backup original configs before changes

```text
Lesson 1: Project Setup & Configuration System
Lesson 2: Basic Security Audit (Phase 1&2)
Lesson 3: Logging System (Phase 4)
Lesson 4: SSH Hardening Module (Phase 3)
Lesson 5: File Permissions Audit (Phase 1-3)
Lesson 6: Module System & Orchestration (Phase 2&4)
Lesson 7: Backup & Rollback (Phase 3&5)
Lesson 8: Reporting System (Phase 4)
Lesson 9: Locking & Error Handling (Phase 5)
Lesson 10: Cron Automation & Final Polish (Phase 3&5)
```

https://chat.deepseek.com/a/chat/s/69d3da99-e204-4e37-bbee-a6f5492f76d0
