package parser

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/zclconf/go-cty/cty"
)

var (
	tagRe            = regexp.MustCompile(`(?m)^\s*(?:#|//)\s*tfdoc:([^:]+:\S+)\s+(.*?)\s*$`)
	fileDescDefaults = map[string]string{
		"main.tf":      "Module-level locals and resources.",
		"outputs.tf":   "Module outputs.",
		"providers.tf": "Provider configurations.",
		"variables.tf": "Module variables.",
		"versions.tf":  "Version pins.",
	}
	recipeRe        = regexp.MustCompile(`(?m)^#\s*(.*?)$`)
)

func extractTagsFromTokens(tokens []hclsyntax.Token, startLine, endLine int) map[string]string {
	tags := make(map[string]string)
	for _, tok := range tokens {
		if tok.Type == hclsyntax.TokenComment {
			if tok.Range.Start.Line >= startLine && tok.Range.End.Line <= endLine {
				matches := tagRe.FindAllStringSubmatch(string(tok.Bytes), -1)
				for _, match := range matches {
					if len(match) == 3 {
						tags[match[1]] = match[2]
					}
				}
			}
		}
	}
	return tags
}

func extractFileTags(src []byte) map[string]string {
	tags := make(map[string]string)
	matches := tagRe.FindAllStringSubmatch(string(src), -1)
	for _, match := range matches {
		if len(match) == 3 {
			tags[match[1]] = match[2]
		}
	}
	return tags
}

func ParseVariables(basepath string, excludeFiles []string) ([]*Variable, error) {
	var variables []*Variable
	
	files, err := getMatchFiles(basepath, []string{"variables*tf", "local-*variables*tf"})
	if err != nil {
		return nil, err
	}

	excludeMap := make(map[string]bool)
	for _, x := range excludeFiles {
		excludeMap[x] = true
	}

	for _, name := range files {
		shortname := filepath.Base(name)
		if excludeMap[shortname] {
			continue
		}

		src, err := os.ReadFile(name)
		if err != nil {
			return nil, err
		}

		file, _ := hclsyntax.ParseConfig(src, shortname, hcl.Pos{Line: 1, Column: 1})
		if file == nil {
			continue
		}

		tokens, _ := hclsyntax.LexConfig(src, shortname, hcl.Pos{Line: 1, Column: 1})

		body, ok := file.Body.(*hclsyntax.Body)
		if !ok {
			continue
		}

		for _, block := range body.Blocks {
			if block.Type == "variable" && len(block.Labels) > 0 {
				v := &Variable{
					Name:     block.Labels[0],
					File:     shortname,
					Line:     block.TypeRange.Start.Line,
					Required: true,
					Nullable: true,
				}

				tags := extractTagsFromTokens(tokens, block.TypeRange.Start.Line, block.CloseBraceRange.End.Line)
				if val, ok := tags["variable:source"]; ok {
					v.Source = val
				}

				if attr, ok := block.Body.Attributes["description"]; ok {
					v.Description = strings.ReplaceAll(getStringValue(attr), "|", "\\|")
				}
				if attr, ok := block.Body.Attributes["type"]; ok {
					rng := attr.Expr.Range()
					rawType := string(src[rng.Start.Byte:rng.End.Byte])
					v.Type = rawType
				}
				if attr, ok := block.Body.Attributes["default"]; ok {
					rng := attr.Expr.Range()
					defStr := string(src[rng.Start.Byte:rng.End.Byte])
					v.Default = defStr
					v.Required = false
					
					// Python script does this logic: "if not required and default != 'null' and vtype == 'string'"
					// "default = f'\"{{default}}\"'" Wait! hcl natively prints strings with quotes if they were strings. 
					// Actually the token range gives exactly what it looks like (`"foo"`). So we don't need to wrap in quotes!
				}
				if attr, ok := block.Body.Attributes["nullable"]; ok {
					v.Nullable = getStringValue(attr) != "false"
				}

				variables = append(variables, v)
			}
		}
	}
	return variables, nil
}

func ParseOutputs(basepath string, excludeFiles []string) ([]*Output, error) {
	var outputs []*Output
	
	files, err := getMatchFiles(basepath, []string{"outputs*tf", "local-*outputs*tf"})
	if err != nil {
		return nil, err
	}

	excludeMap := make(map[string]bool)
	for _, x := range excludeFiles {
		excludeMap[x] = true
	}

	for _, name := range files {
		shortname := filepath.Base(name)
		if excludeMap[shortname] {
			continue
		}

		src, err := os.ReadFile(name)
		if err != nil {
			return nil, err
		}

		file, _ := hclsyntax.ParseConfig(src, shortname, hcl.Pos{Line: 1, Column: 1})
		if file == nil {
			continue
		}

		tokens, _ := hclsyntax.LexConfig(src, shortname, hcl.Pos{Line: 1, Column: 1})

		body, ok := file.Body.(*hclsyntax.Body)
		if !ok {
			continue
		}

		for _, block := range body.Blocks {
			if block.Type == "output" && len(block.Labels) > 0 {
				o := &Output{
					Name: block.Labels[0],
					File: shortname,
					Line: block.TypeRange.Start.Line,
				}

				tags := extractTagsFromTokens(tokens, block.TypeRange.Start.Line, block.CloseBraceRange.End.Line)
				if val, ok := tags["output:consumers"]; ok {
					o.Consumers = val
				}

				if attr, ok := block.Body.Attributes["description"]; ok {
					o.Description = getStringValue(attr)
				}
				if attr, ok := block.Body.Attributes["sensitive"]; ok {
					o.Sensitive = getStringValue(attr) == "true"
				}

				outputs = append(outputs, o)
			}
		}
}
	return outputs, nil
}



func getStringValue(attr *hclsyntax.Attribute) string {
	if attr == nil || attr.Expr == nil {
		return ""
	}
	val, diags := attr.Expr.Value(nil)
	if diags.HasErrors() || val.IsNull() {
		// fallback to string extraction if expression evaluation fails
		return ""
	}
	if val.Type().Equals(cty.String) {
		return val.AsString()
	}
	if val.Type().Equals(cty.Bool) {
		if val.True() {
			return "true"
		}
		return "false"
	}
	return ""
}

func getMatchFiles(basepath string, patterns []string) ([]string, error) {
	var results []string
	for _, pattern := range patterns {
		matches, err := filepath.Glob(filepath.Join(basepath, pattern))
		if err != nil {
			return nil, err
		}
		for _, m := range matches {
			if info, err := os.Lstat(m); err == nil && !info.Mode().IsDir() {
				// Don't follow symlinks
				if info.Mode()&os.ModeSymlink != 0 {
					continue
				}
				results = append(results, m)
			}
		}
	}
	return results, nil
}
