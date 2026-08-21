# 03. grep And Regular Expressions

**Objective:** Use `grep` and regular expressions to analyze text.

This objective appears as a task in its own right ("find all lines in X that match Y and write them to Z") and inside almost every other task, because searching config files and logs is how you diagnose anything.

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Reading thirty grep flags upfront feels like learning. Typing them one at a time actually is.

---

## Follow Along

Work on your lab VM. After each step, compare your output to **You should see**.

### 1. Search for a plain string

```bash
grep root /etc/passwd
```

**You should see** several lines — every line in `/etc/passwd` that contains the letters `root` anywhere.

`grep` prints **whole lines** that match, not just the matching word.

### 2. Case-insensitive search (`-i`)

```bash
grep -i selinux /etc/selinux/config
grep -i SELINUX /etc/selinux/config
```

**You should see** the same lines from both commands.

Use `-i` when you are not sure how something is capitalised in a config file.

### 3. Line numbers (`-n`)

```bash
grep -n root /etc/passwd
```

**You should see** each match prefixed with a line number, like `1:root:x:0:0:...`.

Useful in logs when someone says "check line 482".

### 4. Lines that do NOT match (`-v`)

```bash
grep -v nologin /etc/passwd | head
```

**You should see** accounts whose shell is **not** `nologin` — the first ten of them because of `| head`.

`-v` **inverts** the match. "Show me everything except this."

### 5. Count matching lines (`-c`)

```bash
grep -c nologin /etc/passwd
grep -cv nologin /etc/passwd
```

**You should see** two different numbers. The first counts lines **with** `nologin`. The second counts lines **without** it (`-v` plus `-c` together).

On the exam, read carefully: "count lines that match" versus "count lines that are not comments or blank".

### 6. Start and end of a line (`^` and `$`)

```bash
grep '^root' /etc/passwd
grep 'bash$' /etc/passwd
```

**You should see:**

- First command: only lines that **start** with `root`.
- Second command: only lines whose **last field** ends with `bash` (login shells).

`^` = start of line. `$` = end of line. These are regex anchors, not shell syntax.

Compare:

```bash
grep root /etc/passwd | wc -l
grep -w root /etc/passwd | wc -l
```

**You should see** the second count is smaller or equal. `-w` matches **whole words** only, so `chroot` and `rootkit` are excluded.

### 7. Extended regex and alternation (`-E` and `|`)

Always prefer `-E`. It saves escaping.

```bash
grep -E 'error|warning' /var/log/messages | tail
```

**You should see** recent log lines containing either word (if the file exists and has content; an empty result is fine on a fresh VM).

Without `-E`, the `|` is literal in basic regex. With `-E`, it means **or**.

Try the config-file idiom — the single most useful grep on the exam:

```bash
grep -Ev '^\s*#|^\s*$' /etc/ssh/sshd_config | head
```

**You should see** only **active** settings — no comment lines, no blank lines.

Reading the pattern:

- `-E` — extended regex
- `-v` — invert (we will flip this in a moment for a different use)
- `^\s*#` — line starts with optional whitespace then `#`
- `|` — or
- `^\s*$` — blank or whitespace-only line

Wait — we used `-v`, so grep shows lines that do **not** match comments or blanks. That is exactly "show me real config".

Count active lines in `/etc/fstab`:

```bash
grep -Evc '^\s*#|^\s*$' /etc/fstab
```

**You should see** a small integer (how many real mount entries you have).

### 8. Recursive search and filenames only (`-r`, `-l`)

```bash
sudo grep -r SELINUX /etc/selinux/ 2>/dev/null | head
sudo grep -rl SELINUX /etc/selinux/ 2>/dev/null
```

**You should see:**

- First: matching **lines** with filenames prefixed.
- Second: only **filenames** that contain a match.

`-l` stops reading each file after the first hit — much faster across all of `/etc`.

### 9. Print only the match (`-o`)

```bash
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' /etc/hosts
```

**You should see** just IP addresses, not the whole line.

`-o` = "output only the part that matched". The pattern is a loose IPv4 matcher: one to three digits, dot, three times, then one to three digits.

**Important:** a dot in regex means "any character". For a literal dot, escape it: `192\.168\.1\.1`.

### 10. Context lines (`-A`, `-B`, `-C`)

```bash
grep -A2 '^PASS_' /etc/login.defs
```

**You should see** each line starting with `PASS_` plus the **two lines after** it.

`-A3` = after, `-B3` = before, `-C3` = both sides.

### 11. grep in a pipeline

```bash
grep '/bin/bash$' /etc/passwd | wc -l
grep '/bin/bash$' /etc/passwd | cut -d: -f1
```

**You should see** a count, then a list of usernames only.

You already know pipes from `02-redirection-pipes.md`. grep is the filter you will pipe most often.

### 12. Quiet mode for tests (`-q`)

```bash
grep -q '^SELINUX=enforcing' /etc/selinux/config && echo ENFORCING || echo "NOT ENFORCING"
```

**You should see** either `ENFORCING` or `NOT ENFORCING`.

`-q` produces no output — only an exit status. Scripts and one-liners use this constantly.

### Mini checkpoint

Before the practice tasks, you should be able to explain:

| Flag | Does |
| --- | --- |
| `-i` | ignore case |
| `-v` | invert (non-matching lines) |
| `-c` | count lines |
| `-n` | line numbers |
| `-r` | recursive |
| `-l` | filenames only |
| `-E` | extended regex (use this) |
| `-w` | whole word |
| `-o` | print match only |
| `-q` | silent, exit status only |

If any row is blank in your head, re-run the step above that covers it.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Write all lines from `/etc/passwd` containing the string `nologin` to `/tmp/nologin.txt`.

> Hint: plain grep, output redirection from `02-redirection-pipes.md`.

**Task 2.** Count how many lines in `/etc/services` are neither blank nor comments.

> Hint: `-E`, `-v`, `-c`, and the comment-or-blank pattern from step 7.

**Task 3.** List every file under `/etc` that contains the word `SELINUX`, showing only filenames.

> Hint: `-r`, `-l`, and `2>/dev/null` for permission noise.

**Task 4.** Show the non-comment, non-blank configuration lines from `/etc/ssh/sshd_config`.

> Hint: the idiom from follow-along step 7, without `-c`.

**Task 5.** Find all accounts in `/etc/passwd` whose login shell is `/bin/bash`, and write them to `/root/bash-users.txt`.

> Hint: `$` anchor on the shell field; use `sudo tee` if redirecting to `/root/`.

**Task 6.** Search `/var/log/secure` case-insensitively for lines containing either `fail` or `invalid`, with line numbers.

> Hint: combine `-n`, `-i`, `-E`, and `|`.

**Task 7.** Find every line in `/etc/passwd` for the user `root` as a whole word, not as a substring.

> Hint: `-w`, or stricter: `'^root:'`.

**Task 8.** Extract every IPv4 address that appears in `/etc/hosts`, printing only the addresses themselves.

> Hint: `-o` and `-E` from step 9.

**Task 9.** Count how many lines in `/etc/fstab` are active configuration, that is, not comments and not blank.

> Hint: same pattern as Task 2.

**Task 10.** Show all lines in `/etc/login.defs` that set a `PASS_` variable, with the three lines following each match.

> Hint: `-A3` and `^` anchor from step 10.

**Task 11.** List the names of all `.conf` files under `/etc` that do **not** contain the string `Port`.

> Hint: `-L` is the opposite of `-l`; restrict with `--include='*.conf'`.

**Task 12.** Find all lines in `/etc/passwd` where the UID field is exactly four digits.

> Hint: fields are colon-separated; `[^:]*` skips one field; `{4}` needs `-E`.

**Task 13.** In `/var/log/messages`, find lines that mention `kernel` but not `usb`.

> Hint: two greps in a pipe is normal and acceptable.

**Task 14.** Write a one-line test that prints `ENFORCING` if `/etc/selinux/config` is set to enforcing at boot, and `NOT ENFORCING` otherwise.

> Hint: follow-along step 12.

---

## Solutions

**Task 1.**

```bash
grep nologin /etc/passwd > /tmp/nologin.txt
wc -l /tmp/nologin.txt
```

**Task 2.**

```bash
grep -Evc '^\s*#|^\s*$' /etc/services
```

Reading the pattern: `-E` for extended regex, `-v` to invert, `-c` to count. `^\s*#` is "optional whitespace then a hash", which catches indented comments that `^#` would miss. `^\s*$` is a blank or whitespace-only line.

Note that combining `-v` and `-c` counts the lines that **do not** match, which is what was asked.

**Task 3.**

```bash
sudo grep -rl SELINUX /etc 2>/dev/null
```

`-l` prints filenames only and stops reading each file after the first match, which makes it much faster than a full search. `2>/dev/null` hides unreadable-file noise.

**Task 4.**

```bash
grep -Ev '^\s*#|^\s*$' /etc/ssh/sshd_config
```

This is the single most useful grep on the exam. Configuration files ship with hundreds of commented lines, and this shows you the handful that are actually in effect. Use it on `sshd_config`, `chrony.conf`, `smb.conf`, and `httpd.conf`.

**Task 5.**

```bash
grep '/bin/bash$' /etc/passwd | sudo tee /root/bash-users.txt
```

The `$` anchor matters. Without it you would also match a hypothetical `/bin/bash-old`. To get just the usernames:

```bash
grep '/bin/bash$' /etc/passwd | cut -d: -f1 | sudo tee /root/bash-users.txt
```

**Task 6.**

```bash
sudo grep -niE 'fail|invalid' /var/log/secure
```

`-n` numbers, `-i` ignores case, `-E` enables the `|` alternation without escaping. In BRE this would be `grep -ni 'fail\|invalid'`.

**Task 7.**

```bash
grep -w root /etc/passwd
```

Compare the outputs of `grep root /etc/passwd` and `grep -w root /etc/passwd`. Anchoring to the start of the line is another approach and is stricter still:

```bash
grep '^root:' /etc/passwd
```

**Task 8.**

```bash
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' /etc/hosts
```

`-o` prints only the matched portion rather than the whole line. The pattern is "one to three digits followed by a dot, three times, then one to three digits". The `\.` escapes are essential; an unescaped `.` matches any character.

**Task 9.**

```bash
grep -Evc '^\s*#|^\s*$' /etc/fstab
```

Same idiom as Task 2. This is a genuinely useful check after editing `fstab`, since it tells you how many active entries you have and whether that matches your expectation.

**Task 10.**

```bash
grep -A3 '^PASS_' /etc/login.defs
```

If the settings are commented in your build, add `-i` and loosen the anchor:

```bash
grep -A3 -iE '^#?\s*PASS_' /etc/login.defs
```

`-A` for after, `-B` for before, `-C` for both. Useful when a setting's meaning is in the comment underneath it.

**Task 11.**

```bash
sudo grep -rL Port /etc --include='*.conf' 2>/dev/null
```

`-L` is the inverse of `-l`: filenames with **no** match. `--include` restricts the recursive search by filename pattern, which is much faster than searching all of `/etc`.

**Task 12.**

```bash
grep -E '^[^:]*:[^:]*:[0-9]{4}:' /etc/passwd
```

Reading it: start of line, then any non-colon characters (username), a colon, non-colon characters (password field), a colon, then exactly four digits, then a colon. `[^:]*` is the idiomatic way to skip a field.

A more readable equivalent using `awk`:

```bash
awk -F: 'length($3)==4' /etc/passwd
```

On the exam, use whichever you can write correctly on the first attempt. Both are acceptable.

**Task 13.**

```bash
sudo grep kernel /var/log/messages | grep -v usb
```

Two greps, because a single regex for "contains A but not B" is awkward. Chaining an inverted grep is the normal approach and is perfectly good practice.

**Task 14.**

```bash
grep -q '^SELINUX=enforcing' /etc/selinux/config && echo ENFORCING || echo "NOT ENFORCING"
```

`-q` gives you the exit status with no output. This exact pattern reappears in `33-shell-scripting.md` for shell scripting and is how you write conditional checks against config files.

---

## Verify

```bash
wc -l /tmp/nologin.txt
sudo cat /root/bash-users.txt
grep -Evc '^\s*#|^\s*$' /etc/fstab
```

## Persistence Check

Nothing here requires persistence. But the idiom below is one you will use to **verify** persistent work in every later file:

```bash
# Confirm a setting is actually written to disk, not just active in memory
grep -E '^SELINUX=' /etc/selinux/config
grep -Ev '^\s*#|^\s*$' /etc/fstab
grep "^${USER}:" /etc/passwd
```

## Quick Reference

Come back here when you need a flag you forgot — not before your first pass through Follow Along.

### grep options

```bash
grep pattern file
grep -i pattern file          # case-insensitive
grep -v pattern file          # INVERT: lines that do NOT match
grep -c pattern file          # count matching LINES (not matches)
grep -n pattern file          # show line numbers
grep -l pattern *.conf        # list only FILENAMES that match
grep -L pattern *.conf        # list filenames that do NOT match
grep -r pattern /etc          # recursive
grep -ri pattern /etc         # recursive, case-insensitive
grep -w pattern file          # match WHOLE WORDS only
grep -x pattern file          # match the WHOLE LINE
grep -A3 pattern file         # 3 lines AFTER each match
grep -B3 pattern file         # 3 lines BEFORE
grep -C3 pattern file         # 3 lines of CONTEXT either side
grep -o pattern file          # print only the matched part, not the line
grep -q pattern file          # QUIET: no output, just an exit status. For scripts
grep -E pattern file          # extended regex (same as egrep) — use this
grep -F pattern file          # fixed string, no regex (same as fgrep)
grep -e pat1 -e pat2 file     # multiple patterns (OR)
grep -f patterns.txt file     # patterns from a file
grep --color=auto pattern file
grep -r pattern /etc --include='*.conf'   # limit recursive search by filename
```

The four you will use most under time pressure: **`-i`**, **`-v`**, **`-r`**, **`-E`**.

### Basic versus extended regular expressions

grep defaults to **basic** regular expressions (BRE), where several useful metacharacters must be escaped. `-E` switches to **extended** (ERE), where they do not.

| Meaning | BRE (`grep`) | ERE (`grep -E`) |
| --- | --- | --- |
| Alternation (or) | `\|` | `\|` |
| Grouping | `\(...\)` | `(...)` |
| One or more | `\+` | `+` |
| Zero or one | `\?` | `?` |
| Interval | `\{2,4\}` | `{2,4}` |

**Just use `-E`.** The only reason to know BRE is that `sed` without `-E` uses it.

### Metacharacters

```text
.          any single character
*          zero or more of the PREVIOUS item
+          one or more            (ERE, or \+ in BRE)
?          zero or one            (ERE, or \? in BRE)
^          start of line
$          end of line
[abc]      any one of a, b, c
[^abc]     any character NOT a, b, or c
[a-z]      range
[0-9]      digit range
{n}        exactly n times
{n,}       n or more
{n,m}      between n and m
|          alternation             (ERE, or \| in BRE)
()         grouping                (ERE, or \(\) in BRE)
\          escape the next character
```

### Character classes

Portable and clearer than ranges. Note the **double** brackets.

```text
[[:alpha:]]   letters
[[:digit:]]   0-9
[[:alnum:]]   letters and digits
[[:space:]]   whitespace incl. tab
[[:upper:]]   uppercase
[[:lower:]]   lowercase
```

```bash
grep '^[[:upper:]]' file          # lines starting with a capital
grep -E '[[:digit:]]{3}' file     # three consecutive digits
```

### Common patterns

```bash
grep -Ev '^\s*#|^\s*$' file       # active config lines only
grep '^#' file                    # comment lines only
grep -w 'root' /etc/passwd        # whole word
grep -E 'error|warning' logfile   # either word
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' file   # IPv4 addresses
grep -E '^[^:]*:[^:]*:[0-9]{4}:' /etc/passwd # four-digit UID field
```

### Combining grep with other tools

```bash
ps aux | grep -v grep | grep httpd            # exclude the grep itself
journalctl -u sshd | grep -i fail
pgrep -a httpd                                 # cleaner than ps | grep
ps aux | grep '[h]ttpd'                          # bracket trick
```

### grep in scripts

```bash
if grep -q '^SELINUX=enforcing' /etc/selinux/config; then
  echo "SELinux set to enforce at boot"
fi
```

## Exam Tips

- **Use `-E`.** It removes almost all backslash escaping. `grep -E 'a|b'` versus `grep 'a\|b'`.
- **`grep -Ev '^\s*#|^\s*$' file`** shows you a config file's real content. Memorise this one string.
- **`-i`** case, **`-v`** invert, **`-c`** count lines, **`-n`** line numbers, **`-r`** recursive, **`-l`** filenames only, **`-L`** filenames without a match, **`-o`** only the match, **`-q`** quiet for scripts, **`-w`** whole word.
- `-v -c` together counts **non-matching** lines.
- **`-A`/`-B`/`-C`** for context lines around a match.
- **`-w`** matters: `grep root` also matches `chroot`.
- **Escape literal dots.** `192\.168\.1\.1`, not `192.168.1.1`.
- Character classes need **double brackets**: `[[:digit:]]`, not `[:digit:]`.
- `[^:]*` is how you skip a colon-delimited field in a regex.
- Anchors: **`^` start, `$` end, `-x` whole line.**
- `--include='*.conf'` makes recursive searches dramatically faster.
- **`grep -q ... && echo yes || echo no`** is the config-check idiom for scripts.
- For processes, prefer **`pgrep -a name`** over `ps aux | grep name`, or use the `'[n]ame'` bracket trick.
- BRE needs `\+`, `\?`, `\{n\}`, `\(\)`, `\|`. ERE does not. `sed` without `-E` is BRE.
