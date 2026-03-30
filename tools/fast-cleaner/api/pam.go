package api

import (
	"encoding/json"
	"fmt"
	"io"
	"time"
)

const pamBaseURL = "https://privilegedaccessmanager.googleapis.com/v1"

// PamEntitlement represents a Privileged Access Manager entitlement.
type PamEntitlement struct {
	Name  string `json:"name"`
	State string `json:"state"`
}

type ListPamEntitlementsResponse struct {
	Entitlements []PamEntitlement `json:"entitlements"`
}

// ListPamEntitlements lists PAM entitlements for a given parent (e.g. organizations/123/locations/global)
func (c *Client) ListPamEntitlements(parent string) ([]PamEntitlement, error) {
	reqURL := fmt.Sprintf("%s/%s/locations/global/entitlements", pamBaseURL, parent)
	resp, err := c.Get(reqURL)
	if err != nil {
		return nil, fmt.Errorf("failed to list PAM entitlements: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		if resp.StatusCode == 403 {
			return nil, nil // API might not be enabled or permission denied
		}
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API error listing PAM entitlements for %s: %s - %s", parent, resp.Status, string(body))
	}

	var listResp ListPamEntitlementsResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		return nil, fmt.Errorf("failed to decode PAM entitlements: %w", err)
	}

	return listResp.Entitlements, nil
}

// DeletePamEntitlement deletes a specific PAM entitlement.
func (c *Client) DeletePamEntitlement(name string) error {
	reqURL := fmt.Sprintf("%s/%s", pamBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete PAM entitlement %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting PAM entitlement %s: %s - %s", name, resp.Status, string(body))
	}

	if c.dryRun {
		return nil
	}

	var op Operation
	if err := json.NewDecoder(resp.Body).Decode(&op); err != nil {
		return nil // Maybe not an LRO or empty response
	}

	if op.Name != "" && !op.Done {
		if err := c.WaitForPamOperation(op.Name); err != nil {
			return err
		}
	}

	return nil
}

func (c *Client) WaitForPamOperation(opName string) error {
	reqURL := fmt.Sprintf("%s/%s", pamBaseURL, opName)

	for i := 0; i < 30; i++ {
		resp, err := c.Get(reqURL)
		if err != nil {
			return fmt.Errorf("failed to poll PAM operation %s: %w", opName, err)
		}

		if resp.StatusCode != 200 {
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			return fmt.Errorf("API error polling PAM operation %s: %s - %s", opName, resp.Status, string(body))
		}

		var op Operation
		if err := json.NewDecoder(resp.Body).Decode(&op); err != nil {
			resp.Body.Close()
			return fmt.Errorf("failed to decode PAM operation %s: %w", opName, err)
		}
		resp.Body.Close()

		if op.Done {
			if op.Error != nil {
				return fmt.Errorf("PAM operation failed with code %d: %s", op.Error.Code, op.Error.Message)
			}
			return nil
		}

		time.Sleep(2 * time.Second)
	}

	return fmt.Errorf("PAM operation %s timed out", opName)
}
