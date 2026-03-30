package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/url"
)

const computeBaseURL = "https://compute.googleapis.com/compute/v1"

// FirewallPolicyAssociation represents a binding of a firewall policy to a resource.
type FirewallPolicyAssociation struct {
	Name             string `json:"name"`
	AttachmentTarget string `json:"attachmentTarget"`
	FirewallPolicyId string `json:"firewallPolicyId"`
}

type ListFirewallPolicyAssociationsResponse struct {
	Associations []FirewallPolicyAssociation `json:"associations"`
}

// ListFirewallPolicyAssociations returns all firewall policies attached to a target (e.g. folders/12345)
func (c *Client) ListFirewallPolicyAssociations(targetResource string) ([]FirewallPolicyAssociation, error) {
	query := url.Values{}
	query.Set("targetResource", targetResource)

	reqURL := fmt.Sprintf("%s/locations/global/firewallPolicies/listAssociations?%s", computeBaseURL, query.Encode())
	resp, err := c.Get(reqURL)
	if err != nil {
		return nil, fmt.Errorf("failed to get firewall policy associations: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		// Permissions or missing APIs might return 403. Let's not fail the whole process if compute API isn't enabled.
		if resp.StatusCode == 403 {
			return nil, nil
		}
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API error listing firewall policy associations for %s: %s - %s", targetResource, resp.Status, string(body))
	}

	var listResp ListFirewallPolicyAssociationsResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		return nil, fmt.Errorf("failed to decode firewall policy associations response: %w", err)
	}

	return listResp.Associations, nil
}

// RemoveFirewallPolicyAssociation removes a specific firewall policy association.
func (c *Client) RemoveFirewallPolicyAssociation(firewallPolicyId string, name string) error {
	query := url.Values{}
	query.Set("name", name)

	reqURL := fmt.Sprintf("%s/locations/global/firewallPolicies/%s/removeAssociation?%s", computeBaseURL, firewallPolicyId, query.Encode())
	
	// removeAssociation is a POST operation
	resp, err := c.Post(reqURL, "application/json", nil)
	if err != nil {
		return fmt.Errorf("failed to remove firewall policy association %s: %w", name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error removing firewall policy association %s: %s - %s", name, resp.Status, string(body))
	}

	return nil
}

// FirewallPolicy represents a hierarchical firewall policy.
type FirewallPolicy struct {
	Id        string `json:"id"`
	Name      string `json:"name"`
	ShortName string `json:"shortName"`
}

type ListFirewallPoliciesResponse struct {
	Items []FirewallPolicy `json:"items"`
}

// ListFirewallPolicies returns all firewall policies parented by a target (e.g. folders/12345)
func (c *Client) ListFirewallPolicies(parentId string) ([]FirewallPolicy, error) {
	query := url.Values{}
	query.Set("parentId", parentId)

	reqURL := fmt.Sprintf("%s/locations/global/firewallPolicies?%s", computeBaseURL, query.Encode())
	resp, err := c.Get(reqURL)
	if err != nil {
		return nil, fmt.Errorf("failed to get firewall policies: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		if resp.StatusCode == 403 {
			return nil, nil
		}
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API error listing firewall policies for %s: %s - %s", parentId, resp.Status, string(body))
	}

	var listResp ListFirewallPoliciesResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		return nil, fmt.Errorf("failed to decode firewall policies response: %w", err)
	}

	return listResp.Items, nil
}

// DeleteFirewallPolicy deletes a specific firewall policy.
func (c *Client) DeleteFirewallPolicy(policyId string) error {
	reqURL := fmt.Sprintf("%s/locations/global/firewallPolicies/%s", computeBaseURL, policyId)

	resp, err := c.Delete(reqURL)
	if err != nil {
		return fmt.Errorf("failed to delete firewall policy %s: %w", policyId, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting firewall policy %s: %s - %s", policyId, resp.Status, string(body))
	}

	return nil
}
