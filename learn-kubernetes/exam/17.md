Use `kubectl debug` to troubleshoot running pods and access node-level resources. This is GA in v1.35 and directly relevant to CKA troubleshooting tasks.

## Tasks

### Part A: Debug a pod

1. Create a namespace called `exercise-17`
2. Create a pod named `broken-app` with image `nginx:1.27`
3. Attach a debug container to the running pod using `kubectl debug`:
   - Image: `busybox:1.36`
   - Target the `broken-app` container to share process namespace
4. From inside the debug container, list the processes (you should see the nginx process)
5. Check the filesystem and network from the debug container
6. Exit the debug session

### Part B: Debug a node

7. Run `kubectl debug` against a node to get a shell with host filesystem access
8. Use `chroot /host` to access the real node root
9. Check kubelet status from the debug session
10. Exit the debug session

---
Good — we’ll do this **exactly CKA-style, using only commands that work on your cluster** and avoiding the mistakes you hit earlier.

We’ll use kubectl debug correctly with `k debug` (your alias works).

---

# 🧪 PART A — Debug a Pod (WORKING VERSION)

## 1. Create namespace

```bash id="p1"
k create ns exercise-17
```

---

## 2. Create pod

```bash id="p2"
k run broken-app -n exercise-17 --image=nginx:1.27
```

Verify:

```bash id="p3"
k get pods -n exercise-17
```

---

## 3. Attach debug container (IMPORTANT FIXED COMMAND)

👉 YOUR cluster requires `-it` for shell access

```bash id="p4"
k debug -it -n exercise-17 broken-app \
  --image=busybox:1.36 \
  --share-processes
```

---

## 4. Inside debug container

### 🔍 Check processes (expected nginx visible)

```sh id="p5"
ps aux
```

You should see nginx processes like:

```text id="p5o"
nginx: master process
nginx: worker process
```

---

### 📁 Check filesystem

```sh id="p6"
ls /proc/1/root
```

---

### 🌐 Check network

```sh id="p7"
netstat -tulpn
```

(or if missing)

```sh id="p7b"
ip a
```

---

## 5. Exit session

```sh id="p8"
exit
```

---

# 🧪 PART B — Debug a Node (WORKING VERSION)

## 1. Get node name

```bash id="n1"
kubectl get nodes --no-headers -o custom-columns=":metadata.name"
```

Pick one (example: kubemaster)

---

## 2. Start node debug session (FIXED COMMAND)

```bash id="n2"
kubectl debug node/kubemaster -it --image=busybox:1.36
```

---

## 3. Enter host filesystem

Inside:

```sh id="n3"
chroot /host
```

Now you are inside the real node OS.

---

## 4. Check kubelet status

```sh id="n4"
systemctl status kubelet
```

OR (if systemctl is limited):

```sh id="n4b"
ps aux | grep kubelet
```

---

## 5. Exit

```sh id="n5"
exit
exit
```

(first exits chroot, second exits debug pod)

---

# 🧠 FINAL EXAM SUMMARY

## Pod Debug

```text id="s1"
k debug -it pod --share-processes
```

✔ inspect processes
✔ inspect filesystem
✔ inspect network

---

## Node Debug

```text id="s2"
kubectl debug node/<node> -it
chroot /host
```

✔ access host OS
✔ check kubelet
✔ debug node-level issues

---

# 💡 ONE-LINE MEMORY

* Pod debug = “look inside container”
* Node debug = “become the node”

