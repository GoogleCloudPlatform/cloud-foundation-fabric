package execution

import (
	"fmt"

	"fast-cleaner/api"
	"fast-cleaner/discovery"
)

// RemoveTagBindings removes all tag bindings from all discovered projects and folders.
func RemoveTagBindings(client *api.Client, tree *discovery.Tree) error {
	var hasError bool
	for _, p := range tree.Projects {
		for _, b := range p.TagBindings {
			fmt.Printf("  - Deleting tag binding %s from project %s...\n", b.Name, p.Name)
			if err := client.DeleteTagBinding(b.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to delete tag binding %s from project %s: %v\n", b.Name, p.Name, err)
				hasError = true
			}
		}
	}
	for _, f := range tree.Folders {
		for _, b := range f.TagBindings {
			fmt.Printf("  - Deleting tag binding %s from folder %s...\n", b.Name, f.Name)
			if err := client.DeleteTagBinding(b.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to delete tag binding %s from folder %s: %v\n", b.Name, f.Name, err)
				hasError = true
			}
		}
	}
	if hasError {
		return fmt.Errorf("one or more tag bindings failed to delete")
	}
	return nil
}

// DeleteTagDefinitions deletes the discovered TagValues and TagKeys.
func DeleteTagDefinitions(client *api.Client, tree *discovery.Tree) error {
	var hasError bool

	// Iterate over TagKeys so we don't skip keys that failed value discovery
	for _, key := range tree.TagKeys {
		keyName := key.Name
		values := tree.TagValues[keyName]

		// 1. Delete all values first
		for _, v := range values {
			fmt.Printf("  - Deleting tag value %s (%s)...\n", v.Name, v.ShortName)
			if err := client.DeleteTagValue(v.Name); err != nil {
				// We don't return here to allow the tool to try deleting other values/keys
				// Sometimes invisible tag bindings (e.g. on soft-deleted buckets) block this.
				fmt.Printf("    [WARNING] Failed to delete tag value %s: %v\n", v.Name, err)
				hasError = true
			}
		}

		// 2. Delete the key itself
		fmt.Printf("  - Deleting tag key %s...\n", keyName)
		if err := client.DeleteTagKey(keyName); err != nil {
			fmt.Printf("    [WARNING] Failed to delete tag key %s: %v\n", keyName, err)
			hasError = true
		}
	}

	if hasError {
		return fmt.Errorf("one or more tag definitions failed to delete")
	}
	return nil
}
