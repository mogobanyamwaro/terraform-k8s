# Networking Deep Dive

Three objectives — addresses, name resolution, and firewalld — plus "configure network services to start automatically at boot". Networking is also the domain where a mistake can disconnect you from your own exam session, so the order in which you do things matters.

Step-by-step tasks are in `24-network-nmcli.md`, `25-hostnames-dns.md`, and `26-firewalld.md`.

---

## The RHEL networking model

```text
   Hardware interface            ens160          a DEVICE
        │
        ▼
   Connection profile            "static-lab"    a CONFIGURATION
        │                                        one device can have several
        ▼                                        profiles; one is active
   NetworkManager
        │
        ▼
   Keyfile on disk               /etc/NetworkManager/system-connections/
        │
        ▼
   Kernel                        ip addr, ip route
```

**Two things people conflate:**

| | Device | Connection |
| --- | --- | --- |
| Is | Hardware, or a virtual interface | **A named set of settings** |
| Named | `ens160`, `eth0`, `lo` | Anything: `ens160`, `static-lab`, `Wired connection 1` |
| Listed by | `nmcli device status` | **`nmcli connection show`** |
| Can there be several? | One per interface | **Several per device; one active** |
| Modified by | — | **`nmcli connection modify`** |

```bash
nmcli device status
```

```text
DEVICE  TYPE      STATE      CONNECTION
ens160  ethernet  connected  static-lab
lo      loopback  unmanaged  --
```

```bash
nmcli connection show
```

```text
NAME         UUID                                  TYPE      DEVICE
static-lab   b2a1c3d4-...                          ethernet  ens160
dhcp-backup  e5f6a7b8-...                          ethernet  --
```

**`dhcp-backup` exists on disk and is not active.** That is normal and useful: you can define an alternative and switch with one command.

**A connection profile whose name matches the device name is the common default**, which is why `nmcli con mod ens160 ...` usually works — you are naming the *connection*, and it happens to share the device's name.

### Interface naming

RHEL uses predictable names derived from hardware topology:

| Prefix | Meaning |
| --- | --- |
| `en` | Ethernet |
| `wl` | Wireless LAN |
| `ww` | WWAN |
| `enp0s3` | PCI bus 0, slot 3 |
| `ens160` | PCI hotplug slot 160 |
| `eno1` | Onboard index 1 |
| `enx0242ac110002` | Derived from the MAC address |
| `eth0` | The old scheme; appears when predictable naming is disabled |

```bash
ip link
nmcli device status
ls /sys/class/net/
```

**Never assume the interface is `eth0`. Run `nmcli device status` first, every time.**

---

## Configuring addresses

### Creating a new profile

```bash
sudo nmcli connection add \
  type ethernet \
  con-name static-lab \
  ifname ens160 \
  ipv4.method manual \
  ipv4.addresses 192.168.56.11/24 \
  ipv4.gateway 192.168.56.1 \
  ipv4.dns "192.168.56.1 8.8.8.8" \
  ipv4.dns-search lab.example.com \
  autoconnect yes

sudo nmcli connection up static-lab
```

### Modifying an existing profile

```bash
sudo nmcli con mod ens160 ipv4.method manual
sudo nmcli con mod ens160 ipv4.addresses 192.168.56.11/24
sudo nmcli con mod ens160 ipv4.gateway 192.168.56.1
sudo nmcli con mod ens160 ipv4.dns "192.168.56.1 8.8.8.8"
sudo nmcli con mod ens160 ipv4.dns-search lab.example.com
sudo nmcli con mod ens160 connection.autoconnect yes
sudo nmcli con up ens160
```

**Or in one command:**

```bash
sudo nmcli con mod ens160 \
  ipv4.method manual \
  ipv4.addresses 192.168.56.11/24 \
  ipv4.gateway 192.168.56.1 \
  ipv4.dns "192.168.56.1 8.8.8.8" \
  connection.autoconnect yes
sudo nmcli con up ens160
```

### The two-step rule

```text
   nmcli con mod ...        writes the keyfile      → persistent, NOT active
   nmcli con up ...         activates the profile   → active
```

**You need both.** This is the commonest networking mistake, and it is confusing because your verification with `ip addr` shows the old address while the file on disk is already correct.

```bash
sudo nmcli con mod ens160 ipv4.addresses 192.168.56.11/24
ip -brief addr show ens160                    # still the OLD address
sudo nmcli con up ens160
ip -brief addr show ens160                    # now correct
```

**The inverse mistake is `ip addr add`:**

```bash
sudo ip addr add 192.168.56.11/24 dev ens160  # active, NOT persistent
```

**`ip` commands are for diagnosis and never for configuration on this exam.**

### `ipv4.method`

| Value | Meaning |
| --- | --- |
| `auto` | DHCP |
| **`manual`** | **Static. REQUIRED when you set an address** |
| `disabled` | No IPv4 at all |
| `link-local` | 169.254.x.x only |
| `shared` | Act as a DHCP server for this link |

**Setting `ipv4.addresses` without `ipv4.method manual` leaves DHCP in charge**, and your static address is either ignored or added as a secondary. Always set the method.

### Prefix, not netmask

```bash
ipv4.addresses 192.168.56.11/24               # correct
ipv4.addresses 192.168.56.11 255.255.255.0    # WRONG
```

| Prefix | Netmask |
| --- | --- |
| `/8` | 255.0.0.0 |
| `/16` | 255.255.0.0 |
| **`/24`** | **255.255.255.0** |
| `/25` | 255.255.255.128 |
| `/30` | 255.255.255.252 |

### Multiple addresses

```bash
sudo nmcli con mod ens160 +ipv4.addresses 10.0.0.5/24     # ADD
sudo nmcli con mod ens160 -ipv4.addresses 10.0.0.5/24     # REMOVE
sudo nmcli con mod ens160 ipv4.addresses "192.168.56.11/24,10.0.0.5/24"   # SET both
sudo nmcli con up ens160
ip -brief addr show ens160
```

**`+` appends, `-` removes, and plain assignment replaces.** The same applies to `ipv4.dns`, `ipv4.routes`, and other list properties. **Assigning without `+` when you meant to add silently discards the existing values.**

### IPv6

```bash
sudo nmcli con mod ens160 \
  ipv6.method manual \
  ipv6.addresses 2001:db8:0:1::11/64 \
  ipv6.gateway 2001:db8:0:1::1 \
  ipv6.dns 2001:4860:4860::8888
sudo nmcli con up ens160
ip -6 addr show ens160
ip -6 route
ping6 -c3 2001:db8:0:1::1
```

| `ipv6.method` | Meaning |
| --- | --- |
| `auto` | SLAAC or DHCPv6 |
| **`manual`** | **Static** |
| `dhcp` | DHCPv6 only |
| `ignore` | Leave IPv6 alone |
| `disabled` | Off |
| `link-local` | fe80:: only |

**A link-local `fe80::` address always exists when IPv6 is enabled and is not what a task means by "configure an IPv6 address".**

**IPv4 and IPv6 are configured independently on the same profile**, so a dual-stack task is just both sets of properties.

### Keyfiles

```bash
ls -l /etc/NetworkManager/system-connections/
sudo cat /etc/NetworkManager/system-connections/static-lab.nmconnection
```

```ini
[connection]
id=static-lab
uuid=b2a1c3d4-...
type=ethernet
interface-name=ens160
autoconnect=true

[ipv4]
address1=192.168.56.11/24,192.168.56.1
dns=192.168.56.1;8.8.8.8;
dns-search=lab.example.com;
method=manual

[ipv6]
method=auto
```

```bash
sudo nmcli connection reload                  # re-read the files after manual editing
sudo nmcli con up static-lab
```

**Keyfiles must be mode 600 and owned by root**, or NetworkManager ignores them:

```bash
sudo chmod 600 /etc/NetworkManager/system-connections/*.nmconnection
sudo nmcli connection reload
```

**Editing a keyfile by hand is legitimate but `nmcli` is faster and cannot produce a syntax error.** Know where the files are so you can verify persistence by looking at disk.

**Legacy `ifcfg-` files in `/etc/sysconfig/network-scripts/` still work on RHEL 9 via a plugin and are removed in RHEL 10.** Do not create new ones.

### nmtui

```bash
sudo nmtui
```

A menu-driven front end covering "Edit a connection", "Activate a connection", and "Set system hostname". **It writes the same keyfiles, so it is equally persistent.**

**Use it if you cannot remember `nmcli` syntax under pressure.** It is slower but it will not produce a typo in a property name. **Remember to activate the connection afterwards** — editing in nmtui does not necessarily reapply it.

### Applying changes without disconnecting

```bash
sudo nmcli device reapply ens160
```

**`nmcli con up` briefly deactivates and reactivates the connection**, which drops your SSH session if you are connected through it. `device reapply` applies changes in place where possible.

**Safer patterns when you are working over SSH:**

```bash
# 1. Add an address rather than replacing one
sudo nmcli con mod ens160 +ipv4.addresses 192.168.56.11/24
sudo nmcli device reapply ens160
ip -brief addr

# 2. Or schedule a rescue in case you lose access
sudo sh -c 'sleep 300 && nmcli con up ens160' &
```

**If a task requires changing the address you are connected through, expect to reconnect on the new address.** Know it in advance and write the new address down.

### NetworkManager itself

```bash
systemctl status NetworkManager
sudo systemctl enable --now NetworkManager
nmcli general status
nmcli general permissions
nmcli networking off ; nmcli networking on
nmcli device disconnect ens160 ; nmcli device connect ens160
sudo journalctl -u NetworkManager -n 40
```

**`connection.autoconnect yes` is what makes a profile come up at boot.** A perfect profile with `autoconnect no` is not persistent in the sense that matters:

```bash
nmcli -f NAME,DEVICE,AUTOCONNECT connection show
```

```text
NAME         DEVICE  AUTOCONNECT
static-lab   ens160  yes
```

**Check that column before every reboot.**

---

## Name resolution

### The chain

```text
   getent hosts server2
        │
        ▼
   /etc/nsswitch.conf     hosts: files dns myhostname
        │                        │     │
        │                        │     └─→ /etc/resolv.conf → a DNS server
        │                        └─→ /etc/hosts
        ▼
   An address, or failure
```

```bash
grep ^hosts /etc/nsswitch.conf
```

```text
hosts:      files dns myhostname
```

**`files` means `/etc/hosts` and it comes first.** So a wrong entry in `/etc/hosts` overrides DNS and produces a very confusing failure.

### Hostname

```bash
hostnamectl
sudo hostnamectl set-hostname server1.lab.example.com
cat /etc/hostname
hostname ; hostname -f ; hostname -s ; hostname -I
```

```text
 Static hostname: server1.lab.example.com
       Icon name: computer-vm
         Chassis: vm
  Operating System: Red Hat Enterprise Linux 10.0
```

| Kind | Meaning |
| --- | --- |
| **`static`** | **From `/etc/hostname`. This is what `set-hostname` changes** |
| `transient` | Set by DHCP or mDNS, lost at reboot |
| `pretty` | A free-form description |

```bash
sudo hostnamectl set-hostname --pretty "Lab Server One"
sudo hostnamectl set-hostname --static server1.lab.example.com
```

**`hostname server1` is runtime only.** `hostnamectl set-hostname` writes `/etc/hostname` and is persistent — the only correct answer.

**Add the FQDN to `/etc/hosts` as well**, so the name resolves without DNS:

```bash
echo "192.168.56.11  server1.lab.example.com  server1" | sudo tee -a /etc/hosts
hostname -f
```

### `/etc/hosts`

```text
127.0.0.1       localhost localhost.localdomain
::1             localhost localhost.localdomain
192.168.56.11   server1.lab.example.com server1
192.168.56.12   server2.lab.example.com server2
```

```bash
echo "192.168.56.12  server2.lab.example.com server2" | sudo tee -a /etc/hosts
getent hosts server2
ping -c2 server2
```

**Rules:**

- **Address first, then the FQDN, then short aliases.**
- **One line per address.** Multiple names on one line are aliases for the same host.
- **Do not remove or alter the `localhost` lines.** Some services fail without them.
- It is a plain file, so it is persistent by nature.

### DNS

**`/etc/resolv.conf` is generated by NetworkManager. Editing it does not persist.**

```bash
cat /etc/resolv.conf
```

```text
# Generated by NetworkManager
search lab.example.com
nameserver 192.168.56.1
nameserver 8.8.8.8
```

```bash
sudo nmcli con mod ens160 ipv4.dns "192.168.56.1 8.8.8.8"
sudo nmcli con mod ens160 ipv4.dns-search lab.example.com
sudo nmcli con up ens160
cat /etc/resolv.conf                          # now reflects your settings
```

**Adding rather than replacing:**

```bash
sudo nmcli con mod ens160 +ipv4.dns 1.1.1.1
sudo nmcli con mod ens160 -ipv4.dns 8.8.8.8
```

**When DHCP is supplying DNS servers you do not want:**

```bash
sudo nmcli con mod ens160 ipv4.ignore-auto-dns yes
sudo nmcli con mod ens160 ipv4.dns "192.168.56.1"
sudo nmcli con up ens160
```

**To take full manual control of the file** (rarely needed, and worth knowing exists):

```text
# /etc/NetworkManager/NetworkManager.conf
[main]
dns=none
```

```bash
sudo systemctl reload NetworkManager
# now /etc/resolv.conf is yours to edit
```

### Query tools, and which to use

| Tool | Consults |
| --- | --- |
| **`getent hosts NAME`** | **`/etc/nsswitch.conf`: `/etc/hosts` then DNS. What applications actually do** |
| `getent ahosts NAME` | The same, with all address families |
| **`dig NAME`** | **DNS only** |
| `host NAME` | DNS only, briefer output |
| `nslookup NAME` | DNS only, older |
| `ping NAME` | Resolution plus reachability — two things at once |
| `resolvectl query NAME` | Via systemd-resolved, if in use |

```bash
getent hosts server2
dig +short server2.lab.example.com
dig server2.lab.example.com
dig @8.8.8.8 example.com
dig -x 192.168.56.12                          # reverse lookup
dig example.com MX
dig example.com AAAA
host server2 ; host -t MX example.com
```

**The most useful diagnostic in this area:**

```bash
getent hosts server2     # works
dig +short server2       # returns nothing
```

**That combination means the answer came from `/etc/hosts`, not DNS.** Which is fine if the task asked for a static entry, and a red flag if it asked for DNS.

The reverse:

```bash
dig +short server2.lab.example.com   # returns an address
getent hosts server2                 # fails
```

**That means DNS works but the short name is not being completed** — check `ipv4.dns-search`, and note that `getent` does not apply the search domain the way `ping` does.

### Troubleshooting resolution

```text
Symptom                              Check
────────────────────────────────────────────────────────────────────────
"Name or service not known"           cat /etc/resolv.conf — any nameserver?
                                      getent hosts NAME
                                      grep ^hosts /etc/nsswitch.conf

Resolves to the WRONG address         grep NAME /etc/hosts    ← files come first
                                      dig +short NAME

Works by IP, not by name              DNS or /etc/hosts

Works for the FQDN, not the short name ipv4.dns-search
                                      nmcli con show ens160 | grep dns-search

Was working, now is not               /etc/resolv.conf was regenerated;
                                      set DNS via nmcli, not by editing

Slow resolution                       An unreachable first nameserver;
                                      reorder ipv4.dns
```

```bash
cat /etc/resolv.conf
grep ^hosts /etc/nsswitch.conf
nmcli con show ens160 | grep -i dns
getent hosts NAME
dig +short NAME
ping -c2 <the DNS server's IP>
```

---

## firewalld

### The model

```text
   Packet arrives on ens160 from 192.168.56.10
        │
        ▼
   Which ZONE applies?
        │  1. Is the source address bound to a zone?      ← WINS if so
        │  2. Is the interface assigned to a zone?
        │  3. The default zone
        ▼
   Zone rules: services, ports, rich rules, ICMP blocks
        │
        ▼
   ACCEPT / REJECT / DROP
```

```bash
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --get-zones
sudo firewall-cmd --list-all
sudo firewall-cmd --list-all-zones
sudo firewall-cmd --info-zone=public
```

```text
public (active)
  target: default
  interfaces: ens160
  sources:
  services: cockpit dhcpv6-client ssh
  ports:
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  rich rules:
```

| Zone | Default posture |
| --- | --- |
| `drop` | Everything incoming dropped, no reply |
| `block` | Everything incoming rejected with an ICMP message |
| **`public`** | **The default. Selected incoming services only** |
| `external` | Like public, with masquerading on |
| `dmz` | Limited incoming |
| `work`, `home`, `internal` | Progressively more permissive |
| **`trusted`** | **Everything accepted** |

**`public` is the default zone on RHEL and normally has `ssh` allowed.** Never remove `ssh` from your active zone unless a task explicitly demands it.

### Runtime versus permanent

**This is the whole objective in one idea. firewalld keeps two configurations:**

```text
   RUNTIME     what the kernel is enforcing right now
               lost on --reload and at reboot

   PERMANENT   what is written under /etc/firewalld/
               loaded at start and on --reload
```

| Command | Affects |
| --- | --- |
| `firewall-cmd --add-service=http` | **Runtime only** |
| `firewall-cmd --permanent --add-service=http` | **Permanent only — not active yet** |
| **`--permanent` then `--reload`** | **Both. The correct pattern** |
| `--runtime-to-permanent` | Copies runtime into permanent |

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

**Two half-mistakes with the same result:**

```bash
sudo firewall-cmd --add-service=http               # works now, gone at reboot
sudo firewall-cmd --permanent --add-service=http   # survives reboot, not working now
```

**The second is worse on the exam**, because your own verification fails and you may conclude something else is wrong.

**The check that catches both:**

```bash
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
```

**Empty output means the two agree.** Run it before every reboot.

**The rescue, after a session of runtime-only changes:**

```bash
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --permanent --list-all
```

**And note `--reload` discards runtime-only changes**, which is exactly how people lose work they thought was saved.

### Services versus ports

```bash
sudo firewall-cmd --get-services                     # ~180 predefined
sudo firewall-cmd --info-service=http
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service={http,https}
sudo firewall-cmd --permanent --remove-service=http
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=6000-6010/udp
sudo firewall-cmd --permanent --remove-port=8080/tcp
sudo firewall-cmd --reload
```

**Prefer a service name when one exists.** It covers every port the protocol needs, which matters for NFS:

```bash
sudo firewall-cmd --info-service=nfs
sudo firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
```

**Doing NFS by port number means finding three or four ports and getting them all right. The service names are safer.**

Service definitions live in `/usr/lib/firewalld/services/`; your own go in `/etc/firewalld/services/`.

### Zones by source

```bash
sudo firewall-cmd --permanent --zone=trusted --add-source=192.168.56.0/24
sudo firewall-cmd --permanent --zone=trusted --add-source=192.168.56.10/32
sudo firewall-cmd --permanent --zone=drop --add-source=10.0.0.0/8
sudo firewall-cmd --reload
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=trusted --list-all
```

```text
trusted (active)
  target: ACCEPT
  sources: 192.168.56.0/24
```

**A source-bound zone beats the interface's zone.** So "allow everything from the lab subnet, restrict everyone else" is naturally expressed as a source in `trusted` while the interface stays in `public`.

```bash
sudo firewall-cmd --permanent --zone=internal --change-interface=ens160
sudo firewall-cmd --permanent --zone=public --add-interface=ens224
sudo firewall-cmd --reload
```

**`--change-interface` moves an interface; `--add-interface` fails if it is already assigned elsewhere.**

### Rich rules

Rich rules express "this source, this service, this action" in one statement.

```bash
# Allow HTTP from one subnet only
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="192.168.56.0/24" service name="http" accept'

# Reject everything from a subnet
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="10.0.0.0/8" reject'

# Drop silently
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="172.16.0.0/12" drop'

# One host, one port
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="192.168.56.10/32" port port="3306" protocol="tcp" accept'

# With logging and rate limiting
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="192.168.56.0/24" service name="ssh" \
  log prefix="ssh " level="info" limit value="3/m" accept'

# Everything except one host
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="192.168.56.10" service name="http" reject'
sudo firewall-cmd --permanent --add-service=http

sudo firewall-cmd --reload
sudo firewall-cmd --list-rich-rules
sudo firewall-cmd --permanent --list-rich-rules
sudo firewall-cmd --permanent --remove-rich-rule='...the exact same string...'
```

**Syntax notes:**

- **`family="ipv4"` or `"ipv6"` is required** when the rule has a source or destination.
- **Single-quote the whole rule** so the shell leaves the double quotes alone.
- **Removing a rule needs the string to match exactly.** Copy it from `--list-rich-rules`.

| Action | Behaviour |
| --- | --- |
| `accept` | Allow |
| **`reject`** | **Refuse with an ICMP message — the client fails fast** |
| **`drop`** | **Discard silently — the client times out** |
| `mark` | Tag for later processing |

**Precedence within a zone: rich rules with an action are evaluated before the plain service and port lists**, so a `reject` rich rule for one host coexists with a general `--add-service=http`.

### Masquerading and forwarding

```bash
sudo firewall-cmd --permanent --add-masquerade
sudo firewall-cmd --permanent --add-forward-port=port=8080:proto=tcp:toport=80
sudo firewall-cmd --permanent --add-forward-port=port=2222:proto=tcp:toport=22:toaddr=192.168.56.12
sudo firewall-cmd --reload
sudo firewall-cmd --list-forward-ports
sudo firewall-cmd --query-masquerade
```

**Port forwarding to another host requires masquerading.** Same-host forwarding does not, but enabling it is harmless.

### The service

```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --state
systemctl is-enabled firewalld
sudo firewall-cmd --reload                    # reload permanent into runtime
sudo firewall-cmd --complete-reload           # also drops existing connections
sudo firewall-cmd --panic-on                  # block EVERYTHING
sudo firewall-cmd --panic-off
```

**`--panic-on` disconnects you.** Never use it on a machine you are connected to.

**A task saying "the firewall must be active at boot" means `systemctl enable --now firewalld`** as well as the rules.

### Querying and testing

```bash
sudo firewall-cmd --query-service=http ; echo $?
sudo firewall-cmd --query-port=8080/tcp
sudo firewall-cmd --list-services
sudo firewall-cmd --list-ports
sudo firewall-cmd --list-rich-rules
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --list-all
```

**Locally, then remotely — the two tests mean different things:**

```bash
ss -tlnp | grep 8080                          # is anything listening?
curl http://localhost:8080                    # does the service work at all?
# from server2:
curl http://192.168.56.11:8080                # does the firewall allow it?
nc -zv 192.168.56.11 8080
```

| Local | Remote | Diagnosis |
| --- | --- | --- |
| Fails | Fails | **The service, not the firewall** |
| **Works** | **Fails** | **The firewall** |
| Works | Works | Done |
| Fails | Works | Unusual — check what is bound to which address |

**The firewall never stops a local process from binding a port, and never affects loopback traffic.** If `curl http://localhost` fails, stop looking at firewalld.

### Underlying nftables

```bash
sudo nft list ruleset | head -40
sudo nft list table inet firewalld
```

**firewalld generates nftables rules. Never write nftables rules directly on this exam** — firewalld overwrites them at the next reload, so they are not persistent.

---

## Bringing it together

**Task: server1 runs a web server on port 8090, reachable only from 192.168.56.0/24.**

```bash
# 1. The service
sudo dnf install -y httpd
sudo sed -i 's/^Listen 80$/Listen 8090/' /etc/httpd/conf/httpd.conf
echo '<h1>server1</h1>' | sudo tee /var/www/html/index.html

# 2. SELinux — the port label
sudo semanage port -a -t http_port_t -p tcp 8090

# 3. The service, persistently
sudo systemctl enable --now httpd
systemctl is-enabled httpd
ss -tlnp | grep 8090
curl http://localhost:8090

# 4. The firewall — only the lab subnet
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  source address="192.168.56.0/24" port port="8090" protocol="tcp" accept'
sudo firewall-cmd --reload

# 5. Verify
sudo firewall-cmd --list-rich-rules
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)
# from server2:
curl http://192.168.56.11:8090

# 6. Reboot and re-verify, touching nothing
sudo reboot
systemctl is-active httpd
sudo firewall-cmd --list-rich-rules
```

**Three layers again: the service's own config, the SELinux port label, and the firewall.** This structure recurs throughout the exam.

---

## Verification

```bash
# Addresses — active AND persistent
ip -brief addr
ip route
nmcli -f NAME,DEVICE,AUTOCONNECT connection show
nmcli con show ens160 | grep -E 'ipv4.method|ipv4.addresses|ipv4.gateway|ipv4.dns'
ls -l /etc/NetworkManager/system-connections/
systemctl is-enabled NetworkManager

# Name resolution
hostnamectl
cat /etc/hostname
grep -v '^#' /etc/hosts
cat /etc/resolv.conf
getent hosts server2
dig +short server2.lab.example.com

# Firewall
sudo firewall-cmd --state
systemctl is-enabled firewalld
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --list-all
diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)

# Reachability, from the other host
ping -c2 192.168.56.11
ssh server1 hostname
curl http://192.168.56.11
```

**Then reboot and repeat.** In particular `AUTOCONNECT` must be `yes` and the firewall diff must be empty.

---

## The five things to take away

1. **`nmcli con mod` writes the file; `nmcli con up` applies it. Both, every time.**
2. **`ipv4.method manual` when setting a static address**, and `connection.autoconnect yes` for boot.
3. **`hostnamectl set-hostname`, not `hostname`.** And never edit `/etc/resolv.conf` — use `ipv4.dns`.
4. **`firewall-cmd --permanent` then `--reload`.** Verify with the runtime/permanent diff.
5. **Works locally but not remotely is the firewall. Will not start at all is usually SELinux.**
