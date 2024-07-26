#!/bin/bash

# Include functions
source ./functions.sh

# Variables
declare -A variables=(
  # The name of the Azure Resource Group that contains your resources.
  [resourceGroupName]="ai-rg"

  # The location of your Azure resources.
  [location]="westeurope"

  # The name of the Azure AI Services account used by the prompt flow.
  [aiServicesName]="moon-ai-services-test"

  # The name of the project workspace.
  [projectWorkspaceName]="moon-project-test"

  # The name of the Azure Log Analytics workspace to monitor the Azure Machine Learning online endpoint.
  [logAnalyticsName]="moon-log-analytics-test"

  # The SKU of the Azure Log Analytics workspace.
  [logAnalyticsSku]="PerGB2018"

  # The path to the prompt flow zip file for the conversation summarization scenario.
  [promptFlowFilePath]="./test-chat-flow.zip"

  # The name of the prompt flow to be created in Azure AI Studio.
  [promptFlowName]="test-chat-flow"

  # Whether to create the prompt flow in Azure AI Studio (optional).
  [createPromptFlowInAzureAIStudio]="true"

  # Whether to use an existing Azure OpenAI connection and model deployment in the prompt flow.
  # If yes, you need to provide the connection names and deployment name.
  # If not, the prompt flow will try to use the Azure OpenAI Service connection and model with the name indicated in the flow.diag.yaml file.
  [useExistingConnection]="true"

  # The name of the existing Azure OpenAI connection for the prompt flow within the Hub workspace.
  [aoaiConnectionName]="moon-ai-services-test-connection_aoai"

  # The name of the existing Azure OpenAI GPT model deployment within the Hub workspace.
  [aoaiDeploymentName]="gpt-4o"

  # Whether to update an existing Azure Machine Learning online endpoint during provisioning.
  [updateExistingEndpoint]="false"

  # Whether to update an existing Azure Machine Learning managed online deployment during provisioning.
  [updateExistingDeployment]="false"

  # The name of the Azure Machine Learning model used by the prompt flow.
  [endpointName]="test-chat-flow-endpoint"

  # Specifies the name of the Azure Machine Learning model used by the prompt flow.
  [modelName]="test-chat-flow-model"

  # The description of the Azure Machine Learning model for the prompt flow.
  [modelDescription]="Azure Machine Learning model for the test chat prompt flow."

  # The version of the Azure Machine Learning model used by the prompt flow.
  [modelVersion]="1"

  # The name of the Azure Machine Learning environment used by the prompt flow.
  [environmentName]="promptflow-runtime"

  # The version of the Azure Machine Learning environment used by the prompt flow.
  [environmentVersion]="20240619.v2"

  # The image of the Azure Machine Learning environment used by the prompt flow.
  [environmentImage]="mcr.microsoft.com/azureml/promptflow/promptflow-runtime:20240619.v2"

  # The description of the Azure Machine Learning environment used by the prompt flow.
  [environmentDescription]="Environment created via Azure CLI."

  # The name of the Azure Machine Learning managed online deployment for the prompt flow.
  [deploymentName]="test-chat-flow-deployment"

  # The type of Azure Machine Learning managed online deployment.
  [deploymentInstanceType]="Standard_DS3_v2"

  # The number of instances for the Azure Machine Learning managed online deployment.
  [deploymentInstanceCount]=1

  # The maximum number of concurrent requests per instance for the Azure Machine Learning managed online deployment.
  [maxConcurrentRequestsPerInstance]=5

  # Whether to use the hub workspace Azure Application Insights instance for monitoring.
  [applicationInsightsEnabled]="true"

  # The name of the diagnostic setting for monitoring the Azure Machine Learning online endpoint.
  [diagnosticSettingName]="default"

  # Whether to enable debug mode (displays additional information during script execution).
  [debug]="true"

  # The name of the temporary directory for storing files during provisioning.
  [tempDirectory]="temp"
)

# Parse the arguments
parse_args variables $@

# The Azure subscription ID.
subscriptionId=$(az account show --query id --output tsv)

# Check and install unzip if not present
install_unzip

# Check and install yq if not present
install_yq

# Check and install python and pip if not present
install_python_and_pip

# Check and install promptflow tool if not present
install_promptflow

# Creates a temporary directory for the prompt flow
create_new_directory $tempDirectory

# Unzip the archive containing the prompt flow
unzip_archive $promptFlowFilePath "$tempDirectory/$promptFlowName"

# Replace values in the flow.dag.yaml file of the prompt flow
yamlFileName="$tempDirectory/$promptFlowName/flow.dag.yaml"

if [ "$useExistingConnection" == "true" ]; then
  # Check if an Azure OpenAI connection exists in the prompt flow
  connectionName=$(yq '.nodes[] | select(.provider == "AzureOpenAI") | .connection' $yamlFileName)

  # Check if we have found a connection_name
  if [ -n "$connectionName" ]; then
    echo "[$connectionName] found in the prompt flow."

    echo "Using the existing [$aoaiConnectionName] Azure OpenAI connection and [$aoaiDeploymentName] model deployment in the prompt flow..."
    yq eval '(.nodes[] | select(.provider == "AzureOpenAI") | .connection) = "'$aoaiConnectionName'"' -i $yamlFileName
    yq eval '(.nodes[] | select(.provider == "AzureOpenAI") | .inputs.deployment_name) = "'$aoaiDeploymentName'"' -i $yamlFileName

  else
    echo "No Azure OpenAI connection found in the prompt flow."
  fi
fi

if [ "$createPromptFlowInAzureAIStudio" == "true" ]; then
  # Check if the prompt flow already exists in the project workspace
  echo "Checking if the [$promptFlowName] prompt flow already exists in the [$projectWorkspaceName] project workspace..."

  result=$(pfazure flow list \
    --subscription $subscriptionId \
    --resource-group $resourceGroupName \
    --workspace-name $projectWorkspaceName |
    jq --arg display_name $promptFlowName '[.[] | select(.display_name == $display_name)] | length > 0')

  if [ "$result" == "true" ]; then
    echo "The [$promptFlowName] prompt flow already exists in the [$projectWorkspaceName] project workspace."
  else
    # Create the prompt flow on Azure
    echo -e "Creating the [$promptFlowName] prompt flow in the [$projectWorkspaceName] project workspace..."
    result=$(pfazure flow create \
      --flow "$tempDirectory/$promptFlowName" \
      --subscription $subscriptionId \
      --resource-group $resourceGroupName \
      --workspace-name $projectWorkspaceName \
      --set display_name=$promptFlowName)

    if [ $? -eq 0 ]; then
      echo "The [$promptFlowName] prompt flow was created successfully in the [$projectWorkspaceName] project workspace."
    else
      echo "An error occurred while creating the [$promptFlowName] prompt flow in the [$projectWorkspaceName] project workspace."
      exit -1
    fi
  fi
fi

# Create a YAML file with the definition of the Azure Machine Learning online endpoint used to expose the prompt flow
yamlFileName="$tempDirectory/endpoint.yaml"
cat <<EOL >$yamlFileName
\$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineEndpoint.schema.json
auth_mode: aad_token
EOL

if [ "$debug" == "true" ]; then
  cat "$yamlFileName"
fi

# Check whether the Azure Machine Learning online endpoint already exists in the resource group
echo "Checking whether the [$endpointName] Azure Machine Learning online endpoint already exists in the [$resourceGroupName] resource group..."
az ml online-endpoint show \
  --name $endpointName \
  --resource-group $resourceGroupName \
  --workspace-name $projectWorkspaceName \
  --only-show-errors &>/dev/null

if [ $? -eq 0 ]; then
  # Update the Azure Machine Learning online endpoint to trigger the prompt flow execution
  echo "The [$endpointName] Azure Machine Learning online endpoint already exists in the [$resourceGroupName] resource group."

  if [ "$updateExistingEndpoint" == "true" ]; then
    echo "Updating the [$endpointName] Azure Machine Learning online endpoint in the [$resourceGroupName] resource group..."
    az ml online-endpoint update \
      --name $endpointName \
      --resource-group $resourceGroupName \
      --workspace-name $projectWorkspaceName \
      --file $yamlFileName \
      --only-show-errors 1>/dev/null
    if [ $? -eq 0 ]; then
      echo "The [$endpointName] Azure Machine Learning online endpoint was updated successfully in the [$resourceGroupName] resource group."
    else
      echo "An error occurred while updating the [$endpointName] Azure Machine Learning online endpoint in the [$resourceGroupName] resource group."
      exit -1
    fi
  fi
else
  # Create an Azure Machine Learning online endpoint to trigger the prompt flow execution
  echo "Creating the [$endpointName] Azure Machine Learning online endpoint in the [$resourceGroupName] resource group..."
  az ml online-endpoint create \
    --name $endpointName \
    --resource-group $resourceGroupName \
    --workspace-name $projectWorkspaceName \
    --file $yamlFileName \
    --only-show-errors 1>/dev/null
  if [ $? -eq 0 ]; then
    echo "The [$endpointName] Azure Machine Learning online endpoint was created successfully in the [$resourceGroupName] resource group."
  else
    echo "An error occurred while creating the [$endpointName] Azure Machine Learning online endpoint in the [$resourceGroupName] resource group."
    exit -1
  fi
fi

# Retrieve the Azure Machine Learning online endpoint information
echo "Retrieving the [$endpointName] Azure Machine Learning online endpoint information..."
endpoint=$(az ml online-endpoint show \
  --name $endpointName \
  --resource-group $resourceGroupName \
  --workspace-name $projectWorkspaceName \
  --only-show-errors)

if [ $? -eq 0 ]; then
  echo "The [$endpointName] Azure Machine Learning online endpoint information was retrieved successfully."
  endpointResourceId=$(echo "$endpoint" | jq -r '.id')
  endpointPrincipalId=$(echo "$endpoint" | jq -r '.identity.principal_id')
  endpointScoringUri=$(echo "$endpoint" | jq -r '.scoring_uri')
  echo "- id: $endpointResourceId"
  echo "- name: $endpointName"
  echo "- principal_id: $endpointPrincipalId"
  echo "- scoring_uri: $endpointScoringUri"

  # Retrieve the resource id of the Azure AI Services account
  aiServicesId=$(az cognitiveservices account show \
    --name $aiServicesName \
    --resource-group $resourceGroupName \
    --query id \
    --output tsv \
    --only-show-errors)

  if [ -n $aiServicesId ]; then
    echo "The resource id of the [$aiServicesName] Azure AI Services account is [$aiServicesId]."
  else
    echo "An error occurred while retrieving the resource id of the [$aiServicesName] Azure AI Services account."
    exit -1
  fi

  # Assign the Cognitive Services OpenAI User role on the Azure AI Services account to the managed identity of the Azure Machine Learning online endpoint
  role="Cognitive Services OpenAI User"
  echo "Verifying if the endpoint managed identity has been assigned the role [$role] with the [$aiServicesName] Azure AI Services account as a scope..."
  current=$(az role assignment list \
    --assignee $endpointPrincipalId \
    --scope $aiServicesId \
    --query "[?roleDefinitionName=='$role'].roleDefinitionName" \
    --output tsv \
    --only-show-errors 2>/dev/null)

  if [[ $current == $role ]]; then
    echo "The [$endpointName] Azure Machine Learning online endpoint managed identity is already assigned the ["$current"] role with the [$aiServicesName] Azure AI Services account as a scope"
  else
    echo "The [$endpointName] Azure Machine Learning online endpoint managed identity is not assigned the [$role] role with the [$aiServicesName] Azure AI Services account as a scope"
    echo "Assigning the [$role] role to the [$endpointName] Azure Machine Learning online endpoint managed identity with the [$aiServicesName] Azure AI Services account as a scope..."

    az role assignment create \
      --assignee $endpointPrincipalId \
      --role "$role" \
      --scope $aiServicesId \
      --only-show-errors 1>/dev/null

    if [[ $? == 0 ]]; then
      echo "The [$endpointName] Azure Machine Learning online endpoint managed identity has been successfully assigned the [$role] role with the [$aiServicesName] Azure AI Services account as a scope"
    else
      echo "Failed to assign the [$role] role to the [$endpointName] Azure Machine Learning online endpoint managed identity with the [$aiServicesName] Azure AI Services account as a scope"
      exit -1
    fi
  fi

  # Retrieve the resource id of the project workspace
  projectWorkspaceId=$(az ml workspace show \
    --name moon-project-test \
    --resource-group ai-rg \
    --query id \
    --output tsv --only-show-errors)

  if [ -n $projectWorkspaceId ]; then
    echo "The resource id of the [$projectWorkspaceName] project workspace is [$projectWorkspaceId]."
  else
    echo "An error occurred while retrieving the resource id of the [$projectWorkspaceName] project workspace."
    exit -1
  fi

  # Assign the Azure Machine Learning Workspace Connection Secrets Reader role on the project workspace to the managed identity of the Azure Machine Learning online endpoint
  role="Azure Machine Learning Workspace Connection Secrets Reader"
  echo "Verifying if the endpoint managed identity has been assigned the role [$role] with the [$projectWorkspaceName] project workspace as a scope..."
  current=$(az role assignment list \
    --assignee $endpointPrincipalId \
    --scope $projectWorkspaceId \
    --query "[?roleDefinitionName=='$role'].roleDefinitionName" \
    --output tsv \
    --only-show-errors 2>/dev/null)

  if [[ $current == $role ]]; then
    echo "The [$endpointName] Azure Machine Learning online endpoint managed identity is already assigned the ["$current"] role with the [$projectWorkspaceName] project workspace as a scope"
  else
    echo "The [$endpointName] Azure Machine Learning online endpoint managed identity is not assigned the [$role] role with the [$projectWorkspaceName] project workspace as a scope"
    echo "Assigning the [$role] role to the [$endpointName] Azure Machine Learning online endpoint managed identity with the [$projectWorkspaceName] project workspace as a scope..."

    az role assignment create \
      --assignee $endpointPrincipalId \
      --role "$role" \
      --scope $projectWorkspaceId \
      --only-show-errors 1>/dev/null

    if [[ $? == 0 ]]; then
      echo "The [$endpointName] Azure Machine Learning online endpoint managed identity has been successfully assigned the [$role] role with the [$projectWorkspaceName] project workspace as a scope"
    else
      echo "Failed to assign the [$role] role to the [$endpointName] Azure Machine Learning online endpoint managed identity with the [$projectWorkspaceName] project workspace as a scope"
      exit -1
    fi
  fi

  # Check if log analytics workspace exists
  echo "Checking whether ["$logAnalyticsName"] Log Analytics already exists..."
  az monitor log-analytics workspace show \
    --name $logAnalyticsName \
    --resource-group $resourceGroupName \
    --query id \
    --output tsv \
    --only-show-errors &>/dev/null

  if [[ $? != 0 ]]; then
    echo "No ["$logAnalyticsName"] log analytics workspace actually exists in the ["$resourceGroupName"] resource group"
    echo "Creating ["$logAnalyticsName"] log analytics workspace in the ["$resourceGroupName"] resource group..."

    # Create the log analytics workspace
    az monitor log-analytics workspace create \
      --name $logAnalyticsName \
      --resource-group $resourceGroupName \
      --identity-type SystemAssigned \
      --sku $logAnalyticsSku \
      --location $location \
      --only-show-errors

    if [[ $? == 0 ]]; then
      echo "["$logAnalyticsName"] log analytics workspace successfully created in the ["$resourceGroupName"] resource group"
    else
      echo "Failed to create ["$logAnalyticsName"] log analytics workspace in the ["$resourceGroupName"] resource group"
      exit -1
    fi
  else
    echo "["$logAnalyticsName"] log analytics workspace already exists in the ["$resourceGroupName"] resource group"
  fi

  # Retrieve the log analytics workspace id
  workspaceResourceId=$(az monitor log-analytics workspace show \
    --name $logAnalyticsName \
    --resource-group $resourceGroupName \
    --query id \
    --output tsv \
    --only-show-errors 2>/dev/null)

  if [[ -n $workspaceResourceId ]]; then
    echo "Successfully retrieved the resource id for the ["$logAnalyticsName"] log analytics workspace"
  else
    echo "Failed to retrieve the resource id for the ["$logAnalyticsName"] log analytics workspace"
    exit -1
  fi

  # Check if the diagnostic setting for the Azure Machine Learning online endpoint already exists
  echo "Checking if the [$diagnosticSettingName] diagnostic setting for the [$endpointName] Azure Machine Learning online endpoint actually exists..."
  result=$(az monitor diagnostic-settings show \
    --name $diagnosticSettingName \
    --resource $endpointResourceId \
    --query name \
    --output tsv 2>/dev/null)

  if [[ -z $result ]]; then
    echo "[$diagnosticSettingName] diagnostic setting for the [$endpointName] Azure Machine Learning online endpoint does not exist"
    echo "Creating [$diagnosticSettingName] diagnostic setting for the [$endpointName] Azure Machine Learning online endpoint..."

    # Create the diagnostic setting for the Azure Machine Learning online endpoint
    az monitor diagnostic-settings create \
      --name $diagnosticSettingName \
      --resource $endpointResourceId \
      --logs '[{"categoryGroup": "allLogs", "enabled": true}]' \
      --metrics '[{"category": "Traffic", "enabled": true}]' \
      --workspace $workspaceResourceId \
      --only-show-errors 1>/dev/null

    if [[ $? == 0 ]]; then
      echo "[$diagnosticSettingName] diagnostic setting for the [$endpointName] Azure Machine Learning online endpoint successfully created"
    else
      echo "Failed to create [$diagnosticSettingName] diagnostic setting for the [$endpointName] Azure Machine Learning online endpoint"
      exit -1
    fi
  fi
else
  echo "An error occurred while retrieving the [$endpointName] Azure Machine Learning online endpoint information."
  exit -1
fi

# Check whether the Azure Machine Learning model already exists in the project workspace
echo "Checking whether the [$modelName] Azure Machine Learning model already exists in the [$projectWorkspaceName] project workspace..."
az ml model show \
  --name $modelName \
  --version $modelVersion \
  --workspace-name $projectWorkspaceName \
  --resource-group $resourceGroupName \
  --only-show-errors &>/dev/null

if [ $? -eq 0 ]; then
  echo "The [$modelName] Azure Machine Learning model already exists in the [$projectWorkspaceName] project workspace."
else
  echo "The [$modelName] Azure Machine Learning model does not exist in the [$projectWorkspaceName] project workspace."
  echo "Creating the [$modelName] Azure Machine Learning model in the [$projectWorkspaceName] project workspace..."

  # Create a YAML file for the Azure Machine Learning model
  yamlFileName="$tempDirectory/model.yaml"
  cat <<EOF >"$yamlFileName"
\$schema: https://azuremlschemas.azureedge.net/latest/model.schema.json
name: $modelName
version: $modelVersion
path: $promptFlowName
description: $modelDescription
properties:
  azureml.promptflow.dag_file: flow.dag.yaml
EOF

  if [ "$debug" == "true" ]; then
    cat "$yamlFileName"
  fi

  # Create the Azure Machine Learning model
  az ml model create \
    --file $yamlFileName \
    --workspace-name $projectWorkspaceName \
    --resource-group $resourceGroupName \
    --only-show-errors 1>/dev/null

  if [ $? -eq 0 ]; then
    echo "The [$modelName] Azure Machine Learning model was created successfully in the [$projectWorkspaceName] project workspace."
  else
    echo "An error occurred while creating the [$modelName] Azure Machine Learning model in the [$projectWorkspaceName] project workspace."
    exit -1
  fi
fi

# Check if the Azure Machine Learning environment already exists
echo "Checking if the [$environmentName] Azure Machine Learning environment with [$environmentName] version already exists in the [$projectWorkspaceName] project workspace..."
az ml environment show \
  --name $environmentName \
  --version $environmentVersion \
  --resource-group $resourceGroupName \
  --workspace-name $projectWorkspaceName \
  --only-show-errors &>/dev/null

if [ $? -eq 0 ]; then
  echo "The [$environmentName] Azure Machine Learning environment with [$environmentName] version already exists in the [$projectWorkspaceName] project workspace."
else
  echo "The [$environmentName] Azure Machine Learning environment with [$environmentName] version does not exist in the [$projectWorkspaceName] project workspace."
  echo "Creating the [$environmentName] Azure Machine Learning environment with [$environmentName] version in the [$projectWorkspaceName] project workspace..."

  # Create a YAML file for the Azure Machine Learning environment
  yamlFileName="$tempDirectory/environment.yaml"
  cat <<EOF >"$yamlFileName"
\$schema: https://azuremlschemas.azureedge.net/latest/environment.schema.json
name: $environmentName
version: $environmentVersion
image: $environmentImage
description: $environmentDescription
inference_config:
  liveness_route:
    path: /health
    port: 8080
  readiness_route:
    path: /health
    port: 8080
  scoring_route:
    path: /score
    port: 8080
EOF

  if [ "$debug" == "true" ]; then
    cat "$yamlFileName"
  fi

  # Create the Azure Machine Learning environment
  az ml environment create \
    --file $yamlFileName \
    --name $environmentName \
    --version $environmentVersion \
    --resource-group $resourceGroupName \
    --workspace-name $projectWorkspaceName \
    --only-show-errors 1>/dev/null

  if [ $? -eq 0 ]; then
    echo "The [$environmentName] Azure Machine Learning environment with [$environmentName] version was created successfully in the [$projectWorkspaceName] project workspace."
  else
    echo "An error occurred while creating the [$environmentName] Azure Machine Learning environment with [$environmentName] version in the [$projectWorkspaceName] project workspace."
    exit -1
  fi
fi

# Create a YAML file for the Azure Machine Learning managed online deployment
yamlFileName="$tempDirectory/deployment.yaml"
cat <<EOF >"$yamlFileName"
\$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: $deploymentName
endpoint_name: $endpointName
model: azureml:$modelName:$modelVersion
environment: azureml:$environmentName:$environmentVersion
instance_type: $deploymentInstanceType
instance_count: $deploymentInstanceCount
environment_variables:
  # When there are multiple fields in the response, using this env variable will filter the fields to expose in the response.
  # For example, if there are 2 flow outputs: "answer", "context", and I only want to have "answer" in the endpoint response, I can set this env variable to '["answer"]'
  # PROMPTFLOW_RESPONSE_INCLUDED_FIELDS: '["analysisOutputBlobUri"]'

  # if you want to deploy to serving mode, you need to set this env variable to "serving"
  PROMPTFLOW_RUN_MODE: "serving"
  RUN_MODE: "serving"
  PRT_CONFIG_OVERRIDE: "storage.storage_account=$storageAccountName,deployment.subscription_id=$subscriptionId,deployment.resource_group=$resourceGroupName,deployment.workspace_name=$projectWorkspaceName,deployment.endpoint_name=$endpointName,deployment.deployment_name=$deploymentName,deployment.mt_service_endpoint=https://${location,,}.api.azureml.ms"
  PROMPTFLOW_MDC_ENABLE: "True"
  AZURE_ACTIVE_DIRECTORY: "https://login.microsoftonline.com"
  AZURE_RESOURCE_MANAGER: "https://management.azure.com"
# Enable this will collect metrics such as latency/token/etc during inference time to workspace default Azure Application Insights
app_insights_enabled: $applicationInsightsEnabled
request_settings:
  request_timeout_ms: 180000
  max_concurrent_requests_per_instance: $maxConcurrentRequestsPerInstance
scale_settings:
  type: default
readiness_probe:
    failure_threshold: 30
    initial_delay: 10
    period: 10
    success_threshold: 1
    timeout: 2
liveness_probe:
    failure_threshold: 30
    initial_delay: 10
    period: 10
    success_threshold: 1
    timeout: 2
data_collector:
  sampling_rate: 1.0
  collections:
    app_traces:
      enabled: "True"
    model_inputs:
      enabled: "True"
    model_outputs:
      enabled: "True"
EOF

if [ "$debug" == "true" ]; then
  cat "$yamlFileName"
fi

# Check if the Azure Machine Learning managed online deployment already exists
echo "Checking if the [$deploymentName] Azure Machine Learning managed online deployment already exists..."
az ml online-deployment show \
  --name $deploymentName \
  --endpoint-name $endpointName \
  --resource-group $resourceGroupName \
  --workspace-name $projectWorkspaceName \
  --only-show-errors &>/dev/null

if [ $? -eq 0 ]; then
  echo "The [$deploymentName] Azure Machine Learning managed online deployment already exists."

  if [ "$updateExistingDeployment" == "true" ]; then
    echo "Updating the [$deploymentName] Azure Machine Learning managed online deployment in the [$resourceGroupName] resource group..."
    az ml online-deployment update \
      --name $deploymentName \
      --endpoint-name $endpointName \
      --workspace-name $projectWorkspaceName \
      --resource-group $resourceGroupName \
      --file $yamlFileName \
      --only-show-errors 1>/dev/null
    if [ $? -eq 0 ]; then
      echo "The [$deploymentName] Azure Machine Learning managed online deployment was updated successfully in the [$resourceGroupName] resource group."
    else
      echo "An error occurred while updating the [$deploymentName] Azure Machine Learning managed online deployment in the [$resourceGroupName] resource group."
      exit -1
    fi
  fi
else
  echo "The [$deploymentName] Azure Machine Learning managed online deployment does not exist."

  # Create the Azure Machine Learning managed online deployment
  echo "Creating the [$deploymentName] Azure Machine Learning managed online deployment..."
  az ml online-deployment create \
    --name $deploymentName \
    --endpoint-name $endpointName \
    --workspace-name $projectWorkspaceName \
    --resource-group $resourceGroupName \
    --file $yamlFileName \
    --only-show-errors 1>/dev/null

  if [ $? -eq 0 ]; then
    echo "The [$deploymentName] Azure Machine Learning managed online deployment was created successfully."

    # Configuraing the Azure Machine Learning manaed endpoint to send 100% traffic to the new deployment
    echo "Configuring the [$endpointName] Azure Machine Learning managed endpoint to send 100% traffic to the [$deploymentName] deployment..."
    az ml online-endpoint update \
      --name $endpointName \
      --resource-group $resourceGroupName \
      --workspace-name $projectWorkspaceName \
      --traffic $deploymentName=100 \
      --only-show-errors 1>/dev/null

    if [ $? -eq 0 ]; then
      echo "The [$endpointName] Azure Machine Learning managed endpoint was updated successfully to send 100% traffic to the [$deploymentName] deployment."
    else
      echo "An error occurred while updating the [$endpointName] Azure Machine Learning managed endpoint to send 100% traffic to the [$deploymentName] deployment."
      exit -1
    fi
  else
    echo "An error occurred while creating the [$deploymentName] Azure Machine Learning managed online deployment."
    exit -1
  fi
fi

# Remove the temporary directory
remove_directory $tempDirectory