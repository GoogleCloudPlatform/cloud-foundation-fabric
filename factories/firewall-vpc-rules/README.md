# Google Cloud VPC Firewall Factories

This collection of modules implement two different metodologies for the creation of VPC firewall rules, both based on leveraging well-defined `yaml` configuration files.

- The [flat module](flat/) delegates the definition of all firewall rules metadata (project, network amongst other) to the individual `yaml` configuration. This module allows for maximum flexibility, and a custom logical grouping of resources which can be trasversal to the traditional resource hierarchy, and could be useful in scenarios where networking is not managed centrally by a single team.
- The [nested module](nested/) requires and enforces a semantical folder structure that carries some of the rules metadata (project and network), and leaves the rest to each `yaml` configuration. This solution allows for the definition of a resource hierarchy that is aligned with the organisational resource structure.
