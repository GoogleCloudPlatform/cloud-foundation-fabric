package api

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"

	"golang.org/x/oauth2/google"
)

// Client wraps the authenticated http.Client and handles dry-run logic.
type Client struct {
	httpClient *http.Client
	dryRun     bool
}

// NewClient initializes a new GCP API client with Application Default Credentials.
func NewClient(ctx context.Context, dryRun bool) (*Client, error) {
	// Requesting the cloud-platform scope.
	client, err := google.DefaultClient(ctx, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		return nil, fmt.Errorf("failed to create Google default client: %v", err)
	}

	return &Client{
		httpClient: client,
		dryRun:     dryRun,
	}, nil
}

// Do executes an HTTP request, bypassing execution for mutating methods if dry-run is enabled.
func (c *Client) Do(req *http.Request) (*http.Response, error) {
	if c.dryRun && req.Method != http.MethodGet {
		fmt.Printf("[DRY-RUN] Suppressed: %s %s\n", req.Method, req.URL.String())
		// Return a generic success response to allow the simulation to continue
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(bytes.NewBufferString(`{}`)),
			Request:    req,
		}, nil
	}

	return c.httpClient.Do(req)
}

// Get is a helper for GET requests.
func (c *Client) Get(url string) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	return c.Do(req)
}

// Post is a helper for POST requests.
func (c *Client) Post(url string, contentType string, body io.Reader) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodPost, url, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", contentType)
	return c.Do(req)
}

// Delete is a helper for DELETE requests.
func (c *Client) Delete(url string) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodDelete, url, nil)
	if err != nil {
		return nil, err
	}
	return c.Do(req)
}

// Patch is a helper for PATCH requests.
func (c *Client) Patch(url string, contentType string, body io.Reader) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodPatch, url, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", contentType)
	return c.Do(req)
}
