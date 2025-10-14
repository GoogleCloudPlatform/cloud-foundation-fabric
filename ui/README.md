<!-- tftest skip -->
# GCP Landing Zone Deployment UI

This directory contains a web-based UI for deploying the GCP Landing Zone defined in this repository.

## Architecture

The UI consists of two main components:

- **`frontend/`**: A React application that provides the user interface for configuring and triggering the deployment.
- **`backend/`**: A FastAPI (Python) application that orchestrates the Terraform deployment.

## Prerequisites

- Node.js and npm
- Python 3.7+ and pip
- Terraform
- Google Cloud SDK (`gcloud`)

## Setup and Running the Application

### 1. Backend Setup

First, set up and run the backend server.

```bash
# Navigate to the backend directory
cd ui/backend

# Install Python dependencies
pip install -r requirements.txt

# Set the GCP Project ID environment variable
export GCP_PROJECT_ID="your-gcp-project-id"

# Run the bootstrap script to create the GCS bucket and Secret Manager secrets
python bootstrap.py

# Start the FastAPI server
uvicorn main:app --reload
```

The backend server will be running at `http://127.0.0.1:8000`.

### 2. Frontend Setup

In a separate terminal, set up and run the frontend application.

```bash
# Navigate to the frontend directory
cd ui/frontend

# Install Node.js dependencies
npm install

# Start the React development server
npm start
```

The frontend application will open in your browser at `http://localhost:3000`.

### 3. Proxy Setup

The frontend is configured to proxy API requests to the backend server running on port 8000. This is defined in the `package.json` file of the frontend application.

```json
"proxy": "http://127.0.0.1:8000"
```

### 4. Deployment

1. Open the application in your browser (`http://localhost:3000`).
2. In the text area, provide a JSON configuration for the deployment. The structure of the JSON should match the expected variables for each stage.
3. Click the "Deploy" button.
4. The output of the deployment will be streamed to the "Deployment Output" section in real-time.