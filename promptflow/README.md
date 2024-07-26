# Deploy the Basic Chat Prompt Flow

This article will help you set up to deploy the [Basic Chat](https://github.com/microsoft/promptflow/tree/main/examples/flows/chat/chat-basic) prompt flow step-by-step using Azure CLI.

- [Prompt Flow](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/prompt-flow):
  - This is the logic that runs the Basic Chat scenario. It is a DAG (Directed Acyclic Graph) that defines the steps of the prompt flow.
- [Managed Online Endpoint](https://learn.microsoft.com/en-us/azure/machine-learning/concept-endpoints-online?view=azureml-api-2#managed-online-endpoints-vs-kubernetes-online-endpoints):
  - This endpoint makes the prompt flow available as a service. It deploys the model to a server, allowing you to get real-time results through the HTTPS protocol. It also tracks logs and metrics for performance monitoring.
- [Model](https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-model?view=azureml-api-2):
  - This is the AI model that wraps the prompt flow logic and is used by the online endpoint to run the prompt flow.
- [Environment](https://learn.microsoft.com/en-us/azure/machine-learning/concept-environments?view=azureml-api-2):
  - This specifies the software and settings needed to run your model, including the necessary Python packages.
- [Managed Deployment](https://learn.microsoft.com/en-us/azure/machine-learning/concept-endpoints-online?view=azureml-api-2#online-deployments):
  - This includes the virtual machines and resources needed to run the prompt flow. Multiple deployments can be managed through a single endpoint, directing requests as needed.

For more information on prompt flows and how to deploy a prompt flow using an online endpoint and managed deployment, see the following resources:

- [What is Azure Machine Learning prompt flow](https://learn.microsoft.com/en-us/azure/machine-learning/prompt-flow/overview-what-is-prompt-flow?view=azureml-api-2)
- [Get started with prompt flow](https://learn.microsoft.com/en-us/azure/machine-learning/prompt-flow/get-started-prompt-flow?view=azureml-api-2)
- [Prompt flow ecosystem](https://learn.microsoft.com/en-us/azure/machine-learning/prompt-flow/community-ecosystem?view=azureml-api-2)
- [Deploy a flow to online endpoint for real-time inference with CLI](https://learn.microsoft.com/en-us/azure/machine-learning/prompt-flow/how-to-deploy-to-code?view=azureml-api-2&tabs=managed&source=docs)
- [How to use streaming endpoints deployed from prompt Flow](https://learn.microsoft.com/en-us/azure/machine-learning/prompt-flow/how-to-enable-streaming-mode?view=azureml-api-2)
- [How to trace your application with prompt flow SDK](https://learn.microsoft.com/en-us/azure/machine-learning/prompt-flow/how-to-trace-local-sdk?view=azureml-api-2&tabs=python)
- [Prompt Flow GitHub Repository](https://github.com/microsoft/promptflow)

> [!NOTE]
> The setup scripts are designed to run multiple times consistently. It checks if each resource already exists before creating it. This makes the script longer, but it ensures a smooth setup. This article will guide you through each step of deploying and calling a sample prompt flow.

## Table of Contents

- [Deploy the Basic Chat Prompt Flow](#deploy-the-basic-chat-prompt-flow)
  - [Table of Contents](#table-of-contents)
  - [Objectives](#objectives)
  - [Pre-requisites](#pre-requisites)
  - [Deploy the Prompt Flow](#deploy-the-prompt-flow)
    - [Step 01: Confirm All Required Resources Are Created Successfully](#step-01-confirm-all-required-resources-are-created-successfully)
    - [Step 02: Include `functions.sh` File](#step-02-include-functionssh-file)
    - [Step 03: Assign Value to Variables](#step-03-assign-value-to-variables)
    - [Step 04: Install Necessary Tools and Packages](#step-04-install-necessary-tools-and-packages)
    - [Step 05: Unzip the Prompt Flow Archive and Update the Configuration](#step-05-unzip-the-prompt-flow-archive-and-update-the-configuration)
    - [Step 06: Create the Prompt Flow in Azure AI Studio (Optional)](#step-06-create-the-prompt-flow-in-azure-ai-studio-optional)
    - [Step 07: Create the Online Endpoint for the Prompt Flow](#step-07-create-the-online-endpoint-for-the-prompt-flow)
    - [Step 08: Create Role Assignment and Diagnostic Settings](#step-08-create-role-assignment-and-diagnostic-settings)
    - [Step 09: Create a Model for the Prompt Flow](#step-09-create-a-model-for-the-prompt-flow)
    - [Step 11: Create an Environment for the Prompt Flow](#step-11-create-an-environment-for-the-prompt-flow)
    - [Step 12: Create a Managed Online Deployment for the Prompt Flow](#step-12-create-a-managed-online-deployment-for-the-prompt-flow)
  - [Call the Prompt Flow](#call-the-prompt-flow)
    - [Step 01: Include `functions.sh` File](#step-01-include-functionssh-file)
    - [Step 02: Assign Value to Variables](#step-02-assign-value-to-variables)
    - [Step 03: Retrieve a JWT Security Token](#step-03-retrieve-a-jwt-security-token)
    - [Step 04: Retrieve the OpenAPI Schema of the REST Service](#step-04-retrieve-the-openapi-schema-of-the-rest-service)
    - [Step 05: Call the Prompt Flow via the REST Service](#step-05-call-the-prompt-flow-via-the-rest-service)

## Objectives

You can use the `deploy.sh` script to create the necessary Azue resources to run, monitor, and expose your prompt flow to the public internet. You can use the `call.sh` to call vie prompt flow via the online endpoint using a JWT security token issued by Microsoft Entra ID and, optionally, retrieve the OpenAPI schema of the REST endpoint.

## Pre-requisites

- Azure CLI and ML Extension:
  - Ensure you have the Azure CLI and the Azure Machine Learning extension installed. For detailed instructions, see [Install, set up, and use the CLI (v2)](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-configure-cli?view=azureml-api-2&tabs=public).
- Azure AI Studio Hub and Project:
  - You need an Azure AI Studio Hub and Project workspace. If you do not have one, follow the steps in the [How to create and manage an Azure AI Studio hub](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/create-azure-ai-resource?tabs=portal) to create one.
- Azure Role-Based Access Control (RBAC):
  - Ensure you have the appropriate permissions to perform the tasks in this article. Your user account must have the owner or contributor role for the Azure AI Studio Hub and Project workspace or a custom role with the "Microsoft.MachineLearningServices/workspaces/onlineEndpoints/" permission. Additionally, if you use the studio to create or manage online endpoints/deployments, you will need the "Microsoft.Resources/deployments/write" permission from the resource group owner. For more details, see [Role-based access control in Azure AI Studio](https://learn.microsoft.com/en-us/azure/ai-studio/concepts/rbac-ai-studio).
- Tools and Packages:
  - The script uses functions from `functions.sh` to install the following tools and packages:
    - `unzip`
    - `yq`
    - `python`
    - `pip`
    - `promptflow`

## Deploy the Prompt Flow

This section explains the steps followed by the `deploy.sh` Bash script to set up and manage the necessary parts for creating, running, and monitoring the sample prompt flow using an online endpoint.

### Step 01: Confirm All Required Resources Are Created Successfully

Use the [deploy.sh](../bicep/deploy.sh) script to setup all the necessary Azure resources to run, monitor, and expose the prompt flow:

![Architecture](./images/architecture.png)

| Resource                    | Type                                                                                                                                                                    | Description                                                                                                                 |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Azure Application Insights  | [Microsoft.Insights/components](https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components?pivots=deployment-language-bicep)                       | An Azure Application Insights instance associated with the Azure AI Studio workspace                                        |
| Azure Monitor Log Analytics | [Microsoft.OperationalInsights/workspaces](https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?pivots=deployment-language-bicep) | An Azure Log Analytics workspace used to collect diagnostics logs and metrics from Azure resources                          |
| Azure Key Vault             | [Microsoft.KeyVault/vaults](https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults?pivots=deployment-language-bicep)                               | An Azure Key Vault instance associated with the Azure AI Studio workspace                                                   |
| Azure Storage Account       | [Microsoft.Storage/storageAccounts](https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts)                                                | An Azure Storage instance associated with the Azure AI Studio workspace                                                     |
| Azure Container Registry    | [Microsoft.ContainerRegistry/registries](https://learn.microsoft.com/en-us/azure/templates/microsoft.containerregistry/registries)                                      | An Azure Container Registry instance associated with the Azure AI Studio workspace                                          |
| Azure AI Hub / Project      | [Microsoft.MachineLearningServices/workspaces](https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces)                          | An Azure AI Studio Hub and Project (Azure ML Workspace of kind 'hub' and 'project')                                         |
| Azure AI Services           | [Microsoft.CognitiveServices/accounts](https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts)                                          | An Azure AI Services as the model-as-a-service endpoint provider including GPT-4o and ADA Text Embeddings model deployments |

If any of these Azure resources are missing, please refer to the [README](../README.md) to create them.

### Step 02: Include `functions.sh` File

In this step, we incorporate the [functions.sh](./functions.sh) file that contains some helper functions to automate some tasks.

```bash
# Include functions
source ./functions.sh
```

The `functions.sh` file contains the following functions:

```bash
# Checks if a specific command is available on your system.
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Processes named command-line arguments into variables.
parse_args() {
  # $1 - The associative array name containing the argument definitions and default values
  # $2 - The arguments passed to the script
  local -n arg_defs=$1
  shift
  local args=("$@")

  # Assign default values first for defined arguments
  for arg_name in "${!arg_defs[@]}"; do
    declare -g "$arg_name"="${arg_defs[$arg_name]}"
  done

  # Process command-line arguments
  for ((i = 0; i < ${#args[@]}; i++)); do
    arg=${args[i]}
    if [[ $arg == --* ]]; then
      arg_name=${arg#--}
      next_index=$((i + 1))
      next_arg=${args[$next_index]}

      # Check if the argument is defined in arg_defs
      if [[ -z ${arg_defs[$arg_name]+_} ]]; then
        # Argument not defined, skip setting
        continue
      fi

      if [[ $next_arg == --* ]] || [[ -z $next_arg ]]; then
        # Treat as a flag
        declare -g "$arg_name"=1
      else
        # Treat as a value argument
        declare -g "$arg_name"="$next_arg"
        ((i++))
      fi
    else
      break
    fi
  done
}

# Installs unzip, if it is not already installed.
install_unzip() {
  if ! command_exists unzip; then
    echo "[unzip] is not installed. Installing [unzip]..."
    sudo apt-get update && sudo apt-get install -y unzip
    if command_exists unzip; then
      echo "[unzip] successfully installed."
    else
      echo "Failed to install [unzip]."
      exit 1
    fi
  else
    echo "[unzip] is already installed."
  fi
}

# Installs yq, for processing YAML files, if it is not already installed.
install_yq() {
  if ! command_exists yq; then
    echo "[yq] is not installed. Installing [yq]..."
    sudo apt-get update && sudo apt-get install -y jq # jq is a prerequisite for yq
    sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.25.1/yq_linux_amd64"
    sudo chmod +x /usr/local/bin/yq
    if command_exists yq; then
      echo "[yq] successfully installed."
    else
      echo "Failed to install [yq]."
      exit 1
    fi
  else
    echo "[yq] is already installed."
  fi
}

# Installs Python and pip, if they are not already installed.
install_python_and_pip() {
  if ! command_exists python3; then
    echo "[Python3] is not installed. Installing [Python3]..."
    sudo apt-get update && sudo apt-get install -y python3
    if command_exists python3; then
      echo "[Python3] successfully installed."
    else
      echo "Failed to install [Python3]."
      exit 1
    fi
  else
    echo "[Python3] is already installed."
  fi

  if ! command_exists pip3; then
    echo "[pip3] is not installed. Installing [pip3]..."
    sudo apt-get update && sudo apt-get install -y python3-pip
    if command_exists pip3; then
      echo "[pip3] successfully installed."
    else
      echo "Failed to install [pip3]."
      exit 1
    fi
  else
    echo "[pip3] is already installed."
  fi
}

# Installs the promptflow tools, if they are not already installed.
install_promptflow() {
  if sudo pip3 show promptflow >/dev/null 2>&1; then
    echo "[promptflow] is already installed."
  else
    echo "Installing promptflow using pip3..."
    sudo pip3 install promptflow --upgrade
    if sudo pip3 show promptflow >/dev/null 2>&1; then
      echo "[promptflow] successfully installed."
    else
      echo "Failed to install [promptflow]."
      exit 1
    fi
  fi

  if ! command_exists pfazure; then
    echo "[promptflow[azure]] is not installed. Installing [promptflow[azure]]..."
    sudo pip3 install promptflow[azure] --upgrade
    if command_exists pfazure; then
      echo "[promptflow[azure]] successfully installed."
    else
      echo "Failed to install [promptflow[azure]]."
      exit 1
    fi
  else
    echo "[promptflow[azure]] is already installed."
  fi
}

# Replaces a field value in a YAML file using yq.
replace_yaml_field() {
  local yaml_file="$1"
  local field_path="$2"
  local search_value="$3"
  local replace_value="$4"

  yq eval ".${field_path} |= sub(\"${search_value}\", \"${replace_value}\")" "$yaml_file" -i
}

# Sets a new value for a field in a YAML file using yq.
set_yaml_field() {
  local yaml_file="$1"
  local field_path="$2"
  local new_value="$3"

  yq eval ".${field_path} = \"${new_value}\"" "$yaml_file" -i
}

# Generates a new file name with the current date and time appended.
generate_new_filename() {
  local file=$1

  # Check if the input file is provided
  if [[ -z "$file" ]]; then
    echo "Usage: generate_new_filename <file_name>"
    return 1
  fi

  # Extract the file name without the extension
  local filename=$(basename "$file")
  local name="${filename%.*}"
  local extension="${filename##*.}"

  # Get the current date and time to the second
  local current_datetime=$(date +"%Y-%m-%d-%H-%M-%S")

  # Construct the new file name
  local new_file_name="${name}-${current_datetime}.${extension}"

  # Output the new file name
  echo "$new_file_name"
}

# Creates a new directory, removing any existing directory with the same name.
create_new_directory() {
  local directory=$1

  # Check if the directory exists and remove it if it does
  if [ -d "$directory" ]; then
    rm -rf "$directory"
    if [ $? -eq 0 ]; then
      echo "The [$directory] directory was removed successfully."
    else
      echo "An error occurred while removing the [$directory] directory."
      exit -1
    fi
  fi

  # Create the new directory
  mkdir -p "$directory"
  if [ $? -eq 0 ]; then
    echo "The [$directory] directory was created successfully."
  else
    echo "An error occurred while creating the [$directory] directory."
    exit -1
  fi
}

# Removes a directory and all its subdirectories and files.
remove_directory() {
  local directory=$1

  # Check if the directory exists
  if [ -d "$directory" ]; then
    # Remove the directory and its contents
    rm -rf "$directory"
    if [ $? -eq 0 ]; then
      echo "The [$directory] directory and its contents were removed successfully."
    else
      echo "An error occurred while removing the [$directory] directory."
      exit -1
    fi
  else
    echo "The [$directory] directory does not exist."
    exit -1
  fi
}

# Unzips an archive file to a specified directory.
unzip_archive() {
  local archiveFilePath=$1
  local destinationDirectory=$2

  echo "Unzipping the [$archiveFilePath] archive to [$destinationDirectory] directory..."
  unzip -q -o "$archiveFilePath" -d "$destinationDirectory"

  if [ $? -eq 0 ]; then
    echo "The archive was unzipped successfully to [$destinationDirectory] directory."
  else
    echo "An error occurred while unzipping the archive to [$destinationDirectory] directory."
    exit -1
  fi
}
```

### Step 03: Assign Value to Variables

Before you run the script, make sure each variable below has the right value. Each variable has a description to help you understand what it does.

> [!NOTE]
> Some variables already have default values that might not need changing. However, you can modify them to suit your needs, like changing the names of your Azure resources.

When you run the script from the command line, you can pass the values for each variable as named arguments. For example:

```bash
./deploy.sh --resourceGroupName "ai-rg" --location "eastus"
```

> [!NOTE]
> Alternatively, you can set the values directly in the script by replacing the default variable values.

```bash
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
```

### Step 04: Install Necessary Tools and Packages

In this step, we will install the tools and packages we need. To do this, we include the `functions.sh` file in our script and run the commands to check and install each tool, if it is not already present.

```bash
# Check and install unzip if not present
install_unzip

# Check and install yq if not present
install_yq

# Check and install python and pip if not present
install_python_and_pip

# Check and install promptflow tool if not present
install_promptflow
```

### Step 05: Unzip the Prompt Flow Archive and Update the Configuration

In this step, we unzip the prompt flow archive and update the `flow.dag.yaml` configuration file within with the necessary variables before deploying.

The script performs the following steps:

1. Create a temporary directory to store the extracted prompt flow files.
2. Extract the prompt flow archive located at the path given by the `promptFlowFilePath` variable into our temporary directory.
3. Update the `flow.dag.yaml` file with the correct container names using a function called `set_yaml_field`, defined in the `functions.sh` file using [yq](https://mikefarah.gitbook.io/yq).

```bash
# Creates a temporary directory for the prompt flow
create_new_directory $tempDirectory

# Unzip the archive containing the prompt flow
unzip_archive $promptFlowFilePath "$tempDirectory/$promptFlowName"

# Get the flow.dag.yaml file path
yamlFileName="$tempDirectory/$promptFlowName/flow.dag.yaml"
```

In the following snippet, we update the Azure OpenAI Service connection in the YAML file based on the `useExistingConnection` variable. If `useExistingConnection` is set to true, we:

1. Find Azure OpenAI connection in the YAML file.
2. If found, update the connection name and model deployment name with the `aoaiConnectionName` and `aoaiDeploymentName` variables, respectively.

```bash
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
```

### Step 06: Create the Prompt Flow in Azure AI Studio (Optional)

The following steps are optional to help you create the prompt flow scenario in Azure AI Studio. These steps are helpful for reviewing and testing the prompt flow, but are not required for deploying, running, or monitoring it.

The script performs the following steps when the variable `createPromptFlowInAzureAiStudio` is set to `true`:

1. Checks if the prompt flow, named by the variable `promptFlowName`, already exists in your project workspace, named by `projectWorkspaceName`.
2. Gets a list of all prompt flows in the workspace by running the [pfazure flow list](https://microsoft.github.io/promptflow/reference/pfazure-command-reference.html#pfazure-flow-list) command.
3. Check if a prompt flow with your desired name is in the list.
4. If it doesn't find the prompt flow, the script creates a new prompt flow using the [pfazure flow create` command](https://microsoft.github.io/promptflow/reference/pfazure-command-reference.html#pfazure-flow-create). Otherwise, it continues.

```bash
if [ "$createPromptFlowInAzureAiStudio" == "true" ]; then
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
```

### Step 07: Create the Online Endpoint for the Prompt Flow

In this step, we set up an [Azure Machine Learning online endpoint](https://learn.microsoft.com/en-us/azure/machine-learning/concept-endpoints-online?view=azureml-api-2#managed-online-endpoints-vs-kubernetes-online-endpoints) to manage and expose our prompt flow. It follows these steps:

1. Create a YAML file called `endpoint.yaml` within the temporary directory to define the configuration of the Azure Machine Learning online endpoint. This file specifies `aad_token` as the authentication mode. For more information, see [CLI (v2) online endpoint YAML schema](https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-endpoint-online?view=azureml-api-2).
2. Check whether the specified Azure Machine Learning online endpoint already exists in the resource group using the [az ml online-endpoint show](https://learn.microsoft.com/en-us/cli/azure/ml/online-endpoint?view=azure-cli-latest#az-ml-online-endpoint-show) command.
3. If the endpoint exists and the `updateExistingEndpoint` variable is set to `true`, the script updates the existing endpoint using the [az ml online-endpoint update](https://learn.microsoft.com/en-us/cli/azure/ml/online-endpoint?view=azure-cli-latest#az-ml-online-endpoint-update) command with the previously created YAML file.
4. If the endpoint doesn't exist, the script creates a new Azure Machine Learning online endpoint using the [az ml online-endpoint create1](https://learn.microsoft.com/en-us/cli/azure/ml/online-endpoint?view=azure-cli-latest#az-ml-online-endpoint-create) command using the YAML file.

```bash
# Create a YAML file with the definition of the Azure Machine Learning online endpoint used to expose the prompt flow
yamlFileName="$tempDirectory/endpoint.yaml"
cat <<EOL >$yamlFileName
\$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineEndpoint.schema.json
auth_mode: aad_token
properties:
  enforce_access_to_default_secret_stores: enabled
tags:
  AllowlistedObjectIds: "$principalId"
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
```

### Step 08: Create Role Assignment and Diagnostic Settings

This part of the script automates the setup of an Azure Machine Learning (AML) online endpoint. It ensures the endpoint has the right permissions and diagnostic settings for smooth operation. The script performs the following steps:

1. Retrieve information about the specified AML endpoint using the [az ml online-endpoint show](https://learn.microsoft.com/en-us/cli/azure/ml/online-endpoint?view=azure-cli-latest#az-ml-online-endpoint-show) command. It extracts the endpoint's resource ID, principal ID, and scoring URI using `jq`.
2. Retrieve the resource ID of the specified Azure AI Services account using the [az cognitiveservices account show](https://learn.microsoft.com/en-us/cli/azure/cognitiveservices/account?view=azure-cli-latest#az-cognitiveservices-account-show) command.
3. Verify whether the managed identity of the AML endpoint has the [Cognitive Services OpenAI User](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/role-based-access-control#cognitive-services-openai-user) role assigned with the Azure AI Services account scope. If not, assign the role using the [az role assignment create](https://learn.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create) command.
4. Retrieve the resource ID of the specified project workspace using the [az ml workspace show](https://learn.microsoft.com/en-us/cli/azure/ml/workspace?view=azure-cli-latest#az-ml-workspace-show) command.
5. Verify whether the managed identity of the AML online endpoint has the [Azure Machine Learning Workspace Connection Secrets Reader](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-online-endpoint-with-secret-injection?view=azureml-api-2&tabs=sai#optional-assign-a-role-to-the-user-identity) role assigned with the project workspace scope. If not, assign the role using the [az role assignment create](https://learn.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create) command.
6. Verify the existence of a specified Log Analytics workspace. If the workspace doesn't exist, create it using the [az monitor log-analytics workspace create](https://learn.microsoft.com/en-us/cli/azure/monitor/log-analytics/workspace?view=azure-cli-latest#az-monitor-log-analytics-workspace-create) command.
7. Setup a diagnostic setting for the AML endpoint using the [az monitor diagnostic-settings create](https://learn.microsoft.com/en-us/cli/azure/monitor/diagnostic-settings?view=azure-cli-latest#az-monitor-diagnostic-settings-create) command. This setting includes configurations for logging and traffic metrics, associating them with the Log Analytics workspace.

This script ensures that the AML online endpoint is set up correctly with the necessary permissions and diagnostic settings. It includes checks to verify each step and handles errors gracefully by providing appropriate messages if any step fails.

```bash
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
```

### Step 09: Create a Model for the Prompt Flow

The next step guides you through setting up an [Azure Machine Learning (AML) model](https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-model?view=azureml-api-2) for the prompt flow. The script checks for the existence of the specified AML model in the project workspace and creates it if it doesn't already exist.

The script performs the following steps:

1. Verify whether the AML model, identified by the variable `modelName`, already exists in the specified project workspace using the [az ml model show](https://learn.microsoft.com/en-us/cli/azure/ml/model?view=azure-cli-latest#az-ml-model-show) command.
2. If the model doesn't exist, generate a YAML configuration file called `model.yaml` in the temporary directory. This file contains the model's schema, name, version, path, description, and properties.
3. Create the AML model using the [az ml model create](https://learn.microsoft.com/en-us/cli/azure/ml/model?view=azure-cli-latest#az-ml-model-create) command with the generated YAML file.

```bash
# Check whether the Azure Machine Learning model already exists in the project workspace
echo "Checking whether the [$modelName] Azure Machine Learning model already exists in the [$projectWorkspaceName] project workspace..."
az ml model show \
  --name $modelName \
  --version $modelVersion \
  --workspace-name $projectWorkspaceName \
  --resource-group $resourceGroupName \
  --only-show-errors  &>/dev/null

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
```

### Step 11: Create an Environment for the Prompt Flow

In this step, we check if a specific [Azure Machine Learning (AML) environment](https://learn.microsoft.com/en-us/azure/machine-learning/concept-environments?view=azureml-api-2) exists in our project workspace and create it if it doesn't.

The script first checks if the AML environment, identified by the `environmentName` and `environmentVersion`, already exists in the project workspace. This is done using the [az ml environment show](https://learn.microsoft.com/en-us/cli/azure/ml/environment?view=azure-cli-latest#az-ml-environment-show) command.

If it doesn't exist, the script runs the following steps:

1. Generate a YAML configuration file called `environment.yaml` in the temporary directory. This file contains the schema, name, version, Docker image, description, and inference configuration details for the environment.
2. Create the AML environment using the [az ml environment create](https://learn.microsoft.com/en-us/cli/azure/ml/environment?view=azure-cli-latest#az-ml-environment-create) command with the generated YAML file.

```bash
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
```

### Step 12: Create a Managed Online Deployment for the Prompt Flow

Next, we go through how to manage the deployment of an [Azure Machine Learning (AML) managed online deployment](https://learn.microsoft.com/en-us/azure/machine-learning/concept-endpoints-online?view=azureml-api-2#managed-online-endpoints-vs-kubernetes-online-endpoints). This involves checking if a deployment exists and updating it or creating a new one if needed.

The following steps are then performed:

1. Create a YAML configuration file named `deployment.yaml` for the AML managed online deployment. This file includes important details such as the schema URL, deployment name, endpoint name, model and environment details, instance type, instance count, and various settings that control the deployment. For more information, see [CLI (v2) managed online deployment YAML schema](https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-deployment-managed-online?view=azureml-api-2).
2. Check if the specified AML managed online deployment already exists using the [az ml online-deployment show](https://learn.microsoft.com/en-us/cli/azure/ml/online-deployment?view=azure-cli-latest#az-ml-online-deployment-show) command.
3. If the deployment exists and the `updateExistingDeployment` variable is set to `true`, update the existing deployment using the [az ml online-deployment update](https://learn.microsoft.com/en-us/cli/azure/ml/online-deployment?view=azure-cli-latest#az-ml-online-deployment-update) command.
4. If the deployment doesn't exist, create a new AML managed online deployment using the [az ml online-deployment create](https://learn.microsoft.com/en-us/cli/azure/ml/online-deployment?view=azure-cli-latest#az-ml-online-deployment-create) command with the previously generated YAML file.

```bash
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
```

## Call the Prompt Flow

This section explains the steps followed by the `call.sh` Bash script call the prompt flow via a REST service exposed by the online endpoint.

### Step 01: Include `functions.sh` File

In this step, we incorporate the [functions.sh](./functions.sh) file that contains some helper functions to automate some tasks.

```bash
# Include functions
source ./functions.sh
```

### Step 02: Assign Value to Variables

Before you run the script, make sure each variable below has the right value. Each variable has a description to help you understand what it does.

> [!NOTE]
> Some variables already have default values that might not need changing. However, you can modify them to suit your needs, like changing the names of your Azure resources.

When you run the script from the command line, you can pass the values for each variable as named arguments. For example:

```bash
./call.sh --resourceGroupName "ai-rg" --endpointName "test-chat-flow-endpoint" --projectWorkspaceName "moon-project-test" --question "Tell me about Pisa in Tuscany, Italy"
```

> [!NOTE]
> Alternatively, you can set the values directly in the script by replacing the default variable values.

```bash
# Variables
# Variables
declare -A variables=(
  # Specifies the name of the Azure Resource Group that contains your resources.
  [resourceGroupName]="ai-rg"

  # Specifies the name of the Azure Machine Learning model used by the prompt flow.
  [endpointName]="test-chat-flow-endpoint"

  # Specifies the name of the project workspace.
  [projectWorkspaceName]="moon-project-test"

  # Specifies the question to send to the chat prompt flow exposed via the online endpoint.
  [question]="Tell me about Pisa in Tuscany, Italy"

  # Specifies whether to retrieve the OpenAPI schema of the online endpoint.
  [retrieveOpenApiSchema]="true"

  # Specifies whether to enable debug mode (displays additional information during script execution).
  [debug]="true"
)

# Parse the arguments
parse_args variables $@
```

### Step 03: Retrieve a JWT Security Token

In this step, the script executes the [az ml online-endpoint get-credentials](https://learn.microsoft.com/en-us/cli/azure/ml/online-endpoint?view=azure-cli-latest#az-ml-online-endpoint-get-credentials) command to obtain a JWT security token from Microsoft Entra ID. This token is essential for authenticating with the online endpoint configured to use `aad_token` authentication mode. For further details, refer to the following articles:

- [Authenticate clients for online endpoints](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-authenticate-online-endpoint?view=azureml-api-2&tabs=azure-cli#assign-permissions-to-the-identity)
- [Troubleshooting online endpoints deployment and scoring](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-troubleshoot-online-endpoints?view=azureml-api-2&tabs=cli#http-status-codes)

```bash
# Get a security token to call the online endpoint
echo "Getting a security token to call the [$endpointName] online endpoint..."
securityToken=$(az ml online-endpoint get-credentials \
  --name $endpointName \
  --resource-group $resourceGroupName \
  --workspace-name $projectWorkspaceName \
  --output tsv \
  --query accessToken \
  --only-show-errors)

if [ -n "$securityToken" ]; then
  echo "Successfully retrieved the security token to call the [$endpointName] online endpoint"
else
  echo "Failed to retrieve the security token to call the [$endpointName] online endpoint"
  exit -1
fi
```

### Step 04: Retrieve the OpenAPI Schema of the REST Service

In this step, if the value of `retrieveOpenApiSchema` equals `true`, the script executes the [`az ml online-endpoint show`](https://learn.microsoft.com/en-us/cli/azure/ml/online-endpoint?view=azure-cli-latest#az-ml-online-endpoint-show) command to retrieve the URI of the [OpenAPI](https://learn.openapis.org/) schema of the online endpoint.

Next, the script utilizes the `curl` tool with the JWT security token in the `Authorization` header to retrieve the OpenAPI schema using the URI obtained in the previous step.

```bash
if [ "$retrieveOpenApiSchema" == "true" ]; then
  # Get the OpenAPI URI of the online endpoint
  echo "Getting the OpenAPI URI of the [$endpointName] online endpoint..."
  openApiUri=$(az ml online-endpoint show \
    --name $endpointName \
    --resource-group $resourceGroupName \
    --workspace-name $projectWorkspaceName \
    --query openapi_uri \
    --output tsv \
    --only-show-errors)

  if [ -n "$openApiUri" ]; then
    echo "Successfully retrieved the [$openApiUri] OpenAPI URI of the [$endpointName] online endpoint"
  else
    echo "Failed to retrieve the OpenAPI URI of the [$endpointName] online endpoint"
    exit -1
  fi

  # Retrieve the OpenAPI schema of the online endpoint
  echo "Retrieving the OpenAPI schema of the [$endpointName] online endpoint..."
  statuscode=$(
    curl \
      --silent \
      --request GET \
      --url $openApiUri \
      --header "Authorization: Bearer $securityToken" \
      --header "Content-Type: application/json" \
      --header 'accept: application/json' \
      --write-out "%{http_code}" \
      --output >(cat >/tmp/curl_body)
  ) || code="$?"

  body="$(cat /tmp/curl_body)"

  if [[ $statuscode == 200 ]]; then
    echo "OpenAPI schema for the [$endpointName] online endpoint successfully retrieved"
  else
    echo "Failed to retrieve the OpenAPI schema for the [$endpointName] online endpoint"
    echo "Status code: $statuscode"
  fi

  if [[ -n $body ]]; then
    echo $body | jq .
  fi
fi
```

### Step 05: Call the Prompt Flow via the REST Service

In this step, the script runs the [`az ml online-endpoint show`](https://learn.microsoft.com/en-us/cli/azure/ml/online-endpoint?view=azure-cli-latest#az-ml-online-endpoint-show) command to obtain the URI of the scoring endpoint used to trigger the prompt flow.

Next, the script constructs a payload for the prompt flow using the format specified by the OpenAPI schema of the REST service. Finally, it uses the `curl` tool, including the JWT security token in the `Authorization` header, to send the payload via the POST method to the scoring endpoint. If the call is successful, the script prints the answer found in the response message.

```bash
# Get the scoring URI of the online endpoint
echo "Getting the scoring URI of the [$endpointName] online endpoint..."
scoringUri=$(az ml online-endpoint show \
  --name $endpointName \
  --resource-group $resourceGroupName \
  --workspace-name $projectWorkspaceName \
  --query scoring_uri \
  --output tsv \
  --only-show-errors)

if [ -n "$scoringUri" ]; then
  echo "Successfully retrieved the [$scoringUri] scoring URI of the [$endpointName] online endpoint"
else
  echo "Failed to retrieve the scoring URI of the [$endpointName] online endpoint"
  exit -1
fi

# Create the payload
IFS='' read -r -d '' payload <<EOF
{
    "question": "$question",
    "chat_history": []
}
EOF

if [ "$debug" == "true" ]; then
  # Print the request payload
  echo "Request payload:"
  echo $payload | jq .
fi

# Call the online endpoint
echo "Calling the [$endpointName] online endpoint..."

statuscode=$(
  curl \
    --silent \
    --request POST \
    --url $scoringUri \
    --header "Authorization: Bearer $securityToken" \
    --header "Content-Type: application/json" \
    --header 'accept: application/json' \
    --data "${payload}" \
    --write-out "%{http_code}" \
    --output >(cat >/tmp/curl_body)
) || code="$?"

body="$(cat /tmp/curl_body)"

if [[ $statuscode == 200 ]]; then
  echo "Successfully called the [$endpointName] online endpoint"
else
  echo "Failed to call the [$endpointName] online endpoint"
  echo "Status code: $statuscode"
fi

if [[ -n $body ]]; then
  echo $body | jq .answer
fi
```
