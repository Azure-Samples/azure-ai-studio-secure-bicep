#!/bin/bash

# Include functions
source ../../projects/scripts/functions.sh

# Variables
declare -A variables=(
  [template]="main.bicep"
  [parameters]="main.bicepparam"
  [resourceGroupName]="rg-speech-analytics"
  [location]="eastus"
  [validateTemplate]=0
  [useWhatIf]=0
)

subscriptionName=$(az account show --query name --output tsv)
parse_args variables $@

# Validates if the resource group exists in the subscription, if not creates it
echo "Checking if [$resourceGroupName] resource group exists in the [$subscriptionName] subscription..."
az group show --name $resourceGroupName &>/dev/null

if [[ $? != 0 ]]; then
  echo "No [$resourceGroupName] resource group exists in the [$subscriptionName] subscription"
  echo "Creating [$resourceGroupName] resource group in the [$subscriptionName] subscription..."

  # Create the resource group
  az group create --name $resourceGroupName --location $location 1>/dev/null

  if [[ $? == 0 ]]; then
    echo "[$resourceGroupName] resource group successfully created in the [$subscriptionName] subscription"
  else
    echo "Failed to create [$resourceGroupName] resource group in the [$subscriptionName] subscription"
    exit
  fi
else
  echo "[$resourceGroupName] resource group already exists in the [$subscriptionName] subscription"
fi

# Validates the Bicep template
if [[ $validateTemplate == 1 ]]; then
  if [[ $useWhatIf == 1 ]]; then
    # Execute a deployment What-If operation at resource group scope.
    echo "Previewing changes deployed by [$template] Bicep template..."
    az deployment group what-if \
      --resource-group $resourceGroupName \
      --template-file $template \
      --parameters $parameters \
      --parameters \
      location=$location

    if [[ $? == 0 ]]; then
      echo "[$template] Bicep template validation succeeded"
    else
      echo "Failed to validate [$template] Bicep template"
      exit
    fi
  else
    # Validate the Bicep template
    echo "Validating [$template] Bicep template..."
    output=$(az deployment group validate \
      --resource-group $resourceGroupName \
      --template-file $template \
      --parameters $parameters \
      --parameters \
      location=$location)

    if [[ $? == 0 ]]; then
      echo "[$template] Bicep template validation succeeded"
    else
      echo "Failed to validate [$template] Bicep template"
      echo $output
      exit
    fi
  fi
fi

# Deploy the Bicep template
echo "Deploying [$template] Bicep template..."
deploymentOutputs=$(az deployment group create \
  --resource-group $resourceGroupName \
  --only-show-errors \
  --template-file $template \
  --parameters $parameters \
  --parameters location=$location \
  --query 'properties.outputs' -o json)

# Write the outputs to a file in ../../docs/.azureml/config.json
set_configuration_file_object_variable() {
  local key=$1
  local value=$2
  local file="../../docs/.azureml/config.json"

  if [[ ! -f $file ]]; then
    echo "{}" >$file
  fi

  if [[ -f $file ]]; then
    jq ".$key = \"$value\"" $file >$file.tmp && mv $file.tmp $file
  else
    echo "Failed to write the [$key] output to the [$file] file"
    exit
  fi
}

deploymentOutputs=$(echo $deploymentOutputs | jq -r 'to_entries | map({(.key): .value.value}) | add')

subscription_id=$(echo $deploymentOutputs | jq -r '.deploymentInfo.subscriptionId')
resource_group=$(echo $deploymentOutputs | jq -r '.deploymentInfo.resourceGroupName')
location=$(echo $deploymentOutputs | jq -r '.deploymentInfo.location')
storage_account_name=$(echo $deploymentOutputs | jq -r '.deploymentInfo.storageAccountName')
ai_services_name=$(echo $deploymentOutputs | jq -r '.deploymentInfo.aiServicesName')
ai_services_endpoint=$(echo $deploymentOutputs | jq -r '.deploymentInfo.aiServicesEndpoint')
hub_name=$(echo $deploymentOutputs | jq -r '.deploymentInfo.hubName')
speech_analytics_project_name=$(echo $deploymentOutputs | jq -r '.deploymentInfo.projectName')
genai_project_name=$(echo $deploymentOutputs | jq -r '.deploymentInfo.genAIProjectName')
input_container_name=$(echo $deploymentOutputs | jq -r '.deploymentInfo.inputContainerName')
transcription_container_name=$(echo $deploymentOutputs | jq -r '.deploymentInfo.transcriptionContainerName')
analytics_container_name=$(echo $deploymentOutputs | jq -r '.deploymentInfo.analyticsContainerName')
error_output_container_name=$(echo $deploymentOutputs | jq -r '.deploymentInfo.errorOutputContainerName')
processed_output_container_name=$(echo $deploymentOutputs | jq -r '.deploymentInfo.processedOutputContainerName')

set_configuration_file_object_variable "subscription_id" $subscription_id
set_configuration_file_object_variable "resource_group" $resource_group
set_configuration_file_object_variable "location" $location
set_configuration_file_object_variable "storage_account_name" $storage_account_name
set_configuration_file_object_variable "ai_services_name" $ai_services_name
set_configuration_file_object_variable "ai_services_endpoint" $ai_services_endpoint
set_configuration_file_object_variable "hub_name" $hub_name
set_configuration_file_object_variable "speech_analytics_project_name" $speech_analytics_project_name
set_configuration_file_object_variable "genai_project_name" $genai_project_name
set_configuration_file_object_variable "input_container_name" $input_container_name
set_configuration_file_object_variable "transcription_container_name" $transcription_container_name
set_configuration_file_object_variable "analytics_container_name" $analytics_container_name
set_configuration_file_object_variable "error_output_container_name" $error_output_container_name
set_configuration_file_object_variable "processed_output_container_name" $processed_output_container_name