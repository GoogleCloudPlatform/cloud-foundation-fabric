package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	"fast-cleaner/api"
	"fast-cleaner/discovery"
	"fast-cleaner/execution"
)

func main() {
	var dryRun bool
	var quiet bool

	flag.BoolVar(&dryRun, "dry-run", false, "Simulate operations without making changes")
	flag.BoolVar(&quiet, "q", false, "Quiet output (suppresses running operations during discovery)")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s [flags] <target>\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "\nArguments:\n")
		fmt.Fprintf(os.Stderr, "  <target>   The target root for cleanup (e.g., organizations/12345 or folders/12345)\n")
		fmt.Fprintf(os.Stderr, "\nFlags:\n")
		flag.PrintDefaults()
	}

	flag.Parse()

	if flag.NArg() < 1 {
		fmt.Println("Error: target argument is required.")
		flag.Usage()
		os.Exit(1)
	}

	target := flag.Arg(0)

	if !strings.HasPrefix(target, "organizations/") && !strings.HasPrefix(target, "folders/") {
		fmt.Printf("Error: invalid target format '%s'. Must start with 'organizations/' or 'folders/'\n", target)
		os.Exit(1)
	}

	ctx := context.Background()

	// Initialize the GCP API client
	client, err := api.NewClient(ctx, dryRun)
	if err != nil {
		log.Fatalf("Failed to initialize GCP client: %v", err)
	}

	printInitialization(target, dryRun)

	// Phase 1: Discovery
	fmt.Printf("\n[Phase 1] Starting Discovery phase...\n")
	tree, err := discovery.Discover(client, target, !quiet)
	if err != nil {
		log.Fatalf("Discovery failed: %v", err)
	}

	// Phase 2: Plan
	printPlan(tree, dryRun)

	// Phase 3: Execution
	fmt.Printf("\n[Phase 3] Starting Execution phase...\n")

	// Interactive IAM Cleanup (Only for Organizations and Folders)
	if !dryRun {
		fmt.Printf("\n--- IAM Cleanup ---\n")
		fmt.Printf("Do you want to review and remove IAM bindings for %s? (y/N): ", target)
		reader := bufio.NewReader(os.Stdin)
		iamConf, _ := reader.ReadString('\n')
		iamConf = strings.TrimSpace(strings.ToLower(iamConf))

		if iamConf == "y" || iamConf == "yes" {
			policy, err := client.GetIamPolicy(target)
			if err != nil {
				log.Printf("Failed to fetch IAM policy: %v\n", err)
			} else if policy != nil {
				if updatedPolicy := promptForIamCleanup(policy, reader); updatedPolicy != nil {
					fmt.Printf("\n[Step 0] Updating IAM Policy...\n")
					if err := client.SetIamPolicy(target, updatedPolicy); err != nil {
						log.Printf("ERROR updating IAM policy: %v\n", err)
					} else {
						fmt.Printf("  - Successfully updated IAM policy for %s\n", target)
					}
				}
			}
		}
	}

	executeCleanup(client, tree)

	fmt.Printf("\nCleanup operations completed.\n")
}

func printInitialization(target string, dryRun bool) {
	fmt.Printf("==================================================\n")
	fmt.Printf("FAST Cleaner Initialization\n")
	fmt.Printf("Target: %s\n", target)
	if dryRun {
		fmt.Printf("Mode: DRY-RUN (no destructive changes will be made)\n")
	} else {
		fmt.Printf("Mode: LIVE (WARNING: destructive operations enabled)\n")
	}
	fmt.Printf("==================================================\n")
}

func printPlan(tree *discovery.Tree, dryRun bool) {
	fmt.Printf("\n--- Discovery Summary (Execution Plan) ---\n")

	totalProjTags, totalProjLiens, totalProjPam := 0, 0, 0
	fmt.Printf("Found %d Active Projects\n", len(tree.Projects))
	for i, p := range tree.Projects {
		raw := p.Raw.(*api.Project)
		tagsInfo, liensInfo, pamInfo := "", "", ""

		if len(p.TagBindings) > 0 {
			tagsInfo = fmt.Sprintf(" 🏷️[%d]", len(p.TagBindings))
			totalProjTags += len(p.TagBindings)
		}
		if len(p.Liens) > 0 {
			liensInfo = fmt.Sprintf(" 🔒[%d]", len(p.Liens))
			totalProjLiens += len(p.Liens)
		}
		if len(p.PamEntitlements) > 0 {
			pamInfo = fmt.Sprintf(" 🎟️[%d]", len(p.PamEntitlements))
			totalProjPam += len(p.PamEntitlements)
		}
		fmt.Printf("  %d. %s (ID: %s) [%s]%s%s%s\n", i+1, p.Name, raw.ProjectId, raw.DisplayName, tagsInfo, liensInfo, pamInfo)
	}

	totalFolderTags, totalFolderFw, totalFolderFwPol, totalFolderPol, totalFolderSinks, totalFolderACM, totalFolderPam, totalFolderCC := 0, 0, 0, 0, 0, 0, 0, 0
	fmt.Printf("\nFound %d Active Folders (Post-Order / Bottom-Up)\n", len(tree.Folders))
	for i, f := range tree.Folders {
		raw := f.Raw.(*api.Folder)
		tagsInfo, fwInfo, fwPolInfo, polInfo, acmInfo, pamInfo, ccInfo := "", "", "", "", "", "", ""
		if len(f.TagBindings) > 0 {
			tagsInfo = fmt.Sprintf(" 🏷️[%d]", len(f.TagBindings))
			totalFolderTags += len(f.TagBindings)
		}
		if len(f.FirewallAssociations) > 0 {
			fwInfo = fmt.Sprintf(" 🛡️[%d]", len(f.FirewallAssociations))
			totalFolderFw += len(f.FirewallAssociations)
		}
		if len(f.FirewallPolicies) > 0 {
			fwPolInfo = fmt.Sprintf(" 🧱[%d]", len(f.FirewallPolicies))
			totalFolderFwPol += len(f.FirewallPolicies)
		}
		if len(f.OrgPolicies) > 0 {
			polInfo = fmt.Sprintf(" 📜[%d]", len(f.OrgPolicies))
			totalFolderPol += len(f.OrgPolicies)
		}

		sinkCount := 0
		for _, s := range f.Sinks {
			if s.Name != "_Default" && s.Name != "_Required" {
				sinkCount++
			}
		}
		sinkInfo := ""
		if sinkCount > 0 {
			sinkInfo = fmt.Sprintf(" 📥[%d]", sinkCount)
			totalFolderSinks += sinkCount
		}

		acmCount := len(f.AccessPolicies) + len(f.ServicePerimeters) + len(f.AccessLevels)
		if acmCount > 0 {
			acmInfo = fmt.Sprintf(" 🛂[%d]", acmCount)
			totalFolderACM += acmCount
		}

		if len(f.PamEntitlements) > 0 {
			pamInfo = fmt.Sprintf(" 🎟️[%d]", len(f.PamEntitlements))
			totalFolderPam += len(f.PamEntitlements)
		}

		if len(f.CustomConstraints) > 0 {
			ccInfo = fmt.Sprintf(" 🚧[%d]", len(f.CustomConstraints))
			totalFolderCC += len(f.CustomConstraints)
		}

		fmt.Printf("  %d. %s [%s]%s%s%s%s%s%s%s%s\n", i+1, f.Name, raw.DisplayName, tagsInfo, fwInfo, fwPolInfo, polInfo, sinkInfo, acmInfo, pamInfo, ccInfo)
	}
	fmt.Printf("------------------------------------------\n")

	// Plan Summary
	totalTagValues := 0
	for _, values := range tree.TagValues {
		totalTagValues += len(values)
	}

	rootSinkCount := 0
	for _, s := range tree.Root.Sinks {
		if s.Name != "_Default" && s.Name != "_Required" {
			rootSinkCount++
		}
	}
	rootFwPolCount := len(tree.Root.FirewallPolicies)
	rootFwAssocCount := len(tree.Root.FirewallAssociations)
	rootACMCount := len(tree.Root.AccessPolicies) + len(tree.Root.ServicePerimeters) + len(tree.Root.AccessLevels)
	rootPamCount := len(tree.Root.PamEntitlements)
	rootCCCount := len(tree.Root.CustomConstraints)

	fmt.Printf("\n--- Execution Plan ---\n")
	fmt.Printf("Will delete:\n")
	fmt.Printf("  - %d Projects\n", len(tree.Projects))
	fmt.Printf("  - %d Folders\n", len(tree.Folders))
	fmt.Printf("  - %d 🏷️ Tag Bindings\n", totalProjTags+totalFolderTags)
	fmt.Printf("  - %d 🔒 Liens\n", totalProjLiens)
	fmt.Printf("  - %d 🛡️ Firewall Associations\n", totalFolderFw+rootFwAssocCount)
	if (totalFolderFwPol + rootFwPolCount) > 0 {
		fmt.Printf("  - %d 🧱 Firewall Policies\n", totalFolderFwPol+rootFwPolCount)
	}
	if (totalFolderSinks + rootSinkCount) > 0 {
		fmt.Printf("  - %d 📥 Log Sinks\n", totalFolderSinks+rootSinkCount)
	}
	if len(tree.TagKeys) > 0 {
		fmt.Printf("  - %d 🔑 Tag Keys (with %d Tag Values)\n", len(tree.TagKeys), totalTagValues)
	}
	if totalFolderPol > 0 {
		fmt.Printf("  - %d 📜 Org Policies\n", totalFolderPol)
	}
	if (totalFolderACM + rootACMCount) > 0 {
		fmt.Printf("  - %d 🛂 ACM Resources\n", totalFolderACM+rootACMCount)
	}
	if (totalProjPam + totalFolderPam + rootPamCount) > 0 {
		fmt.Printf("  - %d 🎟️ PAM Entitlements\n", totalProjPam+totalFolderPam+rootPamCount)
	}
	if (totalFolderCC + rootCCCount) > 0 {
		fmt.Printf("  - %d 🚧 Custom Constraints\n", totalFolderCC+rootCCCount)
	}
	fmt.Printf("----------------------\n")
	if dryRun {
		fmt.Printf("\n[DRY RUN] Plan complete. Exiting without making changes.\n")
		os.Exit(0)
	}

	// Live mode pre-flight confirmation
	fmt.Printf("\n!!! WARNING: LIVE MODE !!!\n")
	fmt.Printf("You are about to PERMANENTLY DELETE the above resources.\n")
	fmt.Printf("\nAre you sure you want to proceed? Type 'yes' or 'no': ")

	reader := bufio.NewReader(os.Stdin)
	confirmation, _ := reader.ReadString('\n')
	confirmation = strings.TrimSpace(strings.ToLower(confirmation))

	if confirmation != "yes" {
		fmt.Printf("Aborted by user.\n")
		os.Exit(0)
	}
}

func executeCleanup(client *api.Client, tree *discovery.Tree) {
	fmt.Printf("\n[Step 0.5] Removing PAM Entitlements...\n")
	if err := execution.DeletePamResources(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}

	fmt.Printf("\n[Step 1] Removing ACM Resources...\n")
	if err := execution.DeleteACMResources(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}

	fmt.Printf("\n[Step 1.2] Removing Firewall Policy Associations...\n")
	if err := execution.RemoveFirewallAssociations(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}
	fmt.Printf("\n[Step 1.5] Deleting Firewall Policies...\n")
	if err := execution.DeleteFirewallPolicies(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}

	fmt.Printf("\n[Step 2] Removing Log Sinks...\n")
	if err := execution.RemoveSinks(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}

	fmt.Printf("\n[Step 3] Removing Tag Bindings...\n")
	if err := execution.RemoveTagBindings(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}

	fmt.Printf("\n[Step 4] Removing Liens...\n")
	if err := execution.RemoveLiens(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}

	fmt.Printf("\n[Step 5] Removing Folder Org Policies...\n")
	if err := execution.RemoveFolderOrgPolicies(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}

	fmt.Printf("\n[Step 5.5] Removing Custom Constraints...\n")
	if err := execution.DeleteCustomConstraints(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}

	fmt.Printf("\n[Step 6] Deleting Projects...\n")
	if err := execution.DeleteProjects(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}

	fmt.Printf("\n[Step 7] Deleting Folders...\n")
	if err := execution.DeleteFolders(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}

	fmt.Printf("\n[Step 8] Deleting Tag Definitions...\n")
	if err := execution.DeleteTagDefinitions(client, tree); err != nil {
		log.Printf("ERROR: %v\n", err)
	}
}

type flatIamBinding struct {
	Role   string
	Member string
}

func promptForIamCleanup(policy *api.IamPolicy, reader *bufio.Reader) *api.IamPolicy {
	var flatBindings []flatIamBinding
	for _, b := range policy.Bindings {
		for _, m := range b.Members {
			flatBindings = append(flatBindings, flatIamBinding{Role: b.Role, Member: m})
		}
	}

	if len(flatBindings) == 0 {
		fmt.Printf("No IAM bindings found.\n")
		return nil
	}

	fmt.Printf("\n--- Current IAM Bindings ---\n")
	for i, fb := range flatBindings {
		fmt.Printf("  [%2d] %s -> %s\n", i, fb.Member, fb.Role)
	}

	fmt.Printf("\nEnter comma-separated indices to REMOVE (e.g. '0,2,5'), 'all', or leave blank to cancel: ")
	input, _ := reader.ReadString('\n')
	input = strings.TrimSpace(input)

	if input == "" {
		fmt.Printf("Skipping IAM cleanup.\n")
		return nil
	}

	indicesToRemove := make(map[int]bool)
	if strings.ToLower(input) == "all" {
		for i := range flatBindings {
			indicesToRemove[i] = true
		}
	} else {
		parts := strings.Split(input, ",")
		for _, p := range parts {
			var idx int
			if _, err := fmt.Sscanf(strings.TrimSpace(p), "%d", &idx); err == nil {
				if idx >= 0 && idx < len(flatBindings) {
					indicesToRemove[idx] = true
				}
			}
		}
	}

	if len(indicesToRemove) == 0 {
		fmt.Printf("No valid indices selected. Skipping IAM cleanup.\n")
		return nil
	}

	// Rebuild the policy
	newBindingsMap := make(map[string][]string)
	for i, fb := range flatBindings {
		if !indicesToRemove[i] {
			newBindingsMap[fb.Role] = append(newBindingsMap[fb.Role], fb.Member)
		}
	}

	updatedPolicy := &api.IamPolicy{
		Version: policy.Version,
		Etag:    policy.Etag,
	}

	for role, members := range newBindingsMap {
		updatedPolicy.Bindings = append(updatedPolicy.Bindings, api.Binding{
			Role:    role,
			Members: members,
		})
	}

	return updatedPolicy
}
