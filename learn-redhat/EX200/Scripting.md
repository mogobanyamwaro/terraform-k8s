# Shell Scripting Deep Dive

Four objectives, roughly 5% of the exam, and entirely predictable: conditionals, loops, positional parameters, and processing command output. The scripts the exam asks for are twenty lines at most. Step-by-step tasks are in `33-shell-scripting.md`.

**The single most common way to fail a scripting task is forgetting `chmod +x`.**

---

## Anatomy

```bash
#!/bin/bash
#
# Usage: check-users.sh USERFILE
# Reports which usernames in USERFILE exist on this system.

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 USERFILE" >&2
    exit 1
fi

USERFILE="$1"

if [[ ! -f "$USERFILE" ]]; then
    echo "Error: $USERFILE does not exist" >&2
    exit 2
fi

while read -r username; do
    [[ -z "$username" ]] && continue
    if id "$username" &>/dev/null; then
        echo "EXISTS:  $username"
    else
        echo "MISSING: $username"
    fi
done < "$USERFILE"

exit 0
```

```bash
sudo vim /usr/local/bin/check-users.sh
sudo chmod +x /usr/local/bin/check-users.sh
bash -n /usr/local/bin/check-users.sh          # syntax check
/usr/local/bin/check-users.sh /tmp/names.txt
echo $?
```

**Five structural requirements:**

1. **`#!/bin/bash` as the very first line**, column 1, no leading space or blank line.
2. **`chmod +x`.**
3. **A location on `$PATH`** if the task says the script must be runnable by name. `/usr/local/bin` is the conventional place.
4. **Quote every variable expansion.**
5. **Exit with a meaningful status.**

```bash
echo $PATH
ls -l /usr/local/bin/
```

### Running a script four ways

| Invocation | Needs `+x` | Runs in |
| --- | --- | --- |
| `./script.sh` | **Yes** | A child shell |
| `/usr/local/bin/script.sh` | **Yes** | A child shell |
| `bash script.sh` | No | A child shell |
| **`source script.sh`** or **`. script.sh`** | No | **The current shell** |

**`bash script.sh` works without `+x`, which is how people convince themselves a script is fine when the grader's test will fail.** Test with `./script.sh`.

**`source` runs in your current shell**, so variables and `cd` persist — useful for configuration snippets, wrong for a normal script.

---

## Positional parameters

| Variable | Meaning |
| --- | --- |
| `$0` | The script's own path as invoked |
| `$1` ... `$9` | Arguments one to nine |
| `${10}` | **Braces required from ten upward** |
| **`$#`** | **How many arguments** |
| **`"$@"`** | **All arguments, each individually quoted. THE correct form** |
| `"$*"` | All arguments joined into one word |
| `shift` | Discard `$1`, renumber the rest |
| `shift 2` | Discard two |

```bash
#!/bin/bash
echo "script:    $0"
echo "count:     $#"
echo "first:     $1"
echo "all:       $@"

for arg in "$@"; do
    echo "  arg: [$arg]"
done
```

```bash
./args.sh one "two three" four
```

```text
count:     3
  arg: [one]
  arg: [two three]
  arg: [four]
```

**With `$@` unquoted, or with `"$*"`, that middle argument breaks apart or merges.** `"$@"` is the only form that preserves arguments containing spaces, and it is worth using out of habit.

### Validation

```bash
# Exactly one argument
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 FILE" >&2
    exit 1
fi

# At least one
if (( $# < 1 )); then
    echo "Usage: $0 USER [USER...]" >&2
    exit 1
fi

# With a default
THRESHOLD="${1:-80}"

# Required, with an error message
INPUT="${1:?a filename is required}"
```

| Expansion | Meaning |
| --- | --- |
| `${var:-default}` | Use `default` if `var` is unset or empty |
| `${var:=default}` | The same, and assign it |
| `${var:?message}` | Error out with `message` if unset |
| `${var:+alt}` | Use `alt` only if `var` is set |
| `${#var}` | Length |
| `${var#prefix}`, `${var%suffix}` | Strip from the front or back |
| `${var//old/new}` | Replace every occurrence |

```bash
f="report.txt"
echo "${f%.txt}.bak"                  # report.bak
echo "${f#rep}"                       # ort.txt
echo "${f//t/T}"                      # reporT.TxT
```

---

## Conditionals

### `[[ ]]`, `[ ]`, and `(( ))`

| Form | Use for |
| --- | --- |
| **`[[ ... ]]`** | **Bash's test. Strings, files, patterns. What you should use** |
| `[ ... ]` | POSIX test. Requires more quoting care |
| **`(( ... ))`** | **Arithmetic. No `$` needed on variable names** |
| `test ...` | The same as `[ ... ]` |

```bash
[[ -f "$file" ]]
[[ "$name" = "alice" ]]
[[ "$name" == a* ]]                   # pattern matching — only in [[ ]]
[[ "$name" =~ ^a.*e$ ]]               # regex — only in [[ ]]
(( count > 5 ))
(( count++ ))
[[ $# -eq 1 ]]
```

**`[[ ]]` does not word-split or glob-expand, so it forgives an unquoted variable where `[ ]` would break:**

```bash
file="my report.txt"
[ -f $file ]                          # bash: [: too many arguments
[[ -f $file ]]                        # works
[[ -f "$file" ]]                      # correct regardless
```

**Quote anyway. It costs one character and works in both forms.**

### File tests

| Test | True when |
| --- | --- |
| **`-e path`** | **Exists, any type** |
| **`-f path`** | **A regular file** |
| **`-d path`** | **A directory** |
| `-L path` | A symbolic link |
| `-b`, `-c`, `-p`, `-S` | Block, character, pipe, socket |
| **`-r`, `-w`, `-x`** | **Readable, writable, executable by the current user** |
| `-s path` | Exists and is non-empty |
| `-u`, `-g`, `-k` | SUID, SGID, sticky |
| `-O`, `-G` | Owned by you, owned by your group |
| `f1 -nt f2`, `-ot` | Newer than, older than |

```bash
if [[ -d "$dir" ]]; then echo "directory"
elif [[ -f "$dir" ]]; then echo "file"
elif [[ -e "$dir" ]]; then echo "something else"
else echo "does not exist"; fi
```

### String tests

| Test | True when |
| --- | --- |
| **`-z "$s"`** | **Empty** |
| **`-n "$s"`** | **Not empty** |
| **`"$a" = "$b"`** | **Equal (`==` also works in `[[ ]]`)** |
| `"$a" != "$b"` | Not equal |
| `"$a" < "$b"` | Sorts before |
| `"$s" == pat*` | Matches a glob (`[[ ]]` only) |
| `"$s" =~ regex` | Matches a regex (`[[ ]]` only) |

### Numeric tests

| Test | Meaning |
| --- | --- |
| **`-eq`** | equal |
| **`-ne`** | not equal |
| **`-lt`, `-le`** | less than, less or equal |
| **`-gt`, `-ge`** | greater than, greater or equal |

**Or `(( ))` with the familiar symbols:**

```bash
(( a == b )) ; (( a != b )) ; (( a < b )) ; (( a >= b ))
```

**`=` is for strings; `-eq` is for numbers. Mixing them is the classic bug:**

```bash
count=10
[[ $count -gt 5 ]] && echo yes        # TRUE — numeric
[[ $count > 5 ]]   && echo yes        # FALSE — "10" sorts before "5"
(( count > 5 ))    && echo yes        # TRUE
```

### Testing exit status directly

```bash
if grep -q '^root' /etc/passwd; then
    echo found
fi

if ! id "$user" &>/dev/null; then
    echo "no such user" >&2
    exit 1
fi

if systemctl is-active --quiet httpd; then
    echo running
fi

if ping -c1 -W2 server2 &>/dev/null; then
    echo reachable
fi
```

**`if command; then` is cleaner than `command; if [[ $? -eq 0 ]]`.** And `-q` or `&>/dev/null` keeps the output out of the way. **This is the idiom the exam expects for "check whether X exists".**

### Combining

```bash
if [[ -f "$f" && -r "$f" ]]; then ...
if [[ -f "$f" ]] && [[ -r "$f" ]]; then ...
if [[ ! -f "$f" ]] || [[ -z "$content" ]]; then ...
[[ -f "$f" ]] && echo "exists"
[[ -f "$f" ]] || echo "missing"
[[ -d /backup ]] || mkdir -p /backup
```

**`&&` and `||` as one-liners are idiomatic and readable for a single action.** For anything longer, use a full `if`.

**A caution about `set -e` and `&&`:** a failing `[[ ]]` in a one-liner is a non-zero exit status, which under `set -e` terminates the script. Use `[[ ... ]] && cmd || true` or a full `if` when `set -e` is in effect.

### case

```bash
case "$1" in
    start|begin)
        echo "starting"
        ;;
    stop)
        echo "stopping"
        ;;
    *.txt)
        echo "a text file"
        ;;
    [0-9]*)
        echo "starts with a digit"
        ;;
    *)
        echo "Usage: $0 {start|stop}" >&2
        exit 1
        ;;
esac
```

**`case` is better than a chain of `elif` when matching one variable against several patterns**, and it is the natural shape for a script that takes a subcommand.

---

## Loops

### for

```bash
for f in /etc/*.conf; do echo "$f"; done
for i in {1..10}; do echo "$i"; done
for i in {0..20..5}; do echo "$i"; done          # step 5
for i in $(seq 1 10); do echo "$i"; done
for ((i=0; i<10; i++)); do echo "$i"; done
for u in "$@"; do id "$u"; done
for u in alice bob carol; do sudo useradd "$u"; done
for s in httpd sshd firewalld; do systemctl is-enabled "$s"; done
for h in server1 server2; do ssh "$h" hostname; done
```

**A glob that matches nothing expands to itself**, which produces a bogus iteration:

```bash
for f in /tmp/*.nothing; do
    [[ -e "$f" ]] || continue          # the guard
    echo "$f"
done
```

**Or set `nullglob`:**

```bash
shopt -s nullglob
for f in /tmp/*.nothing; do echo "$f"; done      # zero iterations
```

**Never loop over `$(ls)`.** It breaks on filenames with spaces. Use a glob.

### while read

**The correct way to process a file line by line:**

```bash
while read -r line; do
    echo "[$line]"
done < /etc/passwd
```

| Element | Why |
| --- | --- |
| **`-r`** | **Do not interpret backslashes** |
| **`< file`** | **Redirect into the loop, not a pipe** |
| `IFS=` | Preserve leading and trailing whitespace |

```bash
while IFS= read -r line; do echo "[$line]"; done < file
while IFS=: read -r user _ uid _ _ home shell; do
    echo "$user $uid $shell"
done < /etc/passwd
```

**`IFS=:` splits on colons, so this parses `/etc/passwd` with no `cut` or `awk` at all.** `_` is a conventional throwaway name.

### The subshell trap

```bash
count=0
grep -c . /etc/passwd | while read -r n; do count=$n; done
echo "$count"                          # 0 — the assignment was lost
```

**A pipe creates a subshell. Variables set inside it vanish when it ends.**

Three ways round it:

```bash
# 1. Process substitution — the best general answer
count=0
while read -r n; do count=$n; done < <(grep -c . /etc/passwd)
echo "$count"

# 2. A here-string, for a single value
while read -r n; do count=$n; done <<< "$(grep -c . /etc/passwd)"

# 3. Command substitution, when a loop is not needed
count=$(grep -c . /etc/passwd)
```

**`< <(command)` is the pattern to memorise.** Note the space between the two `<`.

**`mapfile` is the modern alternative for reading a whole command's output:**

```bash
mapfile -t users < <(cut -d: -f1 /etc/passwd)
echo "${#users[@]}"
echo "${users[0]}"
for u in "${users[@]}"; do echo "$u"; done
```

### while and until

```bash
count=0
while (( count < 5 )); do
    echo "$count"
    (( count++ ))
done

until [[ -f /tmp/ready ]]; do
    sleep 1
done

while true; do
    check_something
    sleep 60
done
```

### break and continue

```bash
for f in /var/log/*.log; do
    [[ -s "$f" ]] || continue          # skip empty files
    grep -q ERROR "$f" || continue     # skip files with no errors
    echo "errors in $f"
    (( ++found >= 3 )) && break        # stop after three
done
```

---

## Command substitution and arithmetic

```bash
now=$(date +%F)
hostname=$(hostname -s)
count=$(grep -c . /etc/passwd)
users=$(awk -F: '$3>=1000 {print $1}' /etc/passwd)
lines=$(wc -l < file)                  # < avoids the filename in the output
```

**`$(...)` is preferred over backticks** — it nests and is easier to read.

```bash
echo "$(basename "$(dirname /a/b/c)")"
```

```bash
total=$(( a + b ))
pct=$(( used * 100 / size ))
(( count++ )) ; (( count += 5 ))
half=$(( n / 2 ))                      # INTEGER division: 7/2 = 3
rem=$(( n % 2 ))
let "x = y + 1"
```

**Bash arithmetic is integer only.** For decimals, `bc` or `awk`:

```bash
avg=$(echo "scale=2; $total / $count" | bc)
avg=$(awk -v t="$total" -v c="$count" 'BEGIN{printf "%.2f", t/c}')
```

**`wc -l < file` rather than `wc -l file`** — the redirect gives you a bare number instead of "42 file".

---

## Output and input

```bash
echo "text"
echo -n "no trailing newline"
echo -e "tab\there\nnewline"
printf '%s\n' "$var"
printf '%-20s %5d\n' "$name" "$count"
printf '%.2f\n' "$value"
printf '%s\n' "${array[@]}"
```

**`printf` is more predictable than `echo` for anything formatted**, and it is what you want for aligned columns:

```bash
printf '%-16s %-10s %s\n' "SERVICE" "ENABLED" "ACTIVE"
for s in httpd sshd firewalld; do
    printf '%-16s %-10s %s\n' "$s" \
      "$(systemctl is-enabled "$s" 2>/dev/null)" \
      "$(systemctl is-active "$s" 2>/dev/null)"
done
```

```bash
echo "error message" >&2               # to stderr
printf 'error: %s\n' "$msg" >&2
```

**Error messages belong on stderr.** Graders may not check, but it is correct and it keeps errors out of a pipeline.

```bash
read -p "Enter a name: " name
read -s -p "Password: " pass; echo
read -r -t 10 -p "Answer within 10s: " answer
read -r line < file                    # just the first line
read -r a b c <<< "one two three"
```

**Interactive `read` is rare in exam scripts** — a script the grader runs cannot answer prompts. Take input from arguments or a file instead.

---

## Exit status

```bash
exit 0                                 # success
exit 1                                 # generic failure
exit 2                                 # usage error, by convention
exit "$?"                              # pass along the last status
```

| Status | Convention |
| --- | --- |
| **0** | **Success** |
| 1 | General error |
| 2 | Misuse of the command |
| 126 | Found but not executable |
| **127** | **Command not found** |
| 128+n | Killed by signal n; 130 is Ctrl-C |

```bash
command
echo "$?"
if [[ $? -ne 0 ]]; then echo "failed"; fi      # works, but...
if ! command; then echo "failed"; fi           # ...this is better
```

**`$?` is fragile because it changes with every command, including the `echo` you just ran.** Test the command directly.

**A script with no explicit `exit` returns the status of its last command.** Be deliberate:

```bash
#!/bin/bash
main_work || exit 1
echo "done"
exit 0
```

---

## `set` options

```bash
set -e                                 # exit on any unchecked failure
set -u                                 # error on an unset variable
set -o pipefail                        # a pipeline fails if any stage fails
set -x                                 # trace
set -euo pipefail                      # the conventional combination
```

```bash
#!/bin/bash
set -euo pipefail
```

**Two caveats to know before using `set -e` on the exam:**

**It exits on a failing test in a one-liner:**

```bash
set -e
[[ -f /nonexistent ]] && echo "found"      # the script EXITS here
```

**And it does not fire inside an `if` condition or after `||`:**

```bash
set -e
if ! command; then echo "handled"; fi      # fine
command || echo "handled"                  # fine
```

**For a twenty-line exam script, explicit error checks are clearer than `set -e`.** Use `set -e` when you know why you want it.

---

## Debugging

```bash
bash -n script.sh                      # SYNTAX only, no execution
bash -x script.sh                      # trace every command
bash -xv script.sh                     # trace plus the raw source
```

```bash
set -x                                 # trace from here
problematic_section
set +x                                 # stop tracing
```

```text
+ USERFILE=/tmp/names.txt
+ [[ ! -f /tmp/names.txt ]]
+ read -r username
+ id alice
+ echo 'EXISTS:  alice'
EXISTS:  alice
```

**`bash -n` before every run.** It catches an unclosed quote or a missing `fi` in a second, and those are the errors that produce the most confusing symptoms.

```bash
PS4='+ ${BASH_SOURCE}:${LINENO}: ' bash -x script.sh    # line numbers in the trace
```

| Symptom | Cause |
| --- | --- |
| `Permission denied` | **Missing `chmod +x`** |
| `bad interpreter: No such file or directory` | **Windows line endings — run `dos2unix` or `sed -i 's/\r$//'`** |
| `command not found` | Not on `$PATH`; use an absolute path |
| `unexpected end of file` | An unclosed `if`, `do`, quote, or brace |
| `too many arguments` in `[ ]` | An unquoted variable containing spaces |
| `integer expression expected` | A string where a number was expected |
| Variable empty after a loop | **The loop ran in a subshell — a pipe** |
| Works interactively, fails in cron | **cron's minimal `PATH`; use absolute paths** |

```bash
file script.sh                         # detects CRLF line endings
sed -i 's/\r$//' script.sh
```

---

## Text processing inside scripts

```bash
cut -d: -f1 /etc/passwd
cut -d: -f1,3 /etc/passwd
cut -c1-10 file
awk -F: '{print $1, $3}' /etc/passwd
awk -F: '$3 >= 1000 {print $1}' /etc/passwd
awk -F: '$7 ~ /nologin/ {print $1}' /etc/passwd
awk '{sum += $1} END {print sum}' numbers.txt
awk 'NR==2 {print $5}' file
awk 'NR>1' file                        # skip the header
awk -F: 'BEGIN{OFS=":"} {$7="/bin/sh"; print}' /etc/passwd
sed 's/old/new/' file                  # first occurrence per line
sed 's/old/new/g' file                 # all occurrences
sed -i.bak 's/old/new/g' file          # in place, with a backup
sed -n '5,10p' file                    # print lines 5-10
sed '/^#/d;/^$/d' file                 # drop comments and blanks
sed -i '/pattern/d' file
sed '1i\header line' file              # insert before line 1
tr 'a-z' 'A-Z' < file
tr -d '\r' < file
tr -s ' ' < file                       # squeeze repeats
sort -n ; sort -r ; sort -u ; sort -t: -k3 -n ; sort -h
uniq -c ; uniq -d ; sort file | uniq -c | sort -rn
wc -l ; wc -w ; wc -c
head -n5 ; tail -n5 ; tail -n +2       # skip the first line
grep -c pattern file ; grep -o pattern file ; grep -v '^#' file
paste f1 f2 ; join f1 f2 ; column -t ; nl file ; tac file
xargs -I{} cmd {} ; xargs -n1 ; find . -print0 | xargs -0 cmd
```

**Extracting a percentage from `df`, a pattern that appears constantly:**

```bash
df -h / | awk 'NR==2 {gsub(/%/,"",$5); print $5}'
df -h --output=pcent / | tail -1 | tr -dc '0-9'
```

---

## Worked examples

### A user report

**Task: a script that takes a filename, reads usernames one per line, and reports for each whether the account exists, is locked, and when its password expires.**

```bash
sudo tee /usr/local/bin/userreport.sh >/dev/null <<'EOF'
#!/bin/bash
#
# Usage: userreport.sh USERFILE

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 USERFILE" >&2
    exit 1
fi

USERFILE="$1"

if [[ ! -f "$USERFILE" ]]; then
    echo "Error: $USERFILE not found" >&2
    exit 2
fi

printf '%-14s %-8s %-8s %s\n' "USER" "EXISTS" "LOCKED" "PW EXPIRES"

while read -r user; do
    [[ -z "$user" || "$user" == \#* ]] && continue

    if ! id "$user" &>/dev/null; then
        printf '%-14s %-8s %-8s %s\n' "$user" "no" "-" "-"
        continue
    fi

    status=$(passwd -S "$user" 2>/dev/null | awk '{print $2}')
    if [[ "$status" == "L" ]]; then
        locked="yes"
    else
        locked="no"
    fi

    expires=$(chage -l "$user" 2>/dev/null | awk -F': ' '/Password expires/{print $2}')

    printf '%-14s %-8s %-8s %s\n' "$user" "yes" "$locked" "${expires:-unknown}"
done < "$USERFILE"

exit 0
EOF

sudo chmod +x /usr/local/bin/userreport.sh
bash -n /usr/local/bin/userreport.sh
printf 'root\nalice\nnosuchuser\n' > /tmp/names.txt
sudo /usr/local/bin/userreport.sh /tmp/names.txt
```

```text
USER           EXISTS   LOCKED   PW EXPIRES
root           yes      no       never
alice          yes      no       Oct 17, 2026
nosuchuser     no       -        -
```

### A disk usage check for a timer

**Task: a script that reports every filesystem above a threshold given as the first argument, defaulting to 80.**

```bash
sudo tee /usr/local/bin/diskalert.sh >/dev/null <<'EOF'
#!/bin/bash
#
# Usage: diskalert.sh [THRESHOLD]

THRESHOLD="${1:-80}"

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Error: threshold must be a number" >&2
    exit 2
fi

exitcode=0

while read -r pct mount; do
    pct="${pct%\%}"
    if (( pct > THRESHOLD )); then
        echo "WARNING: $mount is ${pct}% full (threshold ${THRESHOLD}%)"
        exitcode=1
    fi
done < <(df -h --output=pcent,target -x tmpfs -x devtmpfs | tail -n +2)

exit "$exitcode"
EOF

sudo chmod +x /usr/local/bin/diskalert.sh
bash -n /usr/local/bin/diskalert.sh
sudo /usr/local/bin/diskalert.sh 10        # low threshold, to see output
echo "exit status: $?"
sudo /usr/local/bin/diskalert.sh
```

**Note the four techniques in eight lines: a default with `${1:-80}`, a regex validation, `< <(...)` to avoid the subshell, and a meaningful exit status.**

Then schedule it, either way:

```bash
# cron
echo '0 * * * * root /usr/local/bin/diskalert.sh 85' \
  | sudo tee /etc/cron.d/diskalert
sudo systemctl enable --now crond
```

```bash
# or a systemd timer
sudo tee /etc/systemd/system/diskalert.service >/dev/null <<'EOF'
[Unit]
Description=Disk usage alert

[Service]
Type=oneshot
ExecStart=/usr/local/bin/diskalert.sh 85
EOF

sudo tee /etc/systemd/system/diskalert.timer >/dev/null <<'EOF'
[Unit]
Description=Hourly disk usage alert

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now diskalert.timer
systemctl list-timers | grep diskalert
sudo systemctl start diskalert.service
sudo journalctl -u diskalert.service -n 10
```

### Bulk user creation

```bash
sudo tee /usr/local/bin/mkusers.sh >/dev/null <<'EOF'
#!/bin/bash
#
# Usage: mkusers.sh CSVFILE     (username:group:shell)

if [[ $# -ne 1 || ! -f "$1" ]]; then
    echo "Usage: $0 CSVFILE" >&2
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Error: must run as root" >&2
    exit 3
fi

while IFS=: read -r user group shell; do
    [[ -z "$user" || "$user" == \#* ]] && continue

    if id "$user" &>/dev/null; then
        echo "SKIP:    $user already exists"
        continue
    fi

    getent group "$group" >/dev/null || groupadd "$group"

    if useradd -g "$group" -s "${shell:-/bin/bash}" -m "$user"; then
        chage -d 0 "$user"
        echo "CREATED: $user (group $group, shell ${shell:-/bin/bash})"
    else
        echo "FAILED:  $user" >&2
    fi
done < "$1"

exit 0
EOF

sudo chmod +x /usr/local/bin/mkusers.sh
printf 'dave:devs:/bin/bash\neve:devs:/sbin/nologin\n' > /tmp/users.csv
sudo /usr/local/bin/mkusers.sh /tmp/users.csv
id dave ; id eve
sudo chage -l dave | head -3
```

**`IFS=: read -r a b c` parses colon-separated input with no external command**, and `$EUID` is how a script checks it is running as root.

---

## Verification

```bash
ls -l /usr/local/bin/script.sh         # look for x
head -1 /usr/local/bin/script.sh       # #!/bin/bash, column 1
file /usr/local/bin/script.sh          # detects CRLF line endings
bash -n /usr/local/bin/script.sh       # syntax
/usr/local/bin/script.sh               # run it with no arguments
echo $?                                # expect a usage error and non-zero
/usr/local/bin/script.sh valid-input
echo $?                                # expect 0
bash -x /usr/local/bin/script.sh args  # trace, if it misbehaves
```

**Test the failure paths as well as the success path.** A task saying "the script must report an error if the file does not exist" is graded by running it with a nonexistent file.

---

## The five things to take away

1. **`chmod +x`.** The most common cause of a zero on a scripting task.
2. **`#!/bin/bash` on line one, and quote every variable: `"$1"`, `"$@"`, `"$var"`.**
3. **`=` for strings, `-eq` for numbers.** `(( ))` for arithmetic.
4. **`while read -r line; do ... done < file`, and `< <(command)` for command output.** Never `cmd | while read`.
5. **`bash -n` before running, `bash -x` when it misbehaves.**
