package execution

import (
	"fmt"

	"fast-cleaner/api"
	"fast-cleaner/discovery"
)

// RemoveFirewallAssociations removes all firewall policy associations from all discovered folders.
func RemoveFirewallAssociations(client *api.Client, tree *discovery.Tree) error {
	for _, f := range tree.Folders {
		for _, assoc := range f.FirewallAssociations {
			fmt.Printf("  - Removing firewall policy association %s from folder %s...\n", assoc.Name, f.Name)
			if err := client.RemoveFirewallPolicyAssociation(assoc.FirewallPolicyId, assoc.Name); err != nil {
				return err
			}
		}
	}
	return nil
}

// RemoveSinks removes all log sinks from the root and all folders.
func RemoveSinks(client *api.Client, tree *discovery.Tree) error {
	// Remove from root
	for _, sink := range tree.Root.Sinks {
		// Ignore default system sinks as they cannot be deleted via API
		if sink.Name == "_Default" || sink.Name == "_Required" {
			continue
		}
		fmt.Printf("  - Deleting sink %s from %s...\n", sink.Name, tree.Root.Name)
		if err := client.DeleteSink(tree.Root.Name, sink.Name); err != nil {
			return err
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
				return err
			}
		}
	}
	return nil
}

// RemoveTagBindings removes all tag bindings from all discovered projects and folders.
func RemoveTagBindings(client *api.Client, tree *discovery.Tree) error {
	for _, p := range tree.Projects {
		for _, b := range p.TagBindings {
			fmt.Printf("  - Deleting tag binding %s from project %s...\n", b.Name, p.Name)
			if err := client.DeleteTagBinding(b.Name); err != nil {
				return err
			}
		}
	}
	for _, f := range tree.Folders {
		for _, b := range f.TagBindings {
			fmt.Printf("  - Deleting tag binding %s from folder %s...\n", b.Name, f.Name)
			if err := client.DeleteTagBinding(b.Name); err != nil {
				return err
			}
		}
	}
	return nil
}

// RemoveLiens removes all liens from all discovered projects.
func RemoveLiens(client *api.Client, tree *discovery.Tree) error {
	for _, p := range tree.Projects {
		for _, l := range p.Liens {
			fmt.Printf("  - Deleting lien %s from project %s (Reason: %s)...\n", l.Name, p.Name, l.Reason)
			if err := client.DeleteLien(l.Name); err != nil {
				return err
			}
		}
	}
	return nil
}

// RemoveFolderOrgPolicies deletes all explicit org policy overrides from folders.
func RemoveFolderOrgPolicies(client *api.Client, tree *discovery.Tree) error {
	for _, f := range tree.Folders {
		for _, pol := range f.OrgPolicies {
			fmt.Printf("  - Deleting org policy %s from folder %s...\n", pol.Name, f.Name)
			if err := client.DeleteOrgPolicy(pol.Name); err != nil {
				return err
			}
		}
	}
	return nil
}

// DeleteProjects deletes all discovered projects.
func DeleteProjects(client *api.Client, tree *discovery.Tree) error {
	for _, p := range tree.Projects {
		fmt.Printf("  - Deleting project %s...\n", p.Name)
		if err := client.DeleteProject(p.Name); err != nil {
			return fmt.Errorf("failed deleting project %s: %w", p.Name, err)
		}
	}
	return nil
}

// DeleteFolders deletes all discovered folders (assumes post-order sorting).
func DeleteFolders(client *api.Client, tree *discovery.Tree) error {
	for _, f := range tree.Folders {
		fmt.Printf("  - Deleting folder %s...\n", f.Name)
		if err := client.DeleteFolder(f.Name); err != nil {
			return fmt.Errorf("failed deleting folder %s: %w", f.Name, err)
		}
	}
	return nil
}

// DeleteTagDefinitions deletes the discovered TagValues and TagKeys.
func DeleteTagDefinitions(client *api.Client, tree *discovery.Tree) error {
	// 1. Delete all values first
	for keyName, values := range tree.TagValues {
		for _, v := range values {
			fmt.Printf("  - Deleting tag value %s (%s)...\n", v.Name, v.ShortName)
			if err := client.DeleteTagValue(v.Name); err != nil {
				// We don't return here to allow the tool to try deleting other values/keys
				// Sometimes invisible tag bindings (e.g. on soft-deleted buckets) block this.
				fmt.Printf("    [WARNING] Failed to delete tag value %s: %v\n", v.Name, err)
			}
		}
		
		// 2. Delete the key itself
		fmt.Printf("  - Deleting tag key %s...\n", keyName)
		if err := client.DeleteTagKey(keyName); err != nil {
			fmt.Printf("    [WARNING] Failed to delete tag key %s: %v\n", keyName, err)
		}
	}
	return nil
}
