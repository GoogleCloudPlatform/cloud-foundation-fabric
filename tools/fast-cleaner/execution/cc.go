package execution

import (
	"fmt"
	"strings"

	"fast-cleaner/api"
	"fast-cleaner/discovery"
)

// DeleteCustomConstraints deletes Custom Organization Policies.
func DeleteCustomConstraints(client *api.Client, tree *discovery.Tree) error {
	var hasError bool

	processNode := func(n *discovery.ResourceNode) {
		for _, c := range n.CustomConstraints {
			nameTokens := strings.Split(c.Name, "/")
			displayName := nameTokens[len(nameTokens)-1]

			fmt.Printf("  - Deleting Custom Constraint %s from %s...\n", displayName, n.Name)
			if err := client.DeleteCustomConstraint(c.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to delete Custom Constraint %s: %v\n", c.Name, err)
				hasError = true
			}
		}
	}

	for _, f := range tree.Folders {
		processNode(f)
	}

	processNode(tree.Root)

	if hasError {
		return fmt.Errorf("one or more Custom Constraints failed to delete")
	}
	return nil
}
