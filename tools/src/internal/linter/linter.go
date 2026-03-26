package linter

import (
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/GoogleCloudPlatform/cloud-foundation-fabric/tools/src/internal/parser"
	"github.com/sergi/go-diff/diffmatchpatch"
)

type State string

const (
	StateOK                      State = "✓ "
	StateFailStaleReadme         State = "✗R"
	StateFailStaleToc            State = "✗T"
	StateFailUnsortedVars        State = "SV"
	StateFailUnsortedOutputs     State = "SO"
	StateFailVariablePeriod      State = ".V"
	StateFailOutputPeriod        State = ".O"
	StateFailVariableDescription State = "DV"
	StateFailOutputDescription   State = "DO"
	StateFailMissingTypes        State = "TY"
)

type LintError struct {
	State State
	Diff  string
}

func extractMarker(readme string, begin string, end string) string {
	bIdx := strings.Index(readme, begin)
	eIdx := strings.Index(readme, end)
	if bIdx == -1 || eIdx == -1 {
		return ""
	}
	content := readme[bIdx+len(begin):eIdx]
	return strings.TrimSpace(content)
}

func checkStale(readme string, newContent string, begin string, end string) (bool, string) {
	currentContent := extractMarker(readme, begin, end)
	if currentContent == "" {
		return false, ""
	}
	
	newContent = strings.TrimSpace(newContent)
	if currentContent != newContent {
		dmp := diffmatchpatch.New()
		diffs := dmp.DiffMain(currentContent, newContent, false)
		return true, dmp.DiffPrettyText(diffs)
	}
	return false, ""
}

func CheckDir(readmePath string, readmeRel string, doc *parser.Document, newDocContent string, newTocContent string) ([]LintError, error) {
	var errors []LintError

	readmeBytes, _ := os.ReadFile(readmePath)
	readme := string(readmeBytes)

	// Check stale README
	isStaleDoc, docDiff := checkStale(readme, newDocContent, "<!-- BEGIN TFDOC -->", "<!-- END TFDOC -->")
	if isStaleDoc {
		errors = append(errors, LintError{
			State: StateFailStaleReadme,
			Diff:  fmt.Sprintf("----- %s diff -----\n%s", readmeRel, docDiff),
		})
	}

	// Check stale TOC
	isStaleToc, tocDiff := checkStale(readme, newTocContent, "<!-- BEGIN TOC -->", "<!-- END TOC -->")
	if isStaleToc {
		errors = append(errors, LintError{
			State: StateFailStaleToc,
			Diff:  fmt.Sprintf("----- %s diff -----\n%s", readmeRel, tocDiff),
		})
	}

	// Missing variable description
	var emptyVarDesc []string
	for _, v := range doc.Variables {
		if v.Description == "" {
			emptyVarDesc = append(emptyVarDesc, v.Name)
		}
	}
	if len(emptyVarDesc) > 0 {
		errors = append(errors, LintError{
			State: StateFailVariableDescription,
			Diff:  fmt.Sprintf("----- %s variables missing description -----\n%s", readmeRel, strings.Join(emptyVarDesc, ", ")),
		})
	}

	// Missing output description
	var emptyOutDesc []string
	for _, o := range doc.Outputs {
		if o.Description == "" {
			emptyOutDesc = append(emptyOutDesc, o.Name)
		}
	}
	if len(emptyOutDesc) > 0 {
		errors = append(errors, LintError{
			State: StateFailOutputDescription,
			Diff:  fmt.Sprintf("----- %s outputs missing description -----\n%s", readmeRel, strings.Join(emptyOutDesc, ", ")),
		})
	}

	// Unsorted variables
	var varNames []string
	for _, v := range doc.Variables {
		if strings.HasSuffix(v.File, "variables.tf") {
			varNames = append(varNames, v.Name)
		}
	}
	sortedVarNames := append([]string(nil), varNames...)
	sort.Strings(sortedVarNames)
	
	if len(varNames) > 0 {
		isSorted := true
		for i := range varNames {
			if varNames[i] != sortedVarNames[i] {
				isSorted = false
				break
			}
		}
		if !isSorted {
			errors = append(errors, LintError{
				State: StateFailUnsortedVars,
				Diff:  fmt.Sprintf("----- %s variables -----\nvariables should be in this order:\n%s", readmeRel, strings.Join(sortedVarNames, ", ")),
			})
		}
	}

	// Unsorted outputs
	var outNames []string
	for _, o := range doc.Outputs {
		if strings.HasSuffix(o.File, "outputs.tf") {
			outNames = append(outNames, o.Name)
		}
	}
	sortedOutNames := append([]string(nil), outNames...)
	sort.Strings(sortedOutNames)
	
	if len(outNames) > 0 {
		isSorted := true
		for i := range outNames {
			if outNames[i] != sortedOutNames[i] {
				isSorted = false
				break
			}
		}
		if !isSorted {
			errors = append(errors, LintError{
				State: StateFailUnsortedOutputs,
				Diff:  fmt.Sprintf("----- %s outputs -----\noutputs should be in this order:\n%s", readmeRel, strings.Join(sortedOutNames, ", ")),
			})
		}
	}

	// Variable description period
	var noPeriodVar []string
	for _, v := range doc.Variables {
		if v.Description != "" && !strings.HasSuffix(strings.TrimSpace(v.Description), ".") {
			noPeriodVar = append(noPeriodVar, v.Name)
		}
	}
	if len(noPeriodVar) > 0 {
		errors = append(errors, LintError{
			State: StateFailVariablePeriod,
			Diff:  fmt.Sprintf("----- %s variable descriptions missing ending period -----\n%s", readmeRel, strings.Join(noPeriodVar, ", ")),
		})
	}

	// Output description period
	var noPeriodOut []string
	for _, o := range doc.Outputs {
		if o.Description != "" && !strings.HasSuffix(strings.TrimSpace(o.Description), ".") {
			noPeriodOut = append(noPeriodOut, o.Name)
		}
	}
	if len(noPeriodOut) > 0 {
		errors = append(errors, LintError{
			State: StateFailOutputPeriod,
			Diff:  fmt.Sprintf("----- %s output descriptions missing ending period -----\n%s", readmeRel, strings.Join(noPeriodOut, ", ")),
		})
	}

	// Missing variable types
	var noType []string
	for _, v := range doc.Variables {
		if v.Type == "" {
			noType = append(noType, v.Name)
		}
	}
	if len(noType) > 0 {
		errors = append(errors, LintError{
			State: StateFailMissingTypes,
			Diff:  fmt.Sprintf("----- %s variables without types -----\n%s", readmeRel, strings.Join(noType, ", ")),
		})
	}

	return errors, nil
}
