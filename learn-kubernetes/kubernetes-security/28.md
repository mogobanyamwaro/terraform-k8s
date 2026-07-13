# 28. Block Latest Image Tags With Admission Policy

**Domain:** Supply Chain Security

## Question

Create a policy that denies pods using images with the `:latest` tag or no tag.

## Answer

Create a ValidatingAdmissionPolicy:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: deny-latest-tag
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["pods"]
  validations:
  - expression: "object.spec.containers.all(c, c.image.contains('@sha256:') || (c.image.contains(':') && !c.image.endsWith(':latest')))"
    message: "Images must use a non-latest tag or a digest"
```

Bind it:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: deny-latest-tag
spec:
  policyName: deny-latest-tag
  validationActions:
  - Deny
```

Apply:

```bash
kubectl apply -f deny-latest-tag-policy.yaml
kubectl apply -f deny-latest-tag-binding.yaml
```

Test bad pod:

```bash
kubectl run bad-latest --image=nginx:latest --restart=Never
```

Test good pod:

```bash
kubectl run good-tag --image=nginx:1.27 --restart=Never
```

## Verify

```bash
kubectl get validatingadmissionpolicy deny-latest-tag
kubectl get validatingadmissionpolicybinding deny-latest-tag
```

## Exam tips

- `latest` is mutable and weakens reproducibility.
- Digests are best when the task asks for immutable image references.
- Admission policies protect future objects, not objects already admitted.

