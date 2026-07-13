# eBPF Deep Dive

Programs at **XDP / TC / cgroup / socket**. **Maps** hold identity, CT, LB. **Verifier** sandboxes.

Benefits: O(1) lookups, incremental updates, identity keys, Hubble hooks, no reboot, L3/L4 without sidecars.

iptables: ordered O(n) rules, IP/port match, full restores, netfilter later than XDP.

See `21.md`–`22.md`.
