# vim: The Twenty Keystrokes You Need

**"Create and edit text files" is an objective, and vi is the only editor guaranteed to be present.** `nano` may not be installed and there is no internet to install it from.

You do not need to be good at vim. You need to open a file, change a line, save, and get out without corrupting anything. This page is that, and nothing more.

---

## The one thing to understand

vim has modes. **Almost every vim disaster is typing in the wrong mode.**

```text
   ┌──────────────────┐
   │   COMMAND MODE   │  ← where vim starts. Keys are COMMANDS
   │   (Normal)       │
   └──────────────────┘
      │            ▲
   i a o O         │ Esc
      ▼            │
   ┌──────────────────┐
   │   INSERT MODE    │  ← keys are TEXT
   └──────────────────┘

   ┌──────────────────┐
   │   COMMAND LINE   │  ← : then a command, then Enter
   │   :w :q :wq      │
   └──────────────────┘
      ▲
      │ :
   from COMMAND MODE
```

**When in doubt, press `Esc`.** It always returns you to command mode from anywhere, it is safe to press repeatedly, and it costs nothing.

**A useful habit: press `Esc` before every command you are about to type.** It removes the entire class of "I was still in insert mode" errors.

```bash
vim /etc/fstab
# Esc  :set nu     ← turn on line numbers; helps you find the line
```

---

## Entering insert mode

| Key | Starts inserting |
| --- | --- |
| **`i`** | **Before the cursor** |
| `a` | After the cursor |
| `I` | At the start of the line |
| `A` | **At the end of the line — useful for appending mount options** |
| **`o`** | **On a new line below** |
| `O` | On a new line above |

```text
--INSERT--
```

**That indicator at the bottom means you are in insert mode.** If it is absent, your keystrokes are commands.

**`Esc` leaves insert mode.**

---

## Saving and quitting

| Command | Effect |
| --- | --- |
| **`:w`** | **Write** |
| **`:q`** | **Quit — refuses if there are unsaved changes** |
| **`:wq`** or **`ZZ`** | **Write and quit** |
| **`:q!`** | **QUIT, DISCARDING EVERYTHING** |
| `:w!` | Force write, for a read-only file you own |
| `:w /path` | Save a copy elsewhere |
| `:wq!` | Force both |

**`:q!` is your undo of last resort.** If you have made a mess of `/etc/fstab` and are not sure what you changed, **`:q!` and start again** is always safer than saving something you do not understand.

```text
E37: No write since last change (add ! to override)
```

**That means you tried `:q` with unsaved changes.** Either `:wq` to save or `:q!` to discard.

```text
E45: 'readonly' option is set (add ! to override)
```

**You opened a system file without `sudo`.** Do not fight it:

```text
:w !sudo tee %          ← saves via sudo without leaving vim; then :q!
```

**Simpler: `:q!`, then `sudo vim` the file again.** Under exam pressure, the simple route is the right one.

---

## Moving

| Key | Moves |
| --- | --- |
| Arrow keys | **They work. Use them** |
| `h` `j` `k` `l` | Left, down, up, right |
| `0` | Start of the line |
| `$` | **End of the line** |
| `w` / `b` | Forward / back one word |
| **`gg`** | **First line** |
| **`G`** | **Last line** |
| **`:42`** or `42G` | **Line 42** |
| `Ctrl-f` / `Ctrl-b` | Page down / up |
| `%` | The matching bracket |

**Arrow keys work in modern vim, including inside insert mode.** Nobody is grading your technique — use them.

```text
:set nu              turn on line numbers
:set nonu            turn them off
```

**Turn on line numbers whenever you are editing a configuration file.** Error messages reference line numbers and matching them up saves time.

---

## Editing

| Key | Effect |
| --- | --- |
| **`x`** | Delete the character under the cursor |
| **`dd`** | **Delete the whole line** |
| `3dd` | Delete three lines |
| `D` | Delete to the end of the line |
| **`yy`** | **Yank (copy) the line** |
| `3yy` | Yank three lines |
| **`p`** | **Paste below** |
| `P` | Paste above |
| **`u`** | **UNDO** |
| **`Ctrl-r`** | **Redo** |
| `r<char>` | Replace one character |
| `cw` | Change a word |
| `C` | Change to the end of the line |
| `J` | Join with the next line |
| `.` | **Repeat the last change** |

**`u` undoes one change at a time and you can press it repeatedly.** In vim (as opposed to classic vi) the undo history is effectively unlimited.

**`dd` then `p` moves a line. `yy` then `p` duplicates one** — which is the fastest way to add an `/etc/fstab` entry similar to an existing one:

```text
Esc  yy  p          duplicate the line
     A               append at the end, or navigate and edit the fields
     Esc  :wq
```

---

## Searching

| Command | Effect |
| --- | --- |
| **`/text`** | **Search forward** |
| `?text` | Search backward |
| **`n`** | **Next match** |
| `N` | Previous match |
| `*` | Search for the word under the cursor |
| `:noh` | Clear the highlighting |

```text
/PermitRootLogin      Enter      then n to cycle through matches
```

**Searching is much faster than scrolling through `/etc/ssh/sshd_config` or `/etc/httpd/conf/httpd.conf`.** Use it.

---

## Substitution

| Command | Effect |
| --- | --- |
| `:s/old/new/` | First occurrence on this line |
| `:s/old/new/g` | Every occurrence on this line |
| **`:%s/old/new/g`** | **Every occurrence in the file** |
| **`:%s/old/new/gc`** | **The same, confirming each one** |
| `:5,10s/old/new/g` | Lines 5 to 10 |
| `:%s/old/new/gi` | Case insensitive |

```text
:%s/enforcing/permissive/g
:%s/#Listen 80/Listen 8090/g
:%s/\/old\/path/\/new\/path/g       escape forward slashes...
:%s#/old/path#/new/path#g           ...or use a different delimiter
```

**`#` or `|` as the delimiter avoids escaping every slash in a path.** Any character works.

**`:%s/old/new/gc` prompts at each match** with `y`, `n`, `a` (all), `q` (quit). **Use it when you are not certain every match should change** — which is most of the time in a configuration file.

---

## Visual mode

| Key | Selects |
| --- | --- |
| `v` | Character by character |
| **`V`** | **Whole lines** |
| `Ctrl-v` | A rectangular block |

Then act on the selection: `d` delete, `y` yank, `>` indent, `<` unindent, `:` operate on just those lines.

```text
V  jjj  d           select four lines and delete them
V  jjj  y   p       select, copy, paste
Ctrl-v  jjj  I # Esc    comment out four lines at once
```

**`Ctrl-v`, select the first column of several lines, `I`, type `#`, `Esc` comments a block.** It looks like nothing happens until you press `Esc` — that is expected.

---

## Settings worth knowing

```text
:set nu              line numbers
:set nonu            off
:set list            show tabs and trailing whitespace
:set paste           STOP AUTO-INDENTING PASTED TEXT
:set nopaste         back to normal
:set ic              case-insensitive search
:set hlsearch        highlight matches
:noh                 clear the highlighting
:syntax on           syntax colouring
```

**`:set paste` before pasting multi-line text into vim.** Without it, auto-indent turns pasted text into a staircase, which is how a perfectly good configuration file becomes broken. Then `:set nopaste` afterwards.

**Persistently, in `~/.vimrc`:**

```bash
cat > ~/.vimrc <<'EOF'
set number
set expandtab
set tabstop=4
syntax on
EOF
```

**Do not spend exam time on this.** Mentioned only so you recognise the file.

---

## Recovering from a swap file

```text
E325: ATTENTION
Found a swap file by the name ".fstab.swp"
Swap file ".fstab.swp" already exists!
[O]pen Read-Only, (E)dit anyway, (R)ecover, (D)elete it, (Q)uit, (A)bort:
```

**This means a previous vim session on this file was killed.** Under exam conditions:

- **`D`** to delete the swap file and continue, if you know the previous session made no changes you need.
- **`R`** to recover, if it might have.
- **`Q`** to back out and think.

```bash
sudo rm /etc/.fstab.swp
sudo vim /etc/fstab
```

**Deleting the swap file directly is the fastest resolution once you are sure.**

---

## Editing files that matter

### `/etc/fstab`

```bash
sudo cp /etc/fstab /etc/fstab.bak          # cheap insurance
sudo vim /etc/fstab
```

```text
Esc  :set nu           see the line numbers
     G                 go to the last line
     yy p              duplicate the last entry as a template
     A                 append at the end of the line
     ...edit...
     Esc  :wq
```

```bash
sudo findmnt --verify
sudo mount -a
```

**Never leave vim on `/etc/fstab` without running those two commands.**

**And prefer not to type a UUID by hand at all:**

```bash
echo "UUID=$(sudo blkid -s UUID -o value /dev/sdb1)  /data  xfs  defaults  0 0" \
  | sudo tee -a /etc/fstab
```

**One command, no typo possible, no vim.** Use vim to fix a line, not to create one containing a UUID.

### `/etc/sudoers`

```bash
sudo visudo                                # NOT sudo vim /etc/sudoers
```

**`visudo` uses vim (or `$EDITOR`) but syntax-checks on save and refuses to write a broken file.** A syntax error in `/etc/sudoers` disables all sudo access.

```text
>>> /etc/sudoers.d/devs: syntax error near line 2 <<<
What now?
Options are:
  (e)dit sudoers file again
  e(x)it without saving changes to sudoers file
```

**Press `e` and fix it.** That prompt is `visudo` saving you.

### `/etc/selinux/config`

```bash
sudo vim /etc/selinux/config
```

```text
/SELINUX=      Enter        find the line
cw             change the word
```

**Or avoid vim entirely:**

```bash
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
grep ^SELINUX= /etc/selinux/config
```

### Configuration files generally

```bash
sudo vim /etc/ssh/sshd_config
```

```text
/PermitRootLogin   Enter     jump straight to it
0                            start of line
x                            delete the leading #
A                            append at the end to edit the value
Esc  :wq
```

```bash
sudo sshd -t                               # ALWAYS syntax-check after editing
sudo systemctl reload sshd
```

**Syntax checkers worth knowing, because a broken config file that reloads cleanly is a task you cannot see is failing:**

| File | Check |
| --- | --- |
| `/etc/ssh/sshd_config` | **`sudo sshd -t`** |
| `/etc/httpd/conf/httpd.conf` | **`sudo httpd -t`** or `apachectl configtest` |
| `/etc/rsyslog.conf` | **`sudo rsyslogd -N1`** |
| `/etc/sudoers` | **`sudo visudo -c`** |
| `/etc/fstab` | **`sudo findmnt --verify`** then `sudo mount -a` |
| `/etc/exports` | `sudo exportfs -rav` |
| A systemd unit | `sudo systemd-analyze verify /path/unit` |
| A shell script | **`bash -n script.sh`** |
| `/etc/chrony.conf` | `sudo chronyd -Q` |
| A Quadlet file | `podman-system-generator --dryrun` |

**Run the appropriate checker after every configuration file you edit.** It is the cheapest verification on the exam.

---

## When not to use vim

**Many exam edits are faster and safer as a single command:**

```bash
# Append a line
echo "192.168.56.12 server2" | sudo tee -a /etc/hosts

# Write a whole file
sudo tee /etc/yum.repos.d/local.repo >/dev/null <<'EOF'
[local-baseos]
name=Local BaseOS
baseurl=file:///mnt/iso/BaseOS
enabled=1
gpgcheck=0
EOF

# Change one setting in place
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
sudo sed -i 's/^#Listen 80/Listen 8090/' /etc/httpd/conf/httpd.conf

# Delete a line
sudo sed -i '/pattern/d' /etc/fstab
sudo sed -i '\|/data|d' /etc/fstab              # alternative delimiter for a path

# Comment out a line
sudo sed -i 's|^/dev/sdb1|#&|' /etc/fstab
```

**`sudo tee` with a here-document is the reliable way to write a multi-line root-owned file.** `sudo echo > /etc/file` fails, because the shell opens the file before `sudo` runs.

**Use `<<'EOF'` with the quotes** so `$` and backticks in the content are not expanded.

**Reach for vim when you need to see and modify existing content; reach for `tee` or `sed` when you know exactly what you want.**

---

## The panic card

```text
Situation                          Keys
──────────────────────────────────────────────────────────────────
I do not know what mode I am in     Esc
I have made a mess                  Esc  u  u  u   (undo repeatedly)
I have made a real mess             Esc  :q!       (quit, discard all)
I want to save and leave            Esc  :wq
It says "readonly"                  Esc  :q!  then sudo vim FILE
It says "No write since last change" Esc  :wq   or   Esc  :q!
Everything looks strange            Esc  :q!  and open it again
Cannot type anything                You are in command mode — press i
Text appears in odd places          You were in command mode; :q! and start again
Terminal is frozen                  Ctrl-q  (Ctrl-s froze it)
```

**Two habits eliminate most vim problems on the exam:**

1. **`sudo cp /etc/important /etc/important.bak` before editing anything critical.**
2. **`Esc` then `:q!` the moment you are unsure.** Reopening a file costs five seconds; saving a file you do not understand can cost the exam.

---

## The whole thing in ten lines

```text
vim file          open
i                 insert
Esc               stop inserting
:wq               save and quit
:q!               quit, discard everything
dd                delete a line
u                 undo
/text  n          search, next match
:%s/a/b/g         replace all
:set nu           line numbers
G   gg   :42      end, start, line 42
```

**That is enough for every editing task on EX200.** Everything else is optional.
