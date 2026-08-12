# 21. Time Services: chrony And timedatectl

**Objective:** Configure time service clients.

Another cheap, predictable task. Two commands for the timezone, one config edit plus a restart for NTP. Do it early.

## Concept Refresher

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
timedatectl status                       # the same
timedatectl list-timezones               # every valid timezone name
timedatectl list-timezones | grep -i nairobi
sudo timedatectl set-timezone Africa/Nairobi
sudo timedatectl set-time "2026-08-18 14:30:00"    # only with NTP disabled
sudo timedatectl set-ntp true            # enable NTP synchronisation
sudo timedatectl set-ntp false           # disable it
sudo timedatectl set-local-rtc 0         # keep the RTC in UTC (recommended)
timedatectl show                         # machine-readable properties
timedatectl timesync-status              # sync details (systemd-timesyncd only)
```

Reading the output:

```text
               Local time: Tue 2026-08-18 19:15:32 EAT
           Universal time: Tue 2026-08-18 16:15:32 UTC
                 RTC time: Tue 2026-08-18 16:15:32
                Time zone: Africa/Nairobi (EAT, +0300)
System clock synchronized: yes            <- is the clock in sync?
              NTP service: active         <- is chronyd running?
          RTC in local TZ: no
```

**"NTP service: active" means `chronyd` is running. "System clock synchronized: yes" means it has actually agreed with a server.** Those are different things, and a task asking you to configure a time client needs both.

**`timedatectl set-ntp true` starts and enables `chronyd`** on RHEL. It is a shortcut for `systemctl enable --now chronyd`.

### Setting the timezone

```bash
timedatectl list-timezones | grep -i london
sudo timedatectl set-timezone Europe/London
timedatectl | grep 'Time zone'
```

**Always find the exact name with `list-timezones` first.** `Africa/Nairobi` is valid; `EAT`, `Nairobi`, and `africa/nairobi` are not. `timedatectl` rejects an invalid name, which is helpful, but only after you have wasted the attempt.

Behind the scenes this is a symlink, consistent with `05-hard-soft-links.md`:

```bash
ls -l /etc/localtime
# /etc/localtime -> ../usr/share/zoneinfo/Africa/Nairobi
```

### chrony configuration

```bash
sudo dnf install -y chrony
sudo systemctl enable --now chronyd
sudo vim /etc/chrony.conf
```

The directives that matter:

```text
# A pool of servers; chrony picks several from it
pool 2.rhel.pool.ntp.org iburst

# A single named server
server classroom.example.com iburst

# Multiple servers
server ntp1.example.com iburst
server ntp2.example.com iburst

driftfile /var/lib/chrony/drift
makestep 1.0 3              # step the clock if off by >1s, in the first 3 updates
rtcsync                     # keep the RTC in sync with the system clock
leapsectz right/UTC
logdir /var/log/chrony

# Act as a server for a local network
allow 192.168.56.0/24
local stratum 10            # serve time even when unsynchronised
```

**`iburst` is the option to remember.** Without it, chrony sends one probe every 64 seconds and can take minutes to synchronise. With `iburst` it sends a rapid burst immediately, so you get sync in a couple of seconds — which matters when you need to *verify* the task before moving on.

After editing, always:

```bash
sudo systemctl restart chronyd
chronyc sources -v
```

**A restart is required.** chrony does not reload the config on its own.

### chronyc: verifying synchronisation

```bash
chronyc sources                     # the servers being used
chronyc sources -v                  # with a legend explaining the columns
chronyc sourcestats                 # accuracy statistics
chronyc tracking                    # the current synchronisation state
chronyc activity                    # how many sources are online/offline
sudo chronyc makestep               # force an immediate step correction
sudo chronyc -a 'burst 4/4'         # force rapid polling
chronyc ntpdata                     # detailed NTP data per source
```

Reading `chronyc sources`:

```text
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* ntp1.example.com              2   6   377    41   +12us[  +18us] +/-   12ms
^- ntp2.example.com              2   6   377    43  -1543us[-1537us] +/-   24ms
^? ntp3.example.com              0   6     0     -     +0ns[   +0ns] +/-    0ns
││
│└─ * = the SELECTED source (synchronised to this one)
│   - = an acceptable source, not selected
│   ? = unreachable
└── ^ = a server, = = a peer
```

**The `^*` marker is what you are looking for.** It means chrony has selected that server and the clock is synchronised. A `^?` on every line means nothing is reachable — check the network, the hostname, and the firewall.

`chronyc tracking` gives the summary:

```text
Reference ID    : C0A83801 (ntp1.example.com)
Stratum         : 3
System time     : 0.000012345 seconds fast of NTP time
Leap status     : Normal
```

`Leap status: Normal` and a non-zero Reference ID mean you are synchronised. `Reference ID : 00000000 ()` and `Leap status: Not synchronised` mean you are not.

### Acting as an NTP server

If a task asks the machine to serve time to a subnet:

```bash
sudo tee -a /etc/chrony.conf <<'EOF'
allow 192.168.56.0/24
EOF
sudo systemctl restart chronyd

# NTP uses UDP 123
sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --reload
```

**Serving time requires opening the firewall; being a client does not.** A client makes outbound connections, which firewalld allows by default. That asymmetry is a common source of confusion.

### The hardware clock

```bash
sudo hwclock                        # read the RTC
sudo hwclock --systohc              # system clock -> RTC
sudo hwclock --hctosys              # RTC -> system clock
timedatectl set-local-rtc 0         # keep the RTC in UTC (recommended)
```

**Keep the RTC in UTC.** `RTC in local TZ: yes` causes problems around daylight saving transitions and RHEL warns about it. On a VM you will rarely touch `hwclock`, because `rtcsync` in `chrony.conf` handles it.

### Setting the time manually

```bash
sudo timedatectl set-ntp false            # NTP must be off first
sudo timedatectl set-time "2026-08-18 14:30:00"
sudo timedatectl set-time 14:30:00        # time only
sudo date -s "2026-08-18 14:30:00"        # the older way
sudo timedatectl set-ntp true             # turn it back on
```

**`set-time` fails while NTP is active**, with "Automatic time synchronization is enabled". That is deliberate — you cannot hand-set a clock that a daemon is actively correcting. Disable NTP, set the time, re-enable.

On the exam a task almost always wants NTP **enabled**, not a manually set clock. Read the wording.

### date formatting

Useful in scripts and cron jobs:

```bash
date                              # default format
date +%F                          # 2026-08-18
date +%T                          # 19:15:32
date "+%Y-%m-%d %H:%M:%S"
date +%s                          # Unix epoch seconds
date -u                           # UTC
date -d "2026-12-25"              # a specific date
date -d "next friday"
date -d "@1755000000"             # from epoch seconds
date -d "2 days ago" +%F
```

Remember from `19-scheduling-cron-at.md` that `%` must be escaped as `\%` inside a crontab.

## Tasks

**Task 1.** Determine the current timezone, whether the clock is synchronised, and whether the NTP service is active.

**Task 2.** Set the system timezone to `Africa/Nairobi`, having first confirmed the exact name is valid.

**Task 3.** Show what file `timedatectl set-timezone` actually changes.

**Task 4.** Ensure `chrony` is installed, enabled, and running.

**Task 5.** Configure this system to synchronise its time from `server2.lab.example.com`, replacing any existing time sources, using the option that makes synchronisation happen quickly.

**Task 6.** Verify that the system has actually synchronised with the configured server, and identify the selected source.

**Task 7.** Enable NTP synchronisation using `timedatectl` and confirm what service that started.

**Task 8.** Configure `server2` to act as an NTP server for the `192.168.56.0/24` network, including any firewall change required.

**Task 9.** Disable NTP, set the system clock manually to a specific time, then re-enable NTP.

**Task 10.** Force chrony to correct a large clock offset immediately rather than slewing gradually.

**Task 11.** Determine the current stratum and reference server that this system is synchronised to.

**Task 12.** Ensure the hardware clock is kept in UTC rather than local time.

**Task 13.** Confirm your time configuration survives a reboot.

**Task 14.** A system shows "System clock synchronized: no" and every source is marked `^?`. List the things you would check, in order.

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
