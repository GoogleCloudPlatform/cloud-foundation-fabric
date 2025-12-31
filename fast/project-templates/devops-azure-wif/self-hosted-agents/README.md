# Self-Hosted Agents

If self-hosted agents are required, a sample Container Optimized OS based agent is provided as part of this example.

Several steps are needed to bootstrap the provided example for a hosted agent:

- build the Docker image according to the [Microsoft-provided documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux)
- enable the Artifact Registry provided as part of this example via the `hosted_agent_config.create_registry` variable
- create an agent token on Azure Devops and save it to a local `token.txt` file
- apply the Terraform provided in the `self-hosted-agents` folder so that the Artifact Registry and token secrets are created
- copy the registry URL from the Terraform outputs, then tag and push the built Docker image
- configure the rest of the `hosted_agent_config` variable and apply Terraform to deploy the hosted agent

This is a sample configuration for the `hosted_agent_config` variable:

```hcl
# TODO: provide example
```
