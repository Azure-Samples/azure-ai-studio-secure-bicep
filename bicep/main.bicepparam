using './main.bicep'

param prefix = 'secure'
param suffix = 'test'
param userObjectId = '<user-object-id>'
param keyVaultEnablePurgeProtection = false
param storageAccountCreateContainers = true
param inputContainerName = 'input'
param transcriptionContainerName = 'transcriptions'
param analyticsContainerName = 'analytics'
param errorOutputContainerName = 'errored'
param processedOutputContainerName = 'processed'
param acrEnabled = true
param openAiDeployments = [
  {
    model: {
      name: 'text-embedding-ada-002'
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    model: {
      name: 'gpt-4o'
      version: '2024-05-13'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
]
param tags = {
  environment: 'development'
  iac: 'bicep'
}
