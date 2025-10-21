## Cursed Knowledge we have learned as a result of building Cloud Foundation Fabric

<!-- new entries go at the top -->

* 2025-10-21 Type checking in ternaries requires both sides to have identical types. For objects, it means that they need to define the same fields. And sometimes `null` and `tonumber(null)` don't converge to a common type (citation needed)
* 2025-10-21 You can't call a provider function within brackets [opentofu#3401](https://github.com/opentofu/opentofu/issues/3401)
* 2025-10-21 Terraform dependency graph considers a variable or a local as one node in the graph [adrs/20251013-context-locals.md], you may resolve your dependency cycles by just rearranging your variables / locals.
* 2025-10-21 `create_before_destory` meta-argument is [contagious](https://github.com/hashicorp/terraform/blob/main/docs/destroying.md#forced-create-before-destroy), which means - any resource that any resource depending on CBD resource will also be marked as CBD. This hits hard, when affected resource is silently accepting creation with the same name, even if the object exists (`google_storage_bucket_object`, I'm looking at you)
