# Fabric Manifesto

This project is managed by several Google PSO people, and provides a collection of carefully crafted Terraform assets to deploy GCP resources. It has matured over years of experience helping customers on foundational and migration engagements, and it’s a live asset used to kickstart automation on GCP. It has also been used for examples on the official [GCP blog](https://cloud.google.com/blog/products/networking/how-to-use-cloud-dns-peering-in-a-shared-vpc-environment), [documentation](https://cloud.google.com/architecture/deploy-hub-spoke-network-using-peering#to-use-your-local-host), and several Medium articles.

Fabric provides both an extensive collection of modules to manage individual GCP entities, and a growing library of end-to-end examples that implement common GCP use-cases (e.g. shared VPC, hub-and-spoke network, remediation via Asset Inventory, etc.). Many of these examples are abridged versions of solutions implemented in production, and they illustrate how to wire Fabric's modules together to deploy non-trivial, real-world scenarios.

Fabric's flexibility, leanness and unified module API also make it a great tool for prototyping or building POCs. However, Fabric's real power shows when it's used via a fork-and-own approach, where the original code is used as a starting point, and further customized in-house to accommodate specific requirements. This is in fact a primary use case for most security-conscious GCP users, who cannot delegate module ownership to external sources.

## Core design principles

- keep modules as lean as possible, to allow for easy readability and simple reuse (e.g. no submodules)
- design for composition, taking particular care in providing a unified API across modules (e.g. IAM)
- no external dependencies or code, Fabric's only dependency should be the Terraform GCP provider.
- map one module to a single GCP entity (e.g. project, ILB), and implement all related functionality like IAM, policies, etc inside the module
- design module variables to provide the smallest possible required surface, by grouping related attributes together and providing sensible defaults
- don’t implement opinionated approaches in modules beyond attribute defaults, for easier extensibility and to support all customer use cases
