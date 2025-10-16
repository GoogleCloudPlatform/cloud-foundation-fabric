from google.adk.agents import LlmAgent
from vertexai.agent_engines import AdkApp

def get_exchange_rate(
    currency_from: str = "USD",
    currency_to: str = "EUR",
    currency_date: str = "latest",
):
    import requests
    response = requests.get(
        f"https://api.frankfurter.app/{currency_date}",
        params={"from": currency_from, "to": currency_to},
    )
    return response.json()

# Create ADK agent with tools
root_agent = LlmAgent(
    model="gemini-2.5-flash",
    instruction="You are a helpful assistant",
    name='currency_exchange_agent',
    tools=[get_exchange_rate],
)

local_agent = AdkApp(agent=root_agent)
