# 13. Apply An AppArmor Profile

**Domain:** System Hardening

## Question

Load a local AppArmor profile named `deny-write` and run a pod that uses it.

## Answer

Create the profile on the target node:

```bash
sudo vi /etc/apparmor.d/deny-write
```

Example profile:

```text
#include <tunables/global>

profile deny-write flags=(attach_disconnected) {
  #include <abstractions/base>
  file,
  deny /** w,
}
```

Load it:

```bash
sudo apparmor_parser -q /etc/apparmor.d/deny-write
sudo aa-status | grep deny-write
```

Create a pod that uses the profile:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: apparmor-test
  namespace: default
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: deny-write
```

Apply:

```bash
kubectl apply -f apparmor-test.yaml
```

## Verify

```bash
kubectl wait --for=condition=Ready pod/apparmor-test --timeout=60s
kubectl exec apparmor-test -- touch /tmp/testfile
```

Expected: permission denied.

Check pod YAML:

```bash
kubectl get pod apparmor-test -o yaml | grep -A4 appArmorProfile
```

## Exam tips

- The profile must exist on the node where the pod runs.
- Use `nodeName` only if the task requires a specific node.
- Newer Kubernetes uses `securityContext.appArmorProfile`; older examples used annotations.




---
Yes — these three are related because they are all **container security**, but they operate at **different layers**.

The easiest way to remember them is:

> **PSS controls what kind of Pod you are allowed to create. AppArmor and seccomp control what the container is allowed to do at runtime.**

### 1. PSS — Pod Security Standards

PSS is the **highest-level policy**.

It answers:

> **"Is this Pod configuration acceptable from a security perspective?"**

For example, with a restrictive PSS policy, you might prohibit:

```text
privileged: true
hostNetwork: true
hostPID: true
hostPath volumes
running as root
```

Think of it as a **security gate before the Pod runs**:

```text
kubectl apply
     |
     ↓
PSS
     |
     +---- ❌ Pod violates security policy
     |
     +---- ✅ Pod allowed
              |
              ↓
           Container
```

PSS has levels such as:

```text
Privileged
Baseline
Restricted
```

---

# 2. AppArmor — "What files/capabilities can the process access?"

AppArmor is a **Linux security mechanism** that restricts what a process can access.

For example, your CKS question:

```text
deny-write
```

could say:

```text
Container process
      |
      +---- read /etc/...      ✅
      +---- execute binaries   ✅
      +---- write files        ❌
```

So even if your application tries:

```bash
echo "hello" > /tmp/test.txt
```

AppArmor can prevent it.

Think:

> **AppArmor controls access to files, capabilities, and other system resources based on a profile.**

It operates at the **Linux kernel security layer**.

---

# 3. Seccomp — "Which system calls can the process make?"

This one is different from AppArmor.

Linux applications communicate with the kernel through **system calls (syscalls)**.

For example:

```text
Application
    |
    | syscall
    ↓
Linux Kernel
```

There are many syscalls:

```text
open()
read()
write()
socket()
execve()
mount()
ptrace()
...
```

A seccomp profile can say:

```text
Allowed:
read      ✅
write     ✅
open      ✅
socket    ✅

Blocked:
mount     ❌
ptrace    ❌
```

So seccomp controls:

> **Which system calls the container's processes can make to the Linux kernel.**

---

# Put them together

Imagine your Jumia backend container.

```text
                    Jumia Backend Pod
                           |
              ┌────────────┴────────────┐
              |                         |
             PSS                    Runtime
              |                         |
       "Can this Pod               ┌────┴─────┐
        be created?"               |          |
              |                 AppArmor    Seccomp
              |                    |          |
              ↓                    ↓          ↓
        Security rules       File access   Syscalls
```

### Example

Your Pod might have:

```yaml
securityContext:
  seccompProfile:
    type: RuntimeDefault

  appArmorProfile:
    type: Localhost
    localhostProfile: deny-write
```

And your namespace might enforce:

```text
PSS = Restricted
```

Now you have **three layers**:

```text
PSS
 ↓
"Don't create dangerous Pods."

AppArmor
 ↓
"Don't access files/resources in ways this profile prohibits."

Seccomp
 ↓
"Don't make dangerous Linux system calls."
```

---

## A simple analogy

Imagine you're entering a secure building.

### PSS = Building security policy

> "Visitors aren't allowed to carry weapons or enter restricted areas."

It decides **whether you're allowed into the building/configuration is acceptable**.

### AppArmor = Room/access restrictions

> "You can enter this room, but you cannot open this cabinet."

It controls **what resources/files you can access**.

### Seccomp = Allowed actions

> "You can use the room, but you cannot use the power tools."

It controls **which kernel operations/syscalls you can perform**.

---

## CKS exam memory trick

Remember:

| Technology   | Main question                                     |
| ------------ | ------------------------------------------------- |
| **PSS**      | **Can this Pod be created?**                      |
| **AppArmor** | **What resources/files can this process access?** |
| **Seccomp**  | **What syscalls can this process make?**          |

And one more important distinction:

**PSS is a Kubernetes-level security standard/policy.**

**AppArmor and seccomp are Linux/kernel-level runtime security mechanisms.**

That's why in CKS you'll encounter them as separate questions even though they all contribute to **defense in depth**.


