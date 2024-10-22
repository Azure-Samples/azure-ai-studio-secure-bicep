---
page_type: sample
languages:
- bash
- bicep
- python
- json
products:
- azure
- azure-openai
- azure-machine-learning-studio
- azure-resource-manager
- azure-container-registry
- azure-storage
- azure-blob-storage
- azure-storage-accounts
- azure-bastion
- azure-private-link
- azure-virtual-network
- azure-key-vault
- azure-monitor
- azure-log-analytics
- azure-virtual-machines
name:  Deploy Secure Azure AI Studio via Bicep
description: This repository contains a collection of Bicep modules designed to deploy a secure Azure AI Studio environment with robust network and identity security restrictions.
urlFragment: azure-ai-studio-secure-bicep
azureDeploy: "https://raw.githubusercontent.com/Azure-Samples/azure-ai-studio-secure-bicep/main/bicep/managedvnet/azuredeploy.json"
---

# Deploy Secure Azure AI Studio via Bicep

This collection of `Bicep` templates demonstrates how to set up an [Azure AI Studio](https://learn.microsoft.com/en-us/azure/ai-studio/what-is-ai-studio) environment with or without a managed network and with managed identity and Azure RBAC to connected [Azure AI Services](https://learn.microsoft.com/en-us/azure/ai-services/what-are-ai-services) and dependent resources.

## Deploy Secure Azure AI Studio without a managed virtual network

The collection of [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/file) templates located in the [bicep/novnet](./bicep/novnet/README.md) folder demonstrates how to configure an [Azure AI Studio](https://learn.microsoft.com/en-us/azure/ai-studio/what-is-ai-studio) environment with managed identity and Azure RBAC for connecting to [Azure AI Services](https://learn.microsoft.com/en-us/azure/ai-services/what-are-ai-services) and dependent resources. For more details and deployment instructions, see [Deploy Secure Azure AI Studio without a managed virtual network](./bicep/novnet/README.md).

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-ai-studio-secure-bicep%2Fmain%2Fbicep%2Fnovnet%2Fmain.bicep)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-ai-studio-secure-bicep%2Fmain%2Fbicep%2Fnovnet%2Fmain.bicep)

![Architecture with no managed virtual network](./images/no-managed-virtual-network.png)

## Deploy Secure Azure AI Studio with a managed virtual network

The collection of [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/file) templates under the [bicep/managedvnet](./bicep/managedvnet/README.md) folder demonstrates how to set up an [Azure AI Studio](https://learn.microsoft.com/en-us/azure/ai-studio/what-is-ai-studio) environment with managed identity and Azure RBAC to connected [Azure AI Services](https://learn.microsoft.com/en-us/azure/ai-services/what-are-ai-services) and dependent resources, with the managed virtual network isolation mode set to [Allow Internet Outbound](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/configure-managed-network). For more details and deployment instructions, see [Deploy Secure Azure AI Studio with a managed virtual network](./bicep/managedvnet/README.md).

> For more information on the network topology, see [How to configure a managed network for Azure AI Studio hubs](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/configure-managed-network).

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-ai-studio-secure-bicep%2Fmain%2Fbicep%2managedvnet%2FFmain.bicep)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-ai-studio-secure-bicep%2Fmain%2Fbicep%2Fmanagedvnet%2Fmain.bicep)

![Architecture with managed virtual network](./images/managed-virtual-network.png)

### How to Test

By following these steps, you will have Azure AI Studio set up and ready for your projects using Bicep. If you encounter any issues, refer to the additional resources or seek help from the Azure support team.

After deploying the resources, you can verify the deployment by checking the [Azure Portal](https://portal.azure.com) or [Azure AI Studio](https://ai.azure.com/build). Ensure all the resources are created and configured correctly.

You can also follow these [instructions](./promptflow/README.md) to deploy, expose, and call the [Basic Chat](https://github.com/microsoft/promptflow/tree/main/examples/flows/chat/chat-basic) prompt flow using Bash scripts and Azure CLI.

![Prompt Flow](./images/prompt-flow.png)

## Learn More

For more information, see:

- [Azure AI Studio Documentation](https://aka.ms/aistudio/docs)
