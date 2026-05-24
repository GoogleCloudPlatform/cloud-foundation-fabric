package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/url"
	"time"
)

const acmBaseURL = "https://accesscontextmanager.googleapis.com/v1"

// AccessPolicy represents an Access Context Manager policy.
type AccessPolicy struct {
	Name   string `json:"name"`
	Parent string `json:"parent"`
	Title  string `json:"title"`
}

type ListAccessPoliciesResponse struct {
	AccessPolicies []AccessPolicy `json:"accessPolicies"`
}

// AccessLevel represents an ACM Access Level.
type AccessLevel struct {
	Name  string `json:"name"`
	Title string `json:"title"`
}

type ListAccessLevelsResponse struct {
	AccessLevels []AccessLevel `json:"accessLevels"`
}

// ServicePerimeter represents an ACM Service Perimeter.
type ServicePerimeter struct {
	Name  string `json:"name"`
	Title string `json:"title"`
}

type ListServicePerimetersResponse struct {
	ServicePerimeters []ServicePerimeter `json:"servicePerimeters"`
}

func (c *Client) WaitForAcmOperation(opName string) error {
	return c.WaitForGenericOperation(acmBaseURL, opName, 2*time.Second)
}

// ListAccessPolicies lists policies for a given parent (e.g. organizations/123 or folders/123)
func (c *Client) ListAccessPolicies(parent string) ([]AccessPolicy, error) {
	query := url.Values{}
	query.Set("parent", parent)

	reqURL := fmt.Sprintf("%s/accessPolicies?%s", acmBaseURL, query.Encode())
	resp, err := c.Get(reqURL)
	if err != nil {
		return nil, fmt.Errorf("failed to list access policies: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		if resp.StatusCode == 403 {
			return nil, nil // Ignore 403 if ACM is not enabled or no permissions
		}
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API error listing access policies for %s: %s - %s", parent, resp.Status, string(body))
	}

	var listResp ListAccessPoliciesResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		return nil, fmt.Errorf("failed to decode access policies: %w", err)
	}

	return listResp.AccessPolicies, nil
}

func (c *Client) ListServicePerimeters(policyName string) ([]ServicePerimeter, error) {
	reqURL := fmt.Sprintf("%s/%s/servicePerimeters", acmBaseURL, policyName)
	resp, err := c.Get(reqURL)
	if err != nil {
		return nil, fmt.Errorf("failed to list service perimeters: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API error listing service perimeters for %s: %s - %s", policyName, resp.Status, string(body))
	}

	var listResp ListServicePerimetersResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		return nil, fmt.Errorf("failed to decode service perimeters: %w", err)
	}

	return listResp.ServicePerimeters, nil
}

func (c *Client) ListAccessLevels(policyName string) ([]AccessLevel, error) {
	reqURL := fmt.Sprintf("%s/%s/accessLevels", acmBaseURL, policyName)
	resp, err := c.Get(reqURL)
	if err != nil {
		return nil, fmt.Errorf("failed to list access levels: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API error listing access levels for %s: %s - %s", policyName, resp.Status, string(body))
	}

	var listResp ListAccessLevelsResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		return nil, fmt.Errorf("failed to decode access levels: %w", err)
	}

	return listResp.AccessLevels, nil
}

func (c *Client) DeleteServicePerimeter(name string) error {
	reqURL := fmt.Sprintf("%s/%s", acmBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete service perimeter %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting service perimeter %s: %s - %s", name, resp.Status, string(body))
	}

	if c.dryRun {
		return nil
	}

	var op Operation
	if err := json.NewDecoder(resp.Body).Decode(&op); err != nil {
		return nil // maybe not an LRO
	}

	if op.Name != "" && !op.Done {
		if err := c.WaitForAcmOperation(op.Name); err != nil {
			return err
		}
	}
	return nil
}

func (c *Client) DeleteAccessLevel(name string) error {
	reqURL := fmt.Sprintf("%s/%s", acmBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete access level %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting access level %s: %s - %s", name, resp.Status, string(body))
	}

	if c.dryRun {
		return nil
	}

	var op Operation
	if err := json.NewDecoder(resp.Body).Decode(&op); err != nil {
		return nil
	}

	if op.Name != "" && !op.Done {
		if err := c.WaitForAcmOperation(op.Name); err != nil {
			return err
		}
	}
	return nil
}

func (c *Client) DeleteAccessPolicy(name string) error {
	reqURL := fmt.Sprintf("%s/%s", acmBaseURL, name)
	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete access policy %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting access policy %s: %s - %s", name, resp.Status, string(body))
	}

	if c.dryRun {
		return nil
	}

	var op Operation
	if err := json.NewDecoder(resp.Body).Decode(&op); err != nil {
		return nil
	}

	if op.Name != "" && !op.Done {
		if err := c.WaitForAcmOperation(op.Name); err != nil {
			return err
		}
	}
	return nil
}
