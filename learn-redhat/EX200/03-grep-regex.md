# 03. grep And Regular Expressions

**Objective:** Use `grep` and regular expressions to analyze text.

This objective appears as a task in its own right ("find all lines in X that match Y and write them to Z") and inside almost every other task, because searching config files and logs is how you diagnose anything.

## Concept Refresher

### grep options that matter

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
grep -E pattern file          # extended regex (same as egrep)
grep -F pattern file          # fixed string, no regex (same as fgrep)
grep -e pat1 -e pat2 file     # multiple patterns (OR)
grep -f patterns.txt file     # patterns from a file
grep --color=auto pattern file
```

The four you will use most under time pressure: **`-i`** (case), **`-v`** (invert), **`-r`** (recursive), **`-E`** (extended).

`-w` deserves attention. `grep root /etc/passwd` also matches `chroot` and `rootkit`. `grep -w root` matches only the standalone word.

### Basic versus extended regular expressions

grep defaults to **basic** regular expressions (BRE), where several useful metacharacters must be escaped. `-E` switches to **extended** (ERE), where they do not.

| Meaning | BRE (`grep`) | ERE (`grep -E`) |
| --- | --- | --- |
| Alternation (or) | `\|` | `\|` |
| Grouping | `\(...\)` | `(...)` |
| One or more | `\+` | `+` |
| Zero or one | `\?` | `?` |
| Interval | `\{2,4\}` | `{2,4}` |

**Just use `-E`.** It saves you from escaping and it is what you already know from other tools. The only reason to know BRE is that `sed` without `-E` uses it, and you will read other people's `sed` commands.

### The metacharacters

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
\<  \>     word boundaries (start / end of word)
\b         word boundary
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
[[:punct:]]   punctuation
[[:blank:]]   space and tab only
```

```bash
grep '^[[:upper:]]' file          # lines starting with a capital
grep '[[:digit:]]\{3\}' file      # three consecutive digits (BRE)
grep -E '[[:digit:]]{3}' file     # the same in ERE
```

The outer brackets are the character class, the inner `[: :]` is the named set. `[:digit:]` alone is wrong.

### Patterns you will actually need

```bash
# Non-empty, non-comment lines: reading a config the fast way
grep -Ev '^\s*#|^\s*$' /etc/ssh/sshd_config
grep -Ev '^#|^$' /etc/chrony.conf

# Only comment lines
grep '^#' /etc/fstab

# Blank lines
grep -c '^$' file

# Lines starting with a specific word
grep '^root' /etc/passwd

# Lines ending with something
grep 'bash$' /etc/passwd
grep 'nologin$' /etc/passwd

# Exactly a whole line
grep -x 'SELINUX=enforcing' /etc/selinux/config

# An IP address (loose but fine for the exam)
grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' /var/log/messages

# An email address
grep -E '[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}' file

# Either of two words
grep -E 'error|warning' /var/log/messages
grep -Ei 'fail|error|denied' /var/log/secure

# A word, not a substring
grep -w 'root' /etc/passwd

# Repeated character
grep -E 'a{2,}' file             # two or more consecutive 'a'

# Lines with exactly 5 characters
grep -E '^.{5}$' file

# Escape a literal dot
grep '192\.168\.1\.1' file       # correct
grep '192.168.1.1' file          # also matches 192x168y1z1
```

### Combining grep with other tools

```bash
ps aux | grep -v grep | grep httpd            # exclude the grep itself
journalctl -u sshd | grep -i fail
dnf list installed | grep -i httpd
lsblk | grep -E 'disk|part'
mount | grep -w /home
grep -r 'SELINUX' /etc/ --include='*.conf'
grep -rl 'listen' /etc/httpd/ 2>/dev/null
```

`grep -v grep` is worth knowing because `ps aux | grep httpd` always finds the `grep httpd` process itself. The cleaner alternatives:

```bash
pgrep -a httpd
ps aux | grep '[h]ttpd'      # the bracket trick: the pattern no longer matches itself
```

### grep in scripts

```bash
if grep -q '^SELINUX=enforcing' /etc/selinux/config; then
  echo "SELinux set to enforce at boot"
fi

if ! grep -q "^${USERNAME}:" /etc/passwd; then
  echo "user does not exist"
fi
```

`-q` produces no output and only sets the exit status, which is exactly what `if` needs. This shows up in `33-shell-scripting.md`.

## Tasks

**Task 1.** Write all lines from `/etc/passwd` containing the string `nologin` to `/tmp/nologin.txt`.

**Task 2.** Count how many lines in `/etc/services` are neither blank nor comments.

**Task 3.** List every file under `/etc` that contains the word `SELINUX`, showing only filenames.

**Task 4.** Show the non-comment, non-blank configuration lines from `/etc/ssh/sshd_config`.

**Task 5.** Find all accounts in `/etc/passwd` whose login shell is `/bin/bash`, and write them to `/root/bash-users.txt`.

**Task 6.** Search `/var/log/secure` case-insensitively for lines containing either `fail` or `invalid`, with line numbers.

**Task 7.** Find every line in `/etc/passwd` for the user `root` as a whole word, not as a substring.

**Task 8.** Extract every IPv4 address that appears in `/etc/hosts`, printing only the addresses themselves.

**Task 9.** Count how many lines in `/etc/fstab` are active configuration, that is, not comments and not blank.

**Task 10.** Show all lines in `/etc/login.defs` that set a `PASS_` variable, with the three lines following each match.

**Task 11.** List the names of all `.conf` files under `/etc` that do **not** contain the string `Port`.

**Task 12.** Find all lines in `/etc/passwd` where the UID field is exactly four digits.

**Task 13.** In `/var/log/messages`, find lines that mention `kernel` but not `usb`.

**Task 14.** Write a one-line test that prints `ENFORCING` if `/etc/selinux/config` is set to enforcing at boot, and `NOT ENFORCING` otherwise.

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
