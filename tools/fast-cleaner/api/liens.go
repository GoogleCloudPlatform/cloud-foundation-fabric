package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/url"
)

// Lien represents a restriction on a GCP resource.
type Lien struct {
	Name         string   `json:"name"`
	Parent       string   `json:"parent"`
	Reason       string   `json:"reason"`
	Origin       string   `json:"origin"`
	Restrictions []string `json:"restrictions"`
}

type ListLiensResponse struct {
	Liens         []Lien `json:"liens"`
	NextPageToken string `json:"nextPageToken"`
}

// ListLiens returns all liens for a given parent resource.
// For projects, parent should be formatted as: projects/123456789
func (c *Client) ListLiens(parent string) ([]Lien, error) {
	var allLiens []Lien
	pageToken := ""

	for {
		query := url.Values{}
		query.Set("parent", parent)
		if pageToken != "" {
			query.Set("pageToken", pageToken)
		}

		reqURL := fmt.Sprintf("%s/liens?%s", crmBaseURL, query.Encode())
		resp, err := c.Get(reqURL)
		if err != nil {
			return nil, fmt.Errorf("failed to get liens: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			body, _ := io.ReadAll(resp.Body)
			return nil, fmt.Errorf("API error listing liens: %s - %s", resp.Status, string(body))
		}

		var listResp ListLiensResponse
		if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
			return nil, fmt.Errorf("failed to decode liens response: %w", err)
		}

		allLiens = append(allLiens, listResp.Liens...)

		if listResp.NextPageToken == "" {
			break
		}
		pageToken = listResp.NextPageToken
	}

	return allLiens, nil
}

// DeleteLien deletes a specific lien by its name (e.g., liens/1234abcd).
func (c *Client) DeleteLien(name string) error {
	reqURL := fmt.Sprintf("%s/%s", crmBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete lien %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting lien %s: %s - %s", name, resp.Status, string(body))
	}

	return nil
}
