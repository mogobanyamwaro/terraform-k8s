# 22. Software Management: dnf, rpm, And Repositories

**Objective:** Install and update software packages from Red Hat Network, a remote repository, or from the local file system. Configure RPM repositories.

**Do the repository task early.** Every later task that says "install and configure X" depends on working repositories. If repos are broken and you leave it until minute 120, you lose every dependent task.

## Concept Refresher

### dnf versus rpm

| | **dnf** | **rpm** |
| --- | --- | --- |
| Resolves dependencies | **Yes** | **No** |
| Downloads from repositories | Yes | No |
| Use for | **Installing, updating, removing, searching** | **Querying what is installed** |
| Install a local file | `dnf install ./pkg.rpm` (resolves deps) | `rpm -ivh pkg.rpm` (fails on missing deps) |

**Rule: install with `dnf`, query with `rpm`.** `dnf install ./local.rpm` is better than `rpm -ivh local.rpm` because it pulls in dependencies from your repos.

`yum` is a symlink to `dnf` on RHEL 8+, so every `yum` command still works.

### dnf: the commands

```bash
sudo dnf install httpd
sudo dnf install -y httpd vim tar          # several at once
sudo dnf install ./local-package.rpm       # a local file, WITH dependency resolution
sudo dnf install https://host/pkg.rpm      # straight from a URL

sudo dnf remove httpd
sudo dnf autoremove                        # drop orphaned dependencies

sudo dnf update                            # everything
sudo dnf update httpd                      # one package
sudo dnf upgrade                           # a synonym for update
sudo dnf check-update                      # what is available, without installing
sudo dnf downgrade httpd                   # go back a version
sudo dnf reinstall httpd

dnf search httpd                           # search names and summaries
dnf search all "web server"                # search descriptions too
dnf info httpd                             # details about a package
dnf list installed                         # everything installed
dnf list installed | grep httpd
dnf list available
dnf list httpd                             # installed and available versions

dnf provides /etc/httpd/conf/httpd.conf    # WHICH PACKAGE PROVIDES THIS FILE
dnf provides */semanage                    # find the package for a command
dnf repoquery -l httpd                     # files in a package, without installing it
dnf deplist httpd                          # dependencies

dnf history                                # transaction history
dnf history info 5                         # details of transaction 5
sudo dnf history undo 5                    # REVERSE transaction 5
sudo dnf history redo 5
sudo dnf history rollback 5

sudo dnf clean all                         # clear the metadata cache
sudo dnf makecache                         # rebuild it
dnf repolist                               # enabled repositories
dnf repolist --all                         # including disabled
dnf repoinfo                               # detailed repository information
```

**`dnf provides` is the one that saves you.** When you know you need `semanage` but not which package supplies it:

```bash
dnf provides */semanage
# policycoreutils-python-utils-3.6-2.el9.x86_64 : SELinux policy core python utilities
```

Memorise that `semanage` comes from **`policycoreutils-python-utils`**. Without it, every SELinux port and fcontext task is impossible, and it is not always installed.

### Package groups

```bash
dnf group list
dnf group list --available
dnf group info "Development Tools"
sudo dnf group install "Development Tools"
sudo dnf group install @development         # the @ shorthand
sudo dnf group remove "Development Tools"
dnf group list --installed
```

`dnf install @groupname` and `dnf group install "Group Name"` are equivalent. Quote names containing spaces.

### Modules and application streams

RHEL 8 introduced modules for shipping multiple versions of the same software. RHEL 9 and 10 use them much less, but recognise the commands:

```bash
dnf module list
dnf module list nodejs
dnf module info nodejs:18
sudo dnf module install nodejs:18
sudo dnf module enable nodejs:18
sudo dnf module disable nodejs
sudo dnf module reset nodejs
sudo dnf module switch-to nodejs:20
```

`reset` returns a module to no enabled stream, which you need before switching versions.

### rpm: querying

```bash
rpm -qa                             # all installed packages
rpm -qa | grep httpd
rpm -q httpd                        # is this package installed, and which version
rpm -qi httpd                       # detailed info
rpm -ql httpd                       # LIST all files
rpm -qc httpd                       # CONFIG files only
rpm -qd httpd                       # DOCUMENTATION files only
rpm -qf /etc/httpd/conf/httpd.conf  # which package owns this FILE
rpm -q --changelog httpd | head
rpm -q --scripts httpd              # install/uninstall scripts
rpm -V httpd                        # VERIFY: what has changed since installation
rpm -Va                             # verify everything (slow)
rpm -qa --last | head               # most recently installed

# Query a FILE that is not installed
rpm -qip package.rpm
rpm -qlp package.rpm

# Install / upgrade / erase (prefer dnf for these)
sudo rpm -ivh package.rpm           # install, verbose, hash progress
sudo rpm -Uvh package.rpm           # upgrade or install
sudo rpm -Fvh package.rpm           # freshen: upgrade only if already installed
sudo rpm -e httpd                   # erase
sudo rpm -ivh --nodeps package.rpm  # skip dependency checks. Avoid
```

**The four query flags to know cold: `-qa` all, `-qf` which package owns a file, `-ql` list files, `-qc` config files.**

`rpm -V` output decodes as:

```text
S.5....T.  c /etc/httpd/conf/httpd.conf
│ │    │   │
│ │    │   └─ c = a config file
│ │    └───── T = timestamp differs
│ └────────── 5 = MD5 checksum differs (CONTENTS CHANGED)
└──────────── S = size differs
```

Other codes: `M` mode, `U` owner, `G` group, `L` symlink path, `D` device. A `5` on a config file is expected if you edited it; a `5` on a binary is a red flag.

### Repository files

Repositories are defined in `/etc/yum.repos.d/*.repo`.

```bash
ls /etc/yum.repos.d/
cat /etc/yum.repos.d/*.repo | head -20
```

The format:

```text
[repo-id]                     <- unique, no spaces, used on the command line
name=Human Readable Name      <- REQUIRED
baseurl=https://host/path/    <- REQUIRED (or mirrorlist/metalink)
enabled=1                     <- 1 or 0
gpgcheck=1                    <- verify package signatures
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
```

Valid `baseurl` schemes:

```text
baseurl=https://repo.example.com/rhel9/BaseOS/
baseurl=http://repo.example.com/rhel9/AppStream/
baseurl=ftp://repo.example.com/rhel9/
baseurl=file:///mnt/iso/BaseOS            <- THREE slashes: file:// + /mnt
```

**`file:///` needs three slashes**: two from the scheme and one starting the absolute path. `file://mnt/iso` is wrong and produces a confusing error.

Creating a repo file by hand:

```bash
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

**Use a quoted heredoc (`<<'EOF'`)** so that `$releasever` and `$basearch`, if present, are written literally rather than expanded by your shell. This is a real and confusing failure mode.

### dnf config-manager

The tool-based alternative to hand-editing.

```bash
sudo dnf install -y dnf-plugins-core       # provides config-manager

sudo dnf config-manager --add-repo https://repo.example.com/rhel9/
sudo dnf config-manager --set-enabled repo-id
sudo dnf config-manager --set-disabled repo-id
dnf config-manager --dump                  # all settings
```

On newer dnf the syntax is `dnf config-manager addrepo --from-repofile=...`. If `--add-repo` complains, hand-writing the `.repo` file is always available and always works. **When in doubt, write the file.**

Temporarily using or ignoring a repo without changing config:

```bash
sudo dnf --disablerepo=* --enablerepo=local-baseos install httpd
sudo dnf --enablerepo=epel install something
sudo dnf --nogpgcheck install ./unsigned.rpm
```

### GPG keys

```bash
ls /etc/pki/rpm-gpg/
rpm -qa gpg-pubkey*                                     # imported keys
rpm -qi gpg-pubkey-fd431d51-4ae0493b                    # details of one
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
sudo rpm --import https://host/RPM-GPG-KEY
```

If a repository has no key available and the task does not require signature checking, `gpgcheck=0` is acceptable. Prefer `gpgcheck=1` with a correct key when one exists.

The key filename differs by distribution:

```bash
ls /etc/pki/rpm-gpg/
# RHEL:      RPM-GPG-KEY-redhat-release
# Rocky:     RPM-GPG-KEY-Rocky-9
# AlmaLinux: RPM-GPG-KEY-AlmaLinux-9
```

### Mounting an ISO as a repository

A very common exam and lab pattern.

```bash
sudo mkdir -p /mnt/iso
sudo mount /dev/sr0 /mnt/iso                # or mount -o loop file.iso /mnt/iso
ls /mnt/iso                                 # expect BaseOS and AppStream

# Make the mount persistent
echo '/dev/sr0  /mnt/iso  iso9660  ro,nofail  0 0' | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo mount -a
```

**Use `nofail`.** Without it, booting without the ISO attached drops you into emergency mode. See `16-boot-interrupt-root-recovery.md`.

### Subscription management (RHEL only)

Not present on Rocky or AlmaLinux.

```bash
sudo subscription-manager register --username=user --password=pass
sudo subscription-manager attach --auto
sudo subscription-manager repos --list
sudo subscription-manager repos --enable=rhel-9-for-x86_64-baseos-rpms
sudo subscription-manager status
sudo subscription-manager unregister
```

On the exam you will normally be given a local or classroom repository rather than a subscription, so know this exists but expect to configure a `.repo` file.

## Tasks

**Task 1.** List all currently enabled repositories.

**Task 2.** Configure a repository named `local-baseos` pointing at `file:///mnt/iso/BaseOS`, with GPG checking enabled, and confirm dnf can use it. Mount the installation ISO persistently first.

**Task 3.** Determine which package provides the `semanage` command, then install it.

**Task 4.** Install the `httpd` package, confirm the version installed, and list its configuration files.

**Task 5.** Determine which package owns `/etc/chrony.conf`.

**Task 6.** List every file the `chrony` package installed.

**Task 7.** Search for packages related to `nfs`, then show detailed information about `nfs-utils` without installing it.

**Task 8.** Install a package group that provides development tools.

**Task 9.** Show the ten most recently installed packages on this system.

**Task 10.** Determine whether any file belonging to the `httpd` package has been modified since installation.

**Task 11.** Show the dnf transaction history and reverse the most recent transaction.

**Task 12.** Install a package from a local `.rpm` file, resolving its dependencies from configured repositories.

**Task 13.** Temporarily disable all repositories except `local-baseos` for a single install command.

**Task 14.** Update all packages on the system, then check whether any updates remain.

**Task 15.** Remove the `httpd` package along with any dependencies that are no longer needed.

**Task 16.** A repository you added returns "Failed to download metadata". List the things you would check, in order.

**Task 17.** Determine the exact version and release of the running kernel package, and list all installed kernels.

---

## Solutions

**Task 1.**

```bash
dnf repolist
```

```text
repo id                  repo name
appstream                Rocky Linux 9 - AppStream
baseos                   Rocky Linux 9 - BaseOS
```

Including disabled ones:

```bash
dnf repolist --all
dnf repoinfo baseos            # full details of one
```

**Task 2.**

Mount the ISO persistently:

```bash
sudo mkdir -p /mnt/iso
sudo mount /dev/sr0 /mnt/iso
ls /mnt/iso                      # confirm BaseOS and AppStream exist

echo '/dev/sr0  /mnt/iso  iso9660  ro,nofail  0 0' | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo mount -a
findmnt /mnt/iso
```

Find the correct GPG key name for your distribution:

```bash
ls /etc/pki/rpm-gpg/
```

Write the repo file:

```bash
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
```

Adjust the `gpgkey` filename to match what `ls /etc/pki/rpm-gpg/` showed. Then:

```bash
sudo dnf clean all
sudo dnf repolist
sudo dnf list available --repo=local-baseos | head
```

Five things to get right:

1. **`file:///` with three slashes.** Two for the scheme, one for the absolute path.
2. **`name=` is mandatory.** Omitting it causes a parse error.
3. **The `[repo-id]` must be unique** and contain no spaces.
4. **`dnf clean all`** after changing repository configuration, or stale metadata is used.
5. **`nofail`** on the ISO mount, so a missing disc cannot prevent booting.

If the GPG key is unavailable, `gpgcheck=0` works but is a weaker answer. Prefer a correct key.

**Task 3.**

```bash
dnf provides */semanage
```

```text
policycoreutils-python-utils-3.6-2.el9.x86_64 : SELinux policy core python utilities
Repo        : appstream
Matched from:
Filename    : /usr/sbin/semanage
```

```bash
sudo dnf install -y policycoreutils-python-utils
command -v semanage
```

**Memorise this package name.** `semanage` is required for every SELinux port-label and fcontext task in `27-selinux.md`, and it is not installed on a minimal system. A task that says "label port 8404 for httpd" is impossible without it, and `dnf provides` is how you would recover if you forgot the name.

`dnf provides` is the general answer to "I need command X, which package supplies it".

**Task 4.**

```bash
sudo dnf install -y httpd
rpm -q httpd
```

```text
httpd-2.4.57-11.el9.x86_64
```

```bash
rpm -qc httpd
```

```text
/etc/httpd/conf.d/autoindex.conf
/etc/httpd/conf.d/userdir.conf
/etc/httpd/conf.d/welcome.conf
/etc/httpd/conf/httpd.conf
/etc/httpd/conf/magic
/etc/logrotate.d/httpd
...
```

**`rpm -qc` is the fast way to find which files you are meant to edit** for a service you have just installed. Compare with `rpm -ql httpd | wc -l`, which lists hundreds of files.

**Task 5.**

```bash
rpm -qf /etc/chrony.conf
```

```text
chrony-4.5-1.el9.x86_64
```

`dnf provides` also works and additionally covers packages that are not installed:

```bash
dnf provides /etc/chrony.conf
```

Use `rpm -qf` for a file that exists locally, `dnf provides` when you need to find a package you have not installed.

**Task 6.**

```bash
rpm -ql chrony
```

For a package that is **not** installed:

```bash
dnf repoquery -l chrony
```

That queries the repository metadata instead of the local database, which is genuinely useful when deciding whether to install something.

**Task 7.**

```bash
dnf search nfs
dnf info nfs-utils
```

`dnf info` works whether or not the package is installed, showing version, size, repository, and description. To search descriptions as well as names:

```bash
dnf search all "network file system"
```

**Task 8.**

```bash
dnf group list
sudo dnf group install -y "Development Tools"
```

Or the shorthand:

```bash
sudo dnf install -y @development
```

Verify:

```bash
dnf group list --installed
dnf group info "Development Tools"
rpm -q gcc make
```

Quote group names containing spaces. `@groupname` and `group install "Group Name"` are equivalent.

**Task 9.**

```bash
rpm -qa --last | head -10
```

```text
httpd-2.4.57-11.el9.x86_64                    Tue 18 Aug 2026 20:15:33 EAT
policycoreutils-python-utils-3.6-2.el9.x86_64 Tue 18 Aug 2026 20:10:12 EAT
...
```

Also, from dnf's perspective:

```bash
dnf history | head
```

`rpm -qa --last` is package-centric; `dnf history` is transaction-centric. For "what did I just install", `dnf history` is often more useful because it groups a package with its dependencies.

**Task 10.**

```bash
rpm -V httpd
```

No output means nothing has changed. If you have edited the config:

```bash
sudo sed -i 's/^#ServerName.*/ServerName localhost/' /etc/httpd/conf/httpd.conf
rpm -V httpd
```

```text
S.5....T.  c /etc/httpd/conf/httpd.conf
```

`S` size differs, `5` checksum differs, `T` timestamp differs, and `c` marks it as a config file. **A `5` on a config file is expected after you edit it. A `5` on a binary in `/usr/bin` would be a serious finding.**

To check everything, slowly:

```bash
sudo rpm -Va | head -20
```

**Task 11.**

```bash
dnf history
```

```text
ID | Command line          | Date and time    | Action(s) | Altered
-------------------------------------------------------------------
 8 | install -y httpd      | 2026-08-18 20:15 | Install   |    5
 7 | install -y chrony     | 2026-08-18 20:10 | Install   |    1
```

```bash
dnf history info 8
sudo dnf history undo 8
rpm -q httpd            # not installed
```

**`dnf history undo` reverses a transaction**, removing what was installed and reinstalling what was removed. This is the fastest way to recover from a mistaken install. Related:

```bash
sudo dnf history redo 8         # do it again
sudo dnf history rollback 7     # return to the state after transaction 7
```

**Task 12.**

```bash
# obtain a package file, e.g. by downloading without installing
sudo dnf install -y 'dnf-command(download)'
dnf download httpd
ls *.rpm

sudo dnf install -y ./httpd-*.rpm
```

**Use `dnf install ./file.rpm`, not `rpm -ivh file.rpm`.** dnf resolves the package's dependencies from your configured repositories; `rpm` fails with a dependency error and leaves you to hunt them down manually.

The `./` prefix matters — without it, dnf treats the argument as a package name to look up in the repositories.

If the package is unsigned:

```bash
sudo dnf install -y --nogpgcheck ./package.rpm
```

**Task 13.**

```bash
sudo dnf --disablerepo="*" --enablerepo="local-baseos" install -y httpd
```

This affects only this command; no configuration is changed. Useful when you must prove a specific repository works, or when a remote repository is slow or unreachable.

To verify which repo a package came from:

```bash
dnf info httpd | grep -i 'repo\|from'
```

**Task 14.**

```bash
sudo dnf check-update            # what is available; exit code 100 if updates exist
sudo dnf update -y
sudo dnf check-update            # exit code 0 and no output when nothing remains
echo $?
```

`dnf check-update` exits **100** when updates are available and **0** when none are, which is useful in scripts.

If a kernel was updated, a reboot is needed for it to take effect:

```bash
needs-restarting -r 2>/dev/null || sudo dnf install -y dnf-utils
sudo needs-restarting -r
```

`needs-restarting -r` reports whether a full reboot is required.

**Task 15.**

```bash
sudo dnf remove -y httpd
sudo dnf autoremove -y
rpm -q httpd
```

`dnf remove` takes the named package and anything that depends on it. `dnf autoremove` then drops packages that were pulled in only as dependencies and are now unused.

Check what `autoremove` intends to do before agreeing:

```bash
sudo dnf autoremove          # review the list, then confirm
```

Be careful: on a system where packages were installed in an unusual order, `autoremove` can propose removing something you want. Read the list.

**Task 16.**

The checks, in order of likelihood:

```bash
# 1. Is the baseurl exactly right, including the file:/// slashes?
cat /etc/yum.repos.d/local.repo

# 2. Does the path actually exist and contain repository metadata?
ls /mnt/iso/BaseOS
ls /mnt/iso/BaseOS/repodata/repomd.xml         # THIS FILE MUST EXIST

# 3. Is the ISO still mounted?
findmnt /mnt/iso
sudo mount -a

# 4. Is the metadata cache stale?
sudo dnf clean all
sudo dnf repolist

# 5. Is the GPG key path correct?
ls /etc/pki/rpm-gpg/
grep gpgkey /etc/yum.repos.d/local.repo

# 6. For a remote repo: network, DNS, and proxy
ping -c1 repo.example.com
curl -sI https://repo.example.com/BaseOS/repodata/repomd.xml | head -1
getent hosts repo.example.com

# 7. Read the actual error rather than guessing
sudo dnf repolist --verbose 2>&1 | tail -20
```

**The most common causes, in order:**

1. **`baseurl` points one directory too high or too low.** `repodata/repomd.xml` must exist directly under the `baseurl` path. That single check resolves most cases.
2. **`file://` with two slashes instead of three.**
3. **The ISO is not mounted**, often after a reboot when the `fstab` entry was missing.
4. **Stale cache** — fixed by `dnf clean all`.
5. **A wrong `gpgkey` filename** for the distribution in use.

The `repodata/repomd.xml` test is the decisive one:

```bash
ls /mnt/iso/BaseOS/repodata/repomd.xml && echo "baseurl is correct"
```

**Task 17.**

```bash
uname -r
rpm -q kernel
rpm -qa kernel*
```

```text
$ uname -r
5.14.0-427.el9.x86_64
$ rpm -q kernel
kernel-5.14.0-427.el9.x86_64
kernel-5.14.0-362.el9.x86_64
```

`uname -r` is what is **running**; `rpm -q kernel` is what is **installed**, and there can be several. They differ immediately after a kernel update, before you reboot. See `17-bootloader.md` for choosing which one boots.

---

## Verify

```bash
dnf repolist
cat /etc/yum.repos.d/local.repo
findmnt /mnt/iso
ls /mnt/iso/BaseOS/repodata/repomd.xml
rpm -q httpd chrony policycoreutils-python-utils
command -v semanage
dnf history | head -5
grep -vE '^\s*#|^\s*$' /etc/fstab | grep iso
```

## Persistence Check

| Change | Persistent artifact | Also required |
| --- | --- | --- |
| Installed packages | The RPM database | Nothing |
| Repository definition | **`/etc/yum.repos.d/*.repo`** | `dnf clean all` after editing |
| **ISO mount for a `file://` repo** | **An `/etc/fstab` entry** | `mount -a` |
| GPG key import | The RPM database | Nothing |
| `dnf config-manager --set-enabled` | The `.repo` file | Nothing |

**The trap in this file is the ISO mount.** A `file:///mnt/iso/BaseOS` repository works perfectly until you reboot, at which point the ISO is not mounted, the repository fails, and any task that depends on installing a package fails with it.

```bash
# The mount MUST be in fstab
echo '/dev/sr0  /mnt/iso  iso9660  ro,nofail  0 0' | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo mount -a
```

And **`nofail` is important**: without it, a VM booted without the ISO attached drops into emergency mode.

Post-reboot verification:

```bash
findmnt /mnt/iso              # the ISO is mounted
dnf repolist                  # the repo is usable
sudo dnf install -y tree      # prove it end to end
rpm -q tree
```

That last install is the real test. A repository that lists correctly but cannot install anything is not done.

## Exam Tips

- **Do the repository task first.** Everything else that installs software depends on it.
- **Install with `dnf`, query with `rpm`.** `dnf install ./file.rpm` resolves dependencies; `rpm -ivh` does not.
- **`dnf provides */command`** finds which package supplies a command. The single most useful recovery command here.
- **`semanage` comes from `policycoreutils-python-utils`.** Memorise it; SELinux tasks are impossible without it.
- **`file:///` needs three slashes.** `file:///mnt/iso/BaseOS`.
- **`repodata/repomd.xml` must exist directly under the `baseurl`.** This one check diagnoses most broken repositories.
- **`name=` and `baseurl=` are mandatory** in a `.repo` file, and the `[repo-id]` must be unique with no spaces.
- **`dnf clean all` after changing repository configuration.**
- **Use a quoted heredoc (`<<'EOF'`)** when writing `.repo` files, so `$releasever` is not expanded by your shell.
- **An ISO-backed repo needs an `/etc/fstab` entry with `nofail`**, or it breaks after a reboot.
- **`rpm -qa`** all, **`-qf FILE`** which package owns it, **`-ql`** all files, **`-qc`** config files, **`-qd`** docs, **`-qi`** info, **`-V`** verify.
- **`rpm -qc PKG`** tells you which files to edit for a newly installed service.
- **`rpm -V`**: `5` means the contents changed. Expected on config files, alarming on binaries.
- **`dnf history`** and **`dnf history undo N`** reverse a mistaken transaction.
- **`--disablerepo="*" --enablerepo="X"`** to use one repository for a single command.
- **`dnf group install "Name"`** or `dnf install @name` for groups.
- **`dnf check-update` exits 100** when updates exist, 0 when none do.
- `dnf repoquery -l pkg` lists files in a package **without installing it**.
- The GPG key filename differs by distribution. Check `ls /etc/pki/rpm-gpg/` rather than assuming.
- **Verify a repository by actually installing something from it**, not just by `dnf repolist`.
