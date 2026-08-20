# 27. Use ImagePullSecrets For A Private Registry

**Domain:** Supply Chain Security

## Question

In namespace `cks-27`, configure Deployment `private-app` to pull from a private registry using Secret `regcred`.

## Answer

Create namespace:

```bash
kubectl create namespace cks-27
```

Create the registry Secret:

```bash
k create secret docker-registry regcred -n cks-27 \
--docker-server=https://index.docker.io/v1/ \
--docker-username=YOUR_DOCKER_USERNAME \
--docker-password=YOUR_DOCKER_PASS
```

Patch the Deployment:

```bash
kubectl patch deployment private-app -n cks-27 \
  -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}}}'
```

Or edit the manifest:

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
      - name: regcred
      containers:
      - name: private-app
        image: registry.example.com/team/private-app:1.0.0
```

Restart if needed:

```bash
kubectl rollout restart deployment/private-app -n cks-27
kubectl rollout status deployment/private-app -n cks-27
```

## Verify

```bash
kubectl get secret regcred -n cks-27
kubectl get deployment private-app -n cks-27 -o jsonpath='{.spec.template.spec.imagePullSecrets}'; echo
kubectl get pods -n cks-27
```

If pods fail:

```bash
kubectl describe pod <pod-name> -n cks-27
```

Look for `ImagePullBackOff`, `ErrImagePull`, or authentication errors.

## Exam tips

- `imagePullSecrets` belongs under `spec.template.spec` for controllers.
- The Secret must be in the same namespace as the pod.
- Avoid storing real registry credentials in Git.

  ---
  Yes — let's do a complete test using a **private Nginx image in your Docker Hub account**, then pull it into Kubernetes using `regcred`.

## 1. First, log in to Docker Hub

Run:

```bash
docker login
```

Enter your **Docker username** and password/access token when prompted. Docker credentials are then stored in your local Docker configuration. ([Kubernetes][1])

Check your Docker username:

```bash
docker info | grep Username
```

Suppose your username is:

```text
douglasnyamwaro
```

We'll use this image name:

```text
douglasnyamwaro/nginx-private:v1
```

> Replace `douglasnyamwaro` with your actual **Docker Hub username**. Your email is not necessarily your Docker Hub namespace.

---

## 2. Pull the Nginx image

```bash
docker pull nginx:1.28
```

Check it:

```bash
docker images | grep nginx
```

---

## 3. Tag it for your Docker Hub repository

```bash
docker tag nginx:1.28 YOUR_DOCKER_USERNAME/nginx-private:v1
```

For example:

```bash
docker tag nginx:1.28 douglasnyamwaro/nginx-private:v1
```

Docker Hub uses the `namespace/repository:tag` format when tagging and pushing images. ([Docker Documentation][2])

Verify:

```bash
docker images | grep nginx
```

You should see something like:

```text
nginx                          1.28
douglasnyamwaro/nginx-private  v1
```

---

## 4. Push the image

```bash
docker push YOUR_DOCKER_USERNAME/nginx-private:v1
```

Example:

```bash
docker push douglasnyamwaro/nginx-private:v1
```

If the repository does not already exist, Docker Hub can create it depending on your account/repository settings; alternatively, create the repository first in Docker Hub and set its visibility to **Private**. Private repositories are only accessible to authorized users. ([Docker Documentation][3])

You can then verify it in your Docker Hub repositories.

---

# 5. Make sure the repository is private

In Docker Hub:

1. Open your repository.
2. Go to **Settings**.
3. Set visibility to **Private**.

Docker documents that private repositories are not publicly searchable and require appropriate access permissions to pull. ([Docker Documentation][3])

---

# 6. Create the `regcred` secret

Since your test Pod is in the `test` namespace:

```bash
docker login
```

Then create the Kubernetes Secret from your Docker config:

```bash
k create secret generic regcred \
  -n test \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson
```

Verify:

```bash
k get secret regcred -n test
```

You should see:

```text
NAME      TYPE                             DATA
regcred   kubernetes.io/dockerconfigjson   1
```

Kubernetes recommends using a `kubernetes.io/dockerconfigjson` Secret for authenticating to private registries, and the Secret must exist in the same namespace as the Pod. ([Kubernetes][1])

---

# 7. Create a Pod that uses your private image

Create `private-nginx.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-nginx
  namespace: test
spec:
  imagePullSecrets:
    - name: regcred

  containers:
    - name: nginx
      image: YOUR_DOCKER_USERNAME/nginx-private:v1
```

Replace `YOUR_DOCKER_USERNAME`.

For example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-nginx
  namespace: test
spec:
  imagePullSecrets:
    - name: regcred

  containers:
    - name: nginx
      image: douglasnyamwaro/nginx-private:v1
```

Apply it:

```bash
k apply -f private-nginx.yaml
```

Then watch:

```bash
k get pods -n test -w
```

If `regcred` works correctly:

```text
NAME            READY   STATUS    RESTARTS
private-nginx   1/1     Running   0
```

---

## The full test flow

```text
nginx:1.28
    │
    │ docker tag
    ▼
YOUR_USERNAME/nginx-private:v1
    │
    │ docker push
    ▼
Docker Hub Private Repository 🔒
    │
    │ Kubernetes Pod starts
    ▼
imagePullSecrets
    │
    ▼
regcred
    │
    │ authenticates
    ▼
Docker Hub
    │
    ▼
Image pulled successfully
    │
    ▼
private-nginx Pod Running 🚀
```

This is a very good hands-on exercise because after it works, you can deliberately remove `imagePullSecrets` and see the Pod fail with `ImagePullBackOff`, then add `regcred` back and understand exactly what problem the Secret solves.




