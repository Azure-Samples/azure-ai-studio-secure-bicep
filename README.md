# Secure Azure AI Studio

This collection of `Bicep` templates demonstrates how to set up an [Azure AI Studio](https://learn.microsoft.com/en-us/azure/ai-studio/what-is-ai-studio) environment in a secure way with [Azure AI Services](https://learn.microsoft.com/en-us/azure/ai-services/what-are-ai-services) and dependent resources. This example shows public internet access enabled, Microsoft-managed keys for encryption, and Microsoft-managed identity configuration for the AI hub resource.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.machinelearningservices%2Faistudio-network-restricted%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.machinelearningservices%2Faistudio-network-restricted%2Fazuredeploy.json)

## Introduction

This guide provides step-by-step instructions for setting up Azure AI Studio using [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) templates. By following these steps, you can automate the provisioning process and ensure all necessary resources are properly configured.

## Resources

The Bicep modules deploy the following resources:

- Azure AI Hub
- Azure AI Project
- Azure AI Services
- Azure OpenAI Service deployments/models:
  - `gpt-4o`
  - `text-embedding-ada-002`
- Azure Container Registry (Optional)
- Azure Key Vault
- Azure Monitor Log Analytics
- Azure Application Insights
- Azure Storage Account

> [!NOTE]
> You can select a different version of the GPT model by specifying the `openAiDeployments` parameter in the `main.bicepparam` parameters file. For details on the models available in various Azure regions, please refer to the [Azure OpenAI Service models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models) documentation.

> [!NOTE]
> The default deployment includes an Azure Container Registry resource. However, if you wish not to deploy an Azure Container Registry, you can simply set the `acrEnabled` parameter to `false`.

## Deployment

You can deploy the Bicep modules in the [`bicep`](./bicep/) folder using the [`deploy.sh` Bash script](./bicep/deploy.sh) in the same folder. Specify a value for the following parameters in the [`main.bicepparam` parameters file](./bicep/main.bicepparam) before deploying the Bicep modules.

| Name                                      | Type   | Allowed Values                                             | Description                                                                                                                                             |
| ----------------------------------------- | ------ | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| prefix                                    | string | N/A                                                        | Specifies the name prefix for all the Azure resources.                                                                                                  |
| suffix                                    | string | N/A                                                        | Specifies the name suffix for all the Azure resources.                                                                                                  |
| location                                  | string | N/A                                                        | Specifies the location for all the Azure resources.                                                                                                     |
| hubName                                   | string | N/A                                                        | Specifies the name Azure AI Hub workspace.                                                                                                              |
| hubFriendlyName                           | string | N/A                                                        | Specifies the friendly name of the Azure AI Hub workspace.                                                                                              |
| hubDescription                            | string | N/A                                                        | Specifies the description for the Azure AI Hub workspace displayed in Azure AI Studio.                                                                  |
| hubIsolationMode                          | string | AllowInternetOutbound, AllowOnlyApprovedOutbound, Disabled | Specifies the isolation mode for the managed network of the Azure AI Hub workspace.                                                                     |
| hubPublicNetworkAccess                    | string | N/A                                                        | Specifies the public network access for the Azure AI Hub workspace.                                                                                     |
| connectionAuthType                        | string | ApiKey, AAD, ManagedIdentity, None                         | Specifies the authentication method for the OpenAI Service connection.                                                                                  |
| customConnectionName                      | string | N/A                                                        | Specifies the name for the custom connection.                                                                                                           |
| projectName                               | string | N/A                                                        | Specifies the name Azure AI Project workspace.                                                                                                          |
| projectFriendlyName                       | string | N/A                                                        | Specifies the friendly name of the Azure AI Project workspace.                                                                                          |
| projectPublicNetworkAccess                | string | N/A                                                        | Specifies the public network access for the Azure AI Project workspace.                                                                                 |
| logAnalyticsName                          | string | N/A                                                        | Specifies the name of the Azure Log Analytics resource.                                                                                                 |
| logAnalyticsSku                           | string | Free, Standalone, PerNode, PerGB2018                       | Specifies the service tier of the workspace.                                                                                                            |
| logAnalyticsRetentionInDays               | int    | N/A                                                        | Specifies the workspace data retention in days. -1 means Unlimited retention for the Unlimited Sku. 730 days is the maximum allowed for all other Skus. |
| applicationInsightsName                   | string | N/A                                                        | Specifies the name of the Azure Application Insights resource.                                                                                          |
| aiServicesName                            | string | N/A                                                        | Specifies the name of the Azure AI Services resource.                                                                                                   |
| aiServicesSku                             | object | N/A                                                        | Specifies the resource model definition representing SKU.                                                                                               |
| aiServicesIdentity                        | object | N/A                                                        | Specifies the identity of the Azure AI Services resource.                                                                                               |
| aiServicesCustomSubDomainName             | string | N/A                                                        | Specifies an optional subdomain name used for token-based authentication.                                                                               |
| aiServicesDisableLocalAuth                | bool   | N/A                                                        | Specifies whether to disable local authentication via API key.                                                                                          |
| aiServicesPublicNetworkAccess             | string | Enabled, Disabled                                          | Specifies whether public endpoint access is allowed for this account.                                                                                   |
| openAiDeployments                         | array  | N/A                                                        | Specifies the OpenAI deployments to create.                                                                                                             |
| keyVaultName                              | string | N/A                                                        | Specifies the name of the Azure Key Vault resource.                                                                                                     |
| keyVaultNetworkAclsDefaultAction          | string | Allow, Deny                                                | Specifies the default action of allow or deny when no other rules match for the Azure Key Vault resource.                                               |
| keyVaultEnabledForDeployment              | bool   | N/A                                                        | Specifies whether the Azure Key Vault resource is enabled for deployments.                                                                              |
| keyVaultEnabledForDiskEncryption          | bool   | N/A                                                        | Specifies whether the Azure Key Vault resource is enabled for disk encryption.                                                                          |
| keyVaultEnabledForTemplateDeployment      | bool   | N/A                                                        | Specifies whether the Azure Key Vault resource is enabled for template deployment.                                                                      |
| keyVaultEnableSoftDelete                  | bool   | N/A                                                        | Specifies whether soft delete is enabled for the Azure Key Vault resource.                                                                              |
| keyVaultEnablePurgeProtection             | bool   | N/A                                                        | Specifies whether purge protection is enabled for the Azure Key Vault resource.                                                                         |
| keyVaultEnableRbacAuthorization           | bool   | N/A                                                        | Specifies whether to enable RBAC authorization for the Azure Key Vault resource.                                                                        |
| keyVaultSoftDeleteRetentionInDays         | int    | N/A                                                        | Specifies the soft delete retention in days.                                                                                                            |
| acrName                                   | string | N/A                                                        | Specifies the name of the Azure Container Registry resource.                                                                                            |
| acrAdminUserEnabled                       | bool   | N/A                                                        | Enable admin user that have push/pull permission to the registry.                                                                                       |
| acrSku                                    | string | Basic, Standard, Premium                                   | Tier of your Azure Container Registry.                                                                                                                  |
| storageAccountName                        | string | N/A                                                        | Specifies the name of the Azure Storage Account resource.                                                                                               |
| storageAccountAccessTier                  | string | N/A                                                        | Specifies the access tier of the Azure Storage Account resource (default: Hot).                                                                         |
| storageAccountAllowBlobPublicAccess       | bool   | N/A                                                        | Specifies whether the Azure Storage Account resource allows public access to blobs (default: false).                                                    |
| storageAccountAllowSharedKeyAccess        | bool   | N/A                                                        | Specifies whether the Azure Storage Account resource allows shared key access (default: true).                                                          |
| storageAccountAllowCrossTenantReplication | bool   | N/A                                                        | Specifies whether the Azure Storage Account resource allows cross-tenant replication (default: false).                                                  |
| storageAccountMinimumTlsVersion           | string | N/A                                                        | Specifies the minimum TLS version to be permitted on requests to the Azure Storage Account resource (default: TLS1_2).                                  |
| storageAccountANetworkAclsDefaultAction   | string | Allow, Deny                                                | Default action of allow or deny when no other rules match.                                                                                              |
| storageAccountSupportsHttpsTrafficOnly    | bool   | N/A                                                        | Specifies whether the Azure Storage Account resource should only support HTTPS traffic.                                                                 |
| storageAccountCreateContainers            | bool   | N/A                                                        | Specifies whether to create containers in the Azure Storage Account.                                                                                    |
| storageAccountContainerNames              | array  | N/A                                                        | Specifies an array of containers to create in the Azure Storage Account.                                                                                |
| tags                                      | object | N/A                                                        | Specifies the resource tags for all the resources.                                                                                                      |
| userObjectId                              | string | N/A                                                        | Specifies the object id of a Microsoft Entra ID user.                                                                                                   |

We suggest reading sensitive configuration data such as passwords or SSH keys from a pre-existing Azure Key Vault resource. For more information, see [Create parameters files for Bicep deployment](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameter-files?tabs=Bicep)

## Resource Types

Here are the main resource types used by the modules:

| Resource Type                                                                                                                                                           | Description                                                                                                 |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| [Microsoft.Insights/components](https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components?pivots=deployment-language-bicep)                       | An Azure Application Insights instance associated with the Azure AI Studio workspace                        |
| [Microsoft.OperationalInsights/workspaces](https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?pivots=deployment-language-bicep) | An Azure Log Analytics workspace used to collect diagnostics logs and metrics from Azure resources          |
| [Microsoft.KeyVault/vaults](https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults?pivots=deployment-language-bicep)                               | An Azure Key Vault instance associated with the Azure AI Studio workspace                                   |
| [Microsoft.Storage/storageAccounts](https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts)                                                | An Azure Storage instance associated with the Azure AI Studio workspace                                     |
| [Microsoft.ContainerRegistry/registries](https://learn.microsoft.com/en-us/azure/templates/microsoft.containerregistry/registries)                                      | An Azure Container Registry instance associated with the Azure AI Studio workspace                          |
| [Microsoft.MachineLearningServices/workspaces](https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces)                          | An Azure AI hub (Azure AI Studio RP workspace of kind 'hub')                                                |
| [Microsoft.CognitiveServices/accounts](https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts)                                          | An Azure AI Services as the model-as-a-service endpoint provider (allowed kinds: 'AIServices' and 'OpenAI') |

## Prerequisites

Before you begin, ensure you have the following:

- An active [Azure subscription](https://azure.microsoft.com/en-us/free/)
- Azure CLI installed on your local machine. Follow the [installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) if needed.
- Appropriate permissions to create resources in your Azure account
- Basic knowledge of using the command line interface

## Step 1: Clone the Repository

Start by cloning the repository to your local machine:

```bash
git clone <repository_url>
cd bicep
```

## Step 2: Configure Parameters

Edit the [`main.bicepparam` file](./bicep/main.bicepparam) to configure values for the parameters required by the `Bicep` templates. **Make sure** you set appropriate values for resource group name, location, and other necessary parameters in the [`deploy.sh` Bash script](./bicep/deploy.sh).

## Step 3: Deploy Resources

Use the [`deploy.sh` script](./bicep/deploy.sh) to deploy the Azure resources via Bicep. This script will provision all the necessary resources as defined in the Bicep templates.

## How to Test

After deploying the resources, you can verify the deployment by checking the Azure Portal. Ensure all the resources are created and configured correctly.

### Learn More

For more information, see:

- [Azure AI Studio Documentation](https://aka.ms/aistudio/docs)

By following these steps, you will have Azure AI Studio set up and ready for your projects using Bicep. If you encounter any issues, refer to the additional resources or seek help from the Azure support team.
