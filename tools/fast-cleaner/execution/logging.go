package execution

import (
	"fmt"

	"fast-cleaner/api"
	"fast-cleaner/discovery"
)

// RemoveSinks removes all log sinks from the root and all folders.
func RemoveSinks(client *api.Client, tree *discovery.Tree) error {
	var hasError bool
	// Remove from root
	for _, sink := range tree.Root.Sinks {
		// Ignore default system sinks as they cannot be deleted via API
		if sink.Name == "_Default" || sink.Name == "_Required" {
			continue
		}
		fmt.Printf("  - Deleting sink %s from %s...\n", sink.Name, tree.Root.Name)
		if err := client.DeleteSink(tree.Root.Name, sink.Name); err != nil {
			fmt.Printf("    [WARNING] Failed to delete sink %s from %s: %v\n", sink.Name, tree.Root.Name, err)
			hasError = true
		}
	}

	// Remove from all folders
	for _, f := range tree.Folders {
		for _, sink := range f.Sinks {
			// Ignore default system sinks
			if sink.Name == "_Default" || sink.Name == "_Required" {
				continue
			}
			fmt.Printf("  - Deleting sink %s from folder %s...\n", sink.Name, f.Name)
			if err := client.DeleteSink(f.Name, sink.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to delete sink %s from folder %s: %v\n", sink.Name, f.Name, err)
				hasError = true
			}
		}
	}
	if hasError {
		return fmt.Errorf("one or more log sinks failed to delete")
	}
	return nil
}
