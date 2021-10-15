# Resource Factories

The examples in this folder are derived from actual production use cases, and show how to use a factory module, and how to structure a codebase for multiple environments.

## Resource Factories usage - Managing subnets

At the top level of this directory, besides the `README.md` your're reading now, you'll find

- `dev/`, a directory which holds all configurations for the *development* environment
- `prod/`, a directory which holds all configurations for the *production* environment
  
and on each directory, `main.tf`, a simple terraform file which consumes the [`subnets`](../subnets/) module and the configurations.

Each environment directory structure is meant to mimic your GCP resource structure 

```
.
├── dev                                   # Environment
│   ├── conf                              # Configuration directory
│   │   ├── project-dev-a                 # Project id 
│   │   │   └── vpc-alpha                 # VPC name
│   │   │       ├── subnet-alpha-a.yaml   # Subnet name (one file per subnet)
│   │   │       └── subnet-alpha-b.yaml
│   │   └── project-dev-b
│   │       ├── vpc-beta
│   │       │   └── subnet-beta-a.yaml
│   │       └── vpc-gamma
│   │           └── subnet-gamma-a.yaml
│   └── main.tf
└── prod
    ├── conf
    │   └── project-prod-a
    │       └── vpc-alpha
    │           ├── subnet-alpha-a.yaml
    │           └── subnet-alpha-b.yaml
    └── main.tf
```

Since this resource factory only creates subnets, projects and VPCs are expected to exist.

In this example, each environment is implemented as a distinct factory, and each has its own `main.tf` file (and hence a dedicated state). 
Another option you might want to consider, in line with the CI/CD pipeline or processes you have in place, might be to leverage a single `main.tf` consuming both environment directories.

