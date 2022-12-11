# Changelog

All notable changes to this project will be documented in this file.
<!-- markdownlint-disable MD024 -->

## [Unreleased]
<!-- None < 2022-09-09 18:02:15+00:00 -->

### BLUEPRINTS

- [[#1045](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1045)] Assorted module fixes ([ludoo](https://github.com/ludoo)) <!-- 2022-12-10 14:40:15+00:00 -->
- [[#1044](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1044)] **incompatible change:** Refactor net-glb module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-12-08 16:35:45+00:00 -->
- [[#982](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/982)] Adding Secondary IP Utilization calculation ([brianhmj](https://github.com/brianhmj)) <!-- 2022-12-07 10:45:21+00:00 -->
- [[#1037](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1037)] Bump qs and formidable in /blueprints/cloud-operations/apigee/functions/export ([dependabot[bot]](https://github.com/dependabot[bot])) <!-- 2022-12-06 15:43:35+00:00 -->
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

- [[#1045](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1045)] Assorted module fixes ([ludoo](https://github.com/ludoo)) <!-- 2022-12-10 14:40:15+00:00 -->
- [[#1014](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1014)] Update typos in `net-vpc-firewall` README.md ([aymanfarhat](https://github.com/aymanfarhat)) <!-- 2022-12-08 16:48:26+00:00 -->
- [[#1044](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1044)] **incompatible change:** Refactor net-glb module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-12-08 16:35:45+00:00 -->
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

- [[#1045](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1045)] Assorted module fixes ([ludoo](https://github.com/ludoo)) <!-- 2022-12-10 14:40:15+00:00 -->
- [[#1040](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1040)] Fix name in google_pubsub_schema resource ([VictorCavalcanteLG](https://github.com/VictorCavalcanteLG)) <!-- 2022-12-08 17:25:36+00:00 -->
- [[#1043](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1043)] added reverse lookup feature to module dns #1042 ([chemapolo](https://github.com/chemapolo)) <!-- 2022-12-08 17:13:05+00:00 -->
- [[#1044](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1044)] **incompatible change:** Refactor net-glb module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-12-08 16:35:45+00:00 -->
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
- [[#997](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/997)] Add BigQuery subcriptions to Pubsub module. ([iht](https://github.com/iht)) <!-- 2022-11-21 17:26:52+00:00 -->
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
- [[#974](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/974)] **incompatible change:** Refactor net-ilb-l7 module for Terraform 1.3 ([ludoo](https://github.com/ludoo)) <!-- 2022-11-14 13:39:00+00:00 -->
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
- [[#775](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/775)] net-glb: Added support for regional external HTTP(s) load balancing ([rosmo](https://github.com/rosmo)) <!-- 2022-08-27 20:58:11+00:00 -->
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
- [[#695](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/695)] Modified reserved IP address outputs in net-glb module ([apichick](https://github.com/apichick)) <!-- 2022-07-01 17:13:10+00:00 -->
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
- new `net-ilb-l7` module
- new [02-networking-peering](fast/stages/02-networking-peering) networking stage
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
- new `api-gateway` [module](./modules/api-gateway) and [example](blueprints/serverless/api-gateway).
- **incompatible change** the `psn_ranges` variable has been renamed to `psa_ranges` in the `net-vpc` module and its type changed from `list(string)` to `map(string)`
- **incompatible change** removed `iam` flag for organization and folder level sinks
- **incompatible change** removed `ingress_settings` configuration option in the `cloud-functions` module.
- new [m4ce VM example](blueprints/cloud-operations/vm-migration/)
- Support for resource management tags in the `organization`, `folder`, `project`, `compute-vm`, and `kms` modules
- new [data platform](fast/stages/03-data-platform) stage 3
- new [02-networking-nva](fast/stages/02-networking-nva) networking stage
- allow customizing the names of custom roles
- added `environment` and `context` resource management tags
- use resource management tags to restrict scope of roles/orgpolicy.policyAdmin
- use `xpnServiceAdmin` (custom role) for stage 3 service accounts that need to attach to a shared VPC
- simplify and standarize ourputs from each stage
- standarize names of projects, service accounts and buckets
- swtich to folder-level `xpnAdmin` and `xpnServiceAdmin`
- moved networking projects to folder matching their enviroments

## [13.0.0] - 2022-01-27

- **initial Fabric FAST implementation**
- new `net-glb` module for Global External Load balancer
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
- new networking example showing how to organize [decentralized firewall](./blueprints/networking/decentralized-firewall/) management on GCP

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
- add `group-config` variable, `groups` and `group_self_links` outputs to `net-ilb` module to allow creating ILBs for externally managed instances
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
- fix health checks in `compute-mig` and `net-ilb` modules
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
- add `compute-mig` and `net-ilb` modules
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
[Unreleased]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v18.0.0...HEAD
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
