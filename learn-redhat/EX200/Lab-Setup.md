# Lab Setup

You cannot pass EX200 by reading. Build this lab before anything else.

## What You Need

Two virtual machines, on the same virtual network, both RHEL-compatible:

| VM | Hostname | Role | RAM | Disks |
| --- | --- | --- | --- | --- |
| **server1** | `server1.lab.example.com` | Your main practice box | 2 GB | 20 GB OS + **three spare 2 GB disks** |
| **server2** | `server2.lab.example.com` | NFS server, SSH peer, `scp` target | 1 GB | 20 GB OS |

The three spare disks on `server1` are non-negotiable. Partitioning, LVM, and swap tasks are worth a large share of the exam and you cannot practise them on a single-disk VM without risking your OS.

## Which Distribution

The exam is RHEL. For a free lab, in order of preference:

| Option | Notes |
| --- | --- |
| **RHEL 10** via the free Red Hat Developer Subscription | Identical to the exam. Register at developers.redhat.com, no cost for personal use, up to 16 systems |
| **Rocky Linux 10** or **AlmaLinux 10** | Binary-compatible rebuilds. Everything in this folder works. The only gaps are `subscription-manager` and Red Hat's own repos |
| **CentOS Stream 10** | Slightly ahead of RHEL. Fine for practice |
| Fedora | **Avoid.** Too far ahead; defaults differ |

If your booked exam is the RHEL 9 version, use version 9 of any of the above instead. This folder notes the differences inline.

## Option A: Vagrant + libvirt or VirtualBox (fastest)

The whole lab in one file. Spare disks included.

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "rockylinux/10"          # or "generic/rhel9", "almalinux/9"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.define "server1" do |s1|
    s1.vm.hostname = "server1.lab.example.com"
    s1.vm.network "private_network", ip: "192.168.56.11"

    s1.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      # three spare disks for partitioning, LVM and swap practice
      (1..3).each do |i|
        vb.customize ["createhd", "--filename", "server1-disk#{i}.vdi",
                      "--size", 2048] unless File.exist?("server1-disk#{i}.vdi")
        vb.customize ["storageattach", :id, "--storagectl", "SATA",
                      "--port", i, "--device", 0, "--type", "hdd",
                      "--medium", "server1-disk#{i}.vdi"]
      end
    end

    s1.vm.provider "libvirt" do |lv|
      lv.memory = 2048
      lv.cpus = 2
      lv.storage :file, size: '2G'
      lv.storage :file, size: '2G'
      lv.storage :file, size: '2G'
    end
  end

  config.vm.define "server2" do |s2|
    s2.vm.hostname = "server2.lab.example.com"
    s2.vm.network "private_network", ip: "192.168.56.12"
    s2.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
    end
    s2.vm.provider "libvirt" do |lv|
      lv.memory = 1024
    end
  end
end
```

```bash
vagrant up
vagrant ssh server1
```

## Option B: KVM / libvirt by hand

If you are on Linux already, this gives you the most exam-like environment, including a real GRUB screen you can interrupt.

```bash
sudo dnf install -y qemu-kvm libvirt virt-install virt-manager libvirt-daemon-config-network
sudo systemctl enable --now libvirtd

# Fetch an ISO first, then:
sudo virt-install \
  --name server1 \
  --memory 2048 --vcpus 2 \
  --disk size=20 \
  --disk size=2 --disk size=2 --disk size=2 \
  --cdrom /var/lib/libvirt/images/rocky-10-dvd.iso \
  --os-variant rhel9.0 \
  --network network=default \
  --graphics spice

sudo virt-install \
  --name server2 \
  --memory 1024 --vcpus 1 \
  --disk size=20 \
  --cdrom /var/lib/libvirt/images/rocky-10-dvd.iso \
  --os-variant rhel9.0 \
  --network network=default \
  --graphics spice
```

**Choose "Minimal Install" during setup.** You want to install packages yourself, because "install and configure httpd" is a real exam task and a pre-installed httpd teaches you nothing.

Console access, which you need for boot-recovery practice:

```bash
sudo virsh list --all
sudo virsh console server1        # exit with Ctrl+]
sudo virsh start server1
sudo virsh destroy server1        # hard power off, useful for practising crash recovery
sudo virsh snapshot-create-as server1 clean "before practice"
sudo virsh snapshot-revert server1 clean
```

## Option C: VirtualBox by hand

Works everywhere, including Windows and macOS hosts. Two things to get right:

1. **Network:** give each VM two adapters — NAT (for package downloads) and Host-only (for VM-to-VM traffic). Note the host-only subnet, usually `192.168.56.0/24`.
2. **Spare disks:** VM Settings → Storage → Controller SATA → "Add Hard Disk" → Create → VDI, dynamically allocated, 2 GB. Repeat three times.

## Snapshots Are The Whole Point

This is the difference between a lab you use once and a lab you use fifty times. **Take a snapshot the moment the base install is clean**, before you touch anything.

```bash
# libvirt
sudo virsh snapshot-create-as server1 clean "clean minimal install"
sudo virsh snapshot-revert server1 clean

# VirtualBox
VBoxManage snapshot server1 take clean
VBoxManage snapshot server1 restore clean

# Vagrant
vagrant snapshot save clean
vagrant snapshot restore clean
```

Practise a storage or SELinux block, wreck the system, revert, repeat. You want to have destroyed and rebuilt LVM setups a dozen times before exam day.

## Post-Install Configuration

Run this on **both** VMs.

```bash
# Confirm you are on the version you think you are
cat /etc/redhat-release
uname -r

# Base tools you will need for practice. Install now so a broken repo
# later does not block you.
sudo dnf install -y vim tar bzip2 xz wget curl \
  nfs-utils autofs chrony tuned \
  policycoreutils-python-utils setroubleshoot-server \
  lvm2 parted psmisc bash-completion man-pages \
  httpd firewalld openssh-server rsync

# policycoreutils-python-utils gives you `semanage`. Without it, SELinux
# port and fcontext tasks are impossible. Memorise that package name;
# a real exam task can require you to install it.

sudo systemctl enable --now firewalld sshd chronyd
```

### Hostnames and resolution

```bash
# On server1
sudo hostnamectl set-hostname server1.lab.example.com

# On server2
sudo hostnamectl set-hostname server2.lab.example.com

# On BOTH, so they can find each other without DNS
sudo tee -a /etc/hosts <<'EOF'
192.168.56.11  server1.lab.example.com server1
192.168.56.12  server2.lab.example.com server2
EOF

# Verify from server1
ping -c1 server2
ssh server2 hostname
```

### Local repository from the ISO

Worth doing, because "configure a repository" is a real exam task and this is exactly the shape of it.

```bash
sudo mkdir -p /mnt/iso /repo
# Attach the install ISO to the VM, then:
sudo mount /dev/sr0 /mnt/iso

# Make it permanent
echo '/dev/sr0  /mnt/iso  iso9660  ro,nofail  0 0' | sudo tee -a /etc/fstab
sudo mount -a
findmnt /mnt/iso

sudo tee /etc/yum.repos.d/local.repo <<'EOF'
[local-baseos]
name=Local BaseOS
baseurl=file:///mnt/iso/BaseOS
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[local-appstream]
name=Local AppStream
baseurl=file:///mnt/iso/AppStream
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF

sudo dnf clean all
sudo dnf repolist
```

On Rocky or AlmaLinux the GPG key filename differs. Check what is actually there:

```bash
ls /etc/pki/rpm-gpg/
```

Note the `nofail` option on the ISO mount. Without it, a VM booting without the ISO attached drops to emergency mode. That is a lesson worth learning here rather than on the exam.

### Confirm the spare disks are visible

```bash
lsblk
# Expect vda/sda as the OS disk, then three empty 2G disks:
# vdb, vdc, vdd  (or sdb, sdc, sdd)
```

If you only see one disk, the extra disks are not attached. Fix that before continuing; five of the numbered files depend on them.

## Verify The Lab

Run this on `server1`. Everything should pass.

```bash
echo "--- release ---";        cat /etc/redhat-release
echo "--- spare disks ---";    lsblk -dno NAME,SIZE | tail -n +2
echo "--- selinux ---";        getenforce
echo "--- firewalld ---";      systemctl is-active firewalld
echo "--- semanage ---";       command -v semanage || echo "MISSING policycoreutils-python-utils"
echo "--- repos ---";          dnf repolist | tail -5
echo "--- peer ---";           ping -c1 -W2 server2 >/dev/null && echo "server2 reachable"
echo "--- ssh peer ---";       ssh -o BatchMode=yes -o ConnectTimeout=3 server2 hostname 2>&1 | tail -1
echo "--- time ---";           timedatectl | head -3
```

Expected: an enforcing SELinux, an active firewalld, a working `semanage`, at least two repos, three spare disks, and a reachable `server2`.

## Practice Discipline

The habits that matter more than any single command.

**1. Reboot constantly.** After every block of tasks:

```bash
sudo systemctl daemon-reload
sudo findmnt --verify
sudo mount -a
sudo reboot
```

Then verify your work still holds. This trains the reflex the exam grades.

**2. Never use `--now` alone.** Train your fingers on `systemctl enable --now`, so that `enable` is never the thing you forgot.

**3. Never mount by device name.** Use `UUID=` or `LABEL=` in `fstab` every single time, even in throwaway practice.

**4. Time yourself.** Real exam tasks take 5-10 minutes each. If a single LVM task takes you 25 minutes, that is the finding, and it is more useful than knowing you eventually got it right.

**5. Break things deliberately.** `36-break-and-fix-drill.md` is built for this. Corrupt `fstab`, wreck a SELinux context, disable a service, forget a firewall rule, then fix it. Diagnosis under pressure is a separate skill from configuration.

**6. Use `man`, not the internet.** The exam gives you `man`, `info`, and `/usr/share/doc` and nothing else. Every time you reach for a search engine in practice, you are training a habit you cannot use.

```bash
man -k selinux | head
man 5 fstab
man 5 crontab
man 8 semanage-fcontext
ls /usr/share/doc/ | head -30
```

`man 5 fstab` and the `EXAMPLES` section of `man semanage-fcontext` have saved more candidates than any cheat sheet.

## Reset Script

Between practice runs, put the box back to a known state. Faster than a snapshot revert for small things.

```bash
#!/bin/bash
# lab-reset.sh — undo common practice artifacts on server1
set -x

# Unmount and remove practice mounts
for m in /mnt/data /mnt/backup /mnt/vfat /mnt/nfs /data /shared; do
  sudo umount -l "$m" 2>/dev/null
done

# Remove practice fstab lines (marked with a trailing comment)
sudo sed -i '/# PRACTICE/d' /etc/fstab

# Remove practice LVM. ADJUST NAMES TO MATCH YOURS.
sudo swapoff -a
sudo lvremove -f /dev/vgdata 2>/dev/null
sudo vgremove -f vgdata 2>/dev/null
sudo pvremove -f /dev/vdb1 /dev/vdb2 /dev/vdc1 2>/dev/null

# Wipe the spare disks completely
for d in /dev/vdb /dev/vdc /dev/vdd; do
  [ -b "$d" ] && sudo wipefs -a "$d"
done

# Remove practice users and groups
for u in alice bob carol dave natasha harry sarah; do
  sudo userdel -r "$u" 2>/dev/null
done
for g in sysadmin developers contractors adminuser; do
  sudo groupdel "$g" 2>/dev/null
done

# Reset firewall and SELinux
sudo firewall-cmd --reload
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

sudo swapon -a
sudo systemctl daemon-reload
lsblk
```

Always append `# PRACTICE` to `fstab` lines you add during drills, so this script can find and remove them. Keep that habit out of the real exam, where the lines must be permanent.

## What Good Looks Like

You are ready to start the practice exams when, on a freshly reverted snapshot, you can do all of this in **under 40 minutes** without notes:

- Create a 1 GB partition on a spare disk, format it `xfs`, and mount it persistently at `/mnt/data` by UUID.
- Create a volume group from two physical volumes, carve out a 500 MB logical volume, format and mount it, then extend it to 800 MB with the filesystem resized.
- Add a 512 MB swap partition that activates at boot.
- Create a group, three users in it, and a set-GID collaborative directory that only they can use.
- Install and enable `httpd`, serve content from a non-default document root, fix the SELinux context, and open the firewall.
- Reset a forgotten root password from the GRUB prompt.
- Reboot and have every one of the above still working.

If any of those makes you reach for notes, go back to the corresponding numbered file.
