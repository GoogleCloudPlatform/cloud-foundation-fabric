package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/url"
)

const orgPolicyBaseURL = "https://orgpolicy.googleapis.com/v2"

// Policy represents an Organization Policy applied to a resource.
type Policy struct {
	Name string `json:"name"`
}

type ListPoliciesResponse struct {
	Policies      []Policy `json:"policies"`
	NextPageToken string   `json:"nextPageToken"`
}

// ListOrgPolicies returns all custom organization policies attached to a target (e.g. folders/12345)
func (c *Client) ListOrgPolicies(parent string) ([]Policy, error) {
	var allPolicies []Policy
	pageToken := ""

	for {
		query := url.Values{}
		if pageToken != "" {
			query.Set("pageToken", pageToken)
		}

		reqURL := fmt.Sprintf("%s/%s/policies?%s", orgPolicyBaseURL, parent, query.Encode())
		resp, err := c.Get(reqURL)
		if err != nil {
			return nil, fmt.Errorf("failed to get org policies: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			// Permissions or missing APIs might return 403. Let's not fail the whole process if orgpolicy API isn't enabled.
			if resp.StatusCode == 403 {
				return nil, nil
			}
			body, _ := io.ReadAll(resp.Body)
			return nil, fmt.Errorf("API error listing org policies for %s: %s - %s", parent, resp.Status, string(body))
		}

		var listResp ListPoliciesResponse
		if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
			return nil, fmt.Errorf("failed to decode org policies response: %w", err)
		}

		allPolicies = append(allPolicies, listResp.Policies...)

		if listResp.NextPageToken == "" {
			break
		}
		pageToken = listResp.NextPageToken
	}

	return allPolicies, nil
}

// DeleteOrgPolicy deletes an organization policy (reverts it to inherited state).
func (c *Client) DeleteOrgPolicy(name string) error {
	reqURL := fmt.Sprintf("%s/%s", orgPolicyBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete org policy %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting org policy %s: %s - %s", name, resp.Status, string(body))
	}
	return nil
}
