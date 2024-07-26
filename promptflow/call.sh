#!/bin/bash

# Include functions
source ./functions.sh

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
