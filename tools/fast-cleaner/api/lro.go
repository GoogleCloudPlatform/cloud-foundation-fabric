package api

import (
	"encoding/json"
	"fmt"
	"io"
	"time"
)

type Operation struct {
	Name  string `json:"name"`
	Done  bool   `json:"done"`
	Error *struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
}

// WaitForOperation polls a GCP Long Running Operation until it is Done or an Error occurs.
func (c *Client) WaitForOperation(opName string) error {
	// opName comes back from the API as e.g. "operations/rm.12345"
	// We need to query https://cloudresourcemanager.googleapis.com/v3/operations/rm.12345
	reqURL := fmt.Sprintf("%s/%s", crmBaseURL, opName)

	for i := 0; i < 30; i++ { // wait up to 30 seconds
		resp, err := c.Get(reqURL)
		if err != nil {
			return fmt.Errorf("failed to poll operation %s: %w", opName, err)
		}

		if resp.StatusCode != 200 {
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			return fmt.Errorf("API error polling operation %s: %s - %s", opName, resp.Status, string(body))
		}

		var op Operation
		if err := json.NewDecoder(resp.Body).Decode(&op); err != nil {
			resp.Body.Close()
			return fmt.Errorf("failed to decode operation %s: %w", opName, err)
		}
		resp.Body.Close()

		if op.Done {
			if op.Error != nil {
				return fmt.Errorf("operation failed with code %d: %s", op.Error.Code, op.Error.Message)
			}
			return nil
		}

		time.Sleep(1 * time.Second)
	}

	return fmt.Errorf("operation %s timed out", opName)
}
