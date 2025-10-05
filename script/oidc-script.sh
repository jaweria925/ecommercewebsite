#!/usr/bin/env bash
set -euo pipefail

# ---------- CONFIG SECTION ----------
ORG="your-org"                 # your GitHub org
REPO="infra-configs"           # your GitHub repo name
BRANCH="main"                  # branch allowed to assume the identity
APP_NAME="github-bicep-sp"     # name for the service principal
ROLE="Contributor"             # could be custom
SCOPE="/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>"  # change accordingly
# -----------------------------------

echo "Creating service principal ${APP_NAME} ..."
az ad sp create-for-rbac \
  --name "$APP_NAME" \
  --role "$ROLE" \
  --scopes "$SCOPE" \
  --query "{appId:appId, tenant:tenant, spObjectId:id}" \
  -o json > sp.json

APP_ID=$(jq -r .appId sp.json)
TENANT_ID=$(jq -r .tenant sp.json)
echo "App ID: $APP_ID"
echo "Tenant ID: $TENANT_ID"

echo "Creating federated credential for GitHub OIDC..."
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"${ORG}-${REPO}-${BRANCH}-oidc\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${ORG}/${REPO}:ref:refs/heads/${BRANCH}\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

echo "Verifying federated credentials..."
az ad app federated-credential list --id "$APP_ID" -o table

echo "Done ✅"
echo "Store these values in your GitHub Actions secrets:"
echo "AZURE_CLIENT_ID=$APP_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"
az account show --query "{subscriptionId:id}" -o json | jq -r '.subscriptionId' | xargs -I {} echo "AZURE_SUBSCRIPTION_ID={}"
