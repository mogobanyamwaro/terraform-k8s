# 02. Redirection, Pipes, And Processing Command Output

**Objectives:** Use input-output redirection (`>`, `>>`, `|`, `2>`, etc.). Processing output of shell commands within a script.

Every exam task ends with "write the result to a file" or "show only the lines that match". Redirection and pipes are how you get there. Master these before grep, permissions, or anything else.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Reading every redirection flag upfront feels like learning. Typing them one at a time actually is.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Every process has three streams

```bash
ls /etc > /tmp/stdout-demo.txt
ls /notreal 2> /tmp/stderr-demo.txt
cat /tmp/stdout-demo.txt | head -3
cat /tmp/stderr-demo.txt
```

**You should see** a directory listing in the first file and an error message in the second.

Every command has **stdout** (normal output, FD 1) and **stderr** (errors, FD 2). By default both go to your terminal. Redirection sends them somewhere else.

### 2. Truncate versus append (`>` and `>>`)

```bash
echo "first line" > /tmp/redirect-test.txt
cat /tmp/redirect-test.txt
echo "second line" >> /tmp/redirect-test.txt
cat /tmp/redirect-test.txt
```

**You should see** one line after the first command, two lines after the second.

`>` **replaces** the file. `>>` **appends**. Using `>` on `/etc/fstab` when you meant `>>` destroys the file — a real exam failure mode.

### 3. Split stdout and stderr

```bash
find /etc -name "*.conf" > /tmp/find-results.txt 2> /tmp/find-errors.txt
wc -l /tmp/find-results.txt /tmp/find-errors.txt
```

**You should see** two line counts. The results file has paths; the errors file has "Permission denied" messages.

As a normal user, `find /etc` hits many unreadable directories. Splitting streams lets you keep the useful output clean.

### 4. Combine both streams (`2>&1` and `&>`)

```bash
find /etc -name "*.conf" > /tmp/find-all.txt 2>&1
wc -l /tmp/find-all.txt
```

**You should see** one file containing both results and errors.

`2>&1` means "send stderr wherever stdout is **currently pointing**". Order matters:

```bash
# WRONG — stderr still goes to the terminal:
find /etc -name "*.conf" 2>&1 > /tmp/wrong.txt
```

Read `2>&1` as "make FD 2 follow FD 1 right now". Redirections apply **left to right**.

### 5. Discard output (`/dev/null`)

```bash
find /etc -name "*.conf" 2>/dev/null | head -5
```

**You should see** five `.conf` paths with no permission errors mixed in.

`2>/dev/null` throws away stderr. You will use this constantly with `grep -r` and `find`.

### 6. Pipes connect commands

```bash
cat /etc/passwd | wc -l
cut -d: -f7 /etc/passwd | sort | uniq -c | sort -nr | head -5
```

**You should see** a user count, then the five most common login shells with counts.

A pipe (`|`) sends **stdout only** to the next command's stdin. The shell pipeline is how you build reports from raw data.

### 7. Pipe stderr too

```bash
find /etc -name hosts 2>&1 | grep -v "Permission denied"
```

**You should see** the path to `hosts` without permission noise — or just the grep match.

If errors need to reach a filter, redirect stderr into stdout first: `2>&1 |`.

### 8. `tee`: write and still see it

```bash
ls /etc | tee /tmp/etc-tee.txt | wc -l
wc -l /tmp/etc-tee.txt
```

**You should see** the same count from both commands — the data went to the file **and** through the pipe.

`tee` splits the stream. Essential when you want to capture output but still watch it.

### 9. `sudo tee`: the exam-critical pattern

```bash
echo "# practice line" | sudo tee -a /etc/hosts
tail -3 /etc/hosts
```

**You should see** your comment at the end of `/etc/hosts`.

This fails:

```bash
sudo echo "# practice line" >> /etc/hosts    # Permission denied
```

Your **shell** opens the file for redirection, not `sudo`. The shell is not root. Always use `| sudo tee -a` when appending to root-owned files.

### 10. Extract fields with `cut`

```bash
cut -d: -f1 /etc/passwd | head -5
cut -d: -f1,3 /etc/passwd | head -3
```

**You should see** usernames only, then username:UID pairs.

`-d:` sets the delimiter. `-f1` is field 1. This is faster than regex when fields are colon-separated.

### 11. Conditional filtering with `awk`

```bash
awk -F: '$3 >= 1000 {print $1}' /etc/passwd | wc -l
```

**You should see** a count of regular user accounts (UID 1000 and above on RHEL).

`awk` shines when you need a **condition** on a field. `$3` is the third field (UID). `-F:` sets the delimiter.

### 12. Edit text with `sed`

```bash
cp /etc/selinux/config /tmp/selinux-copy
sed 's/enforcing/permissive/' /tmp/selinux-copy | grep SELINUX=
sed -i.bak 's/permissive/enforcing/' /tmp/selinux-copy
ls -l /tmp/selinux-copy*
```

**You should see** the substitution on stdout, then a backup file `.bak` alongside the edited copy.

`sed 's/old/new/'` prints to stdout. `sed -i.bak` edits in place and keeps the original as a backup. Use `-i.bak` on config files until you are confident.

### 13. Command substitution (`$(...)`)

```bash
echo "Today is $(date +%Y-%m-%d)"
echo "Hostname: $(hostname)"
```

**You should see** today's date and your VM's hostname embedded in the strings.

`$(command)` runs the command and substitutes its output. Prefer this over backticks — it nests cleanly and reads better.

### 14. Exit status and conditional commands

```bash
true && echo SUCCESS || echo FAILED
false && echo SUCCESS || echo FAILED
sudo mount -a && echo "fstab OK" || echo "FSTAB BROKEN"
```

**You should see** SUCCESS, then FAILED, then either fstab OK or BROKEN.

`&&` runs the next command only if the previous succeeded (exit 0). `||` runs only on failure. `$?` holds the last exit status: `echo $?` after any command.

### Mini checkpoint

Before the practice tasks, you should be able to explain:

| Symbol | Does |
| --- | --- |
| `>` | stdout to file, truncate |
| `>>` | stdout to file, append |
| `2>` | stderr only |
| `2>&1` | stderr follows stdout |
| `\|` | pipe stdout to next command |
| `tee` | write to file and pass through |
| `\| sudo tee -a` | append to a root-owned file |

If any row is blank in your head, re-run the step above that covers it.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Write the output of `ls /etc` to `/tmp/etc-list.txt`, replacing any existing content.

> Hint: output redirection from follow-along step 2 — truncate, not append.

**Task 2.** Append the current date to `/tmp/etc-list.txt`.

> Hint: the append operator from step 2.

**Task 3.** Run `find /etc -name "*.conf"` as a normal user, sending error messages to `/tmp/find-errors.txt` and results to `/tmp/find-results.txt`.

> Hint: split stdout and stderr from step 3.

**Task 4.** Run the same `find` but combine both results and errors into a single file `/tmp/find-all.txt`.

> Hint: combine streams from step 4; watch the ordering.

**Task 5.** As a normal user with sudo, append the line `# managed by admin` to `/etc/hosts`. Do not use an editor.

> Hint: the `sudo tee` pattern from step 9.

**Task 6.** Count how many user accounts on this system have a UID of 1000 or greater.

> Hint: `awk` conditional from step 11, then pipe to `wc -l`.

**Task 7.** List the login shells in use on this system, with a count of how many accounts use each, sorted most common first.

> Hint: `cut` field 7, then the `sort | uniq -c | sort -nr` pipeline from step 6.

**Task 8.** Create `/root/report.txt` containing a heredoc with the hostname and kernel version expanded at write time.

> Hint: heredoc with unquoted `EOF` so `$(...)` expands; use `sudo tee` for `/root/`.

**Task 9.** Extract just the usernames and UIDs from `/etc/passwd`, colon-separated, sorted numerically by UID.

> Hint: `cut -d: -f1,3` then `sort -t: -k2 -n`.

**Task 10.** Change every occurrence of `SELINUX=enforcing` to `SELINUX=permissive` in a copy of `/etc/selinux/config` at `/tmp/config`, keeping a backup of the original copy.

> Hint: `sed -i.bak` from step 12.

**Task 11.** Capture the output of `dnf repolist` into `/tmp/repos.txt` while still seeing it on screen.

> Hint: `tee` from step 8.

**Task 12.** Run `mount -a` and print `OK` if it succeeded or `BROKEN` if it failed.

> Hint: `&&` and `||` from step 14.

**Task 13.** Store the UUID of the root filesystem in a variable and print a correctly formatted `/etc/fstab` line for it, mounted at `/`, without writing to the file.

> Hint: command substitution from step 13 plus `blkid` or `findmnt`.

**Task 14.** Find the five largest files under `/var` and write their sizes and names to `/root/big-files.txt`.

> Hint: `find` or `du`, pipe through `sort -hr`, `head`, and `sudo tee`.

---

## Solutions

**Task 1.**

```bash
ls /etc > /tmp/etc-list.txt
```

`>` truncates. If the file existed with 500 lines, it now has only this output.

**Task 2.**

```bash
date >> /tmp/etc-list.txt
tail -3 /tmp/etc-list.txt
```

`>>` appends. Confusing `>` and `>>` when adding a line to `/etc/fstab` destroys the file, which is a real way people fail this exam.

**Task 3.**

```bash
find /etc -name "*.conf" > /tmp/find-results.txt 2> /tmp/find-errors.txt
wc -l /tmp/find-results.txt /tmp/find-errors.txt
```

Two separate targets, one for each stream. As a normal user, `/tmp/find-errors.txt` will be full of "Permission denied".

**Task 4.**

```bash
find /etc -name "*.conf" > /tmp/find-all.txt 2>&1
```

Or equivalently:

```bash
find /etc -name "*.conf" &> /tmp/find-all.txt
```

Order matters. `find ... 2>&1 > /tmp/find-all.txt` would leave errors on your terminal.

**Task 5.**

```bash
echo "# managed by admin" | sudo tee -a /etc/hosts
```

Verify:

```bash
tail -3 /etc/hosts
```

`sudo echo "..." >> /etc/hosts` fails with "Permission denied" because your non-root shell performs the redirection. This is the single most useful pattern in this file.

**Task 6.**

```bash
awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | wc -l
```

The upper bound excludes `nobody`, which is UID 65534. A simpler version that is usually accepted:

```bash
awk -F: '$3 >= 1000 {print $1}' /etc/passwd | wc -l
```

Regular user accounts start at **1000** on RHEL. System accounts are below it.

**Task 7.**

```bash
cut -d: -f7 /etc/passwd | sort | uniq -c | sort -nr
```

The pipeline reads as: take field 7, sort so duplicates are adjacent, count runs, then sort those counts descending. **`uniq` only collapses adjacent lines**, so the first `sort` is mandatory. `uniq -c | sort -nr` is the canonical "frequency count" idiom.

**Task 8.**

```bash
sudo tee /root/report.txt <<EOF
Hostname: $(hostname)
Kernel:   $(uname -r)
Date:     $(date)
EOF
```

Verify:

```bash
sudo cat /root/report.txt
```

The unquoted `EOF` means `$(...)` is evaluated as the heredoc is written. With `<<'EOF'` the file would literally contain `$(hostname)`.

**Task 9.**

```bash
cut -d: -f1,3 /etc/passwd | sort -t: -k2 -n
```

`-t:` sets the sort delimiter, `-k2` selects the second field of the cut output (the UID), `-n` makes it numeric. Without `-n` you get `1`, `10`, `100`, `2` in that order.

**Task 10.**

```bash
cp /etc/selinux/config /tmp/config
sed -i.bak 's/SELINUX=enforcing/SELINUX=permissive/' /tmp/config
diff /tmp/config.bak /tmp/config
```

`-i.bak` edits in place and leaves the original as `/tmp/config.bak`. Using `diff` to confirm exactly what changed is a good habit before you do this to a real system file.

**Task 11.**

```bash
dnf repolist | tee /tmp/repos.txt
```

`tee` splits the stream. To capture errors too:

```bash
dnf repolist 2>&1 | tee /tmp/repos.txt
```

**Task 12.**

```bash
sudo mount -a && echo OK || echo BROKEN
```

Get this into your fingers. It is the pre-reboot safety check from `Persistence.md`, and it is much more reliable than looking at silent output and assuming success.

**Task 13.**

```bash
ROOTDEV=$(findmnt -no SOURCE /)
UUID=$(sudo blkid -s UUID -o value "$ROOTDEV")
echo "UUID=$UUID  /  xfs  defaults  0 0"
```

`blkid -s UUID -o value` prints just the bare UUID with no label or quoting, which is exactly what you want to interpolate. Compare with plain `blkid`, whose output you would then have to cut apart.

**Task 14.**

```bash
sudo find /var -type f -exec du -h {} + 2>/dev/null | sort -hr | head -5 | sudo tee /root/big-files.txt
```

`sort -hr` sorts human-readable sizes like `1.5G` and `900M` correctly; plain `sort -nr` would get those wrong. A simpler alternative:

```bash
sudo du -ah /var 2>/dev/null | sort -hr | head -5 | sudo tee /root/big-files.txt
```

---

## Verify

```bash
ls -l /tmp/etc-list.txt /tmp/find-results.txt /tmp/find-errors.txt /tmp/find-all.txt
tail -3 /etc/hosts
sudo cat /root/report.txt
sudo cat /root/big-files.txt
```

## Persistence Check

Nothing here needs to survive a reboot, but two habits from this file protect everything that does:

```bash
# Always append, never overwrite, when adding to a system file
echo "..." | sudo tee -a /etc/fstab

# Always confirm before rebooting
sudo mount -a && echo OK || echo BROKEN
```

## Quick Reference

Come back here when you need a flag you forgot — not before your first pass through Follow Along.

Every process starts with three open file descriptors.

| FD | Name | Default | Redirect with |
| --: | --- | --- | --- |
| **0** | stdin | keyboard | `<` |
| **1** | stdout | terminal | `>`, `>>`, `1>` |
| **2** | stderr | terminal | `2>`, `2>>` |

### Output redirection

```bash
command > file            # stdout to file, TRUNCATING it
command >> file           # stdout to file, APPENDING
command 2> file           # stderr only
command 2>> file          # stderr, appending
command > out 2> err      # split them into separate files
command > file 2>&1       # BOTH into one file
command &> file           # both, bash shorthand. Same effect
command &>> file          # both, appending
command > /dev/null       # discard stdout
command 2> /dev/null      # discard stderr — very common with find
command &> /dev/null      # discard everything
```

### The `2>&1` ordering trap

```bash
command > file 2>&1       # CORRECT: both end up in file
command 2>&1 > file       # WRONG: stderr goes to the TERMINAL, stdout to file
```

Redirections are processed **left to right**. In the wrong version, `2>&1` first points stderr at wherever stdout currently is (the terminal), and only then is stdout moved to the file. stderr keeps pointing at the terminal.

Read `2>&1` as "make FD 2 go wherever FD 1 is **pointing right now**". That reading makes the ordering obvious.

### Input redirection and here-documents

```bash
command < file                    # read stdin from a file
sort < unsorted.txt
mail -s "subject" user < body.txt

# Here-document: feed literal lines as stdin
cat <<EOF > /etc/motd
Welcome to $(hostname)
EOF

# Quoted delimiter: NO expansion of $variables or $(commands)
cat <<'EOF' > /root/script.sh
echo "$HOME is not expanded now"
EOF

# Here-string: a single line
grep root <<< "$(cat /etc/passwd)"
```

The quoting distinction is important. `<<EOF` expands variables and command substitutions as the heredoc is written. `<<'EOF'` writes them literally. When you are generating a script or a config containing `$` characters, you almost always want the quoted form.

### Pipes

```bash
command1 | command2               # stdout of 1 becomes stdin of 2
ps aux | grep httpd
cat /etc/passwd | wc -l
dmesg | less

command1 |& command2              # pipe stdout AND stderr (bash)
command1 2>&1 | command2          # the portable way to do the same
```

A plain `|` only carries **stdout**. If you need error output to reach `grep`, you must redirect stderr into stdout first. This is why `somecommand | grep error` sometimes finds nothing even though errors are printing.

### `tee`: write and pass through

```bash
command | tee file                # write to file AND to stdout
command | tee -a file             # append instead of truncate
command | tee file1 file2         # multiple files
command | tee /dev/null           # write nowhere, only pass through
command 2>&1 | tee log            # capture everything and still watch it
```

**The critical use of `tee` on this exam:**

```bash
# FAILS: your shell, not sudo, opens the file
sudo echo "line" > /root/protected.txt

# WORKS: sudo runs tee, and tee opens the file as root
echo "line" | sudo tee /root/protected.txt

# WORKS: appending
echo "line" | sudo tee -a /etc/fstab
```

The redirection is performed by the shell **before** `sudo` ever runs, and your shell is not root. This will bite you when appending to `/etc/fstab`, `/etc/hosts`, and `/etc/exports`, all of which are real exam tasks. Learn `| sudo tee -a` as one unit.

### Text processing you actually need

```bash
sort file                         # alphabetical
sort -n file                      # numeric
sort -nr file                     # numeric, descending
sort -u file                      # sorted, unique
sort -k3 file                      # by field 3
sort -t: -k3 -n /etc/passwd       # by UID: ':' delimiter, field 3, numeric

uniq file                         # collapse ADJACENT duplicates
sort file | uniq                  # the correct way to dedupe
sort file | uniq -c               # with counts
sort file | uniq -c | sort -nr    # frequency, most common first
sort file | uniq -d               # only duplicated lines
sort file | uniq -u               # only unique lines

cut -d: -f1 /etc/passwd           # field 1, ':' delimited
cut -d: -f1,3 /etc/passwd         # fields 1 and 3
cut -d: -f1-3 /etc/passwd         # range
cut -c1-10 file                   # characters, not fields

tr 'a-z' 'A-Z' < file             # translate
tr -d ' ' < file                  # delete spaces
tr -s ' ' < file                  # squeeze repeats

awk -F: '{print $1}' /etc/passwd            # field 1
awk -F: '$3 >= 1000 {print $1}' /etc/passwd # conditional
awk '{print $1, $NF}' file                  # first and last field
awk '{sum+=$1} END {print sum}' file        # total a column

sed 's/old/new/' file             # first match per line
sed 's/old/new/g' file            # every match
sed -i 's/old/new/g' file         # EDIT THE FILE IN PLACE
sed -i.bak 's/old/new/g' file     # in place, keeping file.bak
sed -n '5p' file                  # print only line 5
sed -n '10,20p' file              # lines 10-20
sed '/^#/d' file                  # delete comment lines
sed -i '/^SELINUX=/d' file        # delete matching lines in place
```

`sed -i` is the workhorse for exam config edits:

```bash
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i.bak 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub
```

Use `sed -i.bak` when you are not certain. It gives you a free undo.

### Command substitution

```bash
echo "Today is $(date)"
UUID=$(blkid -s UUID -o value /dev/vdb1)
echo "UUID=$UUID /mnt/data xfs defaults 0 0" | sudo tee -a /etc/fstab

FILES=$(find /etc -name "*.conf" | wc -l)
echo "There are $FILES conf files"

# Backticks are the old form. Works, but does not nest.
echo "Today is `date`"
```

`$(...)` is preferred: it nests, and it is easier to read. The `UUID=$(blkid ...)` pattern is one you will type on the exam, so practise it.

### Exit status

```bash
command
echo $?                  # 0 = success, non-zero = failure

command && echo OK       # run only if the previous succeeded
command || echo FAILED   # run only if the previous failed
command1 ; command2      # run both regardless

mount -a && echo "fstab OK" || echo "FSTAB BROKEN"
```

`$?` is how you verify silent commands. `mount -a` printing nothing is ambiguous until you check `$?`.

## Exam Tips

- **1 is stdout, 2 is stderr.** `2>` for errors only, `&>` or `> file 2>&1` for both.
- **`> file 2>&1` is correct. `2>&1 > file` is wrong.** Redirections apply left to right.
- **`>` truncates, `>>` appends.** Using `>` on `/etc/fstab` destroys it.
- **`sudo cmd > /root/file` does not work.** Use **`cmd | sudo tee /root/file`** or `tee -a` to append. This is the most useful line in this file.
- A plain pipe carries **stdout only**. Use `2>&1 |` to pipe errors too.
- **`2>/dev/null`** to silence permission noise from `find`.
- **`uniq` needs sorted input.** The frequency idiom is `sort | uniq -c | sort -nr`.
- `cut -d: -f1` for delimited fields; `awk -F:` when you need a condition.
- **`sed -i`** edits in place; **`sed -i.bak`** gives you an undo. Use it on config files.
- **`$(...)`** over backticks. `UUID=$(blkid -s UUID -o value /dev/vdb1)` is an exam-critical idiom.
- `<<EOF` expands variables; **`<<'EOF'` does not**. Use the quoted form when writing scripts.
- **`$?`** is 0 on success. `cmd && echo OK || echo FAIL` is the fast way to check silent commands.
- `sort -h` for human-readable sizes, `sort -n` for plain numbers.
