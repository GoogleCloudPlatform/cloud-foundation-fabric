import os
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Dict, Any

from terraform_runner import run_terraform

app = FastAPI()

class DeployRequest(BaseModel):
    config: Dict[str, Any]

from fastapi.middleware.cors import CORSMiddleware
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    fast_stages_path: str = "../../fast/stages"

settings = Settings()

# In a real app, this would be more sophisticated,
# likely discovered by reading the file structure.
STAGES_ORDER = [
    "0-org-setup",
    "1-resman",
    "2-networking",
    "3-project-factory",
    # Add other stages as needed
]

@app.post("/deploy")
async def deploy(deploy_request: DeployRequest):
    """
    Receives configuration and orchestrates the deployment of all stages.
    Streams back the output of the terraform commands.
    """
    async def deployment_generator():
        for stage in STAGES_ORDER:
            stage_path = os.path.abspath(os.path.join(settings.fast_stages_path, stage))
            if not os.path.isdir(stage_path):
                yield f"Stage directory not found: {stage_path}. Skipping.\n"
                continue

            yield f"--- Starting stage: {stage} ---\n"
            try:
                # Extract variables relevant to the current stage
                # This is a simplification. A real implementation would need
                # a more robust way to map frontend config to stage variables.
                stage_vars = deploy_request.config.get(stage, {})

                for line in run_terraform(stage_path, stage_vars):
                    yield line
                yield f"--- Stage {stage} completed successfully ---\n"
            except Exception as e:
                error_message = f"--- Error in stage {stage}: {str(e)} ---\n"
                yield error_message
                # Stop deployment on failure
                return

    return StreamingResponse(deployment_generator(), media_type="text/plain")

@app.get("/")
def read_root():
    return {"message": "GCP Landing Zone Deployment API"}