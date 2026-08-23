# 04. Archiving And Compression

**Objective:** Archive, compress, unpack, and uncompress files using `tar`, `star`, `gzip`, and `bzip2`.

The exam wording historically mentions `star` as well. It is a legacy `tar` variant with SELinux-attribute support and is rarely installed; if a task ever asks for it, `tar --xattrs --selinux` does the same job. Focus on `tar`.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Creating archives feels like memorising flags until you type them once on real files.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Archive without compression

```bash
sudo tar -cvf /tmp/etc-demo.tar /etc/hosts /etc/hostname
ls -lh /tmp/etc-demo.tar
```

**You should see** a `.tar` file, probably a few kilobytes, and verbose output listing each member.

`tar -c` **c**reates, `-v` is verbose, `-f` names the archive file. **`-f` is always required.** Archiving bundles files; it does not shrink them.

### 2. Create a gzip-compressed archive

```bash
sudo tar -czvf /tmp/etc-demo.tar.gz /etc/hosts /etc/hostname
ls -lh /tmp/etc-demo.tar /tmp/etc-demo.tar.gz
```

**You should see** the `.tar.gz` is smaller than the plain `.tar`.

`-z` applies **gzip** compression. The common extension is `.tar.gz` or `.tgz`. `tar` can archive and compress in one step.

### 3. List contents without extracting

```bash
tar -tvf /tmp/etc-demo.tar.gz
tar -tvf /tmp/etc-demo.tar.gz | head -5
```

**You should see** each file's permissions, owner, size, and path inside the archive.

`-t` **l**is**t**s. You do not need `-z` on modern GNU tar for listing — it auto-detects compression. **Always list before extracting an archive you did not create.**

### 4. Extract to a specific directory

```bash
mkdir -p /tmp/tar-restore
tar -xvf /tmp/etc-demo.tar.gz -C /tmp/tar-restore
ls -l /tmp/tar-restore/etc/
```

**You should see** `hosts` and `hostname` under `/tmp/tar-restore/etc/`.

`-x` e**x**tracts. `-C dir` changes to that directory first — and **the directory must already exist**. Member names have **no leading slash** (`etc/hosts`, not `/etc/hosts`).

### 5. Extract a single file from an archive

```bash
mkdir -p /tmp/single-restore
tar -xvf /tmp/etc-demo.tar.gz -C /tmp/single-restore etc/hosts
cat /tmp/single-restore/etc/hosts | head -3
```

**You should see** only `hosts` was extracted. Use `-t` first if you are unsure of the exact member name.

### 6. Preserve SELinux contexts on RHEL

```bash
sudo tar -czvf /tmp/etc-selinux.tar.gz --xattrs --selinux --acls /etc/selinux/config
tar -tvf /tmp/etc-selinux.tar.gz
```

**You should see** the archive created with a warning about `Removing leading '/' from member names` — that is normal and desirable.

On RHEL exams, when contexts matter, add **`--xattrs --selinux --acls`** on both create and extract. Without them, restored files get default contexts.

### 7. bzip2 and xz compression

```bash
sudo tar -cjvf /tmp/etc-demo.tar.bz2 /etc/hosts /etc/hostname
sudo tar -cJvf /tmp/etc-demo.tar.xz /etc/hosts /etc/hostname
ls -lh /tmp/etc-demo.tar.*
```

**You should see** three compressed archives with different sizes. **`-j` is bzip2**, **`-J` (capital) is xz**.

Mnemonic: **z**ip (gzip), **j** for b**j**ip2, capital **J** for the "bigger" xz. Creation requires the right letter; extraction auto-detects.

### 8. Standalone gzip — and the disappearing original

```bash
cp /etc/services /tmp/services-demo
gzip -k /tmp/services-demo
ls -l /tmp/services-demo*
```

**You should see** both `/tmp/services-demo` and `/tmp/services-demo.gz`.

Without `-k`, `gzip` **replaces** the original — only the `.gz` remains. If a task says "compress but keep the original", you need `-k` or `gzip -c file > file.gz`.

### 9. Search inside a compressed file

```bash
zgrep -i http /tmp/services-demo.gz | head -5
```

**You should see** matching lines from the compressed file without decompressing it.

The `z*` family (`zcat`, `zless`, `zgrep`) works on `.gz` files. Use `bzgrep`/`bzcat` for bzip2 and `xzgrep`/`xzcat` for xz. Very useful against rotated logs in `/var/log/*.gz`.

### 10. Exclude patterns when archiving

```bash
sudo tar -czvf /tmp/log-demo.tar.gz --exclude='*.gz' /var/log/messages /var/log/secure 2>/dev/null
tar -tvf /tmp/log-demo.tar.gz
```

**You should see** only the uncompressed log files, no `.gz` rotated copies.

Quote exclude patterns so the shell does not expand them. Repeat `--exclude` for multiple patterns.

### 11. Append to an uncompressed archive

```bash
sudo tar -cvf /tmp/append-demo.tar /etc/hostname
sudo tar -rvf /tmp/append-demo.tar /etc/hosts
tar -tvf /tmp/append-demo.tar
```

**You should see** both files in the archive.

`-r` **a**ppends to an existing archive. **This only works on uncompressed `.tar` files.** You cannot append to `.tar.gz` — the compression wraps the whole stream.

### 12. Check compression ratio

```bash
gzip -l /tmp/services-demo.gz
```

**You should see** compressed size, uncompressed size, ratio, and the original filename.

### Mini checkpoint

Before the practice tasks, you should be able to explain:

| Flag | Does |
| --- | --- |
| `-c` | create archive |
| `-x` | extract |
| `-t` | list contents |
| `-f` | archive filename (always required) |
| `-z` | gzip |
| `-j` | bzip2 |
| `-J` | xz |
| `-C dir` | change directory before extract/create |

If any row is blank in your head, re-run the step above that covers it.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Create a gzip-compressed archive of `/etc` at `/root/etc-backup.tar.gz`, preserving SELinux contexts and extended attributes.

> Hint: `-czvf` plus preservation flags from follow-along step 6.

**Task 2.** List the contents of that archive without extracting it, showing only the first 20 entries.

> Hint: `-tvf` and pipe to `head` from step 3.

**Task 3.** Extract only `etc/hosts` from the archive into `/tmp/restore`.

> Hint: create the directory first; member name has no leading slash — step 5.

**Task 4.** Create a bzip2-compressed archive of `/var/log` at `/root/logs.tar.bz2`, excluding any file ending in `.gz`.

> Hint: `-j` for bzip2 and `--exclude` from steps 7 and 10.

**Task 5.** Create an xz-compressed archive of `/home` at `/root/home.tar.xz`.

> Hint: capital `-J` from step 7.

**Task 6.** Compare the sizes of the three archives you have created and state which compressor was most effective.

> Hint: `ls -lhS` or `du -h` on the three files from steps 6–7.

**Task 7.** Copy `/etc/services` to `/tmp/services`, then compress it with gzip while keeping the uncompressed original.

> Hint: `gzip -k` from step 8.

**Task 8.** Search the compressed file from Task 7 for the word `http` without decompressing it.

> Hint: `zgrep` from step 9.

**Task 9.** Extract `/root/etc-backup.tar.gz` completely into `/tmp/fullrestore`, preserving permissions and SELinux contexts.

> Hint: `-xvpf` with preservation flags; `-p` preserves permissions — step 6.

**Task 10.** Create an uncompressed archive of `/etc/ssh` at `/root/ssh.tar`, then append `/etc/hosts` to that same archive.

> Hint: `-cvf` then `-rvf` from step 11.

**Task 11.** Create a compressed archive of `/etc` that excludes `/etc/pki` and any `.key` file, at `/root/etc-safe.tar.gz`.

> Hint: multiple `--exclude` options from step 10.

**Task 12.** Determine the compression ratio of `/tmp/services.gz`.

> Hint: `gzip -l` from step 12.

---

## Solutions

**Task 1.**

```bash
sudo tar -czvf /root/etc-backup.tar.gz --xattrs --selinux --acls /etc
```

Verify:

```bash
ls -lh /root/etc-backup.tar.gz
```

Reading the flags: `c` create, `z` gzip, `v` verbose, `f` the filename. `tar` will warn `Removing leading '/' from member names`, which is normal and desirable.

Without `--selinux`, restoring into `/` would give every file the default context for its location, which may or may not be right. On a RHEL exam, get into the habit of including the three preservation flags.

**Task 2.**

```bash
tar -tvf /root/etc-backup.tar.gz | head -20
```

`-t` lists. Notice you do not need `-z`; modern `tar` detects it.

**Task 3.**

```bash
mkdir -p /tmp/restore
tar -xvf /root/etc-backup.tar.gz -C /tmp/restore etc/hosts
ls -l /tmp/restore/etc/hosts
```

The member name is `etc/hosts`, without the leading slash, because `tar` stripped it at creation. Specifying `/etc/hosts` finds nothing. Use `-t` first if you are unsure of the exact member name.

`-C /tmp/restore` requires that directory to exist already.

**Task 4.**

```bash
sudo tar -cjvf /root/logs.tar.bz2 --exclude='*.gz' /var/log
```

Verify the exclusion worked:

```bash
tar -tvf /root/logs.tar.bz2 | grep -c '\.gz$'      # should be 0
```

Quote the exclude pattern so the shell does not expand it against your current directory.

**Task 5.**

```bash
sudo tar -cJvf /root/home.tar.xz /home
```

Capital `J`. Lowercase `j` is bzip2, and mixing them up produces an archive whose extension lies about its contents.

**Task 6.**

```bash
ls -lhS /root/*.tar.*
du -h /root/etc-backup.tar.gz /root/logs.tar.bz2 /root/home.tar.xz
```

`ls -S` sorts by size, largest first. These archives contain different data, so this is not a controlled comparison. For a real one, archive the same source three ways:

```bash
sudo tar -czf /tmp/t.gz  /etc 2>/dev/null
sudo tar -cjf /tmp/t.bz2 /etc 2>/dev/null
sudo tar -cJf /tmp/t.xz  /etc 2>/dev/null
ls -lhS /tmp/t.*
```

Expect **xz smallest, gzip largest, bzip2 in between**, with creation time in the opposite order.

**Task 7.**

```bash
cp /etc/services /tmp/services
gzip -k /tmp/services
ls -l /tmp/services /tmp/services.gz
```

`-k` keeps the original. Without it, `/tmp/services` would be gone and only `/tmp/services.gz` would remain. This is the most common surprise with the standalone compressors.

An equivalent that never touches the original:

```bash
gzip -c /tmp/services > /tmp/services.gz
```

**Task 8.**

```bash
zgrep http /tmp/services.gz
```

`zgrep` decompresses on the fly. The family is `zcat`, `zless`, `zgrep`, `zdiff`, with `bz*` and `xz*` equivalents. Very useful against rotated logs in `/var/log/*.gz`.

**Task 9.**

```bash
sudo mkdir -p /tmp/fullrestore
sudo tar -xvpf /root/etc-backup.tar.gz -C /tmp/fullrestore --xattrs --selinux --acls
```

Verify contexts came back:

```bash
ls -lZ /tmp/fullrestore/etc/shadow
ls -lZ /etc/shadow
```

`-p` preserves permissions. When extracting as root, `-p` is the default, but stating it costs nothing and is explicit about intent.

**Task 10.**

```bash
sudo tar -cvf /root/ssh.tar /etc/ssh
sudo tar -rvf /root/ssh.tar /etc/hosts
tar -tvf /root/ssh.tar | tail
```

`-r` appends. **This only works on uncompressed archives.** You cannot append to a `.tar.gz`, because the compression wraps the whole stream. If a task requires appending, the archive must be plain `.tar`.

To add to a compressed archive you must decompress, append, recompress:

```bash
gunzip /root/etc-backup.tar.gz
sudo tar -rvf /root/etc-backup.tar /some/newfile
gzip /root/etc-backup.tar
```

**Task 11.**

```bash
sudo tar -czvf /root/etc-safe.tar.gz \
  --exclude='/etc/pki' \
  --exclude='*.key' \
  /etc
```

Verify:

```bash
tar -tvf /root/etc-safe.tar.gz | grep -cE 'etc/pki|\.key$'    # should be 0
```

You may repeat `--exclude` as many times as you need. For a long list, use `--exclude-from=file`.

**Task 12.**

```bash
gzip -l /tmp/services.gz
```

Prints compressed size, uncompressed size, ratio, and the original filename. Handy for showing a task's effect, though not something you would rely on in production.

---

## Verify

```bash
ls -lh /root/*.tar*
tar -tvf /root/etc-backup.tar.gz | wc -l
ls -l /tmp/services /tmp/services.gz
ls -lZ /tmp/fullrestore/etc/hosts
```

## Persistence Check

Archives are files, so they persist by definition. Two things to be careful about:

- If a task says "back up `/etc` to `/root/etc.tar.gz`", the archive must **exist at that exact path** after the reboot. Do not write it to `/tmp`, which some systems clean on boot.
- If a task says the restore must preserve SELinux contexts, use `--xattrs --selinux --acls` on **both** create and extract. A restore without them can leave services broken after the reboot in a way that looks like an SELinux task failure.

## Quick Reference

Come back here when you need a flag you forgot — not before your first pass through Follow Along.

**Archiving and compression are two different operations.** `tar` bundles many files into one; `gzip`/`bzip2`/`xz` shrink a single file. `tar` can invoke a compressor for you, which is why the two get conflated.

### The tar flags

| Flag | Meaning |
| --- | --- |
| **`-c`** | **c**reate an archive |
| **`-x`** | e**x**tract |
| **`-t`** | **t**est / lis**t** contents |
| **`-f`** | **f**ile — the archive name. **Always required** |
| `-v` | verbose |
| **`-z`** | gzip (`.tar.gz`, `.tgz`) |
| **`-j`** | bzip2 (`.tar.bz2`) |
| **`-J`** | xz (`.tar.xz`), capital J |
| `-C dir` | **c**hange to this directory first |
| `-p` | preserve permissions |
| `--xattrs` | preserve extended attributes |
| `--selinux` | preserve SELinux contexts |
| `--acls` | preserve ACLs |
| `-r` | append files to an existing uncompressed archive |
| `-u` | update: append only newer versions |
| `--exclude=PATTERN` | skip matching paths |
| `-a` | pick the compressor from the filename extension |

Only one of `-c`, `-x`, or `-t` per command, and `-f` always.

### Creating archives

```bash
# Uncompressed
tar -cvf /root/etc.tar /etc

# gzip: fastest, weakest compression
tar -czvf /root/etc.tar.gz /etc

# bzip2: slower, better compression
tar -cjvf /root/etc.tar.bz2 /etc

# xz: slowest, best compression
tar -cJvf /root/etc.tar.xz /etc

# Let tar decide from the extension
tar -cavf /root/etc.tar.gz /etc

# Preserving everything that matters on RHEL
sudo tar -czvf /root/etc.tar.gz --xattrs --selinux --acls /etc

# Multiple sources
tar -czvf /root/backup.tar.gz /etc /home/alice /var/log/messages

# Excluding
tar -czvf /root/home.tar.gz --exclude='*.tmp' --exclude='cache' /home
```

`tar` strips the leading `/` and warns you about it. That is deliberate and good: it means extraction is relative to wherever you are, not straight over `/etc`.

### Listing before extracting

```bash
tar -tvf /root/etc.tar.gz              # list contents
tar -tvf /root/etc.tar.gz | head
tar -tzvf archive.tar.gz               # -z is optional on modern tar for listing
```

**Always list before extracting an archive you did not create.** An archive with absolute paths or `../` components can write outside the current directory. `-t` costs two seconds.

### Extracting

```bash
tar -xvf /root/etc.tar.gz                        # into the current directory
tar -xvf /root/etc.tar.gz -C /tmp/restore        # into a specific directory
sudo tar -xvf /root/etc.tar.gz -C / --xattrs --selinux --acls   # restore in place

# Extract a single member
tar -xvf /root/etc.tar.gz etc/hosts

# Extract several by pattern
tar -xvf /root/etc.tar.gz --wildcards 'etc/ssh/*'
```

Modern GNU `tar` auto-detects the compression on extraction, so `tar -xvf` works for `.gz`, `.bz2`, and `.xz` alike. You still need the right letter when **creating**.
The destination directory for `-C` must already exist. `tar` will not create it.

### Standalone compressors

Each of these **replaces** the original file by default.

```bash
gzip file                     # -> file.gz, original GONE
gzip -k file                  # keep the original
gzip -9 file                  # maximum compression
gzip -1 file                  # fastest
gunzip file.gz                # -> file
gzip -d file.gz               # same thing
gzip -l file.gz               # show the compression ratio
zcat file.gz                  # read without decompressing
zless file.gz
zgrep pattern file.gz         # grep a compressed file

bzip2 file                    # -> file.bz2
bzip2 -k file
bunzip2 file.bz2
bzip2 -d file.bz2
bzcat file.bz2
bzgrep pattern file.bz2

xz file                       # -> file.xz
xz -k file
unxz file.xz
xz -d file.xz
xzcat file.xz
```

**The surprise is that the original disappears.** `gzip bigfile.log` leaves you with only `bigfile.log.gz`. If a task says "compress this file but keep the original", you need `-k`.

The `z*`/`bz*`/`xz*` reader family is genuinely useful for rotated logs:

```bash
sudo zgrep -i error /var/log/messages-*.gz
sudo zcat /var/log/messages-20260801.gz | tail -50
```

### Comparison

| Tool | tar flag | Extension | Speed | Ratio |
| --- | --- | --- | --- | --- |
| gzip | `-z` | `.gz`, `.tgz` | Fastest | Lowest |
| bzip2 | `-j` | `.bz2` | Medium | Medium |
| xz | `-J` | `.xz` | Slowest | Highest |

Mnemonic for the letters: **z**ip, **j**ay for b**j**ip2, and capital **J** for xz because it is the "bigger" one.

### Related copying tools

Occasionally useful, and `rsync` in particular is worth knowing for "securely transfer files" tasks in `09-ssh.md`.

```bash
# rsync: only transfers differences
rsync -av /source/ /dest/
rsync -avz /source/ user@server2:/dest/        # -z compresses in transit
rsync -av --delete /source/ /dest/             # mirror exactly

# cpio, still used by initramfs
find /etc -name '*.conf' | cpio -ov > /root/conf.cpio
cpio -idv < /root/conf.cpio
```

The trailing slash on an `rsync` source matters: `/source/` copies the **contents**, `/source` copies the **directory itself** into the destination.

## Exam Tips

- **`-c` create, `-x` extract, `-t` list, `-f` filename.** `-f` is always required, and exactly one of `c`/`x`/`t`.
- **`-z` gzip, `-j` bzip2, `-J` xz.** Capital J for xz.
- Extraction auto-detects compression, so `tar -xvf` handles all three. Creation does not.
- **`-C dir` changes directory first**, and that directory must already exist.
- Member names have **no leading slash**. Extract `etc/hosts`, not `/etc/hosts`.
- **`tar -tvf` before extracting anything you did not create.**
- On RHEL, add **`--xattrs --selinux --acls`** when the contexts matter.
- **`gzip`, `bzip2`, and `xz` delete the original.** Use **`-k`** to keep it, or `-c` with a redirect.
- **`-r` appends, but only to uncompressed archives.**
- Quote exclude patterns: **`--exclude='*.gz'`**.
- **`zcat`, `zless`, `zgrep`** for `.gz`; `bzcat`/`bzgrep` and `xzcat`/`xzgrep` for the others. Great for rotated logs.
- Size order: **xz < bzip2 < gzip**. Speed order is the reverse.
- `rsync -av` for copying; a trailing slash on the source copies **contents**, without it copies the **directory**.
