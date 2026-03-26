package parser

type SourceItem interface {
	GetLocation() (file string, line int)
}

type FileInfo struct {
	Name        string
	Description string
	Modules     []string
	Resources   []string
}

type Output struct {
	Name        string
	Description string
	Sensitive   bool
	Consumers   string
	File        string
	Line        int
}

func (o *Output) GetLocation() (file string, line int) {
	return o.File, o.Line
}

type Recipe struct {
	Path  string
	Title string
}

type Variable struct {
	Name        string
	Description string
	Type        string
	Default     string
	Required    bool
	Nullable    bool
	Source      string
	File        string
	Line        int
}

func (v *Variable) GetLocation() (file string, line int) {
	return v.File, v.Line
}

type Document struct {
	Content   string
	Files     []*FileInfo
	Variables []*Variable
	Outputs   []*Output
	Recipes   []*Recipe
}
