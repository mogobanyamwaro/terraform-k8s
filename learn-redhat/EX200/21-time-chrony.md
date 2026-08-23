# 21. Time Services: chrony And timedatectl

**Objective:** Configure time service clients.

Another cheap, predictable task. Two commands for the timezone, one config edit plus a restart for NTP. Do it early.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Reading every chrony directive upfront feels like learning. Typing them one at a time actually is.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Current time status

```bash
timedatectl
```

**You should see** local time, timezone, **`System clock synchronized:`**, and **`NTP service:`**. Those last two are different — you want both yes/active for a working time client.

Individual properties:

```bash
timedatectl show -p Timezone --value
timedatectl show -p NTPSynchronized --value
systemctl is-active chronyd
```

### 2. Set the timezone

```bash
timedatectl list-timezones | grep -i nairobi
sudo timedatectl set-timezone Africa/Nairobi
timedatectl | grep 'Time zone'
ls -l /etc/localtime
```

**You should see** `Africa/Nairobi` and a symlink into `/usr/share/zoneinfo/`. **Always find the exact name with `list-timezones` first** — names are case-sensitive and use `Region/City` format.

Your shell prompt will not update until you start a new shell:

```bash
exec bash
```

### 3. Install and enable chrony

```bash
rpm -q chrony || sudo dnf install -y chrony
sudo systemctl enable --now chronyd
systemctl is-enabled chronyd
systemctl is-active chronyd
```

**You should see** chrony enabled and active. **`timedatectl set-ntp true`** on RHEL also enables and starts `chronyd`.

### 4. Enable NTP with timedatectl

```bash
sudo timedatectl set-ntp true
timedatectl | grep -i ntp
```

**You should see** `NTP service: active` and eventually `System clock synchronized: yes`.

### 5. Configure a time server with iburst

```bash
sudo cp /etc/chrony.conf{,.bak}
sudo sed -i 's/^pool /#pool /; s/^server /#server /' /etc/chrony.conf
echo "server server2.lab.example.com iburst" | sudo tee -a /etc/chrony.conf
grep -Ev '^\s*#|^\s*$' /etc/chrony.conf
sudo systemctl restart chronyd
sleep 5
chronyc sources -v
```

**You should see** your server line with **`iburst`** — it sends a burst of probes immediately instead of waiting 64 seconds. **A restart is required**; chrony does not reload config on its own.

If the hostname does not resolve, add it to `/etc/hosts` (see `25-hostnames-dns.md`).

### 6. Verify synchronisation

```bash
chronyc sources -v
chronyc tracking
timedatectl | grep -i synchronized
```

**You should see** a **`^*`** marker on the selected source in `sources`, a non-zero Reference ID in `tracking`, and `System clock synchronized: yes`.

Reading `chronyc sources`:

```text
^* server2.lab.example.com    # selected source — synchronised
^- ntp2.example.com          # acceptable, not selected
^? ntp3.example.com          # unreachable
```

### 7. Force a clock step correction

```bash
sudo chronyc makestep
chronyc tracking
```

**You should see** the clock corrected immediately rather than slewed gradually. The `makestep 1.0 3` line in `chrony.conf` controls when stepping is allowed at startup.

### 8. Keep the hardware clock in UTC

```bash
timedatectl | grep -i 'RTC in local'
sudo timedatectl set-local-rtc 0
grep rtcsync /etc/chrony.conf
```

**You should see** `RTC in local TZ: no`. **`set-local-rtc 0`** keeps the RTC in UTC, which is recommended.

### 9. Acting as an NTP server (brief)

On a server that must serve time to a subnet:

```bash
grep '^allow' /etc/chrony.conf
# if missing:
echo "allow 192.168.56.0/24" | sudo tee -a /etc/chrony.conf
sudo systemctl restart chronyd
sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --reload
```

**Serving time requires opening the firewall; being a client does not.** NTP is UDP port 123.

### Mini checkpoint

| Command / file | Remember |
| --- | --- |
| `timedatectl set-timezone Region/City` | persists via `/etc/localtime` symlink |
| `timedatectl set-ntp true` | enables and starts `chronyd` |
| Edit `/etc/chrony.conf` | then **`systemctl restart chronyd`** |
| `iburst` on server lines | fast initial synchronisation |
| `chronyc sources -v` | look for **`^*`** |
| `chronyc tracking` | Reference ID and Leap status |
| `set-time` | fails while NTP is enabled |
| `ntpd` | gone on RHEL 8+ — use **chrony** |

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Determine the current timezone, whether the clock is synchronised, and whether the NTP service is active.

> Hint: `timedatectl` — read three specific lines.

**Task 2.** Set the system timezone to `Africa/Nairobi`, having first confirmed the exact name is valid.

> Hint: `list-timezones | grep -i nairobi` first.

**Task 3.** Show what file `timedatectl set-timezone` actually changes.

> Hint: `ls -l /etc/localtime`.

**Task 4.** Ensure `chrony` is installed, enabled, and running.

> Hint: `enable --now chronyd`.

**Task 5.** Configure this system to synchronise its time from `server2.lab.example.com`, replacing any existing time sources, using the option that makes synchronisation happen quickly.

> Hint: follow-along step 5; comment out pool/server lines; add `iburst`.

**Task 6.** Verify that the system has actually synchronised with the configured server, and identify the selected source.

> Hint: follow-along step 6; three signs of success.

**Task 7.** Enable NTP synchronisation using `timedatectl` and confirm what service that started.

> Hint: `set-ntp true` starts `chronyd`.

**Task 8.** Configure `server2` to act as an NTP server for the `192.168.56.0/24` network, including any firewall change required.

> Hint: follow-along step 9; `allow` plus `firewall-cmd --add-service=ntp --permanent`.

**Task 9.** Disable NTP, set the system clock manually to a specific time, then re-enable NTP.

> Hint: `set-ntp false` before `set-time`.

**Task 10.** Force chrony to correct a large clock offset immediately rather than slewing gradually.

> Hint: `chronyc makestep`.

**Task 11.** Determine the current stratum and reference server that this system is synchronised to.

> Hint: `chronyc tracking`.

**Task 12.** Ensure the hardware clock is kept in UTC rather than local time.

> Hint: `set-local-rtc 0`.

**Task 13.** Confirm your time configuration survives a reboot.

> Hint: check `is-enabled chronyd` and `chronyc sources` after reboot.

**Task 14.** A system shows "System clock synchronized: no" and every source is marked `^?`. List the things you would check, in order.

> Hint: chronyd running? config restarted? name resolves? firewall on server?

---

## Solutions

**Task 1.**

```bash
timedatectl
```

The three lines to read:

```text
                Time zone: Africa/Nairobi (EAT, +0300)
System clock synchronized: yes
              NTP service: active
```

Or individually:

```bash
timedatectl show -p Timezone --value
timedatectl show -p NTPSynchronized --value
systemctl is-active chronyd
```

**Task 2.**

```bash
timedatectl list-timezones | grep -i nairobi
```

```text
Africa/Nairobi
```

```bash
sudo timedatectl set-timezone Africa/Nairobi
timedatectl | grep 'Time zone'
```

**Confirm the name with `list-timezones` first.** The format is `Region/City` and it is case-sensitive. `Nairobi`, `EAT`, and `africa/nairobi` are all rejected.

**Task 3.**

```bash
ls -l /etc/localtime
```

```text
lrwxrwxrwx. 1 root root 33 Aug 18 19:20 /etc/localtime -> ../usr/share/zoneinfo/Africa/Nairobi
```

A symlink into the zoneinfo database. You could set it by hand:

```bash
sudo ln -sf /usr/share/zoneinfo/Africa/Nairobi /etc/localtime
```

Use `timedatectl set-timezone` on the exam — it is shorter and it validates the name — but knowing the mechanism lets you verify and repair it.

**Task 4.**

```bash
rpm -q chrony || sudo dnf install -y chrony
sudo systemctl enable --now chronyd
systemctl is-enabled chronyd
systemctl is-active chronyd
```

**`enable --now`.** A time service that is not enabled leaves the clock unsynchronised after a reboot, which is exactly what a grader checks.

**Task 5.**

```bash
sudo cp /etc/chrony.conf{,.bak}
```

Comment out the existing pool or server lines and add your own:

```bash
sudo sed -i 's/^pool /#pool /; s/^server /#server /' /etc/chrony.conf
echo "server server2.lab.example.com iburst" | sudo tee -a /etc/chrony.conf
```

Check the result:

```bash
grep -Ev '^\s*#|^\s*$' /etc/chrony.conf
```

```text
server server2.lab.example.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
```

Restart and verify:

```bash
sudo systemctl restart chronyd
sleep 5
chronyc sources -v
```

**`iburst` is the option "that makes synchronisation happen quickly".** It sends an immediate burst of probes instead of waiting for the normal 64-second polling interval. Without it you may wait several minutes before `chronyc sources` shows a `^*`, and on a timed exam you want to verify and move on.

**A restart is required**; chrony does not reload its configuration automatically.

If `server2.lab.example.com` does not resolve, add it to `/etc/hosts` (see `25-hostnames-dns.md`) or use its IP address.

**Task 6.**

```bash
chronyc sources -v
```

Look for the `^*` marker:

```text
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* server2.lab.example.com       3   6   377     5    +18us[  +24us] +/-  8.2ms
```

Then the summary:

```bash
chronyc tracking
```

```text
Reference ID    : C0A8380C (server2.lab.example.com)
Stratum         : 4
Leap status     : Normal
```

And the systemd view:

```bash
timedatectl | grep -i synchronized
# System clock synchronized: yes
```

**Three signs of success: a `^*` in `chronyc sources`, a non-zero Reference ID in `chronyc tracking`, and `System clock synchronized: yes`.** Check at least two.

If everything shows `^?`, see Task 14.

**Task 7.**

```bash
sudo timedatectl set-ntp true
timedatectl | grep -i ntp
systemctl is-active chronyd
systemctl is-enabled chronyd
```

On RHEL, `timedatectl set-ntp true` **enables and starts `chronyd`**. Confirm by checking before and after:

```bash
sudo systemctl disable --now chronyd
systemctl is-enabled chronyd            # disabled
sudo timedatectl set-ntp true
systemctl is-enabled chronyd            # enabled
systemctl is-active chronyd             # active
```

So `timedatectl set-ntp true` and `systemctl enable --now chronyd` are two routes to the same place. Either satisfies a task asking to enable time synchronisation.

**Task 8.**

On `server2`:

```bash
sudo cp /etc/chrony.conf{,.bak}
echo "allow 192.168.56.0/24" | sudo tee -a /etc/chrony.conf
sudo systemctl restart chronyd

sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --reload
```

Verify locally:

```bash
grep '^allow' /etc/chrony.conf
sudo firewall-cmd --list-services
sudo ss -ulnp | grep 123
```

Verify from `server1`:

```bash
chronyc -h server2.lab.example.com tracking 2>/dev/null
# or simply configure server1 to use it, as in Task 5, and check for ^*
```

**Two changes are needed, and people forget the firewall.** `allow` tells chrony to answer queries; firewalld still blocks UDP 123 until you open it. Being a *client* needs no firewall change, because the reply to an outbound query is permitted by connection tracking.

If the server has no upstream time source of its own and must still serve time:

```bash
echo "local stratum 10" | sudo tee -a /etc/chrony.conf
sudo systemctl restart chronyd
```

**Task 9.**

```bash
sudo timedatectl set-ntp false
timedatectl | grep -i ntp                       # inactive

sudo timedatectl set-time "2026-08-18 14:30:00"
timedatectl | head -3

sudo timedatectl set-ntp true
sleep 5
chronyc tracking | head -3
timedatectl | grep -i synchronized
```

**`set-time` fails while NTP is active:**

```text
Failed to set time: Automatic time synchronization is enabled
```

That is deliberate. You cannot hand-set a clock a daemon is actively correcting.

Note that on the exam, a task almost always wants NTP **enabled**. Manually setting the clock is usually a diagnostic step, not the goal.

**Task 10.**

```bash
sudo chronyc makestep
chronyc tracking
```

`makestep` applies the correction as a single **step** rather than slewing the clock gradually. By default chrony only steps in the first few updates after startup, controlled by:

```text
makestep 1.0 3       # step if off by more than 1 second, during the first 3 updates
```

To allow stepping at any time:

```bash
sudo sed -i 's/^makestep.*/makestep 1.0 -1/' /etc/chrony.conf
sudo systemctl restart chronyd
```

`-1` means "always allowed to step". Useful on a VM that has been suspended and resumed with a badly wrong clock.

Also useful for forcing rapid resynchronisation:

```bash
sudo chronyc -a 'burst 4/4'
sleep 10
chronyc sources -v
```

**Task 11.**

```bash
chronyc tracking
```

```text
Reference ID    : C0A8380C (server2.lab.example.com)
Stratum         : 4
Ref time (UTC)  : Tue Aug 18 16:20:11 2026
System time     : 0.000004321 seconds fast of NTP time
Leap status     : Normal
```

**Stratum** is the distance from a reference clock: stratum 1 is directly attached to one (GPS, atomic), stratum 2 syncs from a stratum 1 server, and so on. Your machine is one level above whatever it syncs from.

`Reference ID : 00000000 ()` with `Leap status: Not synchronised` means you are not synchronised at all.

**Task 12.**

```bash
timedatectl | grep -i 'RTC in local'
sudo timedatectl set-local-rtc 0
timedatectl | grep -i 'RTC in local'
# RTC in local TZ: no
```

`0` means the RTC is kept in **UTC**, which is what you want. `1` keeps it in local time, which RHEL warns against because it breaks around daylight saving transitions and confuses dual-boot systems.

Also ensure chrony keeps the RTC updated:

```bash
grep rtcsync /etc/chrony.conf
```

`rtcsync` is enabled in the default RHEL config, which is why you rarely need `hwclock` manually.

**Task 13.**

```bash
# before
timedatectl
chronyc sources -v
systemctl is-enabled chronyd

sudo reboot
```

After the reboot:

```bash
timedatectl                          # timezone and sync state
systemctl is-enabled chronyd         # enabled
systemctl is-active chronyd          # active
chronyc sources -v                   # a ^* source
grep -Ev '^\s*#|^\s*$' /etc/chrony.conf
```

**All five.** The timezone and the config file persist by themselves; the risk is `chronyd` not being **enabled**, in which case the clock drifts and nothing is synchronised even though the configuration is perfect.

**Task 14.**

The checks, in order of likelihood:

```bash
# 1. Is chronyd even running?
systemctl is-active chronyd
systemctl status chronyd --no-pager
sudo journalctl -u chronyd -n 30

# 2. Is the configuration what you think it is?
grep -Ev '^\s*#|^\s*$' /etc/chrony.conf

# 3. Did you restart after editing? (chrony does not reload)
sudo systemctl restart chronyd; sleep 5; chronyc sources -v

# 4. Does the server name resolve?
getent hosts server2.lab.example.com
ping -c1 server2.lab.example.com

# 5. Is there a route and is the network up?
ip -brief addr show
ip route

# 6. Is UDP 123 reachable? (a firewall on the SERVER side)
sudo ss -ulnp | grep 123
nc -zvu server2.lab.example.com 123 2>&1 | tail -1

# 7. On the SERVER: is `allow` set and the firewall open?
grep '^allow' /etc/chrony.conf
sudo firewall-cmd --list-services | grep -o ntp

# 8. Force a burst and re-check
sudo chronyc -a 'burst 4/4'; sleep 10; chronyc sources -v
```

**The four most common causes, in order:** `chronyd` not restarted after editing the config, the server name not resolving, the firewall on the server side not permitting NTP, and `allow` missing from the server's `chrony.conf`.

Notice that a `^?` on every line points at **reachability** — network, name resolution, or firewall — while sources that are reachable but never selected (`^-` only, no `^*`) points at the clock being too far off or too few sources to agree on. `chronyc activity` distinguishes them:

```bash
chronyc activity
```

```text
200 OK
1 sources online
0 sources offline
```

---

## Verify

```bash
timedatectl
chronyc sources -v
chronyc tracking | head -4
systemctl is-enabled chronyd; systemctl is-active chronyd
grep -Ev '^\s*#|^\s*$' /etc/chrony.conf
ls -l /etc/localtime
sudo firewall-cmd --list-services       # if acting as a server
```

## Persistence Check

| Change | Persistent artifact | Also required |
| --- | --- | --- |
| Timezone | **`/etc/localtime`** symlink | Nothing |
| Time servers | **`/etc/chrony.conf`** | **`systemctl restart chronyd`** |
| `allow` for serving time | `/etc/chrony.conf` | Restart, plus a `--permanent` firewall rule |
| NTP enabled | `chronyd` enablement | **`systemctl enable --now chronyd`** |
| `set-local-rtc 0` | systemd state | Nothing |
| `timedatectl set-time` | **Nothing meaningful** — NTP overwrites it | — |

The two failure modes:

1. **`chronyd` not enabled.** The config is perfect, the timezone is right, and after the reboot the clock is unsynchronised because the daemon never started.
2. **Config edited but not restarted.** `chronyc sources` still shows the old servers. Unlike some daemons, chrony does not pick up changes on its own.

Post-reboot verification:

```bash
timedatectl | grep -E 'Time zone|synchronized|NTP service'
systemctl is-enabled chronyd
chronyc sources -v | grep '\^\*'         # a selected source exists
```

## Quick Reference

Come back here when you need a command you forgot — not before your first pass through Follow Along.

### The tools

| Tool | Purpose |
| --- | --- |
| **`timedatectl`** | **Timezone, clock, and whether NTP is enabled.** The systemd front end |
| **`chronyd`** | **The NTP daemon on RHEL 7+.** Replaced `ntpd` |
| `chronyc` | The chrony client: query and control the running daemon |
| `hwclock` | The hardware (RTC) clock |
| `date` | Show or set the system clock manually |

`ntpd` is gone from RHEL 8 onwards. If a task mentions NTP, the answer is **chrony**.

### timedatectl

```bash
timedatectl                              # full status
timedatectl list-timezones               # every valid timezone name
timedatectl list-timezones | grep -i nairobi
sudo timedatectl set-timezone Africa/Nairobi
sudo timedatectl set-time "2026-08-18 14:30:00"    # only with NTP disabled
sudo timedatectl set-ntp true            # enable NTP synchronisation
sudo timedatectl set-ntp false           # disable it
sudo timedatectl set-local-rtc 0         # keep the RTC in UTC (recommended)
timedatectl show                         # machine-readable properties
```

**"NTP service: active" means `chronyd` is running. "System clock synchronized: yes" means it has actually agreed with a server.**

### chrony configuration

```bash
sudo dnf install -y chrony
sudo systemctl enable --now chronyd
sudo vim /etc/chrony.conf
```

The directives that matter:

```text
pool 2.rhel.pool.ntp.org iburst
server classroom.example.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3              # step the clock if off by >1s, in the first 3 updates
rtcsync                     # keep the RTC in sync with the system clock
allow 192.168.56.0/24       # act as a server for a local network
local stratum 10            # serve time even when unsynchronised
```

**`iburst` is the option to remember.** After editing, always:

```bash
sudo systemctl restart chronyd
chronyc sources -v
```

### chronyc: verifying synchronisation

```bash
chronyc sources                     # the servers being used
chronyc sources -v                  # with a legend explaining the columns
chronyc sourcestats                 # accuracy statistics
chronyc tracking                    # the current synchronisation state
chronyc activity                    # how many sources are online/offline
sudo chronyc makestep               # force an immediate step correction
sudo chronyc -a 'burst 4/4'         # force rapid polling
```

**The `^*` marker is what you are looking for.** It means chrony has selected that server and the clock is synchronised.

### The hardware clock

```bash
sudo hwclock                        # read the RTC
sudo hwclock --systohc              # system clock -> RTC
sudo hwclock --hctosys              # RTC -> system clock
timedatectl set-local-rtc 0         # keep the RTC in UTC (recommended)
```

### Setting the time manually

```bash
sudo timedatectl set-ntp false            # NTP must be off first
sudo timedatectl set-time "2026-08-18 14:30:00"
sudo timedatectl set-ntp true             # turn it back on
```

**`set-time` fails while NTP is active**, with "Automatic time synchronization is enabled".

### date formatting

```bash
date +%F                          # 2026-08-18
date +%T                          # 19:15:32
date +%s                          # Unix epoch seconds
date -u                           # UTC
```

Remember from `19-scheduling-cron-at.md` that `%` must be escaped as `\%` inside a crontab.

## Exam Tips

- **chrony, not ntpd.** `ntpd` does not exist on RHEL 8+.
- **`timedatectl list-timezones | grep -i <city>`** first, then **`timedatectl set-timezone Region/City`**. The name is case-sensitive.
- **`timedatectl set-ntp true`** enables and starts `chronyd`. So does `systemctl enable --now chronyd`.
- **Edit `/etc/chrony.conf`, then `systemctl restart chronyd`.** chrony does not reload on its own.
- **Add `iburst`** to server lines so synchronisation happens in seconds, not minutes.
- **`chronyc sources -v` and look for `^*`** — that marker means a source is selected and you are synchronised.
- **`chronyc tracking`**: a non-zero Reference ID and `Leap status: Normal` mean success.
- **`timedatectl` shows both "NTP service: active" and "System clock synchronized: yes".** They are different; you want both.
- **Serving time needs `allow <subnet>` in `chrony.conf` AND `firewall-cmd --add-service=ntp --permanent`.** Being a client needs no firewall change.
- **NTP is UDP port 123.**
- **`set-time` fails while NTP is enabled.** Disable it first, then re-enable. A task usually wants NTP on.
- **`/etc/localtime` is a symlink** into `/usr/share/zoneinfo/`.
- **`set-local-rtc 0`** keeps the hardware clock in UTC, which is the recommended setting.
- **`chronyc makestep`** forces an immediate step correction; `makestep 1.0 -1` allows it at any time.
- All sources showing `^?` means a **reachability** problem: restart, name resolution, or firewall. Check in that order.
- **This is a cheap task.** Two commands for the timezone, one edit plus a restart for NTP. Do it early and verify it.
