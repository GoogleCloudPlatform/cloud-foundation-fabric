# Mixer

Mixer is a collection of ready to use (and customize) recipes to create platform blueprints.
Mixer enables well known scenarios in the area of AI, data and application modernization.

## How to use

- Setup a project with [project factory]() (optional)
Create a project using the `*-prj.yaml` recipe in the `recipes` folder. If you don't
execute this step we expect you to have a project already setup with the same
characteristics, service accounts, permissions as described in the recipe.

- Setup platform components for your recipe

```shell
terraform init

terraform apply -var recipe_file=ai-agent-conversational.yaml
```

## Contribute

You can either add a new recipe based on existing comopnents already integrated
in mixer, or integrate new components before writing new recipes.

To add new components:
- create a .tf file in the main folder for the product you want to integrate.
Similarly to other files, make sure it can either read a yaml file or a variable
from tfvars

To add a recipe:

- drop a new .yaml receipe file in the receipes folder. You can inspect yaml
defaults in each product tf file in the main folder.
- drop another .yaml receipt name as aboved with the prefix `-prj` in the recipes
folder. This file should be passed to project factory to optionally create the
project and the "system-level" prerequisites (enable APIs, SA, permissions, ...)
