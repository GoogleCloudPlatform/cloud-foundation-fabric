package api

import (
	"encoding/json"
	"fmt"
	"io"
)

// CustomConstraint represents an Organization Policy Custom Constraint.
type CustomConstraint struct {
	Name string `json:"name"`
}

type ListCustomConstraintsResponse struct {
	CustomConstraints []CustomConstraint `json:"customConstraints"`
}

// ListCustomConstraints lists Custom Constraints for a given parent (e.g. organizations/123)
func (c *Client) ListCustomConstraints(parent string) ([]CustomConstraint, error) {
	reqURL := fmt.Sprintf("%s/%s/customConstraints", orgPolicyBaseURL, parent)
	resp, err := c.Get(reqURL)
	if err != nil {
		return nil, fmt.Errorf("failed to list custom constraints: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		if resp.StatusCode == 403 {
			return nil, nil // API might not be enabled or permission denied
		}
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API error listing custom constraints for %s: %s - %s", parent, resp.Status, string(body))
	}

	var listResp ListCustomConstraintsResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		return nil, fmt.Errorf("failed to decode custom constraints: %w", err)
	}

	return listResp.CustomConstraints, nil
}

// DeleteCustomConstraint deletes a specific Custom Constraint.
func (c *Client) DeleteCustomConstraint(name string) error {
	reqURL := fmt.Sprintf("%s/%s", orgPolicyBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete custom constraint %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting custom constraint %s: %s - %s", name, resp.Status, string(body))
	}

	return nil
}
