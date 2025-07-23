# Changelog

All notable changes to this project will be documented in this file.
<!-- markdownlint-disable MD024 -->

## [Unreleased] <!-- from: 2025-05-21 08:30:09+00:00 to: None since: v40.0.0 -->

## [41.0.0] - 2025-06-29

### BREAKING CHANGES

- `fast/stages/0-bootstrap`: two new custom roles for KMS keys have been added: re-run stage 0 so that they are available to the resman stage, where they are required. [[#3147](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3147)]

### BLUEPRINTS

- [[#3195](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3195)] Add default route action to internal app lb path matcher ([sepehrjavid](https://github.com/sepehrjavid)) <!-- 2025-06-26 12:21:32+00:00 -->

### FAST

- [[#3199](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3199)] Rename workflows config variable introduced in #3198 ([ludoo](https://github.com/ludoo)) <!-- 2025-06-28 08:57:56+00:00 -->
- [[#3198](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3198)] Support user-defined tfvar files in resman CI/CD definitions ([ludoo](https://github.com/ludoo)) <!-- 2025-06-27 14:58:54+00:00 -->
- [[#3195](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3195)] Add default route action to internal app lb path matcher ([sepehrjavid](https://github.com/sepehrjavid)) <!-- 2025-06-26 12:21:32+00:00 -->
- [[#3190](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3190)] Added option for tag factory in resman ([lnesteroff](https://github.com/lnesteroff)) <!-- 2025-06-23 21:31:52+00:00 -->
- [[#3185](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3185)] Bypass accounts.google.com in FAST DNS policy rules ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 08:00:01+00:00 -->
- [[#3183](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3183)] Revert "Bypass accounts.google.com in FAST DNS policy rules" ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 06:19:43+00:00 -->
- [[#3179](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3179)] Bypass accounts.google.com in FAST DNS policy rules ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 05:55:50+00:00 -->
- [[#3163](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3163)] Allow custom roles in context, add support for shared VPC IAM to project and project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-15 08:01:22+00:00 -->
- [[#3160](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3160)] Add notebooks, appengine and appspot to dns policy routing in FAST networking stage ([wiktorn](https://github.com/wiktorn)) <!-- 2025-06-13 14:46:44+00:00 -->
- [[#3162](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3162)] Improve and document org policy tags use in FAST resman stage ([ludoo](https://github.com/ludoo)) <!-- 2025-06-13 13:57:48+00:00 -->
- [[#3154](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3154)] Allow configuring project key format in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-11 11:18:03+00:00 -->
- [[#3147](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3147)] Fix IAM delegation for project factory on security KMS keys ([ludoo](https://github.com/ludoo)) <!-- 2025-06-10 10:56:30+00:00 -->

### MODULES

- [[#3199](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3199)] Rename workflows config variable introduced in #3198 ([ludoo](https://github.com/ludoo)) <!-- 2025-06-28 08:57:56+00:00 -->
- [[#3195](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3195)] Add default route action to internal app lb path matcher ([sepehrjavid](https://github.com/sepehrjavid)) <!-- 2025-06-26 12:21:32+00:00 -->
- [[#3178](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3178)] Added tag factory option for organization module ([lnesteroff](https://github.com/lnesteroff)) <!-- 2025-06-23 06:24:43+00:00 -->
- [[#3181](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3181)] Support new style service account principalsets in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 06:10:21+00:00 -->
- [[#3179](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3179)] Bypass accounts.google.com in FAST DNS policy rules ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 05:55:50+00:00 -->
- [[#3163](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3163)] Allow custom roles in context, add support for shared VPC IAM to project and project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-15 08:01:22+00:00 -->
- [[#3154](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3154)] Allow configuring project key format in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-11 11:18:03+00:00 -->
- [[#3106](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3106)] Revert "Make automation project in project factory module optional" ([ludoo](https://github.com/ludoo)) <!-- 2025-05-21 13:01:40+00:00 -->

### TOOLS

- [[#3195](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3195)] Add default route action to internal app lb path matcher ([sepehrjavid](https://github.com/sepehrjavid)) <!-- 2025-06-26 12:21:32+00:00 -->
- [[#3179](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3179)] Bypass accounts.google.com in FAST DNS policy rules ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 05:55:50+00:00 -->
- [[#3160](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3160)] Add notebooks, appengine and appspot to dns policy routing in FAST networking stage ([wiktorn](https://github.com/wiktorn)) <!-- 2025-06-13 14:46:44+00:00 -->

## [40.2.0] - 2025-06-29

### BREAKING CHANGES

- `modules/ai-applications`: renamed `agentspace` module to `ai-applications` [[#3184](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3184)]
- `fast/stages/0-bootstrap`: two new custom roles for KMS keys have been added: re-run stage 0 so that they are available to the resman stage, where they are required. [[#3147](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3147)]
- `modules/gke-nodepool`: renamed variable `network_config.additional_pod_network_config` to `network_config.additional_pod_network_configs` [[#3134](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3134)]

### BLUEPRINTS

- [[#3201](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3201)] Update service-agents.yaml ([juliocc](https://github.com/juliocc)) <!-- 2025-06-28 17:59:06+00:00 -->
- [[#3200](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3200)] Remove blueprint metadata validation ([juliocc](https://github.com/juliocc)) <!-- 2025-06-28 17:06:11+00:00 -->
- [[#3120](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3120)] Bump Terraform to 1.11 ([juliocc](https://github.com/juliocc)) <!-- 2025-05-29 09:11:39+00:00 -->
- [[#3114](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3114)] Allow creation of regional templates in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-27 12:18:40+00:00 -->

### FAST

- [[#3199](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3199)] Rename workflows config variable introduced in #3198 ([ludoo](https://github.com/ludoo)) <!-- 2025-06-28 08:57:56+00:00 -->
- [[#3198](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3198)] Support user-defined tfvar files in resman CI/CD definitions ([ludoo](https://github.com/ludoo)) <!-- 2025-06-27 14:58:54+00:00 -->
- [[#3195](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3195)] Add default route action to internal app lb path matcher ([sepehrjavid](https://github.com/sepehrjavid)) <!-- 2025-06-26 12:21:32+00:00 -->
- [[#3193](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3193)] Only consider active projects to default VPC SC perimeter ([juliocc](https://github.com/juliocc)) <!-- 2025-06-25 16:01:01+00:00 -->
- [[#3190](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3190)] Added option for tag factory in resman ([lnesteroff](https://github.com/lnesteroff)) <!-- 2025-06-23 21:31:52+00:00 -->
- [[#3180](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3180)] Fixed hard-coded resource management tags (!var.tag_names) ([lnesteroff](https://github.com/lnesteroff)) <!-- 2025-06-20 09:50:58+00:00 -->
- [[#3187](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3187)] Clean fast 2 security from vpcsc ([aumohr](https://github.com/aumohr)) <!-- 2025-06-20 09:22:22+00:00 -->
- [[#3185](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3185)] Bypass accounts.google.com in FAST DNS policy rules ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 08:00:01+00:00 -->
- [[#3183](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3183)] Revert "Bypass accounts.google.com in FAST DNS policy rules" ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 06:19:43+00:00 -->
- [[#3179](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3179)] Bypass accounts.google.com in FAST DNS policy rules ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 05:55:50+00:00 -->
- [[#3174](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3174)] Fixed option to set descriptions for environment tag values ([lnesteroff](https://github.com/lnesteroff)) <!-- 2025-06-19 07:00:17+00:00 -->
- [[#3163](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3163)] Allow custom roles in context, add support for shared VPC IAM to project and project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-15 08:01:22+00:00 -->
- [[#3160](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3160)] Add notebooks, appengine and appspot to dns policy routing in FAST networking stage ([wiktorn](https://github.com/wiktorn)) <!-- 2025-06-13 14:46:44+00:00 -->
- [[#3162](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3162)] Improve and document org policy tags use in FAST resman stage ([ludoo](https://github.com/ludoo)) <!-- 2025-06-13 13:57:48+00:00 -->
- [[#3154](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3154)] Allow configuring project key format in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-11 11:18:03+00:00 -->
- [[#3147](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3147)] Fix IAM delegation for project factory on security KMS keys ([ludoo](https://github.com/ludoo)) <!-- 2025-06-10 10:56:30+00:00 -->
- [[#3146](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3146)] Bump requests from 2.32.2 to 2.32.4 in /fast/project-templates/secops-anonymization-pipeline/source ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2025-06-10 08:51:36+00:00 -->
- [[#3145](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3145)] Add KMS keys interpolation to project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-10 08:24:25+00:00 -->
- [[#3134](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3134)] fix additional pod networks config creation in GKE node pool ([jacek-jablonski](https://github.com/jacek-jablonski)) <!-- 2025-06-05 11:41:51+00:00 -->
- [[#3126](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3126)] Allow multiple types in JSON schema docs tool ([ludoo](https://github.com/ludoo)) <!-- 2025-05-31 09:58:20+00:00 -->
- [[#3120](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3120)] Bump Terraform to 1.11 ([juliocc](https://github.com/juliocc)) <!-- 2025-05-29 09:11:39+00:00 -->
- [[#3114](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3114)] Allow creation of regional templates in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-27 12:18:40+00:00 -->
- [[#3112](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3112)] Add support for service agent expansion to project factory IAM ([ludoo](https://github.com/ludoo)) <!-- 2025-05-24 10:33:20+00:00 -->

### MODULES

- [[#3201](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3201)] Update service-agents.yaml ([juliocc](https://github.com/juliocc)) <!-- 2025-06-28 17:59:06+00:00 -->
- [[#3202](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3202)] Fix ai-applications provider_meta ([juliocc](https://github.com/juliocc)) <!-- 2025-06-28 17:44:05+00:00 -->
- [[#3197](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3197)] Create (or import) subnets with empty description ([lnesteroff](https://github.com/lnesteroff)) <!-- 2025-06-28 02:15:05+00:00 -->
- [[#3196](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3196)] Added node_pool_auto_config to GKE cluster ([apichick](https://github.com/apichick)) <!-- 2025-06-26 18:26:09+00:00 -->
- [[#3195](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3195)] Add default route action to internal app lb path matcher ([sepehrjavid](https://github.com/sepehrjavid)) <!-- 2025-06-26 12:21:32+00:00 -->
- [[#3192](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3192)] Added option to set force_destroy on pf buckets ([lnesteroff](https://github.com/lnesteroff)) <!-- 2025-06-25 23:20:41+00:00 -->
- [[#3191](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3191)] fix failing E2E test for net-vpc ([wiktorn](https://github.com/wiktorn)) <!-- 2025-06-24 11:20:53+00:00 -->
- [[#3178](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3178)] Added tag factory option for organization module ([lnesteroff](https://github.com/lnesteroff)) <!-- 2025-06-23 06:24:43+00:00 -->
- [[#3189](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3189)] [module/ai-applications] fix module for unexpected updates from APIs ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-06-22 20:59:16+00:00 -->
- [[#3169](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3169)] Addition of Cloud Deploy Module ([vineeteldochan](https://github.com/vineeteldochan)) <!-- 2025-06-22 18:39:14+00:00 -->
- [[#3177](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3177)] Add support for IPv6 only subnets and IP collections ([cmm-cisco](https://github.com/cmm-cisco)) <!-- 2025-06-20 16:22:09+00:00 -->
- [[#3184](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3184)] Rename agentspace module to ai-applications ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-06-20 07:53:18+00:00 -->
- [[#3181](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3181)] Support new style service account principalsets in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 06:10:21+00:00 -->
- [[#3179](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3179)] Bypass accounts.google.com in FAST DNS policy rules ([ludoo](https://github.com/ludoo)) <!-- 2025-06-20 05:55:50+00:00 -->
- [[#3170](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3170)] Add new Agentspace module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-06-19 09:36:28+00:00 -->
- [[#3172](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3172)] feat: Update session affinity validation for ALB ([williamsmt](https://github.com/williamsmt)) <!-- 2025-06-18 13:38:35+00:00 -->
- [[#3165](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3165)] Cloud run direct iap ([msikora-rtb](https://github.com/msikora-rtb)) <!-- 2025-06-18 10:28:54+00:00 -->
- [[#3149](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3149)] Add support for DNS zones to Apigee module ([apichick](https://github.com/apichick)) <!-- 2025-06-18 08:44:00+00:00 -->
- [[#3161](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3161)] feat: ignores labels added by gh action in unmanaged cloud run service / job ([msikora-rtb](https://github.com/msikora-rtb)) <!-- 2025-06-16 08:09:14+00:00 -->
- [[#3163](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3163)] Allow custom roles in context, add support for shared VPC IAM to project and project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-15 08:01:22+00:00 -->
- [[#3156](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3156)] Allow to directly specify service agents for CMEK in project module (Composer v2 support) ([jnahelou](https://github.com/jnahelou)) <!-- 2025-06-12 18:27:41+00:00 -->
- [[#3157](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3157)] Fixed problem with backend preference, changed it to boolean. Backend… ([apichick](https://github.com/apichick)) <!-- 2025-06-12 05:40:39+00:00 -->
- [[#3154](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3154)] Allow configuring project key format in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-11 11:18:03+00:00 -->
- [[#3153](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3153)] Bring back master ipv4 cidr block ([jacklever-hub24](https://github.com/jacklever-hub24)) <!-- 2025-06-11 09:51:47+00:00 -->
- [[#3140](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3140)] Added recipe for Apigee X with SWP ([apichick](https://github.com/apichick)) <!-- 2025-06-11 05:40:17+00:00 -->
- [[#3150](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3150)] Added default compute network tier to project module ([apichick](https://github.com/apichick)) <!-- 2025-06-10 21:44:39+00:00 -->
- [[#3151](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3151)] Added network tier to network interfaces in compute-vm module ([apichick](https://github.com/apichick)) <!-- 2025-06-10 21:26:44+00:00 -->
- [[#3145](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3145)] Add KMS keys interpolation to project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-06-10 08:24:25+00:00 -->
- [[#3139](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3139)] Added backend preference to global application load balancers ([apichick](https://github.com/apichick)) <!-- 2025-06-10 06:49:47+00:00 -->
- [[#3144](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3144)] Fix #3142 ([juliocc](https://github.com/juliocc)) <!-- 2025-06-10 06:08:44+00:00 -->
- [[#3143](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3143)] Fixed mistake in net-vpn-ha module docs ([apichick](https://github.com/apichick)) <!-- 2025-06-09 19:45:18+00:00 -->
- [[#3141](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3141)] Improve SWP transparent gateway example ([wiktorn](https://github.com/wiktorn)) <!-- 2025-06-09 07:43:23+00:00 -->
- [[#3129](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3129)] Cloud Run with IAP recipe ([apichick](https://github.com/apichick)) <!-- 2025-06-08 12:51:09+00:00 -->
- [[#3137](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3137)] Return instance ID not IP address ([kkrtbhouse](https://github.com/kkrtbhouse)) <!-- 2025-06-06 11:21:34+00:00 -->
- [[#3135](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3135)] CloudSQL - Create password resource only when needed ([wiktorn](https://github.com/wiktorn)) <!-- 2025-06-05 14:28:58+00:00 -->
- [[#3134](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3134)] fix additional pod networks config creation in GKE node pool ([jacek-jablonski](https://github.com/jacek-jablonski)) <!-- 2025-06-05 11:41:51+00:00 -->
- [[#3133](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3133)] Add explicit errors when VPC-SC perimeters reference undefined directional policies ([juliocc](https://github.com/juliocc)) <!-- 2025-06-04 18:50:33+00:00 -->
- [[#3128](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3128)] Added multi-region API Gateway recipe, that was removed by accident ([apichick](https://github.com/apichick)) <!-- 2025-06-01 11:26:16+00:00 -->
- [[#3127](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3127)] Interpolate egress_to resources in enforced perimeter config ([juliocc](https://github.com/juliocc)) <!-- 2025-05-31 16:11:07+00:00 -->
- [[#3126](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3126)] Allow multiple types in JSON schema docs tool ([ludoo](https://github.com/ludoo)) <!-- 2025-05-31 09:58:20+00:00 -->
- [[#3125](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3125)] Document x-referencing HCs in net-lb-int ([sruffilli](https://github.com/sruffilli)) <!-- 2025-05-30 16:34:30+00:00 -->
- [[#3124](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3124)] Allow explicit definition of automation prefix in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-05-30 12:30:54+00:00 -->
- [[#3119](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3119)] Expose private_endpoint_enforcement_enabled in gke modules ([juliocc](https://github.com/juliocc)) <!-- 2025-05-29 10:33:03+00:00 -->
- [[#3120](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3120)] Bump Terraform to 1.11 ([juliocc](https://github.com/juliocc)) <!-- 2025-05-29 09:11:39+00:00 -->
- [[#3083](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3083)] Remove default values for access_config.ip_config for gke cluster modules ([jaiakt](https://github.com/jaiakt)) <!-- 2025-05-28 20:07:36+00:00 -->
- [[#3117](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3117)] adds revision label ([msikora-rtb](https://github.com/msikora-rtb)) <!-- 2025-05-28 16:32:06+00:00 -->
- [[#3116](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3116)] Add support for binary authorization policy to cloud function v2 module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-28 15:01:43+00:00 -->
- [[#3114](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3114)] Allow creation of regional templates in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-27 12:18:40+00:00 -->
- [[#3113](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3113)] Allow creating disks with no name in compute-vm ([ludoo](https://github.com/ludoo)) <!-- 2025-05-27 07:19:13+00:00 -->
- [[#3112](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3112)] Add support for service agent expansion to project factory IAM ([ludoo](https://github.com/ludoo)) <!-- 2025-05-24 10:33:20+00:00 -->
- [[#3105](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3105)] Add option to specify any port on https protocol ([Stepanenko-Alexey](https://github.com/Stepanenko-Alexey)) <!-- 2025-05-24 06:31:18+00:00 -->
- [[#3110](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3110)] Support iam_sa_roles in project factory service accounts ([ludoo](https://github.com/ludoo)) <!-- 2025-05-22 08:22:32+00:00 -->

### TOOLS

- [[#3203](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3203)] Add PEP 723 dependencies to tfdoc.py, versions.py and build_service_agents.py ([juliocc](https://github.com/juliocc)) <!-- 2025-06-28 18:48:07+00:00 -->
- [[#3200](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3200)] Remove blueprint metadata validation ([juliocc](https://github.com/juliocc)) <!-- 2025-06-28 17:06:11+00:00 -->
- [[#3126](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3126)] Allow multiple types in JSON schema docs tool ([ludoo](https://github.com/ludoo)) <!-- 2025-05-31 09:58:20+00:00 -->
- [[#3120](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3120)] Bump Terraform to 1.11 ([juliocc](https://github.com/juliocc)) <!-- 2025-05-29 09:11:39+00:00 -->

## [40.1.0] - 2025-05-21

### BLUEPRINTS

- [[#3107](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3107)] Add fast_version.txt to FAST stages ([juliocc](https://github.com/juliocc)) <!-- 2025-05-21 13:10:58+00:00 -->

### FAST

- [[#3108](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3108)] Add version tracking files to FAST ([ludoo](https://github.com/ludoo)) <!-- 2025-05-21 14:14:06+00:00 -->
- [[#3107](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3107)] Add fast_version.txt to FAST stages ([juliocc](https://github.com/juliocc)) <!-- 2025-05-21 13:10:58+00:00 -->

### MODULES

- [[#3107](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3107)] Add fast_version.txt to FAST stages ([juliocc](https://github.com/juliocc)) <!-- 2025-05-21 13:10:58+00:00 -->

### TOOLS

- [[#3107](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3107)] Add fast_version.txt to FAST stages ([juliocc](https://github.com/juliocc)) <!-- 2025-05-21 13:10:58+00:00 -->

## [40.0.0] - 2025-05-21

### BREAKING CHANGES

- `fast/stages/0-boostrap`: the default set of organization policies now prevents the creation of bridge perimeters. [[#3098](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3098)]
- `modules/vpc-sc`: perimeter bridge are no longer supported. Please migrate to directional policies (ingress/egress rules) for more granular and secure perimeter configurations.
`modules/vpc-sc`: `service_perimeters_regular` renamed to `perimeters` [[#3062](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3062)]

### BLUEPRINTS

- [[#3062](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3062)] VPC SC module refactor ([juliocc](https://github.com/juliocc)) <!-- 2025-05-09 12:37:03+00:00 -->
- [[#3066](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3066)] New FAST data platform ([ludoo](https://github.com/ludoo)) <!-- 2025-05-03 21:21:38+00:00 -->

### FAST

- [[#3074](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3074)] Improves fast/data-platform-ng README for clarity ([jayBana](https://github.com/jayBana)) <!-- 2025-05-21 07:30:25+00:00 -->
- [[#3098](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3098)] Disable creation of bridge perimeters ([juliocc](https://github.com/juliocc)) <!-- 2025-05-20 07:13:27+00:00 -->
- [[#3093](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3093)] Add support for additive perimeter resources to vpc-sc module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-19 09:05:06+00:00 -->
- [[#3090](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3090)] Relax WIF org policy in IaC project ([ludoo](https://github.com/ludoo)) <!-- 2025-05-16 07:31:22+00:00 -->
- [[#3089](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3089)] Fix permadiff in FAST bootstrap IAM ([ludoo](https://github.com/ludoo)) <!-- 2025-05-16 07:10:39+00:00 -->
- [[#3080](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3080)] Map secops group to security by default ([juliocc](https://github.com/juliocc)) <!-- 2025-05-12 11:16:46+00:00 -->
- [[#3062](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3062)] VPC SC module refactor ([juliocc](https://github.com/juliocc)) <!-- 2025-05-09 12:37:03+00:00 -->
- [[#3075](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3075)] Fix no VPC composer scenario and roles ([lcaggio](https://github.com/lcaggio)) <!-- 2025-05-09 08:49:45+00:00 -->
- [[#3070](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3070)] JSON schema documentation tool ([ludoo](https://github.com/ludoo)) <!-- 2025-05-06 06:17:47+00:00 -->
- [[#3066](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3066)] New FAST data platform ([ludoo](https://github.com/ludoo)) <!-- 2025-05-03 21:21:38+00:00 -->

### MODULES

- [[#3100](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3100)] Project Factory: fix reference to automation SAs in IAM block for service accounts ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-05-20 12:01:50+00:00 -->
- [[#3091](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3091)] Make automation project in project factory module optional ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-05-20 06:19:58+00:00 -->
- [[#3094](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3094)] Enable context replacements for IAM principals in project factory module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-19 11:57:26+00:00 -->
- [[#3093](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3093)] Add support for additive perimeter resources to vpc-sc module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-19 09:05:06+00:00 -->
- [[#3089](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3089)] Fix permadiff in FAST bootstrap IAM ([ludoo](https://github.com/ludoo)) <!-- 2025-05-16 07:10:39+00:00 -->
- [[#3062](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3062)] VPC SC module refactor ([juliocc](https://github.com/juliocc)) <!-- 2025-05-09 12:37:03+00:00 -->
- [[#3070](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3070)] JSON schema documentation tool ([ludoo](https://github.com/ludoo)) <!-- 2025-05-06 06:17:47+00:00 -->
- [[#3066](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3066)] New FAST data platform ([ludoo](https://github.com/ludoo)) <!-- 2025-05-03 21:21:38+00:00 -->
- [[#3051](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3051)] Add ability to reuse existing projects in project factory ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-04-21 08:57:53+00:00 -->

### TOOLS

- [[#3070](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3070)] JSON schema documentation tool ([ludoo](https://github.com/ludoo)) <!-- 2025-05-06 06:17:47+00:00 -->

## [39.2.0] - 2025-05-21

### FAST

- [[#3088](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3088)] Add GitLab SaaS support in fast/extras/0-cicd-gitlab ([Alhossril](https://github.com/Alhossril)) <!-- 2025-05-18 08:32:40+00:00 -->
- [[#2944](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2944)] fix: remove file starting by 1 and 2 to avoid copying 1-resman-provid… ([Alhossril](https://github.com/Alhossril)) <!-- 2025-05-18 07:14:29+00:00 -->

### MODULES

- [[#3103](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3103)] Added auto-provisioning-locations to gke-cluster-standard module ([apichick](https://github.com/apichick)) <!-- 2025-05-20 15:42:03+00:00 -->
- [[#3102](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3102)] feat: enables blue-green upgrades ([msikora-rtb](https://github.com/msikora-rtb)) <!-- 2025-05-20 14:43:04+00:00 -->
- [[#3101](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3101)] Backup enablement for CloudSQL instance should be only based on user provided settings ([apichick](https://github.com/apichick)) <!-- 2025-05-20 11:24:18+00:00 -->
- [[#3099](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3099)] Fix net vpc firewall module schema ([ludoo](https://github.com/ludoo)) <!-- 2025-05-20 08:59:35+00:00 -->
- [[#3096](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3096)] Enable multi-network GKE ([msikora-rtb](https://github.com/msikora-rtb)) <!-- 2025-05-19 16:43:59+00:00 -->
- [[#3092](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3092)] feat(gke): add kubelet_readonly_port_enabled ([6uellerBpanda](https://github.com/6uellerBpanda)) <!-- 2025-05-19 09:07:15+00:00 -->
- [[#3086](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3086)] bug: mark policy_controller as optional ([FalconerTC](https://github.com/FalconerTC)) <!-- 2025-05-15 16:16:13+00:00 -->
- [[#3077](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3077)] Add ability to optionally update Cloud Run job containers outside Terraform ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-05-10 13:36:34+00:00 -->
- [[#3061](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3061)] AlloyDB read poll support and various usability fixes ([viliampucik](https://github.com/viliampucik)) <!-- 2025-05-09 11:03:58+00:00 -->
- [[#3071](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3071)] [cloud-run-v2] Add ability to deploy OpenTelemetry Collector sidecar ([charles-salmon](https://github.com/charles-salmon)) <!-- 2025-05-08 09:05:59+00:00 -->
- [[#3073](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3073)] Added versions.tf to net-vpc-factory ([sruffilli](https://github.com/sruffilli)) <!-- 2025-05-08 08:40:45+00:00 -->

## [39.1.0] - 2025-05-05

### BLUEPRINTS

- [[#3068](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3068)] vertex-mlops: fix permadiff after apply ([wiktorn](https://github.com/wiktorn)) <!-- 2025-05-04 14:46:39+00:00 -->
- [[#3063](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3063)] Enable repd tag bindings in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-03 09:29:08+00:00 -->

### FAST

- [[#3063](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3063)] Enable repd tag bindings in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-03 09:29:08+00:00 -->
- [[#3052](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3052)] Updated network config variables in GKE node pool ([apichick](https://github.com/apichick)) <!-- 2025-04-21 18:44:40+00:00 -->
- [[#3050](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3050)] New Dataplex Aspect Types module ([ludoo](https://github.com/ludoo)) <!-- 2025-04-20 09:25:13+00:00 -->

### MODULES

- [[#3069](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3069)] [cloudsql-instance] Add cloudsql_iam_authentication flag to fix example in readme ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-05-05 06:50:32+00:00 -->
- [[#3067](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3067)] fix reference to boot disk in snapshots when using independent disks ([wiktorn](https://github.com/wiktorn)) <!-- 2025-05-03 12:21:38+00:00 -->
- [[#3063](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3063)] Enable repd tag bindings in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-03 09:29:08+00:00 -->
- [[#3060](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3060)] Add deletion_policy to project-factory module ([tyler-sommer](https://github.com/tyler-sommer)) <!-- 2025-04-30 16:10:12+00:00 -->
- [[#3059](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3059)] Better cert manager module examples ([ludoo](https://github.com/ludoo)) <!-- 2025-04-29 12:12:40+00:00 -->
- [[#3057](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3057)] [cloud-run-v2] Add ability to control code deployments outside Terraform ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-04-29 08:32:58+00:00 -->
- [[#3056](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3056)] Default vulnerability scanning to null in ar module ([ludoo](https://github.com/ludoo)) <!-- 2025-04-29 07:54:20+00:00 -->
- [[#3054](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3054)] New Managed Kafka module ([juliocc](https://github.com/juliocc)) <!-- 2025-04-24 06:52:03+00:00 -->
- [[#3053](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3053)] Rename Dataplex Aspects module to Dataplex Aspect Types ([ludoo](https://github.com/ludoo)) <!-- 2025-04-22 13:06:40+00:00 -->
- [[#3052](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3052)] Updated network config variables in GKE node pool ([apichick](https://github.com/apichick)) <!-- 2025-04-21 18:44:40+00:00 -->
- [[#3049](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3049)] [#3048] Fix serverless NEG example in net-lb-app-ext ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-04-20 19:17:16+00:00 -->
- [[#3050](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3050)] New Dataplex Aspect Types module ([ludoo](https://github.com/ludoo)) <!-- 2025-04-20 09:25:13+00:00 -->

### TOOLS

- [[#3063](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3063)] Enable repd tag bindings in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2025-05-03 09:29:08+00:00 -->

## [39.0.0] - 2025-04-18

### UPDATING FAST

- the `1-resman` stage has a new stage 2 definition for secops that depends on a previously not needed group; create the group or edit the groups variable in stage 0 and apply if you need the secops stage, delete the secops stage definition if you don't
- the `1-vpcsc` stage has a moved file to help you transition resources to a new internal naming scheme
- the `2-project-factory` stage is changing internal project keys following the changes to the underlying project factory module; you need to manually move (or re-import) all stage resources and tere's no sane way for us to provide you with pre-made move definitions; to buy time, you can change the source of the only module in the stage to point the previous version's `project-factory` module

### BREAKING CHANGES

- `fast/stages/2-project-factory`: project keys now contain the relative path prefix. [[#3030](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3030)]
- `modules/project-factory`: project keys now contain the relative path prefix. [[#3030](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3030)]
- `fast/stages/1-vpcsc`: the `perimeters` variable now matches the type of the variable `service_perimeters_regular` in `modules/vpc-sc`. To migrate, remove the `dry_run` field and use the `use_explicit_dry_run_spec`, `spec`, and `status` fields [[#2928](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2928)]

### BLUEPRINTS

- [[#3046](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3046)] Fix automation object names in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-04-18 13:42:45+00:00 -->
- [[#3022](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3022)] Replace all instances of stackdriver.googleapis.com with log+mon ([sruffilli](https://github.com/sruffilli)) <!-- 2025-04-11 12:04:50+00:00 -->

### FAST

- [[#3038](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3038)] 2-secops stage ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-04-18 13:57:29+00:00 -->
- [[#3046](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3046)] Fix automation object names in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-04-18 13:42:45+00:00 -->
- [[#3042](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3042)] Rename stage_config output/variables to stage_configs ([ludoo](https://github.com/ludoo)) <!-- 2025-04-16 09:34:01+00:00 -->
- [[#3036](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3036)] PF SA fix for budget alert ([karpok78](https://github.com/karpok78)) <!-- 2025-04-13 13:14:32+00:00 -->
- [[#3032](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3032)] Update CICD section of 0-bootstrap. Fixes #2930 ([sruffilli](https://github.com/sruffilli)) <!-- 2025-04-12 07:45:59+00:00 -->
- [[#3028](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3028)] add tag binding for stage folder config ([sepehrjavid](https://github.com/sepehrjavid)) <!-- 2025-04-11 15:34:47+00:00 -->
- [[#3026](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3026)] Add FAST to Python linting check ([ludoo](https://github.com/ludoo)) <!-- 2025-04-11 14:48:18+00:00 -->
- [[#3022](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3022)] Replace all instances of stackdriver.googleapis.com with log+mon ([sruffilli](https://github.com/sruffilli)) <!-- 2025-04-11 12:04:50+00:00 -->
- [[#3021](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3021)] Allow configuring dns zone names in FAST networking stages ([ludoo](https://github.com/ludoo)) <!-- 2025-04-09 16:53:20+00:00 -->
- [[#3017](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3017)] Restrict HMAC keys in FAST ([juliocc](https://github.com/juliocc)) <!-- 2025-04-08 13:43:26+00:00 -->
- [[#3015](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3015)] feat: Add Okta identity provider definition ([williamsmt](https://github.com/williamsmt)) <!-- 2025-04-08 12:48:07+00:00 -->
- [[#3014](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3014)] Properly support org policy tags in resman/project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-04-08 12:24:47+00:00 -->
- [[#3010](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3010)] Add trusted images projects ([wiktorn](https://github.com/wiktorn)) <!-- 2025-04-06 10:49:16+00:00 -->
- [[#3009](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3009)] Allow configuring base set of restricted services in vpc-sc stage ([ludoo](https://github.com/ludoo)) <!-- 2025-04-04 12:04:15+00:00 -->
- [[#3007](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3007)] Implement support for VPC-SC perimeter membership from project factory  ([ludoo](https://github.com/ludoo)) <!-- 2025-04-04 11:45:23+00:00 -->
- [[#3005](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3005)] Fix stage-3 CICD SA access ([c-jason-kim](https://github.com/c-jason-kim)) <!-- 2025-04-03 19:17:04+00:00 -->
- [[#2995](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2995)] Add requireInvokerIam constraint  ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-31 18:46:48+00:00 -->
- [[#2988](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2988)] Improve SecOps Anonymization pipeline ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-03-29 18:09:38+00:00 -->
- [[#2986](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2986)] Mongodb Atlas cluster project template ([ludoo](https://github.com/ludoo)) <!-- 2025-03-29 08:43:28+00:00 -->
- [[#2961](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2961)] Update FAST stage diagram ([ludoo](https://github.com/ludoo)) <!-- 2025-03-17 12:48:15+00:00 -->
- [[#2947](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2947)] Fix output in VPC-SC FAST stage ([ludoo](https://github.com/ludoo)) <!-- 2025-03-10 11:30:54+00:00 -->
- [[#2922](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2922)] Allow different principal types in bootstrap user variable ([dgourillon](https://github.com/dgourillon)) <!-- 2025-02-25 11:14:25+00:00 -->
- [[#2928](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2928)] Use VPC-SC perimeter factory in FAST 1-vpcsc stage ([juliocc](https://github.com/juliocc)) <!-- 2025-02-24 12:29:52+00:00 -->

### MODULES

- [[#3046](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3046)] Fix automation object names in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-04-18 13:42:45+00:00 -->
- [[#3030](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3030)] Use path as keys in project factory ([wiktorn](https://github.com/wiktorn)) <!-- 2025-04-11 20:30:39+00:00 -->
- [[#3027](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3027)] Apply recent changes to factory-projects-object.tf to vpc-factory ([wiktorn](https://github.com/wiktorn)) <!-- 2025-04-11 14:28:33+00:00 -->
- [[#3022](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3022)] Replace all instances of stackdriver.googleapis.com with log+mon ([sruffilli](https://github.com/sruffilli)) <!-- 2025-04-11 12:04:50+00:00 -->
- [[#3014](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3014)] Properly support org policy tags in resman/project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-04-08 12:24:47+00:00 -->
- [[#3007](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3007)] Implement support for VPC-SC perimeter membership from project factory  ([ludoo](https://github.com/ludoo)) <!-- 2025-04-04 11:45:23+00:00 -->
- [[#2990](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2990)] Merge master to fast dev ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-31 08:08:28+00:00 -->
- [[#2986](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2986)] Mongodb Atlas cluster project template ([ludoo](https://github.com/ludoo)) <!-- 2025-03-29 08:43:28+00:00 -->
- [[#2961](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2961)] Update FAST stage diagram ([ludoo](https://github.com/ludoo)) <!-- 2025-03-17 12:48:15+00:00 -->
- [[#2959](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2959)] Rationalize project factory context interpolations for automation service accounts ([ludoo](https://github.com/ludoo)) <!-- 2025-03-16 15:40:47+00:00 -->
- [[#2958](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2958)] Fix subnet schema in net-vpc module & hybrid subnets example implementation ([SamuPert](https://github.com/SamuPert)) <!-- 2025-03-15 17:29:45+00:00 -->
- [[#2929](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2929)] Expose tags in project factory ([juliocc](https://github.com/juliocc)) <!-- 2025-02-24 22:12:17+00:00 -->
- [[#2928](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2928)] Use VPC-SC perimeter factory in FAST 1-vpcsc stage ([juliocc](https://github.com/juliocc)) <!-- 2025-02-24 12:29:52+00:00 -->
- [[#2926](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2926)] Fix project ids in ingress policy resources ([juliocc](https://github.com/juliocc)) <!-- 2025-02-24 09:22:30+00:00 -->
- [[#2919](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2919)] Add perimeter factory to `modules/vpc-sc` ([karpok78](https://github.com/karpok78)) <!-- 2025-02-22 06:49:06+00:00 -->
- [[#2920](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2920)] Fix KMS service agent when universe is set ([dgourillon](https://github.com/dgourillon)) <!-- 2025-02-21 14:59:49+00:00 -->

### TOOLS

- [[#3038](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3038)] 2-secops stage ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-04-18 13:57:29+00:00 -->
- [[#3046](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3046)] Fix automation object names in project factory ([ludoo](https://github.com/ludoo)) <!-- 2025-04-18 13:42:45+00:00 -->
- [[#3026](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3026)] Add FAST to Python linting check ([ludoo](https://github.com/ludoo)) <!-- 2025-04-11 14:48:18+00:00 -->
- [[#2990](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2990)] Merge master to fast dev ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-31 08:08:28+00:00 -->
- [[#2986](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2986)] Mongodb Atlas cluster project template ([ludoo](https://github.com/ludoo)) <!-- 2025-03-29 08:43:28+00:00 -->

## [38.2.0] - 2025-04-18

### BREAKING CHANGES

- `modules/iam-service-account`: removed `public_keys_directory` variable. Use bare `google_service_account_key` resources if this functionality is needed. [[#3008](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3008)]
- `modules/gke-cluster-standard`, `modules/gke-cluster-autopilot`: Default value for `access_config.ip_access` changed from `{}` to `null`; explicitly set to keep IP access enabled. [[#2997](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2997)]

### BLUEPRINTS

- [[#3043](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3043)] Bump golang.org/x/net from 0.36.0 to 0.38.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/restarter ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2025-04-17 05:38:23+00:00 -->
- [[#2982](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2982)] Module: net-vpc-factory ([sruffilli](https://github.com/sruffilli)) <!-- 2025-04-10 09:44:40+00:00 -->
- [[#3008](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3008)] Add support to attach tags to service accounts ([juliocc](https://github.com/juliocc)) <!-- 2025-04-04 12:31:19+00:00 -->
- [[#2997](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2997)] Allow disabling GKE IP endpoints and setting GKE VPC scope DNS domain ([juliocc](https://github.com/juliocc)) <!-- 2025-04-02 07:03:58+00:00 -->
- [[#2989](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2989)] Fix Cloud SQL deployment and use local remote docker hub for pulling gitlab docker image ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-04-01 12:20:24+00:00 -->

### FAST

- [[#3033](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3033)] Pathexpand all factory data paths ([sruffilli](https://github.com/sruffilli)) <!-- 2025-04-16 11:28:10+00:00 -->
- [[#3035](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3035)] Add managed Kafka  ([franpinedab](https://github.com/franpinedab)) <!-- 2025-04-15 18:15:46+00:00 -->
- [[#3013](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3013)] SecOps Anonymization improvements ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-04-11 13:14:06+00:00 -->
- [[#3020](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3020)] [FAST] Remove object creator permission from storage viewer custom role ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-04-09 14:39:20+00:00 -->
- [[#3000](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3000)] Add roles support to VPC-SC ([juliocc](https://github.com/juliocc)) <!-- 2025-04-02 07:39:04+00:00 -->
- [[#2997](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2997)] Allow disabling GKE IP endpoints and setting GKE VPC scope DNS domain ([juliocc](https://github.com/juliocc)) <!-- 2025-04-02 07:03:58+00:00 -->

### MODULES

- [[#3033](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3033)] Pathexpand all factory data paths ([sruffilli](https://github.com/sruffilli)) <!-- 2025-04-16 11:28:10+00:00 -->
- [[#3040](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3040)] Add vulnerability scanning to artifact registry module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-04-14 16:33:35+00:00 -->
- [[#3034](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3034)] Added recipe HA VPN between AWS and GCP ([apichick](https://github.com/apichick)) <!-- 2025-04-14 10:47:21+00:00 -->
- [[#3031](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3031)] Use path as keys in project factory ([wiktorn](https://github.com/wiktorn)) <!-- 2025-04-11 20:50:50+00:00 -->
- [[#3029](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3029)] Allow IAP configuration with default IdP ([stribioli](https://github.com/stribioli)) <!-- 2025-04-11 16:19:17+00:00 -->
- [[#3023](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3023)] secops-rules module ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-04-11 13:44:31+00:00 -->
- [[#3024](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3024)] Use factory-projects-object to normalize inputs for project module in net-vpc-factory ([wiktorn](https://github.com/wiktorn)) <!-- 2025-04-11 08:53:08+00:00 -->
- [[#2982](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2982)] Module: net-vpc-factory ([sruffilli](https://github.com/sruffilli)) <!-- 2025-04-10 09:44:40+00:00 -->
- [[#2999](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2999)] Added variable for activating nat and implementation in google_apigee… ([jacklever-hub24](https://github.com/jacklever-hub24)) <!-- 2025-04-08 12:31:33+00:00 -->
- [[#2998](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2998)] Fix handling of data_overrides in project factory ([wiktorn](https://github.com/wiktorn)) <!-- 2025-04-06 18:17:22+00:00 -->
- [[#3008](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3008)] Add support to attach tags to service accounts ([juliocc](https://github.com/juliocc)) <!-- 2025-04-04 12:31:19+00:00 -->
- [[#3006](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3006)] Better lifecycle management description in VPC-SC module ([ludoo](https://github.com/ludoo)) <!-- 2025-04-04 07:06:26+00:00 -->
- [[#3004](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3004)] Add support for non-destructive tag bindings to compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2025-04-03 16:20:00+00:00 -->
- [[#3003](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3003)] Cross-project serverless neg example for internal app load balancer ([ludoo](https://github.com/ludoo)) <!-- 2025-04-03 08:53:48+00:00 -->
- [[#3000](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3000)] Add roles support to VPC-SC ([juliocc](https://github.com/juliocc)) <!-- 2025-04-02 07:39:04+00:00 -->
- [[#2997](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2997)] Allow disabling GKE IP endpoints and setting GKE VPC scope DNS domain ([juliocc](https://github.com/juliocc)) <!-- 2025-04-02 07:03:58+00:00 -->
- [[#2994](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2994)] Fr/timhiatt/invoker iam disable ([timbohiatt](https://github.com/timbohiatt)) <!-- 2025-04-01 09:41:08+00:00 -->
- [[#2993](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2993)] feat: add gcp_public_cidrs_access_enabled to gke modules ([domcyrus](https://github.com/domcyrus)) <!-- 2025-04-01 06:17:44+00:00 -->
- [[#2987](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2987)] Project object c14n in separate file ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-30 08:39:08+00:00 -->
- [[#2984](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2984)] compute-vm: Add graceful shutdown configuration and some missing GPUs. ([rosmo](https://github.com/rosmo)) <!-- 2025-03-26 12:51:54+00:00 -->

### TOOLS

- [[#3034](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3034)] Added recipe HA VPN between AWS and GCP ([apichick](https://github.com/apichick)) <!-- 2025-04-14 10:47:21+00:00 -->
- [[#3024](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/3024)] Use factory-projects-object to normalize inputs for project module in net-vpc-factory ([wiktorn](https://github.com/wiktorn)) <!-- 2025-04-11 08:53:08+00:00 -->
- [[#2997](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2997)] Allow disabling GKE IP endpoints and setting GKE VPC scope DNS domain ([juliocc](https://github.com/juliocc)) <!-- 2025-04-02 07:03:58+00:00 -->
- [[#2996](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2996)] Improve failure message for tests ([wiktorn](https://github.com/wiktorn)) <!-- 2025-04-01 08:40:32+00:00 -->
- [[#2987](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2987)] Project object c14n in separate file ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-30 08:39:08+00:00 -->

## [38.1.0] - 2025-03-22

### BREAKING CHANGES

- `modules/cloud-function-v2`: Make function compatible with direct egress settings - allow to specify function egress settings without using a VPC connector. [[#2967](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2967)]
- `modules/dns`: Reverse zones are by default created as unmanaged now. To keep your zone as managed, please set `var.zone_config.private.reverse_managed` to `true` [[#2942](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2942)]

### BLUEPRINTS

- [[#2971](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2971)] Bump google.golang.org/grpc from 1.53.0 to 1.56.3 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/healthchecker ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2025-03-19 11:51:08+00:00 -->
- [[#2970](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2970)] Bump google.golang.org/protobuf from 1.28.1 to 1.33.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/healthchecker ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2025-03-19 11:37:12+00:00 -->
- [[#2969](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2969)] Bump golang.org/x/net from 0.33.0 to 0.36.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/healthchecker ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2025-03-19 11:23:21+00:00 -->
- [[#2966](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2966)] Add custom routes for directpath to net-vpc module ([ludoo](https://github.com/ludoo)) <!-- 2025-03-19 10:22:48+00:00 -->
- [[#2965](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2965)] Revert "Fix broken upgrades of TF provider for routes" ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-18 10:06:46+00:00 -->
- [[#2964](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2964)] Fix broken upgrades of TF provider for routes ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-18 08:41:57+00:00 -->
- [[#2953](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2953)] Bump golang.org/x/net from 0.33.0 to 0.36.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/restarter ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2025-03-13 08:22:45+00:00 -->
- [[#2936](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2936)] Fix broken link in GCP Data Services blueprints ([javiergp](https://github.com/javiergp)) <!-- 2025-03-03 09:01:41+00:00 -->

### FAST

- [[#2967](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2967)] Allow to specify function egress settings without using a VPC connector ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-03-19 10:38:33+00:00 -->
- [[#2941](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2941)] Fast 2-networking-a README update ([sruffilli](https://github.com/sruffilli)) <!-- 2025-03-05 06:56:00+00:00 -->
- [[#2938](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2938)] Fix localfile project factory readme ([Alhossril](https://github.com/Alhossril)) <!-- 2025-03-04 08:06:27+00:00 -->
- [[#2927](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2927)] fix(bootstrap): fix custom roles billing viewer duplicate permissions ([Ameausoone](https://github.com/Ameausoone)) <!-- 2025-02-24 11:52:31+00:00 -->
- [[#2924](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2924)] Add limits for stage_names and environment ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-23 17:33:32+00:00 -->
- [[#2923](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2923)] Fix CICD SA access ([c-jason-kim](https://github.com/c-jason-kim)) <!-- 2025-02-23 07:04:10+00:00 -->
- [[#2918](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2918)] Bump requests from 2.27.1 to 2.32.2 in /fast/project-templates/secops-anonymization-pipeline/source ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2025-02-21 09:03:12+00:00 -->

### MODULES

- [[#2981](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2981)] Add dependency on VPC-SC resources to project factory ([LFicteam](https://github.com/LFicteam)) <!-- 2025-03-21 22:20:36+00:00 -->
- [[#2974](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2974)] Fix push subscription in pubsub module ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-03-20 19:22:43+00:00 -->
- [[#2973](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2973)] Add support for any ports to net-lb-app modules ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-20 10:28:17+00:00 -->
- [[#2968](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2968)] Add transparent proxy example and e2e test to net-swp module ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-19 11:00:21+00:00 -->
- [[#2967](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2967)] Allow to specify function egress settings without using a VPC connector ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-03-19 10:38:33+00:00 -->
- [[#2966](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2966)] Add custom routes for directpath to net-vpc module ([ludoo](https://github.com/ludoo)) <!-- 2025-03-19 10:22:48+00:00 -->
- [[#2965](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2965)] Revert "Fix broken upgrades of TF provider for routes" ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-18 10:06:46+00:00 -->
- [[#2964](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2964)] Fix broken upgrades of TF provider for routes ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-18 08:41:57+00:00 -->
- [[#2962](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2962)] Adding enterprise_config -> desired_tier feature to GKE autopilot and… ([fpreli](https://github.com/fpreli)) <!-- 2025-03-17 16:41:48+00:00 -->
- [[#2960](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2960)] cloudsql: Align replica attributes to primary instance ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-17 10:46:01+00:00 -->
- [[#2956](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2956)] Update GKE addons and features ([juliocc](https://github.com/juliocc)) <!-- 2025-03-14 19:07:16+00:00 -->
- [[#2952](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2952)] feat(artifact-registry): Add possibility to setup Docker common remote repository configuration ([anthonyhaussman](https://github.com/anthonyhaussman)) <!-- 2025-03-13 12:30:35+00:00 -->
- [[#2949](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2949)] `net-vpc`: fix permadiff in docs ([sruffilli](https://github.com/sruffilli)) <!-- 2025-03-12 09:09:08+00:00 -->
- [[#2948](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2948)] Use full type definition in project-factory ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-10 14:34:13+00:00 -->
- [[#2942](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2942)] **incompatible change:** Allow un-managed reverse lookup zones ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-06 07:28:51+00:00 -->
- [[#2935](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2935)] Introduce test isolation and fix missing GCS service account ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-01 13:45:16+00:00 -->
- [[#2933](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2933)] Fix failing E2E test for module/project ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-28 17:45:14+00:00 -->
- [[#2931](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2931)] Fixed title: from Artifact Registry to Binary Authorization ([ggalloro](https://github.com/ggalloro)) <!-- 2025-02-26 11:18:10+00:00 -->
- [[#2925](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2925)] Fix E2E tests using modules/project project_create ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-23 17:19:29+00:00 -->
- [[#2921](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2921)] Add execution/invocation commands to outputs ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-21 16:53:42+00:00 -->

### TOOLS

- [[#2965](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2965)] Revert "Fix broken upgrades of TF provider for routes" ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-18 10:06:46+00:00 -->
- [[#2964](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2964)] Fix broken upgrades of TF provider for routes ([wiktorn](https://github.com/wiktorn)) <!-- 2025-03-18 08:41:57+00:00 -->

## [38.0.0] - 2025-02-21

### BREAKING CHANGES

- `modules/vpc-sc`: Referencing ingress/egress policies that are not defined results in an error (previously, undefined directional policies were silently ignored) [[#2909](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2909)]
- `modules/project-factory`: The `automation.buckets` attribute has been changed to `automation.bucket` and support for multiple state buckets has been dropped. Save your state to a local file for any automation-enabled project before applying changes in the project factory. [[#2914](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2914)]
- `modules/project`: move input variable `service_agents_config.services_enabled` to `project_reuse.project_attributes.services_enabled` [[#2900](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2900)]
- fast/stages/0-boostrap: enabled restrictProtocolForwardingCreationForTypes to internal only by default [[#2884](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2884)]
- fast/stages/0-boostrap/data/org-policies-managed: new set of org policies using managed constraints [[#2884](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2884)]
- fast/stages/0-boostrap: if you use `var.org_policies_config.constraints.allowed_policy_member_domains` or `var.org_policies_config.constraints.allowed_policy_member_domains`, move their values to a YAML file under bootstrap's org policy factory. [[#2878](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2878)]

### BLUEPRINTS

- [[#2909](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2909)] Add title to VPC-SC directional policies ([juliocc](https://github.com/juliocc)) <!-- 2025-02-20 08:48:09+00:00 -->
- [[#2794](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2794)] New SecOps anonymization pipeline ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-02-17 18:23:20+00:00 -->
- [[#2899](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2899)] Project factory additions, project module reuse implementation ([ludoo](https://github.com/ludoo)) <!-- 2025-02-15 19:37:46+00:00 -->
- [[#2894](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2894)] Make service agents work in different universes ([juliocc](https://github.com/juliocc)) <!-- 2025-02-14 12:16:07+00:00 -->

### FAST

- [[#2909](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2909)] Add title to VPC-SC directional policies ([juliocc](https://github.com/juliocc)) <!-- 2025-02-20 08:48:09+00:00 -->
- [[#2914](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2914)] **incompatible change:** Add provider output files to project factory stage, single automation bucket in module ([ludoo](https://github.com/ludoo)) <!-- 2025-02-19 17:45:56+00:00 -->
- [[#2906](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2906)] Update default FAST org policies ([juliocc](https://github.com/juliocc)) <!-- 2025-02-18 15:34:44+00:00 -->
- [[#2904](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2904)] Fix default compute.restrictProtocolForwardingCreationForTypes value ([juliocc](https://github.com/juliocc)) <!-- 2025-02-18 13:28:33+00:00 -->
- [[#2902](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2902)] Allow passing explicit regions in net test addon subnets ([ludoo](https://github.com/ludoo)) <!-- 2025-02-18 09:26:39+00:00 -->
- [[#2794](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2794)] New SecOps anonymization pipeline ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-02-17 18:23:20+00:00 -->
- [[#2899](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2899)] Project factory additions, project module reuse implementation ([ludoo](https://github.com/ludoo)) <!-- 2025-02-15 19:37:46+00:00 -->
- [[#2897](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2897)] FAST project templates example ([ludoo](https://github.com/ludoo)) <!-- 2025-02-14 19:14:27+00:00 -->
- [[#2893](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2893)] Add support for project-level log sinks to FAST stage 0 ([ludoo](https://github.com/ludoo)) <!-- 2025-02-14 10:58:18+00:00 -->
- [[#2887](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2887)] Update VPC-SC module and FAST stage ([juliocc](https://github.com/juliocc)) <!-- 2025-02-13 18:04:09+00:00 -->
- [[#2891](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2891)] Address DNS issues with googleapis RPZ and forwarding ([ludoo](https://github.com/ludoo)) <!-- 2025-02-13 16:08:28+00:00 -->
- [[#2888](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2888)] Add restrictProtocolForwardingCreationForTypes to FAST import policies ([juliocc](https://github.com/juliocc)) <!-- 2025-02-13 13:00:26+00:00 -->
- [[#2884](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2884)] Add new set of org policies with managed constraints to FAST bootstrap ([juliocc](https://github.com/juliocc)) <!-- 2025-02-12 19:38:44+00:00 -->
- [[#2878](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2878)] Move DRS and essential contact domains to factory ([juliocc](https://github.com/juliocc)) <!-- 2025-02-11 16:36:17+00:00 -->
- [[#2875](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2875)] New FAST stages diagram ([ludoo](https://github.com/ludoo)) <!-- 2025-02-10 13:39:28+00:00 -->
- [[#2872](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2872)] Add bucket IAM policy read ([karpok78](https://github.com/karpok78)) <!-- 2025-02-09 23:55:55+00:00 -->
- [[#2864](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2864)] Workflow fix ([karpok78](https://github.com/karpok78)) <!-- 2025-02-03 15:31:59+00:00 -->
- [[#2854](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2854)] Expose custom constraint factory in bootstrap ([juliocc](https://github.com/juliocc)) <!-- 2025-01-31 06:03:29+00:00 -->
- [[#2853](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2853)] Allow addons to any flex stage 2 ([juliocc](https://github.com/juliocc)) <!-- 2025-01-30 18:04:28+00:00 -->
- [[#2851](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2851)] Support mulitple universes in bootstrap  ([juliocc](https://github.com/juliocc)) <!-- 2025-01-30 11:35:57+00:00 -->
- [[#2840](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2840)] Flexible stage 2s in FAST resource manager ([ludoo](https://github.com/ludoo)) <!-- 2025-01-29 12:16:36+00:00 -->

### MODULES

- [[#2917](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2917)] Add error messages for failing interpolations ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-21 08:20:44+00:00 -->
- [[#2909](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2909)] Add title to VPC-SC directional policies ([juliocc](https://github.com/juliocc)) <!-- 2025-02-20 08:48:09+00:00 -->
- [[#2914](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2914)] **incompatible change:** Add provider output files to project factory stage, single automation bucket in module ([ludoo](https://github.com/ludoo)) <!-- 2025-02-19 17:45:56+00:00 -->
- [[#2900](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2900)] **incompatible change:** Add ability to refer to other project service accounts in Project Factory ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-19 15:47:15+00:00 -->
- [[#2906](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2906)] Update default FAST org policies ([juliocc](https://github.com/juliocc)) <!-- 2025-02-18 15:34:44+00:00 -->
- [[#2899](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2899)] Project factory additions, project module reuse implementation ([ludoo](https://github.com/ludoo)) <!-- 2025-02-15 19:37:46+00:00 -->
- [[#2897](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2897)] FAST project templates example ([ludoo](https://github.com/ludoo)) <!-- 2025-02-14 19:14:27+00:00 -->
- [[#2894](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2894)] Make service agents work in different universes ([juliocc](https://github.com/juliocc)) <!-- 2025-02-14 12:16:07+00:00 -->
- [[#2893](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2893)] Add support for project-level log sinks to FAST stage 0 ([ludoo](https://github.com/ludoo)) <!-- 2025-02-14 10:58:18+00:00 -->
- [[#2892](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2892)] Add universe support to iam-service-account ([juliocc](https://github.com/juliocc)) <!-- 2025-02-14 08:06:23+00:00 -->
- [[#2887](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2887)] Update VPC-SC module and FAST stage ([juliocc](https://github.com/juliocc)) <!-- 2025-02-13 18:04:09+00:00 -->

### TOOLS

- [[#2909](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2909)] Add title to VPC-SC directional policies ([juliocc](https://github.com/juliocc)) <!-- 2025-02-20 08:48:09+00:00 -->
- [[#2900](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2900)] Add ability to refer to other project service accounts in Project Factory ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-19 15:47:15+00:00 -->
- [[#2794](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2794)] New SecOps anonymization pipeline ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-02-17 18:23:20+00:00 -->
- [[#2899](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2899)] Project factory additions, project module reuse implementation ([ludoo](https://github.com/ludoo)) <!-- 2025-02-15 19:37:46+00:00 -->
- [[#2894](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2894)] Make service agents work in different universes ([juliocc](https://github.com/juliocc)) <!-- 2025-02-14 12:16:07+00:00 -->

## [37.4.0] - 2025-02-21

### BREAKING CHANGES

- `modules/workstation-cluster`: changed the interface for configuration timeouts to object, timeouts are now specified as numbers. [[#2911](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2911)]
- `modules/cloudsql-instance`: changed the name of the `var.ssl.ssl_mode` attribute to `var.ssl.mode`. [[#2910](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2910)]
- `modules/iam-service-account`: Removed service account key generation functionality [[#2907](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2907)]
- `modules/net-lb-app-ext`: Adds the two missing fields for locality_lb_policy and locality_lb_policies with field and block set, validation for both and tests. [[#2898](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2898)]

### BLUEPRINTS

- [[#2907](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2907)] Remove Service Account key generation ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-18 17:02:39+00:00 -->

### MODULES

- [[#2916](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2916)] Add support for custom error response policies to net_lb_app_ext module ([peter-norton](https://github.com/peter-norton)) <!-- 2025-02-20 19:32:24+00:00 -->
- [[#2915](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2915)] Fix dns_keys output in dns module ([nathou](https://github.com/nathou)) <!-- 2025-02-20 09:56:58+00:00 -->
- [[#2913](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2913)] Add generated_id backends output to net-lb-app-ext ([danistrebel](https://github.com/danistrebel)) <!-- 2025-02-19 17:16:06+00:00 -->
- [[#2911](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2911)] **incompatible change:** Add support for max workstations, refactor timeouts in workstation-cluster module ([ludoo](https://github.com/ludoo)) <!-- 2025-02-19 09:45:38+00:00 -->
- [[#2910](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2910)] **incompatible change:** Add ssl_mode support to cloudsql-instance replicas ([sruffilli](https://github.com/sruffilli)) <!-- 2025-02-19 09:31:36+00:00 -->
- [[#2907](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2907)] **incompatible change:** Remove Service Account key generation ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-18 17:02:39+00:00 -->
- [[#2886](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2886)] Increase the default complexity of Cloud SQL DB passwords ([lyricnz](https://github.com/lyricnz)) <!-- 2025-02-18 10:46:29+00:00 -->
- [[#2901](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2901)] Add CA chain output to CAS module ([ludoo](https://github.com/ludoo)) <!-- 2025-02-18 07:05:29+00:00 -->
- [[#2898](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2898)] Add support for locality policies to net-lb-app-ext module ([jacklever-hub24](https://github.com/jacklever-hub24)) <!-- 2025-02-18 06:25:45+00:00 -->

### TOOLS

- [[#2908](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2908)] Add breaking changes to changelog ([juliocc](https://github.com/juliocc)) <!-- 2025-02-18 18:09:13+00:00 -->

## [37.3.0] - 2025-02-12

### BLUEPRINTS

- [[#2883](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2883)] **incompatible change:** Fix ipv6 and align loadbalancer address types ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-12 13:09:31+00:00 -->

### MODULES

- [[#2883](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2883)] **incompatible change:** Fix ipv6 and align loadbalancer address types ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-12 13:09:31+00:00 -->

## [37.2.0] - 2025-02-11

### BLUEPRINTS

- [[#2879](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2879)] Address outstanding load balancer FRs ([ludoo](https://github.com/ludoo)) <!-- 2025-02-11 17:09:02+00:00 -->
- [[#2869](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2869)] Expose org policy parameters ([juliocc](https://github.com/juliocc)) <!-- 2025-02-07 09:55:06+00:00 -->
- [[#2863](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2863)] Deprecate composer-2 blueprint ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-03 10:27:15+00:00 -->
- [[#2841](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2841)] Add cAdvisor Metrics to Autopilot/Standard GKE Cluster ([HeiglAnna](https://github.com/HeiglAnna)) <!-- 2025-01-30 13:29:07+00:00 -->

### FAST

- [[#2874](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2874)] Add note about the use of n-stagename/moved/ files during upgrade ([lyricnz](https://github.com/lyricnz)) <!-- 2025-02-10 07:34:37+00:00 -->
- [[#2862](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2862)] update docs: clarify 0-bootstrap.auto.tfvars creation and outputs_loc… ([ZoranBatman](https://github.com/ZoranBatman)) <!-- 2025-02-03 15:44:47+00:00 -->

### MODULES

- [[#2879](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2879)] Address outstanding load balancer FRs ([ludoo](https://github.com/ludoo)) <!-- 2025-02-11 17:09:02+00:00 -->
- [[#2876](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2876)] Add context to organization policy factories ([juliocc](https://github.com/juliocc)) <!-- 2025-02-10 22:24:02+00:00 -->
- [[#2871](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2871)] Fix KMS E2E tests ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-09 23:56:20+00:00 -->
- [[#2870](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2870)] Add dependency for compute-vm schedule ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-07 11:02:40+00:00 -->
- [[#2869](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2869)] Expose org policy parameters ([juliocc](https://github.com/juliocc)) <!-- 2025-02-07 09:55:06+00:00 -->
- [[#2867](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2867)] Disable E2E test for direct VPC Egress ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-05 08:56:04+00:00 -->
- [[#2855](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2855)] Add support for advanced machine features to compute-vm ([ludoo](https://github.com/ludoo)) <!-- 2025-01-31 09:27:29+00:00 -->
- [[#2841](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2841)] Add cAdvisor Metrics to Autopilot/Standard GKE Cluster ([HeiglAnna](https://github.com/HeiglAnna)) <!-- 2025-01-30 13:29:07+00:00 -->
- [[#2852](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2852)] Allow universe-bound projects to exclude services ([juliocc](https://github.com/juliocc)) <!-- 2025-01-30 07:48:58+00:00 -->
- [[#2848](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2848)] Support project creation in different universes ([juliocc](https://github.com/juliocc)) <!-- 2025-01-29 11:40:41+00:00 -->
- [[#2842](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2842)] Refactor data catalog tag template module ([ludoo](https://github.com/ludoo)) <!-- 2025-01-28 09:30:42+00:00 -->

### TOOLS

- [[#2871](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2871)] Fix KMS E2E tests ([wiktorn](https://github.com/wiktorn)) <!-- 2025-02-09 23:56:20+00:00 -->
- [[#2869](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2869)] Expose org policy parameters ([juliocc](https://github.com/juliocc)) <!-- 2025-02-07 09:55:06+00:00 -->

## [37.1.0] - 2025-01-26

### FAST

- [[#2839](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2839)] Revert "Allow multiple stage-2 project factories" ([ludoo](https://github.com/ludoo)) <!-- 2025-01-26 09:37:43+00:00 -->

## [37.0.0] - 2025-01-24

### FAST

- [[#2836](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2836)] Interpolate SAs in tag-level iam ([juliocc](https://github.com/juliocc)) <!-- 2025-01-24 09:39:03+00:00 -->
- [[#2834](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2834)] **incompatible change:** Allow multiple stage-2 project factories ([juliocc](https://github.com/juliocc)) <!-- 2025-01-23 23:38:22+00:00 -->
- [[#2831](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2831)] Allow networking stage to be disabled ([juliocc](https://github.com/juliocc)) <!-- 2025-01-22 06:45:23+00:00 -->
- [[#2828](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2828)] Small fix to net test add-on context expansion ([ludoo](https://github.com/ludoo)) <!-- 2025-01-21 10:14:43+00:00 -->
- [[#2826](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2826)] Fix stage 1 addons provider outputs ([juliocc](https://github.com/juliocc)) <!-- 2025-01-21 06:55:40+00:00 -->
- [[#2825](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2825)] FAST add-on for networking test resources ([ludoo](https://github.com/ludoo)) <!-- 2025-01-20 08:41:35+00:00 -->
- [[#2823](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2823)] Update service activation in ngfw add-on ([ludoo](https://github.com/ludoo)) <!-- 2025-01-18 13:23:23+00:00 -->
- [[#2821](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2821)] FAST SWP networking add-on, refactor CAS module interface ([ludoo](https://github.com/ludoo)) <!-- 2025-01-18 07:12:41+00:00 -->
- [[#2818](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2818)] Top level folder factory support for automation SA IAM ([sruffilli](https://github.com/sruffilli)) <!-- 2025-01-16 09:33:00+00:00 -->
- [[#2817](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2817)] Fix permadiff in stage 0 vpc-sc service account, add schemas to hierarchical policy YAML files ([ludoo](https://github.com/ludoo)) <!-- 2025-01-15 09:47:04+00:00 -->
- [[#2815](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2815)] [FAST] Add missing permission to ngfwEnterprise org ([LucaPrete](https://github.com/LucaPrete)) <!-- 2025-01-14 08:40:58+00:00 -->
- [[#2813](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2813)] feat: restructure how var files are provided to workflow templates ([Liam-Johnston](https://github.com/Liam-Johnston)) <!-- 2025-01-14 06:29:38+00:00 -->
- [[#2810](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2810)] Small fixes and improvements to FAST netsec/net ([ludoo](https://github.com/ludoo)) <!-- 2025-01-11 12:48:45+00:00 -->
- [[#2800](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2800)] Implement FAST stage add-ons, refactor netsec as add-on ([ludoo](https://github.com/ludoo)) <!-- 2025-01-09 18:14:12+00:00 -->
- [[#2801](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2801)] Add optional support for fw policies via new vpc_configs variable, refactor factories variable in net stages ([ludoo](https://github.com/ludoo)) <!-- 2025-01-09 16:14:56+00:00 -->
- [[#2787](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2787)] Leverage environments for folder and project creation in FAST resman and security ([ludoo](https://github.com/ludoo)) <!-- 2024-12-27 20:03:31+00:00 -->

### MODULES

- [[#2821](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2821)] **incompatible change:** FAST SWP networking add-on, refactor CAS module interface ([ludoo](https://github.com/ludoo)) <!-- 2025-01-18 07:12:41+00:00 -->
- [[#2820](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2820)] **incompatible change:** Do not create service agent resources in project module for services not explicitly enabled ([ludoo](https://github.com/ludoo)) <!-- 2025-01-17 15:55:41+00:00 -->

## [36.2.0] - 2025-01-24

### BLUEPRINTS

- [[#2837](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2837)] Update module metadata format and prep v36.2.0 ([juliocc](https://github.com/juliocc)) <!-- 2025-01-24 15:45:17+00:00 -->
- [[#2827](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2827)] Add `bucket_create` to `modules/gcs` ([juliocc](https://github.com/juliocc)) <!-- 2025-01-21 22:48:36+00:00 -->
- [[#2816](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2816)] Update `logging_data_access` type ([juliocc](https://github.com/juliocc)) <!-- 2025-01-14 16:00:35+00:00 -->

### FAST

- [[#2831](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2831)] Allow networking stage to be disabled ([juliocc](https://github.com/juliocc)) <!-- 2025-01-22 06:45:23+00:00 -->
- [[#2828](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2828)] Small fix to net test add-on context expansion ([ludoo](https://github.com/ludoo)) <!-- 2025-01-21 10:14:43+00:00 -->
- [[#2826](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2826)] Fix stage 1 addons provider outputs ([juliocc](https://github.com/juliocc)) <!-- 2025-01-21 06:55:40+00:00 -->
- [[#2825](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2825)] FAST add-on for networking test resources ([ludoo](https://github.com/ludoo)) <!-- 2025-01-20 08:41:35+00:00 -->
- [[#2823](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2823)] Update service activation in ngfw add-on ([ludoo](https://github.com/ludoo)) <!-- 2025-01-18 13:23:23+00:00 -->

## [36.1.0] - 2025-01-10

- [[#2777](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2777)] Document `tag_bindings` definition as `map(string)` ([juliocc](https://github.com/juliocc)) <!-- 2024-12-19 13:47:32+00:00 -->

### BLUEPRINTS

- [[#2808](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2808)] Bump golang.org/x/net from 0.23.0 to 0.33.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/healthchecker ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2025-01-10 15:48:39+00:00 -->
- [[#2807](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2807)] Bump golang.org/x/net from 0.23.0 to 0.33.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/restarter ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2025-01-09 14:02:26+00:00 -->
- [[#2803](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2803)] New tool `versions.py` to manage versions.tf/tofu  ([juliocc](https://github.com/juliocc)) <!-- 2025-01-09 08:57:49+00:00 -->
- [[#2796](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2796)] Add docker image tag to bindplane config variable ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2025-01-03 15:52:51+00:00 -->
- [[#2792](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2792)] fix non-empty plan after apply for vertex mlops ([wiktorn](https://github.com/wiktorn)) <!-- 2024-12-31 16:27:47+00:00 -->
- [[#2791](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2791)] Fabric e2e fixes ([juliocc](https://github.com/juliocc)) <!-- 2024-12-31 14:25:36+00:00 -->
- [[#2790](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2790)] Fix cycle in the autopilot-cluster blueprint ([wiktorn](https://github.com/wiktorn)) <!-- 2024-12-29 19:30:59+00:00 -->
- [[#2721](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2721)] New BindPlane OP Management console on GKE SecOps blueprint ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-12-17 21:16:40+00:00 -->
- [[#2771](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2771)] Use separate versions.tofu for OpenTofu constraints ([wiktorn](https://github.com/wiktorn)) <!-- 2024-12-17 11:29:04+00:00 -->
- [[#2768](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2768)] Support customizable resource names in FAST stage 0 ([ludoo](https://github.com/ludoo)) <!-- 2024-12-16 16:46:34+00:00 -->
- [[#2761](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2761)] Refactor GKE cluster modules access configurations, add support for DNS endpoint ([ludoo](https://github.com/ludoo)) <!-- 2024-12-12 10:02:24+00:00 -->
- [[#2736](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2736)] Add confidential compute support to google_dataproc_cluster module, bump provider versions ([steenblik](https://github.com/steenblik)) <!-- 2024-12-10 15:39:48+00:00 -->
- [[#2752](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2752)] Bump path-to-regexp and express in /blueprints/apigee/apigee-x-foundations/functions/instance-monitor ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-12-08 09:34:19+00:00 -->
- [[#2748](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2748)] Add ability to autogenerate md5 keys in net-vpn-ha ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-12-06 07:34:56+00:00 -->
- [[#2749](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2749)] Bump path-to-regexp and express in /blueprints/gke/binauthz/image ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-12-06 05:54:12+00:00 -->
- [[#2745](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2745)] Add optional automated MD5 generation to net-vlan-attachment module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-12-05 16:55:16+00:00 -->

### FAST

- [[#2798](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2798)] ADR proposal for FAST add-on stages ([ludoo](https://github.com/ludoo)) <!-- 2025-01-05 15:02:47+00:00 -->
- [[#2774](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2774)] [FAST] Remove unused stage 1 CICD variables ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-12-17 16:26:02+00:00 -->
- [[#2769](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2769)] Support customizable resource names to fast stage 1 ([ludoo](https://github.com/ludoo)) <!-- 2024-12-16 18:07:28+00:00 -->
- [[#2768](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2768)] Support customizable resource names in FAST stage 0 ([ludoo](https://github.com/ludoo)) <!-- 2024-12-16 16:46:34+00:00 -->
- [[#2767](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2767)] Fix workspace logs sink in FAST bootstrap stage ([ludoo](https://github.com/ludoo)) <!-- 2024-12-13 13:22:42+00:00 -->
- [[#2766](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2766)] Allow optional creation of billing resources in FAST boostrap stage ([ludoo](https://github.com/ludoo)) <!-- 2024-12-13 11:32:17+00:00 -->
- [[#2761](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2761)] **incompatible change:** Refactor GKE cluster modules access configurations, add support for DNS endpoint ([ludoo](https://github.com/ludoo)) <!-- 2024-12-12 10:02:24+00:00 -->
- [[#2744](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2744)] Fix parent id lookup for networking and security in resource management stage ([ludoo](https://github.com/ludoo)) <!-- 2024-12-04 20:08:31+00:00 -->
- [[#2733](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2733)] **incompatible change:** Updating yaml naming in prod subnet folder to match other lifecycles ([mtndrew404](https://github.com/mtndrew404)) <!-- 2024-11-26 06:40:22+00:00 -->

### MODULES

- [[#2799](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2799)] Add intercepting sinks to the organization and folder modules ([rshokati2](https://github.com/rshokati2)) <!-- 2025-01-10 10:36:08+00:00 -->
- [[#2806](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2806)] ASN should be optional in router_config variable as it is not necessa… ([apichick](https://github.com/apichick)) <!-- 2025-01-09 14:46:43+00:00 -->
- [[#2803](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2803)] New tool `versions.py` to manage versions.tf/tofu  ([juliocc](https://github.com/juliocc)) <!-- 2025-01-09 08:57:49+00:00 -->
- [[#2802](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2802)] Added BGP priority variable for dedicated interconnect because it was… ([apichick](https://github.com/apichick)) <!-- 2025-01-07 17:07:55+00:00 -->
- [[#2758](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2758)] Add Alerts, Logging, Channels Factories ([joshw123](https://github.com/joshw123)) <!-- 2025-01-05 19:49:21+00:00 -->
- [[#2791](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2791)] Fabric e2e fixes ([juliocc](https://github.com/juliocc)) <!-- 2024-12-31 14:25:36+00:00 -->
- [[#2786](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2786)] Make PSA connection more robust ([wiktorn](https://github.com/wiktorn)) <!-- 2024-12-26 15:37:25+00:00 -->
- [[#2784](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2784)] Fix validation message in cas module ([ludoo](https://github.com/ludoo)) <!-- 2024-12-25 07:25:07+00:00 -->
- [[#2783](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2783)] Update net-lb-app-ext security_settings variables ([wenzizone](https://github.com/wenzizone)) <!-- 2024-12-25 06:52:31+00:00 -->
- [[#2781](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2781)] Fix bindplane cos module ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-12-23 09:37:09+00:00 -->
- [[#2780](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2780)] Fix handling of SSL certificates in external load balancer modules ([rodriguezsergio](https://github.com/rodriguezsergio)) <!-- 2024-12-21 10:26:29+00:00 -->
- [[#2776](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2776)] Add support for log views and log scopes ([juliocc](https://github.com/juliocc)) <!-- 2024-12-18 17:29:45+00:00 -->
- [[#2772](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2772)] Fix for perma-diff when using PSC NEGs. ([wiktorn](https://github.com/wiktorn)) <!-- 2024-12-17 13:28:48+00:00 -->
- [[#2771](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2771)] Use separate versions.tofu for OpenTofu constraints ([wiktorn](https://github.com/wiktorn)) <!-- 2024-12-17 11:29:04+00:00 -->
- [[#2768](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2768)] Support customizable resource names in FAST stage 0 ([ludoo](https://github.com/ludoo)) <!-- 2024-12-16 16:46:34+00:00 -->
- [[#2761](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2761)] **incompatible change:** Refactor GKE cluster modules access configurations, add support for DNS endpoint ([ludoo](https://github.com/ludoo)) <!-- 2024-12-12 10:02:24+00:00 -->
- [[#2764](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2764)] Ignore ssl certificates if none are passed in net-lb-app-int module ([ludoo](https://github.com/ludoo)) <!-- 2024-12-12 09:37:37+00:00 -->
- [[#2757](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2757)] Update net-vlan-attachment module readme ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-12-11 08:00:28+00:00 -->
- [[#2736](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2736)] Add confidential compute support to google_dataproc_cluster module, bump provider versions ([steenblik](https://github.com/steenblik)) <!-- 2024-12-10 15:39:48+00:00 -->
- [[#2740](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2740)] Add support for password validation policy to cloudsql module ([ludoo](https://github.com/ludoo)) <!-- 2024-12-09 09:44:15+00:00 -->
- [[#2750](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2750)] Add disk encyption key to the google_compute_instance_template - Sovereign support ([rune92](https://github.com/rune92)) <!-- 2024-12-09 09:30:58+00:00 -->
- [[#2718](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2718)] Add path_template_match and path_template_rewrite support to net-lb-app-ext  ([rosmo](https://github.com/rosmo)) <!-- 2024-12-09 08:32:48+00:00 -->
- [[#2755](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2755)] remove default location in tag value - cloud-run-v2 tags.tf ([Mattible](https://github.com/Mattible)) <!-- 2024-12-09 07:48:23+00:00 -->
- [[#2751](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2751)] Add support for routing mode to net-swp module ([ludoo](https://github.com/ludoo)) <!-- 2024-12-08 13:26:02+00:00 -->
- [[#2748](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2748)] Add ability to autogenerate md5 keys in net-vpn-ha ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-12-06 07:34:56+00:00 -->
- [[#2745](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2745)] Add optional automated MD5 generation to net-vlan-attachment module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-12-05 16:55:16+00:00 -->
- [[#2741](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2741)] Add support for secret manager config to gke cluster modules ([ludoo](https://github.com/ludoo)) <!-- 2024-11-29 08:24:18+00:00 -->
- [[#2734](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2734)] Allow override of GKE Nodepool SA Display Name ([robrankin](https://github.com/robrankin)) <!-- 2024-11-28 06:47:17+00:00 -->
- [[#2738](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2738)] Support switchover in alloydb module ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-11-27 15:57:33+00:00 -->
- [[#2739](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2739)] Add basename to SWP policy rules factory ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-11-27 14:42:33+00:00 -->
- [[#2737](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2737)] **incompatible change:** SWP module refactor ([ludoo](https://github.com/ludoo)) <!-- 2024-11-27 12:54:59+00:00 -->

### TOOLS

- [[#2803](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2803)] New tool `versions.py` to manage versions.tf/tofu  ([juliocc](https://github.com/juliocc)) <!-- 2025-01-09 08:57:49+00:00 -->
- [[#2791](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2791)] Fabric e2e fixes ([juliocc](https://github.com/juliocc)) <!-- 2024-12-31 14:25:36+00:00 -->
- [[#2778](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2778)] Fix failing tests for OpenTofu ([wiktorn](https://github.com/wiktorn)) <!-- 2024-12-20 09:19:01+00:00 -->
- [[#2721](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2721)] New BindPlane OP Management console on GKE SecOps blueprint ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-12-17 21:16:40+00:00 -->
- [[#2771](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2771)] Use separate versions.tofu for OpenTofu constraints ([wiktorn](https://github.com/wiktorn)) <!-- 2024-12-17 11:29:04+00:00 -->
- [[#2769](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2769)] Support customizable resource names to fast stage 1 ([ludoo](https://github.com/ludoo)) <!-- 2024-12-16 18:07:28+00:00 -->
- [[#2768](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2768)] Support customizable resource names in FAST stage 0 ([ludoo](https://github.com/ludoo)) <!-- 2024-12-16 16:46:34+00:00 -->
- [[#2765](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2765)] Update issue templates ([juliocc](https://github.com/juliocc)) <!-- 2024-12-12 12:40:47+00:00 -->
- [[#2736](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2736)] Add confidential compute support to google_dataproc_cluster module, bump provider versions ([steenblik](https://github.com/steenblik)) <!-- 2024-12-10 15:39:48+00:00 -->

## [36.0.1] - 2024-11-23

### FAST

- [[#2731](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2731)] Add missing role to FAST stage 0 org-level delegated IAM grants ([ludoo](https://github.com/ludoo)) <!-- 2024-11-23 06:58:13+00:00 -->

### TOOLS

- [[#2730](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2730)] Run tests and linting when pushing to master or fast-dev ([juliocc](https://github.com/juliocc)) <!-- 2024-11-22 19:21:38+00:00 -->

## [36.0.0] - 2024-11-22

### BLUEPRINTS

- [[#2648](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2648)] Refactor of FAST resource management and subsequent stages ([ludoo](https://github.com/ludoo)) <!-- 2024-10-31 15:55:55+00:00 -->

### FAST

- [[#2714](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2714)] Remove stale resman validation ([juliocc](https://github.com/juliocc)) <!-- 2024-11-18 16:00:06+00:00 -->
- [[#2707](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2707)] Expose `factories_config` for resman top level folders ([juliocc](https://github.com/juliocc)) <!-- 2024-11-17 22:54:56+00:00 -->
- [[#2701](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2701)] Allow disabling network security stage ([juliocc](https://github.com/juliocc)) <!-- 2024-11-17 09:04:18+00:00 -->
- [[#2697](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2697)] Remove REGIONAL/MULTI_REGIONAL buckets from FAST ([juliocc](https://github.com/juliocc)) <!-- 2024-11-16 10:14:47+00:00 -->
- [[#2693](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2693)] Unify usage of top level folders short_name ([juliocc](https://github.com/juliocc)) <!-- 2024-11-15 12:56:46+00:00 -->
- [[#2694](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2694)] Make project iam viewer name consistent with GCP naming ([juliocc](https://github.com/juliocc)) <!-- 2024-11-15 10:48:37+00:00 -->
- [[#2688](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2688)] Streamline environments variable across stages ([ludoo](https://github.com/ludoo)) <!-- 2024-11-15 09:22:18+00:00 -->
- [[#2685](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2685)] Add missing billing roles to project factory ro SA in stage 1 ([ludoo](https://github.com/ludoo)) <!-- 2024-11-14 10:41:30+00:00 -->
- [[#2683](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2683)] Add missing roles to project factory ro SA in stage 1 ([ludoo](https://github.com/ludoo)) <!-- 2024-11-14 09:25:51+00:00 -->
- [[#2656](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2656)] Fix permadiff in bootstrap IAM ([ludoo](https://github.com/ludoo)) <!-- 2024-11-01 14:56:07+00:00 -->
- [[#2652](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2652)] Final fixes for v36.0.0-rc1 ([ludoo](https://github.com/ludoo)) <!-- 2024-10-31 16:47:11+00:00 -->
- [[#2648](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2648)] **incompatible change:** Refactor of FAST resource management and subsequent stages ([ludoo](https://github.com/ludoo)) <!-- 2024-10-31 15:55:55+00:00 -->

### MODULES

- [[#2648](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2648)] Refactor of FAST resource management and subsequent stages ([ludoo](https://github.com/ludoo)) <!-- 2024-10-31 15:55:55+00:00 -->

### TOOLS

- [[#2688](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2688)] Streamline environments variable across stages ([ludoo](https://github.com/ludoo)) <!-- 2024-11-15 09:22:18+00:00 -->
- [[#2660](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2660)] Refactor changelog for the new release process ([ludoo](https://github.com/ludoo)) <!-- 2024-11-11 10:59:45+00:00 -->
- [[#2648](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2648)] Refactor of FAST resource management and subsequent stages ([ludoo](https://github.com/ludoo)) <!-- 2024-10-31 15:55:55+00:00 -->

## [35.1.0] - 2024-11-22

### BLUEPRINTS

- [[#2706](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2706)] Added min_instances, max_instances, min_throughput and max_throughtpu… ([apichick](https://github.com/apichick)) <!-- 2024-11-21 08:05:12+00:00 -->
- [[#2712](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2712)] Add hierarchical namespace support to GCS module ([juliocc](https://github.com/juliocc)) <!-- 2024-11-18 11:41:49+00:00 -->
- [[#2705](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2705)] Added outputs to apigee-x-foundations blueprint (PSC NEGs) ([apichick](https://github.com/apichick)) <!-- 2024-11-18 07:36:49+00:00 -->
- [[#2704](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2704)] Added outputs to apigee-x-foundations blueprint (instances and lbs) ([apichick](https://github.com/apichick)) <!-- 2024-11-17 16:28:30+00:00 -->
- [[#2514](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2514)] New SecOps blueprints section and SecOps GKE Forwarder ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-11-05 13:41:37+00:00 -->
- [[#2658](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2658)] Update service agents spec ([juliocc](https://github.com/juliocc)) <!-- 2024-11-05 11:10:23+00:00 -->
- [[#2659](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2659)] Fix Vertex MLOps blueprint  ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-05 10:22:43+00:00 -->
- [[#2632](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2632)] Migrate blueprints/data-solutions/vertex-mlops to google_workbench_instance ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-04 09:34:54+00:00 -->
- [[#2631](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2631)] fix Vertex-ML-Ops e2e tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-04 09:13:33+00:00 -->

### FAST

- [[#2715](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2715)] Allow setting GCS location default/override in project factory ([ludoo](https://github.com/ludoo)) <!-- 2024-11-18 16:45:52+00:00 -->
- [[#2640](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2640)] Add Automation Service Accounts Output ([joshw123](https://github.com/joshw123)) <!-- 2024-11-17 17:29:06+00:00 -->
- [[#2681](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2681)] Keeping my contributor status :) ([drebes](https://github.com/drebes)) <!-- 2024-11-13 20:28:44+00:00 -->
- [[#2680](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2680)] Swap groups_iam/iam_group for iam_by_principals in bootstrap README ([robrankin](https://github.com/robrankin)) <!-- 2024-11-13 15:33:41+00:00 -->

### MODULES

- [[#2726](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2726)] enable_private_path_for_google_cloud_services added to CloudSQL ([fulyagonultas](https://github.com/fulyagonultas)) <!-- 2024-11-22 13:08:34+00:00 -->
- [[#2727](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2727)] Fix typo on maintenance config ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-11-22 09:35:45+00:00 -->
- [[#2706](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2706)] Added min_instances, max_instances, min_throughput and max_throughtpu… ([apichick](https://github.com/apichick)) <!-- 2024-11-21 08:05:12+00:00 -->
- [[#2719](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2719)] Allow factory files to be empty ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-11-21 07:41:24+00:00 -->
- [[#2723](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2723)] Fix not setting user defined password ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-20 09:55:00+00:00 -->
- [[#2716](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2716)] Add support for workload_metadata_config in Standard GKE clusters ([Tirthankar17](https://github.com/Tirthankar17)) <!-- 2024-11-20 09:36:10+00:00 -->
- [[#2720](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2720)] Add location to cert-manager issuance config and fix issuance config reference ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-11-19 12:27:11+00:00 -->
- [[#2715](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2715)] Allow setting GCS location default/override in project factory ([ludoo](https://github.com/ludoo)) <!-- 2024-11-18 16:45:52+00:00 -->
- [[#2689](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2689)] add GPU options to compute-vm module ([ooshrioo](https://github.com/ooshrioo)) <!-- 2024-11-18 15:40:38+00:00 -->
- [[#2712](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2712)] Add hierarchical namespace support to GCS module ([juliocc](https://github.com/juliocc)) <!-- 2024-11-18 11:41:49+00:00 -->
- [[#2711](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2711)] Allow providing network for Direct VPC access ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-18 09:25:20+00:00 -->
- [[#2640](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2640)] Add Automation Service Accounts Output ([joshw123](https://github.com/joshw123)) <!-- 2024-11-17 17:29:06+00:00 -->
- [[#2702](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2702)] Move direct vpc out of BETA ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-16 11:52:50+00:00 -->
- [[#2700](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2700)] Fix non-empty plan after mixing CloudSQL with other mounts ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-16 10:55:37+00:00 -->
- [[#2699](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2699)] Fix E2E tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-16 10:02:16+00:00 -->
- [[#2692](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2692)] Fix examples for GCS mount ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-15 08:58:01+00:00 -->
- [[#2687](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2687)] Fix initial user on secondary cluster issue ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-11-14 21:20:38+00:00 -->
- [[#2686](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2686)] Fix gcs & NFS mounts for cloud-run-v2 service ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-14 12:33:21+00:00 -->
- [[#2682](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2682)] Add support for service account in pubsub module bigquery subscriptions ([ludoo](https://github.com/ludoo)) <!-- 2024-11-14 11:05:37+00:00 -->
- [[#2676](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2676)] Fix "inconsistent conditional result types" error in `modules/vpc-sc` ([joelvoss](https://github.com/joelvoss)) <!-- 2024-11-12 09:27:51+00:00 -->
- [[#2673](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2673)] bump modules/README github tag reference ([kaue](https://github.com/kaue)) <!-- 2024-11-11 18:13:12+00:00 -->
- [[#2670](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2670)] Fix the location of the GCS and NFS attributes ([wintermi](https://github.com/wintermi)) <!-- 2024-11-11 09:01:16+00:00 -->
- [[#2669](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2669)] Additional examples for Cloud Run and Cloud SQL ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-10 06:02:30+00:00 -->
- [[#2668](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2668)] SWP: remove condition from `addresses` variable and make it null by default ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-11-09 21:50:47+00:00 -->
- [[#2666](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2666)] Update SWP ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-11-09 12:54:13+00:00 -->
- [[#2657](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2657)] add enable_object_retention argument ([kejti23](https://github.com/kejti23)) <!-- 2024-11-05 16:27:29+00:00 -->
- [[#2658](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2658)] Update service agents spec ([juliocc](https://github.com/juliocc)) <!-- 2024-11-05 11:10:23+00:00 -->
- [[#2632](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2632)] Migrate blueprints/data-solutions/vertex-mlops to google_workbench_instance ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-04 09:34:54+00:00 -->
- [[#2631](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2631)] fix Vertex-ML-Ops e2e tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-11-04 09:13:33+00:00 -->
- [[#2653](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2653)] Add required enabled field introduced in Terraform version 5.41.0 ([jacobmammoliti](https://github.com/jacobmammoliti)) <!-- 2024-11-01 07:01:14+00:00 -->

## [35.0.0] - 2024-10-30
<!-- None < 2024-09-05 10:07:19+00:00 -->

### BLUEPRINTS

- [[#2643](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2643)] Add codespell to pre-commit  ([wiktorn](https://github.com/wiktorn)) <!-- 2024-10-30 09:30:37+00:00 -->
- [[#2629](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2629)] Bump cookie and express in /blueprints/apigee/apigee-x-foundations/functions/instance-monitor ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-10-17 07:11:45+00:00 -->
- [[#2623](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2623)] Bump cookie and express in /blueprints/gke/binauthz/image ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-10-15 14:05:52+00:00 -->
- [[#2609](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2609)] Add support for bundling net monitoring tool in a Docker image, and deploying via CR Job ([ludoo](https://github.com/ludoo)) <!-- 2024-10-07 12:56:09+00:00 -->
- [[#2585](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2585)] Apigee x foundations certificate manager ([apichick](https://github.com/apichick)) <!-- 2024-09-24 06:49:36+00:00 -->
- [[#2584](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2584)] README fixes to FAST docs ([skalolazka](https://github.com/skalolazka)) <!-- 2024-09-19 13:23:40+00:00 -->
- [[#2574](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2574)] Bump path-to-regexp and express in /blueprints/apigee/apigee-x-foundations/functions/instance-monitor ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-09-18 08:21:22+00:00 -->
- [[#2573](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2573)] Bump path-to-regexp and express in /blueprints/gke/binauthz/image ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-09-18 08:09:06+00:00 -->
- [[#2536](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2536)] **incompatible change:** Add support for google provider 6.x ([sruffilli](https://github.com/sruffilli)) <!-- 2024-09-05 10:35:59+00:00 -->

### FAST

- [[#2649](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2649)] Clarify fast-dev purpose ([juliocc](https://github.com/juliocc)) <!-- 2024-10-30 14:08:04+00:00 -->
- [[#2643](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2643)] Add codespell to pre-commit  ([wiktorn](https://github.com/wiktorn)) <!-- 2024-10-30 09:30:37+00:00 -->
- [[#2641](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2641)] Adding DNS for GKE control plane to private google access APIs ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2024-10-29 13:09:26+00:00 -->
- [[#2630](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2630)] [FAST] Fix stage 2 simple NVA wrong location - causing test failures ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-10-18 12:43:03+00:00 -->
- [[#2611](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2611)] Add TFE integration for backend and CICD ([lnesteroff](https://github.com/lnesteroff)) <!-- 2024-10-16 06:01:39+00:00 -->
- [[#2620](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2620)] added output for tfvars_globals ([lnesteroff](https://github.com/lnesteroff)) <!-- 2024-10-15 07:39:09+00:00 -->
- [[#2544](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2544)] GCVE network mode for 2-networking-b-nva  stage ([eliamaldini](https://github.com/eliamaldini)) <!-- 2024-10-15 06:28:15+00:00 -->
- [[#2616](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2616)] Support log exclusions in FAST bootstrap log sinks ([ludoo](https://github.com/ludoo)) <!-- 2024-10-09 07:22:28+00:00 -->
- [[#2604](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2604)] fixed tfe wif definition variables ([lnesteroff](https://github.com/lnesteroff)) <!-- 2024-10-03 13:41:31+00:00 -->
- [[#2600](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2600)] FAST: Adds support for PSC transitivity to 2-a ([sruffilli](https://github.com/sruffilli)) <!-- 2024-10-02 09:39:24+00:00 -->
- [[#2598](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2598)] added terraform enterprise/hcp terraform def to wif providers ([lnesteroff](https://github.com/lnesteroff)) <!-- 2024-10-01 23:12:49+00:00 -->
- [[#2584](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2584)] README fixes to FAST docs ([skalolazka](https://github.com/skalolazka)) <!-- 2024-09-19 13:23:40+00:00 -->
- [[#2582](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2582)] Make it explicit in FAST docs that stages need to be run once before CI/CD setup ([ludoo](https://github.com/ludoo)) <!-- 2024-09-19 07:43:36+00:00 -->
- [[#2581](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2581)] Update FAST stage diagrams ([ludoo](https://github.com/ludoo)) <!-- 2024-09-19 07:39:35+00:00 -->
- [[#2579](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2579)] FAST resman mt fixes ([ludoo](https://github.com/ludoo)) <!-- 2024-09-19 07:02:04+00:00 -->
- [[#2568](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2568)] Update a few references from 3-project-factory to 2-project-factory ([lyricnz](https://github.com/lyricnz)) <!-- 2024-09-19 05:11:32+00:00 -->
- [[#2558](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2558)] Update variables.tf ([eliamaldini](https://github.com/eliamaldini)) <!-- 2024-09-16 08:28:22+00:00 -->
- [[#2564](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2564)] Enables compute.setNewProjectDefaultToZonalDNSOnly and essentialcontacts.allowedContactDomains ([sruffilli](https://github.com/sruffilli)) <!-- 2024-09-13 09:09:55+00:00 -->
- [[#2563](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2563)] Update list of imported org policies ([sruffilli](https://github.com/sruffilli)) <!-- 2024-09-13 07:05:01+00:00 -->

### MODULES

- [[#2642](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2642)] Reorganize ADRs and new versioning ADR ([juliocc](https://github.com/juliocc)) <!-- 2024-10-30 11:39:53+00:00 -->
- [[#2643](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2643)] Add codespell to pre-commit  ([wiktorn](https://github.com/wiktorn)) <!-- 2024-10-30 09:30:37+00:00 -->
- [[#2645](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2645)] feat(modules/secret-manager): add support for version_destroy_ttl ([frits-v](https://github.com/frits-v)) <!-- 2024-10-30 08:54:31+00:00 -->
- [[#2639](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2639)] **incompatible change:** Add option to attach multiple snapshot schedule to disks ([shujaatsscripts](https://github.com/shujaatsscripts)) <!-- 2024-10-28 17:53:43+00:00 -->
- [[#2638](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2638)] Fix ipv6 output in net-vpc module, add support for extra volumes in cloud run v2 module ([ludoo](https://github.com/ludoo)) <!-- 2024-10-24 06:36:21+00:00 -->
- [[#2625](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2625)] Add Project Factory Logging Data Option ([joshw123](https://github.com/joshw123)) <!-- 2024-10-17 10:54:42+00:00 -->
- [[#2617](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2617)] fix(artifact-registry): fix a move issue with tf>1.7 ([NitriKx](https://github.com/NitriKx)) <!-- 2024-10-11 09:41:06+00:00 -->
- [[#2608](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2608)] Additional job attributes in cloud run v2 module ([ludoo](https://github.com/ludoo)) <!-- 2024-10-07 09:45:59+00:00 -->
- [[#2599](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2599)] **incompatible change:** Alloydb variables refactor ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-10-06 09:49:16+00:00 -->
- [[#2606](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2606)] feat: implement the new iam interface in `artifact-registry` ([NitriKx](https://github.com/NitriKx)) <!-- 2024-10-04 13:49:48+00:00 -->
- [[#2595](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2595)] Allow manage existing SSM instance ([lnesteroff](https://github.com/lnesteroff)) <!-- 2024-09-27 10:13:30+00:00 -->
- [[#2572](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2572)] Added biglake-catalog module ([apichick](https://github.com/apichick)) <!-- 2024-09-24 15:39:29+00:00 -->
- [[#2593](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2593)] Fix looker README and add custom url for looker instance module ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-09-23 09:12:24+00:00 -->
- [[#2590](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2590)] Fix permadiff on iap attribute in net-lb-app-int module ([eliamaldini](https://github.com/eliamaldini)) <!-- 2024-09-20 11:35:18+00:00 -->
- [[#2565](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2565)] New looker core module ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-09-20 10:12:09+00:00 -->
- [[#2587](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2587)] Project Module CMEK: added CloudRun ([artemBogdantsev](https://github.com/artemBogdantsev)) <!-- 2024-09-20 08:30:06+00:00 -->
- [[#2586](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2586)] Add location for each SSM IAM resource ([lnesteroff](https://github.com/lnesteroff)) <!-- 2024-09-20 07:30:46+00:00 -->
- [[#2569](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2569)] Secure source manager ([apichick](https://github.com/apichick)) <!-- 2024-09-19 10:29:01+00:00 -->
- [[#2570](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2570)] Bigquery dataset routines ([apichick](https://github.com/apichick)) <!-- 2024-09-19 09:13:32+00:00 -->
- [[#2583](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2583)] **incompatible change:** Support secret-level expire time in secret manager module ([ludoo](https://github.com/ludoo)) <!-- 2024-09-19 08:35:44+00:00 -->
- [[#2559](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2559)] Fix e2e tests for cloud run ([wiktorn](https://github.com/wiktorn)) <!-- 2024-09-10 10:04:40+00:00 -->
- [[#2536](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2536)] **incompatible change:** Add support for google provider 6.x ([sruffilli](https://github.com/sruffilli)) <!-- 2024-09-05 10:35:59+00:00 -->

### TOOLS

- [[#2536](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2536)] **incompatible change:** Add support for google provider 6.x ([sruffilli](https://github.com/sruffilli)) <!-- 2024-09-05 10:35:59+00:00 -->

## [34.1.0] - 2024-09-05
<!-- 2024-09-05 10:07:19+00:00 < 2024-08-30 08:18:13+00:00 -->

### BLUEPRINTS

- [[#2557](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2557)] Bump provider to 5.43.1 ahead of next release ([juliocc](https://github.com/juliocc)) <!-- 2024-09-04 17:58:07+00:00 -->

### FAST

- [[#2545](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2545)] Add documentation instructions for potential issues in cicd-github and bootstrap stages ([ludoo](https://github.com/ludoo)) <!-- 2024-08-30 12:04:44+00:00 -->

### MODULES

- [[#2557](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2557)] Bump provider to 5.43.1 ahead of next release ([juliocc](https://github.com/juliocc)) <!-- 2024-09-04 17:58:07+00:00 -->
- [[#2556](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2556)] Updated the auto pilot gke security posture configuration ([oluakingcp](https://github.com/oluakingcp)) <!-- 2024-09-04 13:53:07+00:00 -->
- [[#2553](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2553)] Added the GKE security_posture configuration ([oluakingcp](https://github.com/oluakingcp)) <!-- 2024-09-04 13:29:18+00:00 -->
- [[#2546](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2546)] Full examples for CMEK examples ([wiktorn](https://github.com/wiktorn)) <!-- 2024-09-04 10:16:50+00:00 -->

### TOOLS

- [[#2557](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2557)] Bump provider to 5.43.1 ahead of next release ([juliocc](https://github.com/juliocc)) <!-- 2024-09-04 17:58:07+00:00 -->
- [[#2552](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2552)] Upload hidden files ([wiktorn](https://github.com/wiktorn)) <!-- 2024-09-03 15:18:21+00:00 -->

## [34.0.0] - 2024-08-30
<!-- 2024-08-30 08:18:13+00:00 < 2024-08-01 11:45:37+00:00 -->

### BLUEPRINTS

- [[#2543](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2543)] Prepare v34.0.0 release ([ludoo](https://github.com/ludoo)) <!-- 2024-08-30 08:06:33+00:00 -->
- [[#2542](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2542)] Use generic project name in HA VPN over IC blueprint ([juliocc](https://github.com/juliocc)) <!-- 2024-08-30 07:32:21+00:00 -->
- [[#2530](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2530)] Add managed folders support to `gcs` module ([juliocc](https://github.com/juliocc)) <!-- 2024-08-28 07:30:53+00:00 -->
- [[#2531](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2531)] Update stable provider too to 5.43 ([juliocc](https://github.com/juliocc)) <!-- 2024-08-28 06:49:46+00:00 -->
- [[#2525](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2525)] Bump provider to last release of version 5 ([juliocc](https://github.com/juliocc)) <!-- 2024-08-27 14:50:59+00:00 -->
- [[#2502](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2502)] Add `deletion_policy` to project module ([juliocc](https://github.com/juliocc)) <!-- 2024-08-16 16:33:39+00:00 -->
- [[#2469](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2469)] Fix  E2E tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-08-06 09:49:30+00:00 -->
- [[#2463](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2463)] Typo in README: well know -> well-known ([derailed-dash](https://github.com/derailed-dash)) <!-- 2024-08-03 07:54:55+00:00 -->

### FAST

- [[#2543](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2543)] Prepare v34.0.0 release ([ludoo](https://github.com/ludoo)) <!-- 2024-08-30 08:06:33+00:00 -->
- [[#2541](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2541)] Moved blocks and fix to resman for FAST v33-v34 transition ([ludoo](https://github.com/ludoo)) <!-- 2024-08-30 07:44:27+00:00 -->
- [[#2484](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2484)] [FAST] TLS inspection support for NGFW Enterprise ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-08-30 07:15:17+00:00 -->
- [[#2530](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2530)] Add managed folders support to `gcs` module ([juliocc](https://github.com/juliocc)) <!-- 2024-08-28 07:30:53+00:00 -->
- [[#2511](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2511)] [FAST] Add permissions to nsec-r SA ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-08-21 18:26:32+00:00 -->
- [[#2509](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2509)] Depend network security stage from fast features in FAST resman stage ([ludoo](https://github.com/ludoo)) <!-- 2024-08-21 06:38:43+00:00 -->
- [[#2505](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2505)] **incompatible change:** Refactor FAST project factory and supporting documentation ([ludoo](https://github.com/ludoo)) <!-- 2024-08-20 16:45:42+00:00 -->
- [[#2499](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2499)] Firewall policy module factory schema ([ludoo](https://github.com/ludoo)) <!-- 2024-08-11 08:12:03+00:00 -->
- [[#2498](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2498)] DNS rpz module factory schema ([ludoo](https://github.com/ludoo)) <!-- 2024-08-10 15:19:28+00:00 -->
- [[#2497](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2497)] Net vpc firewall factory schema ([ludoo](https://github.com/ludoo)) <!-- 2024-08-10 13:04:50+00:00 -->
- [[#2494](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2494)] Additional module schemas ([ludoo](https://github.com/ludoo)) <!-- 2024-08-09 13:58:06+00:00 -->
- [[#2491](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2491)] Organization module factory schemas ([ludoo](https://github.com/ludoo)) <!-- 2024-08-09 10:22:57+00:00 -->
- [[#2483](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2483)] Add bootstrap output with log destination ids ([juliocc](https://github.com/juliocc)) <!-- 2024-08-08 14:23:38+00:00 -->
- [[#2482](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2482)] [FAST] Rename netsec stage to nsec ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-08-08 12:30:09+00:00 -->
- [[#2477](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2477)] VPC-SC factory JSON Schemas ([ludoo](https://github.com/ludoo)) <!-- 2024-08-07 12:09:38+00:00 -->
- [[#2471](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2471)] Rename 1-vpc-sc stage to 1-vpcsc ([juliocc](https://github.com/juliocc)) <!-- 2024-08-06 11:21:55+00:00 -->
- [[#2470](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2470)] Make policyReader binding additive in bootstrap ([juliocc](https://github.com/juliocc)) <!-- 2024-08-06 09:35:38+00:00 -->
- [[#2466](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2466)] [FAST] Sets projects_data_path optional, as in the project factory module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-08-06 06:27:34+00:00 -->
- [[#2464](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2464)] Fix peering routes config in fast a network stage ([ludoo](https://github.com/ludoo)) <!-- 2024-08-03 20:18:45+00:00 -->
- [[#2460](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2460)] **incompatible change:** VPC-SC as separate FAST stage 1 ([ludoo](https://github.com/ludoo)) <!-- 2024-08-02 16:04:36+00:00 -->

### MODULES

- [[#2543](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2543)] Prepare v34.0.0 release ([ludoo](https://github.com/ludoo)) <!-- 2024-08-30 08:06:33+00:00 -->
- [[#2538](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2538)] Module net-vpc fix for reserved ranges ([jamesdalf](https://github.com/jamesdalf)) <!-- 2024-08-30 05:10:28+00:00 -->
- [[#2539](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2539)] Exposing aws_v4_authentication configuration in global external alb ([okguru1](https://github.com/okguru1)) <!-- 2024-08-29 13:45:50+00:00 -->
- [[#2537](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2537)] Add send_secondary_ip_range_if_empty=true to google_compute_subnetwork ([sruffilli](https://github.com/sruffilli)) <!-- 2024-08-28 14:00:09+00:00 -->
- [[#2533](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2533)] Added the possibility of setting the duration of a GCE instance. ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2024-08-28 09:36:45+00:00 -->
- [[#2535](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2535)] Allow customizable prefix in net-vpc module PSA configs ([ludoo](https://github.com/ludoo)) <!-- 2024-08-28 09:24:13+00:00 -->
- [[#2528](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2528)] Support budget restriction read only ([kejti23](https://github.com/kejti23)) <!-- 2024-08-28 09:08:14+00:00 -->
- [[#2530](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2530)] Add managed folders support to `gcs` module ([juliocc](https://github.com/juliocc)) <!-- 2024-08-28 07:30:53+00:00 -->
- [[#2531](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2531)] Update stable provider too to 5.43 ([juliocc](https://github.com/juliocc)) <!-- 2024-08-28 06:49:46+00:00 -->
- [[#2525](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2525)] Bump provider to last release of version 5 ([juliocc](https://github.com/juliocc)) <!-- 2024-08-27 14:50:59+00:00 -->
- [[#2523](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2523)] feat: Add security_policy to backend service configuration ([EmileHofsink](https://github.com/EmileHofsink)) <!-- 2024-08-27 12:19:14+00:00 -->
- [[#2521](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2521)] net-vpc module add overlap CIDR subnet attribute ([jamesdalf](https://github.com/jamesdalf)) <!-- 2024-08-26 19:48:26+00:00 -->
- [[#2518](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2518)] Fix CMEK typo in project module. Part 2 :) ([artemBogdantsev](https://github.com/artemBogdantsev)) <!-- 2024-08-23 17:16:17+00:00 -->
- [[#2517](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2517)] Fix CMEK typo in project module  ([artemBogdantsev](https://github.com/artemBogdantsev)) <!-- 2024-08-23 16:39:21+00:00 -->
- [[#2516](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2516)] Key inconsistency in project-factory ([V0idC0de](https://github.com/V0idC0de)) <!-- 2024-08-23 15:47:51+00:00 -->
- [[#2515](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2515)] Add ca pool object to certification-authority-service module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-08-23 09:43:01+00:00 -->
- [[#2508](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2508)] Add support for disable default snat ([okguru1](https://github.com/okguru1)) <!-- 2024-08-21 09:43:28+00:00 -->
- [[#2510](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2510)] net-swp module cleanup ([sruffilli](https://github.com/sruffilli)) <!-- 2024-08-21 09:28:20+00:00 -->
- [[#2505](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2505)] **incompatible change:** Refactor FAST project factory and supporting documentation ([ludoo](https://github.com/ludoo)) <!-- 2024-08-20 16:45:42+00:00 -->
- [[#2501](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2501)] Use the `google_tags_location_tag_binding` Terraform resource to bind tags on KMS key rings ([arnodasilva](https://github.com/arnodasilva)) <!-- 2024-08-20 05:43:18+00:00 -->
- [[#2502](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2502)] Add `deletion_policy` to project module ([juliocc](https://github.com/juliocc)) <!-- 2024-08-16 16:33:39+00:00 -->
- [[#2420](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2420)] Add name overrides for Internal and External Load Balancers ([cvanwijck-hub24](https://github.com/cvanwijck-hub24)) <!-- 2024-08-16 06:45:30+00:00 -->
- [[#2499](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2499)] Firewall policy module factory schema ([ludoo](https://github.com/ludoo)) <!-- 2024-08-11 08:12:03+00:00 -->
- [[#2498](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2498)] DNS rpz module factory schema ([ludoo](https://github.com/ludoo)) <!-- 2024-08-10 15:19:28+00:00 -->
- [[#2497](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2497)] Net vpc firewall factory schema ([ludoo](https://github.com/ludoo)) <!-- 2024-08-10 13:04:50+00:00 -->
- [[#2496](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2496)] [fix] certificate authority service returning bad pool id ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-08-09 16:20:53+00:00 -->
- [[#2493](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2493)] [fix] Fixes errors in certificate-authority-service module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-08-09 14:58:53+00:00 -->
- [[#2495](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2495)] ensure dns_keys output freshness ([nathou](https://github.com/nathou)) <!-- 2024-08-09 14:33:55+00:00 -->
- [[#2494](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2494)] Additional module schemas ([ludoo](https://github.com/ludoo)) <!-- 2024-08-09 13:58:06+00:00 -->
- [[#2491](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2491)] Organization module factory schemas ([ludoo](https://github.com/ludoo)) <!-- 2024-08-09 10:22:57+00:00 -->
- [[#2490](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2490)] Bind schemas to factory files, add support for groups in VPC-SC schema ([wiktorn](https://github.com/wiktorn)) <!-- 2024-08-09 10:08:22+00:00 -->
- [[#2489](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2489)] Extend test collector to include yaml files under tests/schemas/ and fast data files ([juliocc](https://github.com/juliocc)) <!-- 2024-08-09 08:59:00+00:00 -->
- [[#2486](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2486)] Fix failing tests for CloudSQL ([wiktorn](https://github.com/wiktorn)) <!-- 2024-08-08 18:16:53+00:00 -->
- [[#2485](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2485)] Project factory module JSON schemas ([ludoo](https://github.com/ludoo)) <!-- 2024-08-08 16:43:11+00:00 -->
- [[#2481](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2481)] Adds a new certification authority service (CAS) module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-08-08 07:55:49+00:00 -->
- [[#2480](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2480)] Add support for PSC global access to net-address ([juliocc](https://github.com/juliocc)) <!-- 2024-08-07 17:27:03+00:00 -->
- [[#2477](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2477)] VPC-SC factory JSON Schemas ([ludoo](https://github.com/ludoo)) <!-- 2024-08-07 12:09:38+00:00 -->
- [[#2474](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2474)] [fix] Pass optional location variable at certificates creation ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-08-07 07:05:57+00:00 -->
- [[#2476](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2476)] Cloud run v2 custom audiences ([apichick](https://github.com/apichick)) <!-- 2024-08-07 06:54:36+00:00 -->
- [[#2475](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2475)] Cloud run v2 output uri ([apichick](https://github.com/apichick)) <!-- 2024-08-06 20:09:19+00:00 -->
- [[#2472](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2472)] Fix grammar in net-vpc-peering preconditions ([juliocc](https://github.com/juliocc)) <!-- 2024-08-06 12:27:31+00:00 -->
- [[#2469](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2469)] Fix  E2E tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-08-06 09:49:30+00:00 -->
- [[#2460](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2460)] **incompatible change:** VPC-SC as separate FAST stage 1 ([ludoo](https://github.com/ludoo)) <!-- 2024-08-02 16:04:36+00:00 -->

### TOOLS

- [[#2543](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2543)] Prepare v34.0.0 release ([ludoo](https://github.com/ludoo)) <!-- 2024-08-30 08:06:33+00:00 -->
- [[#2531](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2531)] Update stable provider too to 5.43 ([juliocc](https://github.com/juliocc)) <!-- 2024-08-28 06:49:46+00:00 -->
- [[#2525](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2525)] Bump provider to last release of version 5 ([juliocc](https://github.com/juliocc)) <!-- 2024-08-27 14:50:59+00:00 -->
- [[#2520](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2520)] Add e2e pubusb errors ([juliocc](https://github.com/juliocc)) <!-- 2024-08-26 17:55:33+00:00 -->
- [[#2492](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2492)] Add schema testing to PR workflow ([juliocc](https://github.com/juliocc)) <!-- 2024-08-09 13:43:11+00:00 -->
- [[#2488](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2488)] Introduce YAML schema validation for YAML examples ([juliocc](https://github.com/juliocc)) <!-- 2024-08-08 21:09:22+00:00 -->
- [[#2487](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2487)] Example testing improvements ([juliocc](https://github.com/juliocc)) <!-- 2024-08-08 19:22:27+00:00 -->

## [33.0.0] - 2024-08-01

### BLUEPRINTS

- [[#2450](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2450)] Remove "constraints/" from org policy names ([juliocc](https://github.com/juliocc)) <!-- 2024-07-29 13:15:04+00:00 -->
- [[#2448](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2448)] Add generic URL output to modules/artifiact-registry ([juliocc](https://github.com/juliocc)) <!-- 2024-07-25 08:33:01+00:00 -->
- [[#2423](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2423)] **incompatible change:** Refactor service agent management ([juliocc](https://github.com/juliocc)) <!-- 2024-07-23 20:05:38+00:00 -->
- [[#2433](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2433)] **incompatible change:** Reintroduce docker image path output in AR module ([ludoo](https://github.com/ludoo)) <!-- 2024-07-20 06:49:59+00:00 -->
- [[#2416](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2416)] Add support for sqlAssertion AutoDQ rule type in dataplex-datascan ([jayBana](https://github.com/jayBana)) <!-- 2024-07-09 21:29:45+00:00 -->
- [[#2395](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2395)] Fix tutorial error. ([wiktorn](https://github.com/wiktorn)) <!-- 2024-06-29 06:55:33+00:00 -->
- [[#2396](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2396)] **incompatible change:** Update `modules/artifact-registry` with newly-released features. ([juliocc](https://github.com/juliocc)) <!-- 2024-06-28 17:52:25+00:00 -->
- [[#2392](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2392)] Added forward_proxy_uri to apigee environments in apigee-x-foundation… ([apichick](https://github.com/apichick)) <!-- 2024-06-27 17:48:24+00:00 -->
- [[#2389](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2389)] Several wording and typos updates  ([bluPhy](https://github.com/bluPhy)) <!-- 2024-06-27 05:36:19+00:00 -->
- [[#2382](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2382)] Fixes related to Apigee KMS keys ([apichick](https://github.com/apichick)) <!-- 2024-06-26 06:12:26+00:00 -->
- [[#2372](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2372)] Added spanner-instance module ([apichick](https://github.com/apichick)) <!-- 2024-06-23 17:25:22+00:00 -->

### FAST

- [[#2410](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2410)] [FAST] Add basic NGFW enterprise stage ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-08-01 09:41:31+00:00 -->
- [[#2450](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2450)] Remove "constraints/" from org policy names ([juliocc](https://github.com/juliocc)) <!-- 2024-07-29 13:15:04+00:00 -->
- [[#2397](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2397)] NCC in 2-net-a-simple ([sruffilli](https://github.com/sruffilli)) <!-- 2024-07-25 16:03:09+00:00 -->
- [[#2446](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2446)] Remove alpha from gcloud storage cp as it moved to GA ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-07-24 20:46:43+00:00 -->
- [[#2444](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2444)] Add context to net-vpc factory ([sruffilli](https://github.com/sruffilli)) <!-- 2024-07-24 13:54:20+00:00 -->
- [[#2423](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2423)] **incompatible change:** Refactor service agent management ([juliocc](https://github.com/juliocc)) <!-- 2024-07-23 20:05:38+00:00 -->
- [[#2440](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2440)] FAST ng: stage 0 environments and VPC-SC IaC resources ([ludoo](https://github.com/ludoo)) <!-- 2024-07-23 09:52:39+00:00 -->
- [[#2430](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2430)] FAST: IAM cleanups to reflect PF changes ([sruffilli](https://github.com/sruffilli)) <!-- 2024-07-18 12:59:30+00:00 -->
- [[#2417](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2417)] Allow description to be set for FAST-managed tags ([juliocc](https://github.com/juliocc)) <!-- 2024-07-09 16:55:21+00:00 -->
- [[#2412](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2412)] [FAST] Housekeeping in CICD workflow templates and extra stage ([jayBana](https://github.com/jayBana)) <!-- 2024-07-08 12:40:33+00:00 -->
- [[#2411](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2411)] [FAST] Fix IAM bindings to impersonate resman CICD SAs at bootstrap stage ([jayBana](https://github.com/jayBana)) <!-- 2024-07-08 10:58:41+00:00 -->
- [[#2404](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2404)] Documented new GCVE design options ([eliamaldini](https://github.com/eliamaldini)) <!-- 2024-07-02 14:46:55+00:00 -->
- [[#2402](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2402)] gitlab workflow template fixes #2401 ([sudhirrs](https://github.com/sudhirrs)) <!-- 2024-07-01 09:42:55+00:00 -->
- [[#2389](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2389)] Several wording and typos updates  ([bluPhy](https://github.com/bluPhy)) <!-- 2024-06-27 05:36:19+00:00 -->
- [[#2378](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2378)] Add wording for SCC Enterprise to FAST stage 0 ([ludoo](https://github.com/ludoo)) <!-- 2024-06-24 17:03:07+00:00 -->

### MODULES

- [[#2459](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2459)] Allow user to override peerings names ([juliocc](https://github.com/juliocc)) <!-- 2024-07-31 15:13:22+00:00 -->
- [[#2457](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2457)] update readme with cross project backend external regional/global LB - review ([vivianvarela](https://github.com/vivianvarela)) <!-- 2024-07-30 15:28:14+00:00 -->
- [[#2454](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2454)] Add support for dry-run org policies ([juliocc](https://github.com/juliocc)) <!-- 2024-07-30 13:12:57+00:00 -->
- [[#2456](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2456)] Manage lifecycle of cloud functions v2 IAM ([ludoo](https://github.com/ludoo)) <!-- 2024-07-30 12:08:05+00:00 -->
- [[#2449](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2449)] Add moved blocks for the service networking service agent and IAM ([juliocc](https://github.com/juliocc)) <!-- 2024-07-25 12:01:21+00:00 -->
- [[#2448](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2448)] **incompatible change:** Add generic URL output to modules/artifact-registry ([juliocc](https://github.com/juliocc)) <!-- 2024-07-25 08:33:01+00:00 -->
- [[#2447](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2447)] Fix wrong expression in compute-mig module ([bz-canva](https://github.com/bz-canva)) <!-- 2024-07-25 05:26:26+00:00 -->
- [[#2445](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2445)] Override primary flag for the storage transfer service agent ([juliocc](https://github.com/juliocc)) <!-- 2024-07-24 14:12:56+00:00 -->
- [[#2444](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2444)] Add context to net-vpc factory ([sruffilli](https://github.com/sruffilli)) <!-- 2024-07-24 13:54:20+00:00 -->
- [[#2443](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2443)] Project service agents moved block and enabled services ([ludoo](https://github.com/ludoo)) <!-- 2024-07-24 12:02:53+00:00 -->
- [[#2423](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2423)] **incompatible change:** Refactor service agent management ([juliocc](https://github.com/juliocc)) <!-- 2024-07-23 20:05:38+00:00 -->
- [[#2439](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2439)] **incompatible change:** Remove default values to secondary range names in GKE cluster modules ([fulyagonultas](https://github.com/fulyagonultas)) <!-- 2024-07-22 20:20:58+00:00 -->
- [[#2437](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2437)] Add coalesce to factory fw policies to support empty yaml files ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-07-22 15:40:22+00:00 -->
- [[#2436](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2436)] Allow disabling topic creation in GCS module notification ([ludoo](https://github.com/ludoo)) <!-- 2024-07-22 10:51:26+00:00 -->
- [[#2433](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2433)] **incompatible change:** Reintroduce docker image path output in AR module ([ludoo](https://github.com/ludoo)) <!-- 2024-07-20 06:49:59+00:00 -->
- [[#2424](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2424)] E2E tests for ncc-spoke-ra ([wiktorn](https://github.com/wiktorn)) <!-- 2024-07-13 11:54:34+00:00 -->
- [[#2427](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2427)] Fix Cloud Function v1/v2 E2E tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-07-13 11:43:05+00:00 -->
- [[#2421](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2421)] fix cloudbuild service account email ([nathou](https://github.com/nathou)) <!-- 2024-07-11 13:31:04+00:00 -->
- [[#2418](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2418)] Adding support for DWS for GKE nodepools ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2024-07-10 13:18:12+00:00 -->
- [[#2416](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2416)] Add support for sqlAssertion AutoDQ rule type in dataplex-datascan ([jayBana](https://github.com/jayBana)) <!-- 2024-07-09 21:29:45+00:00 -->
- [[#2406](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2406)] **incompatible change:** Adding TPU limits for GKE cluster node auto-provisioning (NAP) ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2024-07-09 09:26:30+00:00 -->
- [[#2415](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2415)] Added certificate_manager_certificates to app load balancers ([apichick](https://github.com/apichick)) <!-- 2024-07-09 05:36:06+00:00 -->
- [[#2413](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2413)] **incompatible change:** Add E2E tests for Cloud Functions and fix perma-diff ([wiktorn](https://github.com/wiktorn)) <!-- 2024-07-08 14:14:21+00:00 -->
- [[#2409](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2409)] Adds support for external SPGs to net-firewall-policy ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-07-06 10:33:09+00:00 -->
- [[#2407](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2407)] Allow project factory projects to override name ([juliocc](https://github.com/juliocc)) <!-- 2024-07-04 18:14:04+00:00 -->
- [[#2405](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2405)] Adding placement_policy for GKE nodepools (ex: GPU compact placement or TPU topology) ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2024-07-03 10:21:31+00:00 -->
- [[#2400](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2400)] Add info about roles for connectors service agent ([wiktorn](https://github.com/wiktorn)) <!-- 2024-06-30 18:17:51+00:00 -->
- [[#2396](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2396)] **incompatible change:** Update `modules/artifact-registry` with newly-released features. ([juliocc](https://github.com/juliocc)) <!-- 2024-06-28 17:52:25+00:00 -->
- [[#2393](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2393)] Add support for SSL policy to net-lb-app-int module ([ludoo](https://github.com/ludoo)) <!-- 2024-06-28 07:03:10+00:00 -->
- [[#2387](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2387)] Added certificate-manager module ([apichick](https://github.com/apichick)) <!-- 2024-06-27 13:05:35+00:00 -->
- [[#2390](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2390)] Add AssuredWorkload support to the folder module ([averbuks](https://github.com/averbuks)) <!-- 2024-06-27 12:28:17+00:00 -->
- [[#2384](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2384)] Allow Cloud NAT to only use secondary ranges ([juliocc](https://github.com/juliocc)) <!-- 2024-06-27 08:05:45+00:00 -->
- [[#2388](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2388)] Added missing links to firestore module is READMEs. ([apichick](https://github.com/apichick)) <!-- 2024-06-27 06:54:03+00:00 -->
- [[#2389](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2389)] Several wording and typos updates  ([bluPhy](https://github.com/bluPhy)) <!-- 2024-06-27 05:36:19+00:00 -->
- [[#2374](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2374)] Added firestore module ([apichick](https://github.com/apichick)) <!-- 2024-06-26 12:18:42+00:00 -->
- [[#2380](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2380)] Added private_endpoint_subnetwork parameters to GKE standard and autopilot modules ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2024-06-25 14:16:01+00:00 -->
- [[#2370](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2370)] Apigee - Add forward_proxy_uri support on environment resource ([diogo-j-n-teixeira](https://github.com/diogo-j-n-teixeira)) <!-- 2024-06-25 07:50:19+00:00 -->
- [[#2376](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2376)] Removed advertised_groups ALL_VPC_SUBNETS, ALL_VPC_SUBNETS as they ar… ([apichick](https://github.com/apichick)) <!-- 2024-06-24 07:15:20+00:00 -->
- [[#2375](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2375)] Minor fixes in workstations IAM ([apichick](https://github.com/apichick)) <!-- 2024-06-24 06:59:29+00:00 -->
- [[#2372](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2372)] Added spanner-instance module ([apichick](https://github.com/apichick)) <!-- 2024-06-23 17:25:22+00:00 -->
- [[#2373](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2373)] Added expire_time option to the secret-manager module ([deanosaurx](https://github.com/deanosaurx)) <!-- 2024-06-23 15:20:10+00:00 -->
- [[#2371](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2371)] Support build service account in cloud function v2 module ([ludoo](https://github.com/ludoo)) <!-- 2024-06-21 18:19:29+00:00 -->
- [[#2369](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2369)] Add example, tests and fix for Google APIs PSC endpoint ([wiktorn](https://github.com/wiktorn)) <!-- 2024-06-20 10:44:43+00:00 -->
- [[#2368](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2368)] Fix for plan not in sync when creating billing budgets in project factory #2365 ([sudhirrs](https://github.com/sudhirrs)) <!-- 2024-06-20 05:23:20+00:00 -->
- [[#2366](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2366)] Added additional range field to GKE standand and autopilot ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2024-06-18 12:17:09+00:00 -->

### TOOLS

- [[#2452](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2452)] Add `--extra-files` option to plan_summary.py cmd ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-07-30 09:29:19+00:00 -->
- [[#2445](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2445)] Override primary flag for the storage transfer service agent ([juliocc](https://github.com/juliocc)) <!-- 2024-07-24 14:12:56+00:00 -->
- [[#2423](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2423)] **incompatible change:** Refactor service agent management ([juliocc](https://github.com/juliocc)) <!-- 2024-07-23 20:05:38+00:00 -->
- [[#2441](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2441)] Add commit id at the end of README ([juliocc](https://github.com/juliocc)) <!-- 2024-07-23 10:04:18+00:00 -->
- [[#2413](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2413)] **incompatible change:** Add E2E tests for Cloud Functions and fix perma-diff ([wiktorn](https://github.com/wiktorn)) <!-- 2024-07-08 14:14:21+00:00 -->
- [[#2399](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2399)] Test different versions of Terraform ([wiktorn](https://github.com/wiktorn)) <!-- 2024-07-05 11:21:41+00:00 -->

## [32.0.1] - 2024-07-26
<!-- 2024-07-26 05:52:59+00:00 < 2024-06-16 07:51:14+00:00 -->

### MODULES

- [[#2447](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2447)] Fix wrong expression in compute-mig module ([bz-canva](https://github.com/bz-canva)) <!-- 2024-07-25 05:26:26+00:00 -->

## [32.0.0] - 2024-06-16

### BLUEPRINTS

- [[#2361](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2361)] **incompatible change:** Support GCS objects in cloud function modules bundles ([ludoo](https://github.com/ludoo)) <!-- 2024-06-14 11:44:01+00:00 -->
- [[#2358](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2358)] **incompatible change:** Support pre-made bundle archives in cloud function modules ([ludoo](https://github.com/ludoo)) <!-- 2024-06-13 12:58:23+00:00 -->
- [[#2347](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2347)] Add GCVE Logging and Monitoring Blueprint ([KonradSchieban](https://github.com/KonradSchieban)) <!-- 2024-06-11 14:36:23+00:00 -->
- [[#2356](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2356)] Add Terraform installation step to meet the versions.tf requirements ([wiktorn](https://github.com/wiktorn)) <!-- 2024-06-11 13:40:31+00:00 -->
- [[#2355](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2355)] Bump @grpc/grpc-js from 1.10.7 to 1.10.9 in /blueprints/apigee/apigee-x-foundations/functions/instance-monitor ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-06-11 05:21:41+00:00 -->
- [[#2341](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2341)] Alloydb add support for psc ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-06-05 11:39:03+00:00 -->
- [[#2328](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2328)] [FAST] Rename stage 2-networking-d-separate-envs to 2-networking-c-separate-envs ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-05-31 06:09:31+00:00 -->
- [[#2326](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2326)] Add pre-commit hook configuration ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-30 17:35:09+00:00 -->
- [[#2299](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2299)] Kong Gateway on GKE offloading to Cloud Run ([juliodiez](https://github.com/juliodiez)) <!-- 2024-05-29 14:26:25+00:00 -->
- [[#2317](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2317)] resource_labels added to the node_config nodepool ([fulyagonultas](https://github.com/fulyagonultas)) <!-- 2024-05-29 12:56:15+00:00 -->
- [[#2106](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2106)] Gitlab Runner blueprint ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-05-27 08:34:35+00:00 -->
- [[#2303](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2303)] **incompatible change:** Remove default location from gcs module ([ludoo](https://github.com/ludoo)) <!-- 2024-05-24 07:02:33+00:00 -->
- [[#2296](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2296)] Bump requests from 2.31.0 to 2.32.0 in /blueprints/cloud-operations/network-quota-monitoring/src ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-05-21 07:20:53+00:00 -->
- [[#2284](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2284)] **incompatible change:** Unify VPN and Peering FAST stages ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-16 09:18:32+00:00 -->

### DOCUMENTATION

- [[#2106](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2106)] Gitlab Runner blueprint ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-05-27 08:34:35+00:00 -->

### FAST

- [[#2353](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2353)] Add main project factory service account ([ludoo](https://github.com/ludoo)) <!-- 2024-06-10 10:23:30+00:00 -->
- [[#2352](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2352)] **incompatible change:** Remove support for source repositories from FAST CI/CD ([ludoo](https://github.com/ludoo)) <!-- 2024-06-10 09:02:55+00:00 -->
- [[#2344](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2344)] Fix typos in documentation ([albertogeniola](https://github.com/albertogeniola)) <!-- 2024-06-07 14:32:06+00:00 -->
- [[#2340](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2340)] Fix wrong documentation reference to tfvars ([albertogeniola](https://github.com/albertogeniola)) <!-- 2024-06-04 14:23:08+00:00 -->
- [[#2337](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2337)] DNS policy fix ([sruffilli](https://github.com/sruffilli)) <!-- 2024-06-03 06:25:35+00:00 -->
- [[#2335](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2335)] Add perimeter ids in vpc-sc module outputs, fix vpc-sc in project factory module ([ludoo](https://github.com/ludoo)) <!-- 2024-05-31 18:08:00+00:00 -->
- [[#2334](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2334)] Support setting IAM for FAST tags in resource management stage ([ludoo](https://github.com/ludoo)) <!-- 2024-05-31 12:57:14+00:00 -->
- [[#2333](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2333)] Fix resman top-level folders variable types ([ludoo](https://github.com/ludoo)) <!-- 2024-05-31 12:45:32+00:00 -->
- [[#2332](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2332)] Fix dns policy ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-31 11:27:31+00:00 -->
- [[#2331](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2331)] Enable hierarchy in fast project factory ([ludoo](https://github.com/ludoo)) <!-- 2024-05-31 11:11:13+00:00 -->
- [[#2330](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2330)] Update PGA domains ([juliocc](https://github.com/juliocc)) <!-- 2024-05-31 10:53:50+00:00 -->
- [[#2329](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2329)] FAST: Enable networkconnectivity when using NCC-RA in 2-b ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-31 08:22:24+00:00 -->
- [[#2328](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2328)] [FAST] Rename stage 2-networking-d-separate-envs to 2-networking-c-separate-envs ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-05-31 06:09:31+00:00 -->
- [[#2325](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2325)] Fix restrictAllowedGenerations org policy example ([juliocc](https://github.com/juliocc)) <!-- 2024-05-30 12:19:24+00:00 -->
- [[#2317](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2317)] resource_labels added to the node_config nodepool ([fulyagonultas](https://github.com/fulyagonultas)) <!-- 2024-05-29 12:56:15+00:00 -->
- [[#2319](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2319)] Pbrumblay/clarify org policy tags ([pbrumblay](https://github.com/pbrumblay)) <!-- 2024-05-29 06:19:39+00:00 -->
- [[#2309](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2309)] **incompatible change:** Merge FAST C and E network stages into a new B stage. ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-28 15:27:28+00:00 -->
- [[#2315](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2315)] FAST: Obsolete assets cleanup ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-28 09:35:13+00:00 -->
- [[#2305](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2305)] FAST MT: Readme updates and more prefix validation  ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-24 10:01:55+00:00 -->
- [[#2232](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2232)] New extra stage for FAST gitlab setup ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-05-22 07:17:14+00:00 -->
- [[#2294](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2294)] Avoid unnecessary terraform plans for closed (unmerged) PRs ([pbrumblay](https://github.com/pbrumblay)) <!-- 2024-05-21 13:03:07+00:00 -->
- [[#2298](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2298)] Adjust list of imported org policies to official docs ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-21 09:27:57+00:00 -->
- [[#2297](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2297)] Add support for tenant factory CI/CD ([ludoo](https://github.com/ludoo)) <!-- 2024-05-21 08:39:47+00:00 -->
- [[#2292](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2292)] [FAST] fix: tenant-factory logging bucket project ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-05-20 16:51:12+00:00 -->
- [[#2290](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2290)] Add wif permissions to bootstrap tf SA ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-05-20 16:15:23+00:00 -->
- [[#2289](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2289)] Fix mt diagram and broken link ([ludoo](https://github.com/ludoo)) <!-- 2024-05-18 21:53:49+00:00 -->
- [[#2288](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2288)] Ignore test resource data in new network stage, split out fast variables ([ludoo](https://github.com/ludoo)) <!-- 2024-05-17 13:30:57+00:00 -->
- [[#2286](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2286)] Switch FAST stages 0-1s to excalidraw diagrams ([ludoo](https://github.com/ludoo)) <!-- 2024-05-17 09:10:13+00:00 -->
- [[#2287](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2287)] **incompatible change:** FAST: Cleanup/harmonization of Simple and NVA net stages ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-16 13:49:16+00:00 -->
- [[#2284](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2284)] **incompatible change:** Unify VPN and Peering FAST stages ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-16 09:18:32+00:00 -->
- [[#2254](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2254)] **incompatible change:** FAST: add top-level folders and restructure teams/tenants in resman ([ludoo](https://github.com/ludoo)) <!-- 2024-05-15 09:17:13+00:00 -->

### MODULES

- [[#2364](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2364)] Relax dataproc master config type ([ludoo](https://github.com/ludoo)) <!-- 2024-06-14 14:19:57+00:00 -->
- [[#2363](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2363)] Add support for different endpoint types for Cloud NAT ([wiktorn](https://github.com/wiktorn)) <!-- 2024-06-14 13:37:58+00:00 -->
- [[#2362](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2362)] Strip bucket name from bundle URI in cloud function modules ([ludoo](https://github.com/ludoo)) <!-- 2024-06-14 12:31:01+00:00 -->
- [[#2361](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2361)] **incompatible change:** Support GCS objects in cloud function modules bundles ([ludoo](https://github.com/ludoo)) <!-- 2024-06-14 11:44:01+00:00 -->
- [[#2360](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2360)] Validate bundle, use pathexpand in cloud function modules ([ludoo](https://github.com/ludoo)) <!-- 2024-06-14 07:23:50+00:00 -->
- [[#2359](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2359)] Don't compute checksum in cloud function modules for static bundles ([ludoo](https://github.com/ludoo)) <!-- 2024-06-13 16:08:12+00:00 -->
- [[#2358](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2358)] **incompatible change:** Support pre-made bundle archives in cloud function modules ([ludoo](https://github.com/ludoo)) <!-- 2024-06-13 12:58:23+00:00 -->
- [[#2357](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2357)] Add use_table_schema parameter for PubSub subscription to BigQuery ([mdaddetta](https://github.com/mdaddetta)) <!-- 2024-06-12 22:36:19+00:00 -->
- [[#2354](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2354)] Use var.vpc_config.subnetwork in NEGs when var.neg_config.*.subnetwork is not provided ([wiktorn](https://github.com/wiktorn)) <!-- 2024-06-10 14:57:12+00:00 -->
- [[#2351](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2351)] Added missing validation values for backend services ([deanosaurx](https://github.com/deanosaurx)) <!-- 2024-06-09 07:15:22+00:00 -->
- [[#2350](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2350)] Add network tags outputs and examples to project module ([ludoo](https://github.com/ludoo)) <!-- 2024-06-09 05:52:15+00:00 -->
- [[#2341](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2341)] Alloydb add support for psc ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-06-05 11:39:03+00:00 -->
- [[#2339](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2339)] Enable stateful ha in gke cluster standard module ([ludoo](https://github.com/ludoo)) <!-- 2024-06-04 07:51:20+00:00 -->
- [[#2336](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2336)] Add documentation for load balancer changes ([wiktorn](https://github.com/wiktorn)) <!-- 2024-06-03 06:47:49+00:00 -->
- [[#2335](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2335)] Add perimeter ids in vpc-sc module outputs, fix vpc-sc in project factory module ([ludoo](https://github.com/ludoo)) <!-- 2024-05-31 18:08:00+00:00 -->
- [[#2321](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2321)] Fixed e2e tests for alloydb module ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-05-30 09:41:15+00:00 -->
- [[#2312](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2312)] Fixes for Alloydb E2E tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-29 14:46:15+00:00 -->
- [[#2317](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2317)] resource_labels added to the node_config nodepool ([fulyagonultas](https://github.com/fulyagonultas)) <!-- 2024-05-29 12:56:15+00:00 -->
- [[#2280](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2280)] Secret manager e2etests ([dibaskar-google](https://github.com/dibaskar-google)) <!-- 2024-05-28 07:28:09+00:00 -->
- [[#2307](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2307)] Extend support for tag bindings to more modules ([ludoo](https://github.com/ludoo)) <!-- 2024-05-25 08:42:45+00:00 -->
- [[#2306](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2306)] Internet NEG for internal proxy LB ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-24 10:56:28+00:00 -->
- [[#2304](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2304)] **incompatible change:** Remove default location from container-registry, datacatalog-policy-tag, workstation-cluster ([ludoo](https://github.com/ludoo)) <!-- 2024-05-24 07:20:53+00:00 -->
- [[#2303](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2303)] **incompatible change:** Remove default location from gcs module ([ludoo](https://github.com/ludoo)) <!-- 2024-05-24 07:02:33+00:00 -->
- [[#2301](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2301)] Fix permadiff in cloud nat module ([ludoo](https://github.com/ludoo)) <!-- 2024-05-23 06:38:03+00:00 -->
- [[#2300](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2300)] Add support for shared vpc host to project factory ([ludoo](https://github.com/ludoo)) <!-- 2024-05-22 07:56:34+00:00 -->
- [[#2285](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2285)] New alloydb module ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-05-22 07:40:26+00:00 -->
- [[#2291](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2291)] IPS support for Firewall Policy ([rickygodoy](https://github.com/rickygodoy)) <!-- 2024-05-21 04:38:43+00:00 -->
- [[#2293](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2293)] Internet NEG for net-lb-app-int ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-20 19:12:39+00:00 -->

### TOOLS

- [[#2363](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2363)] Add support for different endpoint types for Cloud NAT ([wiktorn](https://github.com/wiktorn)) <!-- 2024-06-14 13:37:58+00:00 -->
- [[#2346](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2346)] use /bin/sh for pre-commit script for portability ([wiktorn](https://github.com/wiktorn)) <!-- 2024-06-07 06:15:33+00:00 -->
- [[#2343](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2343)] Change shebang on pre-commit checks ([albertogeniola](https://github.com/albertogeniola)) <!-- 2024-06-05 17:55:09+00:00 -->
- [[#2327](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2327)] Add outstanding checks from lint.sh to pre-commit ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-31 10:22:21+00:00 -->
- [[#2326](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2326)] Add pre-commit hook configuration ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-30 17:35:09+00:00 -->
- [[#2315](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2315)] FAST: Obsolete assets cleanup ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-28 09:35:13+00:00 -->
- [[#2314](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2314)] Explicit YAPF style ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-28 08:53:14+00:00 -->
- [[#2302](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2302)] Add AlloyDB service for e2e tests harness ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-23 09:44:41+00:00 -->
- [[#2285](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2285)] New alloydb module ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-05-22 07:40:26+00:00 -->
- [[#2254](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2254)] **incompatible change:** FAST: add top-level folders and restructure teams/tenants in resman ([ludoo](https://github.com/ludoo)) <!-- 2024-05-15 09:17:13+00:00 -->

## [31.1.0] - 2024-05-15
<!-- 2024-05-15 09:01:39+00:00 < 2024-05-14 19:52:57+00:00 -->

### BLUEPRINTS

- [[#2282](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2282)] Disable reserved_internal_range in net-vpc due to provider bug ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-15 05:46:18+00:00 -->

### MODULES

- [[#2282](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2282)] Disable reserved_internal_range in net-vpc due to provider bug ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-15 05:46:18+00:00 -->

## [31.0.0] - 2024-05-14
<!-- 2024-05-14 19:52:57+00:00 < 2024-03-20 13:57:56+00:00 -->

### BLUEPRINTS

- [[#2278](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2278)] Bump express from 4.18.2 to 4.19.2 in /blueprints/apigee/apigee-x-foundations/functions/instance-monitor ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-05-14 19:30:35+00:00 -->
- [[#2275](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2275)] Add support for reserved_internal_range in net-vpc ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-14 19:19:45+00:00 -->
- [[#2277](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2277)] Added missing apigee org attributes to apigee x foundations blueprint ([apichick](https://github.com/apichick)) <!-- 2024-05-14 18:48:05+00:00 -->
- [[#2279](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2279)] Bump protobufjs, @google-cloud/logging-bunyan and @google-cloud/monitoring in /blueprints/apigee/apigee-x-foundations/functions/instance-monitor ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-05-14 18:37:16+00:00 -->
- [[#2274](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2274)] Added apigee-x-foundations blueprint ([apichick](https://github.com/apichick)) <!-- 2024-05-14 14:53:38+00:00 -->
- [[#2243](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2243)] Added new attributes Apigee organization and bumped up providers version ([apichick](https://github.com/apichick)) <!-- 2024-04-28 15:31:42+00:00 -->
- [[#2239](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2239)] Update README.md ([vicenteg](https://github.com/vicenteg)) <!-- 2024-04-25 23:14:32+00:00 -->
- [[#2230](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2230)] docs: :memo: fix error in phpIPAM terraform config by updating VPC pe… ([PapaPeskwo](https://github.com/PapaPeskwo)) <!-- 2024-04-22 10:55:03+00:00 -->
- [[#2227](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2227)] Bump golang.org/x/net from 0.17.0 to 0.23.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/healthchecker ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-04-19 12:26:14+00:00 -->
- [[#2228](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2228)] Bump golang.org/x/net from 0.17.0 to 0.23.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/restarter ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-04-19 12:25:52+00:00 -->
- [[#2226](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2226)] fix cloud sql PSA after module upgrade ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-04-19 10:41:02+00:00 -->
- [[#2220](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2220)] Add tflint to pipelines ([juliocc](https://github.com/juliocc)) <!-- 2024-04-17 08:23:49+00:00 -->
- [[#2218](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2218)] **incompatible change:** Allow multiple PSA service providers in net-vpc module ([ludoo](https://github.com/ludoo)) <!-- 2024-04-16 15:02:36+00:00 -->
- [[#2208](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2208)] Updated diagram to better reflect PSC terminology ([bswenka](https://github.com/bswenka)) <!-- 2024-04-09 15:18:43+00:00 -->
- [[#2207](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2207)] feat(gke-cluster-standard): Add optional `CiliumClusterWideNetworkPolicy` ([anthonyhaussman](https://github.com/anthonyhaussman)) <!-- 2024-04-09 15:08:36+00:00 -->
- [[#2201](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2201)] Updating cloud-run-v2 terraform and some typos ([bluPhy](https://github.com/bluPhy)) <!-- 2024-04-07 09:49:07+00:00 -->
- [[#2191](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2191)] FAST GCVE stage ([eliamaldini](https://github.com/eliamaldini)) <!-- 2024-04-03 15:25:12+00:00 -->
- [[#2181](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2181)] Bump express from 4.17.3 to 4.19.2 in /blueprints/gke/binauthz/image ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-03-28 06:14:50+00:00 -->
- [[#2174](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2174)] Bump provider version to 5.18 to fix non-empty plan for google_notebooks_instance ([wiktorn](https://github.com/wiktorn)) <!-- 2024-03-25 18:57:14+00:00 -->
- [[#2171](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2171)] **incompatible change:** Fix subnet configuration in cloud nat module ([ludoo](https://github.com/ludoo)) <!-- 2024-03-22 14:59:02+00:00 -->
- [[#2168](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2168)] Support advanced_datapath_observability in gke cluster standard module ([ludoo](https://github.com/ludoo)) <!-- 2024-03-22 07:25:43+00:00 -->
- [[#2169](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2169)] Add stub READMEs for the removed hub and spoke blueprints ([ludoo](https://github.com/ludoo)) <!-- 2024-03-22 06:48:46+00:00 -->

### DOCUMENTATION

- [[#2164](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2164)] Updated CONTRIBUTING.md with a guide to cut a new release ([sruffilli](https://github.com/sruffilli)) <!-- 2024-03-20 17:08:27+00:00 -->

### FAST

- [[#2267](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2267)] Fix 0-bootstrap iam_by_principals not taking into account all principals ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-12 19:02:04+00:00 -->
- [[#2263](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2263)] Update docs - gcp-network-admins -> gcp-vpc-network-admins ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-10 08:04:25+00:00 -->
- [[#2260](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2260)] Remove data source from folder module ([ludoo](https://github.com/ludoo)) <!-- 2024-05-09 13:09:54+00:00 -->
- [[#2253](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2253)] Misc FAST fixes ([juliocc](https://github.com/juliocc)) <!-- 2024-05-02 06:56:26+00:00 -->
- [[#2235](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2235)] Update FAST logging ([juliocc](https://github.com/juliocc)) <!-- 2024-04-25 06:31:52+00:00 -->
- [[#2233](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2233)] Fix permissions for branch network dev - read sa ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-04-23 13:19:39+00:00 -->
- [[#2221](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2221)] Enable TFLint in FAST stages ([juliocc](https://github.com/juliocc)) <!-- 2024-04-18 08:06:24+00:00 -->
- [[#2220](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2220)] Add tflint to pipelines ([juliocc](https://github.com/juliocc)) <!-- 2024-04-17 08:23:49+00:00 -->
- [[#2218](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2218)] **incompatible change:** Allow multiple PSA service providers in net-vpc module ([ludoo](https://github.com/ludoo)) <!-- 2024-04-16 15:02:36+00:00 -->
- [[#2219](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2219)] Remove unused variables/locals from FAST ([juliocc](https://github.com/juliocc)) <!-- 2024-04-16 14:14:24+00:00 -->
- [[#2215](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2215)] Add new org policies to FAST ([juliocc](https://github.com/juliocc)) <!-- 2024-04-15 13:29:24+00:00 -->
- [[#2210](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2210)] Add support for quotas to project module ([ludoo](https://github.com/ludoo)) <!-- 2024-04-10 17:03:04+00:00 -->
- [[#2206](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2206)] Update the description and README for the tags variable ([timothy-jabez](https://github.com/timothy-jabez)) <!-- 2024-04-10 13:08:59+00:00 -->
- [[#2204](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2204)] Align exported tfvars in FAST networking stages, add psc and proxy only subnets ([ludoo](https://github.com/ludoo)) <!-- 2024-04-08 07:26:47+00:00 -->
- [[#2203](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2203)] **incompatible change:** FAST security stage refactor ([ludoo](https://github.com/ludoo)) <!-- 2024-04-08 03:14:39+00:00 -->
- [[#2196](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2196)] Add variable to resman to control top-level folder IAM ([juliocc](https://github.com/juliocc)) <!-- 2024-04-04 08:26:35+00:00 -->
- [[#2195](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2195)] Allow r/o project factory SAs access to folder-level IAM ([ludoo](https://github.com/ludoo)) <!-- 2024-04-03 19:51:47+00:00 -->
- [[#2191](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2191)] FAST GCVE stage ([eliamaldini](https://github.com/eliamaldini)) <!-- 2024-04-03 15:25:12+00:00 -->
- [[#2178](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2178)] Add missing permission to org viewer custom role in FAST stage 0 ([ludoo](https://github.com/ludoo)) <!-- 2024-03-27 08:06:25+00:00 -->
- [[#2172](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2172)] Fix subnet names in FAST net stage c nva ([ludoo](https://github.com/ludoo)) <!-- 2024-03-24 11:54:29+00:00 -->

### MODULES

- [[#2275](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2275)] Add support for reserved_internal_range in net-vpc ([sruffilli](https://github.com/sruffilli)) <!-- 2024-05-14 19:19:45+00:00 -->
- [[#2274](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2274)] Added apigee-x-foundations blueprint ([apichick](https://github.com/apichick)) <!-- 2024-05-14 14:53:38+00:00 -->
- [[#2270](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2270)] Cloud function CMEK key support ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2024-05-14 12:56:10+00:00 -->
- [[#2272](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2272)] New Bindplane cloud-config-container setup ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-05-14 12:45:40+00:00 -->
- [[#2269](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2269)] Implement the full IAM interface for tags ([ludoo](https://github.com/ludoo)) <!-- 2024-05-13 18:18:52+00:00 -->
- [[#2268](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2268)] Add logging settings to folder module ([ludoo](https://github.com/ludoo)) <!-- 2024-05-13 07:24:17+00:00 -->
- [[#2242](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2242)] CloudSQL PSC Endpoints support ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-12 10:00:40+00:00 -->
- [[#2265](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2265)] Fix failing E2E net-vpc test ([wiktorn](https://github.com/wiktorn)) <!-- 2024-05-11 15:29:35+00:00 -->
- [[#2264](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2264)] Fix bug from output typo in new project-factory module ([JanCVanB](https://github.com/JanCVanB)) <!-- 2024-05-10 22:19:36+00:00 -->
- [[#2262](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2262)] Make Simple NVA route IAP traffic through NIC 0 ([juliocc](https://github.com/juliocc)) <!-- 2024-05-09 16:29:25+00:00 -->
- [[#2261](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2261)] Add Hybrid NAT support ([juliocc](https://github.com/juliocc)) <!-- 2024-05-09 13:24:41+00:00 -->
- [[#2260](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2260)] Remove data source from folder module ([ludoo](https://github.com/ludoo)) <!-- 2024-05-09 13:09:54+00:00 -->
- [[#2247](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2247)] Fix workstation-cluster module for private deployment ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-05-02 06:09:10+00:00 -->
- [[#2252](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2252)] Add support for labels to GKE backup plans ([ludoo](https://github.com/ludoo)) <!-- 2024-05-01 18:20:22+00:00 -->
- [[#2251](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2251)] Fix factory ingress policy services in vpc-sc module ([ludoo](https://github.com/ludoo)) <!-- 2024-05-01 16:50:30+00:00 -->
- [[#2248](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2248)] Added missing identity when connectors API is enabled ([jnahelou](https://github.com/jnahelou)) <!-- 2024-04-30 17:21:35+00:00 -->
- [[#2246](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2246)] Fixed issue with service networking DNS peering ([apichick](https://github.com/apichick)) <!-- 2024-04-28 20:18:02+00:00 -->
- [[#2243](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2243)] Added new attributes Apigee organization and bumped up providers version ([apichick](https://github.com/apichick)) <!-- 2024-04-28 15:31:42+00:00 -->
- [[#2244](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2244)] **incompatible change:** Removed BFD settings from net-vpn-ha module as it is not supported ([apichick](https://github.com/apichick)) <!-- 2024-04-28 10:11:08+00:00 -->
- [[#2241](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2241)] Use default labels on pubsub subscription when no override is provided ([wiktorn](https://github.com/wiktorn)) <!-- 2024-04-27 07:22:41+00:00 -->
- [[#2238](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2238)] fix: allow disabling node autoprovisioning ([kumadee](https://github.com/kumadee)) <!-- 2024-04-26 07:17:48+00:00 -->
- [[#2234](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2234)] Added build environment variables in cloud function v1 ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2024-04-23 17:20:38+00:00 -->
- [[#2229](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2229)] **incompatible change:** Refactor vpc-sc support in project module, add support for dry run ([ludoo](https://github.com/ludoo)) <!-- 2024-04-22 07:28:01+00:00 -->
- [[#2226](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2226)] fix cloud sql PSA after module upgrade ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-04-19 10:41:02+00:00 -->
- [[#2224](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2224)] added missing option for exclusion scope ([cmalpe](https://github.com/cmalpe)) <!-- 2024-04-18 11:12:16+00:00 -->
- [[#2220](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2220)] Add tflint to pipelines ([juliocc](https://github.com/juliocc)) <!-- 2024-04-17 08:23:49+00:00 -->
- [[#2218](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2218)] **incompatible change:** Allow multiple PSA service providers in net-vpc module ([ludoo](https://github.com/ludoo)) <!-- 2024-04-16 15:02:36+00:00 -->
- [[#2216](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2216)] Remove data source from net-vpc module ([ludoo](https://github.com/ludoo)) <!-- 2024-04-16 11:11:12+00:00 -->
- [[#2214](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2214)] Net LB App Internal Cross-Region recipe ([ludoo](https://github.com/ludoo)) <!-- 2024-04-14 16:38:05+00:00 -->
- [[#2213](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2213)] Add support for tags to GCS module ([ludoo](https://github.com/ludoo)) <!-- 2024-04-11 13:19:06+00:00 -->
- [[#2211](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2211)] Add project quotas factory ([wiktorn](https://github.com/wiktorn)) <!-- 2024-04-11 09:51:19+00:00 -->
- [[#2212](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2212)] Add support for GCS soft-delete retention period ([sruffilli](https://github.com/sruffilli)) <!-- 2024-04-11 07:31:00+00:00 -->
- [[#2210](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2210)] Add support for quotas to project module ([ludoo](https://github.com/ludoo)) <!-- 2024-04-10 17:03:04+00:00 -->
- [[#2209](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2209)] Add support for data cache to cloud sql module ([ludoo](https://github.com/ludoo)) <!-- 2024-04-10 06:24:01+00:00 -->
- [[#2207](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2207)] feat(gke-cluster-standard): Add optional `CiliumClusterWideNetworkPolicy` ([anthonyhaussman](https://github.com/anthonyhaussman)) <!-- 2024-04-09 15:08:36+00:00 -->
- [[#2205](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2205)] Add validation rule for DNS module health check targets ([ludoo](https://github.com/ludoo)) <!-- 2024-04-08 11:30:42+00:00 -->
- [[#2201](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2201)] Updating cloud-run-v2 terraform and some typos ([bluPhy](https://github.com/bluPhy)) <!-- 2024-04-07 09:49:07+00:00 -->
- [[#2202](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2202)] added force_destroy to dns module ([nika-pr](https://github.com/nika-pr)) <!-- 2024-04-05 09:20:51+00:00 -->
- [[#2191](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2191)] FAST GCVE stage ([eliamaldini](https://github.com/eliamaldini)) <!-- 2024-04-03 15:25:12+00:00 -->
- [[#2190](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2190)] VPC module - PSA configurable service producer ([spica29](https://github.com/spica29)) <!-- 2024-04-02 18:23:25+00:00 -->
- [[#2185](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2185)] Fix failing e2e tests for Cloud Run CMEK ([wiktorn](https://github.com/wiktorn)) <!-- 2024-03-28 14:02:56+00:00 -->
- [[#2182](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2182)] **incompatible change:** Fix default nodepool defaults in gke standard module ([ludoo](https://github.com/ludoo)) <!-- 2024-03-28 10:22:15+00:00 -->
- [[#2177](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2177)] add cmek option for cloud_run_v2 ([SalehElnagarSecurrency](https://github.com/SalehElnagarSecurrency)) <!-- 2024-03-27 09:15:03+00:00 -->
- [[#2175](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2175)] feat(gke-cluster-standard): Set optional `default_node_pool` configuration ([anthonyhaussman](https://github.com/anthonyhaussman)) <!-- 2024-03-26 17:05:35+00:00 -->
- [[#2174](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2174)] Bump provider version to 5.18 to fix non-empty plan for google_notebooks_instance ([wiktorn](https://github.com/wiktorn)) <!-- 2024-03-25 18:57:14+00:00 -->
- [[#2171](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2171)] **incompatible change:** Fix subnet configuration in cloud nat module ([ludoo](https://github.com/ludoo)) <!-- 2024-03-22 14:59:02+00:00 -->
- [[#2170](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2170)] Support optional secondary ranges in net-cloudnat module ([ludoo](https://github.com/ludoo)) <!-- 2024-03-22 11:10:48+00:00 -->
- [[#2168](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2168)] Support advanced_datapath_observability in gke cluster standard module ([ludoo](https://github.com/ludoo)) <!-- 2024-03-22 07:25:43+00:00 -->
- [[#2166](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2166)] feat(net-cloudnat): add `tcp_time_wait` to `config_timeouts` ([frits-v](https://github.com/frits-v)) <!-- 2024-03-20 21:26:28+00:00 -->

### TOOLS

- [[#2225](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2225)] Generalization of tflint call for FAST stages ([wiktorn](https://github.com/wiktorn)) <!-- 2024-04-18 19:04:24+00:00 -->
- [[#2221](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2221)] Enable TFLint in FAST stages ([juliocc](https://github.com/juliocc)) <!-- 2024-04-18 08:06:24+00:00 -->
- [[#2220](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2220)] Add tflint to pipelines ([juliocc](https://github.com/juliocc)) <!-- 2024-04-17 08:23:49+00:00 -->
- [[#2214](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2214)] Net LB App Internal Cross-Region recipe ([ludoo](https://github.com/ludoo)) <!-- 2024-04-14 16:38:05+00:00 -->
- [[#2192](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2192)] Update labeler version ([ludoo](https://github.com/ludoo)) <!-- 2024-04-03 09:24:10+00:00 -->
- [[#2189](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2189)] Use explicit UTF-8 encoding in tfdoc.py ([wiktorn](https://github.com/wiktorn)) <!-- 2024-04-02 18:34:51+00:00 -->
- [[#2163](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2163)] feat: add e2e test for pubsub module ([andybubu](https://github.com/andybubu)) <!-- 2024-03-20 16:30:30+00:00 -->

<!-- markdown-link-check-disable -->
[Unreleased]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v41.0.0...HEAD
[41.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v40.2.0...41.0.0
[40.2.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v40.1.0...40.2.0
[40.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v40.0.0...40.1.0
[40.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v39.2.0...v40.0.0
[39.2.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v39.1.0...v39.2.0
[39.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v39.0.0...v39.1.0
[39.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v38.2.0...v39.0.0
[38.2.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v38.1.0...v38.2.0
[38.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v38.0.0...v38.1.0
[38.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v37.4.0...v38.0.0
[37.4.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v37.3.0...v37.4.0
[37.3.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v37.2.0...v37.3.0
[37.2.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v37.1.0...v37.2.0
[37.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v37.0.0...v37.1.0
[37.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v36.2.0...v37.0.0
[36.2.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v36.1.0...v36.2.0
[36.1.0]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v36.0.1...v36.1.0>
[36.0.1]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v36.0.0...v36.0.1>
[36.0.0]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v35.1.0...v36.0.0>
[35.1.0]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v35.0.0...v35.1.0>
[35.0.0]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v34.1.0...v35.0.0>
[34.1.0]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v34.0.0...v34.1.0>
[34.0.0]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v33.0.0...v34.0.0>
[33.0.0]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v32.0.1...v33.0.0>
[32.0.1]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v32.0.0...v32.0.1>
[32.0.0]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v31.1.0...v32.0.0>
[31.1.0]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v31.0.0...v31.1.0>
[31.0.0]: <https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v30.0.0...v31.0.0>
