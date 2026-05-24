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

// WaitForOperation polls a Cloud Resource Manager Long Running Operation until it is Done or an Error occurs.
func (c *Client) WaitForOperation(opName string) error {
	return c.WaitForGenericOperation(crmBaseURL, opName, 1*time.Second)
}

// WaitForGenericOperation polls any standard GCP Long Running Operation.
func (c *Client) WaitForGenericOperation(baseURL string, opName string, pollDelay time.Duration) error {
	reqURL := fmt.Sprintf("%s/%s", baseURL, opName)

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

		time.Sleep(pollDelay)
	}

	return fmt.Errorf("operation %s timed out", opName)
}
