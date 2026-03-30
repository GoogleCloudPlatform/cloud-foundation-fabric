package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/url"
)

type TagKey struct {
	Name       string `json:"name"`
	Parent     string `json:"parent"`
	ShortName  string `json:"shortName"`
	Namespaced string `json:"namespacedName"`
}

type ListTagKeysResponse struct {
	TagKeys       []TagKey `json:"tagKeys"`
	NextPageToken string   `json:"nextPageToken"`
}

// ListTagKeys returns all tag keys for a given parent (e.g. organizations/123)
func (c *Client) ListTagKeys(parent string) ([]TagKey, error) {
	var allKeys []TagKey
	pageToken := ""

	for {
		query := url.Values{}
		query.Set("parent", parent)
		if pageToken != "" {
			query.Set("pageToken", pageToken)
		}

		reqURL := fmt.Sprintf("%s/tagKeys?%s", crmBaseURL, query.Encode())
		resp, err := c.Get(reqURL)
		if err != nil {
			return nil, fmt.Errorf("failed to get tag keys: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			body, _ := io.ReadAll(resp.Body)
			return nil, fmt.Errorf("API error listing tag keys: %s - %s", resp.Status, string(body))
		}

		var listResp ListTagKeysResponse
		if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
			return nil, fmt.Errorf("failed to decode tag keys response: %w", err)
		}

		allKeys = append(allKeys, listResp.TagKeys...)

		if listResp.NextPageToken == "" {
			break
		}
		pageToken = listResp.NextPageToken
	}

	return allKeys, nil
}

type TagValue struct {
	Name       string `json:"name"`
	Parent     string `json:"parent"`
	ShortName  string `json:"shortName"`
	Namespaced string `json:"namespacedName"`
}

type ListTagValuesResponse struct {
	TagValues     []TagValue `json:"tagValues"`
	NextPageToken string     `json:"nextPageToken"`
}

// ListTagValues returns all tag values for a given tag key (e.g. tagKeys/123)
func (c *Client) ListTagValues(parent string) ([]TagValue, error) {
	var allValues []TagValue
	pageToken := ""

	for {
		query := url.Values{}
		query.Set("parent", parent)
		if pageToken != "" {
			query.Set("pageToken", pageToken)
		}

		reqURL := fmt.Sprintf("%s/tagValues?%s", crmBaseURL, query.Encode())
		resp, err := c.Get(reqURL)
		if err != nil {
			return nil, fmt.Errorf("failed to get tag values: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			body, _ := io.ReadAll(resp.Body)
			return nil, fmt.Errorf("API error listing tag values: %s - %s", resp.Status, string(body))
		}

		var listResp ListTagValuesResponse
		if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
			return nil, fmt.Errorf("failed to decode tag values response: %w", err)
		}

		allValues = append(allValues, listResp.TagValues...)

		if listResp.NextPageToken == "" {
			break
		}
		pageToken = listResp.NextPageToken
	}

	return allValues, nil
}

// DeleteTagValue deletes a tag value. It must have no bindings.
func (c *Client) DeleteTagValue(name string) error {
	reqURL := fmt.Sprintf("%s/%s", crmBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete tag value %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting tag value %s: %s - %s", name, resp.Status, string(body))
	}

	if c.dryRun {
		return nil
	}

	if resp.StatusCode == 200 || resp.StatusCode == 202 {
		var op Operation
		if err := json.NewDecoder(resp.Body).Decode(&op); err == nil && op.Name != "" {
			if err := c.WaitForOperation(op.Name); err != nil {
				return fmt.Errorf("error waiting for tag value deletion %s: %w", name, err)
			}
		}
	}

	return nil
}

// DeleteTagKey deletes a tag key. It must have no values.
func (c *Client) DeleteTagKey(name string) error {
	reqURL := fmt.Sprintf("%s/%s", crmBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete tag key %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting tag key %s: %s - %s", name, resp.Status, string(body))
	}

	if c.dryRun {
		return nil
	}

	if resp.StatusCode == 200 || resp.StatusCode == 202 {
		var op Operation
		if err := json.NewDecoder(resp.Body).Decode(&op); err == nil && op.Name != "" {
			if err := c.WaitForOperation(op.Name); err != nil {
				return fmt.Errorf("error waiting for tag key deletion %s: %w", name, err)
			}
		}
	}

	return nil
}
