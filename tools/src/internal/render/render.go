package render

import (
	"fmt"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/GoogleCloudPlatform/cloud-foundation-fabric/tools/src/internal/parser"
)

var (
	escapeChars = strings.Split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,;:_-", "")
	markBegin   = "<!-- BEGIN TFDOC -->"
	markEnd     = "<!-- END TFDOC -->"
	tocBegin    = "<!-- BEGIN TOC -->"
	tocEnd      = "<!-- END TOC -->"
	optsRe      = regexp.MustCompile(`(?sm)<!-- TFDOC OPTS ((?:[a-z_]+:\S+\s*?)+) -->`)
)

func escape(s string) string {
	var sb strings.Builder
	for _, c := range s {
		char := string(c)
		isUnescaped := false
		for _, e := range escapeChars {
			if char == e {
				isUnescaped = true
				break
			}
		}
		if isUnescaped {
			sb.WriteString(char)
		} else {
			sb.WriteString(fmt.Sprintf("&#%d;", c))
		}
	}
	return sb.String()
}

func FormatTfref(outputs []*parser.Output, variables []*parser.Variable, files []*parser.FileInfo, fixtures []string, recipes []*parser.Recipe, showExtra bool) string {
	var buffer []string

	if len(recipes) > 0 {
		buffer = append(buffer, "", "## Recipes", "")
		for _, r := range recipes {
			buffer = append(buffer, fmt.Sprintf("- [%s](%s)", r.Title, r.Path))
		}
	}

	if len(files) > 0 {
		buffer = append(buffer, "", "## Files", "")
		
		sort.Slice(files, func(i, j int) bool {
			return files[i].Name < files[j].Name
		})

		numModules := 0
		numResources := 0
		for _, f := range files {
			numModules += len(f.Modules)
			numResources += len(f.Resources)
		}

		header := "| name | description |"
		if numModules > 0 {
			header += " modules |"
		}
		if numResources > 0 {
			header += " resources |"
		}
		buffer = append(buffer, header)

		sep := "|---|---|"
		if numModules > 0 {
			sep += "---|"
		}
		if numResources > 0 {
			sep += "---|"
		}
		buffer = append(buffer, sep)

		for _, f := range files {
			modStr := ""
			if len(f.Modules) > 0 {
				sort.Strings(f.Modules)
				modStr = "<code>" + strings.Join(f.Modules, "</code> · <code>") + "</code>"
			}
			resStr := ""
			if len(f.Resources) > 0 {
				sort.Strings(f.Resources)
				resStr = "<code>" + strings.Join(f.Resources, "</code> · <code>") + "</code>"
			}

			row := fmt.Sprintf("| [%s](./%s) | %s |", f.Name, f.Name, f.Description)
			if numModules > 0 {
				if modStr != "" {
					row += fmt.Sprintf(" %s |", modStr)
				} else {
					row += "  |"
				}
			}
			if numResources > 0 {
				if resStr != "" {
					row += fmt.Sprintf(" %s |", resStr)
				} else {
					row += "  |"
				}
			}
			buffer = append(buffer, row)
		}
	}

	if len(variables) > 0 {
		buffer = append(buffer, "", "## Variables", "")
		
		varsCopy := append([]*parser.Variable(nil), variables...)
		sort.Slice(varsCopy, func(i, j int) bool {
			if varsCopy[i].Required != varsCopy[j].Required {
				return varsCopy[i].Required
			}
			return varsCopy[i].Name < varsCopy[j].Name
		})

		header := "| name | description | type | required | default |"
		if showExtra {
			header += " producer |"
		}
		buffer = append(buffer, header)

		sep := "|---|---|:---:|:---:|:---:|"
		if showExtra {
			sep += ":---:|"
		}
		buffer = append(buffer, sep)

		for _, v := range varsCopy {
			reqStr := ""
			if v.Required {
				reqStr = "✓"
			}
			
			defStrFormatted := ""
			if v.Default != "" {
				defStrFormatted = fmt.Sprintf("<code>%s</code>", escape(v.Default))
			}
			
			srcStrFormatted := ""
			if v.Source != "" {
				srcStrFormatted = fmt.Sprintf("<code>%s</code>", v.Source)
			}
			
			typeStrFormatted := fmt.Sprintf("<code>%s</code>", escape(v.Type))
			
			// Handle multi-line truncation
			processMultiline := func(raw string, formatted string) string {
				if strings.Contains(raw, "\n") {
					lines := strings.Split(raw, "\n")
					title := lines[0]
					for i := 1; i < len(lines); i++ {
						line := lines[i]
						if len(line) >= 2 {
							line = line[2:]
						}
						title += "\n" + line
					}
					
					val := lines[0]
					last := strings.TrimSpace(lines[len(lines)-1])
					if len(val) >= 18 || len(last) >= 18 {
						val = "…"
					} else {
						val = fmt.Sprintf("%s…%s", val, last)
					}
					return fmt.Sprintf("<code>%s</code>", escape(val))
				}
				return formatted
			}

			if v.Default != "" {
				defStrFormatted = processMultiline(v.Default, defStrFormatted)
			}
			typeStrFormatted = processMultiline(v.Type, typeStrFormatted)

			desc := v.Description
			if desc == "" {
				desc = ""
			}

			row := fmt.Sprintf("| [%s](%s#L%d) | %s | %s | %s | %s |", v.Name, v.File, v.Line, desc, typeStrFormatted, reqStr, defStrFormatted)
			if showExtra {
				row += fmt.Sprintf(" %s |", srcStrFormatted)
			}
			buffer = append(buffer, row)
		}
	}

	if len(outputs) > 0 {
		buffer = append(buffer, "", "## Outputs", "")

		outsCopy := append([]*parser.Output(nil), outputs...)
		sort.Slice(outsCopy, func(i, j int) bool {
			return outsCopy[i].Name < outsCopy[j].Name
		})

		header := "| name | description | sensitive |"
		if showExtra {
			header += " consumers |"
		}
		buffer = append(buffer, header)

		sep := "|---|---|:---:|"
		if showExtra {
			sep += "---|"
		}
		buffer = append(buffer, sep)

		for _, o := range outsCopy {
			consStr := ""
			if o.Consumers != "" {
				fields := strings.Fields(o.Consumers)
				consStr = "<code>" + strings.Join(fields, "</code> · <code>") + "</code>"
			}
			senStr := ""
			if o.Sensitive {
				senStr = "✓"
			}

			row := fmt.Sprintf("| [%s](%s#L%d) | %s | %s |", o.Name, o.File, o.Line, o.Description, senStr)
			if showExtra {
				if consStr != "" {
					row += fmt.Sprintf(" %s |", consStr)
				} else {
					row += "  |"
				}
			}
			buffer = append(buffer, row)
		}
	}

	if len(fixtures) > 0 {
		buffer = append(buffer, "", "## Fixtures", "")
		sort.Strings(fixtures)
		for _, x := range fixtures {
			buffer = append(buffer, fmt.Sprintf("- [%s](%s)", filepath.Base(x), x))
		}
	}

	return strings.TrimSpace(strings.Join(buffer, "\n"))
}

func GetTfrefOpts(readme string) map[string]string {
	opts := make(map[string]string)
	matches := optsRe.FindStringSubmatch(readme)
	if len(matches) > 1 {
		for _, o := range strings.Fields(matches[1]) {
			parts := strings.SplitN(o, ":", 2)
			if len(parts) == 2 {
				opts[parts[0]] = parts[1]
			}
		}
	}
	return opts
}

func RenderTfref(readme string, doc string) (string, error) {
	beginIdx := strings.Index(readme, markBegin)
	endIdx := strings.Index(readme, markEnd)
	
	if beginIdx == -1 || endIdx == -1 {
		return readme, fmt.Errorf("mark not found in README")
	}

	startStr := readme[:beginIdx]
	startStr = strings.TrimRight(startStr, " \t\r\n")
	
	endStr := readme[endIdx+len(markEnd):]
	endStr = strings.TrimLeft(endStr, " \t\r\n")
	
	newReadme := startStr + "\n" + markBegin + "\n" + doc + "\n" + markEnd + "\n" + endStr
	return newReadme, nil
}

func RenderToc(readme string, toc string) string {
	beginIdx := strings.Index(readme, tocBegin)
	endIdx := strings.Index(readme, tocEnd)
	
	if beginIdx == -1 || endIdx == -1 {
		return readme
	}
	
	startStr := readme[:beginIdx]
	startStr = strings.TrimRight(startStr, " \t\r\n")
	
	endStr := readme[endIdx+len(tocEnd):]
	endStr = strings.TrimLeft(endStr, " \t\r\n")
	
	return startStr + "\n\n" + tocBegin + "\n" + toc + "\n" + tocEnd + "\n\n" + endStr
}
