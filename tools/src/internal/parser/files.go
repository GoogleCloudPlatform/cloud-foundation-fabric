package parser

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsyntax"
)

func ParseFiles(basepath string, excludeFiles []string) ([]*FileInfo, error) {
	var results []*FileInfo
	files, err := filepath.Glob(filepath.Join(basepath, "*.tf"))
	if err != nil {
		return nil, err
	}

	excludeMap := make(map[string]bool)
	for _, x := range excludeFiles {
		excludeMap[x] = true
	}

	for _, name := range files {
		info, err := os.Lstat(name)
		if err != nil || info.Mode().IsDir() || info.Mode()&os.ModeSymlink != 0 {
			continue
		}

		shortname := filepath.Base(name)
		if excludeMap[shortname] {
			continue
		}

		src, err := os.ReadFile(name)
		if err != nil {
			return nil, err
		}

		// Parse description from tags
		tags := extractFileTags(src)
		desc, ok := tags["file:description"]
		if !ok {
			if defDesc, ok2 := fileDescDefaults[shortname]; ok2 {
				desc = defDesc
			} else {
				desc = "None"
			}
		}

		// Python logic for Regex file modules and resources
		// modules = set(os.path.basename(urllib.parse.urlparse(m).path) for m in FILE_RE_MODULES.findall(body))
		// resources = set(FILE_RE_RESOURCES.findall(body))
		
		// Actually using hclsyntax to extract module and resource blocks is MUCH MORE robust, but wait,
		// checking strict regex is easier here if we just want module sources.
		modSet := make(map[string]bool)
		resSet := make(map[string]bool)

		f, _ := hclsyntax.ParseConfig(src, shortname, hcl.Pos{Line: 1, Column: 1})
		if f != nil {
			body, ok := f.Body.(*hclsyntax.Body)
			if ok {
				for _, block := range body.Blocks {
					if block.Type == "module" {
						if attr, ok := block.Body.Attributes["source"]; ok {
							sourceStr := getStringValue(attr)
							// parse basename of url
							// This mimics python's `urllib.parse.urlparse(m).path` basename
							parts := strings.Split(sourceStr, "?") // Strip query like `?ref=...`
							path := parts[0]
							parts = strings.Split(path, "//") // Strip double slash
							path = parts[len(parts)-1]
							modSet[filepath.Base(path)] = true
						}
					}
					if block.Type == "resource" && len(block.Labels) > 0 {
						resSet[block.Labels[0]] = true
					}
				}
			}
		}

		var modules []string
		for m := range modSet {
			modules = append(modules, m)
		}
		var resources []string
		for r := range resSet {
			resources = append(resources, r)
		}

		results = append(results, &FileInfo{
			Name:        shortname,
			Description: desc,
			Modules:     modules,
			Resources:   resources,
		})
	}
	return results, nil
}

func ParseRecipes(basepath string, moduleURL string) ([]*Recipe, error) {
	var recipes []*Recipe
	err := filepath.Walk(basepath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			name := filepath.Base(path)
			if strings.HasPrefix(name, "recipe-") {
				readmePath := filepath.Join(path, "README.md")
				if _, err := os.Stat(readmePath); err == nil {
					src, err := os.ReadFile(readmePath)
					if err != nil {
						return err
					}
					matches := recipeRe.FindSubmatch(src)
					if len(matches) > 1 {
						title := string(matches[1])
						recipes = append(recipes, &Recipe{
							Path:  moduleURL + "/" + name,
							Title: title,
						})
					}
				}
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return recipes, nil
}
