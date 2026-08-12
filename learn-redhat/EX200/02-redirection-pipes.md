# 02. Redirection, Pipes, And Processing Command Output

**Objectives:** Use input-output redirection (`>`, `>>`, `|`, `2>`, etc.). Processing output of shell commands within a script.

## Concept Refresher

Every process starts with three open file descriptors.

| FD | Name | Default | Redirect with |
| --: | --- | --- | --- |
| **0** | stdin | keyboard | `<` |
| **1** | stdout | terminal | `>`, `>>`, `1>` |
| **2** | stderr | terminal | `2>`, `2>>` |

The numbers matter. Almost every redirection mistake on the exam is a confusion between 1 and 2, or an ordering mistake in `2>&1`.

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

## Tasks

**Task 1.** Write the output of `ls /etc` to `/tmp/etc-list.txt`, replacing any existing content.

**Task 2.** Append the current date to `/tmp/etc-list.txt`.

**Task 3.** Run `find /etc -name "*.conf"` as a normal user, sending error messages to `/tmp/find-errors.txt` and results to `/tmp/find-results.txt`.

**Task 4.** Run the same `find` but combine both results and errors into a single file `/tmp/find-all.txt`.

**Task 5.** As a normal user with sudo, append the line `# managed by admin` to `/etc/hosts`. Do not use an editor.

**Task 6.** Count how many user accounts on this system have a UID of 1000 or greater.

**Task 7.** List the login shells in use on this system, with a count of how many accounts use each, sorted most common first.

**Task 8.** Create `/root/report.txt` containing a heredoc with the hostname and kernel version expanded at write time.

**Task 9.** Extract just the usernames and UIDs from `/etc/passwd`, colon-separated, sorted numerically by UID.

**Task 10.** Change every occurrence of `SELINUX=enforcing` to `SELINUX=permissive` in a copy of `/etc/selinux/config` at `/tmp/config`, keeping a backup of the original copy.

**Task 11.** Capture the output of `dnf repolist` into `/tmp/repos.txt` while still seeing it on screen.

**Task 12.** Run `mount -a` and print `OK` if it succeeded or `BROKEN` if it failed.

**Task 13.** Store the UUID of the root filesystem in a variable and print a correctly formatted `/etc/fstab` line for it, mounted at `/`, without writing to the file.

**Task 14.** Find the five largest files under `/var` and write their sizes and names to `/root/big-files.txt`.

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
