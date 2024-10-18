# Changelog

All notable changes to this project will be documented in this file.
<!-- markdownlint-disable MD024 -->

## [Unreleased]
<!-- None < 2024-09-05 10:07:19+00:00 -->

### BLUEPRINTS

- [[#2585](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2585)] Apigee x foundations certificate manager ([apichick](https://github.com/apichick)) <!-- 2024-09-24 06:49:36+00:00 -->
- [[#2584](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2584)] README fixes to FAST docs ([skalolazka](https://github.com/skalolazka)) <!-- 2024-09-19 13:23:40+00:00 -->
- [[#2574](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2574)] Bump path-to-regexp and express in /blueprints/apigee/apigee-x-foundations/functions/instance-monitor ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-09-18 08:21:22+00:00 -->
- [[#2573](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2573)] Bump path-to-regexp and express in /blueprints/gke/binauthz/image ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2024-09-18 08:09:06+00:00 -->
- [[#2536](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2536)] **incompatible change:** Add support for google provider 6.x ([sruffilli](https://github.com/sruffilli)) <!-- 2024-09-05 10:35:59+00:00 -->

### FAST

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

- [[#2599](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2599)] Alloydb variables refactor ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-10-06 09:49:16+00:00 -->
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
- [[#2483](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2483)] Add boostrap output with log destination ids ([juliocc](https://github.com/juliocc)) <!-- 2024-08-08 14:23:38+00:00 -->
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
- [[#2175](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2175)] feat(gke-cluster-standard): Set optionnal `default_node_pool` configuration ([anthonyhaussman](https://github.com/anthonyhaussman)) <!-- 2024-03-26 17:05:35+00:00 -->
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

## [30.0.0] - 2024-03-20
<!-- 2024-03-20 13:57:56+00:00 < 2024-01-24 19:15:39+00:00 -->

### BLUEPRINTS

- [[#2141](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2141)] Dataproc module cleanup & fixes ([wiktorn](https://github.com/wiktorn)) <!-- 2024-03-11 10:05:33+00:00 -->
- [[#2131](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2131)] Introduce mandatory OWNERS file for blueprint maintainership ([juliocc](https://github.com/juliocc)) <!-- 2024-03-08 08:40:46+00:00 -->
- [[#2133](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2133)] Updated diagram to better reflect code naming. ([bswenka](https://github.com/bswenka)) <!-- 2024-03-06 19:23:37+00:00 -->
- [[#2135](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2135)] Rename `modules/cloudsql-instance` deletion protection variables ([juliocc](https://github.com/juliocc)) <!-- 2024-03-06 10:44:55+00:00 -->
- [[#2119](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2119)] Fix phpipam blueprint ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-02-29 08:33:07+00:00 -->
- [[#2110](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2110)] Gitlab blueprint ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-02-27 17:36:46+00:00 -->
- [[#1843](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1843)] **incompatible change:** Factories refactor ([ludoo](https://github.com/ludoo)) <!-- 2024-02-26 10:16:52+00:00 -->
- [[#2105](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2105)] **incompatible change:** Enable shielded nodes by default on GKE mt blueprint and FAST stage ([ludoo](https://github.com/ludoo)) <!-- 2024-02-22 07:35:27+00:00 -->
- [[#2082](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2082)] Fix GKE multitenant blueprint roles ([ludoo](https://github.com/ludoo)) <!-- 2024-02-16 14:15:22+00:00 -->
- [[#2076](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2076)] Use Fabric modules in blueprints/networking/psc-glb-and-armor ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-15 20:57:47+00:00 -->
- [[#2075](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2075)] Updated path matchers to be more user friendly, added better test exa… ([bswenka](https://github.com/bswenka)) <!-- 2024-02-15 17:27:26+00:00 -->
- [[#2079](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2079)] Format python files in blueprints ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-02-15 08:37:49+00:00 -->
- [[#2071](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2071)] Bswenka/psc glb and armor 2 producers ([bswenka](https://github.com/bswenka)) <!-- 2024-02-14 15:40:51+00:00 -->
- [[#2072](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2072)] Fix e2e tests - vertex mlops and net-address ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-13 06:40:31+00:00 -->
- [[#2064](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2064)] **incompatible change:** Extend FAST to support different principal types ([ludoo](https://github.com/ludoo)) <!-- 2024-02-12 13:35:30+00:00 -->
- [[#2058](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2058)] glb and armor subnet fix ([bswenka](https://github.com/bswenka)) <!-- 2024-02-09 10:41:14+00:00 -->
- [[#2061](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2061)] HA MySQL cluster deployment on GKE ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-09 10:23:35+00:00 -->
- [[#2059](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2059)] GKE stateful blueprints ([juliocc](https://github.com/juliocc)) <!-- 2024-02-08 18:28:41+00:00 -->
- [[#2036](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2036)] Shielded nodes and custom service account in FAST GKE stage and blueprint (CSPR-related) ([ludoo](https://github.com/ludoo)) <!-- 2024-02-01 15:16:00+00:00 -->
- [[#2016](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2016)] **incompatible change:** Ensure data platform service accounts meet FAST requirements ([ludoo](https://github.com/ludoo)) <!-- 2024-01-28 13:00:33+00:00 -->

### DOCUMENTATION

- [[#2143](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2143)] Update README.md (Fixed typos in /cloud-foundation-fabric/tree/master/blueprints/cloud-operations) ([Tianyou3](https://github.com/Tianyou3)) <!-- 2024-03-10 14:25:12+00:00 -->
- [[#2131](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2131)] Introduce mandatory OWNERS file for blueprint maintainership ([juliocc](https://github.com/juliocc)) <!-- 2024-03-08 08:40:46+00:00 -->
- [[#2138](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2138)] Updating README.md file for fixing some typo ([NayeemShaMd](https://github.com/NayeemShaMd)) <!-- 2024-03-07 15:20:51+00:00 -->
- [[#2136](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2136)] Update FAST state IAM files ([ludoo](https://github.com/ludoo)) <!-- 2024-03-06 23:08:09+00:00 -->
- [[#2134](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2134)] **incompatible change:** Add links to factories doc ([ludoo](https://github.com/ludoo)) <!-- 2024-03-06 07:25:43+00:00 -->
- [[#2120](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2120)] Implement GKE patterns naming conventions ([juliocc](https://github.com/juliocc)) <!-- 2024-02-29 06:57:22+00:00 -->
- [[#2110](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2110)] Gitlab blueprint ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-02-27 17:36:46+00:00 -->
- [[#1843](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1843)] **incompatible change:** Factories refactor ([ludoo](https://github.com/ludoo)) <!-- 2024-02-26 10:16:52+00:00 -->
- [[#2094](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2094)] update README to add analytics hub module ([thinhha](https://github.com/thinhha)) <!-- 2024-02-19 16:07:57+00:00 -->
- [[#2060](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2060)] Data catalog Tag module ([lcaggio](https://github.com/lcaggio)) <!-- 2024-02-13 16:24:17+00:00 -->
- [[#2064](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2064)] **incompatible change:** Extend FAST to support different principal types ([ludoo](https://github.com/ludoo)) <!-- 2024-02-12 13:35:30+00:00 -->
- [[#2061](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2061)] HA MySQL cluster deployment on GKE ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-09 10:23:35+00:00 -->
- [[#2059](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2059)] GKE stateful blueprints ([juliocc](https://github.com/juliocc)) <!-- 2024-02-08 18:28:41+00:00 -->
- [[#2013](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2013)] Add Tag Template module ([lcaggio](https://github.com/lcaggio)) <!-- 2024-01-27 11:30:21+00:00 -->

### FAST

- [[#2139](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2139)] Logging updates ([juliocc](https://github.com/juliocc)) <!-- 2024-03-08 09:07:13+00:00 -->
- [[#2115](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2115)] **incompatible change:** Align resource names in FAST networking stages ([ludoo](https://github.com/ludoo)) <!-- 2024-02-29 06:45:19+00:00 -->
- [[#2112](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2112)] Add support for billing budgets to project factory ([ludoo](https://github.com/ludoo)) <!-- 2024-02-27 18:13:49+00:00 -->
- [[#1843](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1843)] **incompatible change:** Factories refactor ([ludoo](https://github.com/ludoo)) <!-- 2024-02-26 10:16:52+00:00 -->
- [[#2105](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2105)] **incompatible change:** Enable shielded nodes by default on GKE mt blueprint and FAST stage ([ludoo](https://github.com/ludoo)) <!-- 2024-02-22 07:35:27+00:00 -->
- [[#2101](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2101)] Make all project_parent_ids fields optional ([juliocc](https://github.com/juliocc)) <!-- 2024-02-20 15:21:56+00:00 -->
- [[#2086](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2086)] Support domainless orgs in FAST ([ludoo](https://github.com/ludoo)) <!-- 2024-02-19 08:29:37+00:00 -->
- [[#2077](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2077)] **incompatible change:** Add workforce_identity_federation in 0-bootstrap ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-02-14 23:10:24+00:00 -->
- [[#2064](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2064)] **incompatible change:** Extend FAST to support different principal types ([ludoo](https://github.com/ludoo)) <!-- 2024-02-12 13:35:30+00:00 -->
- [[#2065](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2065)] Fix imports of org policies ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-11 06:22:11+00:00 -->
- [[#2057](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2057)] Postpone setting essential contacts until provisioning using SA ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-07 19:08:44+00:00 -->
- [[#2056](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2056)] import default org-level org-policies  ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-07 16:25:11+00:00 -->
- [[#2050](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2050)] Enable additional recommended org policies ([juliocc](https://github.com/juliocc)) <!-- 2024-02-05 09:46:37+00:00 -->
- [[#2041](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2041)] Leverage net-vpc module for DNS logging in FAST ([ludoo](https://github.com/ludoo)) <!-- 2024-02-03 07:16:00+00:00 -->
- [[#2038](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2038)] Make Cloud NAT creation optional in FAST net stages. ([juliocc](https://github.com/juliocc)) <!-- 2024-02-02 09:58:17+00:00 -->
- [[#2036](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2036)] Shielded nodes and custom service account in FAST GKE stage and blueprint (CSPR-related) ([ludoo](https://github.com/ludoo)) <!-- 2024-02-01 15:16:00+00:00 -->
- [[#2033](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2033)] Add DNS query logging to FAST net stages ([juliocc](https://github.com/juliocc)) <!-- 2024-01-31 12:44:51+00:00 -->
- [[#2032](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2032)] Selectively enable logging in FAST and firewall policy module rules (CSPR-related) ([ludoo](https://github.com/ludoo)) <!-- 2024-01-31 08:50:35+00:00 -->
- [[#2031](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2031)] Clarify relationship with checklist groups in FAST bootstrap docs ([ludoo](https://github.com/ludoo)) <!-- 2024-01-31 07:51:21+00:00 -->
- [[#2030](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2030)] logging for default ingress rules in FAST (CSPR-related) ([juliocc](https://github.com/juliocc)) <!-- 2024-01-30 16:53:01+00:00 -->
- [[#2019](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2019)] Fix sourcerepo templates and concat call ([juliocc](https://github.com/juliocc)) <!-- 2024-01-30 10:46:34+00:00 -->
- [[#2016](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2016)] **incompatible change:** Ensure data platform service accounts meet FAST requirements ([ludoo](https://github.com/ludoo)) <!-- 2024-01-28 13:00:33+00:00 -->
- [[#2014](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2014)] Enforce trusted image projects constraint in FAST bootstrap (CSPR-related) ([ludoo](https://github.com/ludoo)) <!-- 2024-01-26 10:14:45+00:00 -->
- [[#2010](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2010)] Add support for essential contacts to FAST (CSPR-related) ([ludoo](https://github.com/ludoo)) <!-- 2024-01-25 11:20:14+00:00 -->

### MODULES

- [[#2162](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2162)] Support automation/controlling projects and resources in project factory ([ludoo](https://github.com/ludoo)) <!-- 2024-03-19 15:50:07+00:00 -->
- [[#2152](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2152)] Add folder factory to project-factory module ([juliocc](https://github.com/juliocc)) <!-- 2024-03-14 12:03:42+00:00 -->
- [[#2141](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2141)] Dataproc module cleanup & fixes ([wiktorn](https://github.com/wiktorn)) <!-- 2024-03-11 10:05:33+00:00 -->
- [[#2142](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2142)] Adds bfd and md5 auth support to google_compute_router_peer ([sruffilli](https://github.com/sruffilli)) <!-- 2024-03-10 13:06:49+00:00 -->
- [[#2139](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2139)] Logging updates ([juliocc](https://github.com/juliocc)) <!-- 2024-03-08 09:07:13+00:00 -->
- [[#2135](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2135)] Rename `modules/cloudsql-instance` deletion protection variables ([juliocc](https://github.com/juliocc)) <!-- 2024-03-06 10:44:55+00:00 -->
- [[#2134](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2134)] **incompatible change:** Add links to factories doc ([ludoo](https://github.com/ludoo)) <!-- 2024-03-06 07:25:43+00:00 -->
- [[#2130](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2130)] **incompatible change:** Add support for service account IAM variables to pf ([ludoo](https://github.com/ludoo)) <!-- 2024-03-05 12:13:02+00:00 -->
- [[#2129](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2129)] Remove ignore_changes as terraform-provider-google#16804 is closed ([wiktorn](https://github.com/wiktorn)) <!-- 2024-03-05 07:11:07+00:00 -->
- [[#2125](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2125)] Add support for PSC network attachments and interfaces in modules ([ludoo](https://github.com/ludoo)) <!-- 2024-03-04 09:12:11+00:00 -->
- [[#2124](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2124)] Update docs about role automatically granted to dataform SA ([wiktorn](https://github.com/wiktorn)) <!-- 2024-03-04 06:47:26+00:00 -->
- [[#2122](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2122)] Define service attachment interface for lb modules and implement in internal LBs ([ludoo](https://github.com/ludoo)) <!-- 2024-03-02 18:36:30+00:00 -->
- [[#2121](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2121)] **incompatible change:** enabling dataform service agent upon activating the API ([marcjwo](https://github.com/marcjwo)) <!-- 2024-02-29 16:27:32+00:00 -->
- [[#2118](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2118)] Add https security to cloud-functions-v1 module ([mibelbahri](https://github.com/mibelbahri)) <!-- 2024-02-28 20:20:56+00:00 -->
- [[#2112](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2112)] Add support for billing budgets to project factory ([ludoo](https://github.com/ludoo)) <!-- 2024-02-27 18:13:49+00:00 -->
- [[#2111](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2111)] Fix pathexpand in firewall policy module ([ludoo](https://github.com/ludoo)) <!-- 2024-02-26 15:52:41+00:00 -->
- [[#1843](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1843)] **incompatible change:** Factories refactor ([ludoo](https://github.com/ludoo)) <!-- 2024-02-26 10:16:52+00:00 -->
- [[#2107](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2107)] Time zone support for CloudSQL SQL Server ([spica29](https://github.com/spica29)) <!-- 2024-02-25 19:49:14+00:00 -->
- [[#2100](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2100)] Module Data Catalog Tag - Add support for types ([lcaggio](https://github.com/lcaggio)) <!-- 2024-02-22 10:51:54+00:00 -->
- [[#2104](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2104)] Fix datacalog type of kubernetes_software_config.component_version and properties ([SalehElnagarSecurrency](https://github.com/SalehElnagarSecurrency)) <!-- 2024-02-22 07:23:39+00:00 -->
- [[#2090](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2090)] add session affinity values: "GENERATED_COOKIE", "HEADER_FIELD", "HTTP_COOKIE" to variables-backend-service.tf ([tamartayar](https://github.com/tamartayar)) <!-- 2024-02-21 09:04:10+00:00 -->
- [[#2102](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2102)] Allow projects as destinations for log sinks ([juliocc](https://github.com/juliocc)) <!-- 2024-02-21 07:41:13+00:00 -->
- [[#2098](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2098)] Fix cors policy type in lb app ext modules ([ludoo](https://github.com/ludoo)) <!-- 2024-02-20 07:17:25+00:00 -->
- [[#2097](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2097)] Fix #2095 for other types of load balancers ([juliocc](https://github.com/juliocc)) <!-- 2024-02-19 21:33:25+00:00 -->
- [[#2096](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2096)] Do not convert route rules to set ([juliocc](https://github.com/juliocc)) <!-- 2024-02-19 21:14:03+00:00 -->
- [[#2087](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2087)] add analytics hub module ([thinhha](https://github.com/thinhha)) <!-- 2024-02-19 15:55:00+00:00 -->
- [[#2091](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2091)] Accept email in service account module name ([ludoo](https://github.com/ludoo)) <!-- 2024-02-19 12:43:05+00:00 -->
- [[#1954](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1954)] Add support for Cloud Run v2 jobs ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-18 13:57:34+00:00 -->
- [[#2083](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2083)] Fix data-catalog tag module ([lcaggio](https://github.com/lcaggio)) <!-- 2024-02-17 09:56:18+00:00 -->
- [[#2081](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2081)] VPC-SC module factories ([ludoo](https://github.com/ludoo)) <!-- 2024-02-17 07:02:16+00:00 -->
- [[#2060](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2060)] Data catalog Tag module ([lcaggio](https://github.com/lcaggio)) <!-- 2024-02-13 16:24:17+00:00 -->
- [[#2064](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2064)] **incompatible change:** Extend FAST to support different principal types ([ludoo](https://github.com/ludoo)) <!-- 2024-02-12 13:35:30+00:00 -->
- [[#2062](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2062)] Add Tags in project output. ([lcaggio](https://github.com/lcaggio)) <!-- 2024-02-09 09:42:18+00:00 -->
- [[#2056](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2056)] import default org-level org-policies  ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-07 16:25:11+00:00 -->
- [[#2053](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2053)] Added destroy_scheduled_duration variable ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2024-02-07 15:47:50+00:00 -->
- [[#2051](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2051)] fix: auto_provisioning_defaults is not really optional ([kumadee](https://github.com/kumadee)) <!-- 2024-02-06 06:09:13+00:00 -->
- [[#2035](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2035)] Fix dnssec_config issue on state off ([haraldhaas](https://github.com/haraldhaas)) <!-- 2024-02-01 06:53:33+00:00 -->
- [[#2030](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2030)] logging for default ingress rules in FAST (CSPR-related) ([juliocc](https://github.com/juliocc)) <!-- 2024-01-30 16:53:01+00:00 -->
- [[#2008](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2008)] Updated the DataQualitySpec for Dataplex Datascan ([shourya116](https://github.com/shourya116)) <!-- 2024-01-30 15:14:50+00:00 -->
- [[#2027](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2027)] Tag Template - Fix readme tests ([lcaggio](https://github.com/lcaggio)) <!-- 2024-01-30 11:04:47+00:00 -->
- [[#2015](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2015)] Fix typo in logging sinks implementation ([ludoo](https://github.com/ludoo)) <!-- 2024-01-28 09:27:28+00:00 -->
- [[#2013](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2013)] Add Tag Template module ([lcaggio](https://github.com/lcaggio)) <!-- 2024-01-27 11:30:21+00:00 -->
- [[#2012](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2012)] Add support for target_resources to net-firewall-policy module ([bcorbitt-ps](https://github.com/bcorbitt-ps)) <!-- 2024-01-25 17:56:17+00:00 -->
- [[#2002](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2002)] Fixes and additional support for ssl_mode for CloudSQL module ([spica29](https://github.com/spica29)) <!-- 2024-01-25 15:29:08+00:00 -->
- [[#2010](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2010)] Add support for essential contacts to FAST (CSPR-related) ([ludoo](https://github.com/ludoo)) <!-- 2024-01-25 11:20:14+00:00 -->

### TOOLS

- [[#2154](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2154)] Projects data source e2e tests ([dibaskar-google](https://github.com/dibaskar-google)) <!-- 2024-03-15 22:58:11+00:00 -->
- [[#2151](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2151)] Kms e2e tests ([dibaskar-google](https://github.com/dibaskar-google)) <!-- 2024-03-13 10:31:21+00:00 -->
- [[#2149](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2149)] Cloudnat E-2-E Tests ([Lorioux](https://github.com/Lorioux)) <!-- 2024-03-11 15:47:11+00:00 -->
- [[#2147](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2147)] Add test reports to checks ([wiktorn](https://github.com/wiktorn)) <!-- 2024-03-11 09:54:35+00:00 -->
- [[#2144](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2144)] Update actions to latest versions ([juliocc](https://github.com/juliocc)) <!-- 2024-03-11 08:31:16+00:00 -->
- [[#2136](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2136)] Update FAST state IAM files ([ludoo](https://github.com/ludoo)) <!-- 2024-03-06 23:08:09+00:00 -->
- [[#2132](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2132)] feat: add e2e test for compute-mig module ([andybubu](https://github.com/andybubu)) <!-- 2024-03-06 20:30:20+00:00 -->
- [[#2118](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2118)] Add https security to cloud-functions-v1 module ([mibelbahri](https://github.com/mibelbahri)) <!-- 2024-02-28 20:20:56+00:00 -->
- [[#1843](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1843)] **incompatible change:** Factories refactor ([ludoo](https://github.com/ludoo)) <!-- 2024-02-26 10:16:52+00:00 -->
- [[#2109](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2109)] Once again fix e2e tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-23 18:21:39+00:00 -->
- [[#2108](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2108)] Fix too long project names in e2e tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-23 10:41:58+00:00 -->
- [[#1954](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1954)] Add support for Cloud Run v2 jobs ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-18 13:57:34+00:00 -->
- [[#2079](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2079)] Format python files in blueprints ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-02-15 08:37:49+00:00 -->
- [[#2056](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2056)] import default org-level org-policies  ([wiktorn](https://github.com/wiktorn)) <!-- 2024-02-07 16:25:11+00:00 -->
- [[#2039](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2039)] Remove unused tfeditor ([juliocc](https://github.com/juliocc)) <!-- 2024-02-02 10:14:14+00:00 -->

## [29.0.0] - 2024-01-24

### BLUEPRINTS

- [[#2004](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2004)] **incompatible change:** Remove default region for Cloud Function and Cloud Run ([wiktorn](https://github.com/wiktorn)) <!-- 2024-01-24 10:23:40+00:00 -->
- [[#1977](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1977)] Add example to FAST GKE stage, streamline GKE Hub module variables and usage ([ludoo](https://github.com/ludoo)) <!-- 2024-01-20 10:06:38+00:00 -->
- [[#1992](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1992)] Fix Data platform foundation ([lcaggio](https://github.com/lcaggio)) <!-- 2024-01-20 07:49:47+00:00 -->
- [[#1976](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1976)] Network dashboard - fixing 2 bugs: overriden variable and page token … ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2024-01-15 13:28:17+00:00 -->
- [[#1819](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1819)] Serverless networking program ([juliodiez](https://github.com/juliodiez)) <!-- 2024-01-05 21:03:34+00:00 -->
- [[#1952](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1952)] Composer blueprints improvements ([wiktorn](https://github.com/wiktorn)) <!-- 2023-12-29 11:09:16+00:00 -->
- [[#1939](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1939)] Networking Sandbox Blueprint ([sruffilli](https://github.com/sruffilli)) <!-- 2023-12-21 16:50:39+00:00 -->
- [[#1942](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1942)] Blueprints naming convention update ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-12-21 16:02:25+00:00 -->
- [[#1936](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1936)] Move squid to __need_fixing ([sruffilli](https://github.com/sruffilli)) <!-- 2023-12-19 14:27:37+00:00 -->
- [[#1931](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1931)] Quota monitor blueprint: don't fail quota fetch on deleted project ([ludoo](https://github.com/ludoo)) <!-- 2023-12-15 19:20:49+00:00 -->
- [[#1930](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1930)] Allow granting network user role on host project from project module and factory ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-12-15 13:39:21+00:00 -->
- [[#1924](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1924)] Update quota monitor blueprint to support project discovery ([maunope](https://github.com/maunope)) <!-- 2023-12-12 18:17:01+00:00 -->
- [[#1912](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1912)] **incompatible change:** Custom role factories for organization and project modules ([ludoo](https://github.com/ludoo)) <!-- 2023-12-11 14:16:39+00:00 -->
- [[#1916](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1916)] Add triggerer configuration for Composer ([wiktorn](https://github.com/wiktorn)) <!-- 2023-12-11 11:54:49+00:00 -->
- [[#1907](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1907)] Add support for subnet-level service network user grants to project module, improve docs ([ludoo](https://github.com/ludoo)) <!-- 2023-12-07 09:07:48+00:00 -->
- [[#1871](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1871)] Added workstation-cluster module ([apichick](https://github.com/apichick)) <!-- 2023-11-30 06:15:37+00:00 -->
- [[#1886](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1886)] Fixes to F5 blueprint docs ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-11-24 18:45:38+00:00 -->
- [[#1874](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1874)] Added PSC support to CloudSQL Module ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-11-24 14:47:45+00:00 -->
- [[#1883](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1883)] F5 deployment blueprint ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-11-24 13:02:34+00:00 -->

### DOCUMENTATION

- [[#2001](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2001)] Marcwo/dataform module ([marcjwo](https://github.com/marcjwo)) <!-- 2024-01-24 16:13:22+00:00 -->
- [[#1981](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1981)] Added Cross-region internal application load balancer module ([apichick](https://github.com/apichick)) <!-- 2024-01-16 17:10:08+00:00 -->
- [[#1819](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1819)] Serverless networking program ([juliodiez](https://github.com/juliodiez)) <!-- 2024-01-05 21:03:34+00:00 -->
- [[#1959](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1959)] net-lb-app-ext example fixes ([juliocc](https://github.com/juliocc)) <!-- 2024-01-05 13:38:30+00:00 -->
- [[#1899](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1899)] Read-only service accounts for automation and CI/CD ([ludoo](https://github.com/ludoo)) <!-- 2023-12-27 11:33:16+00:00 -->
- [[#1902](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1902)] First version of Cloud Run module v2 ([juliodiez](https://github.com/juliodiez)) <!-- 2023-12-26 18:19:16+00:00 -->
- [[#1949](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1949)] Update REFERENCES.md ([juliodiez](https://github.com/juliodiez)) <!-- 2023-12-26 10:57:15+00:00 -->
- [[#1939](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1939)] Networking Sandbox Blueprint ([sruffilli](https://github.com/sruffilli)) <!-- 2023-12-21 16:50:39+00:00 -->
- [[#1942](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1942)] Blueprints naming convention update ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-12-21 16:02:25+00:00 -->
- [[#1936](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1936)] Move squid to __need_fixing ([sruffilli](https://github.com/sruffilli)) <!-- 2023-12-19 14:27:37+00:00 -->
- [[#1890](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1890)] Use TFTEST_E2E_ instead of TF_VAR variables ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-30 19:03:59+00:00 -->
- [[#1871](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1871)] Added workstation-cluster module ([apichick](https://github.com/apichick)) <!-- 2023-11-30 06:15:37+00:00 -->
- [[#1883](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1883)] F5 deployment blueprint ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-11-24 13:02:34+00:00 -->

### FAST

- [[#2009](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2009)] Tighten up security of automation project (CSPR-related) ([ludoo](https://github.com/ludoo)) <!-- 2024-01-24 18:40:36+00:00 -->
- [[#2000](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2000)] Checklist attribution bucket ([ludoo](https://github.com/ludoo)) <!-- 2024-01-23 11:32:15+00:00 -->
- [[#1997](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1997)] Update checklist parsing for top-level key ([ludoo](https://github.com/ludoo)) <!-- 2024-01-23 06:34:03+00:00 -->
- [[#1992](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1992)] Fix Data platform foundation ([lcaggio](https://github.com/lcaggio)) <!-- 2024-01-20 07:49:47+00:00 -->
- [[#1969](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1969)] Integrate checklist data in FAST ([ludoo](https://github.com/ludoo)) <!-- 2024-01-18 04:45:30+00:00 -->
- [[#1967](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1967)] Add locations on terraform.tfvars.sample for bootstrap stage ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2024-01-09 07:32:28+00:00 -->
- [[#1899](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1899)] Read-only service accounts for automation and CI/CD ([ludoo](https://github.com/ludoo)) <!-- 2023-12-27 11:33:16+00:00 -->
- [[#1945](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1945)] Fix GitHub CI/CD provider ([ludoo](https://github.com/ludoo)) <!-- 2023-12-21 17:10:50+00:00 -->
- [[#1943](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1943)] Revert "Add debug step for JWT tokens" ([ludoo](https://github.com/ludoo)) <!-- 2023-12-21 13:50:28+00:00 -->
- [[#1940](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1940)] Add kernels.googleusercontent.com zone in dns response policy ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-12-20 10:18:11+00:00 -->
- [[#1938](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1938)] Add debug step for JWT tokens ([wiktorn](https://github.com/wiktorn)) <!-- 2023-12-20 08:26:55+00:00 -->
- [[#1932](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1932)] Simplify organization tags.tf locals ([juliocc](https://github.com/juliocc)) <!-- 2023-12-18 16:09:22+00:00 -->
- [[#1912](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1912)] **incompatible change:** Custom role factories for organization and project modules ([ludoo](https://github.com/ludoo)) <!-- 2023-12-11 14:16:39+00:00 -->
- [[#1900](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1900)] Patch Github actions ci google-github-actions/auth@v0 --> v2 ([ibrahimparvez2](https://github.com/ibrahimparvez2)) <!-- 2023-12-04 12:16:02+00:00 -->

### MODULES

- [[#2009](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2009)] Tighten up security of automation project (CSPR-related) ([ludoo](https://github.com/ludoo)) <!-- 2024-01-24 18:40:36+00:00 -->
- [[#2001](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2001)] Marcwo/dataform module ([marcjwo](https://github.com/marcjwo)) <!-- 2024-01-24 16:13:22+00:00 -->
- [[#2005](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2005)] Fix named ranges behaviour if cidr_tpl_file variable not provided. ([miromichalicka](https://github.com/miromichalicka)) <!-- 2024-01-24 11:18:11+00:00 -->
- [[#2004](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2004)] **incompatible change:** Remove default region for Cloud Function and Cloud Run ([wiktorn](https://github.com/wiktorn)) <!-- 2024-01-24 10:23:40+00:00 -->
- [[#1993](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1993)] Fix DNS E2E test + add one to net-lb-app-int-cross-region ([wiktorn](https://github.com/wiktorn)) <!-- 2024-01-23 15:34:45+00:00 -->
- [[#1999](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1999)] Added Enabled Kubernetes Beta APIs feature ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2024-01-23 11:09:22+00:00 -->
- [[#1996](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1996)] Fix factory default value for rule ports in firewall policy module ([ludoo](https://github.com/ludoo)) <!-- 2024-01-21 11:38:24+00:00 -->
- [[#1994](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1994)] DNS response policies e2e changes ([dibaskar-google](https://github.com/dibaskar-google)) <!-- 2024-01-20 18:47:02+00:00 -->
- [[#1977](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1977)] Add example to FAST GKE stage, streamline GKE Hub module variables and usage ([ludoo](https://github.com/ludoo)) <!-- 2024-01-20 10:06:38+00:00 -->
- [[#1987](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1987)] Specify `docker_repository` field for google_cloudfunctions2_function ([kumadee](https://github.com/kumadee)) <!-- 2024-01-20 09:40:27+00:00 -->
- [[#1990](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1990)] Fixed README and test for DNS module ([apichick](https://github.com/apichick)) <!-- 2024-01-19 09:12:20+00:00 -->
- [[#1988](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1988)] Added health checked targets for geo routing policy in dns module ([apichick](https://github.com/apichick)) <!-- 2024-01-18 17:46:46+00:00 -->
- [[#1979](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1979)] feat: enable mtls on external application application load balancer ([Tazminia](https://github.com/Tazminia)) <!-- 2024-01-17 06:24:54+00:00 -->
- [[#1982](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1982)] Add resource manager tags support for instance template ([LucaPrete](https://github.com/LucaPrete)) <!-- 2024-01-16 17:40:15+00:00 -->
- [[#1981](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1981)] Added Cross-region internal application load balancer module ([apichick](https://github.com/apichick)) <!-- 2024-01-16 17:10:08+00:00 -->
- [[#1980](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1980)] Proper validation of empty string value in identity_type ([viliampucik](https://github.com/viliampucik)) <!-- 2024-01-16 09:28:30+00:00 -->
- [[#1978](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1978)] Fix identity_type ([viliampucik](https://github.com/viliampucik)) <!-- 2024-01-15 20:40:06+00:00 -->
- [[#1970](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1970)] Add support for service_external_ips_config to GKE cluster modules ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2024-01-12 10:50:54+00:00 -->
- [[#1968](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1968)] use provided SA for cloud function v2 trigger ([juliocc](https://github.com/juliocc)) <!-- 2024-01-08 16:39:01+00:00 -->
- [[#1966](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1966)] Support for ANY_USER_ACCOUNT in module vpc-sc egress rule. ([xjantoth](https://github.com/xjantoth)) <!-- 2024-01-08 13:23:07+00:00 -->
- [[#1964](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1964)] Use fixtures in net-lb-ext ([wiktorn](https://github.com/wiktorn)) <!-- 2024-01-06 16:09:49+00:00 -->
- [[#1958](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1958)] Create bigtable service identity with project if api is enabled ([steenblik](https://github.com/steenblik)) <!-- 2024-01-06 15:38:08+00:00 -->
- [[#1963](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1963)] net-address end-to-end tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-01-06 13:02:52+00:00 -->
- [[#1962](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1962)] Add end-to-end tests for net-lb-app-ext-regional ([wiktorn](https://github.com/wiktorn)) <!-- 2024-01-06 11:05:53+00:00 -->
- [[#1892](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1892)] New module for external regional application load balancer ([juliocc](https://github.com/juliocc)) <!-- 2024-01-05 15:59:27+00:00 -->
- [[#1960](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1960)] Add PNA support to Service Directory module ([stribioli](https://github.com/stribioli)) <!-- 2024-01-05 15:19:33+00:00 -->
- [[#1957](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1957)] Add e2e test for net_lb_app_ext module ([andybubu](https://github.com/andybubu)) <!-- 2024-01-05 09:02:23+00:00 -->
- [[#1956](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1956)] Support CMEK encryption on Bigtable instances. ([steenblik](https://github.com/steenblik)) <!-- 2024-01-05 08:29:37+00:00 -->
- [[#1902](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1902)] First version of Cloud Run module v2 ([juliodiez](https://github.com/juliodiez)) <!-- 2023-12-26 18:19:16+00:00 -->
- [[#1944](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1944)] Dns e2e ([dibaskar-google](https://github.com/dibaskar-google)) <!-- 2023-12-23 10:29:32+00:00 -->
- [[#1948](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1948)] Fix GCVE network policy ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-12-22 10:29:44+00:00 -->
- [[#1947](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1947)] GCVE: add network policy configuration ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-12-22 10:02:12+00:00 -->
- [[#1946](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1946)] Minor fix to GCVE module readme ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-12-21 17:29:30+00:00 -->
- [[#1941](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1941)] Use new resources in GCVE module, bump provider versions ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-12-21 13:23:38+00:00 -->
- [[#1936](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1936)] Move squid to __need_fixing ([sruffilli](https://github.com/sruffilli)) <!-- 2023-12-19 14:27:37+00:00 -->
- [[#1935](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1935)] E2E tests fixes ([wiktorn](https://github.com/wiktorn)) <!-- 2023-12-19 10:01:03+00:00 -->
- [[#1933](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1933)] Add project-scoped secure tags ([juliocc](https://github.com/juliocc)) <!-- 2023-12-18 17:24:06+00:00 -->
- [[#1932](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1932)] Simplify organization tags.tf locals ([juliocc](https://github.com/juliocc)) <!-- 2023-12-18 16:09:22+00:00 -->
- [[#1930](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1930)] Allow granting network user role on host project from project module and factory ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-12-15 13:39:21+00:00 -->
- [[#1928](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1928)] **incompatible change:** Fix health check autocreation and id output in passthrough LB modules ([ludoo](https://github.com/ludoo)) <!-- 2023-12-13 23:39:55+00:00 -->
- [[#1926](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1926)] Add support for policy based routes to net-vpc ([sruffilli](https://github.com/sruffilli)) <!-- 2023-12-13 15:19:41+00:00 -->
- [[#1905](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1905)] gke-cluster-standard : Support upgrade_settings for node auto provisioner ([noony](https://github.com/noony)) <!-- 2023-12-12 19:17:52+00:00 -->
- [[#1923](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1923)] Removed deprecated variable and added labels ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-12-12 18:32:48+00:00 -->
- [[#1922](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1922)] can_ip_forward in simple-nva examples ([sruffilli](https://github.com/sruffilli)) <!-- 2023-12-12 13:09:59+00:00 -->
- [[#1921](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1921)] Sync tf version to version used by tests ([wiktorn](https://github.com/wiktorn)) <!-- 2023-12-12 08:43:09+00:00 -->
- [[#1920](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1920)] Bump tf version ([ludoo](https://github.com/ludoo)) <!-- 2023-12-12 08:19:47+00:00 -->
- [[#1918](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1918)] Added missing parameters in kubelet and linux node configuration ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-12-11 19:05:24+00:00 -->
- [[#1917](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1917)] Added the possibility to configure maintenance window and deny maintenance period in Cloud SQL module module ([francesco-pavan-huware](https://github.com/francesco-pavan-huware)) <!-- 2023-12-11 16:59:00+00:00 -->
- [[#1912](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1912)] **incompatible change:** Custom role factories for organization and project modules ([ludoo](https://github.com/ludoo)) <!-- 2023-12-11 14:16:39+00:00 -->
- [[#1909](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1909)] net_lb_ext module e2e and example testing changes ([dibaskar-google](https://github.com/dibaskar-google)) <!-- 2023-12-08 09:04:07+00:00 -->
- [[#1908](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1908)] README fixes for #1907 ([wiktorn](https://github.com/wiktorn)) <!-- 2023-12-07 10:05:27+00:00 -->
- [[#1906](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1906)] gke-cluster-standard : Set optional shielded_instance_config block in cluster_autoscaling.auto_provisioning_defaults ([noony](https://github.com/noony)) <!-- 2023-12-07 09:37:13+00:00 -->
- [[#1907](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1907)] Add support for subnet-level service network user grants to project module, improve docs ([ludoo](https://github.com/ludoo)) <!-- 2023-12-07 09:07:48+00:00 -->
- [[#1904](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1904)] gke-cluster-standard : Add possibility to enable image streaming feature at cluster level ([noony](https://github.com/noony)) <!-- 2023-12-07 05:36:22+00:00 -->
- [[#1903](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1903)] Enable sole tenancy (`node_affinities`) on compute_vm ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-12-05 17:05:23+00:00 -->
- [[#1901](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1901)] Add IPv6 to HA VPN module + test inventories ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-12-04 22:38:42+00:00 -->
- [[#1898](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1898)] Use unique names for logging buckets in examples ([wiktorn](https://github.com/wiktorn)) <!-- 2023-12-03 11:50:46+00:00 -->
- [[#1896](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1896)] e2e test fix for net-vpc-firewall module ([rthangaraju](https://github.com/rthangaraju)) <!-- 2023-12-01 12:50:56+00:00 -->
- [[#1895](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1895)] Add support for firewall tags to compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2023-12-01 11:27:38+00:00 -->
- [[#1891](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1891)] artifact-registry: Support cleanup policies ([noony](https://github.com/noony)) <!-- 2023-12-01 10:33:02+00:00 -->
- [[#1894](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1894)] e2e test fix for iam-service-account module ([rthangaraju](https://github.com/rthangaraju)) <!-- 2023-12-01 08:23:37+00:00 -->
- [[#1893](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1893)] E2E and examples tests for net-vpc module ([rthangaraju](https://github.com/rthangaraju)) <!-- 2023-11-30 16:00:56+00:00 -->
- [[#1861](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1861)] Added external data configuration support to BigQuery Module ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-11-30 13:33:51+00:00 -->
- [[#1871](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1871)] Added workstation-cluster module ([apichick](https://github.com/apichick)) <!-- 2023-11-30 06:15:37+00:00 -->
- [[#1874](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1874)] Added PSC support to CloudSQL Module ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-11-24 14:47:45+00:00 -->
- [[#1885](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1885)] Fixed envoy file, it has extra character that was preventing envoy to start ([apichick](https://github.com/apichick)) <!-- 2023-11-24 09:59:48+00:00 -->

### TOOLS

- [[#1985](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1985)] Better error reporting when missing setup for E2E tests ([wiktorn](https://github.com/wiktorn)) <!-- 2024-01-17 20:34:20+00:00 -->
- [[#1961](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1961)] Use zones b and c for MIG fixture ([juliocc](https://github.com/juliocc)) <!-- 2024-01-05 15:02:12+00:00 -->
- [[#1955](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1955)] Add version check to tools/lint.sh ([wiktorn](https://github.com/wiktorn)) <!-- 2023-12-30 08:09:10+00:00 -->
- [[#1914](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1914)] Allow per-module terraform fixtures ([juliocc](https://github.com/juliocc)) <!-- 2023-12-29 09:43:44+00:00 -->
- [[#1953](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1953)] Fix variable region ([andybubu](https://github.com/andybubu)) <!-- 2023-12-28 14:04:15+00:00 -->
- [[#1950](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1950)] Add version check ([wiktorn](https://github.com/wiktorn)) <!-- 2023-12-27 07:40:23+00:00 -->
- [[#1937](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1937)] Fix always succeding test ([wiktorn](https://github.com/wiktorn)) <!-- 2023-12-21 11:01:08+00:00 -->
- [[#1932](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1932)] Simplify organization tags.tf locals ([juliocc](https://github.com/juliocc)) <!-- 2023-12-18 16:09:22+00:00 -->
- [[#1890](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1890)] Use TFTEST_E2E_ instead of TF_VAR variables ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-30 19:03:59+00:00 -->

## [28.0.0] - 2023-11-24
<!-- 2023-11-24 09:21:21+00:00 < 2023-10-04 10:23:37+00:00 -->

### BLUEPRINTS

- [[#1882](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1882)] Fixes/improvements to F5 HA blueprint ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-11-23 15:15:48+00:00 -->
- [[#1787](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1787)] F5 blueprint ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-11-22 18:48:14+00:00 -->
- [[#1873](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1873)] Add DLP Service Agent role ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-20 14:34:28+00:00 -->
- [[#1859](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1859)] Net dash cfv2 ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2023-11-16 14:45:45+00:00 -->
- [[#1863](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1863)] End-to-end tests for Vertex blueprint ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-16 12:49:30+00:00 -->
- [[#1856](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1856)] Sql user features ([Francesco-cloud24](https://github.com/Francesco-cloud24)) <!-- 2023-11-13 09:27:14+00:00 -->
- [[#1739](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1739)] Added CMEK for Secret auto managed ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-11-10 15:45:47+00:00 -->
- [[#1848](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1848)] Dataproc module bug fix ([Francesco-cloud24](https://github.com/Francesco-cloud24)) <!-- 2023-11-09 15:48:29+00:00 -->
- [[#1851](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1851)] Support multilevel data and allow overriding project id in project factory ([ludoo](https://github.com/ludoo)) <!-- 2023-11-09 08:29:46+00:00 -->
- [[#1838](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1838)] Simplify #1836 fix, Avoid map-related casting errors in project factory ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-02 09:34:59+00:00 -->
- [[#1836](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1836)] **incompatible change:** Avoid map-related casting errors in project factory ([ludoo](https://github.com/ludoo)) <!-- 2023-11-02 07:24:51+00:00 -->
- [[#1832](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1832)] [Minimal Data Platform] Fix Landing and curated IAM ([lcaggio](https://github.com/lcaggio)) <!-- 2023-11-01 16:53:07+00:00 -->
- [[#1825](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1825)] Handling SQL IP address issue ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2023-10-30 16:26:07+00:00 -->
- [[#1821](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1821)] [net-address] enable ipv6 ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-10-28 13:36:31+00:00 -->
- [[#1814](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1814)] **incompatible change:** Allow specifying arbitrary project roles for service accounts in project factory ([ludoo](https://github.com/ludoo)) <!-- 2023-10-26 14:09:04+00:00 -->
- [[#1812](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1812)] Stop wrapping yamldecode with try() ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-25 14:16:05+00:00 -->
- [[#1806](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1806)] Updating network dashboard: fixing Cloud SQL problem, fixing 1 metric… ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2023-10-25 10:37:25+00:00 -->
- [[#1796](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1796)] Make extended shared vpc attributes optional in project factory ([ludoo](https://github.com/ludoo)) <!-- 2023-10-23 13:45:48+00:00 -->
- [[#1782](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1782)] Add upper cap to versions, update copyright notices ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-20 16:17:48+00:00 -->
- [[#1765](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1765)] Add support for dual stack and multiple forwarding rules to net-lb-int module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-10-17 09:30:35+00:00 -->
- [[#1748](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1748)] Bump golang.org/x/net from 0.7.0 to 0.17.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/restarter ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2023-10-12 05:41:41+00:00 -->
- [[#1747](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1747)] Bump golang.org/x/net from 0.7.0 to 0.17.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/healthchecker ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2023-10-12 05:21:10+00:00 -->
- [[#1735](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1735)] Make deletion protection consistent across all modules ([juliocc](https://github.com/juliocc)) <!-- 2023-10-05 15:31:08+00:00 -->

### DOCUMENTATION

- [[#1787](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1787)] F5 blueprint ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-11-22 18:48:14+00:00 -->
- [[#1832](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1832)] [Minimal Data Platform] Fix Landing and curated IAM ([lcaggio](https://github.com/lcaggio)) <!-- 2023-11-01 16:53:07+00:00 -->
- [[#1831](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1831)] Update wording in FAST and gcve module READMEs ([bluPhy](https://github.com/bluPhy)) <!-- 2023-10-31 15:54:19+00:00 -->
- [[#1782](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1782)] Add upper cap to versions, update copyright notices ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-20 16:17:48+00:00 -->
- [[#1773](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1773)] Add service usage consumer role to IaC SAs, refactor delegated grants in FAST ([ludoo](https://github.com/ludoo)) <!-- 2023-10-18 12:18:31+00:00 -->
- [[#1743](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1743)] Billing account module ([ludoo](https://github.com/ludoo)) <!-- 2023-10-15 15:02:50+00:00 -->

### FAST

- [[#1855](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1855)] Document `fast_features` ([juliocc](https://github.com/juliocc)) <!-- 2023-11-20 21:41:06+00:00 -->
- [[#1864](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1864)] End to end tests for GCS ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-16 12:36:21+00:00 -->
- [[#1836](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1836)] **incompatible change:** Avoid map-related casting errors in project factory ([ludoo](https://github.com/ludoo)) <!-- 2023-11-02 07:24:51+00:00 -->
- [[#1818](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1818)] FAST: rename VPC-related files to `net-*` ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-27 08:23:08+00:00 -->
- [[#1812](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1812)] Stop wrapping yamldecode with try() ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-25 14:16:05+00:00 -->
- [[#1810](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1810)] FAST: Add access transparency logs to the default sinks ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-24 20:09:01+00:00 -->
- [[#1809](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1809)] FAST: Add VPC serverless connector NAT ranges to hierarchical fw ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-24 19:46:04+00:00 -->
- [[#1811](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1811)] FAST: removed references to kms_defaults ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-24 19:18:08+00:00 -->
- [[#1802](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1802)] Less verbose project factory stage outputs ([ludoo](https://github.com/ludoo)) <!-- 2023-10-24 07:03:36+00:00 -->
- [[#1797](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1797)] Improve usage of optionals in FAST stage 2 VPN variables ([ludoo](https://github.com/ludoo)) <!-- 2023-10-23 13:23:30+00:00 -->
- [[#1788](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1788)] FAST: adds support for wif provider pubkey ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-21 16:52:19+00:00 -->
- [[#1782](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1782)] Add upper cap to versions, update copyright notices ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-20 16:17:48+00:00 -->
- [[#1780](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1780)] Add sink for workspace logs to bootstrap stage ([ludoo](https://github.com/ludoo)) <!-- 2023-10-19 14:51:02+00:00 -->
- [[#1775](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1775)] Add gcp org policy constraints file to bootstrap stage ([ludoo](https://github.com/ludoo)) <!-- 2023-10-18 18:21:17+00:00 -->
- [[#1773](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1773)] Add service usage consumer role to IaC SAs, refactor delegated grants in FAST ([ludoo](https://github.com/ludoo)) <!-- 2023-10-18 12:18:31+00:00 -->
- [[#1765](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1765)] Add support for dual stack and multiple forwarding rules to net-lb-int module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-10-17 09:30:35+00:00 -->
- [[#1760](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1760)] Add support for psa peered domains to fast stages ([ludoo](https://github.com/ludoo)) <!-- 2023-10-16 06:57:18+00:00 -->
- [[#1759](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1759)] Minor edits to FAST network stage READMEs ([ludoo](https://github.com/ludoo)) <!-- 2023-10-15 16:14:48+00:00 -->
- [[#1743](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1743)] Billing account module ([ludoo](https://github.com/ludoo)) <!-- 2023-10-15 15:02:50+00:00 -->
- [[#1735](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1735)] Make deletion protection consistent across all modules ([juliocc](https://github.com/juliocc)) <!-- 2023-10-05 15:31:08+00:00 -->
- [[#1734](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1734)] Update to lint.sh and wording to some tf ([bluPhy](https://github.com/bluPhy)) <!-- 2023-10-05 06:32:08+00:00 -->
- [[#1733](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1733)] Fix typo in FAST stage 2 README ([bluPhy](https://github.com/bluPhy)) <!-- 2023-10-04 22:22:44+00:00 -->

### MODULES

- [[#1884](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1884)] Fix failing E2E tests for folders ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-24 08:09:14+00:00 -->
- [[#1881](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1881)] Support boot disk KMS key in GKE cluster modules ([ludoo](https://github.com/ludoo)) <!-- 2023-11-23 11:52:14+00:00 -->
- [[#1879](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1879)] Output all neg ids in app lbs ([juliocc](https://github.com/juliocc)) <!-- 2023-11-23 07:41:31+00:00 -->
- [[#1878](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1878)] Fix permissions assignments ([flaprimo](https://github.com/flaprimo)) <!-- 2023-11-22 12:16:25+00:00 -->
- [[#1876](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1876)] Examples and E2e testing for folder module ([dibaskar-google](https://github.com/dibaskar-google)) <!-- 2023-11-22 09:25:11+00:00 -->
- [[#1869](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1869)] added missing sql parameters ([Francesco-cloud24](https://github.com/Francesco-cloud24)) <!-- 2023-11-20 21:27:59+00:00 -->
- [[#1868](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1868)] Fix/dlpagent ([ddaluka](https://github.com/ddaluka)) <!-- 2023-11-20 13:11:01+00:00 -->
- [[#1870](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1870)] End to end tests for Cloud Run + permadiff fixes ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-18 18:26:54+00:00 -->
- [[#1864](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1864)] End to end tests for GCS ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-16 12:36:21+00:00 -->
- [[#1860](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1860)] Organization module end-to-end tests ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-14 17:55:00+00:00 -->
- [[#1856](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1856)] Sql user features ([Francesco-cloud24](https://github.com/Francesco-cloud24)) <!-- 2023-11-13 09:27:14+00:00 -->
- [[#1858](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1858)] Removed options that are not applicable to this load balancer ([apichick](https://github.com/apichick)) <!-- 2023-11-13 07:08:26+00:00 -->
- [[#1739](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1739)] Added CMEK for Secret auto managed ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-11-10 15:45:47+00:00 -->
- [[#1845](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1845)] Extend `cluster_autoscaling` fields in gke-cluster-standard ([anthonyhaussman](https://github.com/anthonyhaussman)) <!-- 2023-11-10 11:39:51+00:00 -->
- [[#1848](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1848)] Dataproc module bug fix ([Francesco-cloud24](https://github.com/Francesco-cloud24)) <!-- 2023-11-09 15:48:29+00:00 -->
- [[#1847](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1847)] Fix validation and dynamic block for optional gpu_driver ([Gilfar](https://github.com/Gilfar)) <!-- 2023-11-08 13:49:56+00:00 -->
- [[#1846](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1846)] Add support for IAM to vpc sc module ([ludoo](https://github.com/ludoo)) <!-- 2023-11-08 10:27:44+00:00 -->
- [[#1844](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1844)] Allow disabling IAM for sink identity in resource manager modules ([apichick](https://github.com/apichick)) <!-- 2023-11-07 08:30:42+00:00 -->
- [[#1841](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1841)] Fix modules to support new Apigee X environment types ([Teodelas](https://github.com/Teodelas)) <!-- 2023-11-06 08:56:04+00:00 -->
- [[#1842](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1842)] Bump provider version to 5.6.0 ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-04 08:14:03+00:00 -->
- [[#1823](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1823)] Add end-to-end tests for project module ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-03 17:04:19+00:00 -->
- [[#1837](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1837)] Added envoy as SNI dynamic forward proxy to cloud-config-container ([apichick](https://github.com/apichick)) <!-- 2023-11-03 07:43:15+00:00 -->
- [[#1839](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1839)] Added create_before_destroy = true for self-managed certificates ([apichick](https://github.com/apichick)) <!-- 2023-11-02 14:14:45+00:00 -->
- [[#1833](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1833)] Net VPC Peering: added stack_type field ([cmalpe](https://github.com/cmalpe)) <!-- 2023-11-01 09:46:03+00:00 -->
- [[#1826](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1826)] Add public_access_prevention field to GCS module ([devuonocar](https://github.com/devuonocar)) <!-- 2023-10-31 10:11:31+00:00 -->
- [[#1817](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1817)] KMS module: Import job feature ([cmalpe](https://github.com/cmalpe)) <!-- 2023-10-30 15:25:57+00:00 -->
- [[#1822](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1822)] Billing budget factory ([ludoo](https://github.com/ludoo)) <!-- 2023-10-29 10:24:52+00:00 -->
- [[#1821](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1821)] [net-address] enable ipv6 ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-10-28 13:36:31+00:00 -->
- [[#1820](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1820)] Added iam_bindings and iam_bindings_additive to apigee module ([apichick](https://github.com/apichick)) <!-- 2023-10-27 18:08:18+00:00 -->
- [[#1813](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1813)] empty gpu sharing config fix ([ewojtach](https://github.com/ewojtach)) <!-- 2023-10-27 09:49:34+00:00 -->
- [[#1815](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1815)] Fix logic for default source range in firewall ingress rules ([ludoo](https://github.com/ludoo)) <!-- 2023-10-26 15:25:37+00:00 -->
- [[#1812](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1812)] Stop wrapping yamldecode with try() ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-25 14:16:05+00:00 -->
- [[#1750](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1750)] AI models support ([ewojtach](https://github.com/ewojtach)) <!-- 2023-10-25 09:42:37+00:00 -->
- [[#1798](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1798)] Fix Apigee add-ons configuration ([mwarm2](https://github.com/mwarm2)) <!-- 2023-10-25 07:37:45+00:00 -->
- [[#1808](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1808)] Allow setting `enable_private_nodes` in GKE nodepool pod range ([ludoo](https://github.com/ludoo)) <!-- 2023-10-24 17:34:04+00:00 -->
- [[#1805](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1805)] net-lb-ext: Add option to set IPv6 subnetwork for IPv6 external fw rules ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-10-24 13:37:33+00:00 -->
- [[#1804](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1804)] compute-vm: remove old todo ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-10-24 10:45:54+00:00 -->
- [[#1803](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1803)] use the repository format in the image_path output ([Tutuchan](https://github.com/Tutuchan)) <!-- 2023-10-24 10:24:53+00:00 -->
- [[#1801](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1801)] Fix Internal App LB serverless NEG backend example ([juliocc](https://github.com/juliocc)) <!-- 2023-10-24 07:25:44+00:00 -->
- [[#1795](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1795)] Allow users to optonally specify address names ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-10-23 15:17:07+00:00 -->
- [[#1792](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1792)] Removed unnecessary try statements from apigee module outputs ([apichick](https://github.com/apichick)) <!-- 2023-10-22 16:13:13+00:00 -->
- [[#1786](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1786)] net-lb-ext: add support for multiple forwarding rules (IPs) and dual-stack (IPv4/IPv6) ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-10-21 16:19:18+00:00 -->
- [[#1782](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1782)] Add upper cap to versions, update copyright notices ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-20 16:17:48+00:00 -->
- [[#1774](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1774)] Added ProtectedApplication feature to GKE Backup ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-10-19 17:54:22+00:00 -->
- [[#1775](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1775)] Add gcp org policy constraints file to bootstrap stage ([ludoo](https://github.com/ludoo)) <!-- 2023-10-18 18:21:17+00:00 -->
- [[#1771](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1771)] Fix resource manager tag bindings in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2023-10-18 09:24:00+00:00 -->
- [[#1769](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1769)] Remove incompatible balancing_mode ([wiktorn](https://github.com/wiktorn)) <!-- 2023-10-18 06:11:32+00:00 -->
- [[#1765](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1765)] Add support for dual stack and multiple forwarding rules to net-lb-int module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-10-17 09:30:35+00:00 -->
- [[#1762](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1762)] Make subnets depend on proxy only subnets ([juliocc](https://github.com/juliocc)) <!-- 2023-10-16 11:39:52+00:00 -->
- [[#1757](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1757)] Add autoclass to GCS ([jeroenmonteban](https://github.com/jeroenmonteban)) <!-- 2023-10-16 07:45:10+00:00 -->
- [[#1756](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1756)] Exposed stack_type variable in compute_vm module ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-10-16 06:28:57+00:00 -->
- [[#1743](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1743)] Billing account module ([ludoo](https://github.com/ludoo)) <!-- 2023-10-15 15:02:50+00:00 -->
- [[#1752](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1752)] Add outputs to BigQuery dataset module ([devuonocar](https://github.com/devuonocar)) <!-- 2023-10-13 15:02:48+00:00 -->
- [[#1754](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1754)] Fix typo in GKE nodepool taints ([ludoo](https://github.com/ludoo)) <!-- 2023-10-12 12:04:15+00:00 -->
- [[#1746](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1746)] Module autopilot bug fixes ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-10-12 10:40:29+00:00 -->
- [[#1745](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1745)] Add missing fields to Cloud Storage bucket ([devuonocar](https://github.com/devuonocar)) <!-- 2023-10-10 20:40:30+00:00 -->
- [[#1744](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1744)] Append "s" to pubsub backoff times ([juliocc](https://github.com/juliocc)) <!-- 2023-10-10 10:32:20+00:00 -->
- [[#1741](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1741)] Add PSA peered domains support to `net-vpc` ([juliocc](https://github.com/juliocc)) <!-- 2023-10-06 15:31:33+00:00 -->
- [[#1737](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1737)] Enforce mandatory types in all variables ([juliocc](https://github.com/juliocc)) <!-- 2023-10-06 09:44:34+00:00 -->
- [[#1732](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1732)] Added FQDN Network Policy feature on GKE Cluster ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-10-06 08:05:54+00:00 -->
- [[#1735](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1735)] Make deletion protection consistent across all modules ([juliocc](https://github.com/juliocc)) <!-- 2023-10-05 15:31:08+00:00 -->
- [[#1726](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1726)] Add materialized views for bigquery ([devuonocar](https://github.com/devuonocar)) <!-- 2023-10-04 12:25:57+00:00 -->

### TOOLS

- [[#1863](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1863)] End-to-end tests for Vertex blueprint ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-16 12:49:30+00:00 -->
- [[#1860](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1860)] Organization module end-to-end tests ([wiktorn](https://github.com/wiktorn)) <!-- 2023-11-14 17:55:00+00:00 -->
- [[#1782](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1782)] Add upper cap to versions, update copyright notices ([sruffilli](https://github.com/sruffilli)) <!-- 2023-10-20 16:17:48+00:00 -->
- [[#1751](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1751)] End-to-end tests for terraform modules ([wiktorn](https://github.com/wiktorn)) <!-- 2023-10-20 07:59:52+00:00 -->
- [[#1737](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1737)] Enforce mandatory types in all variables ([juliocc](https://github.com/juliocc)) <!-- 2023-10-06 09:44:34+00:00 -->
- [[#1734](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1734)] Update to lint.sh and wording to some tf ([bluPhy](https://github.com/bluPhy)) <!-- 2023-10-05 06:32:08+00:00 -->

## [27.0.0] - 2023-10-04

### BLUEPRINTS

- [[#1730](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1730)] Minimal Data Platform - Fix ([lcaggio](https://github.com/lcaggio)) <!-- 2023-10-04 10:15:51+00:00 -->
- [[#1725](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1725)] Fix data platform roles ([lcaggio](https://github.com/lcaggio)) <!-- 2023-10-04 05:31:41+00:00 -->
- [[#1724](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1724)] Bump provider versions to v5.0.0 ([ludoo](https://github.com/ludoo)) <!-- 2023-10-03 12:15:36+00:00 -->
- [[#1722](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1722)] Add support for org policies to project factory ([ludoo](https://github.com/ludoo)) <!-- 2023-10-02 14:13:57+00:00 -->
- [[#1692](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1692)] **incompatible change:** Allow using no service account in compute-vm ([ludoo](https://github.com/ludoo)) <!-- 2023-09-19 16:56:51+00:00 -->

### DOCUMENTATION

- [[#1725](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1725)] Fix data platform roles ([lcaggio](https://github.com/lcaggio)) <!-- 2023-10-04 05:31:41+00:00 -->
- [[#1724](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1724)] Bump provider versions to v5.0.0 ([ludoo](https://github.com/ludoo)) <!-- 2023-10-03 12:15:36+00:00 -->
- [[#1707](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1707)] Only apply org policies when bootstrap user is not set ([ludoo](https://github.com/ludoo)) <!-- 2023-09-27 21:24:41+00:00 -->
- [[#1697](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1697)] Define and adopt standard IP ranges for FAST networking ([juliocc](https://github.com/juliocc)) <!-- 2023-09-21 14:27:54+00:00 -->
- [[#1698](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1698)] **incompatible change:** FAST: move organization policies to stage 0 ([ludoo](https://github.com/ludoo)) <!-- 2023-09-21 14:03:22+00:00 -->
- [[#1695](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1695)] **incompatible change:** Rename FAST globals output file ([ludoo](https://github.com/ludoo)) <!-- 2023-09-20 08:36:07+00:00 -->

### FAST

- [[#1725](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1725)] Fix data platform roles ([lcaggio](https://github.com/lcaggio)) <!-- 2023-10-04 05:31:41+00:00 -->
- [[#1724](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1724)] Bump provider versions to v5.0.0 ([ludoo](https://github.com/ludoo)) <!-- 2023-10-03 12:15:36+00:00 -->
- [[#1718](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1718)] FAST: add example of custom org policy condition to bootstrap README ([ludoo](https://github.com/ludoo)) <!-- 2023-09-30 08:22:56+00:00 -->
- [[#1715](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1715)] Fix indentation in FAST hierarchical firewall rules ([juliocc](https://github.com/juliocc)) <!-- 2023-09-29 13:37:41+00:00 -->
- [[#1711](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1711)] [FAST] Fix tenant folder tag ([lcaggio](https://github.com/lcaggio)) <!-- 2023-09-28 21:48:15+00:00 -->
- [[#1707](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1707)] Only apply org policies when bootstrap user is not set ([ludoo](https://github.com/ludoo)) <!-- 2023-09-27 21:24:41+00:00 -->
- [[#1705](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1705)] Fix typo in bootstrap stage README ([giterinhub](https://github.com/giterinhub)) <!-- 2023-09-27 12:21:09+00:00 -->
- [[#1697](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1697)] Define and adopt standard IP ranges for FAST networking ([juliocc](https://github.com/juliocc)) <!-- 2023-09-21 14:27:54+00:00 -->
- [[#1698](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1698)] **incompatible change:** FAST: move organization policies to stage 0 ([ludoo](https://github.com/ludoo)) <!-- 2023-09-21 14:03:22+00:00 -->
- [[#1695](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1695)] **incompatible change:** Rename FAST globals output file ([ludoo](https://github.com/ludoo)) <!-- 2023-09-20 08:36:07+00:00 -->

### MODULES

- [[#1714](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1714)] Support multiple protocols (L3_DEFAULT) through `net-ilb-in` ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-10-04 08:30:11+00:00 -->
- [[#1727](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1727)] Update GCS IAM ([apichick](https://github.com/apichick)) <!-- 2023-10-04 06:43:08+00:00 -->
- [[#1728](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1728)] Fix dnssec keys lookup ([juliocc](https://github.com/juliocc)) <!-- 2023-10-03 19:37:22+00:00 -->
- [[#1724](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1724)] Bump provider versions to v5.0.0 ([ludoo](https://github.com/ludoo)) <!-- 2023-10-03 12:15:36+00:00 -->
- [[#1723](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1723)] Add storage billing model to `bigquery-dataset` ([devuonocar](https://github.com/devuonocar)) <!-- 2023-10-02 17:37:40+00:00 -->
- [[#1719](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1719)] Add GLB HTTP to HTTPS redirect example ([ludoo](https://github.com/ludoo)) <!-- 2023-10-02 10:10:24+00:00 -->
- [[#1717](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1717)] Apigee module fix try ([apichick](https://github.com/apichick)) <!-- 2023-10-01 12:26:22+00:00 -->
- [[#1716](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1716)] Add retry policy for subscriptions ([devuonocar](https://github.com/devuonocar)) <!-- 2023-09-29 14:46:26+00:00 -->
- [[#1709](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1709)] Add bug fix in bucket local variable ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-09-28 10:17:53+00:00 -->
- [[#1704](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1704)] Add cloud function secrets tests ([wiktorn](https://github.com/wiktorn)) <!-- 2023-09-26 09:22:36+00:00 -->
- [[#1703](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1703)] Add bug fix to allow to use Secret Manager secrets to mount files in … ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-09-25 13:27:03+00:00 -->
- [[#1701](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1701)] Add support for default nodepool sa in GKE cluster module ([ludoo](https://github.com/ludoo)) <!-- 2023-09-22 08:37:38+00:00 -->
- [[#1696](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1696)] Add deletion_protection_enabled attribute to cloudsql-instance to ena… ([steenblik](https://github.com/steenblik)) <!-- 2023-09-20 13:09:38+00:00 -->
- [[#1690](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1690)] **incompatible change:** Rename instance attachment to match versions 23 and earlier ([cygnus8595](https://github.com/cygnus8595)) <!-- 2023-09-20 09:32:05+00:00 -->
- [[#1694](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1694)] Fix apigee addons config conditional expression ([eddern](https://github.com/eddern)) <!-- 2023-09-19 19:39:09+00:00 -->
- [[#1692](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1692)] **incompatible change:** Allow using no service account in compute-vm ([ludoo](https://github.com/ludoo)) <!-- 2023-09-19 16:56:51+00:00 -->
- [[#1688](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1688)] Fix repd disk attachment in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2023-09-18 13:02:28+00:00 -->

## [26.0.0] - 2023-09-18
<!-- 2023-09-18 07:03:09+00:00 < 2023-08-09 17:02:13+00:00 -->

### BLUEPRINTS

- [[#1684](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1684)] **incompatible change:** Update resource-level IAM interface for kms and pubsub modules ([juliocc](https://github.com/juliocc)) <!-- 2023-09-17 08:48:09+00:00 -->
- [[#1682](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1682)] GKE cluster modules: add optional kube state metrics ([olliefr](https://github.com/olliefr)) <!-- 2023-09-15 11:18:45+00:00 -->
- [[#1681](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1681)] **incompatible change:** Embed subnet-level IAM in the variables controlling creation of subnets ([juliocc](https://github.com/juliocc)) <!-- 2023-09-15 06:42:24+00:00 -->
- [[#1680](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1680)] Upgrades to `monitoring_config` in `gke-cluster-*`, docs update, and cosmetics fixes to GKE cluster modules ([olliefr](https://github.com/olliefr)) <!-- 2023-09-14 22:25:57+00:00 -->
- [[#1679](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1679)] Add lineage on Minimal Data Platform blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-09-14 15:52:20+00:00 -->
- [[#1678](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1678)] Allow only one of `secondary_range_blocks` or `secondary_range_names` when creating GKE clusters. ([juliocc](https://github.com/juliocc)) <!-- 2023-09-14 11:29:08+00:00 -->
- [[#1671](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1671)] **incompatible change:** Fixed, added back environments to each instance, that way we can also… ([apichick](https://github.com/apichick)) <!-- 2023-09-13 14:58:04+00:00 -->
- [[#1662](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1662)] merge labels from data_merges in project factory ([Tutuchan](https://github.com/Tutuchan)) <!-- 2023-09-08 10:27:46+00:00 -->
- [[#1651](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1651)] add AIRFLOW_VAR_ prefix to environment variables in data-platform blueprints ([Tutuchan](https://github.com/Tutuchan)) <!-- 2023-09-08 07:38:29+00:00 -->
- [[#1642](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1642)] New phpIPAM serverless third parties solution in blueprints ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-09-07 13:30:23+00:00 -->
- [[#1654](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1654)] Fix project factory blueprint and fast stage ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-09-07 12:48:39+00:00 -->
- [[#1647](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1647)] Bump provider version to 4.80.0 ([juliocc](https://github.com/juliocc)) <!-- 2023-09-05 10:06:19+00:00 -->
- [[#1638](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1638)] gke-cluster-standard: change logging configuration ([olliefr](https://github.com/olliefr)) <!-- 2023-08-31 11:49:15+00:00 -->
- [[#1636](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1636)] Delete api gateway blueprint ([juliodiez](https://github.com/juliodiez)) <!-- 2023-08-29 11:32:40+00:00 -->
- [[#1607](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1607)] Trap requests timeout error in quota sync ([ludoo](https://github.com/ludoo)) <!-- 2023-08-21 16:37:55+00:00 -->
- [[#1595](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1595)] **incompatible change:** IAM interface refactor ([ludoo](https://github.com/ludoo)) <!-- 2023-08-20 07:44:20+00:00 -->
- [[#1601](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1601)] [Data Platform] Update README.md ([lcaggio](https://github.com/lcaggio)) <!-- 2023-08-18 16:27:43+00:00 -->

### DOCUMENTATION

- [[#1687](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1687)] Add IAM variables template to ADR ([juliocc](https://github.com/juliocc)) <!-- 2023-09-17 09:08:11+00:00 -->
- [[#1686](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1686)] CONTRIBUTING guide: fix broken links and update "running tests for specific examples" section ([olliefr](https://github.com/olliefr)) <!-- 2023-09-16 19:46:46+00:00 -->
- [[#1658](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1658)] **incompatible change:** Change type of `iam_bindings` variable to allow multiple conditional bindings ([ludoo](https://github.com/ludoo)) <!-- 2023-09-08 06:56:31+00:00 -->
- [[#1642](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1642)] New phpIPAM serverless third parties solution in blueprints ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-09-07 13:30:23+00:00 -->
- [[#1640](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1640)] Simplify linting output in workflow ([juliocc](https://github.com/juliocc)) <!-- 2023-08-31 09:16:37+00:00 -->
- [[#1636](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1636)] Delete api gateway blueprint ([juliodiez](https://github.com/juliodiez)) <!-- 2023-08-29 11:32:40+00:00 -->
- [[#1595](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1595)] **incompatible change:** IAM interface refactor ([ludoo](https://github.com/ludoo)) <!-- 2023-08-20 07:44:20+00:00 -->

### FAST

- [[#1684](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1684)] **incompatible change:** Update resource-level IAM interface for kms and pubsub modules ([juliocc](https://github.com/juliocc)) <!-- 2023-09-17 08:48:09+00:00 -->
- [[#1685](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1685)] Fix psa routing variable in FAST net stages ([ludoo](https://github.com/ludoo)) <!-- 2023-09-16 08:31:03+00:00 -->
- [[#1682](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1682)] GKE cluster modules: add optional kube state metrics ([olliefr](https://github.com/olliefr)) <!-- 2023-09-15 11:18:45+00:00 -->
- [[#1681](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1681)] **incompatible change:** Embed subnet-level IAM in the variables controlling creation of subnets ([juliocc](https://github.com/juliocc)) <!-- 2023-09-15 06:42:24+00:00 -->
- [[#1680](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1680)] Upgrades to `monitoring_config` in `gke-cluster-*`, docs update, and cosmetics fixes to GKE cluster modules ([olliefr](https://github.com/olliefr)) <!-- 2023-09-14 22:25:57+00:00 -->
- [[#1678](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1678)] Allow only one of `secondary_range_blocks` or `secondary_range_names` when creating GKE clusters. ([juliocc](https://github.com/juliocc)) <!-- 2023-09-14 11:29:08+00:00 -->
- [[#1664](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1664)] Align pf stage sample data to new format ([ludoo](https://github.com/ludoo)) <!-- 2023-09-09 08:04:19+00:00 -->
- [[#1663](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1663)] [#1661] Make FAST stage 1 resman tf destroy more reliable ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-09-08 10:09:31+00:00 -->
- [[#1659](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1659)] Link project factory documentation from FAST stage ([ludoo](https://github.com/ludoo)) <!-- 2023-09-08 07:14:16+00:00 -->
- [[#1658](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1658)] **incompatible change:** Change type of `iam_bindings` variable to allow multiple conditional bindings ([ludoo](https://github.com/ludoo)) <!-- 2023-09-08 06:56:31+00:00 -->
- [[#1654](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1654)] Fix project factory blueprint and fast stage ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-09-07 12:48:39+00:00 -->
- [[#1638](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1638)] gke-cluster-standard: change logging configuration ([olliefr](https://github.com/olliefr)) <!-- 2023-08-31 11:49:15+00:00 -->
- [[#1634](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1634)] [revert(revert(patch))] Remove unused ASN numbers for CloudNAT in FAST ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-08-28 15:32:30+00:00 -->
- [[#1631](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1631)] Allow single hfw policy association in folder and organization modules ([juliocc](https://github.com/juliocc)) <!-- 2023-08-28 14:46:05+00:00 -->
- [[#1626](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1626)] Revert "Remove unused ASN numbers from CloudNAT to avoid provider errors" ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-08-28 07:33:53+00:00 -->
- [[#1623](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1623)] Fix role name for delegated grants in FAST bootstrap ([juliocc](https://github.com/juliocc)) <!-- 2023-08-25 06:43:20+00:00 -->
- [[#1612](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1612)] Fix: align stage-2-e-nva-bgp to the latest APIs ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-08-23 11:34:11+00:00 -->
- [[#1610](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1610)] Fix: use existing variable to optionally name fw policies ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-08-22 06:55:56+00:00 -->
- [[#1595](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1595)] **incompatible change:** IAM interface refactor ([ludoo](https://github.com/ludoo)) <!-- 2023-08-20 07:44:20+00:00 -->
- [[#1597](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1597)] fix null object exception in bootstrap output when using cloudsource ([sm3142](https://github.com/sm3142)) <!-- 2023-08-17 09:03:23+00:00 -->
- [[#1593](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1593)] Fix FAST CI/CD for Gitlab ([ludoo](https://github.com/ludoo)) <!-- 2023-08-15 10:59:31+00:00 -->
- [[#1583](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1583)] Fix module path for teams cicd ([ludoo](https://github.com/ludoo)) <!-- 2023-08-09 21:41:57+00:00 -->

### MODULES

- [[#1684](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1684)] **incompatible change:** Update resource-level IAM interface for kms and pubsub modules ([juliocc](https://github.com/juliocc)) <!-- 2023-09-17 08:48:09+00:00 -->
- [[#1683](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1683)] Fix subnet iam_bindings to use arbitrary keys ([juliocc](https://github.com/juliocc)) <!-- 2023-09-15 13:15:59+00:00 -->
- [[#1682](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1682)] GKE cluster modules: add optional kube state metrics ([olliefr](https://github.com/olliefr)) <!-- 2023-09-15 11:18:45+00:00 -->
- [[#1681](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1681)] **incompatible change:** Embed subnet-level IAM in the variables controlling creation of subnets ([juliocc](https://github.com/juliocc)) <!-- 2023-09-15 06:42:24+00:00 -->
- [[#1680](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1680)] Upgrades to `monitoring_config` in `gke-cluster-*`, docs update, and cosmetics fixes to GKE cluster modules ([olliefr](https://github.com/olliefr)) <!-- 2023-09-14 22:25:57+00:00 -->
- [[#1678](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1678)] Allow only one of `secondary_range_blocks` or `secondary_range_names` when creating GKE clusters. ([juliocc](https://github.com/juliocc)) <!-- 2023-09-14 11:29:08+00:00 -->
- [[#1675](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1675)] GKE Autopilot module: add network tags ([olliefr](https://github.com/olliefr)) <!-- 2023-09-14 09:34:51+00:00 -->
- [[#1676](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1676)] fixed up nit from PR 1666 ([dgulli](https://github.com/dgulli)) <!-- 2023-09-14 05:23:20+00:00 -->
- [[#1672](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1672)] Added possibility to use gcs push endpoint on pubsub subscription ([luigi-bitonti](https://github.com/luigi-bitonti)) <!-- 2023-09-13 19:42:43+00:00 -->
- [[#1671](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1671)] **incompatible change:** Fixed, added back environments to each instance, that way we can also… ([apichick](https://github.com/apichick)) <!-- 2023-09-13 14:58:04+00:00 -->
- [[#1666](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1666)] added support for global proxy only subnets ([dgulli](https://github.com/dgulli)) <!-- 2023-09-13 08:46:09+00:00 -->
- [[#1669](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1669)] Fix for partner interconnect ([apichick](https://github.com/apichick)) <!-- 2023-09-12 13:29:35+00:00 -->
- [[#1668](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1668)] fix(compute-mig): add correct type optionality for metrics in autosca… ([NotArpit](https://github.com/NotArpit)) <!-- 2023-09-12 11:58:09+00:00 -->
- [[#1667](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1667)] fix(compute-mig): add mode property to compute_region_autoscaler ([NotArpit](https://github.com/NotArpit)) <!-- 2023-09-11 11:25:32+00:00 -->
- [[#1658](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1658)] **incompatible change:** Change type of `iam_bindings` variable to allow multiple conditional bindings ([ludoo](https://github.com/ludoo)) <!-- 2023-09-08 06:56:31+00:00 -->
- [[#1653](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1653)] Fixes to the apigee module ([juliocc](https://github.com/juliocc)) <!-- 2023-09-07 15:02:56+00:00 -->
- [[#1642](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1642)] New phpIPAM serverless third parties solution in blueprints ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-09-07 13:30:23+00:00 -->
- [[#1650](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1650)] Make net-vpc variables non-nullable ([juliocc](https://github.com/juliocc)) <!-- 2023-09-06 08:52:29+00:00 -->
- [[#1647](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1647)] Bump provider version to 4.80.0 ([juliocc](https://github.com/juliocc)) <!-- 2023-09-05 10:06:19+00:00 -->
- [[#1646](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1646)] gke-cluster-autopilot: add monitoring configuration ([olliefr](https://github.com/olliefr)) <!-- 2023-09-04 15:43:59+00:00 -->
- [[#1645](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1645)] gke-cluster-autopilot: add validation for release_channel input variable ([olliefr](https://github.com/olliefr)) <!-- 2023-09-03 00:37:50+00:00 -->
- [[#1638](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1638)] gke-cluster-standard: change logging configuration ([olliefr](https://github.com/olliefr)) <!-- 2023-08-31 11:49:15+00:00 -->
- [[#1625](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1625)] gke-cluster-autopilot: add logging configuration ([olliefr](https://github.com/olliefr)) <!-- 2023-08-31 11:06:57+00:00 -->
- [[#1637](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1637)] GRPC variable is misnamed "GRCP" in `modules/cloud-run/variables.tf`, causing liveness probe and startup probe to fail ([zacharysmithdatatonic](https://github.com/zacharysmithdatatonic)) <!-- 2023-08-30 11:47:05+00:00 -->
- [[#1632](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1632)] Vpc sc allow null for identity type ([LudovicEmo](https://github.com/LudovicEmo)) <!-- 2023-08-29 02:28:58+00:00 -->
- [[#1633](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1633)] Do not set default ASN number ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-08-28 15:06:32+00:00 -->
- [[#1631](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1631)] Allow single hfw policy association in folder and organization modules ([juliocc](https://github.com/juliocc)) <!-- 2023-08-28 14:46:05+00:00 -->
- [[#1630](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1630)] [Fix] Add explicit dependency between CR peers and NCC RA spoke creation ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-08-28 13:50:46+00:00 -->
- [[#1613](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1613)] Cloud SQL activation policy selectable ([cmvalla](https://github.com/cmvalla)) <!-- 2023-08-25 10:12:08+00:00 -->
- [[#1619](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1619)] Adding support for NAT in Apigee ([billabongrob](https://github.com/billabongrob)) <!-- 2023-08-24 18:25:54+00:00 -->
- [[#1620](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1620)] Remove net-firewall-policy match variable validation ([richard-olson](https://github.com/richard-olson)) <!-- 2023-08-24 17:45:32+00:00 -->
- [[#1614](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1614)] Fix net-firewall-policy factory name and action ([richard-olson](https://github.com/richard-olson)) <!-- 2023-08-23 14:06:00+00:00 -->
- [[#1584](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1584)] add support for object upload to gcs module ([ehorning](https://github.com/ehorning)) <!-- 2023-08-22 17:01:19+00:00 -->
- [[#1609](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1609)] **incompatible change:** Use cloud run bindings for cf v2 invoker role, refactor iam handling in cf v2 and cloud run ([ludoo](https://github.com/ludoo)) <!-- 2023-08-22 07:23:49+00:00 -->
- [[#1590](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1590)] GCVE module first release ([eliamaldini](https://github.com/eliamaldini)) <!-- 2023-08-21 07:05:45+00:00 -->
- [[#1595](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1595)] **incompatible change:** IAM interface refactor ([ludoo](https://github.com/ludoo)) <!-- 2023-08-20 07:44:20+00:00 -->
- [[#1600](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1600)] fix(cloud-run): move cpu boost annotation to revision ([LiuVII](https://github.com/LiuVII)) <!-- 2023-08-18 14:46:25+00:00 -->
- [[#1599](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1599)] Fixing some typos ([bluPhy](https://github.com/bluPhy)) <!-- 2023-08-18 08:29:26+00:00 -->
- [[#1598](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1598)] feat(cloud-run): add startup cpu boost option ([JSchwerberg](https://github.com/JSchwerberg)) <!-- 2023-08-17 22:05:24+00:00 -->
- [[#1594](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1594)] Add support for conditions to `iam_members` module variables ([ludoo](https://github.com/ludoo)) <!-- 2023-08-15 14:28:23+00:00 -->
- [[#1591](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1591)] feat: 🎸 (modules/cloudsql-instance):add project_id for ssl cert ([erabusi](https://github.com/erabusi)) <!-- 2023-08-14 10:40:25+00:00 -->
- [[#1589](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1589)] Add new `iam_members` variable to IAM additive module interfaces ([ludoo](https://github.com/ludoo)) <!-- 2023-08-14 09:54:50+00:00 -->
- [[#1588](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1588)] feat: 🎸 (modules/cloudsql-instance): enable require_ssl cert support ([erabusi](https://github.com/erabusi)) <!-- 2023-08-14 09:37:04+00:00 -->
- [[#1587](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1587)] **incompatible change:** Fix factory rules key in net firewall policy module ([ludoo](https://github.com/ludoo)) <!-- 2023-08-14 05:52:37+00:00 -->
- [[#1578](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1578)] Fix: Instance level stateful disk config  ([beardedsamwise](https://github.com/beardedsamwise)) <!-- 2023-08-11 15:25:17+00:00 -->
- [[#1582](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1582)] feat(modules/cloud-run): add gen2 exec env support ([LiuVII](https://github.com/LiuVII)) <!-- 2023-08-09 21:04:17+00:00 -->

### TOOLS

- [[#1641](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1641)] Lint script ([juliocc](https://github.com/juliocc)) <!-- 2023-08-31 09:38:09+00:00 -->
- [[#1640](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1640)] Simplify linting output in workflow ([juliocc](https://github.com/juliocc)) <!-- 2023-08-31 09:16:37+00:00 -->
- [[#1635](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1635)] Silence FAST tests warnings ([juliocc](https://github.com/juliocc)) <!-- 2023-08-29 05:26:58+00:00 -->
- [[#1595](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1595)] **incompatible change:** IAM interface refactor ([ludoo](https://github.com/ludoo)) <!-- 2023-08-20 07:44:20+00:00 -->
- [[#1585](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1585)] Print inventory path when a test fails ([juliocc](https://github.com/juliocc)) <!-- 2023-08-11 10:28:08+00:00 -->

## [25.0.0] - 2023-08-09
<!-- 2023-08-09 17:02:13+00:00 < 2023-07-07 16:22:14+00:00 -->

### BLUEPRINTS

- [[#1581](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1581)] **incompatible change:** Remove firewall policy management from resource management modules ([ludoo](https://github.com/ludoo)) <!-- 2023-08-09 11:23:08+00:00 -->
- [[#1573](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1573)] Add information about required groups ([wiktorn](https://github.com/wiktorn)) <!-- 2023-08-06 18:27:59+00:00 -->
- [[#1572](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1572)] **incompatible change:** More module descriptions ([ludoo](https://github.com/ludoo)) <!-- 2023-08-06 09:25:45+00:00 -->
- [[#1560](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1560)] Removed unused attribute in variable of ha-vpn-over-blueprint blueprint ([apichick](https://github.com/apichick)) <!-- 2023-08-02 11:41:08+00:00 -->
- [[#1548](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1548)] Minor fixes in Vertex Ai MLOPs blueprint ([javiergp](https://github.com/javiergp)) <!-- 2023-07-31 10:52:37+00:00 -->
- [[#1547](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1547)] **incompatible change:** Peering module refactor ([ludoo](https://github.com/ludoo)) <!-- 2023-07-29 19:33:58+00:00 -->
- [[#1542](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1542)] Grant IAM rights to service identities in host project ([wiktorn](https://github.com/wiktorn)) <!-- 2023-07-29 18:07:21+00:00 -->
- [[#1536](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1536)] **incompatible change:** Update and refactor artifact registry module ([ludoo](https://github.com/ludoo)) <!-- 2023-07-28 09:54:37+00:00 -->
- [[#1533](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1533)] Make demo pipeline append into BQ tables ([danieldeleo](https://github.com/danieldeleo)) <!-- 2023-07-27 15:38:01+00:00 -->
- [[#1510](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1510)] **incompatible change:** Refactoring of dns module ([apichick](https://github.com/apichick)) <!-- 2023-07-19 11:13:41+00:00 -->
- [[#1504](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1504)] Bump semver from 5.7.1 to 5.7.2 in /blueprints/serverless/api-gateway/function ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2023-07-13 06:05:52+00:00 -->
- [[#1501](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1501)] Fix in nb-glb-psc-neg-sb-psc-ilbl7-hybrid-neg blueprint ([apichick](https://github.com/apichick)) <!-- 2023-07-11 10:01:54+00:00 -->
- [[#1498](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1498)] Return only bucket name of composer, not full url to dags folder ([wiktorn](https://github.com/wiktorn)) <!-- 2023-07-10 09:20:51+00:00 -->

### DOCUMENTATION

- [[#1581](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1581)] **incompatible change:** Remove firewall policy management from resource management modules ([ludoo](https://github.com/ludoo)) <!-- 2023-08-09 11:23:08+00:00 -->
- [[#1573](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1573)] Add information about required groups ([wiktorn](https://github.com/wiktorn)) <!-- 2023-08-06 18:27:59+00:00 -->
- [[#1545](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1545)] add dataplex autodq base module ([thinhha](https://github.com/thinhha)) <!-- 2023-08-02 11:16:33+00:00 -->
- [[#1557](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1557)] renaming net-vpc-swp to net-swp ([skalolazka](https://github.com/skalolazka)) <!-- 2023-08-01 15:48:22+00:00 -->
- [[#1553](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1553)] Added module for Regional Internal Proxy Load Balancer ([apichick](https://github.com/apichick)) <!-- 2023-07-31 15:58:09+00:00 -->
- [[#1546](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1546)] **incompatible change:** rename cloud-dataplex to dataplex ([thinhha](https://github.com/thinhha)) <!-- 2023-07-29 12:31:18+00:00 -->
- [[#1506](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1506)] Document architectural decisions ([ludoo](https://github.com/ludoo)) <!-- 2023-07-13 14:15:32+00:00 -->
- [[#1500](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1500)] README: audit logs on org level go to a logging bucket, not bigquery ([skalolazka](https://github.com/skalolazka)) <!-- 2023-07-10 14:59:00+00:00 -->

### FAST

- [[#1579](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1579)] Enable team CI/CD impersonation ([williamsmt](https://github.com/williamsmt)) <!-- 2023-08-09 12:46:24+00:00 -->
- [[#1581](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1581)] **incompatible change:** Remove firewall policy management from resource management modules ([ludoo](https://github.com/ludoo)) <!-- 2023-08-09 11:23:08+00:00 -->
- [[#1572](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1572)] **incompatible change:** More module descriptions ([ludoo](https://github.com/ludoo)) <!-- 2023-08-06 09:25:45+00:00 -->
- [[#1566](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1566)] Remove unused ASN numbers from CloudNAT to avoid provider errors ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-08-04 08:02:12+00:00 -->
- [[#1563](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1563)] Update FAST CI/CD workflows so it can work with ID_TOKEN and Gitlab 15+ ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-08-03 16:09:45+00:00 -->
- [[#1547](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1547)] **incompatible change:** Peering module refactor ([ludoo](https://github.com/ludoo)) <!-- 2023-07-29 19:33:58+00:00 -->
- [[#1514](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1514)] Fix FAST stage links script for GKE stage ([ludoo](https://github.com/ludoo)) <!-- 2023-07-20 10:48:45+00:00 -->
- [[#1510](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1510)] **incompatible change:** Refactoring of dns module ([apichick](https://github.com/apichick)) <!-- 2023-07-19 11:13:41+00:00 -->

### MODULES

- [[#1581](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1581)] **incompatible change:** Remove firewall policy management from resource management modules ([ludoo](https://github.com/ludoo)) <!-- 2023-08-09 11:23:08+00:00 -->
- [[#1580](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1580)] Apigee addons ([apichick](https://github.com/apichick)) <!-- 2023-08-09 06:33:20+00:00 -->
- [[#1576](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1576)] **incompatible change:** Refactor firewall policy module ([ludoo](https://github.com/ludoo)) <!-- 2023-08-08 16:57:59+00:00 -->
- [[#1575](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1575)] Expose allow_net_admin feature in gke-cluster-autopilot module ([eunanhardy](https://github.com/eunanhardy)) <!-- 2023-08-07 15:03:51+00:00 -->
- [[#1572](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1572)] **incompatible change:** More module descriptions ([ludoo](https://github.com/ludoo)) <!-- 2023-08-06 09:25:45+00:00 -->
- [[#1569](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1569)] Add support for cost management to GKE module ([ludoo](https://github.com/ludoo)) <!-- 2023-08-05 11:46:53+00:00 -->
- [[#1568](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1568)] Add support for ipv6 to net-vpc module ([ludoo](https://github.com/ludoo)) <!-- 2023-08-05 11:07:27+00:00 -->
- [[#1567](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1567)] Allow custom route descriptions in net-vpc module ([juliocc](https://github.com/juliocc)) <!-- 2023-08-04 16:45:15+00:00 -->
- [[#1558](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1558)] feat(apigee): add retention variable ([danistrebel](https://github.com/danistrebel)) <!-- 2023-08-04 11:25:36+00:00 -->
- [[#1564](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1564)] Fixed error of inconsistent conditional result types when evaluating … ([apichick](https://github.com/apichick)) <!-- 2023-08-03 06:09:38+00:00 -->
- [[#1561](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1561)] Removed unused attribute in peer_gateway_config variable ([apichick](https://github.com/apichick)) <!-- 2023-08-02 13:38:45+00:00 -->
- [[#1545](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1545)] add dataplex autodq base module ([thinhha](https://github.com/thinhha)) <!-- 2023-08-02 11:16:33+00:00 -->
- [[#1559](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1559)] Added IPSEC_INTERCONNECT addresses to net-address module ([apichick](https://github.com/apichick)) <!-- 2023-08-02 10:28:46+00:00 -->
- [[#1557](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1557)] renaming net-vpc-swp to net-swp ([skalolazka](https://github.com/skalolazka)) <!-- 2023-08-01 15:48:22+00:00 -->
- [[#1513](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1513)] optional description in modules/net-vpc-swp ([skalolazka](https://github.com/skalolazka)) <!-- 2023-08-01 13:50:07+00:00 -->
- [[#1555](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1555)] Fix permadiff in artifact-registry ([juliocc](https://github.com/juliocc)) <!-- 2023-07-31 16:20:28+00:00 -->
- [[#1553](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1553)] Added module for Regional Internal Proxy Load Balancer ([apichick](https://github.com/apichick)) <!-- 2023-07-31 15:58:09+00:00 -->
- [[#1554](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1554)] Fix in IAM bindings of cloud function v2 module ([apichick](https://github.com/apichick)) <!-- 2023-07-31 11:22:07+00:00 -->
- [[#1551](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1551)] Fix in validation of healthchecks variable ([apichick](https://github.com/apichick)) <!-- 2023-07-31 10:13:19+00:00 -->
- [[#1552](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1552)] Add image path output to ar module ([ludoo](https://github.com/ludoo)) <!-- 2023-07-31 09:34:02+00:00 -->
- [[#1550](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1550)] Fix in validation of healthchecks variable ([apichick](https://github.com/apichick)) <!-- 2023-07-31 08:16:52+00:00 -->
- [[#1547](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1547)] **incompatible change:** Peering module refactor ([ludoo](https://github.com/ludoo)) <!-- 2023-07-29 19:33:58+00:00 -->
- [[#1542](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1542)] Grant IAM rights to service identities in host project ([wiktorn](https://github.com/wiktorn)) <!-- 2023-07-29 18:07:21+00:00 -->
- [[#1546](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1546)] **incompatible change:** rename cloud-dataplex to dataplex ([thinhha](https://github.com/thinhha)) <!-- 2023-07-29 12:31:18+00:00 -->
- [[#1540](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1540)] Fixes in cloud function v2 module for trigger service account ([apichick](https://github.com/apichick)) <!-- 2023-07-28 15:21:18+00:00 -->
- [[#1536](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1536)] **incompatible change:** Update and refactor artifact registry module ([ludoo](https://github.com/ludoo)) <!-- 2023-07-28 09:54:37+00:00 -->
- [[#1537](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1537)] Wrong ASN when using partner_interconnect. ([sruffilli](https://github.com/sruffilli)) <!-- 2023-07-28 09:16:04+00:00 -->
- [[#1535](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1535)] Renamed output.tf in net-vlan-attachment ([sruffilli](https://github.com/sruffilli)) <!-- 2023-07-28 08:35:48+00:00 -->
- [[#1523](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1523)] Fix in event_filters of trigger_config ([apichick](https://github.com/apichick)) <!-- 2023-07-25 14:49:07+00:00 -->
- [[#1519](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1519)] Improve Dataplex ([lcaggio](https://github.com/lcaggio)) <!-- 2023-07-24 08:52:08+00:00 -->
- [[#1520](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1520)] feat(cloudsql-instance): Add query insights config ([LiuVII](https://github.com/LiuVII)) <!-- 2023-07-21 18:14:35+00:00 -->
- [[#1512](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1512)] enable-logging flag can only be true for public zones ([apichick](https://github.com/apichick)) <!-- 2023-07-19 15:09:47+00:00 -->
- [[#1510](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1510)] **incompatible change:** Refactoring of dns module ([apichick](https://github.com/apichick)) <!-- 2023-07-19 11:13:41+00:00 -->
- [[#1509](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1509)] Add output to org module with custom constraint details and depends_on ([juliocc](https://github.com/juliocc)) <!-- 2023-07-18 08:24:39+00:00 -->
- [[#1503](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1503)] Move IAM grant to function level for trigger SA ([wiktorn](https://github.com/wiktorn)) <!-- 2023-07-12 14:19:35+00:00 -->
- [[#1479](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1479)] Update ncc-spoke-ra module to explicity request ncc hub id when referencing existing hubs ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-07-10 14:18:43+00:00 -->
- [[#1499](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1499)] Add support for custom description in net-address ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-07-10 11:04:54+00:00 -->
- [[#1497](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1497)] **incompatible change:** Implement proper support for data access logs in resource manager modules ([ludoo](https://github.com/ludoo)) <!-- 2023-07-10 08:08:03+00:00 -->

### TOOLS

- [[#1544](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1544)] Minimal tfdoc refactoring for legibility ([ludoo](https://github.com/ludoo)) <!-- 2023-07-29 09:11:31+00:00 -->
- [[#1538](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1538)] Extend tfdoc to generate TOCs ([juliocc](https://github.com/juliocc)) <!-- 2023-07-28 15:45:12+00:00 -->
- [[#1511](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1511)] Fail if run with Python below 3.10 ([wiktorn](https://github.com/wiktorn)) <!-- 2023-07-19 12:18:55+00:00 -->

## [24.0.0] - 2023-07-07

### BLUEPRINTS

- [[#1496](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1496)] Allow using a separate resource for boot disk in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2023-07-07 15:40:14+00:00 -->
- [[#1488](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1488)] **incompatible change:** Fix and improve quota monitor blueprint ([ludoo](https://github.com/ludoo)) <!-- 2023-07-03 07:23:49+00:00 -->
- [[#1483](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1483)] Updating a few files to fix typos ([bluPhy](https://github.com/bluPhy)) <!-- 2023-06-30 05:55:32+00:00 -->
- [[#1474](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1474)] data-platform-minimal - support web_server_network_access_control ([kthhrv](https://github.com/kthhrv)) <!-- 2023-06-29 16:38:19+00:00 -->
- [[#1482](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1482)] Add region to quota monitor cloud function ([ludoo](https://github.com/ludoo)) <!-- 2023-06-29 11:02:57+00:00 -->
- [[#1475](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1475)] Minimal Data Platform - Shared VPC ([lcaggio](https://github.com/lcaggio)) <!-- 2023-06-28 19:58:03+00:00 -->
- [[#1473](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1473)] Improve Minimal Data Platform Blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-06-28 07:05:49+00:00 -->
- [[#1468](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1468)] Dependencies update for API Gateway blueprint ([apichick](https://github.com/apichick)) <!-- 2023-06-27 06:30:35+00:00 -->
- [[#1469](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1469)] Bump semver and @google-cloud/storage in /blueprints/gke/binauthz/image ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2023-06-26 13:03:48+00:00 -->
- [[#1466](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1466)] **incompatible change:** Rename network load balancer modules ([ludoo](https://github.com/ludoo)) <!-- 2023-06-26 07:50:11+00:00 -->
- [[#1459](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1459)] Add preliminary support for partner interconnect ([wiktorn](https://github.com/wiktorn)) <!-- 2023-06-26 07:22:09+00:00 -->
- [[#1464](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1464)] Fix Shielded folder README ([lcaggio](https://github.com/lcaggio)) <!-- 2023-06-23 16:38:37+00:00 -->
- [[#1458](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1458)] Fixing typos ([bluPhy](https://github.com/bluPhy)) <!-- 2023-06-23 05:12:52+00:00 -->
- [[#1455](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1455)] Match readme groups with variables file in shielded folder blueprint ([CanburakTumer](https://github.com/CanburakTumer)) <!-- 2023-06-21 09:51:33+00:00 -->
- [[#1451](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1451)] Improve Minimal Data Platform blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-06-20 16:47:16+00:00 -->
- [[#1454](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1454)] data-platform-minimal - 02-processing.tf typo ([kthhrv](https://github.com/kthhrv)) <!-- 2023-06-20 13:26:10+00:00 -->
- [[#1453](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1453)] data-platform-minimal - correct typo ([kthhrv](https://github.com/kthhrv)) <!-- 2023-06-20 11:12:00+00:00 -->
- [[#1450](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1450)] Split Cloud Function module in separate v1 and v2 modules ([ludoo](https://github.com/ludoo)) <!-- 2023-06-19 10:50:36+00:00 -->
- [[#1447](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1447)] **incompatible change:** Refactored apigee module and adjusted the blueprints accordingly ([apichick](https://github.com/apichick)) <!-- 2023-06-19 07:16:00+00:00 -->
- [[#1409](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1409)] Added module for Secure Web Proxy ([rosmo](https://github.com/rosmo)) <!-- 2023-06-13 07:07:18+00:00 -->
- [[#1420](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1420)] Move net-dedicated-vlan-attachment module to net-vlan-attachment and … ([apichick](https://github.com/apichick)) <!-- 2023-06-13 06:34:34+00:00 -->
- [[#1427](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1427)] Updating hub-and-spoke peering blueprint to use HA VPN. ([mark1000](https://github.com/mark1000)) <!-- 2023-06-12 20:07:53+00:00 -->
- [[#1432](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1432)] Make internal/external addresses optional in compute-vm ([juliocc](https://github.com/juliocc)) <!-- 2023-06-08 12:14:26+00:00 -->
- [[#1423](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1423)] Add support for Log Analytics on logging-bucket module and  bump provider version ([lcaggio](https://github.com/lcaggio)) <!-- 2023-06-07 21:23:29+00:00 -->
- [[#1416](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1416)] Fix and improve GCS2BQ blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-06-06 07:06:59+00:00 -->

### DOCUMENTATION

- [[#1483](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1483)] Updating a few files to fix typos ([bluPhy](https://github.com/bluPhy)) <!-- 2023-06-30 05:55:32+00:00 -->
- [[#1473](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1473)] Improve Minimal Data Platform Blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-06-28 07:05:49+00:00 -->
- [[#1466](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1466)] **incompatible change:** Rename network load balancer modules ([ludoo](https://github.com/ludoo)) <!-- 2023-06-26 07:50:11+00:00 -->
- [[#1450](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1450)] Split Cloud Function module in separate v1 and v2 modules ([ludoo](https://github.com/ludoo)) <!-- 2023-06-19 10:50:36+00:00 -->
- [[#1444](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1444)] Fixing typos ([bluPhy](https://github.com/bluPhy)) <!-- 2023-06-16 06:00:57+00:00 -->
- [[#1409](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1409)] Added module for Secure Web Proxy ([rosmo](https://github.com/rosmo)) <!-- 2023-06-13 07:07:18+00:00 -->
- [[#1420](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1420)] Move net-dedicated-vlan-attachment module to net-vlan-attachment and … ([apichick](https://github.com/apichick)) <!-- 2023-06-13 06:34:34+00:00 -->
- [[#1418](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1418)] Network Load Balancer module ([ludoo](https://github.com/ludoo)) <!-- 2023-06-05 11:21:40+00:00 -->

### FAST

- [[#1470](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1470)] FAST: initial implementation of lightweight tenants ([ludoo](https://github.com/ludoo)) <!-- 2023-07-07 06:40:38+00:00 -->
- [[#1492](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1492)] Peering dashboard ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2023-07-05 16:25:32+00:00 -->
- [[#1487](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1487)] Fix primary gke/dp ranges in FAST subnets ([juliocc](https://github.com/juliocc)) <!-- 2023-06-30 18:11:43+00:00 -->
- [[#1478](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1478)] FAST: short_name_is_prefix for multi-tenant ([drebes](https://github.com/drebes)) <!-- 2023-06-30 07:49:26+00:00 -->
- [[#1483](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1483)] Updating a few files to fix typos ([bluPhy](https://github.com/bluPhy)) <!-- 2023-06-30 05:55:32+00:00 -->
- [[#1477](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1477)]  Changing the IP range of pods from 100.64.48.0/20 to 100.65.16.0/20 Fixes #1461 ([arvindag07](https://github.com/arvindag07)) <!-- 2023-06-29 16:57:53+00:00 -->
- [[#1466](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1466)] **incompatible change:** Rename network load balancer modules ([ludoo](https://github.com/ludoo)) <!-- 2023-06-26 07:50:11+00:00 -->
- [[#1446](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1446)] fixup(project-factory): Use the correct KMS Service Agents attribute … ([alloveras](https://github.com/alloveras)) <!-- 2023-06-19 23:53:09+00:00 -->
- [[#1445](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1445)] Bump TF version in all workflow templates to coincide with module requirements ([kthhrv](https://github.com/kthhrv)) <!-- 2023-06-16 07:39:28+00:00 -->
- [[#1443](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1443)] Fix repo names check in extra FAST stage ([ludoo](https://github.com/ludoo)) <!-- 2023-06-15 16:08:57+00:00 -->
- [[#1432](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1432)] Make internal/external addresses optional in compute-vm ([juliocc](https://github.com/juliocc)) <!-- 2023-06-08 12:14:26+00:00 -->
- [[#1429](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1429)] Use RFC6598 addresses for pods and subnets ([wiktorn](https://github.com/wiktorn)) <!-- 2023-06-08 05:56:31+00:00 -->
- [[#1426](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1426)] Add custom tag support to FAST ([ludoo](https://github.com/ludoo)) <!-- 2023-06-07 22:10:27+00:00 -->
- [[#1425](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1425)] Small fixes ([ludoo](https://github.com/ludoo)) <!-- 2023-06-07 17:37:47+00:00 -->
- [[#1412](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1412)] Add VPN monitoring alerts to 2-networking and VPN usage chart ([afda16](https://github.com/afda16)) <!-- 2023-06-06 13:23:00+00:00 -->

### MODULES

- [[#1496](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1496)] Allow using a separate resource for boot disk in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2023-07-07 15:40:14+00:00 -->
- [[#1489](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1489)] **incompatible change:** Disable googleapi routes creation when vpc is not created in net-vpc module ([ludoo](https://github.com/ludoo)) <!-- 2023-07-03 07:10:12+00:00 -->
- [[#1486](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1486)] Allow external editing of group instances in lb modules ([ludoo](https://github.com/ludoo)) <!-- 2023-06-30 17:34:10+00:00 -->
- [[#1480](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1480)] Add bigquery authorized resources ([thinhha](https://github.com/thinhha)) <!-- 2023-06-30 16:44:58+00:00 -->
- [[#1485](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1485)] **incompatible change:** Align group names in lb modules ([ludoo](https://github.com/ludoo)) <!-- 2023-06-30 10:18:07+00:00 -->
- [[#1456](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1456)] add missing variable image_uri ([jose-bermudez-digitalfemsa](https://github.com/jose-bermudez-digitalfemsa)) <!-- 2023-06-28 18:24:44+00:00 -->
- [[#1471](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1471)] Add ToCs to resource manager modules ([ludoo](https://github.com/ludoo)) <!-- 2023-06-27 09:36:29+00:00 -->
- [[#1466](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1466)] **incompatible change:** Rename network load balancer modules ([ludoo](https://github.com/ludoo)) <!-- 2023-06-26 07:50:11+00:00 -->
- [[#1467](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1467)] Add support for resource policies to compute vm module ([ludoo](https://github.com/ludoo)) <!-- 2023-06-26 06:49:06+00:00 -->
- [[#1439](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1439)] modules/vpc-sc: google_access_context_manager_service_perimeter add support for method_selectors/permission ([LudovicEmo](https://github.com/LudovicEmo)) <!-- 2023-06-25 06:45:37+00:00 -->
- [[#1460](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1460)] Added validation for edge_availability_domain value ([apichick](https://github.com/apichick)) <!-- 2023-06-23 10:26:14+00:00 -->
- [[#1458](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1458)] Fixing typos ([bluPhy](https://github.com/bluPhy)) <!-- 2023-06-23 05:12:52+00:00 -->
- [[#1449](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1449)] Added iam for DNS managed zone to dns module ([apichick](https://github.com/apichick)) <!-- 2023-06-20 10:35:20+00:00 -->
- [[#1452](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1452)] feat(artifact-registry): Add support for CMEK ([alloveras](https://github.com/alloveras)) <!-- 2023-06-20 08:15:40+00:00 -->
- [[#1450](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1450)] Split Cloud Function module in separate v1 and v2 modules ([ludoo](https://github.com/ludoo)) <!-- 2023-06-19 10:50:36+00:00 -->
- [[#1447](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1447)] **incompatible change:** Refactored apigee module and adjusted the blueprints accordingly ([apichick](https://github.com/apichick)) <!-- 2023-06-19 07:16:00+00:00 -->
- [[#1440](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1440)] enable_logging variable was not being used ([apichick](https://github.com/apichick)) <!-- 2023-06-15 05:31:14+00:00 -->
- [[#1436](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1436)] Ignore Cloud Run system annotations/labels ([wiktorn](https://github.com/wiktorn)) <!-- 2023-06-13 08:07:05+00:00 -->
- [[#1409](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1409)] Added module for Secure Web Proxy ([rosmo](https://github.com/rosmo)) <!-- 2023-06-13 07:07:18+00:00 -->
- [[#1420](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1420)] Move net-dedicated-vlan-attachment module to net-vlan-attachment and … ([apichick](https://github.com/apichick)) <!-- 2023-06-13 06:34:34+00:00 -->
- [[#1434](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1434)] Add subnets id output, expand net-address outputs ([juliocc](https://github.com/juliocc)) <!-- 2023-06-12 09:16:10+00:00 -->
- [[#1432](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1432)] Make internal/external addresses optional in compute-vm ([juliocc](https://github.com/juliocc)) <!-- 2023-06-08 12:14:26+00:00 -->
- [[#1428](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1428)] Added support for PSC negs in net-ilb-l7 module ([apichick](https://github.com/apichick)) <!-- 2023-06-08 10:50:27+00:00 -->
- [[#1430](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1430)] Fix serverless neg example in ILB L7 module ([ludoo](https://github.com/ludoo)) <!-- 2023-06-08 10:05:54+00:00 -->
- [[#1426](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1426)] Add custom tag support to FAST ([ludoo](https://github.com/ludoo)) <!-- 2023-06-07 22:10:27+00:00 -->
- [[#1423](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1423)] Add support for Log Analytics on logging-bucket module and  bump provider version ([lcaggio](https://github.com/lcaggio)) <!-- 2023-06-07 21:23:29+00:00 -->
- [[#1425](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1425)] Small fixes ([ludoo](https://github.com/ludoo)) <!-- 2023-06-07 17:37:47+00:00 -->
- [[#1419](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1419)] Fix NLB module ([ludoo](https://github.com/ludoo)) <!-- 2023-06-05 17:42:33+00:00 -->
- [[#1418](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1418)] Network Load Balancer module ([ludoo](https://github.com/ludoo)) <!-- 2023-06-05 11:21:40+00:00 -->

### TOOLS

- [[#1496](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1496)] Allow using a separate resource for boot disk in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2023-07-07 15:40:14+00:00 -->

## [23.0.0] - 2023-06-05

<!-- None < 2023-05-24 17:31:22+00:00 -->

### BLUEPRINTS

- [[#1410](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1410)] **incompatible change:** Ensure all modules have an `id` output ([ludoo](https://github.com/ludoo)) <!-- 2023-06-02 14:07:23+00:00 -->
- [[#1390](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1390)] HA VPN over Interconnect modules and blueprint ([sruffilli](https://github.com/sruffilli)) <!-- 2023-05-31 10:53:39+00:00 -->

### DOCUMENTATION

- [[#1403](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1403)] add alloydb module ([prabhaarya](https://github.com/prabhaarya)) <!-- 2023-06-04 10:12:32+00:00 -->
- [[#1407](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1407)] Multiple Updates in READMEs and wording ([bluPhy](https://github.com/bluPhy)) <!-- 2023-05-31 17:53:00+00:00 -->
- [[#1390](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1390)] HA VPN over Interconnect modules and blueprint ([sruffilli](https://github.com/sruffilli)) <!-- 2023-05-31 10:53:39+00:00 -->

### FAST

- [[#1414](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1414)] Bump GH TF version to coincide with module requirements ([davideasaf](https://github.com/davideasaf)) <!-- 2023-06-03 06:20:12+00:00 -->
- [[#1400](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1400)] Add default googleapi route creation to net-vpc ([juliocc](https://github.com/juliocc)) <!-- 2023-05-26 15:50:00+00:00 -->

### MODULES

- [[#1417](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1417)] Remove hardcoded description from instance groups created under net-lb-int ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-06-05 09:35:17+00:00 -->
- [[#1415](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1415)] Add notice to net-lb-int module on routes ([ludoo](https://github.com/ludoo)) <!-- 2023-06-05 07:40:34+00:00 -->
- [[#1403](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1403)] add alloydb module ([prabhaarya](https://github.com/prabhaarya)) <!-- 2023-06-04 10:12:32+00:00 -->
- [[#1411](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1411)] Add networksecurity to JIT identity list ([rosmo](https://github.com/rosmo)) <!-- 2023-06-02 16:32:53+00:00 -->
- [[#1410](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1410)] **incompatible change:** Ensure all modules have an `id` output ([ludoo](https://github.com/ludoo)) <!-- 2023-06-02 14:07:23+00:00 -->
- [[#1405](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1405)] Added comment in the dns module, saying that inbound/outbound server … ([apichick](https://github.com/apichick)) <!-- 2023-06-02 09:35:26+00:00 -->
- [[#1407](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1407)] Multiple Updates in READMEs and wording ([bluPhy](https://github.com/bluPhy)) <!-- 2023-05-31 17:53:00+00:00 -->
- [[#1390](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1390)] HA VPN over Interconnect modules and blueprint ([sruffilli](https://github.com/sruffilli)) <!-- 2023-05-31 10:53:39+00:00 -->
- [[#1404](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1404)] Add trigger SA for Cloud Run ([wiktorn](https://github.com/wiktorn)) <!-- 2023-05-30 15:08:37+00:00 -->
- [[#1400](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1400)] Add default googleapi route creation to net-vpc ([juliocc](https://github.com/juliocc)) <!-- 2023-05-26 15:50:00+00:00 -->

### TOOLS

- [[#1410](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1410)] **incompatible change:** Ensure all modules have an `id` output ([ludoo](https://github.com/ludoo)) <!-- 2023-06-02 14:07:23+00:00 -->

## [22.0.0] - 2023-05-24
<!-- 2023-05-24 17:31:22+00:00 < 2023-03-24 12:44:02+00:00 -->

### BLUEPRINTS

- [[#1389](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1389)] Bump requests from 2.28.1 to 2.31.0 in /blueprints/cloud-operations/network-dashboard/src ([dependabot[bot]](<https://github.com/dependabot[bot]>)) <!-- 2023-05-23 05:37:16+00:00 -->
- [[#1388](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1388)] Firewall Validator fix target_service_accounts ref ([afda16](https://github.com/afda16)) <!-- 2023-05-22 14:49:38+00:00 -->
- [[#1382](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1382)] chore: update mlops blueprint metadata ([bharathkkb](https://github.com/bharathkkb)) <!-- 2023-05-17 07:41:57+00:00 -->
- [[#1380](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1380)] Minimal Data Platform - Make components optional ([lcaggio](https://github.com/lcaggio)) <!-- 2023-05-16 12:08:04+00:00 -->
- [[#1378](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1378)] Updates to blueprints/data-solutions/shielded-folder ([bluPhy](https://github.com/bluPhy)) <!-- 2023-05-16 05:28:34+00:00 -->
- [[#1375](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1375)] Several updates ([bluPhy](https://github.com/bluPhy)) <!-- 2023-05-15 21:08:19+00:00 -->
- [[#1365](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1365)] feat(net-cloudnat): add toggle for independent endpoint mapping and dynamic port allocation ([JSchwerberg](https://github.com/JSchwerberg)) <!-- 2023-05-12 13:38:01+00:00 -->
- [[#1362](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1362)] Add Minimal Data Platform blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-05-08 08:25:07+00:00 -->
- [[#1364](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1364)] Cloud Run services in service projects ([juliodiez](https://github.com/juliodiez)) <!-- 2023-05-08 05:28:16+00:00 -->
- [[#1358](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1358)] update variables files for gke nodepool taints ([jackspyder](https://github.com/jackspyder)) <!-- 2023-05-05 17:42:00+00:00 -->
- [[#1359](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1359)] Blueprint metadata validator ([juliocc](https://github.com/juliocc)) <!-- 2023-05-05 15:20:15+00:00 -->
- [[#1355](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1355)] Fix Shielded Folder - VertexML interoperability ([lcaggio](https://github.com/lcaggio)) <!-- 2023-05-05 07:54:57+00:00 -->
- [[#1353](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1353)] fix in IAM binding of Apigee BigQuery analytics blueprint ([apichick](https://github.com/apichick)) <!-- 2023-05-03 16:31:57+00:00 -->
- [[#1346](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1346)] **incompatible change:** FAST: shorten stage 3 prefixes, enforce prefix length in stage 3s ([ludoo](https://github.com/ludoo)) <!-- 2023-05-03 05:39:41+00:00 -->
- [[#1345](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1345)] chore: update metadata schema ([bharathkkb](https://github.com/bharathkkb)) <!-- 2023-04-28 22:14:21+00:00 -->
- [[#1343](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1343)] Fix because of changes in the cloud functions module and the Apigee a… ([apichick](https://github.com/apichick)) <!-- 2023-04-27 12:53:51+00:00 -->
- [[#1342](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1342)] Add directory to vertex-mlops blueprint metadata ([juliocc](https://github.com/juliocc)) <!-- 2023-04-27 07:27:31+00:00 -->
- [[#1337](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1337)] Improve Vertex mlops blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-04-24 19:01:40+00:00 -->
- [[#1338](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1338)] Set all resource requests to the autopilot minimum as the existing va… ([apichick](https://github.com/apichick)) <!-- 2023-04-21 12:26:49+00:00 -->
- [[#1330](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1330)] Separating GKE Standard and Autopilot Modules ([avinashkumar1289](https://github.com/avinashkumar1289)) <!-- 2023-04-21 12:08:14+00:00 -->
- [[#1334](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1334)] Rename mlops blueprint providers file ([ludoo](https://github.com/ludoo)) <!-- 2023-04-18 09:44:09+00:00 -->
- [[#1333](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1333)] Add providers to vertex-mlops blueprint ([juliocc](https://github.com/juliocc)) <!-- 2023-04-18 08:05:15+00:00 -->
- [[#1331](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1331)] IAP for Cloud Run GA ([juliodiez](https://github.com/juliodiez)) <!-- 2023-04-17 14:43:08+00:00 -->
- [[#1309](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1309)] [DataPlatform] Fix data-eng role on orchestration project ([lcaggio](https://github.com/lcaggio)) <!-- 2023-04-12 14:23:01+00:00 -->
- [[#1323](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1323)] fix: create log-export-dataset on shielded-folder when no ecryption keys are defined ([bgdanix](https://github.com/bgdanix)) <!-- 2023-04-12 13:43:25+00:00 -->
- [[#1319](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1319)] Fixed wait_time in locust script ([apichick](https://github.com/apichick)) <!-- 2023-04-12 08:39:45+00:00 -->
- [[#1312](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1312)] add firewall enforcement variable to VPC ([fawzihmouda](https://github.com/fawzihmouda)) <!-- 2023-04-11 14:09:38+00:00 -->
- [[#1305](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1305)] add missing enable_addons reference in gke blueprint for multitenant-… ([jackspyder](https://github.com/jackspyder)) <!-- 2023-04-11 13:15:39+00:00 -->
- [[#1306](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1306)] Support new fields in bigquery module, bump provider versions, unpin local provider ([ludoo](https://github.com/ludoo)) <!-- 2023-04-05 14:22:53+00:00 -->
- [[#1293](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1293)] Refactor cloud run module to use optionals and support all features ([ludoo](https://github.com/ludoo)) <!-- 2023-04-01 12:06:30+00:00 -->
- [[#1289](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1289)] **incompatible change:** Network Dashboard improvements and bug fixing ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-03-29 12:54:07+00:00 -->
- [[#1283](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1283)] Fixed permissions of files created ([apichick](https://github.com/apichick)) <!-- 2023-03-27 19:33:49+00:00 -->
- [[#1274](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1274)] Add support for VPC Connector and different monitoring project to network dashboard deploy ([ludoo](https://github.com/ludoo)) <!-- 2023-03-24 14:29:13+00:00 -->

### DOCUMENTATION

- [[#1393](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1393)] Update README.md ([juliocc](https://github.com/juliocc)) <!-- 2023-05-24 10:59:14+00:00 -->
- [[#1379](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1379)] Update to multiple README.md ([bluPhy](https://github.com/bluPhy)) <!-- 2023-05-16 06:11:34+00:00 -->
- [[#1375](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1375)] Several updates ([bluPhy](https://github.com/bluPhy)) <!-- 2023-05-15 21:08:19+00:00 -->
- [[#1377](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1377)] Fixed home path ([skalolazka](https://github.com/skalolazka)) <!-- 2023-05-15 11:29:02+00:00 -->
- [[#1362](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1362)] Add Minimal Data Platform blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-05-08 08:25:07+00:00 -->
- [[#1357](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1357)] Add module link to README ([prabhaarya](https://github.com/prabhaarya)) <!-- 2023-05-05 08:10:09+00:00 -->
- [[#1347](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1347)] Fix external documentation links ([bobidle](https://github.com/bobidle)) <!-- 2023-05-02 05:26:58+00:00 -->
- [[#1330](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1330)] Separating GKE Standard and Autopilot Modules ([avinashkumar1289](https://github.com/avinashkumar1289)) <!-- 2023-04-21 12:08:14+00:00 -->
- [[#1309](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1309)] [DataPlatform] Fix data-eng role on orchestration project ([lcaggio](https://github.com/lcaggio)) <!-- 2023-04-12 14:23:01+00:00 -->
- [[#1311](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1311)] Fixed type in readme for FAST stages ([derailed-dash](https://github.com/derailed-dash)) <!-- 2023-04-08 19:56:19+00:00 -->
- [[#892](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/892)] Add network NVA NCC stage ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-04-04 18:41:05+00:00 -->
- [[#1297](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1297)] Update CONTRIBUTING.md ([juliocc](https://github.com/juliocc)) <!-- 2023-04-03 12:25:08+00:00 -->
- [[#1276](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1276)] DNS Response Policy module ([ludoo](https://github.com/ludoo)) <!-- 2023-03-26 15:42:58+00:00 -->

### FAST

- [[#1394](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1394)] Allow setting identities in VPC SC module egress policies ([ludoo](https://github.com/ludoo)) <!-- 2023-05-24 10:05:16+00:00 -->
- [[#1391](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1391)] fix(stages): only add sandbox SA when `sandbox` feature is enabled ([gustavovalverde](https://github.com/gustavovalverde)) <!-- 2023-05-24 05:17:35+00:00 -->
- [[#1385](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1385)] Add conditional org admin role to sandbox SA ([ludoo](https://github.com/ludoo)) <!-- 2023-05-21 08:48:41+00:00 -->
- [[#1383](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1383)] Allows groups from other orgs/domains ([drebes](https://github.com/drebes)) <!-- 2023-05-17 09:07:48+00:00 -->
- [[#1375](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1375)] Several updates ([bluPhy](https://github.com/bluPhy)) <!-- 2023-05-15 21:08:19+00:00 -->
- [[#1376](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1376)] fixed permissions for security stage SA ([alx13](https://github.com/alx13)) <!-- 2023-05-15 10:20:34+00:00 -->
- [[#1367](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1367)] fix routes priority typo ([fawzihmouda](https://github.com/fawzihmouda)) <!-- 2023-05-09 14:26:24+00:00 -->
- [[#1358](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1358)] update variables files for gke nodepool taints ([jackspyder](https://github.com/jackspyder)) <!-- 2023-05-05 17:42:00+00:00 -->
- [[#1352](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1352)] **incompatible change:** Switch FAST networking stages to network policies for Google domains ([ludoo](https://github.com/ludoo)) <!-- 2023-05-04 05:38:41+00:00 -->
- [[#1346](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1346)] **incompatible change:** FAST: shorten stage 3 prefixes, enforce prefix length in stage 3s ([ludoo](https://github.com/ludoo)) <!-- 2023-05-03 05:39:41+00:00 -->
- [[#1344](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1344)] Add logging details to bootstrap outputs ([juliocc](https://github.com/juliocc)) <!-- 2023-04-27 11:27:25+00:00 -->
- [[#1324](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1324)] Fix typo in FAST cicd extra stage variable name ([ludoo](https://github.com/ludoo)) <!-- 2023-04-17 07:40:05+00:00 -->
- [[#1328](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1328)] Strip org name from deploy key repo in FAST cicd stage ([ludoo](https://github.com/ludoo)) <!-- 2023-04-17 06:59:08+00:00 -->
- [[#1318](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1318)] Allow longer org prefix plus tenant prefix ([derailed-dash](https://github.com/derailed-dash)) <!-- 2023-04-11 23:36:37+00:00 -->
- [[#1315](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1315)] Fix stage links script for multitenant stages ([ludoo](https://github.com/ludoo)) <!-- 2023-04-11 09:43:39+00:00 -->
- [[#1313](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1313)] Fixed typo in readme for FAST multitenant ([derailed-dash](https://github.com/derailed-dash)) <!-- 2023-04-11 02:47:04+00:00 -->
- [[#892](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/892)] Add network NVA NCC stage ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-04-04 18:41:05+00:00 -->
- [[#1285](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1285)] Update YAML schema for hierarchical firewall rules ([sruffilli](https://github.com/sruffilli)) <!-- 2023-03-30 06:30:53+00:00 -->
- [[#1284](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1284)] Update Provider and Terraform variables section in FAST project factory ([gcardamone](https://github.com/gcardamone)) <!-- 2023-03-28 14:18:45+00:00 -->

### MODULES

- [[#1395](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1395)] allow to configure stack type in GKE autopilot ([NitriKx](https://github.com/NitriKx)) <!-- 2023-05-24 10:19:43+00:00 -->
- [[#1394](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1394)] Allow setting identities in VPC SC module egress policies ([ludoo](https://github.com/ludoo)) <!-- 2023-05-24 10:05:16+00:00 -->
- [[#1387](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1387)] Add default Cloud Build SA to project module ([juliocc](https://github.com/juliocc)) <!-- 2023-05-22 17:25:18+00:00 -->
- [[#1386](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1386)] Support CMEK encryption in logging-bucket module ([afda16](https://github.com/afda16)) <!-- 2023-05-22 14:28:16+00:00 -->
- [[#1375](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1375)] Several updates ([bluPhy](https://github.com/bluPhy)) <!-- 2023-05-15 21:08:19+00:00 -->
- [[#1372](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1372)] Cloud NAT rules support ([juliocc](https://github.com/juliocc)) <!-- 2023-05-14 13:42:34+00:00 -->
- [[#1374](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1374)] added the export_public_ip_routes variable in the net-vpc-peering mod… ([itManuel](https://github.com/itManuel)) <!-- 2023-05-14 13:29:24+00:00 -->
- [[#1373](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1373)] Made available CPUs configurable in Cloud Functions module ([apichick](https://github.com/apichick)) <!-- 2023-05-13 07:59:35+00:00 -->
- [[#1365](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1365)] feat(net-cloudnat): add toggle for independent endpoint mapping and dynamic port allocation ([JSchwerberg](https://github.com/JSchwerberg)) <!-- 2023-05-12 13:38:01+00:00 -->
- [[#1367](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1367)] fix routes priority typo ([fawzihmouda](https://github.com/fawzihmouda)) <!-- 2023-05-09 14:26:24+00:00 -->
- [[#1360](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1360)] Add support for Shared VPC in Cloud Run ([juliodiez](https://github.com/juliodiez)) <!-- 2023-05-05 18:17:49+00:00 -->
- [[#1329](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1329)] fix: Change net-lb-app-ext serve_while_stale type to number ([tobbbles](https://github.com/tobbbles)) <!-- 2023-05-05 07:41:13+00:00 -->
- [[#1308](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1308)] Add cloud dataplex module ([prabhaarya](https://github.com/prabhaarya)) <!-- 2023-05-05 07:26:46+00:00 -->
- [[#1352](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1352)] **incompatible change:** Switch FAST networking stages to network policies for Google domains ([ludoo](https://github.com/ludoo)) <!-- 2023-05-04 05:38:41+00:00 -->
- [[#1349](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1349)] Enhance GKE Backup Configuration Support ([tacchino](https://github.com/tacchino)) <!-- 2023-05-02 14:59:12+00:00 -->
- [[#1348](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1348)] Ignore entire node config in standard cluster ([ludoo](https://github.com/ludoo)) <!-- 2023-05-02 13:23:03+00:00 -->
- [[#1337](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1337)] Improve Vertex mlops blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-04-24 19:01:40+00:00 -->
- [[#1330](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1330)] Separating GKE Standard and Autopilot Modules ([avinashkumar1289](https://github.com/avinashkumar1289)) <!-- 2023-04-21 12:08:14+00:00 -->
- [[#1336](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1336)] Certificate renewal through terraform  ([bjohnrl](https://github.com/bjohnrl)) <!-- 2023-04-19 09:20:01+00:00 -->
- [[#1335](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1335)] Inconsistent conditional result types error in net-vpc module ([jamesmao-xyz](https://github.com/jamesmao-xyz)) <!-- 2023-04-18 11:07:17+00:00 -->
- [[#1332](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1332)] Add CMEK support on Secret manager module ([lcaggio](https://github.com/lcaggio)) <!-- 2023-04-18 05:05:10+00:00 -->
- [[#1326](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1326)] Remove net-interconnect-attachment-direct ([juliocc](https://github.com/juliocc)) <!-- 2023-04-14 09:28:26+00:00 -->
- [[#1322](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1322)] Add inventories to net-vpc-firewall tests ([juliocc](https://github.com/juliocc)) <!-- 2023-04-12 12:27:34+00:00 -->
- [[#1320](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1320)] issue #1303: net-vpc-firewall module supporting source and destination ranges ([ajlopezn](https://github.com/ajlopezn)) <!-- 2023-04-12 10:32:18+00:00 -->
- [[#1312](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1312)] add firewall enforcement variable to VPC ([fawzihmouda](https://github.com/fawzihmouda)) <!-- 2023-04-11 14:09:38+00:00 -->
- [[#1310](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1310)] Use labels var in cloud-run module ([LiuVII](https://github.com/LiuVII)) <!-- 2023-04-11 03:06:13+00:00 -->
- [[#1306](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1306)] Support new fields in bigquery module, bump provider versions, unpin local provider ([ludoo](https://github.com/ludoo)) <!-- 2023-04-05 14:22:53+00:00 -->
- [[#1301](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1301)] Add ability to run vtysh from simple-nva vm directly when frr is active ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-04-03 19:37:02+00:00 -->
- [[#1300](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1300)] Fix vtysh ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-04-03 14:37:46+00:00 -->
- [[#1299](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1299)] Fix urlmap in ILB L7 module ([ludoo](https://github.com/ludoo)) <!-- 2023-04-03 13:47:38+00:00 -->
- [[#1298](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1298)] Add sample vtysh file to remove warnings ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-04-03 13:10:47+00:00 -->
- [[#1293](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1293)] Refactor cloud run module to use optionals and support all features ([ludoo](https://github.com/ludoo)) <!-- 2023-04-01 12:06:30+00:00 -->
- [[#1287](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1287)] **incompatible change:** Add support for backup and remove deprecated control plane field in GKE module ([valeriobponza](https://github.com/valeriobponza)) <!-- 2023-03-30 10:47:40+00:00 -->
- [[#1295](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1295)] Load all service agents identities from yaml ([juliocc](https://github.com/juliocc)) <!-- 2023-03-30 07:02:05+00:00 -->
- [[#1294](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1294)] Add Cloud Batch service identity ([wiktorn](https://github.com/wiktorn)) <!-- 2023-03-30 06:05:12+00:00 -->
- [[#1280](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1280)] Add Dataplex Service Identity  ([wiktorn](https://github.com/wiktorn)) <!-- 2023-03-27 20:11:07+00:00 -->
- [[#1282](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1282)] Added local firewall management (iptables) on the NVA for dealing with COS default deny on inbound connections ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-03-27 14:32:57+00:00 -->
- [[#1281](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1281)] Use unique bundle name for Cloud Function ([wiktorn](https://github.com/wiktorn)) <!-- 2023-03-27 12:13:38+00:00 -->
- [[#1278](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1278)] DNS policy module fixes ([ludoo](https://github.com/ludoo)) <!-- 2023-03-26 16:39:07+00:00 -->
- [[#1276](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1276)] DNS Response Policy module ([ludoo](https://github.com/ludoo)) <!-- 2023-03-26 15:42:58+00:00 -->

### TOOLS

- [[#1375](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1375)] Several updates ([bluPhy](https://github.com/bluPhy)) <!-- 2023-05-15 21:08:19+00:00 -->
- [[#1359](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1359)] Blueprint metadata validator ([juliocc](https://github.com/juliocc)) <!-- 2023-05-05 15:20:15+00:00 -->
- [[#1340](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1340)] Extend tests to use lockfile if available ([juliocc](https://github.com/juliocc)) <!-- 2023-04-26 09:10:13+00:00 -->
- [[#1339](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1339)] Deprecate plan runner fixture and all its variants ([juliocc](https://github.com/juliocc)) <!-- 2023-04-22 11:43:51+00:00 -->
- [[#1327](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1327)] Migrate more tests ([juliocc](https://github.com/juliocc)) <!-- 2023-04-17 07:18:07+00:00 -->
- [[#1307](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1307)] Bump Terraform version ([ludoo](https://github.com/ludoo)) <!-- 2023-04-05 07:15:23+00:00 -->

## [21.0.0] - 2023-03-24
<!-- 2023-03-24 12:44:02+00:00 < 2023-02-04 13:47:22+00:00 -->

### BLUEPRINTS

- [[#1272](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1272)] Removed repeated command in script used to deploy API proxy ([apichick](https://github.com/apichick)) <!-- 2023-03-22 10:16:39+00:00 -->
- [[#1261](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1261)] Fix variable terraform.tfvars.sample ([dedeco](https://github.com/dedeco)) <!-- 2023-03-17 10:13:11+00:00 -->
- [[#1257](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1257)] Fixes related to boot_disk in compute-vm module ([apichick](https://github.com/apichick)) <!-- 2023-03-16 15:24:26+00:00 -->
- [[#1256](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1256)] **incompatible change:** Pin local provider ([ludoo](https://github.com/ludoo)) <!-- 2023-03-16 10:59:07+00:00 -->
- [[#1245](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1245)] Composer-2 - Fix 1236 ([lcaggio](https://github.com/lcaggio)) <!-- 2023-03-13 20:48:22+00:00 -->
- [[#1243](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1243)] Autopilot fixes ([apichick](https://github.com/apichick)) <!-- 2023-03-13 13:17:20+00:00 -->
- [[#1241](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1241)] **incompatible change:** Allow using existing boot disk in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2023-03-12 09:54:00+00:00 -->
- [[#1218](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1218)] Small fixes on Network Dashboard cloud function code ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-03-12 09:53:22+00:00 -->
- [[#1229](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1229)] Removed unnecessary files ([apichick](https://github.com/apichick)) <!-- 2023-03-09 13:06:18+00:00 -->
- [[#1227](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1227)] Add CMEK support on BQML blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-03-09 09:12:50+00:00 -->
- [[#1225](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1225)] Fix on bqml demo ([gioconte](https://github.com/gioconte)) <!-- 2023-03-08 17:40:40+00:00 -->
- [[#1217](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1217)] Added autopilot blueprint ([apichick](https://github.com/apichick)) <!-- 2023-03-07 15:05:15+00:00 -->
- [[#1210](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1210)] Blueprint - BigQuery ML and Vertex AI Pipeline ([lcaggio](https://github.com/lcaggio)) <!-- 2023-03-06 12:51:02+00:00 -->
- [[#1208](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1208)] Fix outdated go deps, dependabot alerts ([averbuks](https://github.com/averbuks)) <!-- 2023-03-03 06:15:09+00:00 -->
- [[#1150](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1150)] Blueprint: GLB hybrid NEG internal ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-03-02 08:53:07+00:00 -->
- [[#1201](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1201)] Add missing tfvars template to the tfc blueprint ([averbuks](https://github.com/averbuks)) <!-- 2023-03-01 20:10:46+00:00 -->
- [[#1196](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1196)] Fix compute-vm:CloudKMS test for provider>=4.54.0 ([dan-farmer](https://github.com/dan-farmer)) <!-- 2023-02-28 15:53:41+00:00 -->
- [[#1189](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1189)] Update healthchecker deps (dependabot alerts) ([averbuks](https://github.com/averbuks)) <!-- 2023-02-27 21:48:49+00:00 -->
- [[#1184](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1184)] **incompatible change:** Allow multiple peer gateways in VPN HA module ([ludoo](https://github.com/ludoo)) <!-- 2023-02-27 10:19:00+00:00 -->
- [[#1143](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1143)] Test blueprints from README files ([juliocc](https://github.com/juliocc)) <!-- 2023-02-27 08:57:41+00:00 -->
- [[#1181](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1181)] Bump golang.org/x/sys from 0.0.0-20220310020820-b874c991c1a5 to 0.1.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/healthchecker ([dependabot[bot]](<https://github.com/dependabot[bot]>)) <!-- 2023-02-25 17:02:08+00:00 -->
- [[#1180](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1180)] Bump golang.org/x/sys from 0.0.0-20220310020820-b874c991c1a5 to 0.1.0 in /blueprints/cloud-operations/unmanaged-instances-healthcheck/function/restarter ([dependabot[bot]](<https://github.com/dependabot[bot]>)) <!-- 2023-02-25 16:47:56+00:00 -->
- [[#1175](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1175)] Serverless networking program ([juliodiez](https://github.com/juliodiez)) <!-- 2023-02-25 10:15:12+00:00 -->
- [[#1179](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1179)] Added a PSC GCLB example ([cgrotz](https://github.com/cgrotz)) <!-- 2023-02-24 20:09:31+00:00 -->
- [[#1165](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1165)] DataPlatform: Support project creation ([lcaggio](https://github.com/lcaggio)) <!-- 2023-02-23 11:10:44+00:00 -->
- [[#1167](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1167)] **incompatible change:** Simplify org policies in resource management modules ([juliocc](https://github.com/juliocc)) <!-- 2023-02-21 15:08:43+00:00 -->
- [[#1161](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1161)] Additional documentation for the Data Platform Dataflow pipeline example ([aymanfarhat](https://github.com/aymanfarhat)) <!-- 2023-02-16 19:09:52+00:00 -->
- [[#1154](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1154)] Workaround to mitigate provider issue 9164 ([lcaggio](https://github.com/lcaggio)) <!-- 2023-02-14 05:37:19+00:00 -->
- [[#1146](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1146)] Serverless networking program ([juliodiez](https://github.com/juliodiez)) <!-- 2023-02-10 19:08:14+00:00 -->
- [[#1142](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1142)] Fix bq factory docs ([juliocc](https://github.com/juliocc)) <!-- 2023-02-08 17:38:03+00:00 -->
- [[#1138](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1138)] New compute-vm examples and tests ([juliocc](https://github.com/juliocc)) <!-- 2023-02-07 16:48:31+00:00 -->
- [[#1132](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1132)] Add descriptive name as optional argument ([paulwoelfel](https://github.com/paulwoelfel)) <!-- 2023-02-06 17:22:32+00:00 -->
- [[#1105](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1105)] [Feature] Update data platform blue print with Dataflow Flex template ([aymanfarhat](https://github.com/aymanfarhat)) <!-- 2023-02-06 06:35:41+00:00 -->
- [[#1129](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1129)] Update KMS blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-02-05 20:26:23+00:00 -->

### DOCUMENTATION

- [[#1257](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1257)] Fixes related to boot_disk in compute-vm module ([apichick](https://github.com/apichick)) <!-- 2023-03-16 15:24:26+00:00 -->
- [[#1248](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1248)] Add link to public serverless networking guide ([juliodiez](https://github.com/juliodiez)) <!-- 2023-03-14 17:05:45+00:00 -->
- [[#1232](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1232)] Network firewall policy module ([ludoo](https://github.com/ludoo)) <!-- 2023-03-10 08:21:50+00:00 -->
- [[#1230](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1230)] Update contributing guide with new test framework ([juliocc](https://github.com/juliocc)) <!-- 2023-03-09 14:16:08+00:00 -->
- [[#1221](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1221)] FAQ on installing Fast on a non-empty org ([skalolazka](https://github.com/skalolazka)) <!-- 2023-03-07 16:23:46+00:00 -->
- [[#1217](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1217)] Added autopilot blueprint ([apichick](https://github.com/apichick)) <!-- 2023-03-07 15:05:15+00:00 -->
- [[#1210](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1210)] Blueprint - BigQuery ML and Vertex AI Pipeline ([lcaggio](https://github.com/lcaggio)) <!-- 2023-03-06 12:51:02+00:00 -->
- [[#1150](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1150)] Blueprint: GLB hybrid NEG internal ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-03-02 08:53:07+00:00 -->
- [[#1193](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1193)] Add reference to Cloud Run blueprints ([juliodiez](https://github.com/juliodiez)) <!-- 2023-02-28 10:16:45+00:00 -->
- [[#1188](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1188)] Add reference to Cloud Run blueprints ([juliodiez](https://github.com/juliodiez)) <!-- 2023-02-27 21:22:31+00:00 -->
- [[#1187](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1187)] Add references to the serverless chapters ([juliodiez](https://github.com/juliodiez)) <!-- 2023-02-27 17:16:20+00:00 -->
- [[#1179](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1179)] Added a PSC GCLB example ([cgrotz](https://github.com/cgrotz)) <!-- 2023-02-24 20:09:31+00:00 -->
- [[#1165](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1165)] DataPlatform: Support project creation ([lcaggio](https://github.com/lcaggio)) <!-- 2023-02-23 11:10:44+00:00 -->
- [[#1145](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1145)] FAST stage docs cleanup ([ludoo](https://github.com/ludoo)) <!-- 2023-02-15 05:42:14+00:00 -->
- [[#1137](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1137)] **incompatible change:** Allow configuring regions from tfvars in FAST networking stages ([ludoo](https://github.com/ludoo)) <!-- 2023-02-08 08:59:43+00:00 -->
- [[#1105](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1105)] [Feature] Update data platform blue print with Dataflow Flex template ([aymanfarhat](https://github.com/aymanfarhat)) <!-- 2023-02-06 06:35:41+00:00 -->
- [[#1052](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1052)] **incompatible change:** FAST multitenant bootstrap and resource management, rename org-level FAST stages ([ludoo](https://github.com/ludoo)) <!-- 2023-02-04 14:00:46+00:00 -->

### FAST

- [[#1266](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1266)] FAST plugin system ([ludoo](https://github.com/ludoo)) <!-- 2023-03-24 12:28:32+00:00 -->
- [[#1273](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1273)] Small fixes to FAST Networking stage with NVAs  ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-03-23 08:57:01+00:00 -->
- [[#1265](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1265)] Fix FAST hub and spoke with VPN networking stage ([ludoo](https://github.com/ludoo)) <!-- 2023-03-17 19:52:40+00:00 -->
- [[#1263](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1263)] Widen scope for prod project factory SA to dev ([ludoo](https://github.com/ludoo)) <!-- 2023-03-17 16:24:56+00:00 -->
- [[#1240](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1240)] feat: Enable populating of data directory and .sample files and update dependencies in 0-cicd-github ([antonkovach](https://github.com/antonkovach)) <!-- 2023-03-15 13:55:08+00:00 -->
- [[#1249](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1249)] Document need to set `outputs_location` explicitly in every stage ([ludoo](https://github.com/ludoo)) <!-- 2023-03-15 10:43:44+00:00 -->
- [[#1247](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1247)] Fast: resman: location and storage class added to GKE GCS buckets ([skalolazka](https://github.com/skalolazka)) <!-- 2023-03-14 15:37:16+00:00 -->
- [[#1241](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1241)] **incompatible change:** Allow using existing boot disk in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2023-03-12 09:54:00+00:00 -->
- [[#1237](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1237)] Add missing attribute to FAST onprem VPN examples ([ludoo](https://github.com/ludoo)) <!-- 2023-03-10 14:58:34+00:00 -->
- [[#1228](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1228)] **incompatible change:** Simplify VPN implementation in FAST networking stages ([ludoo](https://github.com/ludoo)) <!-- 2023-03-09 16:57:45+00:00 -->
- [[#1222](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1222)] Manage billing.creator role authoritatively in FAST bootstrap. ([juliocc](https://github.com/juliocc)) <!-- 2023-03-07 18:04:07+00:00 -->
- [[#1213](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1213)] feat: Add Pull Request support to 0-cicd-github ([antonkovach](https://github.com/antonkovach)) <!-- 2023-03-06 08:32:36+00:00 -->
- [[#1203](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1203)] Update subnet sample yaml files to use subnet_secondary_ranges ([jmound](https://github.com/jmound)) <!-- 2023-03-05 18:37:23+00:00 -->
- [[#1212](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1212)] feat: skip committing unchanged files in 0-cicd-github ([antonkovach](https://github.com/antonkovach)) <!-- 2023-03-05 18:16:48+00:00 -->
- [[#1211](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1211)] **incompatible change:** Add support for proxy and psc subnets to net-vpc module factory ([ludoo](https://github.com/ludoo)) <!-- 2023-03-05 16:08:43+00:00 -->
- [[#1209](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1209)] Billing exclusion support for FAST mt resman ([ludoo](https://github.com/ludoo)) <!-- 2023-03-03 16:23:37+00:00 -->
- [[#1207](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1207)] Allow preventing creation of billing IAM roles in FAST, add instructions on delayed billing association ([ludoo](https://github.com/ludoo)) <!-- 2023-03-03 08:24:42+00:00 -->
- [[#1184](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1184)] **incompatible change:** Allow multiple peer gateways in VPN HA module ([ludoo](https://github.com/ludoo)) <!-- 2023-02-27 10:19:00+00:00 -->
- [[#1165](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1165)] DataPlatform: Support project creation ([lcaggio](https://github.com/lcaggio)) <!-- 2023-02-23 11:10:44+00:00 -->
- [[#1170](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1170)] Add documentation about referring modules stored on CSR ([wiktorn](https://github.com/wiktorn)) <!-- 2023-02-22 09:02:54+00:00 -->
- [[#1167](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1167)] **incompatible change:** Simplify org policies in resource management modules ([juliocc](https://github.com/juliocc)) <!-- 2023-02-21 15:08:43+00:00 -->
- [[#1164](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1164)] fix module_prefix in fast extras 0-cicd-github ([antonkovach](https://github.com/antonkovach)) <!-- 2023-02-19 18:22:42+00:00 -->
- [[#1162](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1162)] Fix Terraform formatting and add module_prefix attribute to modules_config ([antonkovach](https://github.com/antonkovach)) <!-- 2023-02-19 17:01:38+00:00 -->
- [[#1145](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1145)] FAST stage docs cleanup ([ludoo](https://github.com/ludoo)) <!-- 2023-02-15 05:42:14+00:00 -->
- [[#1137](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1137)] **incompatible change:** Allow configuring regions from tfvars in FAST networking stages ([ludoo](https://github.com/ludoo)) <!-- 2023-02-08 08:59:43+00:00 -->
- [[#1133](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1133)] Align VPN peer interface to module in FAST net VPN stage ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-02-07 22:58:28+00:00 -->
- [[#1135](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1135)] Post PR message in GitHub workflow on init or validate failure ([ludoo](https://github.com/ludoo)) <!-- 2023-02-07 09:04:04+00:00 -->
- [[#1134](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1134)] Fix stage 1 output file names and stage links script ([ludoo](https://github.com/ludoo)) <!-- 2023-02-06 19:51:26+00:00 -->
- [[#1128](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1128)] Remove info about non-existing vpc-peering-*.tf files ([skalolazka](https://github.com/skalolazka)) <!-- 2023-02-06 10:36:15+00:00 -->
- [[#1052](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1052)] **incompatible change:** FAST multitenant bootstrap and resource management, rename org-level FAST stages ([ludoo](https://github.com/ludoo)) <!-- 2023-02-04 14:00:46+00:00 -->

### MODULES

- [[#1270](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1270)] Add static gateway id to outputs of VPN ha module ([ludoo](https://github.com/ludoo)) <!-- 2023-03-21 17:08:46+00:00 -->
- [[#1269](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1269)] Ignore changes to metadata.0.annotations in Cloud Run module ([juliocc](https://github.com/juliocc)) <!-- 2023-03-21 11:21:59+00:00 -->
- [[#1267](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1267)] Improvements to NCC-RA spoke module. ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-03-21 07:07:44+00:00 -->
- [[#1268](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1268)] simple-nva: add ability to parse BGP configs as strings. ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-03-21 06:41:13+00:00 -->
- [[#1258](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1258)] Add backend service names to outputs for net-lb-app-ext and net-lb-app-int  ([rosmo](https://github.com/rosmo)) <!-- 2023-03-17 10:40:11+00:00 -->
- [[#1259](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1259)] Add support for `iam_additive` and simplify factory interface in net VPC module ([ludoo](https://github.com/ludoo)) <!-- 2023-03-17 10:12:35+00:00 -->
- [[#1255](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1255)] **incompatible change:** Change `target_vpcs` variable in firewall policy module to support dynamic values ([ludoo](https://github.com/ludoo)) <!-- 2023-03-17 07:14:10+00:00 -->
- [[#1256](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1256)] **incompatible change:** Pin local provider ([ludoo](https://github.com/ludoo)) <!-- 2023-03-16 10:59:07+00:00 -->
- [[#1246](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1246)] Delay creation of SVPC host bindings until APIs and JIT SAs are done ([juliocc](https://github.com/juliocc)) <!-- 2023-03-14 14:16:59+00:00 -->
- [[#1241](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1241)] **incompatible change:** Allow using existing boot disk in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2023-03-12 09:54:00+00:00 -->
- [[#1239](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1239)] Allow overriding name in net-vpc subnet factory ([ludoo](https://github.com/ludoo)) <!-- 2023-03-11 08:30:43+00:00 -->
- [[#1226](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1226)] Fix policy_based_routing.sh script on simple-nva module ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-03-10 17:36:08+00:00 -->
- [[#1234](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1234)] Fixed connection tracking configuration on LB backend in net-lb-int module  ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-03-10 14:25:30+00:00 -->
- [[#1232](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1232)] Network firewall policy module ([ludoo](https://github.com/ludoo)) <!-- 2023-03-10 08:21:50+00:00 -->
- [[#1219](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1219)] Network Connectivity Center module ([juliodiez](https://github.com/juliodiez)) <!-- 2023-03-09 15:01:51+00:00 -->
- [[#1227](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1227)] Add CMEK support on BQML blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-03-09 09:12:50+00:00 -->
- [[#1224](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1224)] Fix JIT notebook service account. ([lcaggio](https://github.com/lcaggio)) <!-- 2023-03-08 15:33:40+00:00 -->
- [[#1195](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1195)] Extended simple-nva module to manage BGP service running on FR routing docker container ([simonebruzzechesse](https://github.com/simonebruzzechesse)) <!-- 2023-03-08 08:43:13+00:00 -->
- [[#1211](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1211)] **incompatible change:** Add support for proxy and psc subnets to net-vpc module factory ([ludoo](https://github.com/ludoo)) <!-- 2023-03-05 16:08:43+00:00 -->
- [[#1206](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1206)] Dataproc module. Fix output. ([lcaggio](https://github.com/lcaggio)) <!-- 2023-03-02 12:59:19+00:00 -->
- [[#1205](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1205)] Fix issue with GKE cluster notifications topic & static output for pubsub module ([rosmo](https://github.com/rosmo)) <!-- 2023-03-02 10:43:40+00:00 -->
- [[#1204](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1204)] Fix url_redirect issue on net-lb-app-ext module ([erabusi](https://github.com/erabusi)) <!-- 2023-03-02 06:51:40+00:00 -->
- [[#1199](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1199)] [Dataproc module] Fix Variables ([lcaggio](https://github.com/lcaggio)) <!-- 2023-03-01 11:16:11+00:00 -->
- [[#1200](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1200)] Add test for #1197 ([juliocc](https://github.com/juliocc)) <!-- 2023-03-01 09:15:13+00:00 -->
- [[#1198](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1198)] Fix secondary ranges in net-vpc readme ([ludoo](https://github.com/ludoo)) <!-- 2023-03-01 07:08:08+00:00 -->
- [[#1196](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1196)] Fix compute-vm:CloudKMS test for provider>=4.54.0 ([dan-farmer](https://github.com/dan-farmer)) <!-- 2023-02-28 15:53:41+00:00 -->
- [[#1194](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1194)] Fix HTTPS health check mismapped to HTTP in compute-mig and net-lb-int modules ([jogoldberg](https://github.com/jogoldberg)) <!-- 2023-02-28 14:48:13+00:00 -->
- [[#1192](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1192)] Dataproc module: Fix outputs ([lcaggio](https://github.com/lcaggio)) <!-- 2023-02-28 10:47:23+00:00 -->
- [[#1190](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1190)] Dataproc Module ([lcaggio](https://github.com/lcaggio)) <!-- 2023-02-28 06:45:41+00:00 -->
- [[#1191](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1191)] Fix external gateway in VPN HA module ([ludoo](https://github.com/ludoo)) <!-- 2023-02-27 23:46:51+00:00 -->
- [[#1186](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1186)] Fix Workload Identity for ASM in GKE hub module ([valeriobponza](https://github.com/valeriobponza)) <!-- 2023-02-27 19:17:45+00:00 -->
- [[#1184](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1184)] **incompatible change:** Allow multiple peer gateways in VPN HA module ([ludoo](https://github.com/ludoo)) <!-- 2023-02-27 10:19:00+00:00 -->
- [[#1177](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1177)] Implemented conditional dynamic blocks for `google_access_context_manager_service_perimeter` `spec` and `status` ([calexandre](https://github.com/calexandre)) <!-- 2023-02-25 16:04:19+00:00 -->
- [[#1178](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1178)] adding meshconfig.googleapis.com to JIT list. ([valeriobponza](https://github.com/valeriobponza)) <!-- 2023-02-24 18:28:05+00:00 -->
- [[#1174](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1174)] Don't define nor use health checks with SNEGs ([juliodiez](https://github.com/juliodiez)) <!-- 2023-02-24 10:39:50+00:00 -->
- [[#1172](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1172)] Allow to not use any health check ([juliodiez](https://github.com/juliodiez)) <!-- 2023-02-24 09:45:59+00:00 -->
- [[#1171](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1171)] Modifications related to autopilot and workload identity. Added workl… ([apichick](https://github.com/apichick)) <!-- 2023-02-24 09:14:18+00:00 -->
- [[#1167](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1167)] **incompatible change:** Simplify org policies in resource management modules ([juliocc](https://github.com/juliocc)) <!-- 2023-02-21 15:08:43+00:00 -->
- [[#1168](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1168)] Remove unused attribute from project module README example ([juliodiez](https://github.com/juliodiez)) <!-- 2023-02-21 14:14:05+00:00 -->
- [[#1166](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1166)] Fix variable name in VPC-SC module examples ([juliodiez](https://github.com/juliodiez)) <!-- 2023-02-20 14:33:54+00:00 -->
- [[#1153](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1153)] net-vpc - add missing iam properties to factory_subnets ([jamesdalf](https://github.com/jamesdalf)) <!-- 2023-02-20 11:34:47+00:00 -->
- [[#1163](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1163)] Projects-data-source module new version ([averbuks](https://github.com/averbuks)) <!-- 2023-02-19 14:44:29+00:00 -->
- [[#1160](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1160)] Allow additive IAM grants by robots name ([wiktorn](https://github.com/wiktorn)) <!-- 2023-02-16 13:39:21+00:00 -->
- [[#1158](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1158)] changed pod_range reference to include secondary_pod_range issue #1157 ([chemapolo](https://github.com/chemapolo)) <!-- 2023-02-15 05:28:48+00:00 -->
- [[#1156](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1156)] Add 'max_time_travel_hours ' support on BQ module ([lcaggio](https://github.com/lcaggio)) <!-- 2023-02-14 08:10:12+00:00 -->
- [[#1151](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1151)] Add example about referencing existing MIGs to net-lb-int module readme ([LucaPrete](https://github.com/LucaPrete)) <!-- 2023-02-11 16:45:16+00:00 -->
- [[#1149](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1149)] Add documentation about JIT-ed service accounts ([wiktorn](https://github.com/wiktorn)) <!-- 2023-02-11 14:52:47+00:00 -->
- [[#1131](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1131)] Add Autopilot Support for cluster_autoscaling Configuration in GKE Module ([tacchino](https://github.com/tacchino)) <!-- 2023-02-10 12:31:57+00:00 -->
- [[#1140](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1140)] CloudSQL Backup Configuration: Support Point In Time Recovery ([tacchino](https://github.com/tacchino)) <!-- 2023-02-10 11:24:50+00:00 -->
- [[#1147](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1147)] Fix gke-cluster dns config feature ([juliocc](https://github.com/juliocc)) <!-- 2023-02-10 10:28:35+00:00 -->
- [[#1144](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1144)] Fixes for service-mesh example in gke-hub ([wiktorn](https://github.com/wiktorn)) <!-- 2023-02-09 16:56:56+00:00 -->
- [[#1138](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1138)] New compute-vm examples and tests ([juliocc](https://github.com/juliocc)) <!-- 2023-02-07 16:48:31+00:00 -->
- [[#1052](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1052)] **incompatible change:** FAST multitenant bootstrap and resource management, rename org-level FAST stages ([ludoo](https://github.com/ludoo)) <!-- 2023-02-04 14:00:46+00:00 -->

### TOOLS

- [[#1266](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1266)] FAST plugin system ([ludoo](https://github.com/ludoo)) <!-- 2023-03-24 12:28:32+00:00 -->
- [[#1242](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1242)] Remove container image workflows ([kunzese](https://github.com/kunzese)) <!-- 2023-03-13 07:39:04+00:00 -->
- [[#1231](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1231)] Simplify testing workflow ([juliocc](https://github.com/juliocc)) <!-- 2023-03-09 15:27:05+00:00 -->
- [[#1216](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1216)] Use composite action for test workflow prerequisite steps ([ludoo](https://github.com/ludoo)) <!-- 2023-03-06 10:44:58+00:00 -->
- [[#1215](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1215)] Try plugin cache, split examples tests ([ludoo](https://github.com/ludoo)) <!-- 2023-03-06 09:38:40+00:00 -->
- [[#1211](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1211)] **incompatible change:** Add support for proxy and psc subnets to net-vpc module factory ([ludoo](https://github.com/ludoo)) <!-- 2023-03-05 16:08:43+00:00 -->
- [[#1209](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1209)] Billing exclusion support for FAST mt resman ([ludoo](https://github.com/ludoo)) <!-- 2023-03-03 16:23:37+00:00 -->
- [[#1208](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1208)] Fix outdated go deps, dependabot alerts ([averbuks](https://github.com/averbuks)) <!-- 2023-03-03 06:15:09+00:00 -->
- [[#1182](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1182)] Bump actions versions ([juliocc](https://github.com/juliocc)) <!-- 2023-02-25 16:27:20+00:00 -->
- [[#1052](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1052)] **incompatible change:** FAST multitenant bootstrap and resource management, rename org-level FAST stages ([ludoo](https://github.com/ludoo)) <!-- 2023-02-04 14:00:46+00:00 -->

## [20.0.0] - 2023-02-04
<!-- 2023-02-04 13:47:22+00:00 < 2022-12-13 10:03:24+00:00 -->

### BLUEPRINTS

- [[#1038](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1038)] Vertex Pipelines MLOps framework blueprint ([javiergp](https://github.com/javiergp)) <!-- 2023-02-02 18:13:13+00:00 -->
- [[#1124](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1124)] Removed unused file package-lock.json ([apichick](https://github.com/apichick)) <!-- 2023-02-01 17:54:25+00:00 -->
- [[#1119](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1119)] **incompatible change:** Multi-Cluster Ingress gateway api config ([wiktorn](https://github.com/wiktorn)) <!-- 2023-01-31 13:16:52+00:00 -->
- [[#1111](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1111)] **incompatible change:** In the apigee module now both the /22 and /28 peering IP ranges are p… ([apichick](https://github.com/apichick)) <!-- 2023-01-31 10:46:38+00:00 -->
- [[#1106](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1106)] Network Dashboard: PSA support for Filestore and Memorystore ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2023-01-25 15:02:31+00:00 -->
- [[#1110](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1110)] Bump cookiejar from 2.1.3 to 2.1.4 in /blueprints/apigee/bigquery-analytics/functions/export ([dependabot[bot]](<https://github.com/dependabot[bot]>)) <!-- 2023-01-24 15:07:12+00:00 -->
- [[#1097](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1097)] Use terraform resource to activate Anthos Service Mesh ([wiktorn](https://github.com/wiktorn)) <!-- 2023-01-23 08:25:31+00:00 -->
- [[#1104](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1104)] Updated apigee hybrid for gke README ([apichick](https://github.com/apichick)) <!-- 2023-01-22 10:34:48+00:00 -->
- [[#1107](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1107)] Check linting for Python dashboard files ([ludoo](https://github.com/ludoo)) <!-- 2023-01-21 16:17:52+00:00 -->
- [[#1102](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1102)] Improvements in apigee hybrid-gke: now using workload identity and GLB ([apichick](https://github.com/apichick)) <!-- 2023-01-20 12:32:08+00:00 -->
- [[#1098](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1098)] Add shared-vpc support on data-playground blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-01-19 08:08:29+00:00 -->
- [[#1095](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1095)] [Data Platform] Fix Table in readme ([lcaggio](https://github.com/lcaggio)) <!-- 2023-01-17 12:39:56+00:00 -->
- [[#1089](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1089)] Update Data Platform ([lcaggio](https://github.com/lcaggio)) <!-- 2023-01-12 22:17:05+00:00 -->
- [[#1081](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1081)] Apigee hybrid on GKE ([apichick](https://github.com/apichick)) <!-- 2023-01-05 08:23:33+00:00 -->
- [[#1082](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1082)] Fixes in Apigee Bigquery Analytics blueprint ([apichick](https://github.com/apichick)) <!-- 2023-01-04 16:42:50+00:00 -->
- [[#1071](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1071)] Moved apigee bigquery analytics blueprint, added apigee network patterns ([apichick](https://github.com/apichick)) <!-- 2022-12-23 15:16:45+00:00 -->
- [[#1073](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1073)] Allow setting no ranges in firewall module custom rules ([ludoo](https://github.com/ludoo)) <!-- 2022-12-23 08:03:31+00:00 -->
- [[#1072](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1072)] **incompatible change:** Add gc_policy to Bigtable module, bump provider versions to 4.47 ([iht](https://github.com/iht)) <!-- 2022-12-22 23:58:08+00:00 -->
- [[#1063](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1063)] Network dashboard: PSA ranges support, starting with Cloud SQL ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2022-12-22 12:14:42+00:00 -->
- [[#1062](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1062)] Fixes for GKE ([wiktorn](https://github.com/wiktorn)) <!-- 2022-12-21 22:14:52+00:00 -->
- [[#1060](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1060)] Update src/README.md for Network Dashboard ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2022-12-21 15:30:10+00:00 -->
- [[#1020](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1020)] Networking dashboard and discovery tool refactor ([ludoo](https://github.com/ludoo)) <!-- 2022-12-18 09:07:24+00:00 -->

### DOCUMENTATION

- [[#1101](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1101)] First batch of testing updates to core modules ([juliocc](https://github.com/juliocc)) <!-- 2023-01-20 06:49:41+00:00 -->
- [[#1089](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1089)] Update Data Platform ([lcaggio](https://github.com/lcaggio)) <!-- 2023-01-12 22:17:05+00:00 -->
- [[#1084](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1084)] Fixes in Apigee blueprints README files ([apichick](https://github.com/apichick)) <!-- 2023-01-05 11:00:46+00:00 -->
- [[#1081](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1081)] Apigee hybrid on GKE ([apichick](https://github.com/apichick)) <!-- 2023-01-05 08:23:33+00:00 -->
- [[#1074](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1074)] Adding new section for Authentication issues ([agutta](https://github.com/agutta)) <!-- 2022-12-29 15:50:23+00:00 -->
- [[#1071](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1071)] Moved apigee bigquery analytics blueprint, added apigee network patterns ([apichick](https://github.com/apichick)) <!-- 2022-12-23 15:16:45+00:00 -->
- [[#1057](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1057)] Adding new file FAQ and an image ([agutta](https://github.com/agutta)) <!-- 2022-12-22 14:00:22+00:00 -->

### FAST

- [[#1118](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1118)] Add missing logging admin role for initial user ([ludoo](https://github.com/ludoo)) <!-- 2023-01-28 08:41:23+00:00 -->
- [[#1099](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1099)] Fix destroy in stage 1 outputs ([ludoo](https://github.com/ludoo)) <!-- 2023-01-19 09:35:41+00:00 -->
- [[#1089](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1089)] Update Data Platform ([lcaggio](https://github.com/lcaggio)) <!-- 2023-01-12 22:17:05+00:00 -->
- [[#1085](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1085)] fix restricted services not being added to the perimeter configurations ([drebes](https://github.com/drebes)) <!-- 2023-01-06 12:25:31+00:00 -->
- [[#1057](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1057)] Adding new file FAQ and an image ([agutta](https://github.com/agutta)) <!-- 2022-12-22 14:00:22+00:00 -->
- [[#1054](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1054)] FAST: fix typo in bootstrap stage README ([agutta](https://github.com/agutta)) <!-- 2022-12-16 16:00:00+00:00 -->
- [[#1051](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1051)] FAST: add instructions for billing export to stage 0 README ([KPRepos](https://github.com/KPRepos)) <!-- 2022-12-15 08:53:57+00:00 -->

### MODULES

- [[#1127](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1127)] Skip node config for autopilot ([ludoo](https://github.com/ludoo)) <!-- 2023-02-02 15:13:57+00:00 -->
- [[#1125](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1125)] Added mesh_certificates setting in GKE cluster ([rosmo](https://github.com/rosmo)) <!-- 2023-02-02 10:19:01+00:00 -->
- [[#1094](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1094)] Added GLB example with MIG as backend ([eliamaldini](https://github.com/eliamaldini)) <!-- 2023-01-31 13:49:13+00:00 -->
- [[#1119](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1119)] **incompatible change:** Multi-Cluster Ingress gateway api config ([wiktorn](https://github.com/wiktorn)) <!-- 2023-01-31 13:16:52+00:00 -->
- [[#1111](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1111)] **incompatible change:** In the apigee module now both the /22 and /28 peering IP ranges are p… ([apichick](https://github.com/apichick)) <!-- 2023-01-31 10:46:38+00:00 -->
- [[#1116](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1116)] Include cloudbuild API in project module ([aymanfarhat](https://github.com/aymanfarhat)) <!-- 2023-01-27 20:38:01+00:00 -->
- [[#1115](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1115)] add new parameters support in apigee module ([blackillzone](https://github.com/blackillzone)) <!-- 2023-01-27 16:39:46+00:00 -->
- [[#1112](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1112)] Add HTTPS frontend with SNEG example ([juliodiez](https://github.com/juliodiez)) <!-- 2023-01-26 19:17:31+00:00 -->
- [[#1097](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1097)] Use terraform resource to activate Anthos Service Mesh ([wiktorn](https://github.com/wiktorn)) <!-- 2023-01-23 08:25:31+00:00 -->
- [[#1101](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1101)] First batch of testing updates to core modules ([juliocc](https://github.com/juliocc)) <!-- 2023-01-20 06:49:41+00:00 -->
- [[#1098](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1098)] Add shared-vpc support on data-playground blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2023-01-19 08:08:29+00:00 -->
- [[#1096](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1096)] [VPC-SC] Add support for scoped Policies ([lcaggio](https://github.com/lcaggio)) <!-- 2023-01-17 14:30:34+00:00 -->
- [[#1093](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1093)] Added tags to gke-cluster module ([apichick](https://github.com/apichick)) <!-- 2023-01-13 12:12:17+00:00 -->
- [[#1078](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1078)] Fixed delete_rule in compute-mig module for stateful disks ([rosmo](https://github.com/rosmo)) <!-- 2023-01-04 08:14:40+00:00 -->
- [[#1080](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1080)] Added device_name field to compute-vm attached_disks parameter  ([rosmo](https://github.com/rosmo)) <!-- 2023-01-03 20:53:48+00:00 -->
- [[#1079](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1079)] Reorder org policy rules ([juliocc](https://github.com/juliocc)) <!-- 2023-01-03 16:11:29+00:00 -->
- [[#1075](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1075)] **incompatible change:** Add cluster replicas to Bigtable module. ([iht](https://github.com/iht)) <!-- 2022-12-30 10:39:38+00:00 -->
- [[#1073](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1073)] Allow setting no ranges in firewall module custom rules ([ludoo](https://github.com/ludoo)) <!-- 2022-12-23 08:03:31+00:00 -->
- [[#1072](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1072)] **incompatible change:** Add gc_policy to Bigtable module, bump provider versions to 4.47 ([iht](https://github.com/iht)) <!-- 2022-12-22 23:58:08+00:00 -->
- [[#1070](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1070)] Fix MIG health check variable ([ludoo](https://github.com/ludoo)) <!-- 2022-12-22 17:12:17+00:00 -->
- [[#1069](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1069)] Allow tables with several column families in Bigtable ([iht](https://github.com/iht)) <!-- 2022-12-22 16:34:24+00:00 -->
- [[#1068](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1068)] Added endpoint_attachment_hosts output to apigee module ([apichick](https://github.com/apichick)) <!-- 2022-12-22 14:57:25+00:00 -->
- [[#1067](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1067)] Corrected load balancing scheme in backend service ([apichick](https://github.com/apichick)) <!-- 2022-12-22 11:41:06+00:00 -->
- [[#1066](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1066)] Refactor GCS module and tests for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-12-22 11:27:09+00:00 -->
- [[#1062](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1062)] Fixes for GKE ([wiktorn](https://github.com/wiktorn)) <!-- 2022-12-21 22:14:52+00:00 -->
- [[#1061](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1061)] **incompatible change:** Allow using dynamically generated address in LB modules NEGs ([ludoo](https://github.com/ludoo)) <!-- 2022-12-21 16:04:56+00:00 -->
- [[#1059](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1059)] Read ranges from correct fields in firewall factory ([juliocc](https://github.com/juliocc)) <!-- 2022-12-20 09:13:54+00:00 -->
- [[#1056](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1056)] Feature - CloudSQL pre-allocation private IP range and GKE Cluster ignore_change lifecycle hook. ([itsavvy-ankur](https://github.com/itsavvy-ankur)) <!-- 2022-12-20 07:08:01+00:00 -->

### TOOLS

- [[#1107](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1107)] Check linting for Python dashboard files ([ludoo](https://github.com/ludoo)) <!-- 2023-01-21 16:17:52+00:00 -->
- [[#1101](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1101)] First batch of testing updates to core modules ([juliocc](https://github.com/juliocc)) <!-- 2023-01-20 06:49:41+00:00 -->
- [[#1091](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1091)] Fix check_documentation output ([juliocc](https://github.com/juliocc)) <!-- 2023-01-12 14:43:13+00:00 -->
- [[#1053](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1053)] Extend inventory-based testing to examples ([juliocc](https://github.com/juliocc)) <!-- 2022-12-18 19:50:34+00:00 -->

## [19.0.0] - 2022-12-13
<!-- 2022-12-13 10:03:24+00:00 < 2022-09-09 18:02:15+00:00 -->

### BLUEPRINTS

- [[#1045](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1045)] Assorted module fixes ([ludoo](https://github.com/ludoo)) <!-- 2022-12-10 14:40:15+00:00 -->
- [[#1044](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1044)] **incompatible change:** Refactor net-lb-app-ext module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-12-08 16:35:45+00:00 -->
- [[#982](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/982)] Adding Secondary IP Utilization calculation ([brianhmj](https://github.com/brianhmj)) <!-- 2022-12-07 10:45:21+00:00 -->
- [[#1037](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1037)] Bump qs and formidable in /blueprints/cloud-operations/apigee/functions/export ([dependabot[bot]](<https://github.com/dependabot[bot]>)) <!-- 2022-12-06 15:43:35+00:00 -->
- [[#1034](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1034)] feat(blueprints): get audience from tfc environment variable ([Thomgrus](https://github.com/Thomgrus)) <!-- 2022-12-05 20:15:31+00:00 -->
- [[#1024](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1024)] Fix Apigee PAYG environment node config ([g-greatdevaks](https://github.com/g-greatdevaks)) <!-- 2022-11-29 13:08:12+00:00 -->
- [[#1019](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1019)] Added endpoint attachments to Apigee module ([apichick](https://github.com/apichick)) <!-- 2022-11-28 16:53:27+00:00 -->
- [[#1000](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1000)] ADFS blueprint fixes ([apichick](https://github.com/apichick)) <!-- 2022-11-28 12:43:33+00:00 -->
- [[#1001](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1001)] Binauthz blueprint fixes related to project creation ([apichick](https://github.com/apichick)) <!-- 2022-11-28 11:45:11+00:00 -->
- [[#1009](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1009)] Fix encryption in Data Playground blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2022-11-25 15:19:02+00:00 -->
- [[#1003](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1003)] Normalize prefix handling in blueprints ([kunzese](https://github.com/kunzese)) <!-- 2022-11-23 10:09:00+00:00 -->
- [[#995](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/995)] Push container images to GitHub instead of Google Container Registry ([kunzese](https://github.com/kunzese)) <!-- 2022-11-21 14:53:52+00:00 -->
- [[#984](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/984)] **incompatible change:** Apigee module and blueprint ([apichick](https://github.com/apichick)) <!-- 2022-11-17 16:20:27+00:00 -->
- [[#980](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/980)] Have Squid log to /dev/stdout to stream logs to Cloud Logging ([kunzese](https://github.com/kunzese)) <!-- 2022-11-16 13:41:26+00:00 -->
- [[#929](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/929)] Updated list of enabled APIs for network dashboard ([maunope](https://github.com/maunope)) <!-- 2022-11-16 09:27:44+00:00 -->
- [[#968](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/968)] Enforce PROXY protocol in `filtering-proxy-psc` blueprint ([kunzese](https://github.com/kunzese)) <!-- 2022-11-15 07:18:58+00:00 -->
- [[#962](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/962)] Add filtering-proxy-psc blueprint ([kunzese](https://github.com/kunzese)) <!-- 2022-11-11 10:24:38+00:00 -->
- [[#913](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/913)] Adding support for PSA ranges, starting with Redis instances. ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2022-11-09 11:07:41+00:00 -->
- [[#952](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/952)] Remove duplicate GLB+CA blueprint folder ([ludoo](https://github.com/ludoo)) <!-- 2022-11-07 12:46:22+00:00 -->
- [[#949](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/949)] **incompatible change:** Refactor VPC firewall module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-04 12:56:08+00:00 -->
- [[#945](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/945)] Org policy factory ([juliocc](https://github.com/juliocc)) <!-- 2022-11-03 11:30:58+00:00 -->
- [[#941](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/941)] **incompatible change:** Refactor ILB module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-02 17:05:21+00:00 -->
- [[#939](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/939)] Temporarily duplicate cloud armor example ([ludoo](https://github.com/ludoo)) <!-- 2022-11-02 09:36:04+00:00 -->
- [[#936](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/936)] Enable org policy service and add README notice to modules ([ludoo](https://github.com/ludoo)) <!-- 2022-11-01 13:25:08+00:00 -->
- [[#931](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/931)] **incompatible change:** Refactor compute-mig module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-01 08:39:00+00:00 -->
- [[#932](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/932)] feat(project-factory): introduce additive iam bindings to project-fac… ([Malet](https://github.com/Malet)) <!-- 2022-10-31 17:24:25+00:00 -->
- [[#925](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/925)] Network dashboard: update main.tf and README following #922 ([brianhmj](https://github.com/brianhmj)) <!-- 2022-10-28 15:49:12+00:00 -->
- [[#924](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/924)] Fix formatting for gcloud dataflow job launch command ([aymanfarhat](https://github.com/aymanfarhat)) <!-- 2022-10-27 14:07:25+00:00 -->
- [[#921](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/921)] Align documentation, move glb blueprint ([ludoo](https://github.com/ludoo)) <!-- 2022-10-26 12:31:04+00:00 -->
- [[#915](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/915)] TFE OIDC with GCP WIF blueprint added ([averbuks](https://github.com/averbuks)) <!-- 2022-10-25 19:06:43+00:00 -->
- [[#899](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/899)] Static routes monitoring metrics added to network dashboard BP ([maunope](https://github.com/maunope)) <!-- 2022-10-25 11:36:39+00:00 -->
- [[#909](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/909)] GCS2BQ: Move images and templates in sub-folders ([lcaggio](https://github.com/lcaggio)) <!-- 2022-10-25 08:31:25+00:00 -->
- [[#907](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/907)] Fix CloudSQL blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2022-10-25 07:08:08+00:00 -->
- [[#897](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/897)] Project-factory: allow folder_id to be defined in defaults_file ([Malet](https://github.com/Malet)) <!-- 2022-10-21 08:20:06+00:00 -->
- [[#900](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/900)] Improve net dashboard variables ([juliocc](https://github.com/juliocc)) <!-- 2022-10-20 20:59:31+00:00 -->
- [[#896](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/896)] Network Dashboard: CFv2 and performance improvements ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2022-10-19 16:59:29+00:00 -->
- [[#871](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/871)] Firewall Policy Metrics, parallel writes, aligned timestamps ([maunope](https://github.com/maunope)) <!-- 2022-10-19 15:37:19+00:00 -->
- [[#884](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/884)] BigQuery factory blueprint ([marcjwo](https://github.com/marcjwo)) <!-- 2022-10-18 15:07:16+00:00 -->
- [[#889](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/889)] Minor fixes to PSC hybrid blueprint readmes ([LucaPrete](https://github.com/LucaPrete)) <!-- 2022-10-17 08:40:12+00:00 -->
- [[#888](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/888)] Let the cloudsql module generate a random password  ([skalolazka](https://github.com/skalolazka)) <!-- 2022-10-17 06:30:41+00:00 -->
- [[#879](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/879)] New PSC hybrid blueprint ([LucaPrete](https://github.com/LucaPrete)) <!-- 2022-10-16 08:18:41+00:00 -->
- [[#880](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/880)] **incompatible change:** Refactor net-vpc module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-10-14 09:02:34+00:00 -->
- [[#872](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/872)] added support 2nd generation cloud function  ([som-nitjsr](https://github.com/som-nitjsr)) <!-- 2022-10-13 06:09:00+00:00 -->
- [[#875](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/875)] **incompatible change:** Refactor GKE nodepool for Terraform 1.3, refactor GKE blueprints and FAST stage ([ludoo](https://github.com/ludoo)) <!-- 2022-10-12 10:59:37+00:00 -->
- [[#873](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/873)] Fix docker tag command and link to Cloud Shell in WP blueprint ([skalolazka](https://github.com/skalolazka)) <!-- 2022-10-11 12:40:25+00:00 -->
- [[#870](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/870)] Temporarily revert to Terraform 1.3.1 to support Cloud Shell ([skalolazka](https://github.com/skalolazka)) <!-- 2022-10-10 09:36:41+00:00 -->
- [[#856](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/856)] Add network firewall metrics to network dashboard ([maunope](https://github.com/maunope)) <!-- 2022-10-10 08:46:22+00:00 -->
- [[#868](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/868)] **incompatible change:** Refactor GKE module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-10-10 07:38:21+00:00 -->
- [[#818](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/818)] Example wordpress ([skalolazka](https://github.com/skalolazka)) <!-- 2022-10-07 14:24:38+00:00 -->
- [[#861](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/861)] Leverage new shared VPC project config defaults across the repo ([juliocc](https://github.com/juliocc)) <!-- 2022-10-07 07:50:43+00:00 -->
- [[#854](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/854)] Added an example of a Nginx reverse proxy cluster using RMIGs ([rosmo](https://github.com/rosmo)) <!-- 2022-10-04 13:49:44+00:00 -->
- [[#850](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/850)] Made sample alert creation optional ([maunope](https://github.com/maunope)) <!-- 2022-09-30 10:08:37+00:00 -->
- [[#837](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/837)] Network dashboard: Subnet IP utilization update ([aurelienlegrand](https://github.com/aurelienlegrand)) <!-- 2022-09-30 08:51:16+00:00 -->
- [[#848](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/848)] updated quota monitoring CF doc ([maunope](https://github.com/maunope)) <!-- 2022-09-29 17:55:22+00:00 -->
- [[#847](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/847)] **incompatible change:** Quotas monitoring, time series format update ([maunope](https://github.com/maunope)) <!-- 2022-09-29 16:20:18+00:00 -->
- [[#839](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/839)] **incompatible change:** Update to terraform 1.3 ([juliocc](https://github.com/juliocc)) <!-- 2022-09-28 11:25:27+00:00 -->
- [[#828](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/828)] Update firewall rules. ([lcaggio](https://github.com/lcaggio)) <!-- 2022-09-20 15:24:12+00:00 -->
- [[#813](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/813)] Add documentation example test for pf ([ludoo](https://github.com/ludoo)) <!-- 2022-09-14 12:34:30+00:00 -->
- [[#809](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/809)] Renaming and moving blueprints ([juliocc](https://github.com/juliocc)) <!-- 2022-09-12 10:19:15+00:00 -->

### DOCUMENTATION

- [[#1048](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1048)] Document new testing approach ([ludoo](https://github.com/ludoo)) <!-- 2022-12-12 19:59:47+00:00 -->
- [[#1045](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1045)] Assorted module fixes ([ludoo](https://github.com/ludoo)) <!-- 2022-12-10 14:40:15+00:00 -->
- [[#1014](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1014)] Update typos in `net-vpc-firewall` README.md ([aymanfarhat](https://github.com/aymanfarhat)) <!-- 2022-12-08 16:48:26+00:00 -->
- [[#1044](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1044)] **incompatible change:** Refactor net-lb-app-ext module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-12-08 16:35:45+00:00 -->
- [[#1009](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1009)] Fix encryption in Data Playground blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2022-11-25 15:19:02+00:00 -->
- [[#1006](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1006)] Add settings for autoscaling to Bigtable module. ([iht](https://github.com/iht)) <!-- 2022-11-24 15:59:32+00:00 -->
- [[#1007](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1007)] fast README, one line fix: 00-cicd stage got moved to extras/ ([skalolazka](https://github.com/skalolazka)) <!-- 2022-11-23 15:31:01+00:00 -->
- [[#1003](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1003)] Normalize prefix handling in blueprints ([kunzese](https://github.com/kunzese)) <!-- 2022-11-23 10:09:00+00:00 -->
- [[#987](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/987)] Add tests to factory examples ([juliocc](https://github.com/juliocc)) <!-- 2022-11-18 17:01:41+00:00 -->
- [[#972](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/972)] Add note about TF_PLUGIN_CACHE_DIR ([wiktorn](https://github.com/wiktorn)) <!-- 2022-11-14 10:21:37+00:00 -->
- [[#961](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/961)] Remove extra file from root ([ludoo](https://github.com/ludoo)) <!-- 2022-11-09 07:53:11+00:00 -->
- [[#943](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/943)] Update bootstrap README.md with unique project id requirements ([KPRepos](https://github.com/KPRepos)) <!-- 2022-11-03 22:22:22+00:00 -->
- [[#937](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/937)] Fix typos in blueprints README.md ([kumar-dhanagopal](https://github.com/kumar-dhanagopal)) <!-- 2022-11-02 07:39:26+00:00 -->
- [[#921](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/921)] Align documentation, move glb blueprint ([ludoo](https://github.com/ludoo)) <!-- 2022-10-26 12:31:04+00:00 -->
- [[#898](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/898)] Update FAST bootstrap README.md ([juliocc](https://github.com/juliocc)) <!-- 2022-10-19 15:15:36+00:00 -->
- [[#878](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/878)] chore: update cft and fabric ([bharathkkb](https://github.com/bharathkkb)) <!-- 2022-10-12 15:38:06+00:00 -->
- [[#863](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/863)] Fabric vs CFT doc ([ludoo](https://github.com/ludoo)) <!-- 2022-10-07 12:47:51+00:00 -->
- [[#806](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/806)] FAST Companion Guide ([ajlopezn](https://github.com/ajlopezn)) <!-- 2022-09-12 07:11:03+00:00 -->

### FAST

- [[#1023](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1023)] **incompatible change:** Small fix: uniform region in Fast in networking-nva ([skalolazka](https://github.com/skalolazka)) <!-- 2022-12-07 12:07:26+00:00 -->
- [[#1032](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1032)] FAST: fix VPC-SC example in security documentation ([imp14a](https://github.com/imp14a)) <!-- 2022-12-05 15:02:01+00:00 -->
- [[#1007](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1007)] fast README, one line fix: 00-cicd stage got moved to extras/ ([skalolazka](https://github.com/skalolazka)) <!-- 2022-11-23 15:31:01+00:00 -->
- [[#976](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/976)] FAST: fixes to GitHub workflow and 02/net outputs ([ludoo](https://github.com/ludoo)) <!-- 2022-11-15 07:48:32+00:00 -->
- [[#966](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/966)] FAST: improve GitHub workflow, stage 01 output fixes ([ludoo](https://github.com/ludoo)) <!-- 2022-11-11 07:55:58+00:00 -->
- [[#963](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/963)] **incompatible change:** Refactor vps-sc module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-10 18:34:45+00:00 -->
- [[#956](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/956)] FAST: bootstrap and extra stage CI/CD improvements and fixes ([ludoo](https://github.com/ludoo)) <!-- 2022-11-08 08:38:16+00:00 -->
- [[#949](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/949)] **incompatible change:** Refactor VPC firewall module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-04 12:56:08+00:00 -->
- [[#943](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/943)] Update bootstrap README.md with unique project id requirements ([KPRepos](https://github.com/KPRepos)) <!-- 2022-11-03 22:22:22+00:00 -->
- [[#948](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/948)] Use display_name instead of description for FAST service accounts ([juliocc](https://github.com/juliocc)) <!-- 2022-11-03 16:22:18+00:00 -->
- [[#947](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/947)] Use org policy factory for resman stage ([juliocc](https://github.com/juliocc)) <!-- 2022-11-03 14:04:08+00:00 -->
- [[#941](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/941)] **incompatible change:** Refactor ILB module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-02 17:05:21+00:00 -->
- [[#935](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/935)] FAST: enable org policy API, fix run.allowedIngress value ([ludoo](https://github.com/ludoo)) <!-- 2022-11-01 08:52:03+00:00 -->
- [[#931](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/931)] **incompatible change:** Refactor compute-mig module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-01 08:39:00+00:00 -->
- [[#930](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/930)] **incompatible change:** Update organization/folder/project modules to use new org policies API and tf1.3 optionals ([juliocc](https://github.com/juliocc)) <!-- 2022-10-28 16:21:06+00:00 -->
- [[#911](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/911)] FAST: Additional PGA DNS records ([sruffilli](https://github.com/sruffilli)) <!-- 2022-10-25 12:28:29+00:00 -->
- [[#903](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/903)] Initial replacement for CI/CD stage ([ludoo](https://github.com/ludoo)) <!-- 2022-10-23 17:52:46+00:00 -->
- [[#898](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/898)] Update FAST bootstrap README.md ([juliocc](https://github.com/juliocc)) <!-- 2022-10-19 15:15:36+00:00 -->
- [[#880](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/880)] **incompatible change:** Refactor net-vpc module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-10-14 09:02:34+00:00 -->
- [[#875](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/875)] **incompatible change:** Refactor GKE nodepool for Terraform 1.3, refactor GKE blueprints and FAST stage ([ludoo](https://github.com/ludoo)) <!-- 2022-10-12 10:59:37+00:00 -->
- [[#566](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/566)] FAST: Separate network environment  ([sruffilli](https://github.com/sruffilli)) <!-- 2022-10-10 09:50:08+00:00 -->
- [[#870](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/870)] Temporarily revert to Terraform 1.3.1 to support Cloud Shell ([skalolazka](https://github.com/skalolazka)) <!-- 2022-10-10 09:36:41+00:00 -->
- [[#868](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/868)] **incompatible change:** Refactor GKE module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-10-10 07:38:21+00:00 -->
- [[#867](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/867)] FAST: Replace NVAs in 02-networking-nva with COS-based VMs ([sruffilli](https://github.com/sruffilli)) <!-- 2022-10-10 07:16:29+00:00 -->
- [[#865](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/865)] Enable FAST 00-cicd provider test ([ludoo](https://github.com/ludoo)) <!-- 2022-10-07 11:20:57+00:00 -->
- [[#861](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/861)] Leverage new shared VPC project config defaults across the repo ([juliocc](https://github.com/juliocc)) <!-- 2022-10-07 07:50:43+00:00 -->
- [[#858](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/858)] Default gcp-support to gcp-devops ([juliocc](https://github.com/juliocc)) <!-- 2022-10-06 12:58:26+00:00 -->
- [[#842](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/842)] Comment redundant role in bootstrap stage, align IAM.md files, improve IAM tool ([ludoo](https://github.com/ludoo)) <!-- 2022-09-29 06:30:02+00:00 -->
- [[#841](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/841)] FAST: revert 00-cicd provider changes ([ludoo](https://github.com/ludoo)) <!-- 2022-09-28 14:17:40+00:00 -->
- [[#835](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/835)] Fix workflow-gitlab.yaml template rendering ([muresan](https://github.com/muresan)) <!-- 2022-09-22 12:26:22+00:00 -->
- [[#828](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/828)] Update firewall rules. ([lcaggio](https://github.com/lcaggio)) <!-- 2022-09-20 15:24:12+00:00 -->
- [[#807](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/807)] FAST: refactor Gitlab template ([ludoo](https://github.com/ludoo)) <!-- 2022-09-12 05:26:49+00:00 -->

### MODULES

- [[#1049](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1049)] Add ssl certs to cloudsql instance ([prabhaarya](https://github.com/prabhaarya)) <!-- 2022-12-12 16:14:45+00:00 -->
- [[#1045](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1045)] Assorted module fixes ([ludoo](https://github.com/ludoo)) <!-- 2022-12-10 14:40:15+00:00 -->
- [[#1040](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1040)] Fix name in google_pubsub_schema resource ([VictorCavalcanteLG](https://github.com/VictorCavalcanteLG)) <!-- 2022-12-08 17:25:36+00:00 -->
- [[#1043](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1043)] added reverse lookup feature to module dns #1042 ([chemapolo](https://github.com/chemapolo)) <!-- 2022-12-08 17:13:05+00:00 -->
- [[#1044](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1044)] **incompatible change:** Refactor net-lb-app-ext module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-12-08 16:35:45+00:00 -->
- [[#1036](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1036)] **incompatible change:** Fix status ingress/egress policies in vpc-sc module ([ludoo](https://github.com/ludoo)) <!-- 2022-12-05 08:00:01+00:00 -->
- [[#1033](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1033)] strongSwan: switch base image to debian-slim ([kunzese](https://github.com/kunzese)) <!-- 2022-12-02 12:11:02+00:00 -->
- [[#1026](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1026)] add lifecycle ignore_changes for apigee PAYG env ([g-greatdevaks](https://github.com/g-greatdevaks)) <!-- 2022-12-01 10:38:19+00:00 -->
- [[#1031](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1031)] Fix default_rules_config description in firewall module ([ludoo](https://github.com/ludoo)) <!-- 2022-12-01 09:04:13+00:00 -->
- [[#1028](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1028)] **incompatible change:** Align rest of vpn modules with #1027 ([juliocc](https://github.com/juliocc)) <!-- 2022-11-30 15:37:24+00:00 -->
- [[#1027](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1027)] **incompatible change:** Update VPN-HA module to tf1.3 ([juliocc](https://github.com/juliocc)) <!-- 2022-11-30 10:50:06+00:00 -->
- [[#1025](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1025)] fix apigee PAYG env node config dynamic block ([g-greatdevaks](https://github.com/g-greatdevaks)) <!-- 2022-11-30 04:53:43+00:00 -->
- [[#1024](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1024)] Fix Apigee PAYG environment node config ([g-greatdevaks](https://github.com/g-greatdevaks)) <!-- 2022-11-29 13:08:12+00:00 -->
- [[#1019](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1019)] Added endpoint attachments to Apigee module ([apichick](https://github.com/apichick)) <!-- 2022-11-28 16:53:27+00:00 -->
- [[#1018](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1018)] Apigee instance doc examples ([danistrebel](https://github.com/danistrebel)) <!-- 2022-11-28 11:10:12+00:00 -->
- [[#1016](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1016)] Fix memory/cpu typo in gke cluster module ([joeheaton](https://github.com/joeheaton)) <!-- 2022-11-27 17:29:26+00:00 -->
- [[#1012](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1012)] Fix tag outputs in organization module ([ludoo](https://github.com/ludoo)) <!-- 2022-11-25 13:06:32+00:00 -->
- [[#1006](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1006)] Add settings for autoscaling to Bigtable module. ([iht](https://github.com/iht)) <!-- 2022-11-24 15:59:32+00:00 -->
- [[#999](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/999)] Default nodepool creation fix ([astianseb](https://github.com/astianseb)) <!-- 2022-11-22 18:17:58+00:00 -->
- [[#1005](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1005)] Only set partitioned table when sink type is bigquery ([juliocc](https://github.com/juliocc)) <!-- 2022-11-22 16:13:53+00:00 -->
- [[#997](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/997)] Add BigQuery subscriptions to Pubsub module. ([iht](https://github.com/iht)) <!-- 2022-11-21 17:26:52+00:00 -->
- [[#995](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/995)] Push container images to GitHub instead of Google Container Registry ([kunzese](https://github.com/kunzese)) <!-- 2022-11-21 14:53:52+00:00 -->
- [[#994](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/994)] Add schemas to Pubsub topic module. ([iht](https://github.com/iht)) <!-- 2022-11-20 16:56:03+00:00 -->
- [[#979](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/979)] Add network tags support to the organization module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2022-11-18 14:56:29+00:00 -->
- [[#991](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/991)] Allow cross-project backend services in ILB L7 module ([ludoo](https://github.com/ludoo)) <!-- 2022-11-18 08:48:41+00:00 -->
- [[#984](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/984)] **incompatible change:** Apigee module and blueprint ([apichick](https://github.com/apichick)) <!-- 2022-11-17 16:20:27+00:00 -->
- [[#988](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/988)] Merge cloud function v1 and v2 tests ([juliocc](https://github.com/juliocc)) <!-- 2022-11-17 10:18:57+00:00 -->
- [[#965](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/965)] **incompatible change:** Add triggers to Cloud Functions v2 ([wiktorn](https://github.com/wiktorn)) <!-- 2022-11-16 16:00:03+00:00 -->
- [[#980](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/980)] Have Squid log to /dev/stdout to stream logs to Cloud Logging ([kunzese](https://github.com/kunzese)) <!-- 2022-11-16 13:41:26+00:00 -->
- [[#983](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/983)] **incompatible change:** Add support for serverless NEGs to ILB L7 module ([ludoo](https://github.com/ludoo)) <!-- 2022-11-16 13:14:05+00:00 -->
- [[#978](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/978)] Worker pool support for `cloud-function` ([maunope](https://github.com/maunope)) <!-- 2022-11-15 16:38:42+00:00 -->
- [[#977](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/977)] Replace Docker's `gcplogs` driver with the GCP COS logging agent ([kunzese](https://github.com/kunzese)) <!-- 2022-11-15 12:19:52+00:00 -->
- [[#975](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/975)] Add validation for health check port specification to ILB L7 module ([ludoo](https://github.com/ludoo)) <!-- 2022-11-14 15:20:01+00:00 -->
- [[#974](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/974)] **incompatible change:** Refactor net-lb-app-int module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-14 13:39:00+00:00 -->
- [[#970](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/970)] Update logging sinks to tf1.3 in resman modules ([juliocc](https://github.com/juliocc)) <!-- 2022-11-12 18:36:59+00:00 -->
- [[#969](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/969)] Update folder and project org policy tests ([juliocc](https://github.com/juliocc)) <!-- 2022-11-11 17:01:26+00:00 -->
- [[#964](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/964)] prefix variable consistency across modules ([skalolazka](https://github.com/skalolazka)) <!-- 2022-11-11 13:38:51+00:00 -->
- [[#963](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/963)] **incompatible change:** Refactor vps-sc module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-10 18:34:45+00:00 -->
- [[#958](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/958)] Add support for org policy custom constraints ([averbuks](https://github.com/averbuks)) <!-- 2022-11-09 09:07:46+00:00 -->
- [[#960](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/960)] Fix README typo in firewall module ([valeriobponza](https://github.com/valeriobponza)) <!-- 2022-11-08 23:25:34+00:00 -->
- [[#953](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/953)] Added IAM Additive and converted some outputs to static ([muresan](https://github.com/muresan)) <!-- 2022-11-07 13:20:17+00:00 -->
- [[#951](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/951)] cloud-functions v2 - fix reference to bucket_name ([wiktorn](https://github.com/wiktorn)) <!-- 2022-11-06 07:32:39+00:00 -->
- [[#949](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/949)] **incompatible change:** Refactor VPC firewall module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-04 12:56:08+00:00 -->
- [[#946](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/946)] **incompatible change:** Deprecate organization-policy module ([juliocc](https://github.com/juliocc)) <!-- 2022-11-03 11:56:12+00:00 -->
- [[#945](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/945)] Org policy factory ([juliocc](https://github.com/juliocc)) <!-- 2022-11-03 11:30:58+00:00 -->
- [[#941](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/941)] **incompatible change:** Refactor ILB module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-02 17:05:21+00:00 -->
- [[#940](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/940)] Ensure the implementation of org policies is consistent ([juliocc](https://github.com/juliocc)) <!-- 2022-11-02 09:55:21+00:00 -->
- [[#936](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/936)] Enable org policy service and add README notice to modules ([ludoo](https://github.com/ludoo)) <!-- 2022-11-01 13:25:08+00:00 -->
- [[#931](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/931)] **incompatible change:** Refactor compute-mig module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-01 08:39:00+00:00 -->
- [[#930](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/930)] **incompatible change:** Update organization/folder/project modules to use new org policies API and tf1.3 optionals ([juliocc](https://github.com/juliocc)) <!-- 2022-10-28 16:21:06+00:00 -->
- [[#926](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/926)] Fix backwards compatibility for vpc subnet descriptions ([ludoo](https://github.com/ludoo)) <!-- 2022-10-28 06:13:04+00:00 -->
- [[#927](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/927)] Add support for deployment type and api proxy type for Apigee org ([kmucha555](https://github.com/kmucha555)) <!-- 2022-10-27 19:56:41+00:00 -->
- [[#923](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/923)] Fix service account creation error in gke nodepool module ([ludoo](https://github.com/ludoo)) <!-- 2022-10-27 15:12:05+00:00 -->
- [[#908](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/908)] GKE module: autopilot fixes ([ludoo](https://github.com/ludoo)) <!-- 2022-10-25 21:33:49+00:00 -->
- [[#906](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/906)] GKE module: add managed_prometheus to features ([apichick](https://github.com/apichick)) <!-- 2022-10-25 21:18:50+00:00 -->
- [[#916](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/916)] Add support for DNS routing policies ([juliocc](https://github.com/juliocc)) <!-- 2022-10-25 14:20:53+00:00 -->
- [[#918](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/918)] Fix race condition in SimpleNVA ([sruffilli](https://github.com/sruffilli)) <!-- 2022-10-25 13:04:38+00:00 -->
- [[#914](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/914)] **incompatible change:** Update DNS module ([juliocc](https://github.com/juliocc)) <!-- 2022-10-25 10:31:11+00:00 -->
- [[#904](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/904)] Add missing description field ([dsbutler101](https://github.com/dsbutler101)) <!-- 2022-10-21 15:05:11+00:00 -->
- [[#891](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/891)] Add internal_ips output to compute-vm module ([LucaPrete](https://github.com/LucaPrete)) <!-- 2022-10-21 08:38:27+00:00 -->
- [[#890](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/890)] Add auto_delete and instance_redistribution_type to compute-vm and compute-mig modules. ([giovannibaratta](https://github.com/giovannibaratta)) <!-- 2022-10-16 19:19:46+00:00 -->
- [[#883](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/883)] Fix csi-driver, logging and monitoring default values when autopilot … ([danielmarzini](https://github.com/danielmarzini)) <!-- 2022-10-14 15:30:54+00:00 -->
- [[#880](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/880)] **incompatible change:** Refactor net-vpc module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-10-14 09:02:34+00:00 -->
- [[#872](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/872)] added support 2nd generation cloud function  ([som-nitjsr](https://github.com/som-nitjsr)) <!-- 2022-10-13 06:09:00+00:00 -->
- [[#877](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/877)] fix autoscaling block ([ludoo](https://github.com/ludoo)) <!-- 2022-10-12 14:44:48+00:00 -->
- [[#875](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/875)] **incompatible change:** Refactor GKE nodepool for Terraform 1.3, refactor GKE blueprints and FAST stage ([ludoo](https://github.com/ludoo)) <!-- 2022-10-12 10:59:37+00:00 -->
- [[#870](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/870)] Temporarily revert to Terraform 1.3.1 to support Cloud Shell ([skalolazka](https://github.com/skalolazka)) <!-- 2022-10-10 09:36:41+00:00 -->
- [[#869](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/869)] Fix optionals for resource_usage_export field in `gke-cluster` ([juliocc](https://github.com/juliocc)) <!-- 2022-10-10 09:04:44+00:00 -->
- [[#868](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/868)] **incompatible change:** Refactor GKE module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-10-10 07:38:21+00:00 -->
- [[#866](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/866)] Update ipprefix_by_netmask.sh in nva module ([sruffilli](https://github.com/sruffilli)) <!-- 2022-10-09 15:26:54+00:00 -->
- [[#860](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/860)] **incompatible change:** Refactor compute-vm for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-10-07 08:53:53+00:00 -->
- [[#861](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/861)] Leverage new shared VPC project config defaults across the repo ([juliocc](https://github.com/juliocc)) <!-- 2022-10-07 07:50:43+00:00 -->
- [[#859](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/859)] Make project shared VPC fields optional ([juliocc](https://github.com/juliocc)) <!-- 2022-10-06 14:18:01+00:00 -->
- [[#853](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/853)] Fixes NVA issue when health checks are not enabled ([sruffilli](https://github.com/sruffilli)) <!-- 2022-10-04 05:55:10+00:00 -->
- [[#846](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/846)] COS based simple networking appliance ([sruffilli](https://github.com/sruffilli)) <!-- 2022-09-30 16:43:24+00:00 -->
- [[#851](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/851)] nginx-tls: only use hostname part for TLS certificate ([rosmo](https://github.com/rosmo)) <!-- 2022-09-30 11:52:43+00:00 -->
- [[#844](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/844)] Management of GCP project default service accounts ([ddaluka](https://github.com/ddaluka)) <!-- 2022-09-29 13:10:08+00:00 -->
- [[#845](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/845)] added root password support for MS SQL Server ([cmalpe](https://github.com/cmalpe)) <!-- 2022-09-29 12:03:59+00:00 -->
- [[#843](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/843)] Add support for disk encryption to instance templates in compute-vm module ([ludoo](https://github.com/ludoo)) <!-- 2022-09-29 07:01:16+00:00 -->
- [[#840](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/840)] **incompatible change:** Refactor net-address module for 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-09-28 12:10:05+00:00 -->
- [[#839](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/839)] **incompatible change:** Update to terraform 1.3 ([juliocc](https://github.com/juliocc)) <!-- 2022-09-28 11:25:27+00:00 -->
- [[#824](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/824)] Add simple composer 2 blueprint ([lcaggio](https://github.com/lcaggio)) <!-- 2022-09-28 09:07:29+00:00 -->
- [[#834](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/834)] Add support for service_label property in internal load balancer ([kmucha555](https://github.com/kmucha555)) <!-- 2022-09-21 21:30:35+00:00 -->
- [[#833](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/833)] regional MySQL DBs - automatic backup conf ([skalolazka](https://github.com/skalolazka)) <!-- 2022-09-21 08:40:53+00:00 -->
- [[#827](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/827)] Project module: Add Artifactregistry Service Identity SA creation. ([lcaggio](https://github.com/lcaggio)) <!-- 2022-09-20 09:48:17+00:00 -->
- [[#826](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/826)] Added new binary_authorization argument in gke-cluster module ([sirohia](https://github.com/sirohia)) <!-- 2022-09-20 06:19:15+00:00 -->
- [[#819](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/819)] Removed old and unused modules ([juliocc](https://github.com/juliocc)) <!-- 2022-09-15 15:02:58+00:00 -->

### TOOLS

- [[#1048](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1048)] Document new testing approach ([ludoo](https://github.com/ludoo)) <!-- 2022-12-12 19:59:47+00:00 -->
- [[#1029](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1029)] Testing framework revamp ([juliocc](https://github.com/juliocc)) <!-- 2022-12-06 15:26:35+00:00 -->
- [[#1022](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1022)] Replace `set-output` with env variable and remove single quotes on labels ([kunzese](https://github.com/kunzese)) <!-- 2022-11-29 08:57:44+00:00 -->
- [[#1021](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1021)] Add OpenContainers annotations to published container images ([kunzese](https://github.com/kunzese)) <!-- 2022-11-29 08:11:53+00:00 -->
- [[#1017](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1017)] Fix auto-labeling ([ludoo](https://github.com/ludoo)) <!-- 2022-11-28 14:00:32+00:00 -->
- [[#1013](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1013)] Update labeler.yml ([ludoo](https://github.com/ludoo)) <!-- 2022-11-25 13:27:47+00:00 -->
- [[#1010](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1010)] Enforce nonempty descriptions ending in a dot ([juliocc](https://github.com/juliocc)) <!-- 2022-11-25 09:15:29+00:00 -->
- [[#1004](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1004)] Use `actions/labeler` to automatically label pull requests ([kunzese](https://github.com/kunzese)) <!-- 2022-11-22 14:42:47+00:00 -->
- [[#998](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/998)] Add missing `write_package` permission ([kunzese](https://github.com/kunzese)) <!-- 2022-11-22 08:32:42+00:00 -->
- [[#996](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/996)] Fix `repository name must be lowercase` on docker build ([kunzese](https://github.com/kunzese)) <!-- 2022-11-21 16:04:57+00:00 -->
- [[#993](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/993)] Fix variable and output sort check ([juliocc](https://github.com/juliocc)) <!-- 2022-11-21 13:32:56+00:00 -->
- [[#950](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/950)] Add a pytest fixture to convert tfvars to yaml ([ludoo](https://github.com/ludoo)) <!-- 2022-11-04 17:37:24+00:00 -->
- [[#942](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/942)] Bump tftest and improve dns tests ([juliocc](https://github.com/juliocc)) <!-- 2022-11-02 19:38:01+00:00 -->
- [[#919](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/919)] Rename workflow names ([juliocc](https://github.com/juliocc)) <!-- 2022-10-25 15:22:51+00:00 -->
- [[#902](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/902)] Bring back sorted variables check ([juliocc](https://github.com/juliocc)) <!-- 2022-10-20 17:08:17+00:00 -->
- [[#887](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/887)] Disable parallel execution of tests and plugin cache ([ludoo](https://github.com/ludoo)) <!-- 2022-10-14 17:52:38+00:00 -->
- [[#886](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/886)] Revert "Improve handling of tf plugin cache in tests" ([ludoo](https://github.com/ludoo)) <!-- 2022-10-14 17:35:31+00:00 -->
- [[#885](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/885)] Improve handling of tf plugin cache in tests ([ludoo](https://github.com/ludoo)) <!-- 2022-10-14 17:14:47+00:00 -->
- [[#881](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/881)] Run tests in parallel using `pytest-xdist` ([ludoo](https://github.com/ludoo)) <!-- 2022-10-14 12:56:16+00:00 -->
- [[#876](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/876)] Make changelog tool slower to work around inconsistencies in API results ([ludoo](https://github.com/ludoo)) <!-- 2022-10-12 12:49:32+00:00 -->
- [[#865](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/865)] Enable FAST 00-cicd provider test ([ludoo](https://github.com/ludoo)) <!-- 2022-10-07 11:20:57+00:00 -->
- [[#864](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/864)] **incompatible change:** Bump terraform required version ([ludoo](https://github.com/ludoo)) <!-- 2022-10-07 10:51:56+00:00 -->
- [[#842](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/842)] Comment redundant role in bootstrap stage, align IAM.md files, improve IAM tool ([ludoo](https://github.com/ludoo)) <!-- 2022-09-29 06:30:02+00:00 -->
- [[#811](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/811)] Fix changelog generator ([ludoo](https://github.com/ludoo)) <!-- 2022-09-13 09:41:29+00:00 -->
- [[#810](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/810)] Fully recursive e2e test runner for examples ([juliocc](https://github.com/juliocc)) <!-- 2022-09-12 12:35:46+00:00 -->

## [18.0.0] - 2022-09-09

<!-- 2022-09-09 18:02:15+00:00 < 2022-06-06 13:42:51+00:00 -->

- [[#808](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/808)] Rename examples to blueprints ([juliocc](https://github.com/juliocc)) <!-- 2022-09-09 15:14:19+00:00 -->

### FAST

- [[#804](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/804)] GKE CI/CD ([ludoo](https://github.com/ludoo)) <!-- 2022-09-09 06:33:25+00:00 -->
- [[#803](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/803)] FAST: fix GCS location in stage 00 and 01 ([miklosn](https://github.com/miklosn)) <!-- 2022-09-09 05:18:45+00:00 -->
- [[#700](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/700)] FAST: GKE multitenant infrastructure ([ludoo](https://github.com/ludoo)) <!-- 2022-09-08 20:49:47+00:00 -->
- [[#800](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/800)] FAST: add support for storage locations in stages 0 and 1 ([ludoo](https://github.com/ludoo)) <!-- 2022-09-08 13:24:43+00:00 -->
- [[#799](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/799)] FAST: add support for project parents to bootstrap stage ([ludoo](https://github.com/ludoo)) <!-- 2022-09-08 13:11:47+00:00 -->
- [[#793](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/793)] FAST: fix typo in CI/CD stage outputs. ([fawzihmouda](https://github.com/fawzihmouda)) <!-- 2022-09-04 11:50:36+00:00 -->
- [[#774](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/774)] FAST: fix data-platform-dev folder in stage 03-data-platform ([sttomm](https://github.com/sttomm)) <!-- 2022-08-16 07:36:24+00:00 -->
- [[#770](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/770)] FAST: fix to move without `output_location` ([daisuky-jp](https://github.com/daisuky-jp)) <!-- 2022-08-07 07:00:27+00:00 -->
- [[#767](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/767)] Allow interpolating SAs in project factory subnet IAM bindings ([ludoo](https://github.com/ludoo)) <!-- 2022-08-04 08:39:28+00:00 -->
- [[#766](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/766)] FAST: refactor teams branch ([ludoo](https://github.com/ludoo)) <!-- 2022-08-03 14:34:09+00:00 -->
- [[#765](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/765)] FAST: move region trigrams to a variable in network stages ([ludoo](https://github.com/ludoo)) <!-- 2022-08-03 09:36:28+00:00 -->
- [[#759](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/759)] FAST: fix missing value to format principalSet ([imp14a](https://github.com/imp14a)) <!-- 2022-07-27 06:18:27+00:00 -->
- [[#753](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/753)] Add support for IAM bindings on service accounts to project factory ([ludoo](https://github.com/ludoo)) <!-- 2022-07-21 13:13:40+00:00 -->
- [[#745](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/745)] FAST: specify gitlab / github providers in CI/CD stage ([imp14a](https://github.com/imp14a)) <!-- 2022-07-19 21:03:33+00:00 -->
- [[#734](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/734)] FAST: Use spot VMs for test VM and for NVAs ([sruffilli](https://github.com/sruffilli)) <!-- 2022-07-13 11:57:03+00:00 -->
- [[#733](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/733)] FAST: fix data platform drop BQ dataset name ([juliocc](https://github.com/juliocc)) <!-- 2022-07-12 12:45:57+00:00 -->
- [[#730](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/730)] FAST: add billing IAM for billing group ([ludoo](https://github.com/ludoo)) <!-- 2022-07-11 06:26:13+00:00 -->
- [[#721](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/721)] FAST: add billing.costManager role to project factory SAs ([sruffilli](https://github.com/sruffilli)) <!-- 2022-07-06 13:10:14+00:00 -->
- [[#716](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/716)] FAST: added missing format argument to project factory CI/CD IAM bindings ([mgfeller](https://github.com/mgfeller)) <!-- 2022-07-05 10:43:32+00:00 -->
- [[#715](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/715)] FAST: fix optional service accounts in networking stages ([ludoo](https://github.com/ludoo)) <!-- 2022-07-05 07:46:54+00:00 -->
- [[#711](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/711)] FAST: update several stage READMEs about usage of *.auto.tfvars files ([mgfeller](https://github.com/mgfeller)) <!-- 2022-06-29 15:32:02+00:00 -->
- [[#703](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/703)] FAST: configuration switches for features ([ludoo](https://github.com/ludoo)) <!-- 2022-06-28 15:33:38+00:00 -->
- [[#706](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/706)] Bump providers versions and pin versions for tests ([juliocc](https://github.com/juliocc)) <!-- 2022-06-28 08:33:42+00:00 -->
- [[#702](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/702)] FAST: also trigger GitHub workflow on PR synchronize event ([mgfeller](https://github.com/mgfeller)) <!-- 2022-06-27 08:13:42+00:00 -->
- [[#692](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/692)] FAST: fix KMS delegation role in security stage ([lcaggio](https://github.com/lcaggio)) <!-- 2022-06-23 07:13:37+00:00 -->
- [[#699](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/699)] FAST: add `repository_owner` to GitHub identity attributes ([ludoo](https://github.com/ludoo)) <!-- 2022-06-23 06:06:25+00:00 -->
- [[#694](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/694)] FAST: add 00-cicd stage to allow managing repositories in Gitlab/GitHub, other CI/CD improvements ([rosmo](https://github.com/rosmo)) <!-- 2022-06-21 13:37:01+00:00 -->
- [[#690](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/690)] FAST: fix stage tfvars link paths in documentation ([lcaggio](https://github.com/lcaggio)) <!-- 2022-06-21 06:20:31+00:00 -->
- [[#676](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/676)] FAST: add group creation GIF to documentation ([amgoogle](https://github.com/amgoogle)) <!-- 2022-06-21 05:19:52+00:00 -->
- [[#687](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/687)] FAST: fix service identity/SA mismatch in project factory ([dosti-tee](https://github.com/dosti-tee)) <!-- 2022-06-17 11:25:30+00:00 -->
- [[#668](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/668)] FAST: add cleanup instructions to documentation ([ajlopezn](https://github.com/ajlopezn)) <!-- 2022-06-17 09:16:13+00:00 -->
- [[#682](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/682)] FAST: fix CI/CD source repositories in stage 01 ([imp14a](https://github.com/imp14a)) <!-- 2022-06-16 22:17:28+00:00 -->
- [[#675](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/675)] FAST: fix audit logs when using pubsub as destination ([juliocc](https://github.com/juliocc)) <!-- 2022-06-10 11:53:18+00:00 -->
- [[#674](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/674)] FAST: remove team folders comment from 01 variables, clarify README ([ludoo](https://github.com/ludoo)) <!-- 2022-06-10 08:51:26+00:00 -->
- [[#671](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/671)] FAST: fix Gitlab WIF attributes ([ludoo](https://github.com/ludoo)) <!-- 2022-06-09 06:31:50+00:00 -->
- [[#669](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/669)] FAST: CI/CD support for Source Repository and Cloud Build ([ludoo](https://github.com/ludoo)) <!-- 2022-06-08 09:34:08+00:00 -->

### EXAMPLES

- [[#801](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/801)] Update Cloud SQL example ([lcaggio](https://github.com/lcaggio)) <!-- 2022-09-09 14:02:07+00:00 -->
- [[#802](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/802)] Fix Data Platform example ([lcaggio](https://github.com/lcaggio)) <!-- 2022-09-09 07:19:28+00:00 -->
- [[#790](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/790)] Cloud Identity Group factory ([lcaggio](https://github.com/lcaggio)) <!-- 2022-09-01 13:30:58+00:00 -->
- [[#740](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/740)] Update to multiple READMEs  ([bluPhy](https://github.com/bluPhy)) <!-- 2022-08-11 07:40:55+00:00 -->
- [[#738](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/738)] Improve Data Playground example ([lcaggio](https://github.com/lcaggio)) <!-- 2022-08-09 13:56:39+00:00 -->
- [[#771](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/771)] Example of a multi-cluster mesh on GKE configuring managed control pl… ([apichick](https://github.com/apichick)) <!-- 2022-08-08 14:54:03+00:00 -->
- [[#743](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/743)] Update Readme.md: gcs to bq + cloud armor / glb ([bensadikgoogle](https://github.com/bensadikgoogle)) <!-- 2022-08-01 15:22:04+00:00 -->
- [[#757](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/757)] Remove key_algorithm from glb/ilb-l7 examples ([ludoo](https://github.com/ludoo)) <!-- 2022-07-25 14:00:14+00:00 -->
- [[#753](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/753)] Add support for IAM bindings on service accounts to project factory ([ludoo](https://github.com/ludoo)) <!-- 2022-07-21 13:13:40+00:00 -->
- [[#746](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/746)] Update multi region cloud SQL documentation ([bensadikgoogle](https://github.com/bensadikgoogle)) <!-- 2022-07-20 19:13:57+00:00 -->
- [[#733](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/733)] FAST: fix data platform drop BQ dataset name ([juliocc](https://github.com/juliocc)) <!-- 2022-07-12 12:45:57+00:00 -->
- [[#712](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/712)] New AD FS example ([apichick](https://github.com/apichick)) <!-- 2022-07-11 08:16:43+00:00 -->
- [[#655](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/655)] New example for a data playground Terraform setup ([aymanfarhat](https://github.com/aymanfarhat)) <!-- 2022-07-10 07:27:18+00:00 -->
- [[#706](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/706)] Bump providers versions and pin versions for tests ([juliocc](https://github.com/juliocc)) <!-- 2022-06-28 08:33:42+00:00 -->

### MODULES

- [[#805](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/805)] Change `modules/project` service_config default ([juliocc](https://github.com/juliocc)) <!-- 2022-09-09 07:54:31+00:00 -->
- [[#787](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/787)] Support manager role in cloud identity group module ([lcaggio](https://github.com/lcaggio)) <!-- 2022-08-31 10:29:05+00:00 -->
- [[#786](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/786)] Secret manager flag sensitive output ([ddaluka](https://github.com/ddaluka)) <!-- 2022-08-29 11:22:52+00:00 -->
- [[#775](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/775)] net-lb-app-ext: Added support for regional external HTTP(s) load balancing ([rosmo](https://github.com/rosmo)) <!-- 2022-08-27 20:58:11+00:00 -->
- [[#784](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/784)] fix envoy-traffic-director config for xDS v3 ([drebes](https://github.com/drebes)) <!-- 2022-08-24 14:34:33+00:00 -->
- [[#785](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/785)] nginx-tls module ([drebes](https://github.com/drebes)) <!-- 2022-08-24 14:20:36+00:00 -->
- [[#783](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/783)] fix service unit indent on cloud-config-container module ([drebes](https://github.com/drebes)) <!-- 2022-08-24 07:38:48+00:00 -->
- [[#782](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/782)] typo fix (max_scale -> min_scale) ([skalolazka](https://github.com/skalolazka)) <!-- 2022-08-23 17:04:56+00:00 -->
- [[#778](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/778)] **incompatible change:** instance_termination_action must be set for compute-vm spot instances ([sruffilli](https://github.com/sruffilli)) <!-- 2022-08-20 16:37:17+00:00 -->
- [[#727](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/727)] Fix `ip_range` variable description in `apigee-x-instance` module ([alexlo03](https://github.com/alexlo03)) <!-- 2022-08-11 07:55:39+00:00 -->
- [[#773](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/773)] **incompatible change:** Refactor Cloud Run module ([ludoo](https://github.com/ludoo)) <!-- 2022-08-09 12:06:30+00:00 -->
- [[#754](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/754)] Add support to a public access to cloudsql-instance ([alefmreis](https://github.com/alefmreis)) <!-- 2022-08-09 11:42:42+00:00 -->
- [[#768](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/768)] Add egress / ingress policy example to VPC SC module ([ludoo](https://github.com/ludoo)) <!-- 2022-08-04 15:00:14+00:00 -->
- [[#767](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/767)] Allow interpolating SAs in project factory subnet IAM bindings ([ludoo](https://github.com/ludoo)) <!-- 2022-08-04 08:39:28+00:00 -->
- [[#764](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/764)] Add dependency on shared vpc service project attachment to project module outputs ([apichick](https://github.com/apichick)) <!-- 2022-08-02 16:38:01+00:00 -->
- [[#761](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/761)] Fix gke hub module features condition ([ludoo](https://github.com/ludoo)) <!-- 2022-07-30 13:53:05+00:00 -->
- [[#760](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/760)] **incompatible change:** GKE hub module refactor ([ludoo](https://github.com/ludoo)) <!-- 2022-07-29 06:39:25+00:00 -->
- [[#756](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/756)] Set cluster id output to sensitive in GKE module ([apichick](https://github.com/apichick)) <!-- 2022-07-25 14:13:05+00:00 -->
- [[#752](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/752)] Also depend on shared vpc host in project module ([apichick](https://github.com/apichick)) <!-- 2022-07-21 12:51:38+00:00 -->
- [[#747](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/747)] Added gkehub.googleapis.com to jit services ([apichick](https://github.com/apichick)) <!-- 2022-07-21 12:09:12+00:00 -->
- [[#744](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/744)] Fixed issue with missing project reference in Cloud DNS data source  ([rosmo](https://github.com/rosmo)) <!-- 2022-07-19 09:26:36+00:00 -->
- [[#741](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/741)] Added servicemesh feature to GKE hub and included fleet robot service… ([apichick](https://github.com/apichick)) <!-- 2022-07-17 19:59:52+00:00 -->
- [[#737](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/737)] Move Cloud Run VPC Connector annotations to template metadata (#735) ([sethmoon](https://github.com/sethmoon)) <!-- 2022-07-13 19:06:28+00:00 -->
- [[#732](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/732)] Add support for topic message duration to pubsub module ([ludoo](https://github.com/ludoo)) <!-- 2022-07-12 07:23:24+00:00 -->
- [[#731](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/731)] Avoid setting empty IAM binding in subnet factory ([ludoo](https://github.com/ludoo)) <!-- 2022-07-11 19:11:52+00:00 -->
- [[#729](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/729)] Fix connector create logic in cloud run module ([ludoo](https://github.com/ludoo)) <!-- 2022-07-10 09:34:42+00:00 -->
- [[#726](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/726)] Fix documentation for organization-policy module ([averbuks](https://github.com/averbuks)) <!-- 2022-07-10 07:12:47+00:00 -->
- [[#722](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/722)] OrgPolicy module (factory) using new org-policy API, #698 ([averbuks](https://github.com/averbuks)) <!-- 2022-07-08 13:38:42+00:00 -->
- [[#695](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/695)] Modified reserved IP address outputs in net-lb-app-ext module ([apichick](https://github.com/apichick)) <!-- 2022-07-01 17:13:10+00:00 -->
- [[#709](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/709)] Fix incompatibility between logging and monitor config/service arguments in GKE module ([psabhishekgoogle](https://github.com/psabhishekgoogle)) <!-- 2022-06-29 12:34:13+00:00 -->
- [[#708](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/708)] Fix incompatibility between backup and autopilot in GKE module ([ludoo](https://github.com/ludoo)) <!-- 2022-06-28 16:53:55+00:00 -->
- [[#707](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/707)] Fix addons for autopilot clusters and add specific tests in GKE module ([juliocc](https://github.com/juliocc)) <!-- 2022-06-28 10:41:46+00:00 -->
- [[#706](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/706)] Bump providers versions and pin versions for tests ([juliocc](https://github.com/juliocc)) <!-- 2022-06-28 08:33:42+00:00 -->
- [[#704](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/704)] Add `consumer_accept_list` to `apigee-x-instance` ([juliocc](https://github.com/juliocc)) <!-- 2022-06-27 09:52:16+00:00 -->
- [[#696](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/696)] Added missing image in GLB and Cloud Armor example ([apichick](https://github.com/apichick)) <!-- 2022-06-23 06:08:56+00:00 -->
- [[#689](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/689)] New binary authorization module and example ([apichick](https://github.com/apichick)) <!-- 2022-06-18 10:18:58+00:00 -->
- [[#686](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/686)] Revert "Binary authorization module and example" ([ludoo](https://github.com/ludoo)) <!-- 2022-06-17 10:32:42+00:00 -->
- [[#683](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/683)] Binary authorization module and example ([apichick](https://github.com/apichick)) <!-- 2022-06-17 09:36:26+00:00 -->
- [[#684](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/684)] Cloud function module: add support for secrets ([ludoo](https://github.com/ludoo)) <!-- 2022-06-16 14:34:47+00:00 -->

### TOOLS

- [[#796](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/796)] Remove duplicate path component from doc_examples test names. ([juliocc](https://github.com/juliocc)) <!-- 2022-09-07 09:37:19+00:00 -->
- [[#794](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/794)] Test documentation examples in the `examples/` folder ([juliocc](https://github.com/juliocc)) <!-- 2022-09-06 19:38:26+00:00 -->
- [[#788](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/788)] fix yaml quotes for merge-pr workflow ([drebes](https://github.com/drebes)) <!-- 2022-08-31 13:47:33+00:00 -->
- [[#763](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/763)] Changelog generator ([ludoo](https://github.com/ludoo)) <!-- 2022-08-02 09:45:06+00:00 -->
- [[#762](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/762)] Update changelog on pull request merge ([ludoo](https://github.com/ludoo)) <!-- 2022-07-30 17:04:00+00:00 -->
- [[#680](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/680)] Tools: fix `ValueError` raised in `check_names.py` when overlong names are detected ([27Bslash6](https://github.com/27Bslash6)) <!-- 2022-06-16 08:01:59+00:00 -->
- [[#672](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/672)] Module attribution and version updater tool, plus release automation ([rosmo](https://github.com/rosmo)) <!-- 2022-06-09 11:40:50+00:00 -->

## [16.0.0] - 2022-06-06

- add support for [Spot VMs](https://cloud.google.com/compute/docs/instances/spot) to `gke-nodepool` module
- **incompatible change** add support for [Spot VMs](https://cloud.google.com/compute/docs/instances/spot) to `compute-vm` module
- SQL Server AlwaysOn availability groups example
- fixed Terraform change detection in CloudSQL when backup is disabled
- allow multiple CIDR blocks in the ip_range for Apigee Instance
- add prefix to project factory SA bindings
- **incompatible change** `subnets_l7ilb` variable is deprecated in the `net-vpc` module, instead `subnets_proxy_only` variable [should be used](https://cloud.google.com/load-balancing/docs/proxy-only-subnets#proxy_only_subnet_create)
- add support for [Private Service Connect](https://cloud.google.com/vpc/docs/private-service-connect#psc-subnets) and [Proxy-only](https://cloud.google.com/load-balancing/docs/proxy-only-subnets) subnets to `net-vpc` module
- bump Google provider versions to `>= 4.17.0`
- bump Terraform version to `>= 1.1.0`
- add `shielded_instance_config` support for instance template on `compute-vm` module
- add support for `gke_backup_agent_config` to GKE module addons
- add support for subscription filters to PubSub module
- refactor Hub and Spoke with VPN example
- fix tfdoc parsing on newllines in outputs
- fix subnet factory example in vpc module README
- fix condition in subnet factory flow logs
- added new example on GLB and Cloud Armor
- revamped and expanded Contributing Guide
- add support for Workload Identity Federation and CI/CD repositories
- simplify VPN tunnel configuration in the Hub and Spoke VPN network stage
- fix subnet YAML schema

## [15.0.0] - 2022-04-05

- **incompatible change** the variable for PSA ranges in the `net-vpc` module has changed to support configuring peering routes
- fix permadiff in `net-vpc-firewall` module rules
- new [gke-hub](modules/gke-hub) module
- new [unmanaged-instances-healthcheck](blueprints/cloud-operations/unmanaged-instances-healthcheck) example
- add support for IAM to `data-catalog-policy-tag` module
- add support for IAM additive to `folder` module, fixes #580
- optionally turn off gcplogs driver in COS modules
- fix `tag` output on `data-catalog-policy-tag` module
- add shared-vpc support on `gcs-to-bq-with-least-privileges`
- new `net-lb-app-int` module
- new `02-networking-peering` networking stage
- **incompatible change** the variable for PSA ranges in networking stages have changed

## [14.0.0] - 2022-02-25

- **incompatible change** removed `iam` key from logging sink configuration in the `project` and `organization` modules
- remove GCS to BQ with Dataflow example, replace by GCS to BQ with least privileges
- the `net-vpc` and `project` modules now use the beta provider for shared VPC-related resources
- new iot-core module
- **incompatible change** the variables for host and service Shared VPCs have changed in the project module
- **incompatible change** the variable for service identities IAM has changed in the project factory
- add `data-catalog-policy-tag` module
- new [workload identity federetion example](blueprints/cloud-operations/workload-identity-federation)
- new `api-gateway` [module](./modules/api-gateway) and example
- **incompatible change** the `psn_ranges` variable has been renamed to `psa_ranges` in the `net-vpc` module and its type changed from `list(string)` to `map(string)`
- **incompatible change** removed `iam` flag for organization and folder level sinks
- **incompatible change** removed `ingress_settings` configuration option in the `cloud-functions` module.
- new [m4ce VM example](blueprints/cloud-operations/vm-migration/)
- Support for resource management tags in the `organization`, `folder`, `project`, `compute-vm`, and `kms` modules
- new `data platform` stage 3
- new `02-networking-nva` networking stage
- allow customizing the names of custom roles
- added `environment` and `context` resource management tags
- use resource management tags to restrict scope of roles/orgpolicy.policyAdmin
- use `xpnServiceAdmin` (custom role) for stage 3 service accounts that need to attach to a shared VPC
- simplify and standardize ourputs from each stage
- standardize names of projects, service accounts and buckets
- switch to folder-level `xpnAdmin` and `xpnServiceAdmin`
- moved networking projects to folder matching their environments

## [13.0.0] - 2022-01-27

- **initial Fabric FAST implementation**
- new `net-lb-app-ext` module for Global External Load balancer
- new `project-factory` module in [`blueprints/factories`](./blueprints/factories)
- add missing service identity accounts (artifactregistry, composer) in project module
- new "Cloud Storage to Bigquery with Cloud Dataflow with least privileges" example
- support service dependencies for crypto key bindings in project module
- refactor project module in multiple files
- add support for per-file option overrides to tfdoc

## [12.0.0] - 2022-01-11

- new repo structure. All end-to-end examples moved to the top level `examples` folder

## [11.2.0] - 2022-01-11

- fix `net-vpc` subnet factory bug preventing the use of yamls with different shapes

## [11.1.0] - 2022-01-11

- add support for additive IAM bindings to `kms` module

## [11.0.0] - 2022-01-04

- **incompatible change** remove location from `gcs` bucket names
- add support for interpolating access levels based on keys to the `vpc-sc` module

## [10.0.1] - 2022-01-03

- remove lifecycle block from vpc sc perimeter resources

## [10.0.0] - 2021-12-31

- fix cases where bridge perimeter status resources are `null` in `vpc-sc` module
- re-release 9.0.3 as a major release as it contains breaking changes
- update hierarchical firewall resources to use the newer `google_compute_firewall_*` resources
- **incompatible change** rename `firewall_policy_attachments` to `firewall_policy_association` in the `organization` and `folder` modules
- **incompatible change** updated API for the `net-vpc-sc` module

## [9.0.3] - 2021-12-31

- update hierarchical firewall resources to use the newer `google_compute_firewall_*` resources
- **incompatible change** rename `firewall_policy_attachments` to `firewall_policy_association` in the `organization` and `folder` modules
- **incompatible change** updated API for the `net-vpc-sc` module

## [9.0.2] - 2021-12-22

- ignore description changes in firewall policy rule to avoid permadiff, add factory example to `folder` module documentation

## [9.0.0] - 2021-12-22

- new `cloud-run` module
- added gVNIC support to `compute-vm` module
- added a rule factory to `net-vpc-firewall` module
- added a subnet factory to `net-vpc` module
- **incompatible change** added support for partitioned tables to `organization` module sinks
- **incompatible change** renamed `private_service_networking_range` variable to `psc_ranges` in `net-vpc`module, and changed its type to `list(string)`
- added a firewall policy factory to `organization` and `firewall` module
- refactored `tfdoc`
- added support for metric scopes to the `project` module

## [8.0.0] - 2021-10-21

- added support for GCS notifications in `gcs` module
- added new `skip_delete` variable to `compute-vm` module
- **incompatible change** all modules and examples now require Terraform >= 1.0.0 and Google provider >= 4.0.0

## [7.0.0] - 2021-10-21

- new cloud operations example showing how to deploy infrastructure for [Compute Engine image builder based on Hashicorp Packer](./blueprints/cloud-operations/packer-image-builder)
- **incompatible change** the format of the `records` variable in the `dns` module has changed, to better support dynamic values
- new `naming-convention` module
- new `cloudsql-instance` module
- added support for website to `gcs` module, and removed auto-set labels
- new `factories` top-level folder with initial `subnets`, `firewall-hierarchical-policies`, `firewall-vpc-rules` and `example-environments` examples
- added new `description` variable to `compute-vm` module
- added support for L7 ILB subnets to `net-vpc` module
- added support to override default description in `compute-vm`
- added support for backup retention count in `cloudsql-instance`
- added new `description` variable to `cloud-function` module
- added new `description` variable to `bigquery-dataset` module
- added new `description` variable to `iam-service-account` module
- **incompatible change** fix deprecated message from `gke-nodepool`, change your `workload_metadata_config` to correct values (`GCE_METADATA` or `GKE_METADATA`)
- **incompatible change** changed maintenance window definition from `maintenance_start_time` to `maintenance_config` in `gke-cluster`
- added `monitoring_config`,`logging_config`, `dns_config` and `enable_l4_ilb_subsetting` to `gke-cluster`

## [6.0.0] - 2021-10-04

- new `apigee-organization` and `apigee-x-instance`
- generate `email` and `iam_email` statically in the `iam-service-account` module
- new `billing-budget` module
- fix `scheduled-asset-inventory-export-bq` module
- output custom role information from the `organization` module
- enable multiple `vpc-sc` perimeters over multiple modules
- new cloud operations example showing how to [restrict service usage using delegated role grants](./blueprints/cloud-operations/iam-delegated-role-grants)
- **incompatible change** multiple instance support has been removed from the `compute-vm` module, to bring its interface in line with other modules and enable simple use of `for_each` at the module level; its variables have also slightly changed (`attached_disks`, `boot_disk_delete`, `crate_template`, `zone`)
- **incompatible change** dropped the `admin_ranges_enabled` variable in `net-vpc-firewall`. Set `admin_ranges = []` to get the same effect
- added the `named_ranges` variable to `net-vpc-firewall`

## [5.1.0] - 2021-08-30

- add support for `lifecycle_rule` in gcs module
- create `pubsub` service identity if service is enabled
- support for creation of GKE Autopilot clusters
- add support for CMEK keys in Data Foundation end to end example
- add support for VPC-SC perimeters in Data Foundation end to end example
- fix `vpc-sc` module
- new networking example showing how to use [Private Service Connect to call a Cloud Function from on-premises](./blueprints/networking/private-cloud-function-from-onprem/)
- new networking example showing how to organize decentralized firewall management on GCP

## [5.0.0] - 2021-06-17

- fix `message_retention_duration` variable type in `pubsub` module
- move `bq` robot service account into the robot service account project output
- add IAM cryptDecrypt role to robot service account on specified keys
- add Service Identity creation on `project` module if secretmanager enabled
- add Data Foundation end to end example

## [4.9.0] - 2021-06-04

- **incompatible change** updated resource name for `google_dns_policy` on the `net-vpc` module
- added support for VPC-SC Ingress Egress policies on the `vpc-sc` module
- update CI to Terraform 0.15 and fix minor incompatibilities
- add `deletion_protection` to the `bigquery-dataset` module
- add support for dataplane v2 to GKE cluster module
- add BGP peer outputs to HA VPN module

## [4.8.0] - 2021-05-12

- added support for `CORS` to the `gcs` module
- make cluster creation optional in the Shared VPC example
- make service account creation optional in `iam-service-account` module
- new `third-party-solutions` top-level folder with initial `openshift` example
- added support for DNS Policies to the `net-vpc` module

## [4.7.0] - 2021-04-21

- **incompatible change** add support for `master_global_access_config` block in gke-cluster module
- add support for group-based IAM to resource management modules
- add support for private service connect

## [4.6.1] - 2021-04-01

- **incompatible change** support one group per zone in the `compute-vm` module

## [4.6.0] - 2021-03-31

- **incompatible change** logging sinks now create non-authoritative bindings when iam=true
- fixed IAM bindings for module `bigquery` not specifying project_id
- remove device_policy from `vpc_sc` module as it requires BeyondCorp Enterprise Premium
- allow using unsuffixed name in `compute_vm` module

## [4.5.1] - 2021-03-27

- allow creating private DNS zones with no visible VPCs in `dns` module

## [4.5.0] - 2021-03-20

- new `logging-bucket` module to create Cloud Logging Buckets
- add support to create logging sinks using logging buckets as the destination
- **incompatible change** extended logging sinks to support per-sink exclusions
- new `net-vpc-firewall-yaml` module
- add support for regions, device policy and access policy dependency to `vpc-sc` module
- add support for joining VPC-SC perimeters in `project` module
- add `userinfo.email` to default scopes in `compute-vm` module

## [4.4.2] - 2021-03-05

- fix versions constraints on modules to avoid the `no available releases match the given constraints` error

## [4.4.1] - 2021-03-05

- depend specific org module resources (eg policies) from IAM bindings
- set version for google-beta provider in project module

## [4.4.0] - 2021-03-02

- new `filtering_proxy` networking example
- add support for a second region in the onprem networking example
- add support for per-tunnel router to VPN HA and VPN dynamic modules
- **incompatible change** the `attached_disks` variable type has changed in the `compute-vm` module, to add support for regional persistent disks, and attaching existing disks to instances / templates
- the hub and spoke via peering example now supports project creation, resource prefix, and GKE peering configuration
- make the `project_id` output from the `project` module non-dynamic. This means you can use this output as a key for map fed into a `for_each` (for example, as a key for `iam_project_bindings` in the `iam-service-accounts` module)
- add support for essential contacts in the in the `project`, `folder` and `organization` modules

## [4.3.0] - 2021-01-11

- new DNS for Shared VPC example
- **incompatible change** removed the `logging-sinks` module. Logging sinks can now be created the `logging_sinks` variable in the in the `project`, `folder` and `organization` modules
- add support for creating logging exclusions in the `project`, `folder` and `organization` modules
- add support for Confidential Compute to `compute-vm` module
- add support for handling IAM policy (bindings, audit config) as fully authoritative in the `organization` module

## [4.2.0] - 2020-11-25

- **incompatible change** the `org_id` variable and output in the `vpc-sc` module have been renamed to `organization_id`, the variable now accepts values in `organizations/nnnnnnnn` format
- **incompatible change** the `forwarders` variable in the `dns` module has a different type, to support specifying forwarding path
- add support for MTU in `net-vpc` module
- **incompatible change** access variables have been renamed in the `bigquery-dataset` module
- add support for IAM to the `bigquery-dataset` module
- fix default OAuth scopes in `gke-nodepool` module
- add support for hierarchical firewalls to the `folder` and `organization` modules
- **incompatible change** the `org_id` variable and output in the `organization` module have been renamed to `organization_id`, the variable now accepts values in `organizations/nnnnnnnn` format

## [4.1.0] - 2020-11-16

- **incompatible change** rename prefix for node configuration variables in `gke-nodepool` module [#156]
- add support for internally managed service account in `gke-nodepool` module [#156]
- made examples in READMEs runnable and testable [#157]
- **incompatible change** `iam_additive` is now keyed by role to be more resilient with dynamic values, a new `iam_additive_members` variable has been added for backwards compatibility.
- add support for node taints in `gke-nodepool` module
- add support for CMEK in `gke-nodepool` module

## [4.0.0] - 2020-11-06

- This is a major refactor adding support for Terraform 0.13 features
- **incompatible change** minimum required terraform version is now 0.13.0
- **incompatible change** `folders` module renamed to `folder`
- **incompatible change** `iam-service-accounts` module renamed to `iam-service-account`
- **incompatible change** all `iam_roles` and `iam_member` variables merged into a single `iam` variable. This change affects most modules
- **incompatible change** modules like `folder`, `gcs`, `iam-service-account` now create a single resource. Use for_each at the module level if you need multiple instances
- added basic variable validations to some modules

## [3.5.0] - 2020-10-27

- end to end example for scheduled Cloud Asset Inventory export to Bigquery
- decouple Cloud Run from Istio in GKE cluster module
- depend views on tables in bigquery dataset module
- bring back logging options for firewall rules in `net-vpc-firewall` module
- removed interpolation-only expressions causing terraform warnings
- **incompatible change** simplify alias IP specification in `compute-vm`. We now use a map (alias range name to list of IPs) instead of a list of maps.
- allow using alias IPs with `instance_count` in `compute-vm`
- add support for virtual displays in `compute-vm`
- add examples of alias IPs in `compute-vm` module
- fix support for creating disks from images in `compute-vm`
- allow creating single-sided peerings in `net-vpc` and `net-vpc-peering`
- use service project registration to Shared VPC in GKE example to remove need for two-step apply

## [3.4.0] - 2020-09-24

- add support for logging and better type for the `retention_policies` variable in `gcs` module
- **incompatible change** deprecate `bucket_policy_only` in favor of `uniform_bucket_level_access` in `gcs` module
- **incompatible change** allow project module to configure itself as both shared VPC service and host project

## [3.3.0] - 2020-09-01

- remove extra readers in `gcs-to-bq-with-dataflow` example (issue: 128)
- make VPC creation optional in `net-vpc` module to allow managing a pre-existing VPC
- make HA VPN gateway creation optional in `net-vpn-ha` module
- add retention_policy in `gcs` module
- refactor `net-address` module variables, and add support for internal address `purpose`

## [3.2.0] - 2020-08-29

- **incompatible change** add alias IP support in `cloud-vm` module
- add tests for `data-solutions` examples
- fix apply errors on dynamic resources in dataflow example
- make zone creation optional in `dns` module
- new `quota-monitoring` end-to-end example in `cloud-operations`

## [3.1.1] - 2020-08-26

- fix error in `project` module
- **incompatible change** make HA VPN Gateway creation optional for `net-vpn-ha` module. Now an existing HA VPN Gateway can be used. Updating to the new version of the module will cause VPN Gateway recreation which can be handled by `terraform state rm/terraform import` operations.

## [3.1.0] - 2020-08-16

- **incompatible change** add support for specifying a different project id in the GKE cluster module; if using the `peering_config` variable, `peering_config.project_id` now needs to be explicitly set, a `null` value will reuse the `project_id` variable for the peering

## [3.0.0] - 2020-08-15

- **incompatible change** the top-level `infrastructure` folder has been renamed to `networking`
- add end-to-end example for ILB as next hop
- add basic tests for `foundations` and `networking` end-to-end examples
- fix Shared VPC end-to-end example and documentation

## [2.8.0] - 2020-08-01

- fine-grained Cloud DNS IAM via Service Directory example
- add feed id output dependency on IAM roles in `pubsub` module

## [2.7.1] - 2020-07-24

- fix provider issue in bigquery module

## [2.7.0] - 2020-07-24

- add support for VPC connector and ingress settings to `cloud-function` module
- add support for logging to `net-cloudnat` module

## [2.6.0] - 2020-07-19

- **incompatible changes** setting zone in the `compute-vm` module is now done via an optional `zones` variable, that accepts a list of zones
- fix optional IAM permissions in folder unit module

## [2.5.0] - 2020-07-10

- new `vpc-sc` module
- add support for Shared VPC to the `project` module
- fix bug with `compute-vm` address reservations introduced in [2.4.1]

## [2.4.2] - 2020-07-09

- add support for Shielded VM to `compute-vm`

## [2.4.1] - 2020-07-06

- better fix external IP assignment in `compute-vm`

## [2.4.0] - 2020-07-06

- fix external IP assignment in `compute-vm`
- new top-level `cloud-operations` example folder
- Cloud Asset Inventory end to end example in `cloud-operations`

## [2.3.0] - 2020-07-02

- new 'Cloud Storage to Bigquery with Cloud Dataflow' end to end data solution
- **incompatible change** additive IAM bindings are now keyed by identity instead of role, and use a single `iam_additive_bindings` variable, refer to [#103] for details
- set `delete_contents_on_destroy` in the foundations examples audit dataset to allow destroying
- trap errors raised by the `project` module on destroy

## [2.2.0] - 2020-06-29

- make project creation optional in `project` module to allow managing a pre-existing project
- new `cloud-endpoints` module
- new `cloud-function` module

## [2.1.0] - 2020-06-22

- **incompatible change** routes in the `net-vpc` module now interpolate the VPC name to ensure uniqueness, upgrading from a previous version will drop and recreate routes
- the top-level `docker-images` folder has been moved inside `modules/cloud-config-container/onprem`
- `dns_keys` output added to the `dns` module
- add `group-config` variable, `groups` and `group_self_links` outputs to `net-lb-int` module to allow creating ILBs for externally managed instances
- make the IAM bindings depend on the compute instance in the `compute-vm` module

## [2.0.0] - 2020-06-11

- new `data-solutions` section and `cmek-via-centralized-kms` example
- **incompatible change** static VPN routes now interpolate the VPN gateway name to enforce uniqueness, upgrading from a previous version will drop and recreate routes

## [1.9.0] - 2020-06-10

- new `bigtable-instance` module
- add support for IAM bindings to `compute-vm` module

## [1.8.1] - 2020-06-07

- use `all` instead of specifying protocols in the admin firewall rule of the `net-vpc-firewall` module
- add support for encryption keys in `gcs` module
- set `next_hop_instance_zone` in `net-vpc` for next hop instance routes to avoid triggering recreation

## [1.8.0] - 2020-06-03

- **incompatible change** the `kms` module has been refactored and will be incompatible with previous state
- **incompatible change** robot and default service accounts outputs in the `project` module have been refactored and are now exposed via a single `service_account` output (cf [#82])
- add support for PD CSI driver in GKE module
- refactor `iam-service-accounts` module outputs to be more resilient
- add option to use private GCR to `cos-generic-metadata` module

## [1.7.0] - 2020-05-30

- add support for disk encryption to the `compute-vm` module
- new `datafusion` module
- new `container-registry` module
- new `artifact-registry` module

## [1.6.0] - 2020-05-20

- add output to `gke-cluster` exposing the cluster's CA certificate
- fix `gke-cluster` autoscaling options
- add support for Service Directory bound zones to the `dns` module
- new `service-directory` module
- new `source-repository` module

## [1.5.0] - 2020-05-11

- **incompatible change** the `bigquery` module has been removed and replaced by the new `bigquery-dataset` module
- **incompatible change** subnets in the `net-vpc` modules are now passed as a list instead of map, and all related variables for IAM and flow logs use `region/name` instead of `name` keys; it's now possible to have the same subnet name in different regions
- replace all references to the removed `resourceviews.googleapis.com` API with `container.googleapis.com`
- fix advanced options in `gke-nodepool` module
- fix health checks in `compute-mig` and `net-lb-int` modules
- new `cos-generic-metadata` module in the `cloud-config-container` suite
- new `envoy-traffic-director` module in the `cloud-config-container` suite
- new `pubsub` module

## [1.4.1] - 2020-05-02

- new `secret-manager` module
- fix access in `bigquery` module, this is the last version of this module to support multiple datasets, future versions will be called `bigquery-dataset`

## [1.4.0] - 2020-05-01

- fix DNS module internal zone lookup
- fix Cloud NAT module internal router name lookup
- re-enable and update outputs for the foundations environments example
- add peering route configuration for private clusters to GKE cluster module
- **incompatible changes** in the GKE nodepool module: rename `node_config_workload_metadata_config` variable to `workload_metadata_config`, new default for `workload_metadata_config` is `GKE_METADATA_SERVER`
- **incompatible change** in the `compute-vm` module: removed support for MIG and the `group_manager` variable
- add `compute-mig` and `net-lb-int` modules
- **incompatible change** in `net-vpc`: a new `name` attribute has been added to the `subnets` variable, allowing to directly set subnet name, to update to the new module add an extra `name = false` attribute to each subnet

## [1.3.0] - 2020-04-08

- add organization policy module
- add support for organization policies to folders and project modules

## [1.2.0] - 2020-04-06

- add squid container to the `cloud-config-container` module

## [1.1.0] - 2020-03-27

- rename the `cos-container` suite of modules to `cloud-config-container`
- refactor the `onprem-in-a-box` module to only manage the `cloud-config` configuration, and make it part of the `cloud-config-container` suite of modules
- update the `onprem-google-access-dns` example to use the refactored `onprem` module
- fix the `external_addresses` output in the `compute-vm` module
- small tweaks and fixes to the `cloud-config-container` modules

## [1.0.0] - 2020-03-27

- merge development branch with suite of new modules and end-to-end examples

<!-- markdown-link-check-disable -->
[Unreleased]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v34.1.0...HEAD
[34.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v34.0.0...v34.1.0
[34.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v33.0.0...v34.0.0
[33.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v32.0.1...v33.0.0
[32.0.1]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v32.0.0...v32.0.1
[32.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v31.1.0...v32.0.0
[31.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v31.0.0...v31.1.0
[31.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v30.0.0...v31.0.0
[30.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v29.0.0...v30.0.0
[29.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v28.0.0...v29.0.0
[28.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v27.0.0...v28.0.0
[27.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v26.0.0...v27.0.0
[26.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v25.0.0...v26.0.0
[25.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v24.0.0...v25.0.0
[24.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v23.0.0...v24.0.0
[23.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v22.0.0...v23.0.0
[22.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v21.0.0...v22.0.0
[21.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v20.0.0...v21.0.0
[20.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v19.0.0...v20.0.0
[19.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v18.0.0...v19.0.0
[18.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v16.0.0...v18.0.0
[16.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v15.0.0...v16.0.0
[15.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v14.0.0...v15.0.0
[14.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v13.0.0...v14.0.0
[13.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v12.0.0...v13.0.0
[12.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v11.2.0...v12.0.0
[11.2.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v11.1.0...v11.2.0
[11.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v11.0.0...v11.1.0
[11.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v10.0.1...v11.0.0
[10.0.1]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v10.0.0...v10.0.1
[10.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v9.0.3...v10.0.0
[9.0.3]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v9.0.2...v9.0.3
[9.0.2]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v9.0.0...v9.0.2
[9.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v8.0.0...v9.0.0
[8.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v7.0.0...v8.0.0
[7.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v6.0.0...v7.0.0
[6.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v5.1.0...v6.0.0
[5.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v5.0.0...v5.1.0
[5.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.9.0...v5.0.0
[4.9.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.8.0...v4.9.0
[4.8.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.7.0...v4.8.0
[4.7.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.6.1...v4.7.0
[4.6.1]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.6.0...v4.6.1
[4.6.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.5.1...v4.6.0
[4.5.1]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.5.0...v4.5.1
[4.5.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.4.2...v4.5.0
[4.4.2]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.4.1...v4.4.2
[4.4.1]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.4.0...v4.4.1
[4.4.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.3.0...v4.4.0
[4.3.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.2.0...v4.3.0
[4.2.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.1.0...v4.2.0
[4.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v4.0.0...v4.1.0
[4.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v3.5.0...v4.0.0
[3.5.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v3.4.0...v3.5.0
[3.4.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v3.3.0...v3.4.0
[3.3.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v3.1.1...v3.2.0
[3.1.1]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.8.0...v3.0.0
[2.8.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.7.1...v2.8.0
[2.7.1]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.7.0...v2.7.1
[2.7.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.6.0...v2.7.0
[2.6.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.4.2...v2.5.0
[2.4.2]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.4.1...v2.4.2
[2.4.1]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.4.0...v2.4.1
[2.4.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.9.0...v2.0.0
[1.9.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.8.1...v1.9.0
[1.8.1]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.8.0...v1.8.1
[1.8.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v0.1...v1.0.0
