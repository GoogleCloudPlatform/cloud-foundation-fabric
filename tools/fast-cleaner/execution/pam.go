package execution

import (
	"fmt"
	"strings"

	"fast-cleaner/api"
	"fast-cleaner/discovery"
)

// DeletePamResources deletes Privileged Access Manager entitlements.
func DeletePamResources(client *api.Client, tree *discovery.Tree) error {
	var hasError bool

	processNode := func(n *discovery.ResourceNode) {
		for _, e := range n.PamEntitlements {
			nameTokens := strings.Split(e.Name, "/")
			displayName := nameTokens[len(nameTokens)-1]

			fmt.Printf("  - Deleting PAM entitlement %s from %s...\n", displayName, n.Name)
			if err := client.DeletePamEntitlement(e.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to delete PAM entitlement %s: %v\n", e.Name, err)
				hasError = true
			}
		}
	}

	for _, p := range tree.Projects {
		processNode(p)
	}

	for _, f := range tree.Folders {
		processNode(f)
	}

	processNode(tree.Root)

	if hasError {
		return fmt.Errorf("one or more PAM entitlements failed to delete")
	}
	return nil
}
