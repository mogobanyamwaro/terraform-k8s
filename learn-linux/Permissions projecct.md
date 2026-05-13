

# 🧪 MINI PROJECT: Linux Permissions Playground

We’ll create:

* a folder
* a file
* 2 users/groups (simulated via groups)
* then change permissions step by step

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
-rw-r--r-- 1 douglas douglas 18 secret.txt
```

---

# 🧠 STEP 3 — Understand current state

Break it:

* owner = douglas
* group = douglas
* permissions = rw-r--r--

Meaning:

* you can read/write
* everyone else can read

---

# 👥 STEP 4 — Create a test group

```bash
sudo groupadd devteam
```

Add yourself:

```bash
sudo usermod -aG devteam $USER
```

⚠️ Important: you must restart session for group change to fully apply.

Check:

```bash
groups
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
-rw-r--r-- 1 douglas devteam secret.txt
```

---

# 🔐 STEP 6 — Remove “others” access

Now we lock it down:

```bash
chmod o-r secret.txt
```

Check:

```
-rw-r----- 1 douglas devteam secret.txt
```

Meaning:

* owner: full access
* group: read only
* others: nothing

---

# 🔧 STEP 7 — Give group write access

```bash
chmod g+w secret.txt
```

Now:

```
-rw-rw---- 1 douglas devteam secret.txt
```

Now group members can edit too.

---

# 🚨 STEP 8 — Test as another user (simulation)

Create another user:

```bash
sudo adduser testuser
sudo usermod -aG devteam testuser
```

Switch user:

```bash
su - testuser
```

Try:

```bash
cat /home/douglas/perm-lab/secret.txt
```

---

# 🧠 Expected behavior

If permissions are correct:

* group can read/write
* others cannot access

If not:

* “Permission denied”

---

# 🔐 STEP 9 — Make file private (owner only)

Back to original user:

```bash
chmod 700 secret.txt
```

Now:

```
-rwx------ 1 douglas devteam secret.txt
```

Meaning:

* only owner can read/write/execute
* group + others blocked

---

# 🔥 STEP 10 — Restore safe state

```bash
chmod 644 secret.txt
```

Back to normal:

```
-rw-r--r--
```

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

* user
* group
* others

### 4. Real-world behavior

* who can read files
* who can edit configs
* who is blocked

---

# 🧠 MENTAL MODEL (VERY IMPORTANT)

Think:

```
File = locked box

Owner = keyholder
Group = shared key
Others = strangers
```

Permissions decide:

* can open box
* can change contents
* can execute (if script)

---

# ⚠️ IMPORTANT WARNING

Be careful with:

```bash
chmod 777
```

It means:

> everyone can do everything

That’s why admins avoid it.

---

# 🧠 ONE-LINE MEMORY

> Permissions = control who can read, write, or execute a file using owner, group, and others.

---

If you want next step, I can upgrade this lab into:

### 🔥 “real admin scenario”

* web server folder permissions (`/var/www`)
* nginx access issues
* fixing “403 forbidden” using chmod/chown

That’s where this becomes real production skill.
