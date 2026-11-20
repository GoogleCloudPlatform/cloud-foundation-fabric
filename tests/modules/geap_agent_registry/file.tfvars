project_id = "project-id"
location   = "europe-west8"
services = {
  weather-mcp = {
    display_name = "Weather MCP server"
    type         = "mcp_server"
    content      = "data/weather-mcp-tools.json"
    url          = "https://weather-mcp-123456789.europe-west8.run.app/mcp"
    protocol     = "JSONRPC"
  }
}
