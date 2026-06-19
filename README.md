# Encurtador de Links - Azure Functions URL Shortener

A serverless URL shortening service built with Azure Functions, designed for scalability, reliability, and comprehensive access logging.

## Features

- **URL Shortening**: Convert long URLs into short, shareable codes
- **URL Redirection**: Redirect from short codes to original URLs with HTTP 302
- **Access Logging**: Track all redirects with client IP addresses via Application Insights
- **Collision Handling**: Automatic detection and resolution of short code collisions
- **Idempotency**: Same URL always generates the same short code
- **Serverless**: Auto-scaling on Azure with pay-as-you-go pricing

## Architecture

### Components

- **Azure Functions (Consumption Plan)**: Serverless compute for HTTP endpoints
- **Azure Table Storage**: Key-value store for URL mappings
- **Application Insights**: Distributed logging and monitoring
- **Azure Service Bus (optional)**: For async processing

### Technologies

- **.NET 8**: Modern C# implementation
- **Azure SDK**: Official Azure client libraries
- **Application Insights SDK**: Structured logging and telemetry

## Endpoints

### POST /api/shorten
Shortens a URL and returns a short code.

**Request:**
```json
{
  "url": "https://example.com/very/long/path/to/resource"
}
```

**Response (200 OK):**
```json
{
  "shortCode": "abc123",
  "shortUrl": "http://localhost:7071/api/redirect/abc123"
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "Invalid or missing URL"
}
```

### GET /api/redirect/{shortCode}
Redirects to the original URL and logs the access.

**Response:**
- HTTP 302 Found with Location header pointing to original URL
- Access logged to Application Insights with client IP

**Error Response (404 Not Found):**
```json
{
  "error": "Short code not found"
}
```

## Prerequisites for Deployment

### Local Development

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure Functions Core Tools v4](https://github.com/Azure/azure-functions-core-tools)
- [Azure Storage Emulator](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-emulator) or Azurite
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)
- PowerShell or Bash

### Azure Resources

- Azure Subscription with sufficient quota
- Resource Group for organizing resources
- Azure Storage Account for table storage
- Application Insights instance for logging

## Local Development Setup

### 1. Install Dependencies

```bash
dotnet restore
```

### 2. Start Azure Storage Emulator

Using Azurite (recommended):
```bash
npm install -g azurite
azurite --silent
```

Or Docker:
```bash
docker run -p 10000:10000 -p 10001:10001 -p 10002:10002 mcr.microsoft.com/azure-storage/azurite
```

### 3. Configure local.settings.json

The `local.settings.json` file is already configured for local development:
- `AzureWebJobsStorage`: Points to local storage emulator
- `TableStorageConnection`: Points to local storage emulator
- `ShortUrlBaseUrl`: Base URL for shortened links (localhost)

For production, you'll need to update these with actual Azure connection strings.

### 4. Run Locally

```bash
func start
```

The function will be available at:
- POST http://localhost:7071/api/shorten
- GET http://localhost:7071/api/redirect/{shortCode}

### 5. Test with cURL

**Create a short URL:**
```bash
curl -X POST http://localhost:7071/api/shorten \
  -H "Content-Type: application/json" \
  -d '{"url":"https://github.com/microsoft/azure-functions"}'
```

**Use a short URL:**
```bash
curl -i http://localhost:7071/api/redirect/abc123
```

## Azure Deployment

### 1. Create Azure Resources

```bash
# Set variables
$resourceGroup = "rg-encurtador-links"
$location = "eastus"
$storageAccount = "saencurtadorlinks"
$functionApp = "func-encurtador-links"
$appInsights = "appi-encurtador-links"

# Create resource group
az group create --name $resourceGroup --location $location

# Create storage account
az storage account create \
  --resource-group $resourceGroup \
  --name $storageAccount \
  --location $location \
  --sku Standard_LRS

# Create table storage table
az storage table create \
  --account-name $storageAccount \
  --name UrlMappings

# Create Application Insights
az monitor app-insights component create \
  --app $appInsights \
  --location $location \
  --resource-group $resourceGroup \
  --application-type web

# Create Function App
az functionapp create \
  --resource-group $resourceGroup \
  --consumption-plan-location $location \
  --runtime dotnet-isolated \
  --runtime-version 8 \
  --functions-version 4 \
  --name $functionApp \
  --storage-account $storageAccount
```

### 2. Configure Function App Settings

```bash
# Get storage connection string
$storageConnectionString=$(az storage account show-connection-string \
  --name $storageAccount \
  --resource-group $resourceGroup \
  --query connectionString \
  -o tsv)

# Get Application Insights connection string
$appInsightsConnectionString=$(az monitor app-insights component show \
  --app $appInsights \
  --resource-group $resourceGroup \
  --query connectionString \
  -o tsv)

# Update function app settings
az functionapp config appsettings set \
  --resource-group $resourceGroup \
  --name $functionApp \
  --settings \
  TableStorageConnection="$storageConnectionString" \
  APPLICATIONINSIGHTS_CONNECTION_STRING="$appInsightsConnectionString" \
  ShortUrlBaseUrl="https://$functionApp.azurewebsites.net"
```

### 3. Deploy the Function

```bash
# Publish the function
func azure functionapp publish $functionApp

# Or using dotnet CLI
dotnet publish -c Release -o ./bin/publish
cd ./bin/publish
func azure functionapp publish $functionApp --build-native-deps
```

### 4. Test the Deployed Function

```bash
$functionUrl = "https://$functionApp.azurewebsites.net"

# Create short URL
curl -X POST "$functionUrl/api/shorten" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}'

# Test redirect
curl -i "$functionUrl/api/redirect/{shortCode}"
```

## Monitoring and Logging

### Application Insights

Access logs and metrics in Azure Portal:
1. Go to Application Insights resource
2. View "Logs" to query custom events
3. Check "Metrics" for performance data
4. Review "Live Metrics" for real-time data

### Sample Kusto Query Language (KQL)

**All URL access events:**
```kql
customEvents
| where name == "UrlAccess"
| project TimeGenerated=timestamp, ClientIp=tostring(customDimensions.ClientIp), ShortCode=tostring(customDimensions.ShortCode), StatusCode=tostring(customDimensions.StatusCode)
| order by TimeGenerated desc
```

**Redirects by IP:**
```kql
customEvents
| where name == "UrlAccess" and customDimensions.StatusCode == "302"
| summarize AccessCount=count() by ClientIp=tostring(customDimensions.ClientIp)
| top 10 by AccessCount
```

## Maintenance and Operations

### Monitoring

- Set up alerts on Application Insights for failed requests
- Monitor function execution time and memory usage
- Track storage account performance metrics

### Scaling

Azure Functions automatically scales based on demand. No configuration needed for consumption plan.

### Updating Code

```bash
# Make code changes
# Rebuild
dotnet build

# Test locally
func start

# Deploy updated code
func azure functionapp publish $functionApp
```

## Privacy and Compliance

### IP Logging

- Client IP addresses are logged for every redirect
- IPs are stored in Application Insights logs
- Azure Application Insights follows Azure Privacy & Security guidelines
- Data is stored in the same region as your resources

### Data Retention

- Configure Application Insights data retention (default: 90 days)
- Set data filtering rules to exclude sensitive information
- Implement GDPR compliance by implementing data deletion endpoints if needed

## Troubleshooting

### Deployment Issues

**Error: "Storage connection string not found"**
- Ensure `TableStorageConnection` is set in function app settings
- Verify storage account exists and is accessible

**Error: "Table 'UrlMappings' not found"**
- Create the table using Azure Portal or CLI
- Verify table storage account is connected

### Runtime Issues

**Short codes not persisting**
- Check Application Insights logs for storage errors
- Verify table storage connection string in function app settings
- Check storage account quota and permissions

**IP logging shows "unknown"**
- This is expected for direct connections
- In production, requests typically have X-Forwarded-For header from load balancer
- Check request headers in Application Insights

## Development Roadmap

- [ ] Custom vanity codes (e.g., `/my-campaign`)
- [ ] API authentication and rate limiting
- [ ] URL expiration/TTL support
- [ ] Click analytics dashboard
- [ ] QR code generation
- [ ] Bulk URL shortening API
- [ ] Admin endpoints for URL deletion

## Contributing

1. Clone the repository
2. Make your changes
3. Test locally with `func start`
4. Run `dotnet build` to verify compilation
5. Submit a pull request

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Support

For issues, questions, or suggestions:
1. Check existing GitHub issues
2. Create a new issue with detailed description
3. Provide error messages and reproduction steps
