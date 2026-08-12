# 20. Tuning Profiles With tuned

**Objective:** Manage tuning profiles.

A small objective with a short command set. Two or three commands and you are done, which makes it one of the cheapest points on the exam — do it early while you are fresh.

## Concept Refresher

`tuned` is a daemon that applies a bundle of kernel, CPU, disk, and network settings appropriate to a workload. Instead of hand-tuning `sysctl` values, you select a profile.

```bash
sudo dnf install -y tuned
sudo systemctl enable --now tuned
```

**`tuned` must be running for a profile to be applied.** Setting a profile with the service stopped records the choice but changes nothing.

### The commands

```bash
tuned-adm list                    # available profiles, with the current one marked
tuned-adm active                  # which profile is active
tuned-adm profile_info            # details of the active profile
tuned-adm profile_info throughput-performance   # details of a named profile
tuned-adm recommend               # what tuned suggests for this hardware
sudo tuned-adm profile virtual-guest            # APPLY a profile
sudo tuned-adm profile throughput-performance powersave   # combine (later wins on conflict)
sudo tuned-adm off                # stop applying any profile
sudo tuned-adm verify             # check the active profile's settings are actually in place
```

Four to memorise: **`list`**, **`active`**, **`recommend`**, and **`profile <name>`**.

### The standard profiles

| Profile | Optimised for |
| --- | --- |
| **`balanced`** | **General purpose. The usual default** |
| `powersave` | Minimum power consumption |
| **`throughput-performance`** | **Maximum throughput. Typical for servers and databases** |
| `latency-performance` | Minimum latency, at the cost of power |
| `network-latency` | Low network latency |
| `network-throughput` | Maximum network throughput |
| **`virtual-guest`** | **A VM guest. What `recommend` returns inside a VM** |
| `virtual-host` | A hypervisor |
| `desktop` | Interactive responsiveness |
| `accelerator-performance` | GPU and accelerator workloads |
| `intel-sst` | Intel Speed Select |
| `optimize-serial-console` | Serial console throughput |
| `hpc-compute` | HPC compute nodes |

Profiles inherit from each other. `virtual-guest` includes `throughput-performance` and adds VM-specific tweaks, which you can see with `tuned-adm profile_info virtual-guest`.

### Where profiles live

```text
/usr/lib/tuned/                          Shipped profiles. DO NOT EDIT
      └── balanced/tuned.conf
/etc/tuned/                              YOUR profiles and overrides
      └── myprofile/tuned.conf
/etc/tuned/active_profile                the active profile name
/etc/tuned/profile_mode                  auto or manual
```

```bash
ls /usr/lib/tuned/
ls /etc/tuned/
cat /etc/tuned/active_profile
cat /usr/lib/tuned/virtual-guest/tuned.conf
```

**`/etc/tuned/active_profile` is the persistence mechanism.** `tuned-adm profile X` writes the name there, and `tuned` reads it at startup. That is why the setting survives a reboot without any extra step.

### Creating a custom profile

Occasionally asked. Inherit from an existing profile and override what you need.

```bash
sudo mkdir -p /etc/tuned/myprofile
sudo tee /etc/tuned/myprofile/tuned.conf <<'EOF'
[main]
summary=Custom profile based on throughput-performance
include=throughput-performance

[sysctl]
vm.swappiness=10
net.core.somaxconn=2048

[cpu]
governor=performance
EOF

sudo tuned-adm profile myprofile
tuned-adm active
sudo tuned-adm verify
```

`include=` is the inheritance directive. A custom profile in `/etc/tuned/` with the same name as a shipped one takes precedence.

### Verifying a profile is genuinely applied

```bash
tuned-adm active
sudo tuned-adm verify
systemctl is-active tuned
systemctl is-enabled tuned
cat /etc/tuned/active_profile
```

`tuned-adm verify` re-checks every setting the profile should have applied and reports any that do not match. It is the honest answer to "is this really in effect", as opposed to `active`, which only reports what was requested.

Spot-check individual values:

```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
sysctl vm.swappiness
cat /sys/block/*/queue/scheduler
```

### Related: power profiles

RHEL 9 and later also ship `power-profiles-daemon` on desktops, which conflicts with `tuned`. On a server install only `tuned` is present. If both are installed, they fight; `tuned` is the one RHCSA cares about.

```bash
systemctl status power-profiles-daemon 2>/dev/null
```

## Tasks

**Task 1.** Determine whether `tuned` is installed, enabled, and running. Install and enable it if not.

**Task 2.** List all available tuning profiles and identify which is currently active.

**Task 3.** Determine which profile `tuned` recommends for this system.

**Task 4.** Apply the recommended profile and confirm it is active.

**Task 5.** Apply the `throughput-performance` profile, then verify its settings are genuinely in place.

**Task 6.** Show a description of what the `virtual-guest` profile changes.

**Task 7.** Determine, from a configuration file rather than a command, which profile will be active after the next reboot.

**Task 8.** Disable all tuning without uninstalling `tuned`, then re-enable the `balanced` profile.

**Task 9.** Create a custom profile named `ex200` that inherits from `balanced` and sets `vm.swappiness` to 10. Apply it and verify the setting took effect.

**Task 10.** Confirm that your profile choice survives a reboot.

**Task 11.** Determine the value of `vm.swappiness` currently in effect, and where the active tuned profile sets it.

---

## Solutions

**Task 1.**

```bash
rpm -q tuned
systemctl is-enabled tuned
systemctl is-active tuned
```

If it is missing:

```bash
sudo dnf install -y tuned
sudo systemctl enable --now tuned
```

Verify:

```bash
systemctl status tuned --no-pager
```

**`enable --now`, not `start`.** If `tuned` is not running at boot, the profile is not applied, and a grader checking `tuned-adm active` after a reboot may see the wrong thing.

**Task 2.**

```bash
tuned-adm list
```

```text
Available profiles:
- accelerator-performance  - Throughput performance based tuning...
- balanced                 - General non-specialized tuned profile
- desktop                  - Optimize for the desktop use-case
- latency-performance      - Optimize for deterministic performance...
- network-latency          - Optimize for deterministic performance...
- network-throughput       - Optimize for streaming network throughput...
- powersave                - Optimize for low power consumption
- throughput-performance   - Broadly applicable tuning...
- virtual-guest            - Optimize for running inside a virtual guest
- virtual-host             - Optimize for running KVM guests

Current active profile: virtual-guest
```

The active profile is named at the bottom. Or ask directly:

```bash
tuned-adm active
```

```text
Current active profile: virtual-guest
```

**Task 3.**

```bash
tuned-adm recommend
```

Inside a VM this returns `virtual-guest`. On bare-metal server hardware it typically returns `throughput-performance`. On a laptop, `balanced`.

`recommend` inspects the hardware and virtualisation status. If a task says "apply the profile recommended for this system", this command gives you the answer rather than making you guess.

**Task 4.**

```bash
sudo tuned-adm profile "$(tuned-adm recommend)"
tuned-adm active
```

Or explicitly, having read what `recommend` said:

```bash
sudo tuned-adm profile virtual-guest
tuned-adm active
```

The command substitution version is neat but the explicit version is clearer to verify. Either is fine.

**Task 5.**

```bash
sudo tuned-adm profile throughput-performance
tuned-adm active
sudo tuned-adm verify
```

```text
Verification succeeded, current system settings match the preset profile.
```

**`tuned-adm verify` is the real check.** `tuned-adm active` reports what you *asked for*; `verify` confirms every setting was actually applied. If `tuned` was not running, `active` may still show the profile name while `verify` fails.

If verification fails:

```bash
sudo tuned-adm verify
sudo journalctl -u tuned -n 30
sudo systemctl restart tuned
sudo tuned-adm verify
```

**Task 6.**

```bash
tuned-adm profile_info virtual-guest
```

Also readable directly:

```bash
cat /usr/lib/tuned/virtual-guest/tuned.conf
```

```text
[main]
summary=Optimize for running inside a virtual guest
include=throughput-performance

[sysctl]
vm.dirty_ratio = 30
vm.swappiness = 30
```

Note `include=throughput-performance`: `virtual-guest` builds on it. That inheritance is worth understanding, since it explains why two profiles can produce overlapping settings.

**Task 7.**

```bash
cat /etc/tuned/active_profile
```

```text
virtual-guest
```

Also:

```bash
cat /etc/tuned/profile_mode        # manual (you chose) or auto (recommend chose)
```

**This file is the persistence mechanism.** `tuned-adm profile X` writes the name here; `tuned` reads it at startup. Nothing else is needed to make a profile survive a reboot — no `--permanent` flag, no separate step. That is unusual on this exam and worth noting.

**Task 8.**

```bash
sudo tuned-adm off
tuned-adm active
```

```text
No current active profile.
```

The service is still running but applies nothing, so the kernel keeps whatever settings were last in place. Confirm:

```bash
systemctl is-active tuned          # still active
cat /etc/tuned/active_profile      # now empty
```

Re-enable:

```bash
sudo tuned-adm profile balanced
tuned-adm active
sudo tuned-adm verify
```

**Task 9.**

```bash
sudo mkdir -p /etc/tuned/ex200
sudo tee /etc/tuned/ex200/tuned.conf <<'EOF'
[main]
summary=EX200 practice profile
include=balanced

[sysctl]
vm.swappiness=10
EOF
```

Apply it:

```bash
sudo tuned-adm profile ex200
tuned-adm active
sudo tuned-adm verify
```

Verify the setting genuinely took effect:

```bash
sysctl vm.swappiness
# vm.swappiness = 10
cat /proc/sys/vm/swappiness
# 10
```

Confirm it is listed as available:

```bash
tuned-adm list | grep ex200
```

Two details: the directory name **is** the profile name, and the file **must** be called `tuned.conf`. Custom profiles go in `/etc/tuned/`, never `/usr/lib/tuned/`, which a package update would overwrite.

`include=balanced` means you inherit everything from `balanced` and override only `vm.swappiness`. Without `include`, you would get *only* your own settings and lose all the sensible defaults.

**Task 10.**

```bash
tuned-adm active
cat /etc/tuned/active_profile
sudo reboot
```

After the reboot:

```bash
tuned-adm active                   # the same profile
systemctl is-active tuned          # active
systemctl is-enabled tuned         # enabled
sudo tuned-adm verify              # settings actually applied
sysctl vm.swappiness               # your custom value, if using ex200
```

**All four checks matter.** The profile name persists in `/etc/tuned/active_profile` regardless, but if `tuned` is not **enabled**, the service does not start and the settings are never applied — so `active` could report a profile that is having no effect. That is why `is-enabled` and `verify` are both part of the check.

**Task 11.**

Current effective value:

```bash
sysctl vm.swappiness
cat /proc/sys/vm/swappiness
```

Where the profile sets it:

```bash
tuned-adm active
grep -r swappiness /usr/lib/tuned/ /etc/tuned/ 2>/dev/null
```

```text
/usr/lib/tuned/virtual-guest/tuned.conf:vm.swappiness = 30
/usr/lib/tuned/throughput-performance/tuned.conf:vm.swappiness=10
/etc/tuned/ex200/tuned.conf:vm.swappiness=10
```

Note that the value can also come from `/etc/sysctl.conf` or `/etc/sysctl.d/*.conf`, which are independent of `tuned`:

```bash
grep -r swappiness /etc/sysctl.conf /etc/sysctl.d/ 2>/dev/null
```

**When a kernel parameter is not what you expect, check both `tuned` and `sysctl.d`.** They are separate mechanisms and can disagree; whichever was applied last wins, and `tuned` re-applies its values when the service restarts.

---

## Verify

```bash
rpm -q tuned
systemctl is-enabled tuned; systemctl is-active tuned
tuned-adm active
tuned-adm recommend
sudo tuned-adm verify
cat /etc/tuned/active_profile
tuned-adm list | head -15
sysctl vm.swappiness
```

## Persistence Check

| Change | Persistent artifact |
| --- | --- |
| `tuned-adm profile X` | **`/etc/tuned/active_profile`** — automatically persistent |
| A custom profile | `/etc/tuned/<name>/tuned.conf` |
| `tuned-adm off` | Empties `active_profile` |
| **`tuned` enabled** | **Required, or nothing is applied at boot** |

This objective is unusual in that the profile choice persists with no extra step — no `--permanent`, no config file to edit. But the service enablement is the catch:

```bash
sudo systemctl enable --now tuned
```

Without `enable`, a reboot leaves `tuned` stopped. `tuned-adm active` would still print the profile name from `/etc/tuned/active_profile`, but `tuned-adm verify` would fail and the actual kernel settings would be defaults. **A grader checking the applied settings rather than the profile name would fail you.**

Post-reboot check, all four lines:

```bash
systemctl is-enabled tuned      # enabled
systemctl is-active tuned       # active
tuned-adm active                # the expected profile
sudo tuned-adm verify           # settings genuinely in place
```

## Exam Tips

- **The four commands: `tuned-adm list`, `tuned-adm active`, `tuned-adm recommend`, `sudo tuned-adm profile <name>`.**
- **`tuned-adm recommend`** answers "apply the profile recommended for this system" without guessing.
- **`sudo systemctl enable --now tuned`.** Without `enable`, nothing is applied after a reboot even though the profile name persists.
- **The profile choice persists automatically** in `/etc/tuned/active_profile`. No extra step needed.
- **`tuned-adm verify`** confirms the settings are genuinely applied. `active` only reports what was requested.
- **`virtual-guest`** for a VM, **`throughput-performance`** for a physical server, **`balanced`** as the general default.
- **`tuned-adm off`** stops applying any profile without stopping the service.
- Custom profiles go in **`/etc/tuned/<name>/tuned.conf`**, never `/usr/lib/tuned/`. The directory name is the profile name and the file must be `tuned.conf`.
- Use **`include=`** to inherit from an existing profile, or you lose all its defaults.
- `tuned-adm profile_info <name>` describes what a profile changes; the `tuned.conf` files are readable directly.
- Kernel parameters can also come from **`/etc/sysctl.d/`**, independently of `tuned`. Check both when a value surprises you.
- **This is a cheap task. Do it early**, verify it, and move on to storage.
