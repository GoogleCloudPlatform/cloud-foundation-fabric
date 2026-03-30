package execution

import (
	"fmt"

	"fast-cleaner/api"
	"fast-cleaner/discovery"
)

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
