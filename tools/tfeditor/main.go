/*
  Copyright 2022 Google LLC

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  This tool updates in-place versions.tf files to change module_name parameter
  on an automated basis. In retains all existing comments and structures.
*/
package main

import (
	"bytes"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"text/template"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclwrite"
	"github.com/zclconf/go-cty/cty"
)

type Provider struct {
	Source  string
	Version string
}

func main() {
	var path string
	var pattern string
	var moduleName string
	var terraformVersion string
	var providerVersions string
	var updateProviderVersions bool = false
	var updateTerraformVersion bool = false
	var updateModuleName bool = false

	flag.StringVar(&path, "path", "./", "Path to search for file pattern (default ./")
	flag.StringVar(&pattern, "pattern", "versions.tf", "Pattern to search (default versions.tf)")
	flag.StringVar(&moduleName, "module-name", "", "module_name attribute for provider_meta (can be templated with {{ .Module }})")
	flag.StringVar(&providerVersions, "provider-versions", "", "set provider versions (usage: hashicorp/google>= 4.0.0,hashicorp/googlegoogle-beta== 4.0.0)")
	flag.StringVar(&terraformVersion, "terraform-version", "", "Update terraform required_version")
	flag.Parse()

	if !strings.HasSuffix(path, "/") {
		path = fmt.Sprintf("%s/", path)
	}

	if moduleName != "" {
		updateModuleName = true
		log.Printf("Updating module_name to: %s", moduleName)
	}

	if terraformVersion != "" {
		updateTerraformVersion = true
		log.Printf("Updating Terraform version to: %s", terraformVersion)
	}

	providerVersionsMap := map[string]Provider{}
	if providerVersions != "" {
		for _, v := range strings.Split(providerVersions, ",") {
			re := regexp.MustCompile("([a-zA-Z_/-]+)(.+)")
			split := re.FindAllStringSubmatch(v, -1)
			for _, splitN := range split {
				providerKey := filepath.Base(splitN[1])
				providerVersionsMap[providerKey] = Provider{Source: splitN[1], Version: splitN[2]}
				log.Printf("Updating provider %s to: %s %s", providerKey, providerVersionsMap[providerKey].Source, providerVersionsMap[providerKey].Version)
			}
		}
		updateProviderVersions = true
	}

	log.Printf("Looking for files (%s) in: %s", pattern, path)

	var foundFiles []string
	err := filepath.Walk(path, func(file string, f os.FileInfo, err error) error {
		if isMatch, _ := filepath.Match(pattern, filepath.Base(file)); isMatch {
			foundFiles = append(foundFiles, file)
		}
		return nil
	})
	log.Printf("Found %d files.", len(foundFiles))

	for _, foundFile := range foundFiles {
		fileBytes, fErr := ioutil.ReadFile(foundFile)
		if fErr != nil {
			panic(fErr)
		}
		fileBasename := filepath.Base(foundFile)

		hclFile, diag := hclwrite.ParseConfig(fileBytes, fileBasename, hcl.Pos{})
		if diag == nil {
			hclBody := hclFile.Body()
			for _, block := range hclBody.Blocks() {
				if block.Type() == "terraform" {
					if updateTerraformVersion {
						for k, _ := range block.Body().Attributes() {
							if k == "required_version" {
								block.Body().SetAttributeValue("required_version", cty.StringVal(terraformVersion))
							}
						}
					}

					hasProviderMetaForGoogle := false
					hasProviderMetaForGoogleBeta := false

					// Expand template
					tmpl, tErr := template.New("modulename").Parse(moduleName)
					if tErr != nil {
						panic(tErr)
					}
					expandedBuffer := new(bytes.Buffer)
					tErr = tmpl.Execute(expandedBuffer, map[string]string{
						"Module": filepath.Base(filepath.Dir(foundFile)),
					})
					if tErr != nil {
						panic(tErr)
					}
					expandedModuleName := expandedBuffer.String()

					for _, tfBlock := range block.Body().Blocks() {
						if tfBlock.Type() == "required_providers" && updateProviderVersions {
							for k, _ := range tfBlock.Body().Attributes() {
								if provider, ok := providerVersionsMap[k]; ok {
									tfBlock.Body().SetAttributeValue(k, cty.ObjectVal(map[string]cty.Value{
										"source":  cty.StringVal(provider.Source),
										"version": cty.StringVal(provider.Version),
									}))
								}
							}
						}

						if tfBlock.Type() == "provider_meta" && updateModuleName {
							labels := tfBlock.Labels()
							if len(labels) > 0 {
								if labels[0] == "google" {
									hasProviderMetaForGoogle = true
									tfBlock.Body().SetAttributeValue("module_name", cty.StringVal(expandedModuleName))
								}
								if labels[0] == "google-beta" {
									hasProviderMetaForGoogleBeta = true
									tfBlock.Body().SetAttributeValue("module_name", cty.StringVal(expandedModuleName))
								}
							}
						}
					}

					if updateModuleName {
						if !hasProviderMetaForGoogle {
							providerMetaGoogleBlock := hclwrite.NewBlock("provider_meta", []string{"google"})
							providerMetaGoogleBlock.Body().SetAttributeValue("module_name", cty.StringVal(expandedModuleName))
							block.Body().AppendBlock(providerMetaGoogleBlock)
						}
						if !hasProviderMetaForGoogleBeta {
							providerMetaGoogleBlock := hclwrite.NewBlock("provider_meta", []string{"google-beta"})
							providerMetaGoogleBlock.Body().SetAttributeValue("module_name", cty.StringVal(expandedModuleName))
							block.Body().AppendBlock(providerMetaGoogleBlock)
						}
					}
				}
			}

			log.Printf("Updating: %s", foundFile)
			info, sErr := os.Stat(foundFile)
			if sErr != nil {
				panic(sErr)
			}
			tempFilePath := fmt.Sprintf("%s.tmp", foundFile)
			wErr := os.WriteFile(tempFilePath, hclFile.Bytes(), info.Mode())
			if wErr != nil {
				panic(wErr)
			}
			os.Rename(tempFilePath, foundFile)
		} else {
			panic(diag)
		}
	}

	if err != nil {
		panic(err)
	}
	log.Printf("All done.")
}
