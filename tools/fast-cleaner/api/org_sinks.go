package api

import (
	"encoding/json"
	"fmt"
	"io"
)

type LogSink struct {
	Name        string `json:"name"`
	Destination string `json:"destination"`
	Filter      string `json:"filter"`
}

type ListSinksResponse struct {
	Sinks         []LogSink `json:"sinks"`
	NextPageToken string    `json:"nextPageToken"`
}

// ListSinks returns all log sinks for a given parent (e.g. organizations/123 or folders/456)
func (c *Client) ListSinks(parent string) ([]LogSink, error) {
	var allSinks []LogSink
	pageToken := ""

	for {
		urlStr := fmt.Sprintf("https://logging.googleapis.com/v2/%s/sinks", parent)
		if pageToken != "" {
			urlStr = fmt.Sprintf("%s?pageToken=%s", urlStr, pageToken)
		}

		resp, err := c.Get(urlStr)
		if err != nil {
			return nil, fmt.Errorf("failed to get sinks: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			// Sinks API might return 403 or 404 if logging API isn't fully enabled on the parent
			if resp.StatusCode == 403 || resp.StatusCode == 404 {
				return nil, nil
			}
			body, _ := io.ReadAll(resp.Body)
			return nil, fmt.Errorf("API error listing sinks for %s: %s - %s", parent, resp.Status, string(body))
		}

		var listResp ListSinksResponse
		if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
			return nil, fmt.Errorf("failed to decode sinks response: %w", err)
		}

		allSinks = append(allSinks, listResp.Sinks...)

		if listResp.NextPageToken == "" {
			break
		}
		pageToken = listResp.NextPageToken
	}

	return allSinks, nil
}

// DeleteSink deletes a specific sink by its name
func (c *Client) DeleteSink(parent, sinkName string) error {
	urlStr := fmt.Sprintf("https://logging.googleapis.com/v2/%s/sinks/%s", parent, sinkName)
	resp, err := c.Delete(urlStr)
	if err != nil {
		return fmt.Errorf("failed to delete sink %s: %w", sinkName, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 202 && resp.StatusCode != 204 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error deleting sink %s: %s - %s", sinkName, resp.Status, string(body))
	}
	return nil
}
