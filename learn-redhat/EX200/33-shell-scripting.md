# 33. Shell Scripting

**Objectives:**
- Conditionally execute code (use of: if, test, [], etc.)
- Use Looping constructs (for, etc.) to process file, command line input
- Process script inputs ($1, $2, etc.)
- Processing output of shell commands within a script

**A single scripting task on the exam is usually worth a meaningful number of points**, and it is entirely self-contained — no reboot dependency, no firewall, no SELinux. Get the script right and the marks are yours.

**The most common way to lose them is forgetting `chmod +x`.**

## Before You Start

You need a running lab VM. If you have not built one yet, do `Lab-Setup.md` first.

```bash
vagrant ssh server1    # or ssh into your practice VM
```

**How to use this file:**

1. **Follow Along** — type every command in order. One idea per step. Do not skip ahead.
2. **Practice Tasks** — try these yourself before reading Solutions. They are worded like the exam.
3. **Quick Reference** — cheat sheet for review. Come back here after the follow-along, not before.

Reading every bash construct upfront feels like learning. Typing them one at a time actually is.

---

## Follow Along

Work on your lab VM as root (or with `sudo`). After each step, compare your output to **You should see**.

### 1. Write your first script — shebang and `chmod +x`

Every script needs three things: a shebang on line 1, the execute bit, and `./` or an absolute path to run it.

```bash
sudo tee /root/demo-hello.sh >/dev/null <<'EOF'
#!/bin/bash
echo "Hello from a script"
EOF
sudo chmod +x /root/demo-hello.sh
ls -l /root/demo-hello.sh
sudo /root/demo-hello.sh
```

**You should see** `-rwxr-xr-x` in the permissions (the `x` bits) and the line `Hello from a script`.

The shebang `#!/bin/bash` must be the **very first line** — no blank line or comment before it. Without it, the script may run under `sh`, where `[[ ]]`, `=~`, and other bashisms fail.

Try without the execute bit:

```bash
sudo chmod -x /root/demo-hello.sh
sudo /root/demo-hello.sh
sudo chmod +x /root/demo-hello.sh
```

**You should see** `command not found` or `Permission denied` without `+x`. **`bash /root/demo-hello.sh` works without the bit, but a grader expects `chmod +x`.** Always confirm with `ls -l`.

### 2. Positional parameters — `$0`, `$1`, `$#`, `"$@"`

Scripts receive arguments as numbered parameters.

```bash
sudo tee /root/demo-args.sh >/dev/null <<'EOF'
#!/bin/bash
echo "Script name : $0"
echo "First arg   : $1"
echo "Second arg  : $2"
echo "Arg count   : $#"
echo "All args    : $@"
EOF
sudo chmod +x /root/demo-args.sh
sudo /root/demo-args.sh alpha beta gamma
```

**You should see** the script name, `alpha`, `beta`, count `3`, and all three arguments listed.

| Variable | Meaning |
| --- | --- |
| `$0` | The script's own name |
| **`$1`, `$2`, `$3`** | **The first, second, third argument** |
| `${10}` | **The tenth — braces required beyond 9** |
| **`$#`** | **The number of arguments** |
| **`$@`** | **All arguments, each separately quoted** |
| `$*` | All arguments as one string |
| `$?` | **The exit status of the last command** |

**`"$@"` and `"$*"` differ:**

```bash
sudo tee /root/demo-at.sh >/dev/null <<'EOF'
#!/bin/bash
echo '--- "$@" ---'
for a in "$@"; do echo "[$a]"; done
echo '--- "$*" ---'
for a in "$*"; do echo "[$a]"; done
EOF
sudo chmod +x /root/demo-at.sh
sudo /root/demo-at.sh one "two three" four
```

**You should see** three bracketed items under `"$@"` (with `two three` as one) and **one** item under `"$*"` (everything joined). **Use `"$@"` almost always.**

When writing a script via heredoc, use `<<'EOF'` with quotes so `$1` is not expanded while *writing* the file.

### 3. The usage-check idiom

Exam tasks often say "print a usage message if no argument is given."

```bash
sudo tee /root/demo-usage.sh >/dev/null <<'EOF'
#!/bin/bash
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <filename>" >&2
    exit 1
fi
echo "Processing: $1"
EOF
sudo chmod +x /root/demo-usage.sh
sudo /root/demo-usage.sh
echo "exit status: $?"
sudo /root/demo-usage.sh myfile
echo "exit status: $?"
```

**You should see** the usage message on stderr with exit status `1`, then `Processing: myfile` with status `0`.

Three details graders check: **`>&2`** sends errors to stderr, **`exit 1`** is non-zero failure, **`$#`** is the argument count. Use `-ne 1` for exactly one argument; `-lt 1` for at least one.

`shift` moves parameters down when consuming arguments:

```bash
while [[ $# -gt 0 ]]; do
    echo "Processing: $1"
    shift
done
```

### 4. Conditionals and file tests

Use `[[ ]]` in bash scripts — safer with empty variables and supports `=~` and `&&`.

```bash
sudo tee /root/demo-filetest.sh >/dev/null <<'EOF'
#!/bin/bash
TARGET="${1:-/etc/passwd}"
if [[ -f "$TARGET" ]]; then
    echo "$TARGET is a regular file"
elif [[ -d "$TARGET" ]]; then
    echo "$TARGET is a directory"
elif [[ -e "$TARGET" ]]; then
    echo "$TARGET exists but is neither file nor directory"
else
    echo "$TARGET does not exist" >&2
    exit 1
fi
EOF
sudo chmod +x /root/demo-filetest.sh
sudo /root/demo-filetest.sh /etc/passwd
sudo /root/demo-filetest.sh /etc
sudo /root/demo-filetest.sh /nonexistent; echo "status: $?"
```

**You should see** "regular file" for `/etc/passwd`, "directory" for `/etc`, and an error for `/nonexistent`.

| Test | True when |
| --- | --- |
| **`-f FILE`** | **Exists and is a regular file** |
| **`-d DIR`** | **Exists and is a directory** |
| **`-e PATH`** | **Exists, any type** |
| `-r`, `-w`, `-x` | Readable / writable / executable |
| `-z STRING` | **The string is empty** |
| `-n STRING` | The string is non-empty |

**Order matters:** test `-d` before `-f`, and `-e` last. **Quote variables:** `[[ -f "$file" ]]`.

Three test syntaxes exist: `test EXPR`, `[ EXPR ]` (spaces mandatory), **`[[ EXPR ]]`** (bash — use this), and **`(( EXPR ))`** (arithmetic).

### 5. Numeric comparison — and the `>` trap

Numbers use `-eq`, `-lt`, `-gt`; strings use `=`, `!=`. Inside `[ ]`, `>` performs *redirection* and creates a file:

```bash
sudo tee /root/demo-numtest.sh >/dev/null <<'EOF'
#!/bin/bash
NUM="${1:-5}"
if [[ $NUM -lt 10 ]]; then
    echo "$NUM is less than 10"
elif [[ $NUM -eq 10 ]]; then
    echo "$NUM equals 10"
else
    echo "$NUM is greater than 10"
fi
EOF
sudo chmod +x /root/demo-numtest.sh
sudo /root/demo-numtest.sh 5
sudo /root/demo-numtest.sh 10
sudo /root/demo-numtest.sh 42
```

**You should see** less than, equal to, and greater than messages for the three runs.

| String | Numeric | Meaning |
| --- | --- | --- |
| `=` or `==` | **`-eq`** | Equal |
| `!=` | **`-ne`** | Not equal |
| `<` | **`-lt`** | Less than |
| `>` | **`-gt`** | Greater than |
| | **`-le`, `-ge`** | Less/greater or equal |

The arithmetic form is also available: `if (( NUM < 10 )); then` and `(( count++ ))`.

Regex matching (bash only, inside `[[ ]]`):

```bash
if [[ "$input" =~ ^[0-9]+$ ]]; then echo "numeric"; fi
```

### 6. `for` loops — lists and ranges

```bash
sudo tee /root/demo-for.sh >/dev/null <<'EOF'
#!/bin/bash
echo "Literal list:"
for i in one two three; do echo "  $i"; done
echo "Range 1-5:"
for i in {1..5}; do echo "  $i"; done
echo "Evens 2-10:"
for i in {2..10..2}; do echo "  $i"; done
EOF
sudo chmod +x /root/demo-for.sh
sudo /root/demo-for.sh
```

**You should see** three words, numbers 1 through 5, then even numbers 2, 4, 6, 8, 10.

C-style loops work when the limit is a variable (brace expansion `{1..$n}` does **not** expand `$n`):

```bash
n=5
for (( i=1; i<=n; i++ )); do echo "$i"; done
```

Loop control: `continue` skips an iteration; `break` leaves the loop.

### 7. Loop over files and command output

The glob must be **unquoted** so the shell expands it:

```bash
sudo tee /root/demo-glob.sh >/dev/null <<'EOF'
#!/bin/bash
for f in /etc/*.conf; do
    [[ -f "$f" ]] || continue
    lines=$(wc -l < "$f")
    printf "%-30s %5d\n" "$f" "$lines"
done | head -5
EOF
sudo chmod +x /root/demo-glob.sh
sudo /root/demo-glob.sh
```

**You should see** up to five `.conf` files with line counts. If no files match, bash passes the literal pattern — the `[[ -f "$f" ]]` guard skips it.

Command output in a loop:

```bash
for u in $(cut -d: -f1 /etc/passwd); do echo "$u"; done | head -3
```

**You should see** the first three usernames from `/etc/passwd`.

### 8. `while read` — process a file line by line

**Never `for line in $(cat file)`** — it splits on whitespace, not lines.

```bash
sudo tee /root/demo-users.txt >/dev/null <<'EOF'
root
bin
nosuchuser_xyz
EOF

sudo tee /root/demo-read.sh >/dev/null <<'EOF'
#!/bin/bash
while read -r name; do
    [[ -z "$name" ]] && continue
    if id "$name" &>/dev/null; then
        echo "EXISTS  : $name"
    else
        echo "MISSING : $name"
    fi
done < /root/demo-users.txt
EOF
sudo chmod +x /root/demo-read.sh
sudo /root/demo-read.sh
```

**You should see** EXISTS for `root` and `bin`, MISSING for `nosuchuser_xyz`.

| Element | Why |
| --- | --- |
| **`-r`** | **Do not interpret backslashes — always use it** |
| **`< "$FILE"` after `done`** | **Not a pipe — avoids subshell** |
| `[[ -z "$line" ]] && continue` | Skip blank lines |

**Piping into `while` runs the loop in a subshell** — variables set inside are lost afterwards. Use `< file` or `< <(command)` instead.

### 9. Command substitution and arithmetic

Capture command output with `$(...)`, not backticks:

```bash
sudo tee /root/demo-subst.sh >/dev/null <<'EOF'
#!/bin/bash
count=$(ls /etc | wc -l)
today=$(date +%F)
host=$(hostname -s)
echo "Host $host has $count entries in /etc as of $today"
total=$(( 5 + 3 ))
echo "5 + 3 = $total"
echo "10 / 3 = $(( 10 / 3 ))"
EOF
sudo chmod +x /root/demo-subst.sh
sudo /root/demo-subst.sh
```

**You should see** host info, `5 + 3 = 8`, and `10 / 3 = 3` (integer division only — use `bc` or `awk` for decimals).

Quoting matters:

| Form | Behaviour |
| --- | --- |
| `"$var"` | **Expands. Use this** |
| `'$var'` | Literal, no expansion |
| `$var` | Expands, but **word-splits on whitespace** |
| `"$(cmd)"` | Expands command output, preserving spaces |

**Quote every variable expansion unless you specifically want word splitting.**

### 10. Exit status — `if command; then`

Test a command's success directly — no `[[ ]]` needed:

```bash
sudo tee /root/demo-exit.sh >/dev/null <<'EOF'
#!/bin/bash
if grep -q root /etc/passwd; then
    echo "root account found"
fi
if ! systemctl is-active --quiet sshd; then
    echo "sshd is not running"
else
    echo "sshd is active"
fi
command && echo "&& worked" || echo "|| failed"
EOF
sudo chmod +x /root/demo-exit.sh
sudo /root/demo-exit.sh
grep -q root /etc/passwd; echo "grep exit status: $?"
```

**You should see** root found, sshd status, and `grep exit status: 0`. **`$?` is 0 for success, non-zero for failure.**

Many commands are designed for this: `systemctl is-active --quiet`, `id user &>/dev/null`, `grep -q`, `rpm -q`.

Exiting: `exit 0` success, `exit 1` failure. Errors go to stderr: `echo "Error" >&2`.

### 11. `case` for subcommands

Clearer than a chain of `elif` when matching one variable against fixed values:

```bash
sudo tee /root/demo-case.sh >/dev/null <<'EOF'
#!/bin/bash
case "$1" in
    start)   echo "starting" ;;
    stop)    echo "stopping" ;;
    restart) echo "restarting" ;;
    *)       echo "Usage: $0 {start|stop|restart}" >&2; exit 1 ;;
esac
EOF
sudo chmod +x /root/demo-case.sh
sudo /root/demo-case.sh start
sudo /root/demo-case.sh bogus; echo "status: $?"
```

**You should see** `starting`, then a usage message with status `1`. Note **`;;`** at each branch end and **`esac`** to close. Patterns are globs, not regexes. Put `*)` last.

### 12. Parameter expansion — defaults and trimming

```bash
sudo tee /root/demo-params.sh >/dev/null <<'EOF'
#!/bin/bash
TARGET="${1:-/var}"
COUNT="${2:-5}"
echo "Target: $TARGET  Count: $COUNT"
FILE="/var/log/messages.log"
echo "Basename: ${FILE##*/}"
echo "Dirname:  ${FILE%/*}"
echo "No .log:  ${FILE%.log}"
EOF
sudo chmod +x /root/demo-params.sh
sudo /root/demo-params.sh
sudo /root/demo-params.sh /usr 3
```

**You should see** default `/var` and `5`, then `/usr` and `3`, plus basename/dirname trimming.

| Form | Behaviour |
| --- | --- |
| **`${1:-default}`** | **Use `default` if `$1` is unset or empty** |
| `${1-default}` | Use `default` only if `$1` is unset |
| **`${1:?message}`** | **Error and exit if unset** |
| `${var%pattern}` | Remove shortest match from end |
| `${var##pattern}` | Remove longest match from start |

### 13. Debug a silent script

When a script produces no output, trace it:

```bash
sudo tee /root/demo-broken.sh >/dev/null <<'EOF'
#!/bin/bash
FILE=/root/no-such-file.txt
if [ -f $FILE ]; then
    echo "file exists"
fi
EOF
sudo chmod +x /root/demo-broken.sh
sudo /root/demo-broken.sh
bash -x /root/demo-broken.sh
bash -n /root/demo-broken.sh && echo "syntax OK"
```

**You should see** no output from the script itself. **`bash -x`** shows the `[ -f ... ]` test was false — the file does not exist, so the body never ran.

| Technique | Finds |
| --- | --- |
| **`bash -n script`** | **Syntax errors without running** |
| **`bash -x script`** | **Which commands ran and with what values** |
| `set -x` / `set +x` | Trace a specific section |
| **`set -u`** | **Undefined variable use** |
| `set -euo pipefail` | Exit on error, undefined vars, pipeline failures |

Common silent failures: missing file (condition false), no `chmod +x`, CRLF line endings (`sed -i 's/\r$//'`), unquoted empty variables in `[ ]`.

### 14. A complete example — everything together

This script uses argument checks, file tests, `while read`, exit status, and counters:

```bash
sudo tee /root/demo-batch.sh >/dev/null <<'EOF'
#!/bin/bash
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <userfile>" >&2
    exit 1
fi
USERFILE="$1"
if [[ ! -f "$USERFILE" ]]; then
    echo "Error: $USERFILE does not exist" >&2
    exit 2
fi
created=0
skipped=0
while read -r username; do
    [[ -z "$username" ]] && continue
    [[ "$username" =~ ^# ]] && continue
    if id "$username" &>/dev/null; then
        echo "SKIP: $username"
        (( skipped++ ))
    else
        useradd "$username" 2>/dev/null && echo "OK: $username"
        (( created++ ))
    fi
done < "$USERFILE"
echo "Created: $created  Skipped: $skipped"
exit 0
EOF
sudo chmod +x /root/demo-batch.sh
```

**You should see** the script created with execute permission. Run it only if you have a user list ready — the pattern is what matters for the exam.

### Mini checkpoint

Before the practice tasks, you should be able to explain:

| Concept | Key point |
| --- | --- |
| Shebang | `#!/bin/bash` on line 1, no blank line before |
| Execute bit | `chmod +x` — confirm with `ls -l` |
| Positional params | `$1`, `$#`, `"$@"` (not `"$*"`) |
| Usage idiom | `if [[ $# -ne 1 ]]; then echo "Usage..." >&2; exit 1; fi` |
| File tests | `-f` file, `-d` dir, `-e` exists; quote `"$var"` |
| Numeric compare | `-eq -lt -gt` for numbers; `>` inside `[ ]` redirects |
| `for` loops | `{1..10}` literal only; use `seq` or `(( ))` for variables |
| `while read` | `done < file` with `-r`; never `for x in $(cat file)` |
| Subshell trap | Never pipe into `while` if you need variables after |
| Command subst | `$(cmd)` not backticks; `"$var"` always |
| Exit status | `if command; then`; `$?`; `exit 1` for failure |
| `case` | `;;` per branch, `*)` last, `esac` to close |
| Param expansion | `${1:-default}`, `${var##*/}`, `${var%pattern}` |
| Debugging | `bash -n` syntax, `bash -x` trace, `set -u` for typos |

If any row is blank in your head, re-run the step above that covers it.

---

## Practice Tasks

Do these **before** reading Solutions. If you are stuck for more than five minutes, peek at the hint — not the full answer.

**Task 1.** Write a script at `/root/hello.sh` that prints "Hello, World", make it executable, and run it. Show what happens if you forget the execute bit.

> Hint: shebang, `echo`, `chmod +x`, confirm with `ls -l`. Follow-along step 1.

**Task 2.** Write a script that prints its own name, its first two arguments, and how many arguments it received.

> Hint: `$0`, `$1`, `$2`, `$#`, `"$@"`. Follow-along step 2.

**Task 3.** Write a script that requires exactly one argument, printing a usage message to stderr and exiting non-zero otherwise.

> Hint: the usage idiom with `$# -ne 1`, `>&2`, and `exit 1`. Follow-along step 3.

**Task 4.** Write a script that takes a path as an argument and reports whether it is a regular file, a directory, or does not exist.

> Hint: test `-d` before `-f`, then `-e`; quote `"$1"`. Follow-along step 4.

**Task 5.** Write a script that takes a number and prints whether it is less than, equal to, or greater than 10.

> Hint: `-lt`, `-eq`, `-gt` inside `[[ ]]`. Follow-along step 5.

**Task 6.** Write a script that loops through the numbers 1 to 10 and prints only the even ones.

> Hint: `for i in {1..10}` with modulo, `{2..10..2}`, or `continue`. Follow-along step 6.

**Task 7.** Write a script that loops over every `.conf` file in `/etc` and prints the filename and its line count.

> Hint: unquoted glob, `[[ -f "$f" ]]`, `wc -l < "$f"`, `printf`. Follow-along step 7.

**Task 8.** Write a script that reads `/root/users.txt` line by line and reports for each name whether that user exists on the system.

> Hint: `while read -r`, `id "$name" &>/dev/null`. Follow-along step 8.

**Task 9.** Write a script that creates every user listed in a file given as an argument, skipping any that already exist, and reports a count at the end.

> Hint: `$1` and `$#`, `while read`, `useradd`, `if id ...; then`. Follow-along step 14.

**Task 10.** Write a script that accepts any number of arguments and processes each one, correctly handling arguments that contain spaces.

> Hint: `for arg in "$@"` — compare with `$@` and `"$*"`. Follow-along step 2.

**Task 11.** Write a script that captures the output of a command into a variable and uses it in a calculation.

> Hint: `$(command)` and `$(( ))` arithmetic. Follow-along step 9.

**Task 12.** Write a script that tests whether a service is active and reports accordingly, using the command's exit status rather than parsing its output.

> Hint: `systemctl is-active --quiet`, `if command; then`. Follow-along step 10.

**Task 13.** Write a script implementing `start`, `stop`, and `status` subcommands using `case`.

> Hint: `case "$1" in ... ;; esac` with `*)` catch-all. Follow-along step 11.

**Task 14.** Write a script that reports the top five largest directories under a path given as an argument, defaulting to `/var` if none is given.

> Hint: `${1:-/var}`, `du`, `sort -rh`, `head`. Follow-along step 12.

**Task 15.** Write a script that checks all local user accounts and reports which have UID 1000 or greater.

> Hint: `while IFS=: read -r user _ uid ...` from `/etc/passwd`, or `awk -F:`. Follow-along step 8.

**Task 16.** Write a script that reports whether each filesystem is over a threshold percentage of usage, with the threshold as an optional argument.

> Hint: `${1:-80}`, `df -hP`, `while read`, `< <(command)` to avoid subshell. Follow-along step 12.

**Task 17.** Write a script that validates its argument is a positive integer, using a regular expression.

> Hint: `[[ "$INPUT" =~ ^[1-9][0-9]*$ ]]` inside `[[ ]]`. Follow-along step 5.

**Task 18.** Debug a script that produces no output and exits silently.

> Hint: `bash -x`, `bash -n`, check if a condition was false. Follow-along step 13.

**Task 19.** Explain why a counter incremented inside a piped `while` loop is empty afterwards, and fix it.

> Hint: pipeline subshell — use `done < file` or `done < <(cmd)`. Follow-along step 8.

**Task 20.** Make a script run automatically every day at 02:00.

> Hint: cron in `/etc/cron.d/` or `crontab -e`; absolute paths, `chmod +x`, enable `crond`. See `19-scheduling-cron-at.md`.

---

## Solutions

**Task 1.**

```bash
sudo vim /root/hello.sh
```

```bash
#!/bin/bash
echo "Hello, World"
```

```bash
sudo chmod +x /root/hello.sh
ls -l /root/hello.sh
sudo /root/hello.sh
```

```text
-rwxr-xr-x. 1 root root 32 Aug 18 17:00 /root/hello.sh
Hello, World
```

Without the execute bit:

```bash
sudo chmod -x /root/hello.sh
sudo /root/hello.sh
```

```text
sudo: /root/hello.sh: command not found
```

or, as a normal user:

```text
bash: ./hello.sh: Permission denied
```

**This is the single most common way to fail a scripting task.** The script is perfect and the grader cannot run it.

```bash
sudo chmod +x /root/hello.sh
sudo /root/hello.sh
```

Two workarounds exist, and neither satisfies a grader:

```bash
bash /root/hello.sh              # works WITHOUT the execute bit
sh /root/hello.sh
```

**Always `chmod +x` and always confirm with `ls -l`.**

Three other beginner traps:

```bash
# 1. No ./ prefix
cd /root
hello.sh                         # bash: hello.sh: command not found
./hello.sh                       # correct — '.' is not in PATH
```

```bash
# 2. Missing or wrong shebang
head -1 /root/hello.sh           # must be exactly #!/bin/bash
```

**The shebang must be the very first line**, with no blank line or comment before it, and no space between `#!` and the path.

```bash
# 3. Windows line endings
file /root/hello.sh
```

```text
/root/hello.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators
```

```text
bash: ./hello.sh: /bin/bash^M: bad interpreter: No such file or directory
```

```bash
sed -i 's/\r$//' /root/hello.sh
```

**Task 2.**

```bash
sudo tee /root/args.sh >/dev/null <<'EOF'
#!/bin/bash
echo "Script name    : $0"
echo "First argument : $1"
echo "Second argument: $2"
echo "Argument count : $#"
echo "All arguments  : $@"
EOF
sudo chmod +x /root/args.sh
sudo /root/args.sh alpha beta gamma
```

```text
Script name    : /root/args.sh
First argument : alpha
Second argument: beta
Argument count : 3
All arguments  : alpha beta gamma
```

**Note the heredoc quoting: `<<'EOF'` with single quotes.** Without them, the shell expands `$0` and `$1` while *writing* the file, producing a script full of empty strings:

```bash
sudo tee /root/bad.sh >/dev/null <<EOF
#!/bin/bash
echo "First: $1"
EOF
cat /root/bad.sh
```

```text
#!/bin/bash
echo "First: "
```

**Always `<<'EOF'` when writing a script with a heredoc.** Or use `vim`, which has no such problem.

The parameters:

| Variable | With `./args.sh alpha beta gamma` |
| --- | --- |
| `$0` | `./args.sh` |
| **`$1`** | **`alpha`** |
| **`$2`** | **`beta`** |
| `$3` | `gamma` |
| **`$#`** | **`3`** |
| `$@` | `alpha beta gamma` |

**Beyond `$9` you need braces**: `${10}`, `${11}`. `$10` is parsed as `$1` followed by `0`.

```bash
sudo /root/args.sh              # no arguments
```

```text
Argument count : 0
```

**Unset parameters expand to nothing, not an error.** That is why Task 3 matters.

**Task 3.**

```bash
sudo tee /root/needarg.sh >/dev/null <<'EOF'
#!/bin/bash
#
# Requires exactly one argument.
#

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <filename>" >&2
    exit 1
fi

echo "Processing: $1"
exit 0
EOF
sudo chmod +x /root/needarg.sh
```

```bash
sudo /root/needarg.sh
echo "exit status: $?"
```

```text
Usage: /root/needarg.sh <filename>
exit status: 1
```

```bash
sudo /root/needarg.sh myfile
echo "exit status: $?"
```

```text
Processing: myfile
exit status: 0
```

Confirm the message really went to stderr:

```bash
sudo /root/needarg.sh 2>/dev/null          # nothing printed
sudo /root/needarg.sh >/dev/null           # only the usage message
```

**Three details a task is checking:**

1. **`>&2` sends the message to stderr.** Errors and diagnostics belong there so they are not captured by a pipeline. See `02-redirection-pipes.md`.
2. **`exit 1` is a non-zero status.** Callers and graders test `$?`.
3. **`$#` is the argument count.** `-ne 1` for exactly one; `-lt 1` for at least one.

Variations:

```bash
if [[ $# -lt 1 ]]; then ... fi              # at least one
if [[ $# -gt 2 ]]; then ... fi              # too many
if [[ -z "$1" ]]; then ... fi               # first argument empty or absent
[[ $# -eq 1 ]] || { echo "Usage: $0 <f>" >&2; exit 1; }    # compact
```

**Use `-ne`, `-lt`, `-gt` for numbers**, never `!=`, `<`, `>`. Inside single brackets, `>` performs redirection and creates a file called `1`.

**Task 4.**

```bash
sudo tee /root/pathtest.sh >/dev/null <<'EOF'
#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <path>" >&2
    exit 1
fi

TARGET="$1"

if [[ -d "$TARGET" ]]; then
    echo "$TARGET is a directory"
elif [[ -f "$TARGET" ]]; then
    echo "$TARGET is a regular file"
elif [[ -e "$TARGET" ]]; then
    echo "$TARGET exists but is neither a regular file nor a directory"
else
    echo "$TARGET does not exist" >&2
    exit 2
fi

exit 0
EOF
sudo chmod +x /root/pathtest.sh
```

```bash
sudo /root/pathtest.sh /etc
sudo /root/pathtest.sh /etc/passwd
sudo /root/pathtest.sh /dev/null
sudo /root/pathtest.sh /nonexistent; echo "status: $?"
```

```text
/etc is a directory
/etc/passwd is a regular file
/dev/null exists but is neither a regular file nor a directory
/nonexistent does not exist
status: 2
```

**Order matters.** Test `-d` before `-f`, and `-e` last — `-e` is true for directories too, so putting it first would swallow everything.

The file tests worth knowing:

| Test | True when |
| --- | --- |
| **`-f`** | **A regular file** |
| **`-d`** | **A directory** |
| **`-e`** | **Exists, any type** |
| `-r` / `-w` / `-x` | Readable / writable / executable **by the current user** |
| `-s` | Exists and is non-empty |
| `-L` or `-h` | A symbolic link |
| `-b` / `-c` | Block / character device |
| `-z "$var"` | The string is empty |
| `-n "$var"` | The string is non-empty |

Combining:

```bash
if [[ -f "$f" && -r "$f" ]]; then
    echo "readable regular file"
fi

if [[ ! -e "$f" ]]; then
    echo "does not exist"
fi
```

**Quote the variable: `[[ -f "$TARGET" ]]`.** With `[[ ]]` bash is forgiving, but inside `[ ]` an unquoted empty variable produces a syntax error:

```bash
f=""
[ -f $f ] && echo yes            # bash: [: -f: unary operator expected
[ -f "$f" ] && echo yes          # correctly false
```

**Quote everything. It costs nothing and prevents a whole class of failure.**

**Task 5.**

```bash
sudo tee /root/numtest.sh >/dev/null <<'EOF'
#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <number>" >&2
    exit 1
fi

NUM="$1"

if [[ ! "$NUM" =~ ^-?[0-9]+$ ]]; then
    echo "Error: '$NUM' is not an integer" >&2
    exit 2
fi

if [[ $NUM -lt 10 ]]; then
    echo "$NUM is less than 10"
elif [[ $NUM -eq 10 ]]; then
    echo "$NUM is equal to 10"
else
    echo "$NUM is greater than 10"
fi

exit 0
EOF
sudo chmod +x /root/numtest.sh
```

```bash
sudo /root/numtest.sh 5
sudo /root/numtest.sh 10
sudo /root/numtest.sh 42
sudo /root/numtest.sh abc; echo "status: $?"
```

```text
5 is less than 10
10 is equal to 10
42 is greater than 10
Error: 'abc' is not an integer
status: 2
```

**The numeric operators, and why they matter:**

| Numeric | String equivalent | Meaning |
| --- | --- | --- |
| **`-eq`** | `=` | Equal |
| **`-ne`** | `!=` | Not equal |
| **`-lt`** | `<` | Less than |
| **`-gt`** | `>` | Greater than |
| `-le` | | Less or equal |
| `-ge` | | Greater or equal |

**Using string operators on numbers gives wrong answers:**

```bash
[[ "10" > "9" ]] && echo yes     # FALSE — string comparison: "1" < "9"
[[ 10 -gt 9 ]] && echo yes        # TRUE
```

**And inside single brackets, `>` redirects:**

```bash
[ 5 > 3 ]                        # creates a file named 3, always "true"
ls -l 3
[ 5 -gt 3 ]                      # correct
```

The arithmetic form is also available and reads more naturally:

```bash
if (( NUM < 10 )); then
    echo "less than 10"
fi
(( count++ ))
(( total = a + b ))
```

**Inside `(( ))` you use `<`, `>`, `==` and the `$` is optional.** It is a good alternative for arithmetic, but `[[ -lt ]]` is what most exam material uses.

**Task 6.**

```bash
sudo tee /root/evens.sh >/dev/null <<'EOF'
#!/bin/bash

for i in {1..10}; do
    if (( i % 2 == 0 )); then
        echo "$i"
    fi
done
EOF
sudo chmod +x /root/evens.sh
sudo /root/evens.sh
```

```text
2
4
6
8
10
```

Alternatives, all valid:

```bash
# Step the range by 2
for i in {2..10..2}; do echo "$i"; done

# C-style
for (( i=2; i<=10; i+=2 )); do echo "$i"; done

# With continue
for i in {1..10}; do
    (( i % 2 != 0 )) && continue
    echo "$i"
done

# seq
for i in $(seq 2 2 10); do echo "$i"; done

# while
i=1
while [[ $i -le 10 ]]; do
    (( i % 2 == 0 )) && echo "$i"
    (( i++ ))
done
```

**Brace expansion `{1..10}` is the cleanest for a fixed range**, but note it does not accept variables:

```bash
n=10
for i in {1..$n}; do echo "$i"; done         # prints the literal "{1..10}"
for i in $(seq 1 "$n"); do echo "$i"; done   # correct
for (( i=1; i<=n; i++ )); do echo "$i"; done # also correct
```

**With a variable limit, use `seq` or the C-style form.** This trips people up regularly.

The modulo test:

```bash
(( i % 2 == 0 ))                 # arithmetic — clearest
[[ $(( i % 2 )) -eq 0 ]]         # equivalent
```

**Task 7.**

```bash
sudo tee /root/confcount.sh >/dev/null <<'EOF'
#!/bin/bash

for f in /etc/*.conf; do
    [[ -f "$f" ]] || continue
    lines=$(wc -l < "$f")
    printf "%-40s %5d\n" "$f" "$lines"
done
EOF
sudo chmod +x /root/confcount.sh
sudo /root/confcount.sh
```

```text
/etc/chrony.conf                            48
/etc/dnf.conf                                6
/etc/host.conf                               2
/etc/krb5.conf                              23
/etc/libaudit.conf                           2
/etc/nsswitch.conf                          19
/etc/resolv.conf                             3
/etc/sysctl.conf                            10
```

**Four details in that loop:**

1. **The glob is unquoted:** `for f in /etc/*.conf`. Quoting it prevents expansion and gives you the literal string once.

2. **`[[ -f "$f" ]] || continue` guards against a glob that matches nothing.** If no files match, bash passes the pattern through literally and the loop body sees `/etc/*.conf` as a filename:

```bash
for f in /etc/*.nosuchext; do echo "$f"; done
```

```text
/etc/*.nosuchext
```

The `-f` test skips it. Alternatively:

```bash
shopt -s nullglob                # an unmatched glob expands to nothing
```

3. **`wc -l < "$f"` rather than `wc -l "$f"`.** Redirecting gives just the number; passing the filename appends the name to the output:

```bash
wc -l /etc/hosts                 # "9 /etc/hosts"
wc -l < /etc/hosts               # "9"
```

**That is the idiom for capturing a count into a variable.**

4. **`printf` for aligned columns.** `%-40s` is a left-justified 40-character string, `%5d` a right-justified 5-digit number. `echo` cannot align.

Recursive variants:

```bash
find /etc -name '*.conf' -type f | while read -r f; do
    echo "$f: $(wc -l < "$f")"
done

while IFS= read -r -d '' f; do
    echo "$f: $(wc -l < "$f")"
done < <(find /etc -name '*.conf' -type f -print0)
```

**The second form handles filenames containing spaces or newlines**, using `-print0` and `-d ''`. Worth knowing, though exam tasks rarely need it.

**Task 8.**

```bash
sudo tee /root/users.txt >/dev/null <<'EOF'
root
alice
bob
nosuchuser
EOF

sudo tee /root/checkusers.sh >/dev/null <<'EOF'
#!/bin/bash

USERFILE="/root/users.txt"

if [[ ! -f "$USERFILE" ]]; then
    echo "Error: $USERFILE not found" >&2
    exit 1
fi

while read -r username; do
    [[ -z "$username" ]] && continue
    [[ "$username" =~ ^# ]] && continue

    if id "$username" &>/dev/null; then
        echo "EXISTS  : $username (uid $(id -u "$username"))"
    else
        echo "MISSING : $username"
    fi
done < "$USERFILE"
EOF
sudo chmod +x /root/checkusers.sh
sudo /root/checkusers.sh
```

```text
EXISTS  : root (uid 0)
EXISTS  : alice (uid 1001)
EXISTS  : bob (uid 1002)
MISSING : nosuchuser
```

**The `while read` pattern in detail:**

```bash
while read -r line; do
    ...
done < "$FILE"
```

| Element | Why |
| --- | --- |
| **`-r`** | **Do not interpret backslashes.** Always use it |
| **`< "$FILE"`** | **Redirect after `done`** — not a pipe |
| `[[ -z "$line" ]] && continue` | Skip blank lines |
| `[[ "$line" =~ ^# ]] && continue` | Skip comments |
| `IFS= read -r line` | Preserve leading and trailing whitespace |

**Using `id` for the existence test is the key idea:**

```bash
if id "$username" &>/dev/null; then
```

**`if command; then` tests the command's exit status** — no `[[ ]]` and no output parsing. `&>/dev/null` discards both stdout and stderr so only the status matters.

The alternatives are worse:

```bash
if getent passwd "$username" &>/dev/null; then ...        # equally good
if grep -q "^$username:" /etc/passwd; then ...            # misses LDAP/SSSD users
if [[ -d "/home/$username" ]]; then ...                   # wrong — proves nothing
```

**`getent passwd` and `id` consult NSS**, so they see directory users as well as local ones. `grep /etc/passwd` sees only local accounts.

**And do not read a file with `for`:**

```bash
for line in $(cat file); do ...    # WRONG: splits on every space, not per line
while read -r line; do ... done < file    # correct
```

A file line `alice smith` becomes two iterations with `for`, and one with `while read`.

**Task 9.**

```bash
sudo tee /root/mkusers.sh >/dev/null <<'EOF'
#!/bin/bash
#
# Create users listed one per line in the file given as $1.
#

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <userfile>" >&2
    exit 1
fi

USERFILE="$1"

if [[ ! -f "$USERFILE" ]]; then
    echo "Error: $USERFILE does not exist" >&2
    exit 2
fi

if [[ $EUID -ne 0 ]]; then
    echo "Error: must be run as root" >&2
    exit 3
fi

created=0
skipped=0
failed=0

while read -r username; do
    [[ -z "$username" ]] && continue
    [[ "$username" =~ ^# ]] && continue

    if id "$username" &>/dev/null; then
        echo "SKIP   : $username already exists"
        (( skipped++ ))
    elif useradd "$username" 2>/dev/null; then
        echo "CREATED: $username (uid $(id -u "$username"))"
        (( created++ ))
    else
        echo "FAILED : $username" >&2
        (( failed++ ))
    fi
done < "$USERFILE"

echo
echo "Created: $created   Skipped: $skipped   Failed: $failed"

[[ $failed -eq 0 ]] && exit 0 || exit 4
EOF
sudo chmod +x /root/mkusers.sh
```

```bash
sudo tee /root/newusers.txt >/dev/null <<'EOF'
# team accounts
dev1
dev2
alice
EOF

sudo /root/mkusers.sh /root/newusers.txt
echo "status: $?"
```

```text
CREATED: dev1 (uid 1003)
CREATED: dev2 (uid 1004)
SKIP   : alice already exists

Created: 2   Skipped: 1   Failed: 0
status: 0
```

Verify:

```bash
id dev1
id dev2
getent passwd dev1 dev2
```

**This script demonstrates every objective in this file at once:**

| Objective | Where |
| --- | --- |
| Process script inputs | `$1`, `$#` |
| Conditionally execute | `if`/`elif`/`else`, `[[ -f ]]`, `[[ $# -ne 1 ]]` |
| Looping constructs | `while read -r ... done < "$USERFILE"` |
| Process command output | `$(id -u "$username")`, `if id ...; then` |

Three techniques worth noting:

**`if useradd "$username"; then` uses the command's exit status directly** — cleaner than running it and then checking `$?`.

**`$EUID -ne 0` is the root check.** `useradd` needs root, so failing early with a clear message beats a cascade of permission errors:

```bash
if [[ $EUID -ne 0 ]]; then
    echo "Error: must be run as root" >&2
    exit 3
fi
```

**Distinct exit codes for distinct failures** — 1 for usage, 2 for a missing file, 3 for not root, 4 for partial failure. A task saying "exit with an appropriate status" wants this.

Extending it, if a task asks:

```bash
useradd -c "$comment" -s /bin/bash -G developers "$username"
echo "$username:$(openssl rand -base64 12)" | chpasswd
chage -d 0 "$username"           # force a password change at first login
```

Clean up:

```bash
sudo userdel -r dev1
sudo userdel -r dev2
```

**Task 10.**

```bash
sudo tee /root/eachargs.sh >/dev/null <<'EOF'
#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <arg> [arg...]" >&2
    exit 1
fi

echo "Received $# argument(s):"

n=1
for arg in "$@"; do
    printf "  %d: [%s]\n" "$n" "$arg"
    (( n++ ))
done
EOF
sudo chmod +x /root/eachargs.sh
sudo /root/eachargs.sh one "two three" four
```

```text
Received 3 argument(s):
  1: [one]
  2: [two three]
  3: [four]
```

**`"$@"` with the quotes is what makes "two three" stay a single argument.** Compare all four forms:

```bash
for a in "$@"; do echo "[$a]"; done     # 3 iterations — CORRECT
for a in $@;   do echo "[$a]"; done     # 4 — split on the space
for a in "$*"; do echo "[$a]"; done     # 1 — everything joined
for a in $*;   do echo "[$a]"; done     # 4 — split
```

```text
"$@"  →  [one] [two three] [four]
$@    →  [one] [two] [three] [four]
"$*"  →  [one two three four]
```

| Form | Result |
| --- | --- |
| **`"$@"`** | **Each argument separately, quoting preserved. Use this** |
| `$@` | Word-split on whitespace |
| `"$*"` | One string, arguments joined by the first character of `IFS` |
| `$*` | Word-split |

**`"$@"` is the correct answer essentially always**, whether iterating or passing arguments on to another command:

```bash
some_command "$@"                # forwards arguments faithfully
some_command $@                  # mangles anything containing a space
```

`shift` is the alternative when you consume arguments as you go:

```bash
while [[ $# -gt 0 ]]; do
    echo "Processing: $1"
    shift
done
```

**And quote in the body too**: `printf "%s" "$arg"`, not `$arg`. An unquoted expansion splits again inside the loop.

**Task 11.**

```bash
sudo tee /root/diskreport.sh >/dev/null <<'EOF'
#!/bin/bash

TOTAL_USERS=$(getent passwd | wc -l)
NORMAL_USERS=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | wc -l)
SYSTEM_USERS=$(( TOTAL_USERS - NORMAL_USERS ))
CONF_FILES=$(find /etc -maxdepth 1 -name '*.conf' -type f | wc -l)
ROOT_PCT=$(df --output=pcent / | tail -1 | tr -d ' %')
KERNEL=$(uname -r)
UPTIME_DAYS=$(( $(cut -d. -f1 /proc/uptime) / 86400 ))

echo "Host          : $(hostname -s)"
echo "Kernel        : $KERNEL"
echo "Uptime        : $UPTIME_DAYS day(s)"
echo "Total accounts: $TOTAL_USERS"
echo "  regular     : $NORMAL_USERS"
echo "  system      : $SYSTEM_USERS"
echo "Conf files    : $CONF_FILES"
echo "Root fs used  : ${ROOT_PCT}%"

if (( ROOT_PCT > 80 )); then
    echo "WARNING: root filesystem over 80% full" >&2
    exit 1
fi
exit 0
EOF
sudo chmod +x /root/diskreport.sh
sudo /root/diskreport.sh
```

```text
Host          : server1
Kernel        : 6.12.0-55.el10.x86_64
Uptime        : 2 day(s)
Total accounts: 42
  regular     : 3
  system      : 39
Conf files    : 8
Root fs used  : 13%
```

**Command substitution `$(...)` captures a command's stdout into a variable:**

```bash
count=$(ls /etc | wc -l)
today=$(date +%F)
host=$(hostname -s)
```

**Use `$(...)`, not backticks.** Backticks do not nest and are hard to read:

```bash
outer=$(echo $(date +%Y))        # nests cleanly
outer=`echo \`date +%Y\``        # escaping nightmare
```

Arithmetic on captured values:

```bash
SYSTEM_USERS=$(( TOTAL_USERS - NORMAL_USERS ))
total=$(( a + b ))
(( count++ ))
```

**Bash arithmetic is integer-only:**

```bash
echo $(( 10 / 3 ))                        # 3
echo "scale=2; 10/3" | bc                 # 3.33
awk 'BEGIN {printf "%.2f\n", 10/3}'       # 3.33
```

**Cleaning up command output is where most of the work is.** `df` is the classic example:

```bash
df -h /
df --output=pcent /                       # just the percentage column
df --output=pcent / | tail -1             # drop the header
df --output=pcent / | tail -1 | tr -d ' %'   # 13
df -h / | awk 'NR==2 {gsub(/%/,"",$5); print $5}'   # equivalent with awk
```

**`tail -1` to skip the header and `tr -d ' %'` to strip the percent sign** — a pattern that recurs constantly.

**Quote command substitutions that may contain spaces:**

```bash
files="$(ls /etc)"               # newlines preserved
echo "$files"                    # one per line
echo $files                       # all on one line, word-split
```

**Task 12.**

```bash
sudo tee /root/svccheck.sh >/dev/null <<'EOF'
#!/bin/bash

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <service> [service...]" >&2
    exit 1
fi

rc=0

for svc in "$@"; do
    if systemctl is-active --quiet "$svc"; then
        active="ACTIVE"
    else
        active="INACTIVE"
        rc=1
    fi

    if systemctl is-enabled --quiet "$svc" 2>/dev/null; then
        enabled="enabled"
    else
        enabled="disabled"
        rc=1
    fi

    printf "%-16s %-10s %s\n" "$svc" "$active" "$enabled"
done

exit $rc
EOF
sudo chmod +x /root/svccheck.sh
sudo /root/svccheck.sh sshd firewalld chronyd httpd
echo "status: $?"
```

```text
sshd             ACTIVE     enabled
firewalld        ACTIVE     enabled
chronyd          ACTIVE     enabled
httpd            INACTIVE   disabled
status: 1
```

**The point of this task is using exit status rather than parsing output.**

```bash
if systemctl is-active --quiet httpd; then ...      # CORRECT
if [[ "$(systemctl is-active httpd)" == "active" ]]; then ...   # fragile
```

**`--quiet` suppresses the output and leaves only the exit status**, which is the whole interface:

```bash
systemctl is-active --quiet sshd; echo $?      # 0
systemctl is-active --quiet httpd; echo $?     # 3
```

**Many commands are designed to be used this way:**

| Command | Tests |
| --- | --- |
| `systemctl is-active --quiet UNIT` | Running |
| `systemctl is-enabled --quiet UNIT` | Enabled at boot |
| **`id USER &>/dev/null`** | **The user exists** |
| `getent passwd USER &>/dev/null` | The user exists (NSS-aware) |
| **`grep -q PATTERN FILE`** | **The pattern is present** |
| `ping -c1 -W1 HOST &>/dev/null` | The host responds |
| `rpm -q PACKAGE &>/dev/null` | The package is installed |
| `firewall-cmd --query-service=http` | The service is allowed |
| `mountpoint -q /data` | Something is mounted there |
| `test -f FILE` / `[[ -f FILE ]]` | The file exists |

**`grep -q` is the one to remember for file contents:**

```bash
if grep -q '^PermitRootLogin no' /etc/ssh/sshd_config; then
    echo "root login disabled"
fi
```

Accumulating a status across a loop:

```bash
rc=0
for svc in "$@"; do
    systemctl is-active --quiet "$svc" || rc=1
done
exit $rc
```

**`exit $rc` returns non-zero if any check failed**, which is how a monitoring script should behave.

**Task 13.**

```bash
sudo tee /root/svcctl.sh >/dev/null <<'EOF'
#!/bin/bash

SERVICE="httpd"

usage() {
    echo "Usage: $0 {start|stop|restart|status}" >&2
    exit 1
}

[[ $# -eq 1 ]] || usage

case "$1" in
    start)
        echo "Starting $SERVICE..."
        systemctl start "$SERVICE" && echo "started" || { echo "failed" >&2; exit 2; }
        ;;
    stop)
        echo "Stopping $SERVICE..."
        systemctl stop "$SERVICE" && echo "stopped"
        ;;
    restart)
        echo "Restarting $SERVICE..."
        systemctl restart "$SERVICE" && echo "restarted"
        ;;
    status)
        if systemctl is-active --quiet "$SERVICE"; then
            echo "$SERVICE is running"
        else
            echo "$SERVICE is not running"
            exit 3
        fi
        ;;
    *)
        usage
        ;;
esac

exit 0
EOF
sudo chmod +x /root/svcctl.sh
sudo /root/svcctl.sh status
sudo /root/svcctl.sh start
sudo /root/svcctl.sh status
sudo /root/svcctl.sh bogus; echo "status: $?"
```

```text
httpd is not running
Starting httpd...
started
httpd is running
Usage: /root/svcctl.sh {start|stop|restart|status}
status: 1
```

**The `case` syntax:**

```bash
case "$VARIABLE" in
    pattern1)   commands ;;
    pattern2)   commands ;;
    pat3|pat4)  commands ;;
    *)          default  ;;
esac
```

| Element | Purpose |
| --- | --- |
| `case ... in` | Open |
| `pattern)` | A glob pattern, then `)` |
| **`;;`** | **End of branch. Required** |
| `pat1\|pat2` | Alternatives |
| **`*)`** | **The catch-all. Put it last** |
| **`esac`** | **Close** |

Patterns are globs, not regexes:

```bash
case "$answer" in
    [yY]|[yY][eE][sS]) echo "yes" ;;
    [nN]|[nN][oO])     echo "no"  ;;
    *)                 echo "unrecognised" ;;
esac

case "$file" in
    *.tar.gz|*.tgz) tar -xzf "$file" ;;
    *.tar.bz2)      tar -xjf "$file" ;;
    *.zip)          unzip "$file"    ;;
    *)              echo "unknown format" >&2 ;;
esac
```

**`case` is clearer than a chain of `elif` when matching one variable against fixed values**, and it is the conventional shape for a script with subcommands.

Note the `usage()` function — **defining it once and calling it from both the argument check and the `*)` branch** avoids duplication:

```bash
usage() {
    echo "Usage: $0 {start|stop|restart|status}" >&2
    exit 1
}
```

**Task 14.**

```bash
sudo tee /root/topdirs.sh >/dev/null <<'EOF'
#!/bin/bash

TARGET="${1:-/var}"
COUNT="${2:-5}"

if [[ ! -d "$TARGET" ]]; then
    echo "Error: $TARGET is not a directory" >&2
    exit 1
fi

echo "Top $COUNT directories under $TARGET:"
echo

du -h --max-depth=1 "$TARGET" 2>/dev/null | sort -rh | head -n "$COUNT"

exit 0
EOF
sudo chmod +x /root/topdirs.sh
sudo /root/topdirs.sh
sudo /root/topdirs.sh /usr 3
```

```text
Top 5 directories under /var:

512M	/var
340M	/var/log
124M	/var/lib
28M	/var/cache
16M	/var/tmp
```

**`${1:-/var}` is the default-value expansion, and it is the point of this task:**

```bash
TARGET="${1:-/var}"              # use $1, or /var if $1 is unset OR empty
```

| Form | Behaviour |
| --- | --- |
| **`${1:-default}`** | **Use `default` if `$1` is unset or empty** |
| `${1-default}` | Use `default` only if `$1` is *unset* |
| `${1:=default}` | Use and *assign* the default |
| **`${1:?message}`** | **Error with `message` and exit if unset** |
| `${1:+value}` | Use `value` only if `$1` *is* set |

```bash
FILE="${1:?Usage: $0 <filename>}"      # a one-line required argument
```

**`${VAR:-default}` is a compact idiom for optional arguments** and reads better than the equivalent `if`:

```bash
if [[ -z "$1" ]]; then TARGET="/var"; else TARGET="$1"; fi
TARGET="${1:-/var}"                     # the same thing
```

The pipeline is worth reading closely:

```bash
du -h --max-depth=1 "$TARGET" 2>/dev/null | sort -rh | head -n 5
```

| Piece | Purpose |
| --- | --- |
| `-h` | Human-readable sizes |
| `--max-depth=1` | Immediate children only |
| **`2>/dev/null`** | **Discard permission errors** |
| **`sort -rh`** | **Reverse, human-numeric — understands `M` and `G`** |
| `head -n 5` | The top five |

**`sort -h` versus `sort -n`:**

```bash
du -h --max-depth=1 /var | sort -rn | head -3    # WRONG — "512M" sorts as 512
du -h --max-depth=1 /var | sort -rh | head -3    # correct
```

**`sort -h` is essential when sorting human-readable sizes.** Plain `-n` reads only the leading digits, so 900K outranks 2G.

**Task 15.**

```bash
sudo tee /root/listusers.sh >/dev/null <<'EOF'
#!/bin/bash

MIN_UID="${1:-1000}"

printf "%-16s %-8s %-8s %s\n" "USERNAME" "UID" "GID" "SHELL"
printf "%-16s %-8s %-8s %s\n" "--------" "---" "---" "-----"

count=0
while IFS=: read -r user _ uid gid _ _ shell; do
    if (( uid >= MIN_UID && uid < 65534 )); then
        printf "%-16s %-8s %-8s %s\n" "$user" "$uid" "$gid" "$shell"
        (( count++ ))
    fi
done < /etc/passwd

echo
echo "Total: $count account(s) with UID >= $MIN_UID"
EOF
sudo chmod +x /root/listusers.sh
sudo /root/listusers.sh
sudo /root/listusers.sh 0
```

```text
USERNAME         UID      GID      SHELL
--------         ---      ---      -----
douglas          1000     1000     /bin/bash
alice            1001     1001     /bin/bash
bob              1002     1002     /bin/bash

Total: 3 account(s) with UID >= 1000
```

**`while IFS=: read -r a b c ...` splits each line on colons into separate variables** — the cleanest way to parse `/etc/passwd`:

```bash
while IFS=: read -r user pass uid gid comment home shell; do
```

| Element | Purpose |
| --- | --- |
| **`IFS=:`** | **Split on `:` for this `read` only** |
| `-r` | Do not interpret backslashes |
| Several variable names | One field each, in order |
| `_` | Convention for a field you do not need |
| The last variable | **Receives all remaining fields** |

**Setting `IFS=` as a prefix to `read` scopes it to that command**, leaving the global `IFS` untouched.

The `/etc/passwd` fields, from `10-users-groups.md`:

```text
alice:x:1001:1001:Alice Smith:/home/alice:/bin/bash
  1   2  3    4        5           6         7
```

The one-liner equivalents are usually what an exam answer looks like:

```bash
awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3, $7}' /etc/passwd
getent passwd | awk -F: '$3>=1000 && $3<65534 {print $1}'
cut -d: -f1,3 /etc/passwd | awk -F: '$2>=1000'
lslogins -u                                        # purpose-built
```

**`awk -F: '$3 >= 1000'` is shorter and often preferable** — but the objectives explicitly mention looping constructs, so a task may want the loop.

**Note the `< 65534` bound.** UID 65534 is `nobody`, which would otherwise appear in a "regular users" list. See `10-users-groups.md`.

**`getent passwd` rather than `/etc/passwd`** if directory users should be included:

```bash
getent passwd | while IFS=: read -r user _ uid _; do ...
```

**Task 16.**

```bash
sudo tee /root/diskalert.sh >/dev/null <<'EOF'
#!/bin/bash

THRESHOLD="${1:-80}"

if [[ ! "$THRESHOLD" =~ ^[0-9]+$ ]] || (( THRESHOLD < 1 || THRESHOLD > 100 )); then
    echo "Error: threshold must be an integer between 1 and 100" >&2
    exit 1
fi

echo "Filesystems above ${THRESHOLD}% usage:"
echo

alerts=0

while read -r fs size used avail pcent mount; do
    pct="${pcent%\%}"
    if (( pct >= THRESHOLD )); then
        printf "  %-28s %4s%%  (%s used of %s) on %s\n" "$fs" "$pct" "$used" "$size" "$mount"
        (( alerts++ ))
    fi
done < <(df -hP --local | tail -n +2)

if (( alerts == 0 )); then
    echo "  none"
    exit 0
fi

echo
echo "$alerts filesystem(s) above threshold"
exit 1
EOF
sudo chmod +x /root/diskalert.sh
sudo /root/diskalert.sh
sudo /root/diskalert.sh 10
echo "status: $?"
```

```text
Filesystems above 10% usage:

  /dev/mapper/rhel-root          13%  (2.1G used of 17G) on /
  /dev/sda1                      25%  (247M used of 1014M) on /boot

2 filesystem(s) above threshold
status: 1
```

Three techniques worth noting.

**Process substitution `< <(command)` feeds a command's output into a `while` loop without a subshell:**

```bash
done < <(df -hP --local | tail -n +2)
```

Compare with a pipe:

```bash
df -hP | while read ...; do (( alerts++ )); done
echo "$alerts"                   # EMPTY — the loop ran in a subshell
```

**`while ... done < <(cmd)` keeps the loop in the current shell**, so `alerts` survives. See Task 19.

**Parameter expansion strips the percent sign:**

```bash
pct="${pcent%\%}"                # remove a trailing %
```

| Form | Effect |
| --- | --- |
| **`${var%pattern}`** | **Remove the shortest match from the end** |
| `${var%%pattern}` | Remove the longest match from the end |
| **`${var#pattern}`** | **Remove the shortest match from the start** |
| `${var##pattern}` | Remove the longest match from the start |
| `${var/old/new}` | Replace the first occurrence |
| `${var//old/new}` | Replace all occurrences |
| `${#var}` | The string's length |

```bash
f="/var/log/messages.log"
echo "${f##*/}"                  # messages.log — the basename
echo "${f%/*}"                   # /var/log — the dirname
echo "${f%.log}"                 # /var/log/messages
```

**Faster and dependency-free compared with `basename`, `dirname`, or `sed`.**

**`df -P` guarantees one line per filesystem.** Without it, a long device name wraps onto a second line and breaks the field parsing:

```bash
df -h                            # may wrap long device names
df -hP                           # POSIX format, one line each
df -hP --local                   # skip network filesystems
tail -n +2                       # drop the header
```

**Task 17.**

```bash
sudo tee /root/validate.sh >/dev/null <<'EOF'
#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <positive-integer>" >&2
    exit 1
fi

INPUT="$1"

if [[ ! "$INPUT" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: '$INPUT' is not a positive integer" >&2
    exit 2
fi

echo "'$INPUT' is a valid positive integer"
echo "Its square is $(( INPUT * INPUT ))"
exit 0
EOF
sudo chmod +x /root/validate.sh

for v in 42 0 -5 3.14 abc 007 ""; do
    echo "--- testing '$v'"
    sudo /root/validate.sh "$v"
done
```

```text
--- testing '42'
'42' is a valid positive integer
Its square is 1764
--- testing '0'
Error: '0' is not a positive integer
--- testing '-5'
Error: '-5' is not a positive integer
--- testing '3.14'
Error: '3.14' is not a positive integer
--- testing 'abc'
Error: 'abc' is not a positive integer
--- testing '007'
Error: '007' is not a positive integer
--- testing ''
Error: '' is not a positive integer
```

**`=~` is bash's regex match operator, valid only inside `[[ ]]`:**

```bash
if [[ "$INPUT" =~ ^[1-9][0-9]*$ ]]; then
```

The pattern:

| Piece | Matches |
| --- | --- |
| `^` | Start of string |
| `[1-9]` | One digit, 1 to 9 — **excludes a leading zero** |
| `[0-9]*` | Any number of further digits |
| `$` | End of string |

**`^` and `$` are essential.** Without them, `=~ [0-9]+` matches `abc123xyz` because a substring matches.

Common validation patterns:

```bash
[[ "$v" =~ ^[0-9]+$ ]]                          # a non-negative integer
[[ "$v" =~ ^-?[0-9]+$ ]]                        # any integer
[[ "$v" =~ ^[0-9]+\.[0-9]+$ ]]                  # a decimal
[[ "$v" =~ ^[a-z_][a-z0-9_-]*$ ]]               # a valid username
[[ "$v" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]     # an IPv4 shape
[[ "$v" =~ ^(yes|no)$ ]]                        # one of two words
[[ "$f" =~ \.(tar\.gz|tgz)$ ]]                  # a file extension
```

**Do not quote the pattern:**

```bash
[[ "$v" =~ ^[0-9]+$ ]]           # correct — pattern unquoted
[[ "$v" =~ "^[0-9]+$" ]]         # WRONG — matches the literal string
```

**Quote the variable, leave the pattern bare.** For a pattern held in a variable, that variable must also be unquoted:

```bash
pattern='^[0-9]+$'
[[ "$v" =~ $pattern ]]           # correct
[[ "$v" =~ "$pattern" ]]         # WRONG
```

`BASH_REMATCH` holds the captures:

```bash
if [[ "2026-08-18" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
    echo "year=${BASH_REMATCH[1]} month=${BASH_REMATCH[2]} day=${BASH_REMATCH[3]}"
fi
```

**`=~` requires `[[ ]]` and therefore `#!/bin/bash`.** Under `sh` it is a syntax error — one more reason the shebang matters. Portable alternatives:

```bash
case "$v" in ''|*[!0-9]*) echo "not a number" ;; *) echo "number" ;; esac
echo "$v" | grep -qE '^[0-9]+$' && echo "number"
```

**Task 18.**

The script:

```bash
sudo tee /root/broken.sh >/dev/null <<'EOF'
#!/bin/bash
FILE=/root/data.txt
if [ -f $FILE ]
then
for line in $(cat $FILE)
do
count=$((count+1))
done
echo "Lines: $count"
fi
EOF
sudo chmod +x /root/broken.sh
sudo /root/broken.sh
```

No output. Diagnose systematically.

```bash
# 1. Syntax check — runs nothing
bash -n /root/broken.sh
```

Silence means the syntax is valid, so the logic is at fault.

```bash
# 2. Trace execution
bash -x /root/broken.sh
```

```text
+ FILE=/root/data.txt
+ '[' -f /root/data.txt ']'
```

**The trace stops immediately after the `if`, so the test was false.** The `if` body never ran, which is why there was no output at all.

```bash
# 3. Confirm
ls -l /root/data.txt
```

```text
ls: cannot access '/root/data.txt': No such file or directory
```

**That is the bug: the file does not exist and the script silently does nothing.** A script should say so:

```bash
sudo tee /root/fixed.sh >/dev/null <<'EOF'
#!/bin/bash
set -u

FILE="${1:-/root/data.txt}"

if [[ ! -f "$FILE" ]]; then
    echo "Error: $FILE not found" >&2
    exit 1
fi

count=0
while read -r line; do
    (( count++ ))
done < "$FILE"

echo "Lines: $count"
EOF
sudo chmod +x /root/fixed.sh
printf 'one\ntwo three\nfour\n' | sudo tee /root/data.txt >/dev/null
sudo /root/fixed.sh
```

```text
Lines: 3
```

**Note the original would also have counted wrongly.** `for line in $(cat $FILE)` splits on whitespace, so `two three` counts as two — it would have reported 4 lines instead of 3. **Two bugs in eight lines.**

**The debugging toolkit:**

| Technique | Finds |
| --- | --- |
| **`bash -n script`** | **Syntax errors, without running anything** |
| **`bash -x script`** | **Which commands ran and with what values** |
| `set -x` / `set +x` | Trace a specific section |
| **`set -u`** | **Use of an undefined variable** |
| `set -e` | Exits at the first failing command |
| `set -euo pipefail` | All three, for robustness |
| `echo "DEBUG: var=$var" >&2` | Values at a chosen point |
| `bash -v script` | Prints each line before executing |

```bash
#!/bin/bash
set -x                           # trace from here
risky_section
set +x                           # stop tracing
```

**`bash -x` is the single most useful debugging tool** — it shows every expansion, so you see exactly what the shell saw rather than what you meant.

Common causes of silent failure:

| Symptom | Cause |
| --- | --- |
| **No output at all** | **A condition was false; the body never ran** |
| `command not found` | Missing `#!`, a typo, or `PATH` |
| `Permission denied` | **No `chmod +x`** |
| `bad interpreter: ^M` | **CRLF line endings** — `sed -i 's/\r$//'` |
| `unary operator expected` | An unquoted empty variable inside `[ ]` |
| `[: too many arguments` | An unquoted variable containing spaces |
| Wrong counts | `for` over `$(cat file)` instead of `while read` |
| A variable is empty after a loop | **The loop ran in a subshell** — Task 19 |

**Task 19.**

```bash
printf 'alpha\nbeta\ngamma\n' | sudo tee /root/lines.txt >/dev/null

sudo tee /root/subshell.sh >/dev/null <<'EOF'
#!/bin/bash

count=0
cat /root/lines.txt | while read -r line; do
    (( count++ ))
    echo "  inside loop: count=$count"
done
echo "after loop: count=$count"
EOF
sudo chmod +x /root/subshell.sh
sudo /root/subshell.sh
```

```text
  inside loop: count=1
  inside loop: count=2
  inside loop: count=3
after loop: count=0
```

**The counter reached 3 inside the loop and is 0 afterwards.**

**Every element of a pipeline runs in its own subshell.** The `while` loop is the right-hand side of a pipe, so it executes in a child process with a copy of the parent's variables. It increments its copy; the parent's `count` is never touched, and the child exits taking its copy with it.

```bash
echo "parent PID: $$"
cat /root/lines.txt | while read -r l; do echo "loop PID: $BASHPID"; done
```

Three fixes:

```bash
# 1. Redirect instead of piping — BEST for a file
count=0
while read -r line; do (( count++ )); done < /root/lines.txt
echo "count=$count"                        # 3
```

```bash
# 2. Process substitution — for command output
count=0
while read -r line; do (( count++ )); done < <(cat /root/lines.txt)
echo "count=$count"                        # 3
```

```bash
# 3. lastpipe — works but needs two settings
shopt -s lastpipe
set +m
count=0
cat /root/lines.txt | while read -r l; do (( count++ )); done
echo "count=$count"                        # 3
```

The corrected script:

```bash
sudo tee /root/nosubshell.sh >/dev/null <<'EOF'
#!/bin/bash

# Reading a file: redirect
count=0
while read -r line; do
    (( count++ ))
done < /root/lines.txt
echo "file lines: $count"

# Reading command output: process substitution
users=0
while IFS=: read -r name _ uid _; do
    (( uid >= 1000 )) && (( users++ ))
done < <(getent passwd)
echo "regular users: $users"
EOF
sudo chmod +x /root/nosubshell.sh
sudo /root/nosubshell.sh
```

```text
file lines: 3
regular users: 3
```

| Form | Subshell | Use for |
| --- | --- | --- |
| **`while ...; done < file`** | **No** | **Reading a file** |
| **`while ...; done < <(cmd)`** | **No** | **Reading command output** |
| `cmd \| while ...; done` | **Yes** | Only when you need nothing afterwards |
| `for x in $(cmd)` | No, **but word-splits** | Only for simple word lists |

**Rules of thumb:**

- **`< file` to read a file.**
- **`< <(command)` to read command output.**
- **Never pipe into a `while` loop if you need a variable afterwards.**

The same subshell rule applies elsewhere:

```bash
( count=5 )                      # a subshell — count unchanged outside
echo "$count"

count=$(some_command)            # command substitution: a subshell, but the VALUE returns
```

**Task 20.**

```bash
sudo chmod +x /root/diskalert.sh
sudo /root/diskalert.sh 80          # confirm it works first
```

With cron (see `19-scheduling-cron-at.md`):

```bash
sudo tee /etc/cron.d/diskalert >/dev/null <<'EOF'
# m h dom mon dow user command
0 2 * * * root /root/diskalert.sh 80 >> /var/log/diskalert.log 2>&1
EOF

sudo systemctl enable --now crond
sudo systemctl status crond
sudo cat /etc/cron.d/diskalert
```

Or as root's user crontab:

```bash
sudo crontab -e
```

```text
0 2 * * * /root/diskalert.sh 80 >> /var/log/diskalert.log 2>&1
```

```bash
sudo crontab -l
```

**Five things that matter:**

1. **`chmod +x`.** cron cannot run a non-executable script.
2. **An absolute path.** cron's `PATH` is minimal — `/usr/bin:/bin` — so use full paths for the script and for anything it calls.
3. **A `user` field in `/etc/cron.d/`.** System crontabs have six fields plus the command; user crontabs have five plus the command. Omitting the user is the classic `/etc/cron.d` error.
4. **Redirect the output.** cron mails stdout and stderr to the user; redirecting to a file makes it inspectable.
5. **`crond` must be enabled**, not just started.

The equivalent systemd timer:

```bash
sudo tee /etc/systemd/system/diskalert.service >/dev/null <<'EOF'
[Unit]
Description=Disk usage alert

[Service]
Type=oneshot
ExecStart=/root/diskalert.sh 80
EOF

sudo tee /etc/systemd/system/diskalert.timer >/dev/null <<'EOF'
[Unit]
Description=Run disk usage alert daily at 02:00

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now diskalert.timer
systemctl list-timers diskalert.timer
```

```text
NEXT                        LEFT     LAST  PASSED  UNIT             ACTIVATES
Wed 2026-08-19 02:00:00 EAT 8h left  -     -       diskalert.timer  diskalert.service
```

**Enable the `.timer`, not the `.service`.** And **`daemon-reload` after creating the units.** See `19-scheduling-cron-at.md` and `14-systemd-services.md`.

Test without waiting:

```bash
sudo systemctl start diskalert.service
sudo journalctl -u diskalert.service -n 20
sudo cat /var/log/diskalert.log
```

**Scripts with a schedule are a natural exam combination**, because they test scripting and scheduling together. The persistence requirements are `chmod +x`, absolute paths, and `crond` or the timer enabled.

---

## Verify

```bash
ls -l /root/*.sh                          # every script must show 'x'
head -1 /root/myscript.sh                 # #!/bin/bash
file /root/myscript.sh                    # check for CRLF
bash -n /root/myscript.sh                 # syntax check
bash -x /root/myscript.sh arg1            # trace
./myscript.sh; echo "status: $?"
sudo crontab -l
sudo cat /etc/cron.d/*
systemctl list-timers
```

## Persistence Check

| Item | Persistent because | Also required |
| --- | --- | --- |
| The script | **It is a file on disk** | **`chmod +x`** |
| The shebang | Line 1 of the file | Must be exactly `#!/bin/bash` |
| Scheduled by cron | `/etc/cron.d/` or a user crontab | **`systemctl enable --now crond`** |
| Scheduled by a timer | The unit files | **`daemon-reload` + `enable --now` the `.timer`** |

**Scripts persist by themselves. The things that cost marks:**

1. **No `chmod +x`.** The grader cannot run it. **This is the commonest scripting failure on the exam.**
2. **A missing or wrong shebang.** `[[ ]]`, `=~`, and `(( ))` all fail under `sh`.
3. **CRLF line endings**, giving `bad interpreter: /bin/bash^M`.
4. **A relative path inside the script**, which breaks when run from cron or another directory.

```bash
# The scripting pre-flight check
ls -l /root/myscript.sh                   # is there an x?
head -1 /root/myscript.sh                 # #!/bin/bash ?
bash -n /root/myscript.sh                 # syntax OK?
/root/myscript.sh testarg; echo $?        # does it work from an absolute path?
```

## Quick Reference

Come back here when you need a construct you forgot — not before your first pass through Follow Along.

### Anatomy of a script

```bash
#!/bin/bash
# Description of what this does

USER_LIST="/root/users.txt"

if [[ -f "$USER_LIST" ]]; then
    while read -r name; do
        echo "Processing $name"
    done < "$USER_LIST"
else
    echo "File not found" >&2
    exit 1
fi

exit 0
```

```bash
vim myscript.sh
chmod +x myscript.sh
./myscript.sh
bash myscript.sh                 # runs without the execute bit
```

**Three things every script needs:**

1. **`#!/bin/bash` on line 1.** Without it the script may be interpreted by `sh`.
2. **`chmod +x`.** Without it, `./script.sh` gives "Permission denied".
3. **An absolute path or `./`.** `script.sh` alone fails because `.` is not in `PATH`.

### Positional parameters

| Variable | Meaning |
| --- | --- |
| `$0` | The script's own name |
| **`$1`, `$2`, `$3`** | **The first, second, third argument** |
| `${10}` | **The tenth — braces required beyond 9** |
| **`$#`** | **The number of arguments** |
| **`$@`** | **All arguments, each separately quoted** |
| `$*` | All arguments as one string |
| `$?` | **The exit status of the last command** |
| `$$` | The script's process ID |

**Use `"$@"`, not `"$*"`.** Usage idiom:

```bash
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <filename>" >&2
    exit 1
fi
```

### Conditionals and tests

```bash
if [[ condition ]]; then
    commands
elif [[ other ]]; then
    commands
else
    commands
fi
```

| Syntax | Notes |
| --- | --- |
| `test EXPR` | The original |
| `[ EXPR ]` | POSIX. **Spaces inside brackets mandatory** |
| **`[[ EXPR ]]`** | **Bash. Safer, supports `=~` and `&&`** |
| `(( EXPR ))` | **Arithmetic** |

**File tests:**

| Test | True when |
| --- | --- |
| **`-f FILE`** | **Regular file** |
| **`-d DIR`** | **Directory** |
| **`-e PATH`** | **Exists, any type** |
| `-r`, `-w`, `-x` | Readable / writable / executable |
| `-s FILE` | Non-empty |
| `-L FILE` | Symbolic link |
| `-z STRING` | **Empty string** |
| `-n STRING` | Non-empty string |

**Comparisons:**

| String | Numeric | Meaning |
| --- | --- | --- |
| `=` or `==` | **`-eq`** | Equal |
| `!=` | **`-ne`** | Not equal |
| `<` | **`-lt`** | Less than |
| `>` | **`-gt`** | Greater than |
| | **`-le`, `-ge`** | Less/greater or equal |

**Numbers use `-eq`, `-lt`, `-gt`; strings use `=`, `!=`.** Inside `[ ]`, `>` redirects:

```bash
[ 5 > 3 ]           # creates a file called 3 — WRONG
[ 5 -gt 3 ]         # correct
(( 5 > 3 ))         # also correct
```

Combining: `if [[ -f "$file" && -r "$file" ]]; then`

Regex (bash only): `if [[ "$input" =~ ^[0-9]+$ ]]; then`

### `case`

```bash
case "$1" in
    start)   echo "starting" ;;
    stop)    echo "stopping" ;;
    restart) echo "restarting" ;;
    *)       echo "Usage: $0 {start|stop|restart}" >&2; exit 1 ;;
esac
```

Note `;;` at each branch and `esac` to close. Patterns are globs, not regexes.

### Loops

```bash
# Literal list
for i in one two three; do echo "$i"; done

# Numeric range (literal only — no variables)
for i in {1..10}; do echo "$i"; done
for i in {0..20..5}; do echo "$i"; done

# C-style (variables OK)
for (( i=1; i<=10; i++ )); do echo "$i"; done

# Files — NO quotes around glob
for f in /etc/*.conf; do echo "$f"; done

# Command output
for u in $(cut -d: -f1 /etc/passwd); do echo "$u"; done

# Script arguments
for a in "$@"; do echo "$a"; done
```

```bash
# while — read a file line by line
while read -r line; do
    echo "$line"
done < /etc/hosts

# while with condition
count=1
while [[ $count -le 5 ]]; do
    echo "$count"
    (( count++ ))
done
```

**`while read -r line; do ... done < file` is canonical.** Always `-r`. Redirection after `done`. **Never pipe into `while` if you need variables after** — the loop runs in a subshell.

Loop control: `continue` (skip iteration), `break` (leave loop).

### Command substitution and arithmetic

```bash
count=$(ls /etc | wc -l)
today=$(date +%F)
total=$(( 5 + 3 ))
(( count++ ))
echo $(( 10 / 3 ))               # 3 — integer only
echo "scale=2; 10/3" | bc        # decimals via bc
```

**Use `$(...)`, not backticks.**

### Quoting

| Form | Behaviour |
| --- | --- |
| `"$var"` | **Expands. Use this** |
| `'$var'` | Literal, no expansion |
| `$var` | Expands, **word-splits on whitespace** |
| `"$(cmd)"` | Command output, spaces preserved |

**Quote every variable expansion unless you want word splitting.**

### Exit status

```bash
command
echo $?                          # 0 = success, non-zero = failure

if grep -q "pattern" file; then echo "found"; fi
if ! systemctl is-active --quiet httpd; then echo "not running"; fi
command && echo "worked" || echo "failed"

exit 0                           # success
exit 1                           # failure
```

**`if command; then` tests exit status directly** — idiomatic for `id`, `grep -q`, `systemctl is-active --quiet`.

### Parameter expansion

| Form | Behaviour |
| --- | --- |
| **`${1:-default}`** | **Default if unset or empty** |
| `${1-default}` | Default only if unset |
| `${1:=default}` | Default and assign |
| **`${1:?message}`** | **Error if unset** |
| `${1:+value}` | Use value only if set |
| `${var%pattern}` | Remove shortest match from end |
| `${var%%pattern}` | Remove longest match from end |
| `${var#pattern}` | Remove shortest match from start |
| `${var##pattern}` | Remove longest match from start |
| `${var/old/new}` | Replace first occurrence |
| `${var//old/new}` | Replace all |
| `${#var}` | String length |

### Debugging

```bash
bash -n ./script.sh              # syntax check, run nothing
bash -x ./script.sh              # trace execution
set -x                           # trace from here
set +x                           # stop tracing
set -euo pipefail                # exit on error, undefined vars, pipe failures
set -u                           # error on undefined variable
```

| Symptom | Cause |
| --- | --- |
| No output at all | Condition was false; body never ran |
| Permission denied | **No `chmod +x`** |
| `bad interpreter: ^M` | **CRLF line endings** |
| `unary operator expected` | Unquoted empty variable in `[ ]` |
| Variable empty after loop | **Loop ran in subshell (piped while)** |
| Wrong line counts | `for` over `$(cat file)` instead of `while read` |

### Reading input

```bash
read -p "Enter a name: " name
read -p "Password: " -s pass; echo
```

**Exam scripts are usually graded with arguments (`$1`), not prompts.**

### Output and redirection

```bash
echo "normal output"
echo "error message" >&2         # stderr
printf "%-10s %5d\n" "name" 42
command > /tmp/out 2>/tmp/err
command &> /tmp/all
command &>/dev/null              # discard everything
```

### Text processing inside scripts

```bash
cut -d: -f1 /etc/passwd
awk -F: '{print $1, $3}' /etc/passwd
awk -F: '$3 >= 1000 {print $1}' /etc/passwd
grep -c pattern file
wc -l < file
sort -u file
```

**`awk -F: '{print $1}'` and `cut -d: -f1` are the two you will reach for most.**

## Exam Tips

- **`chmod +x` and confirm with `ls -l`.** The most common way to lose a scripting mark.
- **`#!/bin/bash` on line 1**, no blank line before it.
- **Run it as `./script.sh` or with an absolute path.** `.` is not in `PATH`.
- **`$1`, `$2` for arguments; `$#` for the count; `"$@"` to iterate.** Braces beyond nine: `${10}`.
- **The usage idiom:** `if [[ $# -ne 1 ]]; then echo "Usage: $0 <arg>" >&2; exit 1; fi`.
- **`>&2` for errors, `exit 1` for failure.**
- **Numbers use `-eq -ne -lt -gt -le -ge`; strings use `= != `.** Inside `[ ]`, `>` redirects and creates a file.
- **Use `[[ ]]` rather than `[ ]`.** It is safer with empty variables and supports `=~`.
- **File tests: `-f` regular file, `-d` directory, `-e` exists, `-z` empty string, `-n` non-empty.**
- **Quote every variable expansion**: `"$var"`, `[[ -f "$file" ]]`. Leave the `=~` pattern unquoted.
- **`while read -r line; do ... done < file`** to read a file. **Never `for line in $(cat file)`** — it splits on whitespace.
- **Never pipe into a `while` loop if you need a variable afterwards.** The loop runs in a subshell. Use `< file` or `< <(command)`.
- **`while IFS=: read -r user _ uid _; do ... done < /etc/passwd`** to parse colon-separated fields.
- **`$(...)` for command substitution**, not backticks.
- **`if command; then`** tests exit status directly. `systemctl is-active --quiet`, `id user &>/dev/null`, `grep -q`, `rpm -q`.
- **`$(( ))` for arithmetic, integer only.** `bc` or `awk` for decimals.
- **`${1:-default}`** for an optional argument; **`${1:?message}`** for a required one.
- **`${var%pattern}` and `${var##pattern}`** trim strings without calling `sed`.
- **`{1..10}` for a literal range**, but it does not accept variables — use `seq` or `for (( ))`.
- **`case ... esac` with `;;`** for subcommands. Put `*)` last.
- **`sort -h` not `sort -n`** when sorting human-readable sizes.
- **`wc -l < file`** gives just the number; `wc -l file` appends the filename.
- **`bash -n` for syntax, `bash -x` to trace.** `bash -x` is the fastest way to see what actually happened.
- **`set -euo pipefail`** for robustness; `set -u` catches typos in variable names.
- **Use `<<'EOF'` with quotes** when writing a script via a heredoc, or `$1` is expanded as you write it.
- **cron needs absolute paths and `crond` enabled.** For a timer, `daemon-reload` and enable the `.timer`.
- **`sed -i 's/\r$//' script.sh`** fixes `bad interpreter: ^M`.
