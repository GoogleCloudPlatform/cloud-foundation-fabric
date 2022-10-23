# FAST GitHub repository management

This small extra stage allows creation and management of GitHub repositories used to host FAST stage code, including initial population of files and rewriting of module sources.

This stage is designed for quick repository creation in a GitHub organization, and is not suited for medium or long-term repository management especially if you enable initial population of files.

## Initial population caveats

Initial file population of repositories is controlled via the `populate_from` attribute, and needs a bit of care:

- never run this stage gain with the same variables used for population once the repository starts being used,  as **Terraform will manage file state and revert any changes at each apply**, which is probably not what you want.
- be mindful when enabling initial population of the modules repository, as the number of resulting files to manage is very close to the GitHub hourly limit for their API

The scenario for which this stage has been designed is one-shot creation and/or population of stage repositories, running it multiple times with different variables and Terraform states if incrmental creation is needed for subsequent FAST stages (e.g. GKE, data platform, etc.).

## GitHub provider credentials

A [GitHub token](https://github.com/settings/tokens) is needed to authenticate against their API. The token needs organization-level permissions, like shown in this screenshot:

<p align="center">
  <img src="github_token.png" alt="GitHub token scopes.">
</p>

## Variable configuration

The `organization` required variable sets the GitHub organization where repositories will be created, and is used to configure the Terraform provider.

The `repositories` variable is where you configure which repositories to create, whether initial population of files is desired, and which repository is used to host modules.

This is an example that creates repositories for stages 00 and 01, defines an existing repositories as the source for modules, and populates initial files for stages 00, 01, and 02:

```hcl
organization = "ludomagno"
repositories = {
  fast_00_bootstrap = {
    create_options = {
      description = "FAST bootstrap."
      features = {
        issues = true
      }
    }
    populate_from = "../../stages/00-bootstrap"
  }
  fast_01_resman = {
    create_options = {
      description = "FAST resource management."
      features = {
        issues = true
      }
    }
    populate_from = "../../stages/01-resman"
  }
  fast_02_networking = {
    populate_from = "../../stages/02-networking-peering"
  }
  fast_modules = {
    has_modules = true
  }
}
```

The `create_options` repository attribute controls creation: if the attribute is not present, the repository is assumed to be already existing.

Initial population depends on a modules repository being configured, identified by the `has_modules` attribute, and on `populate_from` attributes in each repository where population is required, pointing to the folder holding the files to be committed.

Finally, a `commit_config` variable is optional: it can be used to configure author, email and message used in commits for initial population of files, its defaults are probably fine for most use cases.

## Modules secret

When initial population is configured for a repository, this stage also adds a secret with the private key used to authenticate against the modules repository. This matches the configuration of the GitHub workflow files created for each FAST stage when CI/CD is enabled.
