package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
)

type Binding struct {
	Role    string   `json:"role"`
	Members []string `json:"members"`
}

type IamPolicy struct {
	Bindings []Binding `json:"bindings"`
	Etag     string    `json:"etag"`
	Version  int       `json:"version"`
}

// GetIamPolicy retrieves the IAM policy for an organization or folder.
// Note: resource should be "organizations/123" or "folders/456"
func (c *Client) GetIamPolicy(resource string) (*IamPolicy, error) {
	reqURL := fmt.Sprintf("%s/%s:getIamPolicy", crmBaseURL, resource)
	// getIamPolicy is a POST request according to CRM v3 spec
	resp, err := c.Post(reqURL, "application/json", bytes.NewBufferString(`{}`))
	if err != nil {
		return nil, fmt.Errorf("failed to get IAM policy for %s: %w", resource, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		if resp.StatusCode == 403 {
			return nil, nil
		}
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API error getting IAM policy for %s: %s - %s", resource, resp.Status, string(body))
	}

	var policy IamPolicy
	if err := json.NewDecoder(resp.Body).Decode(&policy); err != nil {
		return nil, fmt.Errorf("failed to decode IAM policy response: %w", err)
	}

	return &policy, nil
}

// SetIamPolicy replaces the IAM policy for an organization or folder.
func (c *Client) SetIamPolicy(resource string, policy *IamPolicy) error {
	reqURL := fmt.Sprintf("%s/%s:setIamPolicy", crmBaseURL, resource)
	
	body, err := json.Marshal(map[string]interface{}{"policy": policy})
	if err != nil {
		return err
	}

	resp, err := c.Post(reqURL, "application/json", bytes.NewBuffer(body))
	if err != nil {
		return fmt.Errorf("failed to set IAM policy for %s: %w", resource, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		errBody, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error setting IAM policy for %s: %s - %s", resource, resp.Status, string(errBody))
	}

	return nil
}
