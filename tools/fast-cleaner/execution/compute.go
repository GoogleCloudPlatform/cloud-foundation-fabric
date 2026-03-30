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
