# 23. Flatpak

**Objective:** Configure Flatpak repositories and manage Flatpak packages.

**This is new in the RHEL 10 objectives** and is absent from every RHEL 9 study guide. If your exam is the RHEL 10 version, this is a domain your competitors will not have prepared for. It is also a short topic — perhaps twenty minutes of learning.

## Concept Refresher

### What Flatpak is, and why RHEL cares

Flatpak distributes **sandboxed desktop applications** independently of the base operating system. An application ships with its own runtime and libraries, so it does not depend on the RPM versions RHEL provides.

| | **RPM / dnf** | **Flatpak** |
| --- | --- | --- |
| Scope | The whole OS: kernel, services, libraries | **Desktop applications only** |
| Dependencies | Shared, resolved system-wide | **Bundled with the app, per-runtime** |
| Isolation | None | **Sandboxed** |
| Installed for | The system | The system **or a single user** |
| Requires root | Yes | **No, for `--user` installs** |
| Update mechanism | `dnf update` | `flatpak update` |
| Repository term | repository | **remote** |
| Package naming | `httpd` | **`org.gnome.Calculator`** (reverse DNS) |

Two vocabulary points that matter for reading tasks: a Flatpak repository is called a **remote**, and applications are named in **reverse-DNS form** like `org.gnome.Calculator`.

### Installing Flatpak itself

```bash
sudo dnf install -y flatpak
flatpak --version
```

### Managing remotes

```bash
flatpak remotes                                   # list configured remotes
flatpak remotes -d                                # with details
flatpak remote-list                               # a synonym

# Add a remote
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Add for the current user only, no root needed
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Add from a local file
sudo flatpak remote-add myrepo /path/to/myrepo.flatpakrepo

# Inspect, modify, remove
flatpak remote-info flathub org.gnome.Calculator
sudo flatpak remote-modify --disable flathub
sudo flatpak remote-modify --enable flathub
sudo flatpak remote-delete flathub
sudo flatpak remote-ls flathub | head            # what the remote offers
```

**`--if-not-exists` makes the command idempotent**, so re-running it is safe. Use it always.

The canonical remote is **Flathub**, at `https://dl.flathub.org/repo/flathub.flatpakrepo`. The older `https://flathub.org/repo/flathub.flatpakrepo` also works and redirects.

Red Hat also ships its own remote on systems with a subscription:

```bash
flatpak remotes
# rhel  Red Hat Enterprise Linux  system
```

### System versus user installations

This distinction is the thing most likely to catch you out.

```bash
# System-wide: needs root, available to every user
sudo flatpak install flathub org.gnome.Calculator

# Per-user: no root, only for you, stored in ~/.local/share/flatpak
flatpak install --user flathub org.gnome.Calculator
```

| | System (`--system`, the default with sudo) | User (`--user`) |
| --- | --- | --- |
| Needs root | **Yes** | **No** |
| Location | `/var/lib/flatpak/` | `~/.local/share/flatpak/` |
| Available to | All users | Only that user |
| Listed by | `flatpak list --system` | `flatpak list --user` |

**A remote added with `--user` cannot be used for a system install, and vice versa.** If `flatpak install` reports the remote is not found, you almost certainly added it in the other scope. Check both:

```bash
flatpak remotes --system
flatpak remotes --user
```

### Installing and managing applications

```bash
flatpak search calculator                         # search remotes
flatpak search gimp

sudo flatpak install flathub org.gnome.Calculator
sudo flatpak install -y flathub org.gnome.Calculator
flatpak install --user -y flathub org.gnome.Calculator
sudo flatpak install flathub org.gnome.Calculator//stable    # a specific branch

flatpak list                                      # everything installed
flatpak list --app                                # applications only, not runtimes
flatpak list --runtime                            # runtimes only
flatpak list --columns=application,version,branch,installation

flatpak info org.gnome.Calculator                 # details
flatpak info -o org.gnome.Calculator              # the origin remote

flatpak run org.gnome.Calculator                  # launch it
flatpak run --command=sh org.gnome.Calculator      # a shell inside the sandbox

sudo flatpak update                               # update everything
sudo flatpak update org.gnome.Calculator          # one app
flatpak update --user

sudo flatpak uninstall org.gnome.Calculator
sudo flatpak uninstall --delete-data org.gnome.Calculator   # also remove its data
sudo flatpak uninstall --unused                   # remove orphaned runtimes
```

**`flatpak list --app` is usually what you want.** Plain `flatpak list` includes every runtime and extension, which is a long and confusing list.

### Runtimes

Applications depend on a shared runtime, which Flatpak installs automatically.

```bash
flatpak list --runtime
sudo flatpak install flathub org.gnome.Platform//45
sudo flatpak uninstall --unused                   # clean up unreferenced runtimes
```

`uninstall --unused` is the Flatpak equivalent of `dnf autoremove`.

### Permissions and sandboxing

Occasionally relevant, and it shows you understand what Flatpak is for.

```bash
flatpak info --show-permissions org.gnome.Calculator
flatpak override --user --filesystem=home org.gnome.Calculator
sudo flatpak override --filesystem=/data org.gnome.Calculator
flatpak override --show org.gnome.Calculator
sudo flatpak override --reset org.gnome.Calculator
```

An application can only see what its manifest and overrides permit. This is the difference from an RPM, where an installed binary has whatever access the invoking user has.

### Where things live

```text
/var/lib/flatpak/                    system installations
      ├── app/
      ├── runtime/
      └── repo/
~/.local/share/flatpak/              user installations
/etc/flatpak/remotes.d/*.flatpakrepo system remote definitions
~/.local/share/flatpak/repo/config   user remote configuration
/var/tmp/flatpak-cache-*             download cache
```

```bash
ls /var/lib/flatpak/app/ 2>/dev/null
ls ~/.local/share/flatpak/app/ 2>/dev/null
ls /etc/flatpak/remotes.d/ 2>/dev/null
```

Knowing that system remotes appear in `/etc/flatpak/remotes.d/` lets you verify a remote persistently, which matters for the reboot check.

### A caveat about the exam environment

**The exam provides no internet access.** So a task cannot realistically require you to install from Flathub over the network. What a task *can* require:

- Adding a remote from a **local** `.flatpakrepo` file or a classroom HTTP server.
- Installing from a locally provided remote.
- Listing, updating, or removing already-installed Flatpaks.
- Configuring a remote so it is enabled and present after a reboot.

So practise the **command syntax** and the **system versus user distinction**, and do not assume you will have Flathub. Set up a local remote in your lab to practise against, as in Task 9 below.

## Tasks

**Task 1.** Install Flatpak and confirm its version.

**Task 2.** List all currently configured Flatpak remotes, distinguishing system remotes from user remotes.

**Task 3.** Add the Flathub remote system-wide in a way that is safe to re-run.

**Task 4.** Add the Flathub remote for your user only, without root, and show that the two scopes are separate.

**Task 5.** Search the configured remotes for a calculator application.

**Task 6.** Install `org.gnome.Calculator` system-wide and verify where it was installed.

**Task 7.** List only the installed Flatpak applications, excluding runtimes.

**Task 8.** Show the origin remote and full details of an installed Flatpak application.

**Task 9.** Create a local Flatpak remote from a directory on this machine and add it, so you can practise without internet access.

**Task 10.** Update all system Flatpak applications, then update only a single named application.

**Task 11.** Temporarily disable a remote without deleting it, then re-enable it.

**Task 12.** Uninstall a Flatpak application including its user data, then remove any runtimes that are no longer needed.

**Task 13.** Determine which files on disk define the system Flatpak remotes, and confirm your remote will survive a reboot.

**Task 14.** Grant an installed Flatpak application access to `/data` on the host filesystem.

**Task 15.** Explain the practical difference between installing a package with `dnf` and installing an application with `flatpak`, and when each is appropriate.

---

## Solutions

**Task 1.**

```bash
sudo dnf install -y flatpak
flatpak --version
```

```text
Flatpak 1.14.10
```

Verify the package:

```bash
rpm -q flatpak
```

**Task 2.**

```bash
flatpak remotes
```

```text
Name    Options
rhel    system
```

To separate the scopes explicitly:

```bash
flatpak remotes --system
flatpak remotes --user
flatpak remotes -d              # with URLs and details
```

The `Options` column shows `system` or `user`. **A freshly installed system may have no remotes at all**, which is normal.

**Task 3.**

```bash
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remotes
```

```text
Name     Options
flathub  system
rhel     system
```

**`--if-not-exists` makes it idempotent.** Without it, re-running the command errors with "Remote flathub already exists". Use it always — it costs nothing and makes the command safe to repeat.

Confirm the URL:

```bash
flatpak remotes -d | grep -A2 flathub
```

Without internet access this command will fail to fetch the repo definition. In that case use Task 9's local remote instead.

**Task 4.**

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

No `sudo`. Now compare the scopes:

```bash
flatpak remotes --system
flatpak remotes --user
flatpak remotes           # both, with the Options column distinguishing them
```

**The scopes are completely independent.** A remote added with `--user` is invisible to `sudo flatpak install`, and a system remote is used by default when you install with sudo. If `flatpak install` says the remote does not exist, you added it in the other scope. That is the single most common Flatpak confusion.

Locations differ too:

```bash
ls ~/.local/share/flatpak/          # user
sudo ls /var/lib/flatpak/           # system
```

**Task 5.**

```bash
flatpak search calculator
```

```text
Name         Description              Application ID          Version  Branch  Remotes
Calculator   Perform arithmetic...    org.gnome.Calculator    45.0     stable  flathub
```

**The Application ID is what you install**, not the friendly name:

```bash
sudo flatpak install flathub org.gnome.Calculator      # correct
sudo flatpak install flathub Calculator                # will not work
```

The reverse-DNS naming (`org.gnome.Calculator`, `org.mozilla.firefox`, `com.spotify.Client`) is the Flatpak convention.

To see everything a remote offers:

```bash
flatpak remote-ls flathub --app | head -20
```

**Task 6.**

```bash
sudo flatpak install -y flathub org.gnome.Calculator
```

Verify:

```bash
flatpak list --app
flatpak info org.gnome.Calculator
```

```text
Calculator - Perform arithmetic, scientific or financial calculations

          ID: org.gnome.Calculator
         Ref: app/org.gnome.Calculator/x86_64/stable
        Arch: x86_64
      Branch: stable
     Version: 45.0
     Origin: flathub
Installation: system
```

**`Installation: system`** confirms the scope. Also visible on disk:

```bash
sudo ls /var/lib/flatpak/app/org.gnome.Calculator/
```

Note that the first install also pulls in a large runtime (`org.gnome.Platform`), which is why it takes a while and consumes several hundred megabytes.

Run it, if you have a graphical session:

```bash
flatpak run org.gnome.Calculator
```

**Task 7.**

```bash
flatpak list --app
```

Compare with the unfiltered version:

```bash
flatpak list | wc -l
flatpak list --app | wc -l
```

Plain `flatpak list` includes runtimes, locales, and extensions — often twenty entries for one application. **`--app` is almost always what you want.**

A tidier view:

```bash
flatpak list --app --columns=application,version,branch,installation
```

**Task 8.**

```bash
flatpak info org.gnome.Calculator
flatpak info -o org.gnome.Calculator          # just the origin remote
```

```text
$ flatpak info -o org.gnome.Calculator
flathub
```

`-o` prints only the origin, which is useful in scripts. Also:

```bash
flatpak info --show-permissions org.gnome.Calculator
flatpak info --show-runtime org.gnome.Calculator
flatpak info --show-location org.gnome.Calculator
```

**Task 9.**

This is how you practise without internet access, and it is the shape a real exam task would take.

```bash
sudo dnf install -y flatpak-builder ostree
```

Create a bare OSTree repository to act as the remote:

```bash
sudo mkdir -p /srv/flatpak-repo
sudo ostree --repo=/srv/flatpak-repo init --mode=archive-z2
sudo ostree --repo=/srv/flatpak-repo summary -u
```

Add it as a remote using a `file://` URL, with GPG verification disabled since we have not signed it:

```bash
sudo flatpak remote-add --if-not-exists --no-gpg-verify \
  localrepo file:///srv/flatpak-repo

flatpak remotes -d | grep -A3 localrepo
sudo flatpak remote-ls localrepo            # empty, but the remote works
```

Verify it persisted to disk:

```bash
sudo ls /etc/flatpak/remotes.d/
sudo cat /etc/flatpak/remotes.d/localrepo.flatpakrepo 2>/dev/null
```

The repository is empty, so there is nothing to install, but **the remote-add, remote-ls, remote-modify, remote-delete, and persistence workflow is all exercisable** — which is what the objective actually asks for. Note the same `file:///` three-slash rule as in `22-software-management-dnf.md`.

Clean up when done:

```bash
sudo flatpak remote-delete localrepo
sudo rm -rf /srv/flatpak-repo
```

**Task 10.**

```bash
sudo flatpak update -y                              # everything, system scope
sudo flatpak update -y org.gnome.Calculator         # one application
flatpak update --user -y                            # user scope
```

Check for updates without applying them:

```bash
flatpak remote-ls --updates
```

**Note that `sudo flatpak update` only updates system installations.** User installations need `flatpak update --user`, without sudo. Doing both is two commands:

```bash
sudo flatpak update -y
flatpak update --user -y
```

**Task 11.**

```bash
sudo flatpak remote-modify --disable flathub
flatpak remotes -d | grep -A5 flathub
```

A disabled remote is still configured but is not used for installs or updates. Prove it:

```bash
sudo flatpak install flathub org.gnome.Calculator
# error: Remote "flathub" is disabled
```

Re-enable:

```bash
sudo flatpak remote-modify --enable flathub
flatpak remotes
```

**`remote-modify --disable` versus `remote-delete`** is the same distinction as `systemctl disable` versus removing a unit: disabling is reversible and keeps the configuration, deleting removes it. A task saying "temporarily disable" means `--disable`.

Other `remote-modify` options:

```bash
sudo flatpak remote-modify --url=https://new.url/repo flathub
sudo flatpak remote-modify --no-enumerate flathub      # hide from searches
sudo flatpak remote-modify --prio=10 flathub           # priority
```

**Task 12.**

```bash
sudo flatpak uninstall -y --delete-data org.gnome.Calculator
sudo flatpak uninstall -y --unused
flatpak list --app
```

**`--delete-data` also removes the application's data** in `~/.var/app/<app-id>/`. Without it, configuration and saved files remain, which is sometimes what you want and sometimes not. A task saying "remove the application and all its data" means `--delete-data`.

**`--unused` removes orphaned runtimes**, the Flatpak equivalent of `dnf autoremove`. Runtimes are large, so this reclaims real space:

```bash
flatpak list --runtime            # before
sudo flatpak uninstall -y --unused
flatpak list --runtime            # after
du -sh /var/lib/flatpak/
```

**Task 13.**

```bash
sudo ls -l /etc/flatpak/remotes.d/
sudo cat /etc/flatpak/remotes.d/*.flatpakrepo 2>/dev/null
```

Also stored in the OSTree repository config:

```bash
sudo cat /var/lib/flatpak/repo/config
```

```text
[core]
repo_version=1
mode=bare-user-only

[remote "flathub"]
url=https://dl.flathub.org/repo/
xa.title=Flathub
gpg-verify=true
```

For user remotes:

```bash
cat ~/.local/share/flatpak/repo/config
```

Verify persistence properly:

```bash
flatpak remotes
sudo reboot
```

After the reboot:

```bash
flatpak remotes                   # the remote is still listed
flatpak remotes --user            # user remotes too
flatpak list --app                # applications still installed
```

**Flatpak remotes and installations persist automatically** — they are files and an OSTree repository on disk, and there is no service to enable. That makes this an easier objective than most on this exam. The only persistence trap is scope: a `--user` remote belongs to one user's home directory, so it is invisible to root and to other users.

**Task 14.**

```bash
sudo mkdir -p /data
sudo flatpak override --filesystem=/data org.gnome.Calculator
flatpak override --show org.gnome.Calculator
```

```text
[Context]
filesystems=/data;
```

For the current user only:

```bash
flatpak override --user --filesystem=/data org.gnome.Calculator
```

Common filesystem values:

```bash
sudo flatpak override --filesystem=home org.gnome.Calculator      # the whole home dir
sudo flatpak override --filesystem=host org.gnome.Calculator      # ALL of /  — avoid
sudo flatpak override --filesystem=/data:ro org.gnome.Calculator  # read-only
```

Reset:

```bash
sudo flatpak override --reset org.gnome.Calculator
flatpak override --show org.gnome.Calculator
```

Overrides live in `/var/lib/flatpak/overrides/` (system) or `~/.local/share/flatpak/overrides/` (user), so they persist.

**Task 15.**

| | `dnf` / RPM | `flatpak` |
| --- | --- | --- |
| **Use for** | The operating system: kernel, services, libraries, CLI tools | **Desktop applications** |
| Dependency model | Shared system libraries, resolved globally | Bundled runtime per application |
| Version flexibility | One version of a library system-wide | **Several app versions can coexist** |
| Isolation | None; a binary has the invoking user's access | **Sandboxed**, with explicit permissions |
| Root required | Yes | **No, with `--user`** |
| Suitable for a server | **Yes** | Rarely — it is a desktop technology |
| RHCSA relevance | Every service task | The new "manage Flatpak packages" objective |

**Everything in the rest of this folder is RPM.** `httpd`, `chronyd`, `nfs-utils`, `podman`, `firewalld`, and `policycoreutils-python-utils` are all installed with `dnf`. Flatpak exists for graphical applications whose upstream release cadence is faster than RHEL's, or which need a library version RHEL does not ship.

So on the exam: **a task about a service means `dnf`; a task that explicitly says Flatpak means `flatpak`.** Do not reach for Flatpak to install a server component, and do not try to `dnf install org.gnome.Calculator`.

---

## Verify

```bash
rpm -q flatpak
flatpak --version
flatpak remotes
flatpak remotes --system
flatpak remotes --user
flatpak list --app
sudo ls /etc/flatpak/remotes.d/ 2>/dev/null
sudo cat /var/lib/flatpak/repo/config 2>/dev/null | grep -A3 remote
```

## Persistence Check

| Change | Persistent artifact | Also required |
| --- | --- | --- |
| Flatpak installed | The RPM database | Nothing |
| System remote | **`/etc/flatpak/remotes.d/*`** and `/var/lib/flatpak/repo/config` | Nothing |
| User remote | `~/.local/share/flatpak/repo/config` | Nothing |
| System application | `/var/lib/flatpak/app/` | Nothing |
| User application | `~/.local/share/flatpak/app/` | Nothing |
| Permission override | `/var/lib/flatpak/overrides/` | Nothing |

**Flatpak has no daemon to enable**, which makes this the least persistence-hostile objective on the exam. Everything is a file on disk.

The one real trap is **scope**. A remote or application installed with `--user` lives in one user's home directory:

- It is invisible to `sudo flatpak list`.
- It is invisible to every other user.
- If a grader checks system-wide state, a `--user` install scores nothing.

So unless a task explicitly says "for user alice", **install system-wide with sudo**.

Post-reboot verification:

```bash
flatpak remotes                 # remote still present
flatpak list --app              # application still installed
flatpak info <app-id>           # check the Installation: line says system
```

## Exam Tips

- **This is new in RHEL 10 and absent from RHEL 9 guides.** If your exam is the RHEL 10 version, learning it is cheap differentiation.
- **A Flatpak repository is called a "remote".** Applications use **reverse-DNS IDs** like `org.gnome.Calculator`.
- **`flatpak remote-add --if-not-exists <name> <url>`.** Always use `--if-not-exists` so the command is safe to repeat.
- **Flathub URL: `https://dl.flathub.org/repo/flathub.flatpakrepo`.**
- **System versus user scope is the main trap.** `sudo flatpak install` uses system scope; `flatpak install --user` uses your home directory. **The two are completely separate** — a remote added in one is invisible to the other.
- **Unless a task names a user, install system-wide with sudo.**
- **`flatpak list --app`** excludes runtimes and is what you usually want.
- **`flatpak info <id>`** shows the origin and the `Installation:` scope. `flatpak info -o` prints just the origin.
- **`remote-modify --disable` / `--enable`** to disable reversibly; **`remote-delete`** to remove.
- **`flatpak uninstall --delete-data`** also removes application data. **`--unused`** removes orphaned runtimes, like `dnf autoremove`.
- **`sudo flatpak update` only updates system installs.** User installs need `flatpak update --user`.
- **Search by Application ID, install by Application ID**, not by the friendly name.
- **`file:///` needs three slashes** for a local remote, same rule as in `22-software-management-dnf.md`.
- **Everything persists automatically.** No service to enable, no `--permanent` flag.
- **The exam has no internet**, so expect a local or classroom remote. Practise the command syntax against a local `file://` remote.
- **Flatpak is for desktop applications.** Services like `httpd` and `chronyd` are always `dnf`.
