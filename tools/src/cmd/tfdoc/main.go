package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/GoogleCloudPlatform/cloud-foundation-fabric/tools/src/internal/linter"
	"github.com/GoogleCloudPlatform/cloud-foundation-fabric/tools/src/internal/parser"
	"github.com/GoogleCloudPlatform/cloud-foundation-fabric/tools/src/internal/render"
	"github.com/spf13/cobra"
)

var (
	excludeFile []string
	files       bool
	replace     bool
	showExtra   bool
	tocOnly     bool
	tocSkip     []string
	checkMode   bool
	showDiffs   bool
)

func createTfref(modulePath string, filesFlag bool, showExtraFlag bool, excludeFiles []string, readme string, repoRoot string) (*parser.Document, error) {
	opts := render.GetTfrefOpts(readme)
	
	// Override via opts
	if val, ok := opts["files"]; ok {
		filesFlag = (val != "0" && val != "false")
	}
	if val, ok := opts["show_extra"]; ok {
		showExtraFlag = (val != "0" && val != "false")
	}
	if val, ok := opts["exclude"]; ok {
		excludeFiles = append(excludeFiles, val)
	}

	absPath, err := filepath.Abs(modulePath)
	if err != nil {
		return nil, err
	}

	var modRecipes []*parser.Recipe
	if strings.HasSuffix(filepath.Dir(absPath), "/modules") {
		// Module URL calculation
		moduleName := filepath.Base(absPath)
		repoURL := "https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master" // hardcorded default
		modRecipes, err = parser.ParseRecipes(modulePath, repoURL+"/modules/"+moduleName)
		if err != nil {
			return nil, err
		}
	}

	var modFiles []*parser.FileInfo
	if filesFlag {
		modFiles, err = parser.ParseFiles(modulePath, excludeFiles)
		if err != nil {
			return nil, err
		}
	}

	modVariables, err := parser.ParseVariables(modulePath, excludeFiles)
	if err != nil {
		return nil, err
	}

	modOutputs, err := parser.ParseOutputs(modulePath, excludeFiles)
	if err != nil {
		return nil, err
	}

	modFixtures, err := parser.ParseFixtures(modulePath, readme, repoRoot)
	if err != nil {
		return nil, err
	}

	docContent := render.FormatTfref(modOutputs, modVariables, modFiles, modFixtures, modRecipes, showExtraFlag)

	return &parser.Document{
		Content:   docContent,
		Files:     modFiles,
		Variables: modVariables,
		Outputs:   modOutputs,
		Recipes:   modRecipes,
	}, nil
}

func findRepoRoot() string {
	cwd, _ := os.Getwd()
	return _findRepoRoot(cwd)
}

func _findRepoRoot(dir string) string {
	if _, err := os.Stat(filepath.Join(dir, ".git")); err == nil {
		return dir
	}
	parent := filepath.Dir(dir)
	if parent == dir {
		return dir // fallback
	}
	return _findRepoRoot(parent)
}

func runGoTfdoc(dirs []string) {
	repoRoot := findRepoRoot()
	var errors []linter.LintError
	var erroredModules []string

	for _, modPath := range dirs {
		var readmePath string
		if tocOnly && strings.HasSuffix(modPath, ".md") {
			readmePath = modPath
		} else {
			readmePath = filepath.Join(modPath, "README.md")
		}

		readmeBytes, err := os.ReadFile(readmePath)
		if err != nil {
			fmt.Printf("Error open README %s: %v\n", readmePath, err)
			os.Exit(1)
		}
		readme := string(readmeBytes)

		if !tocOnly {
			doc, err := createTfref(modPath, files, showExtra, excludeFile, readme, repoRoot)
			if err != nil {
				fmt.Printf("Error creating tfref: %v\n", err)
				os.Exit(1)
			}

			toc := parser.CreateTOC(readme, tocSkip)

			if checkMode {
				errs, err := linter.CheckDir(readmePath, readmePath, doc, doc.Content, toc)
				if err != nil {
					fmt.Printf("Error checking dir: %v\n", err)
					os.Exit(1)
				}
				moduleFailed := false
				for _, e := range errs {
					errors = append(errors, e)
					moduleFailed = true
				}

				if moduleFailed {
					erroredModules = append(erroredModules, readmePath)
					// We only print the first State for the line summary...
					fmt.Printf("[%s] %s\n", errs[0].State, readmePath)
				} else {
					fmt.Printf("[%s] %s\n", linter.StateOK, readmePath)
				}
			} else {
				readme, err = render.RenderTfref(readme, doc.Content)
				if err != nil {
					// silently ignore if mark missing?
					// Python raised SystemExit
				}
				readme = render.RenderToc(readme, toc)
				if replace {
					err = os.WriteFile(readmePath, []byte(readme), 0644)
					if err != nil {
						fmt.Printf("Error replacing README %s: %v\n", readmePath, err)
						os.Exit(1)
					}
				} else {
					fmt.Print(readme)
				}
			}
		} else {
			toc := parser.CreateTOC(readme, tocSkip)
			readme = render.RenderToc(readme, toc)
			if replace {
				err = os.WriteFile(readmePath, []byte(readme), 0644)
				if err != nil {
					fmt.Printf("Error replacing README %s: %v\n", readmePath, err)
					os.Exit(1)
				}
			} else {
				fmt.Print(readme)
			}
		}
	}

	if checkMode && len(errors) > 0 {
		fmt.Printf("\nErrored modules:\n\n")
		for _, m := range erroredModules {
			fmt.Printf("- %s\n", m)
		}
		
		if showDiffs {
			for _, e := range errors {
				fmt.Println()
				fmt.Println(e.Diff)
				fmt.Println()
			}
		}
		
		fmt.Printf("\nErrors found.\n")
		os.Exit(1)
	}
}

func main() {
	var rootCmd = &cobra.Command{
		Use:   "tfdoc [module_paths...]",
		Short: "Generate tables for Terraform root module files, outputs and variables.",
		Args:  cobra.MinimumNArgs(1),
		Run:   func(cmd *cobra.Command, args []string) { runGoTfdoc(args) },
	}

	rootCmd.Flags().StringSliceVarP(&excludeFile, "exclude-file", "x", nil, "Files to exclude")
	rootCmd.Flags().BoolVar(&files, "files", false, "Include files table")
	rootCmd.Flags().BoolVar(&replace, "replace", true, "Replace in files")
	rootCmd.Flags().BoolVar(&showExtra, "show-extra", false, "Show extra columns")
	rootCmd.Flags().BoolVar(&tocOnly, "toc-only", false, "Only update TOC")
	rootCmd.Flags().StringSliceVar(&tocSkip, "toc-skip", []string{"contents"}, "Slugs to skip in TOC")
	rootCmd.Flags().BoolVar(&checkMode, "check", false, "Run check documentation / linter mode")
	rootCmd.Flags().BoolVar(&showDiffs, "show-diffs", false, "Show diffs in check mode")

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
