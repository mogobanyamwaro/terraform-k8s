# AWS DevOps certification guide

_Exported on 10/28/2026 at 13:07:17 GMT+3 from Cursor (3.12.17)_

---

**User**

be my teacher for aws devops Professional certification. where we will be learning bit by bit , especially where candidates fail the most

---

**Cursor**

I’ll set this up as a short, exam-focused course and start with the topics candidates miss most. First I’m checking the current DevOps Professional exam outline so the lessons match what AWS actually tests.

The live exam is still DOP-C02. I’m pulling the task statements for the heaviest domain so the first lesson matches what the questions actually ask.

I’ll teach this as a short course aimed at the AWS Certified DevOps Engineer – Professional exam, **DOP-C02**. Each turn is one bite: the rule candidates miss, why the wrong answers look right, then one scenario for you to solve. You answer with your reasoning. I mark it and we move on.

## How the exam is built

- **75 questions, 180 minutes.** 65 are scored. 10 are unscored and unmarked.
- **Pass mark is 750** on a 100–1,000 scale. You do not have to pass each domain. A weak domain can be carried by a strong one, but Domain 1 is large enough to sink the attempt on its own.
- **Two question types.** Multiple choice is one correct answer out of four. Multiple response is two or more correct answers out of five or more, and you must select every correct one.
- Blank answers score as wrong. There is no penalty for guessing.

| Domain                              | Weight | Where people lose points                 |
| ----------------------------------- | ------ | ---------------------------------------- |
| 1. SDLC Automation                  | 22%    | Deployment strategy, rollback, pipelines |
| 2. Configuration Management and IaC | 17%    | CloudFormation lifecycle, multi-account  |
| 6. Security and Compliance          | 17%    | IAM at scale, SCPs, encryption           |
| 3. Resilient Cloud Solutions        | 15%    | Matching design to RTO and RPO           |
| 4. Monitoring and Logging           | 15%    | Alarm vs dashboard vs trace              |
| 5. Incident and Event Response      | 14%    | Event-driven remediation                 |

The content failure cluster is **how a change is released and undone**: CodeDeploy and CodePipeline strategies, immutable artifacts, CloudFormation replacements, and cross-account promotion. The skill failure underneath all of that is reading the constraint and ignoring an answer that “works” but violates it.

## The decision rule

A Professional question is a constraint filter. A distractor is a real AWS design that fails one phrase in the stem.

Read the stem for these words before you look at the options:

- **Zero downtime, or rollback in minutes** means shift traffic back to something still running. Redeploying the previous build onto overwritten instances is too slow.
- **Least operational overhead, or keep the current tooling** means extend the service already named. Do not introduce Elastic Beanstalk, a new orchestrator, or a manual console step.
- **Most cost-effective, and a maintenance window is acceptable** means do not pay for a second fleet.
- **Same instances, local disk, or instance IDs must stay** means in-place. Blue/green replaces the instances.
- **Build once, promote to prod** means one artifact. Rebuilding per environment is the trap.
- **Immediately** means use what already exists. **Long term** means automate the source of truth.

## Lesson 1 — EC2 CodeDeploy: in-place vs blue/green

This is the single most failed comparison on the exam.

**In-place** updates the application on the instances you already have. Deployment configs are `AllAtOnce`, `HalfAtATime`, and `OneAtATime`. Rollback is a **new deployment** of the previous revision onto those same instances. Instances already updated stay on the bad version until that second deployment finishes. A CloudWatch alarm can stop or roll back the deployment, but it cannot instantly restore the old process, because the files on disk were replaced.

**Blue/green** keeps the original fleet (blue) and deploys the new revision to a replacement fleet (green). With an Application Load Balancer, production traffic moves from the original target group to the replacement target group. For an Auto Scaling group, CodeDeploy copies the group and launches the green instances. Rollback, while the blue instances still exist, is a **traffic shift back**. That takes minutes. Terminating blue too early destroys the fast rollback path. The termination wait has to cover your alarm window.

Use this filter:

| Stem says                                      | Choose                                                                                                                  |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| No downtime, and automatic rollback in minutes | Blue/green on the existing ALB, second target group, rollback on the 5xx alarm, terminate blue only after the bake time |
| Downtime is acceptable, and cost matters       | In-place, `OneAtATime` or `HalfAtATime`                                                                                 |
| Must preserve instance IDs or local state      | In-place                                                                                                                |
| Breaking database schema in the same change    | Neither strategy saves you. Both versions would hit one schema. The release needs an expand-then-contract migration.    |

Two traps sit inside otherwise correct designs. Stopping an in-place deployment is not a rollback. And “use Elastic Beanstalk instead” fails as soon as the stem says to keep CodeDeploy.

## Your turn

A retail company runs a Java application on an Auto Scaling group behind an Application Load Balancer. CodePipeline deploys with CodeDeploy **in-place, OneAtATime**. The last bad release drove up ALB 5xx responses. Rollback took 25 minutes because CodeDeploy had to reinstall the previous revision on every instance.

Leadership now requires:

- no downtime during deployment
- automatic rollback within a few minutes if the 5xx rate crosses a threshold
- the team must keep CodeDeploy and the existing load balancer

Which option meets every requirement, and why do the others fail?

**A.** Stay in-place with `OneAtATime`. Add a CloudWatch alarm that stops the deployment when 5xx responses rise.

**B.** Switch the deployment group to blue/green. Deploy to a replacement Auto Scaling group, shift traffic on the existing ALB after validation, roll back automatically on the 5xx alarm, and terminate the original instances only after that alarm window.

**C.** Replace CodeDeploy with Elastic Beanstalk immutable updates and swap the environment CNAME.

**D.** Launch a second Auto Scaling group by hand and edit the listener rule in the console when the new group looks healthy.

Reply with the letter and two or three sentences of reasoning. I’ll mark it, then we do the next bite: the same choice for **ECS and Lambda**, where canary and linear traffic shifting replace the EC2 configs and candidates mix the platforms up.

---

**User**

B. blue /green , will enable to devs to switch traffic automatically with alarms,

---

**Cursor**

**B is right.** The part to sharpen is who moves the traffic. CodeDeploy shifts the load balancer back to the original target group when the deployment’s CloudWatch alarm goes into alarm. Developers do not make that switch.

That is fast only while the original Auto Scaling group is still running. The termination wait has to be longer than the alarm window. Once those instances are gone, rollback becomes another full deployment, which is the 25-minute path you already have.

The other options miss a requirement:

- **A** stops the in-place deployment. Instances already updated keep the bad revision on disk until a second deployment reinstalls the old one.
- **C** abandons CodeDeploy and migrates the platform.
- **D** is a manual listener change, with no alarm-driven rollback.

## Lesson 2 — Same choice on ECS and Lambda

Candidates pass the EC2 question, then apply `OneAtATime` or “two Auto Scaling groups” to ECS and Lambda. The platforms do not share deployment configs.

**EC2 / on-premises only:** `AllAtOnce`, `HalfAtATime`, `OneAtATime`, and the CodeDeploy agent. In-place exists here.

**ECS has two mechanisms.** Pick from the wording in the stem.

| Stem asks for                                                                   | Mechanism                                                                                     |
| ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Replace tasks as they become healthy, roll back if new tasks fail health checks | ECS rolling update. `minimumHealthyPercent` and `maximumPercent`. Deployment circuit breaker. |
| 10% of production users for 5 minutes, then the rest                            | CodeDeploy blue/green with `CodeDeployDefault.ECSCanary10Percent5Minutes`                     |
| 10% more production traffic every minute                                        | CodeDeploy with `CodeDeployDefault.ECSLinear10PercentEvery1Minutes`                           |
| Run tests on a separate port before any production user is affected             | CodeDeploy, two target groups, a test listener, and the `AfterAllowTestTraffic` hook          |

A rolling update with `maximumPercent` 200 launches a full extra set of tasks and then drains the old ones. That is surge capacity on one target group. It does not put 10% of listener traffic on the new version for a bake window.

CodeDeploy for ECS is blue/green only. The service deployment controller is `CODE_DEPLOY`. You get a production listener, an optional test listener, and two target groups. Hooks run in this order: `BeforeInstall`, `AfterInstall`, `AfterAllowTestTraffic`, `BeforeAllowTraffic`, `AfterAllowTraffic`. A failing `AfterAllowTestTraffic` hook stops the deployment before the production shift. `AfterAllowTraffic` runs after 100% of production traffic has moved, so it is too late to gate the release. Rollback during the bake window points the production listener back at the original task set.

**Lambda uses an alias, not target groups.** Publish an immutable version, point an alias at it, and send callers to the alias. CodeDeploy shifts the alias weight:

- Canary: `CodeDeployDefault.LambdaCanary10Percent5Minutes` sends 10% for 5 minutes, then jumps to 100%.
- Linear: `CodeDeployDefault.LambdaLinear10PercentEvery1Minute` adds 10% each minute.
- All at once: the alias flips to the new version immediately, and an alarm can still flip it back.

Lambda hooks are only `BeforeAllowTraffic` and `AfterAllowTraffic`. Alarms watch the bake interval between them. There is no test listener and no CodeDeploy agent. Updating `$LATEST`, or pointing API Gateway at a version number, leaves the alias weights unused.

Platform check before you choose:

- Two target groups or a test listener means ECS.
- Alias weights mean Lambda.
- `OneAtATime` means EC2 or on-premises.

## Your turn

A service runs on Amazon ECS on Fargate behind an Application Load Balancer. Deployments are ECS rolling updates. The team wants all of the following:

- send the new version 10% of production traffic for 5 minutes
- if that version’s ALB 5xx rate crosses a threshold during those 5 minutes, return 100% of production traffic to the original version automatically
- run an integration suite against the new version on a separate listener port before any production traffic moves
- keep the workload on ECS

Which option meets every requirement, and which requirement do the others miss?

**A.** Set `minimumHealthyPercent` to 100 and `maximumPercent` to 200. Enable the ECS deployment circuit breaker.

**B.** Set the ECS deployment controller to CodeDeploy. Use two target groups, a production listener and a test listener, run the integration suite in `AfterAllowTestTraffic`, and deploy with `CodeDeployDefault.ECSCanary10Percent5Minutes` plus rollback on the 5xx alarm.

**C.** Use CodeDeploy with `CodeDeployDefault.ECSLinear10PercentEvery1Minutes`, and run the integration suite in `AfterAllowTraffic`.

**D.** Publish the new image through a Lambda alias with a 10% canary for 5 minutes.

Reply with the letter and a short reason for each option you reject.

---

**User**

correct answer is B
A- does not have rollback sulution, test listener,
C- it uses a different rollback approach other than the one Required on the service i.e allow traffic for 5 mins
D - dismissing the service requirement of using ecs instead it wants to use lambda

---

**Cursor**

**B is right.** The reason to tighten is option A. A rolling update with the deployment circuit breaker does roll back, but only when new tasks fail health checks. It never sends 10% of production traffic for 5 minutes, and it has no test listener.

**C** can also roll back on a CloudWatch alarm. It misses the shape of the release. `Linear10PercentEvery1Minutes` adds 10% every minute until it reaches 100%. It does not hold at 10% for 5 minutes and then shift the rest. `AfterAllowTraffic` runs after that full production shift, so the integration suite is no longer on a separate port before users are affected.

**D** leaves ECS, so the platform requirement is gone.

## Lesson 3 — The artifact you tested is the artifact you ship

Domain 1 questions often look like a pipeline design problem. The usual miss is promoting a different build to production, or an approval that does not actually block the deploy.

**Build once.** Source and build run in the pipeline account. CodeBuild produces one immutable artifact: a zip in S3, or an image digest in ECR. Staging and production both deploy that same output. Environment differences belong in Parameter Store, Secrets Manager, or deploy-time variables. A second CodeBuild that clones the repo inside the production account produces an untested artifact.

**An approval gates production only if it finishes first.** Actions in a stage with the same `runOrder` start together. Put the manual approval in an earlier stage, or give it a lower `runOrder` than the production deploy action. An approval sitting beside the deploy at `runOrder` 1 does not hold the deploy.

**Cross-account promotion needs three permissions.** The production action uses `RoleArn` to assume a role in the production account. That role’s trust policy allows the pipeline role. Then both of these must allow the production role:

- the artifact bucket policy, for `s3:GetObject`
- the key policy of the customer managed KMS key that encrypts the artifact, for `kms:Decrypt`

An IAM `kms:Decrypt` permission in the production account is not enough on its own. The key policy lives in the account that owns the key, and it has to name the production role.

There is a second KMS trap. The AWS managed key `aws/s3` has a key policy you cannot edit, and another account cannot decrypt objects encrypted with it. Cross-account artifacts use a customer managed key. Rebuilding in the production account is the distractor that avoids the key and breaks “build once.”

## Your turn

A pipeline in a tooling account builds once and stores the zip in S3, encrypted with the AWS managed key `aws/s3`. The production CloudFormation action assumes a role in another account. That role’s IAM policy allows `s3:GetObject` and `kms:Decrypt`. The deploy fails with `AccessDenied` on decrypt before any stack resources are created.

Which fix deploys the same tested artifact with encryption still on?

**A.** Attach `AdministratorAccess` to the production role.

**B.** Create a customer managed KMS key, encrypt the pipeline artifact store with it, allow the production deploy role in that key policy, and deploy the original build output.

**C.** Add a CodeBuild project in the production account that clones the repository and builds a new zip under a production key.

**D.** Add the production role to the key policy of `aws/s3`.

Reply with the letter and a short reason for each option you reject.

---

**User**

correct answer is B. the rest of the options does not include the usage of customer managed KMS key for Encryption and Decryption

---

**Cursor**

B is the right choice

. I’m checking one CloudFormation behavior before the next lesson so the rule matches what the exam expects.

**B is right.** The sharper rule is that `aws/s3` cannot grant decrypt to another account. A customer managed key can, and production must deploy the zip that already passed the pipeline.

The other options fail for different reasons:

- **A** adds broader IAM permissions in the production account. The key policy for `aws/s3` is not editable, so those permissions still cannot decrypt the artifact.
- **C** can use a customer managed key, and it is still the wrong fix. The production CodeBuild project compiles a new zip from source, so production ships a build the pipeline never tested.
- **D** tries to edit the `aws/s3` key policy. That policy cannot be changed.

## Lesson 4 — Replacement deletes the old resource

Domain 2 questions often hinge on one CloudFormation behavior. An update can modify a resource in place, or it can **replace** it. Replacement creates a new physical ID, moves dependents to that new resource, and then deletes the old one.

`DeletionPolicy: Retain` does not cover that delete. It applies when the stack is deleted, or when the resource is removed from the template. The RDS default of `Snapshot` also applies to those deletions, not to replacement.

`UpdateReplacePolicy` is the attribute that runs on replacement:

| Value      | What happens to the old resource                                                                            |
| ---------- | ----------------------------------------------------------------------------------------------------------- |
| `Delete`   | CloudFormation deletes it. This is the default when the attribute is absent.                                |
| `Retain`   | The old resource keeps running, leaves the stack, and still incurs cost. The stack tracks only the new one. |
| `Snapshot` | CloudFormation snapshots it, then deletes the original. Only for resource types that support snapshots.     |

A database that must survive **both** stack deletion and replacement needs both attributes:

```yaml
DeletionPolicy: Retain
UpdateReplacePolicy: Retain
```

A stack policy is a different control. It can deny `Update:Replace` on that database so the dangerous update never starts. It does not keep the old database after a replacement that you allowed.

## Your turn

A stack manages an RDS database. Two requirements:

- deleting the stack must leave that database running
- a property change that replaces the instance must also leave the original database running

The template has `DeletionPolicy: Retain` and no `UpdateReplacePolicy`. After a replacement update, the new database is in the stack and the original database is gone.

Which change meets both requirements?

**A.** Add `UpdateReplacePolicy: Retain` and keep `DeletionPolicy: Retain`.

**B.** Add a stack policy that allows every update. `DeletionPolicy: Retain` already covers replacement.

**C.** Remove `DeletionPolicy` and rely on the RDS default snapshot behavior for deletion and replacement.

**D.** Set `DeletionPolicy: Snapshot` only. The replacement default will retain the original instance.

Reply with the letter and a short reason for each option you reject.

---

**User**

correct answer is A
B- does not have updateReplacementPolicy when property change is added
D- requirements does not need snapshot it wants running Database
C- also this will make the original database gone

---

**Cursor**

A is right. I’ll confirm

one CloudFormation behavior before the next lesson, because change sets and drift are easy to mix up on this exam.

**A is right.** The reason to make precise is what each rejected option actually does.

**B** allows the update to proceed. A stack policy does not keep the old database. `DeletionPolicy: Retain` still applies only when the stack is deleted or the resource is removed from the template, so the replacement deletes the original instance.

**C** removes the protection you already have. On stack deletion, RDS then uses its default, which snapshots the database and deletes the instance. On replacement, the missing `UpdateReplacePolicy` still deletes the original instance.

**D** keeps a snapshot, then deletes the running instance. Replacement also deletes the original instance because `UpdateReplacePolicy` is still absent.

## Lesson 5 — Change sets and drift answer different questions

Candidates treat these as the same preview. They read different sources.

**Drift detection** compares the live resource with the template that CloudFormation last applied. It finds a console, CLI, or SDK change. It only reports. A drifted security group stays drifted until a later action reconciles it.

**A standard change set** compares a proposed template or parameters with the last deployed template. It shows what CloudFormation will add, modify, or replace, and nothing changes until you execute it. Submit the same template again and the change set is empty, including when someone opened port 22 in the console. The live resource is not an input.

**A drift-aware change set** is the newer third option. You create it with deployment mode `REVERT_DRIFT`. It shows a three-way difference: live state, last deployed template, and proposed template. Executing it writes the resources back to the template, including properties nobody changed in this deploy. Use it when the question says to preview or undo an out-of-band change during a deployment. Use plain drift detection when the question asks only for a report and says not to change anything yet.

| The stem asks for                                                                      | Use                                            |
| -------------------------------------------------------------------------------------- | ---------------------------------------------- |
| Which properties differ from the template right now?                                   | Drift detection                                |
| What will this new template change, before applying it?                                | Standard change set                            |
| Will this deploy overwrite a console fix, and then put resources back on the template? | Drift-aware change set, `REVERT_DRIFT`         |
| Make the console fix the new source of truth                                           | Put that value in the template, then reconcile |

One more distinction from Lesson 4: `UpdateReplacePolicy` decides whether a replaced resource is kept. It does not detect drift, and it does not preview a template.

## Your turn

A security group belongs to a CloudFormation stack. During an incident, an engineer added port 22 in the console. No new template is being proposed. The team wants a report of the properties that differ from the template, and they do not want the security group changed yet.

Which action meets that request?

**A.** Create a standard change set from the stack’s current template.

**B.** Run drift detection on the stack.

**C.** Create a drift-aware change set with deployment mode `REVERT_DRIFT` and execute it.

**D.** Add `UpdateReplacePolicy: Retain` to the security group.

Reply with the letter and a short reason for each option you reject.

---

**User**

C. is the correct one

---

**Cursor**

**B is the answer.** C is the action you take when you want the console change undone.

The stem has two constraints, and C breaks the second one:

- The team wants a **report** of properties that differ from the template.
- They do **not** want the security group changed yet.

Drift detection only reads the live security group and compares it with the template. Port 22 shows up as drift, and the rule stays in place.

Option C creates a drift-aware change set with `REVERT_DRIFT` and then **executes** it. Execution writes the security group back to the template, so the port 22 rule is removed. That is a change, not a report. Creating that change set and stopping before execution would have been a preview. The option includes execution, so it is out.

The other two options miss the report as well:

- **A** compares the current template with the last deployed template. Those match, so the change set is empty. It never reads the live port 22 rule.
- **D** decides what to keep if CloudFormation later replaces the resource. It does not inspect the security group.

The exam habit is to finish the stem before choosing a feature. Here the feature that reverts drift is real, and the words “report” and “not changed yet” remove it.

## Retry

The same security group still has the console rule for port 22. The team has finished the incident and now wants the group returned to the template. They want to see that overwrite before anything changes.

Which action meets that request?

**A.** Run drift detection and leave the result as the record of the difference.

**B.** Create a standard change set from the current template and execute it.

**C.** Create a drift-aware change set with deployment mode `REVERT_DRIFT`, review the three-way difference, and execute it only after that review.

**D.** Set `UpdateReplacePolicy: Retain` on the security group, then update the stack.

Reply with the letter and one sentence on why the option you reject that sounds closest still fails.

---

**User**

C

---

**Cursor**

**C is right.** Drift detection was the closest wrong choice: it records that port 22 differs from the template, and it leaves the rule in place. A standard change set of the unchanged template is empty, so executing it also leaves port 22 in place.

## Lesson 6 — CloudFormation waits only if something signals

A stack can reach `CREATE_COMPLETE` while `UserData` is still installing. CloudFormation marks an Auto Scaling group complete when the instances exist, unless the template makes a success signal part of creation.

That contract has three pieces:

- A `CreationPolicy` on the Auto Scaling group sets how many success signals are required and how long CloudFormation waits.
- The end of `UserData` runs `cfn-signal` with the stack name, the group’s logical ID, the region, and the install’s exit code: `-e $?`. An explicit `-e 0` reports success even when the install failed.
- An `UpdatePolicy` of `AutoScalingRollingUpdate` with `WaitOnResourceSignals: true` uses that same signal during a rolling update. `MinInstancesInService` and `MaxBatchSize` still control capacity. They do not check the application.

If the policy is present and no signal arrives, the stack sits in progress until the timeout, then rolls back. On a private subnet the usual cause is that the instance cannot reach the CloudFormation endpoint: no NAT gateway, and no CloudFormation interface endpoint. The second cause is a signal that names the wrong stack, logical ID, or Region.

`UpdateReplacePolicy`, a change set, and drift detection do not make creation wait for `UserData`.

## Your turn

CloudFormation creates an Auto Scaling group behind an Application Load Balancer. `UserData` installs the application and returns a non-zero exit code when the install fails. The stack reaches `CREATE_COMPLETE` while the install is still running, and the load balancer registers instances before the application is listening. Rolling updates do the same thing.

Which design makes creation and rolling updates wait for a successful install, and fail the resource when the install fails?

**A.** Add a `CreationPolicy` on the Auto Scaling group and an `UpdatePolicy` of `AutoScalingRollingUpdate` with `WaitOnResourceSignals: true`. At the end of `UserData`, run `cfn-signal -e $?` for that group’s logical ID.

**B.** Add `UpdateReplacePolicy: Retain` on the Auto Scaling group.

**C.** Create a standard change set from the current template and execute it before each update.

**D.** Run drift detection on a schedule.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct one

---

**Cursor**

**A is right.** The other three leave `UserData` outside the stack operation.

- **B** decides whether a replaced Auto Scaling group is kept. Creation still finishes when the instances exist.
- **C** previews the template you already have. That template does not tell CloudFormation to wait for the install.
- **D** reports live differences from the template. It does not change when the stack reaches `CREATE_COMPLETE`.

## Lesson 7 — An SCP sets a ceiling. It does not grant access

Multi-account questions on this exam are lost on one evaluation rule.

An **SCP** is attached to the organization root, an OU, or a member account. In a member account, the effective permission is the intersection of every SCP above that account and the identity’s own policies. An explicit `Deny` in any of those SCPs blocks the action, including for a role with `AdministratorAccess`.

An `Allow` in an SCP does not give anyone access. Some identity policy, or a resource policy, still has to grant the action. With no `Deny` and no identity `Allow`, the result is an implicit deny.

SCPs do not apply to the management account or to service-linked roles. They do apply to the root user of a member account. A guardrail such as “nobody in this OU can stop CloudTrail” belongs in an SCP. An IAM policy in each account loses to any administrator who can edit IAM.

A **permissions boundary** is the same kind of ceiling, attached to one user or role. It is how you let someone create roles while capping what those roles can do: the identity policy grants, and `iam:PermissionsBoundary` forces the boundary onto new roles. A boundary cannot override an SCP `Deny`, and a boundary `Allow` by itself grants nothing.

A **session policy**, passed to `AssumeRole`, can only narrow that session.

| The stem says                                                                           | Use                                               |
| --------------------------------------------------------------------------------------- | ------------------------------------------------- |
| No account in this OU may call this API, and account admins must not be able to lift it | SCP `Deny`                                        |
| This role may be assumed, but only up to a defined maximum                              | Permissions boundary                              |
| The SCP already allows the API, and the role still cannot call it                       | Add an identity `Allow`. The SCP is not the grant |
| The role has `AdministratorAccess` and the API still fails in a member account          | Look for an SCP `Deny`                            |

## Your turn

An SCP on a workloads OU allows `s3:*`. A role in a member account has no identity policy that allows S3. Nothing explicitly denies S3. The role cannot read objects in a bucket in the same account, and the bucket policy does not deny the role.

Which change grants the read?

**A.** No identity change. The SCP `Allow` already grants `s3:GetObject`.

**B.** Add an identity policy on the role that allows `s3:GetObject` on the bucket. Leave the SCP as it is.

**C.** Attach a permissions boundary that allows `s3:GetObject`.

**D.** Add an SCP `Deny` for `s3:GetObject` on the organization root, and an `Allow` for that action on the account.

Reply with the letter and a short reason for each option you reject.

---

**User**

B.
A- SCP dont greant permissions
C- Permission boundray dont grant permission
D- adding explicit deny on SCP ,it will trickle down hence wont allow the role

---

**Cursor**

**B is right.** An `Allow` lower in the tree cannot override that root `Deny`. The `Deny` applies to every member account under the root, so the role stays blocked even if an account SCP allows the action.

## Lesson 8 — Nested stacks stay in one place. StackSets fan out

After SCPs, the next miss is deploying a template to many accounts.

A **nested stack** is an `AWS::CloudFormation::Stack` resource inside a parent template. It breaks one deployment into reusable pieces in the **same account and Region** as the parent. Deleting the parent deletes the nested stacks. It does not target an OU, and it does not enroll accounts that appear later.

A **StackSet** creates a stack instance from one template in each chosen account and Region.

| Permission model | How it targets accounts                                                                       | New account in the OU                                      |
| ---------------- | --------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Service-managed  | An OU, through Organizations trusted access                                                   | Automatic deployment can create the stack instance for you |
| Self-managed     | Account IDs you list. You create the admin role and an execution role in every target account | You add the account and the roles yourself                 |

Service-managed StackSets are the low-overhead answer when the stem already has Organizations, the template must land on every account in an OU, and future accounts must be included. One failed account does not have to roll back the others: the operation’s failure tolerance sets how many account failures are acceptable before it stops.

Two tools that do not do this job:

- An **SCP** can stop an API. It cannot contain a template or create a Config recorder, an IAM role, or a log bucket.
- **Service Catalog** lets a user launch an approved product in an account. It is not how a central team pushes one baseline to an OU.

Use Control Tower when the stem asks for a landing zone, account vending, and ongoing guardrails. Use a StackSet when the stem asks to deploy a specific template to existing accounts.

## Your turn

A company already uses AWS Organizations. Every account in the Workloads OU, including accounts added to that OU later, must get the same CloudFormation template. The template creates an AWS Config recorder and a logging role. The team wants the smallest operational overhead.

Which design meets that?

**A.** A parent stack in the management account with a nested stack for each member account.

**B.** A service-managed StackSet that targets the Workloads OU, with automatic deployment enabled.

**C.** A self-managed StackSet. For each new account, create the execution role and add a stack instance by hand.

**D.** An SCP on the OU that contains the Config recorder and the logging role.

Reply with the letter and a short reason for each option you reject.

---

**User**

B. is correct

---

**Cursor**

**B is right.** The other three miss the OU requirement or the overhead requirement.

- **A** deploys nested stacks with the parent, in one account and Region. A nested stack does not target an OU, and a new account does not receive one automatically.
- **C** can deploy the template, but every new account needs an execution role and a stack instance created by hand.
- **D** can only allow or deny an API. An SCP cannot create a Config recorder or a logging role.

## Lesson 9 — Match the Region strategy to RPO, RTO, and what is already running

Domain 3 questions give you two numbers and a cost limit. **RPO** is how much data you can lose, measured as time. **RTO** is how long you can wait to be serving again.

A second Availability Zone is not a second Region. Multi-AZ covers loss of one zone. A stem that says the whole Region is unavailable needs a cross-Region design.

These four strategies are the ones the exam uses, from slowest and cheapest to fastest and most expensive:

| Strategy                 | During normal operation                                                         | Typical fit                                                                                       |
| ------------------------ | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Backup and restore       | Backups only. Infrastructure is created at failover                             | RPO and RTO of hours, lowest cost                                                                 |
| Pilot light              | Data is replicated. Application servers are off. AMIs and templates are ready   | RPO of seconds, RTO of tens of minutes to about an hour, lowest cost that still protects the data |
| Warm standby             | A smaller copy of the whole application is already running and can take traffic | RTO of minutes. You scale it up at failover                                                       |
| Multi-site active-active | Full capacity in two Regions, both serving                                      | RPO and RTO near zero                                                                             |

The trap is buying the next strategy up. Warm standby meets a one-hour RTO, and it leaves servers running that the stem said can stay off. Active-active also meets it, at the highest cost. Nightly snapshots miss an RPO of a few seconds because the last backup is hours old.

Asynchronous replication cannot promise an RPO of zero. Cross-Region RDS replicas, Aurora Global Database, and S3 Cross-Region Replication all have some lag. An RPO of zero inside one Region is a Multi-AZ synchronous database, and that still fails if the Region fails.

## Your turn

A stateful application runs in one Region. A Regional outage may lose no more than a few seconds of data. Service in a second Region may take up to one hour to return. The application servers do not need to run in the second Region during normal operation. Cost should be as low as those targets allow.

Which design meets the targets?

**A.** Nightly snapshots copied to the second Region, with infrastructure built during failover.

**B.** Pilot light: replicate the database continuously to the second Region, keep the AMIs and template ready, and launch the application servers only during failover.

**C.** Warm standby: run a smaller copy of the whole application in the second Region all the time, and scale it up during failover.

**D.** Multi-site active-active at full capacity in both Regions.

Reply with the letter and a short reason for each option you reject.

---

**User**

B. is the correct answer , C and D options needs Operational cost to run servers. option A will take more than 1 hour to recover

---

**Cursor**

B is the right choice.

I’m checking one monitoring behavior before the next lesson so the alarm path matches the current exam.

**B is right.** The correction is why A fails. A one-hour rebuild can still meet the RTO. Nightly snapshots miss the RPO: the last copy can be hours old, so a Regional outage can lose more than a few seconds of data.

**C** and **D** also meet the RPO and the one-hour RTO. They keep application servers running all the time, which is the cost the stem said to avoid.

## Lesson 10 — A log line does not page anyone until you turn it into a number

Domain 4 questions name a symptom in the logs and a reaction. The reaction decides the tool.

A **metric filter** reads each new log event and adds to a CloudWatch metric when the pattern matches. A metric alarm watches that number and can notify Amazon SNS, scale a group, or recover an instance. The metric is also what a dashboard graphs. Filters apply only to events that arrive after the filter exists, and only on Standard-class log groups.

A **subscription filter** ships the matching log events to Lambda, Kinesis Data Streams, Firehose, or OpenSearch. Use it when another service must process or store those events. It does not create an alarm or a dashboard count.

A **Logs Insights** query investigates logs you already have. Running it in the console does not watch the next hour. A log alarm can run a query on a schedule, but the usual exam path for “count these lines and graph the count” is still a metric filter plus a metric alarm.

Alarm on the user-facing symptom. For a web tier that is failing, that is the load balancer’s 5xx count or latency, or the error count extracted from the logs. CPU utilization is the scaling signal only when the stem says the instances are compute-bound.

| The stem asks for                                                                   | Use                                       |
| ----------------------------------------------------------------------------------- | ----------------------------------------- |
| Count matching log lines, graph them, and notify when the count crosses a threshold | Metric filter, then a metric alarm to SNS |
| Deliver the log events themselves to a search or analytics service                  | Subscription filter                       |
| Find the cause of an incident that already happened                                 | Logs Insights                             |
| Page only when two conditions are both true                                         | Composite alarm                           |

## Your turn

A web application writes JSON logs to a Standard-class CloudWatch log group. The team wants the number of events with `status = 500` on a dashboard, and an SNS notification when that count exceeds 10 in five minutes. No other service needs a copy of the log events.

Which design meets that?

**A.** Run a Logs Insights query in the console while investigating an incident.

**B.** Create a metric filter that counts `status = 500`, then create a metric alarm on that metric with an SNS action.

**C.** Create a subscription filter that sends the log group to OpenSearch.

**D.** Create a CloudWatch alarm on EC2 `CPUUtilization` with an SNS action.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is the correct answer

---

**Cursor**

**B is right.** The other three never produce that dashboard count and that notification.

- **A** searches logs you already have. It does not watch the next five minutes or publish to SNS.
- **C** copies the log events into OpenSearch. It does not create a CloudWatch metric or an alarm.
- **D** watches CPU. The application can return HTTP 500 while CPU stays low.

## Lesson 11 — Use the alarm action that already exists

Domain 5 questions start from an event you can already see. The miss is writing a new function when the alarm has a built-in action.

A CloudWatch alarm can notify SNS, run an Auto Scaling action, or act on EC2. Pick the EC2 action from the check that failed:

| Check                                        | What failed                                                   | Alarm action                                                                                                                             |
| -------------------------------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `StatusCheckFailed_System`                   | AWS hardware or the network path to the instance              | **Recover.** The instance moves to healthy hardware. Instance ID, private IP, and metadata stay the same. The volume must be EBS-backed. |
| `StatusCheckFailed_Instance`                 | The operating system                                          | **Reboot.** Recover does not repair an OS that is wedged.                                                                                |
| The instance should be replaced by the group | The application is unhealthy and a new instance is acceptable | Terminate, and let the Auto Scaling group launch a replacement. The instance ID changes.                                                 |

**EventBridge** is the router when no alarm action can do the work. A rule matches a pattern, such as a GuardDuty finding or a failed pipeline execution, and invokes Systems Manager Automation, Lambda, or Step Functions. Keep the pattern narrow. A rule that matches every EC2 event will remediate the wrong changes.

SNS delivers a message. It does not decide which events matter. SQS holds work for a consumer and can send failures to a dead-letter queue. Step Functions is for a remediation that has several steps, retries, and an approval. A single recover or reboot does not need any of those.

## Your turn

A CloudWatch alarm already watches `StatusCheckFailed_System` on an EBS-backed EC2 instance. When it fires, the instance must be moved to healthy hardware, the instance ID and private IP must stay the same, and the operations list must receive an email. Use the least custom code.

Which design meets that?

**A.** Add an EC2 recover action and an SNS action to the existing alarm.

**B.** Add an EC2 reboot action and an SNS action to the existing alarm.

**C.** Run an EventBridge schedule every minute that terminates the instance and lets an Auto Scaling group replace it.

**D.** Add a subscription filter on the application log group that invokes a Lambda function to call `RecoverInstances`.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**A is right.** The other three miss the hardware failure, the instance identity, or both.

- **B** reboots the operating system. A system status check means the AWS host or network path failed, so the reboot happens on the same failed hardware.
- **C** terminates the instance. The replacement has a new instance ID and a new private IP, and the schedule is not tied to the alarm.
- **D** reads application logs and adds a function. The alarm can call `RecoverInstances` directly.

## Lesson 12 — Scale on the metric the backlog actually moves

An Auto Scaling group changes capacity only to chase the metric you give it. CPU is the right signal when the work is compute-bound. It stays low while other work piles up.

Use **target tracking** when the stem says to hold a metric near a value. Use **step scaling** when a small breach and a large breach need different capacity jumps. Use **scheduled scaling** when the clock is the pattern. Predictive scaling adds capacity before a recurring spike, and it still needs a tracking policy for the unplanned load.

| The work                                         | The metric                                                                                                        |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| Web requests behind an Application Load Balancer | `ALBRequestCountPerTarget`. Total request count does not fall when you add instances, so the group keeps scaling. |
| CPU-bound processes                              | `CPUUtilization`                                                                                                  |
| Instances polling SQS                            | Visible messages divided by in-service instances. Target tracking holds that ratio.                               |
| A known busy hour                                | Scheduled scaling                                                                                                 |

The SQS expression is `ApproximateNumberOfMessagesVisible / GroupInServiceInstances`. Queue depth alone has no notion of “about 10 messages per worker.” CPU misses the queue because a worker can be blocked on the network while its CPU is idle.

Two related traps belong with this choice. An ELB health check replaces an instance whose application is failing. An EC2 health check leaves that instance in service as long as the host is up. A health-check grace period keeps the group from terminating an instance that has not finished booting.

## Your turn

An Auto Scaling group runs workers that poll one SQS queue. Each message takes several minutes and uses little CPU. During peaks the visible-message count grows, and the team wants about 10 visible messages per in-service instance.

Which policy meets that?

**A.** Target tracking on average `CPUUtilization` at 40 percent.

**B.** Target tracking on `ApproximateNumberOfMessagesVisible / GroupInServiceInstances`, with a target of 10.

**C.** Target tracking on `ALBRequestCountPerTarget`.

**D.** A scheduled action that sets the desired capacity to 2 every night.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct

---

**Cursor**

B is the right choice.

I’m confirming the current secrets-rotation behavior before the next lesson, because that distinction is a common exam trap.

**B is right.** The other policies chase a signal this workload does not produce.

- **A** watches CPU. These workers stay near idle while messages sit in the queue, so the group does not grow with the backlog.
- **C** watches requests per load-balancer target. This fleet has no load balancer.
- **D** sets a fixed size on a clock. It does not hold 10 visible messages per instance during a peak.

## Lesson 13 — Rotate the password the application fetches

A password in an AMI, in `UserData`, or in a template is a new deployment every time it changes. Instances that are already running keep the old value until you replace them.

**Parameter Store** holds configuration: AMI IDs, endpoints, feature values. A `SecureString` is encrypted with a KMS key. It does not rotate a database password or update the database to match. Use it when the stem wants inexpensive configuration, or a secret you will change yourself.

**Secrets Manager** holds credentials. KMS encryption is required. Automatic rotation updates the secret and the database. RDS, Aurora, DocumentDB, and Redshift can use managed rotation. Other secrets use a Lambda rotation function. The application must call `GetSecretValue` when it opens a connection. A value injected only at boot stays stale after the next rotation.

**AppConfig** rolls out application configuration with validation and alarm-based rollback. It is not a credential store.

| The stem says                                                   | Store it in                                                   |
| --------------------------------------------------------------- | ------------------------------------------------------------- |
| Configuration, AMI ID, or a secret you rotate manually          | Parameter Store. Use `SecureString` when it must be encrypted |
| Rotate this credential on a schedule, including in the database | Secrets Manager                                               |
| Running tasks must get the new password without a deploy        | The application calls Secrets Manager at connection time      |
| Roll out a feature flag and roll it back on an alarm            | AppConfig                                                     |

Reading a `SecureString` from `UserData` encrypts the password and still misses automatic rotation. Existing instances keep whatever they read at boot.

## Your turn

A database password is baked into an AMI in plaintext. The password must be encrypted with a KMS key and rotated automatically every 30 days. Processes that are already running must use the new password without an instance replacement or a new deployment.

Which design meets that?

**A.** Move the password to a Parameter Store `SecureString`. Read it from `UserData` when each instance boots.

**B.** Store the password in Secrets Manager with a KMS key, turn on a 30-day rotation, and change the application to call `GetSecretValue` when it connects.

**C.** Put the password in the CloudFormation template as an environment variable. Update the stack every 30 days.

**D.** Store the password in a private S3 object and bake that object’s URL into the AMI.

Reply with the letter and a short reason for each option you reject.

---

**User**

B. is correct

---

**Cursor**

**B is right.** The other three still leave a running process on the old password.

- **A** encrypts the value, and `UserData` reads it once at boot. Parameter Store does not rotate the database password. Instances that are already up keep the old value.
- **C** puts the password in the template. Updating the stack is a deployment, and it does not rotate the password inside the database.
- **D** bakes a fixed URL into the AMI. Replacing the object does not update running processes, and nothing rotates the database credential.

## Lesson 14 — Detect, repair, and prevent are three different services

Domain 6 questions describe one outcome. The usual miss is sending that outcome to the wrong service.

| The stem wants                                                          | The service                                                    |
| ----------------------------------------------------------------------- | -------------------------------------------------------------- |
| A record of which principal called which API                            | CloudTrail. An organization trail covers every member account. |
| A resource is noncompliant, and it should be changed back               | AWS Config rule, with a remediation action                     |
| Nobody can make the resource noncompliant in the first place            | A preventive control: S3 Block Public Access, or an SCP `Deny` |
| Threats such as compromised credentials or cryptomining                 | GuardDuty                                                      |
| Software vulnerabilities on EC2, Lambda, or container images            | Inspector                                                      |
| Sensitive data stored in S3                                             | Macie                                                          |
| A resource policy that grants access to a principal outside the account | IAM Access Analyzer                                            |
| One place to read findings from those detectors                         | Security Hub                                                   |

CloudTrail and Config do not stop the API call. They see it after it happens. An SCP or a service-level block stops it. GuardDuty does not replace a Config rule: a public bucket is a configuration violation, not a threat finding. Inspector does not read bucket policies. Macie does not remove a public ACL. Security Hub collects findings. It is not the detector you enable instead of Config or GuardDuty.

A notification is a second step. A Config compliance change, or a CloudTrail event, goes through EventBridge to SNS. The remediation is the Systems Manager Automation action on the Config rule, not the email.

## Your turn

In every account, a bucket that becomes publicly readable must be reported, and the public access must be removed automatically. Making buckets public should remain possible for a break-glass exception, so a blanket prevention control is not acceptable.

Which design meets that?

**A.** A CloudTrail metric filter on `PutBucketAcl`, with an alarm that emails SNS. No further action.

**B.** An AWS Config rule that flags publicly readable buckets, a remediation action that removes the public access, and an EventBridge rule that emails SNS when the resource is noncompliant.

**C.** An Amazon Inspector assessment of each bucket.

**D.** A Macie classification job over the objects in each bucket.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**B is the answer.** A only sends the email. The stem also says the public access has to be removed automatically, and a metric filter does not change the bucket.

CloudTrail records the API call. A filter on `PutBucketAcl` misses a bucket that became public through a bucket policy. Config evaluates the result: the bucket is publicly readable, whichever API caused it. The remediation action then removes that access. The EventBridge rule sends the email when the resource is noncompliant.

That remediation is corrective, not preventive. The API still succeeds, so a break-glass change is possible. Config puts the bucket back afterward. An SCP or S3 Block Public Access would have made the change impossible, and the stem ruled that out.

**C** looks for software vulnerabilities. **D** looks for sensitive data inside objects. Neither one reads the bucket’s public access or removes it.

The constraint to underline is “removed automatically.” A notification that leaves the bucket public fails it.

## Retry

The same accounts now need a different outcome. The security team wants an email when a principal calls `PutBucketAcl`. They do not want the ACL changed back.

Which design meets that?

**A.** A CloudTrail metric filter on `PutBucketAcl`, and an alarm that publishes to SNS.

**B.** An AWS Config rule for publicly readable buckets, with automatic remediation that removes the public access.

**C.** An SCP that denies `s3:PutBucketAcl` in every account.

**D.** A Macie job that classifies objects and publishes findings to SNS.

Reply with the letter and one sentence on why the option that changes the bucket fails this stem.

---

**User**

A is correct answer

---

**Cursor**

**A is right.** The option that changes the bucket is **B**. Its remediation removes the public access, and this stem says not to change the ACL back. **C** blocks the API, so the call the team wants to hear about never succeeds. **D** classifies objects. It does not watch `PutBucketAcl`.

## Lesson 15 — A shell, a one-time command, and a desired state are different tools

Systems Manager questions fail when every operational task becomes “open port 22” or “start a session.”

An instance is a managed node only when three things are true. The SSM agent is running. An instance profile allows Systems Manager. The instance can reach the service: a public subnet, a NAT gateway, or interface endpoints for `ssm`, `ssmmessages`, and `ec2messages`. A private subnet with none of those never appears in the console. Opening port 22 does not fix that.

| The stem asks for                                         | Use                                                        |
| --------------------------------------------------------- | ---------------------------------------------------------- |
| A shell, with no inbound SSH, and a record of the session | Session Manager. Log the session to CloudWatch Logs or S3. |
| This script, once, on the instances with this tag         | Run Command                                                |
| This configuration must keep being true                   | State Manager association                                  |
| OS patches in a defined window, and a compliance report   | Patch Manager, attached to a maintenance window            |

Session Manager uses the agent’s outbound connection. The security group needs no inbound rule. A bastion with port 22 open from an office is the design the stem is walking away from when it says least network exposure and an audit trail.

State Manager does not replace a shell, and a one-time Run Command does not keep a setting true next week. Patch Manager is the patch baseline and the compliance view. It is not how an operator logs in.

## Your turn

Application instances run in a private subnet. There is no bastion. Security groups allow no inbound SSH. Operators need a shell on those instances, and every session must be recorded in CloudWatch Logs. Use the smallest inbound exposure.

Which design meets that?

**A.** Session Manager. Attach an instance profile that allows Systems Manager, create interface endpoints for `ssm`, `ssmmessages`, and `ec2messages`, and enable session logging to CloudWatch Logs.

**B.** A bastion in a public subnet, port 22 open from the office, and the SSH private key stored in Secrets Manager.

**C.** A Run Command document that starts `sshd` and adds an inbound rule for port 22.

**D.** A State Manager association that copies an SSH private key onto each instance every 30 minutes.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct answer

---

**Cursor**

**A is right.** The other three open SSH or distribute a key.

- **B** puts a bastion on the internet and allows inbound port 22. Storing the key in Secrets Manager does not record the session.
- **C** is a one-time command that opens port 22. That is the inbound exposure the stem removes.
- **D** copies a long-lived key onto the instance on a schedule. Operators still need SSH, and State Manager does not record the shell session.

## Lesson 16 — A slow request needs a trace, not another counter

You already split logs from metrics. The third signal is the one those questions usually lack.

A **metric** says the checkout call is slow: the load balancer’s latency is high. A **log** can contain the exception text from one service. Neither one shows how that one user request spent its time across API Gateway, Lambda, and the ECS service.

**X-Ray** does. Each hop adds a segment. The service map shows where the time went. API Gateway and Lambda need tracing enabled. The downstream ECS service has to continue the same trace, or the map stops at Lambda. The header that ties the hops together is `X-Amzn-Trace-Id`. A service that does not forward it becomes a gap.

| The question is                           | Use                      |
| ----------------------------------------- | ------------------------ |
| How many requests failed in five minutes? | A metric, and an alarm   |
| What did this error say?                  | Logs, then Logs Insights |
| Which hop made this request slow?         | X-Ray                    |
| Which principal called an API?            | CloudTrail               |
| Was the packet allowed?                   | VPC Flow Logs            |

Flow logs and CloudTrail do not time application hops. A metric filter on the word “slow” only counts lines that happen to contain that word. It does not build the path.

## Your turn

Checkout requests are slow. Application Load Balancer latency is high. The path is API Gateway, then Lambda, then an ECS service. The team needs to see which hop consumes the time.

Which design answers that?

**A.** A metric filter that counts the word “slow” in the load balancer access logs.

**B.** Turn on X-Ray for API Gateway and Lambda, instrument the ECS service so it continues the trace, and read the service map.

**C.** VPC Flow Logs on every interface, with an alarm on bytes transferred.

**D.** A CloudTrail trail with data events for every checkout request.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct

---

**Cursor**

**B is right.** The other three record a different event.

- **A** counts a word in one log. It does not time API Gateway, Lambda, and ECS as parts of the same request.
- **C** shows whether packets flowed. It does not show which application hop used the time.
- **D** records AWS API calls. A checkout’s time inside Lambda and ECS is not a CloudTrail event.

## Lesson 17 — Failover DNS has to see a health signal it can reach

Route 53 chooses the record. It does not watch your application unless you attach a health check.

| The stem says                                                            | Routing                                                                |
| ------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| Everyone uses the primary Region until it is unhealthy, then the standby | **Failover.** One primary, one secondary, health check on the primary. |
| Users go to the Region with the lowest latency, and both Regions serve   | **Latency**, with health checks so a failed Region is removed          |
| Send 10 percent of DNS answers to the new version                        | **Weighted**                                                           |
| Users in a country must stay in that country’s Region                    | **Geolocation**                                                        |

Latency routing is the trap after a warm-standby design. It sends West Coast users to the standby while the primary is healthy. Weighted routing keeps splitting traffic during the outage. Neither one is “primary unless unhealthy.”

The health check has to reach the signal. Route 53’s checkers run on the public internet. They can probe a public ALB. They cannot open a connection to a private IP. For an instance or endpoint in a private subnet, the health check monitors a **CloudWatch alarm**. The alarm goes into alarm, the primary record is marked unhealthy, and failover answers with the secondary. Lower the TTL if new answers need to spread quickly. Resolvers can still cache the old answer until the previous TTL expires.

## Your turn

A primary application and its warm standby have no public endpoints. The instances are in private subnets. Route 53 must answer with the primary record until a CloudWatch alarm says the primary is unhealthy, and then answer with the secondary. The change must be automatic.

Which design meets that?

**A.** An HTTP health check aimed at the instances’ private IP addresses, on a failover record.

**B.** A failover record whose health check monitors the CloudWatch alarm. The primary is the active record, and the standby is the secondary.

**C.** Latency routing across the two private records, with no health check.

**D.** A VPC Flow Logs subscription that invokes Lambda to rewrite the record when bytes drop.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct answer

---

**Cursor**

**B is right.** The other three never mark that private primary unhealthy.

- **A** sends the public Route 53 checkers at a private IP. Those checkers cannot open that connection, so the primary never fails over.
- **C** sends each user to the closer Region while the primary is healthy. With no health check, the alarm cannot move the answer to the standby.
- **D** records network bytes. Flow logs do not change a Route 53 record, and the Lambda rewrite is a second system you do not need.

## Lesson 18 — A failed Lambda event has a path that depends on how it was invoked

The retry you configure for an asynchronous function does nothing for a queue poller. Match the failure path to the source.

**Synchronous** calls, such as API Gateway and an Application Load Balancer, return the error to the caller. Lambda does not retry them, and it does not write them to a destination.

**Asynchronous** calls, such as S3 events, SNS, and EventBridge, are retried twice. After that, the event is discarded unless the function has an **on-failure destination** or an asynchronous dead-letter queue. A destination to SQS, SNS, Lambda, or EventBridge includes the original event and the error. A dead-letter queue keeps the failed event. The destination is the fuller record. Neither one runs while the function is succeeding, unless you also set an on-success destination.

**An SQS event source mapping** is a poller, not an asynchronous invocation. A failed message returns to the queue when the visibility timeout expires. The queue’s redrive policy sends it to a dead-letter queue after `maxReceiveCount`. Set the visibility timeout longer than the function timeout, or the message becomes visible again while the function is still running. Report failed batch-item identifiers when one bad message should not be retried with the rest of the batch.

**Kinesis and DynamoDB streams** keep the record on the shard. Use a maximum retry count, bisect the batch on error, and set the mapping’s on-failure destination. The function’s asynchronous dead-letter queue is not on this path.

Reserved concurrency of **0** stops every invocation. It does not save the event that just failed. Use it to halt a runaway function, then fix the code.

## Your turn

An S3 bucket invokes a Lambda function asynchronously. After the retries, a failed invocation must be kept with the original event and the error details. Successful invocations do not need to be stored. The S3 notification has to stay as it is.

Which design meets that?

**A.** Set an SQS queue as the function’s on-failure destination.

**B.** Add an SQS event source mapping and a redrive policy, and remove the S3 notification.

**C.** Set the function’s reserved concurrency to 0.

**D.** Create a CloudWatch alarm on `Errors` and publish it to SNS. Leave the failed event with no destination.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is the correct answer

---

**Cursor**

**A is right.** The other three miss the failed event, change the source, or stop the function.

- **B** removes the S3 notification and turns the function into a queue poller. The stem keeps the S3 notification as it is.
- **C** throttles every invocation. It does not store the event that already failed.
- **D** sends an email after the metric moves. With no destination, Lambda discards the event once the retries end.

## Lesson 19 — The container and the agent do not share a role

On Amazon ECS, two roles appear in the same task definition. Candidates grant the API call on the wrong one.

The **execution role** is used by the ECS agent before your process is serving. It pulls the image from Amazon ECR, creates the CloudWatch log stream, and injects values from the task definition’s `secrets` field. `AmazonECSTaskExecutionRolePolicy` covers that startup work. It does not become the credentials inside the application.

The **task role** is what the AWS SDK inside the container uses. A call to `s3:GetObject`, `dynamodb:PutItem`, or `sqs:ReceiveMessage` from application code is authorized by this role. If the application itself calls `GetSecretValue`, that permission belongs here too. A secret injected through the `secrets` field is fetched by the execution role instead.

Fargate has no instance. An EC2 container-instance profile only lets the host agent join the cluster. Application permissions on that profile would be shared by every task on the host, so they stay on the task role.

| The failure                                                           | Add the permission to   |
| --------------------------------------------------------------------- | ----------------------- |
| Cannot pull the image, write logs, or inject a task-definition secret | Execution role          |
| Application code receives `AccessDenied` from an AWS API              | Task role               |
| EC2 host never registers with the cluster                             | Container-instance role |

Static access keys in the image fail both rotation and least privilege. The task role is already the temporary credential.

## Your turn

A Fargate task pulls its image and writes logs. The application then receives `AccessDenied` on `s3:GetObject`. The execution role already has `AmazonECSTaskExecutionRolePolicy`. The image contains no access keys.

Which change grants the read?

**A.** Allow `s3:GetObject` on the task role that the task definition uses.

**B.** Allow `s3:GetObject` on the execution role only.

**C.** Allow `s3:GetObject` on an EC2 instance profile in the cluster.

**D.** Bake an access key with `s3:GetObject` into the image and read it from an environment variable.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**A is right.** The application calls S3 with the task role, and the other three change a different credential.

- **B** lets the agent pull the image and write logs. The SDK inside the container does not use that role, so the application still receives `AccessDenied`.
- **C** looks for an EC2 instance profile. This is Fargate, so there is no host profile to change.
- **D** puts a long-lived key in the image. The task role is already the temporary credential for this call.

## Lesson 20 — A public certificate stays with the service that can use it

Public certificates from AWS Certificate Manager renew automatically while DNS validation remains in place and the certificate is attached to a supported service. The private key cannot be exported. An ALB, an API Gateway edge or regional endpoint, and CloudFront can use it. Nginx on an EC2 instance cannot.

The certificate’s Region has to match the service:

| Service                                            | Where the certificate must exist         |
| -------------------------------------------------- | ---------------------------------------- |
| Application Load Balancer or Network Load Balancer | The same Region as the load balancer     |
| Regional API Gateway                               | The same Region as the API               |
| CloudFront                                         | **us-east-1**, wherever the origin lives |

Attaching a `us-east-1` certificate to an ALB in `eu-west-1` fails. So does exporting a public certificate onto an instance. If the stem requires a private key on a host, or mutual TLS inside the VPC, that is AWS Private CA or an imported certificate. Private CA is the high-cost path. Do not choose it when an ALB can terminate TLS.

Redirect HTTP to HTTPS on the load balancer listener. Opening port 443 on every instance, and leaving the load balancer on HTTP, misses the managed renewal the stem is asking for.

## Your turn

A web application sits behind an Application Load Balancer in `eu-west-1`. The company wants HTTPS, automatic renewal, and no certificate installed on the EC2 instances. Use the smallest operational overhead.

Which design meets that?

**A.** Request a public certificate in `eu-west-1`, attach it to the load balancer’s HTTPS listener, and redirect HTTP to HTTPS.

**B.** Request a public certificate in `us-east-1` and install its exported private key on each instance.

**C.** Issue a certificate from AWS Private CA, export it, and terminate TLS on each instance.

**D.** Request a public certificate in `us-east-1` and attach it to the load balancer in `eu-west-1`.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct answer

---

**Cursor**

**A is right.** The other three put the certificate where this load balancer cannot use it.

- **B** depends on exporting a public certificate. ACM does not provide that private key, and `us-east-1` is the CloudFront requirement.
- **C** installs a Private CA certificate on every instance. That is the cost and the placement the stem removes.
- **D** leaves the certificate in `us-east-1`. An Application Load Balancer can attach a certificate only from its own Region.

## Lesson 21 — Blue/green does not protect a breaking schema change

During a blue/green bake, both application versions are running and they share one database. The old version keeps handling traffic until you terminate it. Any schema change in that same deployment has to work for both versions.

A renamed or dropped column fails that test. The new code expects the new name. The old code is still querying the old name, so its requests fail while it is supposed to be the rollback path. Shifting traffic all at once does not fix the old tasks that are still in the bake. A second database restored from a snapshot is not a fix either: writes to the primary during the bake never reach it.

Use an expand-and-contract release.

1. **Expand.** Add the new column or table. Leave the old one. Backfill. The current application keeps working.
2. **Deploy code that understands both shapes.** Shift traffic and bake.
3. **Contract.** After the old version is gone and nothing reads the old column, drop it in a later release.

The destructive migration is its own deployment. It is never in the same change as the first version that requires the new shape.

| Situation                                                      | Result                                |
| -------------------------------------------------------------- | ------------------------------------- |
| Add a nullable column, then deploy code that uses it           | Both versions can run                 |
| Rename or drop a column while the old version is still serving | The old version fails during the bake |
| Green uses a snapshot, with no replication from blue           | Writes during the bake are lost       |

## Your turn

CodeDeploy blue/green shifts traffic on an Application Load Balancer. Both versions use one RDS database. The new version needs a renamed column, and the old version must keep serving correctly during the bake. The rename is currently in the same deployment as the new application version.

Which sequence meets that?

**A.** Rename the column in that deployment, then shift all traffic at once.

**B.** Add the new column and backfill it while the old column remains. Deploy code that can use both. Shift and bake. Drop the old column only after the old version is terminated.

**C.** Restore a second database from a snapshot for the new version, rename the column there, and do not replicate writes from the original database.

**D.** Stop the old Auto Scaling group, rename the column, then start the new version.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct

---

**Cursor**

**B is right.** The other three lose either the old version or the writes that happen during the bake.

- **A** renames the column while the old version is still serving. That version queries the old name, so it fails during the bake.
- **C** gives the new version a snapshot that stops at restore time. Writes to the original database during the bake never arrive.
- **D** stops the old group before the new version is in service. That is downtime, and the stem says the old version keeps serving.

## Lesson 22 — One organization trail, in an account the members do not control

A trail inside each member account fails this exam in two ways. Someone has to create it again for every new account, and an administrator in that account can stop it or delete its bucket.

An **organization trail** is created in the management account, or by a delegated administrator. It records management events for every account and Region, and a new account is included without another trail. Member administrators can see it. They cannot turn it off or delete it.

Put the log bucket and its KMS key in a **log-archive account**. Encrypt with a customer managed key. The bucket policy allows only the CloudTrail service to write, restricted with `aws:SourceArn` and the organization ID. Auditors read from the log-archive account. Workload administrators have no identity there, so a policy in their own account cannot delete the objects.

An SCP is the wrong tool for this delivery path. An SCP in a workload account does not protect a bucket that lives in another account. Use a bucket policy there. Add S3 Object Lock when the stem says that even an administrator of the log-archive account must not delete the objects during the retention period.

GuardDuty, Config, and metric filters do not replace the trail. They consume events or configuration. They are not the immutable record of every API call.

## Your turn

Every account in an organization, including accounts created next month, must record management events in one bucket. Administrators of the workload accounts must not be able to stop that logging or delete those objects. Use the smallest operational overhead.

Which design meets that?

**A.** Create a trail in each workload account that writes to a bucket in that same account.

**B.** Create an organization trail that delivers every account’s management events to a bucket and a customer managed key in a log-archive account. Do not grant workload administrators access to that account.

**C.** Add an SCP that denies `cloudtrail:DeleteTrail` in the workload accounts, and keep each account’s bucket local.

**D.** Enable GuardDuty in the management account and store its findings in the management account.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct

---

**Cursor**

**B is right.** The other three leave logging under the control of each workload account, or they do not record the API calls.

- **A** needs a new trail for every future account, and that account’s administrator can stop the trail or delete the bucket.
- **C** can block `DeleteTrail` and still leaves the objects in the workload account. A new account does not get a trail until someone creates one.
- **D** stores threat findings from one account. It is not a management-event trail for the organization.

## Lesson 23 — A test that needs a running application cannot run in the build

Domain 1 pipelines fail when the test is placed where its dependency does not exist yet.

**Unit tests and dependency or image scans** run in the build, before an image is published. They need source code, not a load balancer. A non-zero exit fails the build, so a bad image never gets a tag.

**Integration and acceptance tests** run after the deploy to staging, against that staging URL. They prove the running application. Putting them in the build stage fails them for the wrong reason: the staging endpoint is not there yet.

**Load tests** also run against staging. Running them against production makes the release itself the incident.

The **manual approval** comes after the staging tests pass and before the production deploy. An approval that shares a stage and a `runOrder` with the production action starts at the same time as that deploy, so it does not gate it. Production deploys the same image digest that staging tested. It does not build again.

| Check                                         | Where it goes                                   |
| --------------------------------------------- | ----------------------------------------------- |
| Unit tests, lint, dependency scan, image scan | Build, before publish                           |
| Integration suite against the staging URL     | After the staging deploy                        |
| A person allows production                    | After those tests, before the production action |
| Production artifact                           | The digest that passed staging                  |

## Your turn

A pipeline must run unit tests and a dependency scan before any image is published. It must then deploy that image to staging, run an integration suite against the staging URL, and wait for a person to approve it. Production must deploy that same image.

Which sequence meets that?

**A.** Source, then a build that runs the unit tests and the scan and publishes one image. Deploy that image to staging, run the integration suite against staging, require approval, then deploy the same image to production.

**B.** Source, then a build that runs both the unit tests and the integration suite before any deploy. Deploy to production, and approve after that deploy.

**C.** Source, build, and approval. Deploy to production, then run the integration suite against the production URL.

**D.** Source and build in the tooling account. After approval, build a new image in the production account and deploy that image.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**A is right.** The other three run a test before its target exists, or they ship a different image.

- **B** runs the integration suite in the build, before staging exists, and the approval comes after production is already deployed.
- **C** deploys to production before anyone approves it. The suite then runs against production.
- **D** builds a second image in the production account. Production no longer runs the image that passed the staging tests.

## Lesson 24 — Let in-flight work finish before the instance disappears

Scale-in and rolling replacements cause 500s when the load balancer or the group kills a connection that is still being served.

The target group’s **deregistration delay** is connection draining. The load balancer stops sending new requests to the instance and keeps existing requests open until they finish, or until the delay expires. Set the delay above the application’s longest request. A delay of 0 cuts those requests off immediately. An Auto Scaling group that is attached to the target group waits for this draining before it terminates the instance.

A **terminating lifecycle hook** is for work the load balancer cannot see: flushing a queue, closing a file, or running a shutdown script. The instance stays in `Terminating:Wait` until something calls `CompleteLifecycleAction`, or until the heartbeat timeout. A hook that never completes leaves the instance stuck and the group short of capacity.

| The failure                                                           | The control                                           |
| --------------------------------------------------------------------- | ----------------------------------------------------- |
| Users with a request already in progress get an error during scale-in | Raise the deregistration delay above the request time |
| The instance must run its own shutdown script                         | Terminating lifecycle hook, then complete the action  |
| New instances are killed before they are ready                        | Health check grace period, not the draining delay     |

A Lambda function that sleeps for 60 seconds is extra code for a behavior the target group already has. An SCP that denies `TerminateInstances` stops scale-in entirely.

## Your turn

During scale-in, requests that are already in progress fail. New requests are going to the remaining instances. The longest request takes 60 seconds. The team wants the built-in load balancer behavior, with no extra function.

Which change meets that?

**A.** Set the target group’s deregistration delay to at least 60 seconds.

**B.** Set the deregistration delay to 0 so the instance leaves the load balancer immediately.

**C.** Add a terminating lifecycle hook that invokes a Lambda function to wait 60 seconds, and leave the delay at 0.

**D.** Add an SCP that denies `ec2:TerminateInstances`.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is the correct answer

---

**Cursor**

**A is right.** The other three cut the request off, wait too late, or block scale-in.

- **B** removes the instance from the load balancer immediately, so an in-flight request is dropped.
- **C** waits in a Lambda function after deregistration. With the delay at 0, the load balancer has already closed those requests before the hook runs.
- **D** stops the group from terminating instances. Capacity cannot fall, and the in-flight requests are still not given a drain window.

## Lesson 25 — Reserved concurrency limits a function. Provisioned concurrency warms it

Cold starts show up as `Init Duration` in the Lambda report. The first request after idle time pays that cost. Later requests on a warm environment do not.

**Provisioned concurrency** keeps a chosen number of environments initialized for a published version or an alias. It does not attach to `$LATEST`. Callers must use that alias, or the warm environments stay unused. You pay for those environments while they are idle. Traffic above that number still scales on demand and can cold-start.

**Reserved concurrency** is a ceiling. It also reserves that many units from the account pool so other functions cannot take them. It does not initialize environments. Set it when one function must not consume the account’s concurrency. Set it to **0** to stop the function. A reserved value of 1, with no provisioned concurrency, still cold-starts, and every additional request is throttled.

API Gateway closes an integration at 29 seconds. Raising the Lambda timeout above that does not save a caller who already received a timeout, and it does not remove the initialization time.

On runtimes that support **SnapStart**, a snapshot can cut initialization cost without a standing pool of warm environments. When the stem says to keep environments initialized and the cost is acceptable, provisioned concurrency on the alias is the direct answer.

| The symptom                                                                            | The setting                                                              |
| -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `Init Duration` on the first request after idle, and warm capacity is worth paying for | Provisioned concurrency on the alias                                     |
| This function must not take the account’s whole pool                                   | Reserved concurrency, greater than 0                                     |
| Stop every invocation now                                                              | Reserved concurrency of 0                                                |
| The client is API Gateway and the limit is 29 seconds                                  | Fix the function. A 15-minute Lambda timeout does not extend the gateway |

## Your turn

An API Gateway API invokes a Lambda alias. After idle periods, the first requests time out and the logs show `Init Duration`. Later requests are fast. The team will pay to keep environments initialized. The function must still be able to run.

Which change meets that?

**A.** Configure provisioned concurrency on the alias that API Gateway invokes.

**B.** Set reserved concurrency to 0.

**C.** Set reserved concurrency to 1 and leave provisioned concurrency unset.

**D.** Raise the Lambda timeout to 15 minutes and leave both concurrency settings unset.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is the correct answer

---

**Cursor**

**A is right.** The other three leave the cold start in place or stop the function.

- **B** sets reserved concurrency to 0. Every invocation is throttled, so the function cannot run.
- **C** caps the function at one execution and does not initialize an environment. The first request still pays `Init Duration`, and a second concurrent request is throttled.
- **D** lets the function run longer. API Gateway has already closed the call at 29 seconds, and the initialization time is still there.

## Lesson 26 — Block a request pattern at the layer that can see it

A security group is an allow list on an elastic network interface. It has no deny rule, and it does not read an HTTP body. You cannot write a security group that says “allow everyone except this IP” or “drop SQL injection.” A network ACL can deny an IP or a port at the subnet, and it is stateless. It still cannot see a query string or a JSON body.

**AWS WAF** sits on an Application Load Balancer, CloudFront, or API Gateway. A web ACL can use a managed SQL-injection rule, a block list of IPs, a geographic match, or a **rate-based rule** that blocks one address after too many requests in five minutes. Legitimate traffic that does not match continues. The instances stay unchanged.

**Shield Standard** is already on for the edge services and covers common network floods. **Shield Advanced** is the paid addition for a large volumetric attack, cost protection, and the response team. It does not inspect SQL. A flood that is big enough to saturate the load balancer is a Shield and edge-network problem. A crafted HTTP request is a WAF problem.

| The stem says                                      | Use                                                                     |
| -------------------------------------------------- | ----------------------------------------------------------------------- |
| Drop this SQL, XSS, or header pattern              | WAF managed rule on the load balancer or CloudFront                     |
| One IP is sending too many HTTP requests           | WAF rate-based rule                                                     |
| Deny one IP at the subnet, with no HTTP inspection | Network ACL                                                             |
| Allow this port from these addresses               | Security group                                                          |
| Absorb a large L3 or L4 flood                      | Shield Advanced, usually with CloudFront or Global Accelerator in front |

## Your turn

An Application Load Balancer receives HTTP requests that contain SQL injection. One source address also sends thousands of requests per minute. Those requests must be blocked before they reach the instances. Legitimate traffic must continue. Do not change the instances.

Which design meets that?

**A.** Add a security group deny for that source address and a deny for the SQL pattern.

**B.** Attach a WAF web ACL to the load balancer, with a managed SQL-injection rule and a rate-based rule.

**C.** Enable Shield Advanced and add no application rules.

**D.** Add a network ACL that denies all inbound traffic on ports 80 and 443.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is the correct answer
A- security group dont have explict deny
C- shield Advanced protect against DDos attacks
D- Network does not support the rate limiting

---

**Cursor**

**B is right.** Two of the rejection reasons need one more fact.

**A** is right about the missing deny. A security group also cannot read an HTTP body, so it cannot match a SQL pattern even if a deny rule existed.

**C** is right. Shield Advanced absorbs a network flood. It does not apply the SQL rule or the per-address request limit.

**D** is only partly about rate limiting. That network ACL denies every connection on ports 80 and 443, so legitimate users are blocked too. It also cannot see the SQL string inside the request.

## Lesson 27 — A fixed threshold pages on a healthy pattern

A static CloudWatch threshold fits a limit that is the same at every hour: a dead-letter queue above zero, a disk above 80 percent, or more than ten 5xx responses. It does not fit a metric that is high every afternoon and low every night.

The failure looks like this. CPU at 60 percent is normal at 2 p.m., so an alarm at 60 percent pages on healthy traffic. The same alarm stays silent at 3 a.m. when 40 percent is twice the normal night load. Raising the threshold to 90 percent removes the afternoon page and also removes the chance of catching the night incident.

An **anomaly detection** alarm builds a band from the metric’s own history and pages when a point falls outside the band for that time of day. Use it when the stem describes a repeating cycle and “abnormal for this hour.” Do not use it for a condition that should always page, such as any message in a dead-letter queue. A band can treat a small non-zero value as normal.

Two other controls are not a time-of-day model. **Datapoints to alarm**, M out of N periods, ignores a single spike. A **composite alarm** pages only when a rule of other alarm states is true, such as high 5xx count and high latency together. It combines states. It does not learn the daily shape of a metric.

| The stem says                                                                | Use                   |
| ---------------------------------------------------------------------------- | --------------------- |
| This number is unacceptable at any hour                                      | Static threshold      |
| This metric has a healthy daily cycle, and the exception is being outside it | Anomaly detection     |
| Ignore a one-period blip                                                     | M out of N datapoints |
| Page only when two conditions are both true                                  | Composite alarm       |

## Your turn

CPU on a web tier follows a daily cycle. An alarm at 60 percent pages every healthy afternoon. Last month, CPU of 40 percent at 3 a.m. was a real incident and the alarm stayed green. The team wants a notification when CPU is outside the normal range for that time of day.

Which design meets that?

**A.** An anomaly detection alarm on `CPUUtilization`.

**B.** Raise the static threshold to 90 percent.

**C.** A composite alarm that is in alarm whenever CPU is above 60 percent during the workday.

**D.** Delete the alarm and review a dashboard each afternoon.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is the correct answer

---

**Cursor**

**A is right.** The other three keep a fixed rule, or they stop notifying.

- **B** stays silent at 3 a.m., when 40 percent was the incident. It also has no model of the daily cycle.
- **C** pages on the healthy afternoon, because that CPU is above 60 percent. It does not notice an abnormal night value that stays under 60 percent.
- **D** is a manual review the next afternoon. Nothing notifies the team when the point falls outside the night’s normal band.

## Lesson 28 — The standby you fail over to is not the replica you query

RDS questions fail when one feature is asked to do both jobs.

**Multi-AZ** keeps a synchronous standby in another Availability Zone in the same Region. If the writer or its zone fails, RDS fails over automatically and the endpoint stays the same. The RPO for that zone failure is effectively zero. The classic standby does not accept connections, so it cannot take reporting traffic. Multi-AZ does not survive the loss of the whole Region.

A **read replica** is asynchronous. It has its own endpoint, and you can send `SELECT` traffic there. Lag can be seconds, which is acceptable when the stem says reports can be slightly stale. It can live in another Region. It does not fail over by itself. You promote it, and promotion makes it a new writer. While it is still a replica, the primary remains the writer.

Use both when the stem asks for both outcomes. Multi-AZ protects the writer. The replica serves the reports.

Aurora is the exception to “the standby cannot be queried.” Aurora replicas share the cluster storage, can serve reads, and can be the failover target. Do not add a MySQL-style unread standby to an Aurora cluster to satisfy a read-scaling question.

| The stem says                                                      | Use                                                                        |
| ------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| Automatic failover if one AZ is lost, same endpoint, RPO near zero | Multi-AZ                                                                   |
| Move reports off the writer, a few seconds of lag is fine          | Read replica                                                               |
| Both of those, in one Region                                       | Multi-AZ and a read replica                                                |
| The whole Region can be lost, and the database should fail over    | Cross-Region replica, or Aurora Global Database. Multi-AZ does not do this |

## Your turn

An RDS MySQL writer in one Availability Zone is slowed by nightly reports. The reports can be a few seconds stale. The primary must remain the only writer. If that Availability Zone fails, failover must be automatic and the application endpoint must not change. Everything stays in one Region.

Which design meets that?

**A.** Enable Multi-AZ. Create a read replica in the same Region and point the reports at the replica.

**B.** Enable Multi-AZ and point the reports at the standby.

**C.** Create a cross-Region read replica and change the application’s DNS to that replica for every report run.

**D.** Keep a single Availability Zone and move the reports onto a larger instance class with the transactions.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is the correct one

---

**Cursor**

**A is right.** The other three miss the reader, the Region limit, or the failover.

- **B** points the reports at the Multi-AZ standby. That standby does not accept connections.
- **C** leaves the Region and changes DNS for each report run. The reports only need a replica endpoint, and the writer’s endpoint is supposed to stay put.
- **D** keeps a single Availability Zone. A larger instance does not fail over, and the reports still run on the writer.

## Lesson 29 — DNS failover waits for caches. Anycast does not

Route 53 failover changes the answer a resolver receives. Each client and resolver can keep the old answer until its TTL expires. A 60-second TTL does not help a device that caches DNS for hours. Route 53 also does not give the application a pair of IP addresses that stay the same for years.

**Global Accelerator** gives you two static anycast addresses. Devices and firewall allow lists use those addresses. Traffic enters the AWS network at the nearest edge, and Accelerator forwards it to a healthy regional endpoint: an ALB, a Network Load Balancer, or an Elastic IP. If the primary endpoint fails its health check, new traffic moves to the other Region in seconds. The addresses on the devices do not change.

CloudFront is the wrong stand-in. It caches HTTP at the edge. It is not how you publish stable IP addresses for clients that are not fetching cacheable web content. A function that rewrites DNS on every device is the operational cost the stem is trying to remove.

| The stem says                                                              | Use                                                        |
| -------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Fail over by DNS, and clients honor a low TTL                              | Route 53 failover                                          |
| Users should reach the closest healthy Region by latency                   | Route 53 latency routing, with health checks               |
| Fixed IP addresses, or clients ignore TTL, and failover must be in seconds | Global Accelerator in front of the regional load balancers |
| Cache static and dynamic HTTP close to users                               | CloudFront                                                 |

## Your turn

A multi-Region application exposes an Application Load Balancer in each Region. IoT devices cache DNS for hours, and they can store only IP addresses that rarely change. If the primary load balancer fails, new connections must move to the other Region within seconds. Do not reconfigure the devices for each failover.

Which design meets that?

**A.** Route 53 failover, with a TTL of 60 seconds.

**B.** Global Accelerator, with both load balancers as endpoints and the two static anycast addresses configured on the devices.

**C.** CloudFront in front of both load balancers, with the cache TTL set to 24 hours.

**D.** A Lambda function that updates the DNS resolver on every device once a minute.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is the correct answer. how many lessons do we have,

---

**Cursor**

**B is right.** There are **29 lessons** so far. Two of them, drift and Config, each had a retry after a missed constraint. Those retries are not extra lessons.

The other three designs miss the devices’ behavior.

- **A** depends on a 60-second DNS TTL. The devices cache DNS for hours, so they keep the old address.
- **C** caches HTTP for 24 hours. It does not give the devices two stable addresses or move new connections in seconds.
- **D** reconfigures every device. That is the operational work the requirement removes.

| Lessons | What they locked                                                                              |
| ------- | --------------------------------------------------------------------------------------------- |
| 1–3     | EC2 blue/green, ECS and Lambda traffic shifting, one artifact across accounts                 |
| 4–6     | `DeletionPolicy` versus `UpdateReplacePolicy`, drift versus change sets, `cfn-signal`         |
| 7–8     | SCPs do not grant, StackSets versus nested stacks                                             |
| 9       | Pilot light versus the more expensive Region strategies                                       |
| 10–12   | Metric filters, recover versus reboot, SQS backlog per instance                               |
| 13–16   | Secrets Manager, Config versus CloudTrail, Session Manager, X-Ray                             |
| 17–18   | Private Route 53 health checks, Lambda on-failure destinations                                |
| 19–21   | ECS task role, ACM Region, expand-and-contract schema changes                                 |
| 22–25   | Organization trail, where a pipeline test runs, deregistration delay, provisioned concurrency |
| 26–29   | WAF, anomaly detection, Multi-AZ plus a read replica, Global Accelerator                      |

Lesson 30 is next, on CloudFormation stack policies: how they differ from `DeletionPolicy` when an update must not replace the database. Say when to start.

---

**User**

in total how many lessons do you have for me

---

**Cursor**

**45 lessons in total.** You have finished **29**. **16** are left, and then this course stops.

The remaining lessons are the high-failure gaps that do not yet have their own bite:

1. Stack policies and termination protection
2. Permissions boundaries when someone else creates roles
3. Cross-account role trust and the confused deputy
4. Centralizing application logs across accounts
5. Delegated admins for GuardDuty, Security Hub, and Config
6. Immutable image tags and scan-on-push
7. CodeBuild in a private subnet
8. Synthetic canaries as a pipeline gate
9. Step Functions for a multi-step response
10. AppConfig rollouts that roll back on an alarm
11. S3 replication and a replication-time limit
12. AWS Backup and a vault lock
13. Elastic Disaster Recovery beside the four Region strategies
14. Aurora Global Database and DynamoDB global tables
15. Composite alarms and error-rate math
16. Service Catalog, Control Tower, and StackSets

Lesson 30 is the stack policy. Say when to start.

---

**User**

okay lets continue

---

**Cursor**

Lesson 30 is the stack policy. It is the control that stops an update from replacing one resource, and it is easy to confuse with the two controls you already learned.

A stack policy applies only while CloudFormation is updating the stack. As soon as you attach one, every resource is protected until a statement allows the update. A useful policy allows updates broadly, then denies the dangerous actions on the database:

- `Update:Replace` blocks a change that would create a new database and delete the old one.
- `Update:Delete` blocks removing that database from the template during an update.
- `Update:Modify` can stay allowed, so a normal parameter change still goes through.

The Auto Scaling group is covered by the broad allow, so application updates continue.

**Termination protection** stops `DeleteStack`. It does not stop an update, and it does not stop a replacement. Someone who turns the protection off can delete the stack on the next call.

**`DeletionPolicy: Retain`** decides what remains after a delete that CloudFormation is allowed to run. The stack is deleted and the database keeps running, outside the stack. For an RDS instance, leaving this unset means the default is **Snapshot**: the instance is removed after a snapshot is taken. Retain is what “the database is still running” requires. It does not block the update that replaces it.

| Requirement                                                | Control                                                                      |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------- |
| This update must not replace or remove the database        | Stack policy denying `Update:Replace` and `Update:Delete` on that logical ID |
| A mistaken `DeleteStack` must fail                         | Termination protection                                                       |
| If the stack is deleted anyway, the database keeps running | `DeletionPolicy: Retain`                                                     |
| If a replacement does happen, keep the old database too    | `UpdateReplacePolicy: Retain`                                                |

A console edit still bypasses all four. The stack policy is not an IAM deny. Drift detection is how you find that edit afterward.

## Your turn

A stack contains an RDS database and an Auto Scaling group. Normal updates must still change the Auto Scaling group. A stack update must not replace the database. A mistaken stack deletion must fail. If someone turns that deletion guard off and deletes the stack anyway, the database instance must keep running.

Which set meets all four requirements?

**A.** A stack policy that allows updates to the other resources and denies `Update:Replace` and `Update:Delete` on the database, termination protection enabled, and `DeletionPolicy: Retain` on the database.

**B.** `DeletionPolicy: Retain` on the database only.

**C.** Termination protection only.

**D.** `UpdateReplacePolicy: Retain` on the database only.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**A is right.** The other three each cover only one of the four requirements.

- **B** keeps the database running if CloudFormation is allowed to delete it. An update can still replace the database, and `DeleteStack` still succeeds.
- **C** makes a mistaken `DeleteStack` fail. An update can still replace the database. After someone turns the protection off, the RDS default is a snapshot, so the running instance does not remain.
- **D** keeps the old database only if a replacement is already underway. The update is still allowed to replace it, and stack deletion is still allowed.

## Lesson 31 — A boundary caps a role. It does not give the role access

A permissions boundary is a managed policy attached to one user or role. The role can do only what **both** its identity policy and its boundary allow. An allow in the boundary alone grants nothing. An explicit deny in either policy wins. A boundary cannot override an SCP deny.

The exam case is delegation. Developers need to create application roles without being able to create an administrator. You do four things:

- Write the ceiling as its own policy, such as `DevBoundary`.
- Allow `iam:CreateRole` and `iam:AttachRolePolicy` only when the condition `iam:PermissionsBoundary` equals that policy’s ARN. A role created without the boundary is the escalation path.
- Deny `iam:DeleteRolePermissionsBoundary` and `iam:PutRolePermissionsBoundary`, so the ceiling cannot be removed after creation.
- Deny changes to the boundary policy itself, including `iam:CreatePolicyVersion`. A developer who can edit the ceiling can raise it.

The application role still needs an identity policy for the actions it should actually perform. The boundary only limits them. `iam:PassRole` has to be limited to roles that carry this boundary, or the developer can pass a different, more powerful role to Lambda or EC2.

An SCP is the wrong size. It caps every principal in the account or OU, including workloads that need more. A session policy narrows one `AssumeRole` call. The role created during that session keeps whatever policies it was given.

| The stem says                                               | Use                                                |
| ----------------------------------------------------------- | -------------------------------------------------- |
| Cap every account in this OU                                | SCP                                                |
| Let this team create roles, but no role can exceed this set | Permissions boundary, required by an IAM condition |
| Narrow the credentials I am about to assume                 | Session policy                                     |
| Grant the application its real access                       | Identity policy on the role, inside the boundary   |

## Your turn

Developers must create IAM roles for their applications and attach those roles’ identity policies. No role they create may be able to do more than the actions in a policy named `DevBoundary`. Other accounts and other teams must not be limited. The ceiling must still be there after the role is created.

Which design meets that?

**A.** Attach an SCP that allows only the `DevBoundary` actions to the workload account.

**B.** Allow `iam:CreateRole` and `iam:AttachRolePolicy` only when `iam:PermissionsBoundary` equals the ARN of `DevBoundary`. Deny removal of that boundary and deny edits to the boundary policy.

**C.** Grant the developers `AdministratorAccess` and instruct them to attach a restrictive identity policy to each new role.

**D.** Add a session policy to the developers’ `AssumeRole` call that lists the `DevBoundary` actions.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is the correct answer

---

**Cursor**

**B is right.** The other three never put a ceiling on the new role.

- **A** limits every principal in the workload account. Other teams lose actions they still need, and an SCP allow does not grant the application its access.
- **C** lets a developer attach `AdministratorAccess` to the role. An instruction is not a limit.
- **D** narrows one `AssumeRole` session. The role created in that session has no boundary, and the restriction ends when the session ends.

## Lesson 32 — The other account must be named, and a third party must present an external ID

Assuming a role across accounts needs both sides. The caller’s identity policy allows `sts:AssumeRole` on the role ARN. The role’s trust policy allows that caller. Either side alone returns `AccessDenied`.

Name the specific role in the other account when you can. Trusting `arn:aws:iam::111122223333:root` lets every principal in that account who is allowed to assume roles become this one.

A vendor that uses one AWS account for many customers adds the **confused deputy**. Another customer can ask the vendor’s service to assume your role and read your metrics. The vendor is the deputy, and it was talked into using its legitimate access on the wrong customer.

The production account enforces the fix in the trust policy. Trust the vendor’s role, and require `sts:ExternalId` to equal a value that only you and the vendor know. The vendor sends that value in `AssumeRole`. A different customer does not know it, so the vendor’s call fails the condition. The external ID belongs in the trust policy. An identity policy in the vendor account is not something you control.

Use a different condition when the caller is an AWS service. A replication role, a CloudFormation service role, or a Config remediation role should require `aws:SourceArn` and `aws:SourceAccount`. An external ID is the third-party control, not the service control.

| The caller                                | The trust policy                                                    |
| ----------------------------------------- | ------------------------------------------------------------------- |
| One known role in another account         | That role’s ARN                                                     |
| A vendor account shared by many customers | That vendor role, plus `sts:ExternalId`                             |
| An AWS service                            | The service principal, plus `aws:SourceArn` and `aws:SourceAccount` |

## Your turn

A monitoring vendor uses one AWS account to serve many customers. The vendor must assume a role in this company’s production account and read CloudWatch metrics. A different customer of the vendor must not be able to make the vendor use this role. This company must enforce that restriction. The vendor’s identity policy will also allow the assume call.

Which design meets that?

**A.** Trust `arn:aws:iam::VENDOR_ACCOUNT:root` and attach `AdministratorAccess` to the production role.

**B.** Trust the vendor’s role ARN and require `sts:ExternalId` to equal a value known only to this company and the vendor.

**C.** Attach an SCP in the vendor account that denies `sts:AssumeRole` for other customers.

**D.** Create an IAM user in the production account and send its access keys to the vendor.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct answer

---

**Cursor**

**B is right.** The other three leave the vendor’s access too broad, or they put the control where this company cannot enforce it.

- **A** trusts every principal in the vendor account. `AdministratorAccess` is more than metric read access, and nothing stops another customer from pointing the vendor at this role.
- **C** tries to attach an SCP in the vendor’s organization. This company cannot do that, and an SCP there would not add the condition on this role’s trust policy.
- **D** sends long-lived keys. Anyone who sees the message can use them, and there is no external ID check.

## Lesson 33 — Application logs are not the organization trail

Lesson 22 collected API calls. An application’s stdout never appears in that trail. CloudTrail data events are still API calls. GuardDuty findings are still findings.

Two different stems use two different designs.

**Someone must query the logs in a central CloudWatch console.** Use CloudWatch observability access manager. The monitoring account has a sink. Each source account links to it. The logs stay in the source account, and the central account can query them. This does not produce an S3 archive.

**Every current and future log group must be stored in an S3 bucket in the log-archive account.** Use an **account-level subscription filter** in each workload account. One account policy covers the log groups that already exist and the ones created next month. The filter targets a CloudWatch Logs destination in the log-archive account. That destination writes through Firehose to the archive bucket. A filter on a single log group misses the next service.

The destination policy has to allow the workload accounts to create the subscription. The bucket and its key stay in the log-archive account, so a workload administrator cannot delete the archive. Subscriptions are regional: a workload that runs in two Regions needs a destination in each.

| The stem says                                                                   | Send it with                                                             |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| API calls from every account                                                    | Organization trail                                                       |
| Query application logs, metrics, and traces in one CloudWatch console           | Observability access manager                                             |
| Keep a copy of every application log in central S3, including future log groups | Account-level subscription filter to Firehose in the log-archive account |
| Threat detection                                                                | GuardDuty                                                                |

## Your turn

Applications in many workload accounts write to CloudWatch Logs. Every current and future log group must be copied to an S3 bucket in a log-archive account for retention and Athena. Workload administrators must not be able to delete that archive. Use the smallest ongoing operational effort. The records must be the application log lines.

Which design meets that?

**A.** An organization trail that delivers management events to the log-archive bucket.

**B.** A subscription filter on today’s production log group, writing to a bucket in that same workload account.

**C.** An account-level subscription filter in each workload account, aimed at a Logs destination and Firehose in the log-archive account, with the archive bucket in that account.

**D.** GuardDuty delegated administration, with findings stored in the log-archive account.

Reply with the letter and a short reason for each option you reject.

---

**User**

C is correct

---

**Cursor**

**C is right.** The other three collect a different record, or they leave the archive where a workload administrator can delete it.

- **A** stores API calls. Application log lines are not management events.
- **B** subscribes one log group and writes to a bucket in that workload account. The next log group is missed, and that account’s administrator can delete the objects.
- **D** stores threat findings. It does not copy the application logs.

## Lesson 34 — Turn the security services on once, from the security account

A detector that runs only in the management account does not see the workload accounts. The management account is also the wrong place to operate those tools. Register a **security account** as the delegated administrator, and let new accounts inherit the setup.

**GuardDuty** is the threat detector. From the delegated administrator, auto-enable it for every account and Region, including accounts created later. Findings arrive in the security account. An SCP can stop a member from disabling it, but the SCP does not enable the detector or collect the findings.

**Security Hub** is the aggregation view. The same security account is its delegated administrator. It pulls findings from GuardDuty, Inspector, Macie, and Config into one place and scores them against a standard. It does not replace GuardDuty. Turn on cross-Region finding aggregation so operators look at one home Region.

**Config** answers a different question: is this resource compliant. An organization aggregator in the security account shows rules and inventory from every account. The aggregator does not record anything by itself. Each account and Region still needs a configuration recorder. A StackSet or an organization conformance pack deploys those recorders. The aggregator only reads them.

| The stem says                                                               | Enable                                                                       |
| --------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Suspicious API use, compromised credentials, cryptomining, in every account | GuardDuty delegated admin, auto-enable                                       |
| One queue of findings and a standards score                                 | Security Hub delegated admin, with those detectors already on                |
| Which resources violate a configuration rule                                | Config recorders everywhere, organization aggregator in the security account |
| Stop an API in every account                                                | SCP                                                                          |

## Your turn

A company uses AWS Organizations. Operators must work only in a security account, not in the management account. Every current and future member account, in every Region, must have threat detection. Those findings, and the compliance findings, must be visible from the security account. Config recorders are already running in every account and Region.

Which design meets that?

**A.** Enable GuardDuty and Security Hub only in the management account.

**B.** Make the security account the delegated administrator for GuardDuty and Security Hub. Auto-enable GuardDuty for the organization. Aggregate Security Hub findings there. Add an organization Config aggregator in that account.

**C.** Add an organization Config aggregator only. Treat noncompliant rules as the threat detection.

**D.** Attach an SCP that denies `guardduty:CreateDetector`, and enable no central detector.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct

---

**Cursor**

**B is right.** The other three leave the member accounts without a detector, or they treat a different finding as a threat.

- **A** runs the tools only in the management account. Member activity is invisible there, and that account is not the daily operations account.
- **C** shows configuration compliance. A failed Config rule is not cryptomining or compromised credentials.
- **D** does not turn on GuardDuty and does not collect findings. Denying `CreateDetector` also blocks the organization from enabling detectors in the member accounts.

## Lesson 35 — The tag that passed staging must keep pointing at the same bytes

A mutable ECR tag can be moved. A pipeline that deploys `latest` or `prod` can pass staging on Monday’s image and start production on Tuesday’s image, because the tag now points at a new digest. **Immutable tags** make that push fail. Each build uses a new tag, usually the git commit, and staging and production both pull that digest.

Scanning is a separate switch. **Scan on push**, with Amazon Inspector enhanced scanning, inspects the image when it arrives. The scan does not block anything by itself. The pipeline has to wait for the result and fail the promotion when the severity is critical. A monthly scan of running containers finds the problem after production is already on the image.

A lifecycle policy only expires old images. GuardDuty does not replace the image CVE scan. Rebuilding the image in the production account creates bytes that staging never tested.

| The stem says                                          | Use                                                                   |
| ------------------------------------------------------ | --------------------------------------------------------------------- |
| This tag must not move to a new image                  | Immutable tags, and deploy by digest                                  |
| Find critical CVEs before deploy                       | Inspector scan on push, then a pipeline gate that fails the promotion |
| Delete images that are older than the retention period | A lifecycle policy, in addition to the scan                           |
| The artifact production runs                           | The same digest that passed the scan and staging                      |

## Your turn

A pipeline builds a container, tags it with the git commit, and pushes it to ECR. Staging and production must run those exact bytes. A later push must not be able to retarget that tag. A critical vulnerability must stop the image before deployment. Use the smallest ongoing operational effort.

Which design meets that?

**A.** Use mutable tags and deploy `latest` to both environments. Run a manual Inspector scan of the running containers once a month.

**B.** Make the repository tags immutable. Enable Inspector scan on push. Fail the pipeline when the scan reports a critical finding. Deploy the same digest to staging and production.

**C.** Add a lifecycle policy that deletes images older than seven days.

**D.** Enable GuardDuty on the cluster and keep the `latest` tag mutable.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct

---

**Cursor**

**B is right.** The other three let the tag move, or they never inspect the image that is about to be deployed.

- **A** deploys `latest`, so the tag can point at a different image by the time production pulls it. A monthly scan looks at containers that are already running.
- **C** deletes old images. It does not stop a tag from being overwritten, and it does not fail a build on a critical finding.
- **D** looks for threats in the cluster. It does not scan the image for vulnerabilities, and `latest` remains movable.

## Lesson 36 — A private build needs a path, and a Docker build needs the daemon

Attaching CodeBuild to a VPC places the build’s elastic network interface in your subnet. The project then loses CodeBuild’s default route to the internet. In a private subnet with no NAT gateway, a push to ECR or a copy to S3 times out unless the endpoints exist.

ECR needs two interface endpoints, `ecr.api` and `ecr.dkr`. Image layers and artifacts also need an **S3 gateway endpoint**, because ECR stores the layers in S3. The CodeBuild security group must be allowed to reach those endpoints on port 443. No inbound rule is required on the build itself.

**Privileged mode** is the other switch, and it does not open that path. It lets the build run the Docker daemon so `docker build` works. A project that only runs unit tests should leave it off. A timeout to ECR, with privileged mode already on, is a missing endpoint or a missing NAT gateway.

Use a NAT gateway when the build must reach something that is not an AWS endpoint, such as a public base image on Docker Hub. Endpoints cannot carry that traffic. Use endpoints when the build only needs ECR, S3, CloudWatch Logs, and other AWS APIs, and the stem wants no internet path.

The project’s service role still needs permission to create the network interface, push to ECR, and write the artifact bucket. A broader role does not create a route.

| The failure                                        | The fix                                            |
| -------------------------------------------------- | -------------------------------------------------- |
| `docker build` cannot start the daemon             | Privileged mode                                    |
| Private subnet, no NAT, timeout reaching ECR or S3 | ECR interface endpoints and an S3 gateway endpoint |
| The build must download from the public internet   | A NAT gateway on the private route table           |
| `AccessDenied` from ECR or S3                      | The CodeBuild service role                         |

## Your turn

A CodeBuild project runs in a private subnet and has privileged mode enabled. It builds an image and pushes it to ECR in the same Region. Artifacts go to S3. There is no NAT gateway. The build times out while contacting ECR. The team wants no path to the internet.

Which change meets that?

**A.** Turn privileged mode off and on again, and add an inbound rule for port 22.

**B.** Add interface endpoints for `ecr.api` and `ecr.dkr`, add an S3 gateway endpoint, and allow the CodeBuild security group to reach them on port 443.

**C.** Move the project to a public subnet and assign a public IP address.

**D.** Replace the CodeBuild service role with `AdministratorAccess` and leave the routes unchanged.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct

---

**Cursor**

**B is right.** The other three do not give a private build a path to ECR and S3.

- **A** toggles privileged mode, which is already on, and opens port 22. The build is failing on an outbound connection to ECR, not on the Docker daemon or an inbound shell.
- **C** puts the project on the internet. The requirement is a private subnet with no internet path.
- **D** widens the service role and leaves the route tables unchanged. A timeout is a missing path, not an access-denied response.

## Lesson 37 — A Synthetics canary walks the site. A deployment canary shifts traffic

“Canary” on this exam means two different things. A **deployment canary** sends a slice of real user traffic to a new version. A **CloudWatch Synthetics canary** is a script, on a schedule or on demand, that pretends to be a user: open the page, sign in, and take a screenshot. It publishes success and failure metrics. It does not shift traffic.

Use the Synthetics canary as a pipeline gate after the staging deploy. The script targets the staging URL. If the sign-in fails, the pipeline stops and production never receives that artifact. The image that passed is still the image that production deploys. A canary that runs only after the production deploy reports an outage you already shipped.

A CPU alarm does not prove the sign-in works. X-Ray shows hops from real requests that already happened. It does not run a scripted journey, and it does not block promotion. A Route 53 health check is a simple probe used for DNS failover. It does not capture a screenshot or walk a login.

Run the canary in the VPC when the staging URL is private, the same way a private CodeBuild project needs a path. A public staging site does not need that.

| The stem says                                                      | Use                                |
| ------------------------------------------------------------------ | ---------------------------------- |
| Send 10 percent of real users to the new version                   | A deployment canary, from lesson 2 |
| Script a sign-in against staging and stop the pipeline if it fails | CloudWatch Synthetics canary       |
| Watch real-request latency across services                         | X-Ray                              |
| Fail over DNS when an endpoint is down                             | Route 53 health check              |

## Your turn

A pipeline deploys an image to staging. Before production, a script must open the staging site, sign in, and store a screenshot. If that journey fails, production must not change. The production deploy must use the image that passed. Use the smallest operational effort.

Which design meets that?

**A.** Run a CloudWatch Synthetics canary against the staging URL as a pipeline gate. Promote that same image only when the canary succeeds.

**B.** Alarm on EC2 `CPUUtilization` and promote when CPU is below 50 percent.

**C.** Turn on X-Ray, deploy to production, and inspect the service map afterward.

**D.** Add a Route 53 health check on the production domain and fail over to a maintenance page. Do not run a staging journey.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**A is right.** The other three never walk the staging sign-in, so they cannot stop a bad image.

- **B** promotes when CPU is low. A broken login can sit on an idle instance and still pass.
- **C** looks at real traffic after production has already changed. X-Ray does not run the script or block the promotion.
- **D** probes the production domain and can fail over to a maintenance page. It does not sign in on staging or save a screenshot.

## Lesson 38 — A long approval is a Standard workflow, not a sleeping function

EventBridge decides that a finding starts automation. It does not snapshot a volume, isolate an instance, retry one API call, and then wait a day for a person. That sequence is **Step Functions**.

Use a **Standard** state machine. Each step is a service integration: create the snapshot, change the security group, publish to SNS. Put retries on the snapshot state so a failed API call does not restart the isolation. For the analyst, use a callback task (`.waitForTaskToken`). The execution pauses, even overnight, until `SendTaskSuccess` or `SendTaskFailure` arrives. Standard executions can run for up to a year, and each execution is audited.

An **Express** workflow is for a high rate of short jobs. It cannot sit for a day waiting on a person. One Lambda function is a single 15-minute execution: a sleep cannot cover a one-day approval, and a retry repeats every step that already succeeded. SNS can deliver the approval request. It does not perform the snapshot or enforce the order.

| The stem says                                       | Use                                               |
| --------------------------------------------------- | ------------------------------------------------- |
| One API action that an alarm can already call       | The alarm action, from lesson 11                  |
| Route this finding to automation                    | EventBridge, with the state machine as the target |
| Several steps, retry one of them, wait for a person | Standard Step Functions, with a callback task     |
| Thousands of short runs, finished in seconds        | Express workflow                                  |

## Your turn

A GuardDuty finding must snapshot the affected EBS volume, move the instance into an isolation security group, notify security, and wait up to one day for an analyst to approve termination. If only the snapshot call fails, retry that step. Use the smallest amount of custom orchestration code.

Which design meets that?

**A.** One Lambda function calls the APIs in order, sleeps until the analyst replies, and retries the whole function after any error.

**B.** EventBridge starts a Standard state machine. The snapshot state has its own retries. A callback task waits for the analyst.

**C.** EventBridge starts an Express workflow that includes the one-day approval.

**D.** Publish the finding to SNS and email the analyst the CLI commands to run.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct

---

**Cursor**

**B is right.** The other three cannot wait a day and retry only the snapshot.

- **A** is capped at 15 minutes, so it cannot sleep until the analyst replies. A failure retries the whole function, including the isolation that already succeeded.
- **C** uses an Express workflow. That type is limited to five minutes and cannot hold a one-day approval.
- **D** emails commands. Nothing snapshots the volume, isolates the instance, or retries the snapshot call.

## Lesson 39 — A feature flag rolls out without a new application version

AppConfig deploys **configuration**. CodeDeploy deploys the application. A flag that must change without a new image, a new task definition, or a new AMI belongs in AppConfig. The running process fetches the current configuration on an interval, through the AppConfig agent or the Lambda extension.

A deployment strategy controls the speed. A canary strategy sends the new configuration to a small share first. A linear strategy adds a percentage on a timer. Bake time is the window at the end of the deployment. You attach the CloudWatch alarm, such as the load balancer’s 5xx rate, to the environment. If that alarm fires during the deployment or the bake, AppConfig restores the previous configuration. You do not launch the old AMI again.

A validator runs before the rollout. A JSON Schema or a Lambda validator rejects a document that is shaped wrong. The alarm catches a document that is valid and still hurts users.

Parameter Store and Secrets Manager can be the source of the document. Neither one, by itself, canaries the value or rolls it back when the 5xx alarm fires. Secrets Manager remains the place for a password that must rotate. Baking the flag into an AMI turns every flag change into the deployment you were trying to avoid.

| The stem says                                                                         | Use                                                 |
| ------------------------------------------------------------------------------------- | --------------------------------------------------- |
| Roll a flag to 10 percent, then everyone, and restore the old value if an alarm fires | AppConfig canary strategy, alarm on the environment |
| Reject a malformed document before anyone receives it                                 | An AppConfig validator                              |
| Rotate a database password                                                            | Secrets Manager                                     |
| Shift user traffic to a new application image                                         | CodeDeploy, from lesson 2                           |

## Your turn

A feature flag must reach 10 percent of the running application first and then everyone. Processes that are already running must pick up the new value without a new image or a new deployment. If the load balancer’s 5xx alarm fires during the bake, the previous flag value must be restored automatically. Use the smallest operational effort.

Which design meets that?

**A.** Bake the flag into a new AMI and roll that AMI out with a CodeDeploy canary. Roll the instances back if the alarm fires.

**B.** Store the flag in AppConfig, deploy it with a canary strategy, and associate the 5xx alarm with the environment. The application retrieves the configuration while it is running.

**C.** Store the flag as an ECR image tag and build a new image for each change.

**D.** Put the flag in an S3 object. If errors rise, have an operator restart the instances.

Reply with the letter and a short reason for each option you reject.

---

**User**

B is correct

---

**Cursor**

**B is right.** The other three turn a flag change into a new build or a manual restart.

- **A** bakes the flag into an AMI and rolls the instances with CodeDeploy. That is a new deployment. Running processes do not pick up the value until they are replaced.
- **C** builds a new image for every change. The flag is no longer configuration.
- **D** waits for an operator to restart instances. Nothing restores the previous value when the 5xx alarm fires, and nothing limits the first step to 10 percent.

## Lesson 40 — New objects replicate asynchronously. Existing objects need a batch

A replication rule copies **new** PUTs from a source bucket to a destination in the same Region or another one. Both buckets need versioning. The copy is asynchronous. Without an extra control, you cannot promise that an object will arrive within 15 minutes.

**Replication Time Control** adds that promise: 99.99 percent of objects replicate within 15 minutes. It also publishes metrics and an event when an object is still pending after that window. It is not synchronous. An RPO of zero is outside what S3 replication can claim.

Objects already in the bucket when you add the rule are not part of it. **S3 Batch Replication** copies that backlog, and it can retry objects that failed. Turning on versioning does not backfill them.

A few objects never enter the rule. Customer-provided encryption keys (SSE-C) are not replicated. SSE-KMS objects replicate only if you enable that option and the replication role can decrypt with the source key and encrypt with the destination key. Delete markers are not copied unless you turn that on, which matters when the destination is supposed to survive an accidental delete in the source.

| The stem says                                                    | Use                                                 |
| ---------------------------------------------------------------- | --------------------------------------------------- |
| Copy new objects to another Region                               | A replication rule, with versioning on both buckets |
| 99.99 percent of them within 15 minutes, and alert on stragglers | Replication Time Control                            |
| Also copy objects that were already there                        | S3 Batch Replication                                |
| A daily recoverable copy, not a 15-minute object mirror          | AWS Backup                                          |

## Your turn

A bucket in `us-east-1` must copy objects to a bucket in `eu-west-1`. Both buckets already have versioning. New objects are encrypted with SSE-S3. 99.99 percent of new objects must arrive within 15 minutes, and the team must get an event when one misses that window. Objects already stored in the source must be copied too.

Which design meets that?

**A.** Add a cross-Region replication rule with Replication Time Control. Run S3 Batch Replication for the objects that are already in the source.

**B.** Add a cross-Region replication rule. Do not enable Replication Time Control, and do not run a batch job.

**C.** Turn versioning off and on again. S3 will synchronously copy the existing objects.

**D.** Create a daily AWS Backup job that copies the bucket to `eu-west-1`.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**A is right.** The other three miss the 15-minute promise, the objects already stored, or both.

- **B** replicates new objects only as a best effort. It has no 15-minute commitment, no event for a late object, and it leaves the existing objects in `us-east-1`.
- **C** does not backfill the bucket. Replication is asynchronous, and toggling versioning does not start a synchronous copy.
- **D** is a once-a-day job. An object written just after the job can wait nearly a day, so it misses the 15-minute window.

## Lesson 41 — A backup vault lock stops the root user. A replication rule does not

AWS Backup is the scheduled recovery point for RDS, EBS, DynamoDB, EFS, S3, and the other services a plan supports. A backup rule sets the frequency and the lifecycle. A copy action in that rule sends the recovery point to another Region, another account, or both. An organization backup policy attaches the plan to an OU, so an account created next month is included without a new job in that account.

The recovery points land in a **backup vault** in the backup account. A vault policy decides who can copy in and who can restore. **Vault Lock** decides whether anyone can delete them. Compliance mode is the exam answer when the stem says that even the root user of the backup account cannot shorten the retention or delete the points before it ends. Governance mode still allows a privileged principal to remove the lock. The lock does not create the backups. The plan does.

S3 replication from lesson 40 mirrors new objects. It is not an application-consistent RDS backup, and it does not cover EBS. Automated RDS backups stay in the workload account, with a short retention, and an administrator there can delete them. Snapshots that “people are told not to delete” are not locked.

| The stem says                                                                 | Use                                        |
| ----------------------------------------------------------------------------- | ------------------------------------------ |
| Daily recovery points for RDS and EBS in every account, including future ones | An organization backup policy              |
| A second copy in another Region or account                                    | A copy action into that vault              |
| Root cannot delete the points for a fixed retention                           | Vault Lock in compliance mode              |
| New S3 objects in another Region within 15 minutes                            | Replication Time Control, not a backup job |

## Your turn

Every current and future account must take a daily backup of its RDS databases and EBS volumes. Copies must land in a vault in a backup account in a second Region. Even the root user of that backup account must be unable to delete those recovery points for seven years. Use the smallest ongoing operational effort.

Which design meets that?

**A.** An organization backup policy with a daily plan, a cross-account and cross-Region copy into the central vault, and Vault Lock in compliance mode for seven years.

**B.** Cross-Region replication with Replication Time Control on the application’s S3 bucket.

**C.** Automated RDS backups with seven-day retention in each workload account.

**D.** EBS snapshots in each workload account, with a written instruction not to delete them.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**A is right.** The other three protect a different resource, a shorter retention, or only a written promise.

- **B** mirrors new S3 objects. It does not create RDS or EBS recovery points, and Replication Time Control is not a seven-year lock.
- **C** keeps seven days of RDS backups in each workload account. A new account is not covered until someone configures it, and an administrator there can delete the backups.
- **D** leaves the snapshots where the workload account can delete them. An instruction is not a vault lock, and a future account does not get the job automatically.

## Lesson 42 — Replicate the existing machines when you cannot redesign them

Lesson 9 picked a Region strategy from RPO, RTO, and what is already running. Those four strategies assume you can shape the recovery: backups, a data replica with servers off, a small stack already up, or two live Regions. Some applications cannot be reshaped this year.

**AWS Elastic Disaster Recovery** continuously replicates the disks of the existing EC2 instances or on-premises servers into a staging area in the target Region. The staging volumes are not a second full-size fleet serving users. On failover you launch recovery instances, which usually takes minutes. The data loss window is seconds, not a backup interval. A drill launches a copy for a test without cutting production over.

Use it when the stem says minimal change to the servers, continuous replication, an RPO of seconds, and an RTO of minutes. Do not use it as a substitute for a cheaper daily backup when hours of data loss are acceptable. Do not use it for a stateless service whose data already lives in DynamoDB or Aurora and whose compute is an immutable image. Those services have their own replication. A full second Region that is already serving traffic is still multi-site active-active, and it costs more than a staging area.

| The stem says                                                                                                | Use                                      |
| ------------------------------------------------------------------------------------------------------------ | ---------------------------------------- |
| Hours of data loss are acceptable, and cost should stay low                                                  | Backup and restore, including AWS Backup |
| The database can be replicated and the servers can stay off                                                  | Pilot light                              |
| A smaller copy is already running and can take traffic                                                       | Warm standby                             |
| Both Regions serve full traffic                                                                              | Multi-site active-active                 |
| Existing servers must be replicated as they are, with seconds of data loss and a test that does not cut over | Elastic Disaster Recovery                |

## Your turn

A stateful application runs on EC2 and on a set of on-premises servers. It cannot be refactored this year. A site loss may lose only a few seconds of data. Recovery machines do not need to be running at full size beforehand, and launching them may take minutes. The team must be able to test recovery without interrupting production. Change to the application should be minimal.

Which design meets that?

**A.** Elastic Disaster Recovery, with continuous replication into a staging area in the target Region and non-disruptive drills.

**B.** A daily AWS Backup of the EBS volumes, restored after the site is lost.

**C.** Multi-site active-active at full capacity in two Regions.

**D.** A pilot light that first replaces the servers with new AMIs and moves the data into RDS replicas.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**A is right.** The other three lose more data than the stem allows, or they redesign the application.

- **B** restores a daily EBS backup. That can lose up to a day of data, and it does not continuously replicate the on-premises servers.
- **C** runs a full second copy that is already serving users. The stem allows the recovery machines to stay off until failover.
- **D** replaces the servers with new AMIs and RDS replicas. That is the refactor the team cannot do this year.

## Lesson 43 — One writer with a fast secondary, or writes in every Region

A Region failure is outside Multi-AZ. Two managed databases cover it in different ways.

**Aurora Global Database** has one writer Region. Secondary Regions receive storage-level replication, usually within a second, and their reader instances serve local reads. If the primary Region is lost, you promote a secondary. That failover is typically about a minute, and the data loss is usually under a second. Until the promotion, the secondary does not become an independent writer. Write forwarding still sends the write to the primary. A secondary with no readers is the cheaper pilot-light shape. Add readers only when the stem asks for local reads.

**DynamoDB global tables** are multi-active. An application in each Region reads and writes the local table, and DynamoDB replicates the changes, usually within a second. Conflicts resolve by last writer wins. Use this when both Regions must accept writes. It is not a MySQL database, and it does not give you a single primary with relational transactions.

Neither one is a seven-year backup. Point-in-time recovery and AWS Backup still hold the recovery points. Elastic Disaster Recovery is the wrong tool once the data already has this native replication.

| The stem says                                                                 | Use                      |
| ----------------------------------------------------------------------------- | ------------------------ |
| Relational, one writer, readers in a second Region, promote in about a minute | Aurora Global Database   |
| DynamoDB, and users in both Regions must write locally                        | Global tables            |
| Loss of one Availability Zone, same Region, same writer endpoint              | Multi-AZ, from lesson 28 |
| Keep a daily or yearly recovery point                                         | AWS Backup               |

## Your turn

A MySQL-compatible database has its writer in `us-east-1`. Readers in `eu-west-1` must serve local reads with about a second of lag or less. If `us-east-1` is lost, `eu-west-1` must become the writer in about a minute, with less than a second of data loss. Until that failover, applications in Europe must not write locally.

Which design meets that?

**A.** An Aurora Global Database with the primary cluster in `us-east-1` and a secondary cluster with readers in `eu-west-1`.

**B.** DynamoDB global tables, with applications in both Regions writing to the local table.

**C.** RDS Multi-AZ in `us-east-1` only.

**D.** Elastic Disaster Recovery of a self-managed database server, with no native database replication.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**A is right.** The other three either let both Regions write, or they never leave `us-east-1`.

- **B** makes both Regions writers. Europe would write locally before any failover, and the store is not the MySQL-compatible database in the stem.
- **C** fails over only inside `us-east-1`. It has no readers in `eu-west-1` and does not survive loss of the Region.
- **D** replicates a server’s disks. Aurora Global Database already replicates this database with the lag and promotion time the stem asks for.

## Lesson 44 — Page on the rate only when there is enough traffic

An error **count** treats one failure and one thousand failures as different sizes, and it ignores how many requests succeeded. An error **rate** divides `5xx` by request count. One failure out of one night-time request is 100 percent, so a rate alarm pages for a single quiet error. The same 5 percent during the day, across thousands of requests, is the incident.

The page has to require both conditions. A **composite alarm** watches other alarm states. Its rule is `ALARM(error-rate)` **AND** `ALARM(request-count)`. Put the SNS action on the composite only, so the two child alarms do not page on their own. **OR** is the trap: high traffic with a healthy rate, or one lonely failure, both page.

Metric math can express the same gate in one alarm: if the request count is above 100, use the rate, otherwise use 0. A composite is the clearer exam choice when the stem already talks about two alarms. Neither one learns a daily curve. That is still anomaly detection. M out of N datapoints only skip a short blip. They do not require a minimum sample.

| The stem says                                                      | Use                                     |
| ------------------------------------------------------------------ | --------------------------------------- |
| More than ten 5xx responses, regardless of traffic                 | A static alarm on the count             |
| Above 5 percent errors, but only if the period has enough requests | A composite: rate **and** request count |
| Either symptom is enough to page                                   | A composite with **OR**                 |
| Outside the normal band for this hour                              | Anomaly detection                       |

## Your turn

One failed request at night is 100 percent errors, and the team is paged. During the day, a 5 percent error rate across thousands of requests is a real incident. They want one notification, only when the error rate is above 5 percent and the period has more than 100 requests.

Which design meets that?

**A.** A composite alarm that is in alarm when the rate alarm and the request-count alarm are both in alarm. Send SNS from the composite only.

**B.** An anomaly detection alarm on CPU utilization.

**C.** A static alarm that fires when the 5xx count is greater than zero.

**D.** A composite alarm that fires when the rate is above 5 percent or the request count is above 100.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is corrrect

---

**Cursor**

**A is right.** The other three page on a different signal, or they page when only one of the two conditions is true.

- **B** watches CPU. It never measures the 5xx rate or how many requests were served.
- **C** pages on a single 5xx response. That is the night-time failure, and it does not check whether the rate is above 5 percent.
- **D** uses **or**. High traffic with a healthy rate pages, and so does one failure out of one request. The notification has to require both.

## Lesson 45 — A landing zone, a pushed baseline, and a menu are three different tools

This is the last lesson. It separates three tools that all sit on CloudFormation.

**Control Tower** builds the multi-account landing zone: Organizations, account vending through Account Factory, preventive guardrails as SCPs, and detective guardrails as Config rules. Choose it when the company does not yet have that landing zone and wants new accounts to come with the guardrails already applied. It is more than one template. If the landing zone already exists, do not stand Control Tower up again just to publish a bucket.

**StackSets** push a template. A service-managed StackSet with automatic deployment, from lesson 8, applies one baseline to every account in an OU, including accounts that appear later. The central team runs it. An account receives the stack even when nobody in that account requested it.

**Service Catalog** is the menu. A product is an approved template. A portfolio grants a team access to it. A **launch constraint** names a role that Catalog assumes, so the developer does not need permission to create the bucket, the database, or the network. A template constraint limits the parameters they can enter. The developer launches a product when they need it. Updating the product updates the standard for the next launch.

An SCP can stop a bad API call. It cannot offer an approved S3 product or fill in encryption parameters. `AdministratorAccess` plus a wiki page is not a constraint.

| The stem says                                                                              | Use                                       |
| ------------------------------------------------------------------------------------------ | ----------------------------------------- |
| Create the landing zone, vend accounts, and apply guardrails                               | Control Tower                             |
| Push this template to every account in the OU, including future accounts                   | Service-managed StackSet                  |
| Let a developer launch an approved product, without IAM rights to the underlying resources | Service Catalog, with a launch constraint |
| Limit the parameters they can type                                                         | A template constraint on that product     |

## Your turn

The company already has a Control Tower landing zone. Developers must launch an approved private S3 bucket with encryption. They can set only the parameters the platform team allows. They must not receive CloudFormation or S3 administration rights. The platform team will update the standard by updating the product.

Which design meets that?

**A.** A Service Catalog product, shared through a portfolio, with a launch role and a template constraint on the parameters.

**B.** A service-managed StackSet that creates the bucket in every account in the OU, whether or not anyone requested it.

**C.** Set up a second Control Tower landing zone and enable every elective guardrail.

**D.** Grant the developers `AdministratorAccess` and publish the bucket standard on a wiki page.

Reply with the letter and a short reason for each option you reject.

---

**User**

A is correct

---

**Cursor**

**A is right.** The other three push a stack, rebuild a landing zone, or drop the permission limit.

- **B** creates the bucket in every account, including accounts where nobody asked for one. The developers still do not get a constrained product to launch.
- **C** stands up another landing zone. The company already has Control Tower, and elective guardrails are not an S3 product with limited parameters.
- **D** gives the developers full administration. A wiki page does not limit the parameters or remove those rights.

That is lesson 45 of 45. The course is complete.

On the exam, read the constraint before the options. The usual deciding words are: same artifact, minutes to roll back, private subnet, including accounts created later, root must not delete it, one writer, both Regions write, and no new deployment. The wrong answer is often a real AWS design that misses one of those words.

You can ask for a mixed drill next: short scenarios that jump across these 45 lessons the way the exam does.
