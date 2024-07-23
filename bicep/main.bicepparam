using './main.bicep'

param prefix = 'secure'
param suffix = 'test'
param userObjectId = '<user-object-id>'
param keyVaultEnablePurgeProtection = false
param acrEnabled = true
param openAiDeployments = [
  {
    model: {
      name: 'text-embedding-ada-002'
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: 1
    }
  }
  {
    model: {
      name: 'gpt-4o'
      version: '2024-05-13'
    }
    sku: {
      name: 'GlobalStandard'
      capacity: 1
    }
  }
]
param tags = {
  environment: 'development'
  iac: 'bicep'
}
