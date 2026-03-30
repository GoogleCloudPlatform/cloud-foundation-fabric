package execution

import (
	"fmt"

	"fast-cleaner/api"
	"fast-cleaner/discovery"
)

// DeleteFirewallPolicies deletes all firewall policies from all folders and then the root.
func DeleteFirewallPolicies(client *api.Client, tree *discovery.Tree) error {
	var hasError bool
	deletedPolicies := make(map[string]bool)

	for _, f := range tree.Folders {
		for _, pol := range f.FirewallPolicies {
			if deletedPolicies[pol.Id] {
				continue
			}
			fmt.Printf("  - Deleting firewall policy %s (%s) from folder %s...\n", pol.Name, pol.Id, f.Name)
			if err := client.DeleteFirewallPolicy(pol.Id); err != nil {
				fmt.Printf("    [WARNING] Failed to delete firewall policy %s: %v\n", pol.Id, err)
				hasError = true
			} else {
				deletedPolicies[pol.Id] = true
			}
		}
	}

	for _, pol := range tree.Root.FirewallPolicies {
		if deletedPolicies[pol.Id] {
			continue
		}
		fmt.Printf("  - Deleting firewall policy %s (%s) from %s...\n", pol.Name, pol.Id, tree.Root.Name)
		if err := client.DeleteFirewallPolicy(pol.Id); err != nil {
			fmt.Printf("    [WARNING] Failed to delete firewall policy %s: %v\n", pol.Id, err)
			hasError = true
		} else {
			deletedPolicies[pol.Id] = true
		}
	}

	if hasError {
		return fmt.Errorf("one or more firewall policies failed to delete")
	}
	return nil
}

// RemoveFirewallAssociations removes all firewall policy associations from all discovered folders and the root.
func RemoveFirewallAssociations(client *api.Client, tree *discovery.Tree) error {
	var hasError bool

	for _, f := range tree.Folders {
		for _, assoc := range f.FirewallAssociations {
			fmt.Printf("  - Removing firewall policy association %s from folder %s...\n", assoc.Name, f.Name)
			if err := client.RemoveFirewallPolicyAssociation(assoc.FirewallPolicyId, assoc.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to remove firewall policy association %s: %v\n", assoc.Name, err)
				hasError = true
			}
		}
	}

	for _, assoc := range tree.Root.FirewallAssociations {
		fmt.Printf("  - Removing firewall policy association %s from %s...\n", assoc.Name, tree.Root.Name)
		if err := client.RemoveFirewallPolicyAssociation(assoc.FirewallPolicyId, assoc.Name); err != nil {
			fmt.Printf("    [WARNING] Failed to remove firewall policy association %s: %v\n", assoc.Name, err)
			hasError = true
		}
	}

	if hasError {
		return fmt.Errorf("one or more firewall policy associations failed to delete")
	}
	return nil
}

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

// RemoveLiens removes all liens from all discovered projects.
func RemoveLiens(client *api.Client, tree *discovery.Tree) error {
	var hasError bool
	for _, p := range tree.Projects {
		for _, l := range p.Liens {
			fmt.Printf("  - Deleting lien %s from project %s (Reason: %s)...\n", l.Name, p.Name, l.Reason)
			if err := client.DeleteLien(l.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to delete lien %s from project %s: %v\n", l.Name, p.Name, err)
				hasError = true
			}
		}
	}
	if hasError {
		return fmt.Errorf("one or more liens failed to delete")
	}
	return nil
}

// RemoveFolderOrgPolicies deletes all explicit org policy overrides from folders.
func RemoveFolderOrgPolicies(client *api.Client, tree *discovery.Tree) error {
	var hasError bool
	for _, f := range tree.Folders {
		for _, pol := range f.OrgPolicies {
			fmt.Printf("  - Deleting org policy %s from folder %s...\n", pol.Name, f.Name)
			if err := client.DeleteOrgPolicy(pol.Name); err != nil {
				fmt.Printf("    [WARNING] Failed to delete org policy %s from folder %s: %v\n", pol.Name, f.Name, err)
				hasError = true
			}
		}
	}
	if hasError {
		return fmt.Errorf("one or more folder org policies failed to delete")
	}
	return nil
}

// DeleteProjects deletes all discovered projects.
func DeleteProjects(client *api.Client, tree *discovery.Tree) error {
	var hasError bool
	for _, p := range tree.Projects {
		fmt.Printf("  - Deleting project %s...\n", p.Name)
		if err := client.DeleteProject(p.Name); err != nil {
			fmt.Printf("    [WARNING] Failed to delete project %s: %v\n", p.Name, err)
			hasError = true
		}
	}
	if hasError {
		return fmt.Errorf("one or more projects failed to delete")
	}
	return nil
}

// DeleteFolders deletes all discovered folders (assumes post-order sorting).
func DeleteFolders(client *api.Client, tree *discovery.Tree) error {
	var hasError bool
	for _, f := range tree.Folders {
		fmt.Printf("  - Deleting folder %s...\n", f.Name)
		if err := client.DeleteFolder(f.Name); err != nil {
			fmt.Printf("    [WARNING] Failed to delete folder %s: %v\n", f.Name, err)
			hasError = true
		}
	}
	if hasError {
		return fmt.Errorf("one or more folders failed to delete")
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
