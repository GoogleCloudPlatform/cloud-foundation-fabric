## Cursed Knowledge we have learned as a result of building Cloud Foundation Fabric

<!-- new entries go at the top -->

* 2025-10-23 Some [service agents](https://cloud.google.com/iam/docs/service-agents) are not created upon API activation nor calling `google_project_service_identity`. Since we have no way of knowing if they exist, we avoid automatically granting their respective roles in the project module. The list of agents for which we do not perform automatic grants can be found in the [tools/build_service_agents.py](./tools/build_service_agents.py) script.
* 2025-10-23 Use `terraform plan` after `terraform apply` to confirm that the plan is empty after applying the changes. Non-empty plan is a sign of potential bug in either Terraform code or provider and suggests, that configuration might not have been applied as expected or potential problems when implementing future changes
* 2025-10-23 Do not use `data` resource. Even if you must, then still it might be [a bad idea](#avoid-data-resources)
* 2025-10-23 when referring other resource prefer using `.id` attribute over names. `.id` is computed field, and will force update when referred resource is replaced. Sometimes this requires explicit `depends_on` - for example for Cloud Run IAM, so it is recreated when parent resource is replaced
* 2025-10-23 Maps are the best drivers for `for_each` on the resource level. When using lists, and adding something in the middle of list means that all resources following insertion needs to be replaced
* 2025-10-21 Type checking in ternaries requires both sides to have identical types. For objects, it means that they need to define the same fields. And sometimes `null` and `tonumber(null)` don't converge to a common type (citation needed)
* 2025-10-21 Terraform dependency graph considers a variable or a local as one node in the graph [adrs/20251013-context-locals.md], you may resolve your dependency cycles by just rearranging your variables / locals. But for resources - the dependency is tracked on attribute level and plan may differ depending on which attribute you depend
* 2025-10-21 `create_before_destory` meta-argument is [contagious](https://github.com/hashicorp/terraform/blob/main/docs/destroying.md#forced-create-before-destroy), which means - any resource that any resource depending on CBD resource will also be marked as CBD. This hits hard, when affected resource is silently accepting creation with the same name, even if the object exists (`google_storage_bucket_object`, I'm looking at you)


## Detailed explanations
### Avoid `data` resources
There are two problems, when using `data` resources:
* when reading is deferred to during apply, any values it returns are also `known after apply`, which may result in unnecessary resource replacement
* when deploying more complex infrastructure with `data` resources, and your deployment fails in the middle, it might be not possible to recover without manual intervention in what is configured, so `data` resource can read its values

What is considered a safe use case for `data` resource:
* using it for validating invariants (resource is guaranteed to exist across full lifecycle of the state)
* using `data` resource outputs in attributes without `ForceNew` flag - so even if `data` will be read during apply, it will result in spurious update-in-place instead of replacement

In Fabric FAST modules `data` resources are used only by request to simplify calling, but then the above caveats apply to the whole module.
