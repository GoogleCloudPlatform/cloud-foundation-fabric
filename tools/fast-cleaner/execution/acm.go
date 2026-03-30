package execution

import (
	"fmt"

	"fast-cleaner/api"
	"fast-cleaner/discovery"
)

// DeleteACMResources deletes Service Perimeters, Access Levels, and Access Policies.
func DeleteACMResources(client *api.Client, tree *discovery.Tree) error {
	var hasError bool

	processNode := func(n *discovery.ResourceNode) {
		// 1. Delete Service Perimeters
		for _, sp := range n.ServicePerimeters {
			fmt.Printf("  - Deleting service perimeter %s...\n", sp.Title)
			if err := client.DeleteServicePerimeter(sp.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to delete service perimeter %s: %v\n", sp.Title, err)
				hasError = true
			}
		}

		// 2. Delete Access Levels
		for _, al := range n.AccessLevels {
			fmt.Printf("  - Deleting access level %s...\n", al.Title)
			if err := client.DeleteAccessLevel(al.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to delete access level %s: %v\n", al.Title, err)
				hasError = true
			}
		}

		// 3. Delete Access Policies
		for _, ap := range n.AccessPolicies {
			fmt.Printf("  - Deleting access policy %s...\n", ap.Title)
			if err := client.DeleteAccessPolicy(ap.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to delete access policy %s: %v\n", ap.Title, err)
				hasError = true
			}
		}
	}

	for _, f := range tree.Folders {
		processNode(f)
	}

	processNode(tree.Root)

	if hasError {
		return fmt.Errorf("one or more ACM resources failed to delete")
	}
	return nil
}
