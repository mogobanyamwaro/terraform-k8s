## Updated Notes with Your Key Learning

Here's your **updated** Linux Permissions Playground with the critical lesson you just discovered:

---

namei -l /home/douglasmogoba/perm-lab/secret.txt

# 🧪 MINI PROJECT: Linux Permissions Playground

We’ll create:

- a folder
- a file
- 2 users/groups (simulated via groups)
- then change permissions step by step

---

# 📁 STEP 1 — Create workspace

```bash
mkdir ~/perm-lab
cd ~/perm-lab
```

---

# 📄 STEP 2 — Create a file

```bash
echo "hello permissions" > secret.txt
```

Check:

```bash
ls -l
```

You’ll see something like:

```
-rw-r--r-- 1 ubuntu ubuntu 18 secret.txt
```

---

# 🧠 STEP 3 — Understand current state

Break it:

- owner = ubuntu
- group = ubuntu
- permissions = rw-r--r--

Meaning:

- you can read/write
- everyone else can read

---

# 👥 STEP 4 — Create a test group

```bash
sudo groupadd devteam
```

Add yourself:

```bash
sudo usermod -aG devteam $USER
```

⚠️ **Important:** you must restart session for group change to fully apply.

Check:

```bash
groups  # May not show immediately until re-login
id      # Shows system truth immediately
```

---

# 🔁 STEP 5 — Change group ownership

```bash
sudo chgrp devteam secret.txt
```

Check:

```bash
ls -l
```

Now:

```
-rw-r--r-- 1 ubuntu devteam secret.txt
```

---

# 🔐 STEP 6 — Remove "others" access

Now we lock it down:

```bash
chmod o-r secret.txt
```

Check:

```
-rw-r----- 1 ubuntu devteam secret.txt
```

Meaning:

- owner: full access
- group: read only
- others: nothing

---

# 🔧 STEP 7 — Give group write access

```bash
chmod g+w secret.txt
```

Now:

```
-rw-rw---- 1 ubuntu devteam secret.txt
```

Now group members can edit too.

---

# 🚨 STEP 8 — Test as another user

Create another user:

```bash
sudo adduser mogoba
sudo usermod -aG devteam mogoba
```

Switch user:

```bash
su - mogoba
```

Try:

```bash
cat /home/ubuntu/perm-lab/secret.txt
```

---

# 🧠 Expected behavior (INITIAL TRY)

If permissions are correct:

- group can read/write
- others cannot access

If not:

- "Permission denied"

---

# 🔥 THE CRITICAL LESSON YOU DISCOVERED

## The Hidden Barrier: Parent Directory Permissions

Even with correct file/folder permissions, **parent directories can block access**.

### The Problem:

```bash
mogoba@worker3:~$ ls -ld /home/ubuntu
drwxr-x--- 7 ubuntu ubuntu 4096  # ← OTHERS HAVE NO EXECUTE (---)
```

- `mogoba` is NOT `ubuntu` (owner)
- `mogoba` is NOT in `ubuntu` group
- `others` have NO execute permission on `/home/ubuntu`

**Result:** `mogoba` cannot traverse through `/home/ubuntu` to reach `perm-lab`

### The Fix:

```bash
ubuntu@worker3:~$ chmod 755 /home/ubuntu
# Now: drwxr-xr-x (others have r-x)
```

### The Proof:

```bash
mogoba@worker3:~$ cat /home/ubuntu/perm-lab/secret.txt
hello world permissions  # ← WORKS!
```

---

# 🧠 MENTAL MODEL (UPDATED)

Think of directory access like **opening multiple doors**:

```
/home/ubuntu/perm-lab/secret.txt

Door 1: /home/ubuntu        ← Need execute (--x) to enter
Door 2: perm-lab/           ← Need execute (--x) to enter
Door 3: secret.txt          ← Need read (r--) to view
```

**If ANY door is locked, you can't reach the file!**

---

# 📊 Permission Requirements for Access

| Action         | Directory needs            | File needs    |
| -------------- | -------------------------- | ------------- |
| `ls` directory | execute (--x)              | -             |
| `cat` file     | execute on ALL parent dirs | read (r--)    |
| `cd` into      | execute (--x)              | -             |
| Edit file      | execute on parent dirs     | write (-w-)   |
| Run script     | execute on parent dirs     | execute (--x) |

---

# 🔑 The "Traverse" Permission

```bash
# Execute permission on a directory = "traverse" or "search" permission
# Allows you to pass THROUGH the directory to reach contents

chmod o+x /home/ubuntu    # Allows others to traverse
chmod 755 /home/ubuntu    # Same: rwxr-xr-x
```

---

# ⚠️ Common Permission Issues (Troubleshooting)

### Issue 1: "Permission denied" even with correct file perms

```bash
# Check parent directories
namei -l /home/ubuntu/perm-lab/secret.txt
# Shows permissions for EVERY path component
```

### Issue 2: Group changes not applying

```bash
# System truth vs current session
id mogoba        # Shows actual group membership
groups          # Shows current session's groups

# Fix: Re-login or use 'newgrp'
newgrp devteam   # Apply group to current session
```

### Issue 3: Can't access file but can see it

```bash
# Check execute permission on parent dirs
ls -ld /home/ubuntu
ls -ld /home/ubuntu/perm-lab
```

---

# 🔐 STEP 9 — Make file private (owner only)

Back to original user:

```bash
chmod 700 secret.txt
```

Now:

```
-rwx------ 1 ubuntu devteam secret.txt
```

Meaning:

- only owner can read/write/execute
- group + others blocked

---

# 🔥 STEP 10 — The "Real Admin" Scenario You Solved

**Situation:** User `mogoba` is in `devteam` group, `perm-lab` is owned by `ubuntu:devteam` with `770` permissions, but `mogoba` still can't access.

**Diagnosis:**

```bash
# Check the path
ls -ld /home/ubuntu           # ← Found the problem!
# drwxr-x--- ← others have no execute
```

**Solution:**

```bash
sudo chmod 755 /home/ubuntu   # Add traverse permission for others
```

**Lesson Learned:** Always check the **ENTIRE PATH**, not just the target file/folder.

---

# 🧠 WHAT YOU JUST LEARNED (IMPORTANT)

You now understand:

### 1. Ownership

```bash
chown / chgrp
```

### 2. Permissions

```bash
chmod
```

### 3. Access layers

- user
- group
- others

### 4. Real-world behavior

- who can read files
- who can edit configs
- who is blocked

### 5. ⭐ PARENT DIRECTORY PERMISSIONS ⭐

- Execute permission on directories controls traversal
- A locked parent = locked everything inside
- `namei -l` shows full path permissions

---

# 🧠 UPDATED MENTAL MODEL

Think of it as **multiple doors**:

```
File = locked box in a locked building

Each directory = door you must pass through
Execute permission = key to open that door

Building door (/home/ubuntu) ← NEED KEY
Office door (perm-lab)       ← NEED KEY
File box (secret.txt)        ← NEED READ PERMISSION
```

If any door is locked → "Permission denied"

---

# 🛠️ Useful Diagnostic Commands

```bash
# See full path permissions
namei -l /home/ubuntu/perm-lab/secret.txt

# Check specific user's access
sudo -u mogoba ls -la /home/ubuntu/perm-lab/

# Check current vs actual groups
groups vs id

# Fix parent directory traversal
chmod 755 /home/ubuntu        # Give others execute
chmod 750 /home/ubuntu        # Give group execute only
```

---

# ⚠️ IMPORTANT WARNING

Be careful with:

```bash
chmod 777 /home/ubuntu    # Too permissive! Others can see everything
```

Better approach:

```bash
chmod 755 /home/ubuntu    # Others can traverse, not read contents
# drwxr-xr-x
```

For shared access:

```bash
# Create shared directory outside home
sudo mkdir /shared
sudo chgrp devteam /shared
sudo chmod 770 /shared     # Only owner and group
```

---

# 🧠 ONE-LINE MEMORY

> Permissions control file access, but **parent directory execute permission** controls if you can even reach the file.

---

# 🔥 NEXT LEVEL: Real Admin Scenarios

Now you're ready for:

- Web server permissions (`/var/www` → 403 Forbidden)
- Shared team directories (umask, sticky bits)
- Sudoers file permissions (must be 440!)
- SSH key permissions (must be 600)

Your discovery today is **exactly** what confuses most Linux beginners (and even some admins!). Great work debugging it! 🎯
