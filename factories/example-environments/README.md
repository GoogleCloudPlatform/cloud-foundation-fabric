# Resource Factories

The example in this folder are derived from actual production use cases, and show how to use a factory module and how you could structure your codebase for multiple environments.


## Resource Factories usage - Managing subnets


At the top level of this directory, besides the `README.md` your're reading now, you'll find

- `dev/`, a directory which holds all configurations for the *development* environment
- `prod/`, a directory which holds all configurations for the *production* environment
- `main.tf`, a simple terraform file which consumes the [`subnets`](../subnets/) module


Each environment directory structure is meant to mimic your GCP resources structure 

```
.
├── dev                              # Environment
│   ├── project-dev-a                # Project id
│   │   └── vpc-alpha                # VPC name
│   │       ├── subnet-alpha-a.yaml  # Subnet name (one file per subnet)
│   │       └── subnet-alpha-b.yaml
│   └── project-dev-b
│       ├── vpc-beta
│       │   └── subnet-beta-a.yaml
│       └── vpc-gamma
│           └── subnet-gamma-a.yaml
├── prod
│   └── project-prod-a
│       └── vpc-alpha
│           ├── subnet-alpha-a.yaml
│           └── subnet-alpha-b.yaml
├── main.tf
└── README.md
```

Since this resource factory only creates subnets, projects and VPCs are expected to exist.

In this example, a single `main.tf` file (hence a single state) drives the creation of both the `dev` and the `prod` environment. Another option you might want to consider, in line with the CI/CD pipeline or processes you have in place, might be to move the `main.tf` to the each environment directory, so that states (and pipelines) can be separated.

