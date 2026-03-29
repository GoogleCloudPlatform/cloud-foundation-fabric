package discovery

import (
	"fmt"

	"fast-cleaner/api"
)

// ResourceNode represents a node in the GCP resource hierarchy (Org, Folder, or Project)
type ResourceNode struct {
	Name                    string
	Type                    string // "organization", "folder", "project"
	Raw                     interface{} // *api.Folder or *api.Project
	Children                []*ResourceNode
	
	// Discovered dependencies that must be deleted first
	TagBindings             []api.TagBinding
	Liens                   []api.Lien
	FirewallAssociations    []api.FirewallPolicyAssociation
	OrgPolicies             []api.Policy
	Sinks                   []api.LogSink
}

// Tree contains the hierarchical structure and flat lists for easy processing.
type Tree struct {
	Root     *ResourceNode
	Folders  []*ResourceNode // Stored in post-order (bottom-up) for safe deletion
	Projects []*ResourceNode
	TagKeys  []api.TagKey
	TagValues map[string][]api.TagValue
}

// Discover maps the entire resource hierarchy starting from a parent.
func Discover(client *api.Client, rootName string, verbose bool) (*Tree, error) {
	if verbose {
		fmt.Printf("[Discovery] Starting discovery from root: %s\n", rootName)
	}

	rootType := "folder"
	if len(rootName) >= 14 && rootName[:14] == "organizations/" {
		rootType = "organization"
	}

	rootNode := &ResourceNode{
		Name: rootName,
		Type: rootType,
	}

	tree := &Tree{
		Root: rootNode,
		TagValues: make(map[string][]api.TagValue),
	}

	// Fetch Tag Keys for the root
	if verbose {
		fmt.Printf("  [Discovery] Fetching tag keys defined on %s...\n", rootName)
	}
	keys, err := client.ListTagKeys(rootName)
	if err == nil {
		tree.TagKeys = keys
		for _, k := range keys {
			if verbose {
				fmt.Printf("  [Discovery] Fetching tag values for key %s...\n", k.Name)
			}
			values, err := client.ListTagValues(k.Name)
			if err == nil {
				tree.TagValues[k.Name] = values
			}
		}
	}

	// Fetch Sinks for the root
	if verbose {
		fmt.Printf("  [Discovery] Fetching sinks defined on %s...\n", rootName)
	}
	if sinks, err := client.ListSinks(rootName); err == nil {
		rootNode.Sinks = sinks
	}

	err = walk(client, rootNode, tree, verbose)
	if err != nil {
		return nil, err
	}

	return tree, nil
}

// walk recursively queries folders and projects.
// It populates the node's Children and appends to the Tree's flat lists.
func walk(client *api.Client, node *ResourceNode, tree *Tree, verbose bool) error {
	// 1. Find and attach projects
	if verbose {
		fmt.Printf("  [Discovery] Listing projects under %s...\n", node.Name)
	}
	projects, err := client.ListProjects(node.Name)
	if err != nil {
		return fmt.Errorf("failed listing projects under %s: %w", node.Name, err)
	}

	for _, p := range projects {
		if p.State != "ACTIVE" {
			continue
		}
		
		projNode := &ResourceNode{
			Name: p.Name,
			Type: "project",
			Raw:  &p,
		}
		
		// Discover Tag Bindings for Project
		tagParent := fmt.Sprintf("//cloudresourcemanager.googleapis.com/%s", p.Name)
		if verbose {
			fmt.Printf("  [Discovery] Fetching tags for project %s...\n", p.Name)
		}
		if bindings, err := client.ListTagBindings(tagParent); err == nil {
			projNode.TagBindings = bindings
		} else {
			return fmt.Errorf("failed getting tags for project %s: %w", p.Name, err)
		}

		// Discover Liens for Project
		if verbose {
			fmt.Printf("  [Discovery] Fetching liens for project %s...\n", p.Name)
		}
		if liens, err := client.ListLiens(p.Name); err == nil {
			projNode.Liens = liens
		} else {
			return fmt.Errorf("failed getting liens for project %s: %w", p.Name, err)
		}

		node.Children = append(node.Children, projNode)
		tree.Projects = append(tree.Projects, projNode)
	}

	// 2. Find and attach folders
	if verbose {
		fmt.Printf("  [Discovery] Listing folders under %s...\n", node.Name)
	}
	folders, err := client.ListFolders(node.Name)
	if err != nil {
		return fmt.Errorf("failed listing folders under %s: %w", node.Name, err)
	}

	for _, f := range folders {
		if f.State != "ACTIVE" {
			continue
		}
		
		folderNode := &ResourceNode{
			Name: f.Name,
			Type: "folder",
			Raw:  &f,
		}

		// Discover Tag Bindings for Folder
		tagParent := fmt.Sprintf("//cloudresourcemanager.googleapis.com/%s", f.Name)
		if verbose {
			fmt.Printf("  [Discovery] Fetching tags for folder %s...\n", f.Name)
		}
		if bindings, err := client.ListTagBindings(tagParent); err == nil {
			folderNode.TagBindings = bindings
		} else {
			return fmt.Errorf("failed getting tags for folder %s: %w", f.Name, err)
		}

		// Discover Firewall Policy Associations for Folder
		if verbose {
			fmt.Printf("  [Discovery] Fetching firewall associations for folder %s...\n", f.Name)
		}
		if fwAssoc, err := client.ListFirewallPolicyAssociations(f.Name); err == nil {
			folderNode.FirewallAssociations = fwAssoc
		} else {
			return fmt.Errorf("failed getting firewall assocs for folder %s: %w", f.Name, err)
		}
		
		// Discover Org Policies for Folder
		if verbose {
			fmt.Printf("  [Discovery] Fetching org policies for folder %s...\n", f.Name)
		}
		if policies, err := client.ListOrgPolicies(f.Name); err == nil {
			folderNode.OrgPolicies = policies
		} else {
			return fmt.Errorf("failed getting org policies for folder %s: %w", f.Name, err)
		}

		// Discover Sinks for Folder
		if verbose {
			fmt.Printf("  [Discovery] Fetching sinks for folder %s...\n", f.Name)
		}
		if sinks, err := client.ListSinks(f.Name); err == nil {
			folderNode.Sinks = sinks
		} else {
			return fmt.Errorf("failed getting sinks for folder %s: %w", f.Name, err)
		}

		node.Children = append(node.Children, folderNode)

		// Recursively walk the child folder BEFORE adding it to the flat folder list.
		// This guarantees post-order (bottom-up) traversal which is required for folder deletion.
		err := walk(client, folderNode, tree, verbose)
		if err != nil {
			return err
		}

		tree.Folders = append(tree.Folders, folderNode)
	}

	return nil
}
