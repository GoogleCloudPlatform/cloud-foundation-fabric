# Phase 1: Environment & Authentication

### Step 1: Environment Assessment & Initialization

1. Ask the user to clarify their target environment: **Standard GCP** or **Google Cloud Dedicated (GCD)**. **Wait for their response.**
2. Once the environment is confirmed, ask how they prefer to run commands: Should you (Gemini CLI) run them automatically, or should you output them for manual execution? **Remember this preference for the rest of the workflow. Wait for their response.**
3. *If GCD is selected*, ask the user if they are working in one of the known universes: **S3NS (France)** or **Berlin (Germany)**.
   - *If S3NS:* Pre-fill the following values:
     - Universe Web Domain: `cloud.s3nscloud.fr`
     - Universe API Domain: `s3nsapis.fr`
     - Universe Name: `s3ns`
     - Universe Prefix: `s3ns`
     - Universe Region: `u-france-east1`
   - *If Berlin:* Pre-fill the following values:
     - Universe Web Domain: `cloud.berlin-build0.goog`
     - Universe API Domain: `apis-berlin-build0.goog`
     - Universe Name: `berlin`
     - Universe Prefix: `eu0`
     - Universe Region: `u-germany-northeast1`
   - *If neither (Custom):* Gather the 5 universe-specific details manually from the user.
   - *Action:* Present the final list of the 5 universe values to the user for review. Ask for explicit confirmation and offer them the opportunity to change any of the values before proceeding.

### Step 2: Authentication

1. Ask the user if they are already authenticated with Google Cloud using the correct principal.
   - *If yes:* Run (or ask the user to run) `gcloud config list account --format="value(core.account)"` to retrieve the current authenticated principal. Show this principal to the user and explicitly ask them to confirm if this is the correct identity they want to use.
     - *If they confirm:* Proceed directly to Phase 2 (Step 3).
     - *If they do not confirm:* Proceed with the authentication steps below.
   - *If no:* Proceed with the authentication steps below.
2. *Standard GCP:* Provide or execute the command:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```
3. *GCD:* Automate or guide the user through WIF login. Ask for the workforce pool audience string first, then generate the configuration:
   ```bash
   # (Use the gathered GCD variables to fill placeholders)
   gcloud config configurations create <UNIVERSE_NAME>
   gcloud config configurations activate <UNIVERSE_NAME>
   gcloud config set universe_domain <UNIVERSE_API_DOMAIN>

   gcloud iam workforce-pools create-login-config <AUDIENCE> \
     --universe-cloud-web-domain="<UNIVERSE_WEB_DOMAIN>" \
     --universe-domain="<UNIVERSE_API_DOMAIN>" \
     --output-file="/tmp/wif-login-config-<UNIVERSE_NAME>.json" \
     --activate

   gcloud auth login --login-config=/tmp/wif-login-config-<UNIVERSE_NAME>.json --no-launch-browser
   gcloud auth application-default login --login-config=/tmp/wif-login-config-<UNIVERSE_NAME>.json
   ```
4. Explicitly ask the user to confirm they have successfully authenticated before moving to the next phase.
