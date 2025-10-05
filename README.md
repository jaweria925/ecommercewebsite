# infra-configs

Automated Bicep infra with GitHub Actions using OIDC.

## One-time bootstrap (admin)
1. Login to Azure: `az login`
2. Run: `./scripts/bootstrap-sp-fedcred.sh <SUBSCRIPTION_ID> <your-org/infra-configs> main github-bicep-sp`
3. After the script prints APP_ID, optionally add to GitHub secrets:
   - AZURE_CLIENT_ID = <appId>
   - AZURE_TENANT_ID = <tenantId> (`az account show --query tenantId -o tsv`)
   - AZURE_SUBSCRIPTION_ID = <subscriptionId>

4. Configure tenant diagnostic settings to send AuditLogs/SignInLogs to the Log Analytics workspace created by the stack (or an existing workspace).

## Deploy (via GitOps)
- Create a PR with changes to bicep files. CI runs `validate-bicep.yml`.
- Merge PR into `main`. `bicep-deploy.yml` will run using OIDC and deploy to resource group `ecommerce-rg`.

## Versioning
- Use tags `vMAJOR.MINOR.PATCH` to create releases.

## Notes
- The federated credential subject is locked to a repo+branch. Adjust if you need deploys from other branches/PRs.
- For tighter security scope the SP role to RG-level rather than subscription-level.



# APP REGISTRATION
In Azure, an app registration is the process of creating an identity for a software application within a Microsoft Entra ID (Azure Active Directory) tenant, allowing it to integrate with Microsoft Entra ID for authentication and authorization to access resources.