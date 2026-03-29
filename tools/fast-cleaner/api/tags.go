package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
)

// TagBinding represents a binding of a TagValue to a GCP resource.
type TagBinding struct {
	Name        string `json:"name"`
	Parent      string `json:"parent"`
	TagValue    string `json:"tagValue"`
	TagValueUid string `json:"tagValueUid"`
}

type ListTagBindingsResponse struct {
	TagBindings   []TagBinding `json:"tagBindings"`
	NextPageToken string       `json:"nextPageToken"`
}

// ListTagBindings returns all tag bindings for a given resource.
// The parent must be formatted as: //cloudresourcemanager.googleapis.com/projects/123 or //cloudresourcemanager.googleapis.com/folders/456
func (c *Client) ListTagBindings(parent string) ([]TagBinding, error) {
	var allBindings []TagBinding
	pageToken := ""

	for {
		query := url.Values{}
		query.Set("parent", parent)
		if pageToken != "" {
			query.Set("pageToken", pageToken)
		}

		reqURL := fmt.Sprintf("%s/tagBindings?%s", crmBaseURL, query.Encode())
		resp, err := c.Get(reqURL)
		if err != nil {
			return nil, fmt.Errorf("failed to get tag bindings: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			body, _ := io.ReadAll(resp.Body)
			return nil, fmt.Errorf("API error listing tag bindings: %s - %s", resp.Status, string(body))
		}

		var listResp ListTagBindingsResponse
		if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
			return nil, fmt.Errorf("failed to decode tag bindings response: %w", err)
		}

		allBindings = append(allBindings, listResp.TagBindings...)

		if listResp.NextPageToken == "" {
			break
		}
		pageToken = listResp.NextPageToken
	}

	return allBindings, nil
}

// DeleteTagBinding deletes a specific tag binding by its name (e.g., tagBindings/123).
func (c *Client) DeleteTagBinding(name string) error {
	// The name comes back from ListTagBindings as:
	// tagBindings/%2F%2Fcloudresourcemanager.googleapis.com%2Ffolders%2F123/tagValues/456
	// We must ensure the %2F%2F part is NOT unescaped by the HTTP client before it reaches GCP.
	
	reqURL := fmt.Sprintf("%s/%s", crmBaseURL, name)
	
	req, err := http.NewRequest(http.MethodDelete, reqURL, nil)
	if err != nil {
		return err
	}
	
	// Force the Opaque URL directly on the request object so the Go HTTP client 
	// doesn't unescape the %2F before sending it over the wire.
	req.URL.Opaque = fmt.Sprintf("//cloudresourcemanager.googleapis.com/v3/%s", name)
	
	resp, err := c.Do(req)
	if err != nil {
		return fmt.Errorf("failed to delete tag binding %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting tag binding %s: %s - %s", name, resp.Status, string(body))
	}

	return nil
}
