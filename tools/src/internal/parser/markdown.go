package parser

import (
	"bytes"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/text"
)

var tftestRe = regexp.MustCompile(`(?m)^ *# *tftest.*?fixtures=([^\s]+)`)

func CreateTOC(readme string, skip []string) string {
	var toc []string
	md := goldmark.New()
	source := []byte(readme)
	node := md.Parser().Parse(text.NewReader(source))

	skipMap := make(map[string]bool)
	for _, s := range skip {
		skipMap[s] = true
	}

	ast.Walk(node, func(n ast.Node, entering bool) (ast.WalkStatus, error) {
		if !entering {
			return ast.WalkContinue, nil
		}

		if heading, ok := n.(*ast.Heading); ok {
			// Skip the title (<h1>)
			if heading.Level <= 1 {
				return ast.WalkContinue, nil
			}

			// Extract title text from children
			var titleBuilder strings.Builder
			for c := heading.FirstChild(); c != nil; c = c.NextSibling() {
				if textNode, ok := c.(*ast.Text); ok {
					titleBuilder.Write(textNode.Segment.Value(source))
				} else if codeSpan, ok := c.(*ast.CodeSpan); ok {
					titleBuilder.WriteString("`")
					for cc := codeSpan.FirstChild(); cc != nil; cc = cc.NextSibling() {
						if textNode, ok := cc.(*ast.Text); ok {
							titleBuilder.Write(textNode.Segment.Value(source))
						}
					}
					titleBuilder.WriteString("`")
				} else if emphasis, ok := c.(*ast.Emphasis); ok {
					if emphasis.Level == 2 {
						titleBuilder.WriteString("**")
					} else {
						titleBuilder.WriteString("*")
					}
					for cc := emphasis.FirstChild(); cc != nil; cc = cc.NextSibling() {
						if textNode, ok := cc.(*ast.Text); ok {
							titleBuilder.Write(textNode.Segment.Value(source))
						}
					}
					if emphasis.Level == 2 {
						titleBuilder.WriteString("**")
					} else {
						titleBuilder.WriteString("*")
					}
				} else {
					// Fallback for any other node (like raw HTML)
					if c.Type() == ast.TypeInline {
						titleBuilder.Write(c.Text(source))
					}
				}
			}

			title := titleBuilder.String()
			// Generate slug matching python's exact algorithm:
			// slug = title.lower().strip()
			// slug = re.sub(r'[^\w\s-]', '', slug)
			// slug = re.sub(r'[-\s]+', '-', slug)
			slug := strings.ToLower(strings.TrimSpace(title))
			slug = regexp.MustCompile(`[^\w\s-]`).ReplaceAllString(slug, "")
			slug = regexp.MustCompile(`[-\s]+`).ReplaceAllString(slug, "-")

			if skipMap[slug] {
				return ast.WalkContinue, nil
			}

			indent := strings.Repeat("  ", heading.Level-2)
			link := "- [" + title + "](#" + slug + ")"
			toc = append(toc, indent+link)
		}
		return ast.WalkContinue, nil
	})

	return strings.Join(toc, "\n")
}

func ParseFixtures(basepath string, readme string, repoRoot string) ([]string, error) {
	fixtureSet := make(map[string]bool)

	md := goldmark.New()
	source := []byte(readme)
	node := md.Parser().Parse(text.NewReader(source))

	ast.Walk(node, func(n ast.Node, entering bool) (ast.WalkStatus, error) {
		if !entering {
			return ast.WalkContinue, nil
		}
		if codeBlock, ok := n.(*ast.FencedCodeBlock); ok {
			if string(codeBlock.Language(source)) == "hcl" {
				var codeBuilder bytes.Buffer
				for i := 0; i < codeBlock.Lines().Len(); i++ {
					line := codeBlock.Lines().At(i)
					codeBuilder.Write(line.Value(source))
				}
				code := codeBuilder.String()
				matches := tftestRe.FindStringSubmatch(code)
				if len(matches) > 1 {
					fixturesAttr := matches[1]
					// fixturesAttr could be like "fixtures=foo.tf,bar.tf" or just "foo.tf,bar.tf" if it matches
					// The regex gets `(.+)` which includes everything after `fixtures=`.
					for _, fixture := range strings.Split(fixturesAttr, ",") {
						fixture = strings.TrimSpace(fixture)
						if fixture == "" {
							continue
						}
						fixtureFull := filepath.Join(repoRoot, "tests", fixture)
						if _, err := os.Stat(fixtureFull); os.IsNotExist(err) {
							// Return error mimicking python SystemExit
							return ast.WalkStop, err
						}
						absBasePath, _ := filepath.Abs(basepath)
						fixtureRel, _ := filepath.Rel(absBasePath, fixtureFull)
						fixtureSet[fixtureRel] = true
					}
				}
			}
		}
		return ast.WalkContinue, nil
	})

	var usedFixtures []string
	for k := range fixtureSet {
		usedFixtures = append(usedFixtures, k)
	}
	return usedFixtures, nil
}
