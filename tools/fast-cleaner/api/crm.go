package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/url"
)

const crmBaseURL = "https://cloudresourcemanager.googleapis.com/v3"

// Folder represents a GCP Folder.
type Folder struct {
	Name        string `json:"name"`
	Parent      string `json:"parent"`
	DisplayName string `json:"displayName"`
	State       string `json:"state"`
}

// Project represents a GCP Project.
type Project struct {
	Name        string `json:"name"`
	Parent      string `json:"parent"`
	ProjectId   string `json:"projectId"`
	DisplayName string `json:"displayName"`
	State       string `json:"state"`
}

// ListFoldersResponse represents the API response for listing folders.
type ListFoldersResponse struct {
	Folders       []Folder `json:"folders"`
	NextPageToken string   `json:"nextPageToken"`
}

// ListProjectsResponse represents the API response for listing projects.
type ListProjectsResponse struct {
	Projects      []Project `json:"projects"`
	NextPageToken string    `json:"nextPageToken"`
}

// ListFolders returns all folders under a given parent (organizations/123 or folders/456).
func (c *Client) ListFolders(parent string) ([]Folder, error) {
	var allFolders []Folder
	pageToken := ""

	for {
		query := url.Values{}
		query.Set("parent", parent)
		if pageToken != "" {
			query.Set("pageToken", pageToken)
		}

		reqURL := fmt.Sprintf("%s/folders?%s", crmBaseURL, query.Encode())
		resp, err := c.Get(reqURL)
		if err != nil {
			return nil, fmt.Errorf("failed to get folders: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			body, _ := io.ReadAll(resp.Body)
			return nil, fmt.Errorf("API error listing folders: %s - %s", resp.Status, string(body))
		}

		var listResp ListFoldersResponse
		if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
			return nil, fmt.Errorf("failed to decode folder response: %w", err)
		}

		allFolders = append(allFolders, listResp.Folders...)

		if listResp.NextPageToken == "" {
			break
		}
		pageToken = listResp.NextPageToken
	}

	return allFolders, nil
}

// ListProjects returns all projects under a given parent.
func (c *Client) ListProjects(parent string) ([]Project, error) {
	var allProjects []Project
	pageToken := ""

	for {
		query := url.Values{}
		query.Set("parent", parent)
		if pageToken != "" {
			query.Set("pageToken", pageToken)
		}

		reqURL := fmt.Sprintf("%s/projects?%s", crmBaseURL, query.Encode())
		resp, err := c.Get(reqURL)
		if err != nil {
			return nil, fmt.Errorf("failed to get projects: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			body, _ := io.ReadAll(resp.Body)
			return nil, fmt.Errorf("API error listing projects: %s - %s", resp.Status, string(body))
		}

		var listResp ListProjectsResponse
		if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
			return nil, fmt.Errorf("failed to decode project response: %w", err)
		}

		allProjects = append(allProjects, listResp.Projects...)

		if listResp.NextPageToken == "" {
			break
		}
		pageToken = listResp.NextPageToken
	}

	return allProjects, nil
}

// DeleteProject deletes a project by its name (e.g. projects/123)
func (c *Client) DeleteProject(name string) error {
	reqURL := fmt.Sprintf("%s/%s", crmBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete project %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting project %s: %s - %s", name, resp.Status, string(body))
	}

	return nil
}

// DeleteFolder deletes a folder by its name (e.g. folders/123) and waits for the operation to complete.
func (c *Client) DeleteFolder(name string) error {
	reqURL := fmt.Sprintf("%s/%s", crmBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete folder %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting folder %s: %s - %s", name, resp.Status, string(body))
	}
	
	// If it's a dry run, we don't have a real operation to wait on
	if c.dryRun {
		return nil
	}

	// Read the Operation object returned by the API
	var op Operation
	if err := json.NewDecoder(resp.Body).Decode(&op); err != nil {
		// Sometimes an empty response or 204 is returned depending on the API state,
		// in which case we just assume success rather than failing to decode.
		return nil
	}

	if op.Name != "" {
		if err := c.WaitForOperation(op.Name); err != nil {
			return fmt.Errorf("delete operation failed for folder %s: %w", name, err)
		}
	}

	return nil
}
