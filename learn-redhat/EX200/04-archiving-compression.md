# 04. Archiving And Compression

**Objective:** Archive, compress, unpack, and uncompress files using `tar`, `star`, `gzip`, and `bzip2`.

The exam wording historically mentions `star` as well. It is a legacy `tar` variant with SELinux-attribute support and is rarely installed; if a task ever asks for it, `tar --xattrs --selinux` does the same job. Focus on `tar`.

## Concept Refresher

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

## Tasks

**Task 1.** Create a gzip-compressed archive of `/etc` at `/root/etc-backup.tar.gz`, preserving SELinux contexts and extended attributes.

**Task 2.** List the contents of that archive without extracting it, showing only the first 20 entries.

**Task 3.** Extract only `etc/hosts` from the archive into `/tmp/restore`.

**Task 4.** Create a bzip2-compressed archive of `/var/log` at `/root/logs.tar.bz2`, excluding any file ending in `.gz`.

**Task 5.** Create an xz-compressed archive of `/home` at `/root/home.tar.xz`.

**Task 6.** Compare the sizes of the three archives you have created and state which compressor was most effective.

**Task 7.** Copy `/etc/services` to `/tmp/services`, then compress it with gzip while keeping the uncompressed original.

**Task 8.** Search the compressed file from Task 7 for the word `http` without decompressing it.

**Task 9.** Extract `/root/etc-backup.tar.gz` completely into `/tmp/fullrestore`, preserving permissions and SELinux contexts.

**Task 10.** Create an uncompressed archive of `/etc/ssh` at `/root/ssh.tar`, then append `/etc/hosts` to that same archive.

**Task 11.** Create a compressed archive of `/etc` that excludes `/etc/pki` and any `.key` file, at `/root/etc-safe.tar.gz`.

**Task 12.** Determine the compression ratio of `/tmp/services.gz`.

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
