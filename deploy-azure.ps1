# Azure Deployment Script for Encurtador de Links
# This script creates all necessary Azure resources and deploys the function

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$Location,

    [Parameter(Mandatory=$false)]
    [string]$FunctionAppName = "func-encurtador-links-$((Get-Random).ToString().Substring(0,5))",

    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName = "saencurtadorlinks$((Get-Random % 1000).ToString('D3'))",

    [Parameter(Mandatory=$false)]
    [string]$AppInsightsName = "appi-encurtador-links",

    [Parameter(Mandatory=$false)]
    [switch]$Deploy = $false,

    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = "."
)

Write-Host "Azure Deployment for Encurtador de Links" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Check Azure CLI
Write-Host "Checking Azure CLI..." -ForegroundColor Cyan
$azVersion = az --version 2>$null
if (-not $azVersion) {
    Write-Host "Azure CLI not found. Please install from https://docs.microsoft.com/en-us/cli/azure/" -ForegroundColor Red
    exit 1
}

# Check Azure subscription
Write-Host "Checking Azure subscription..." -ForegroundColor Cyan
$account = az account show 2>$null
if (-not $account) {
    Write-Host "Not logged in to Azure. Run: az login" -ForegroundColor Red
    exit 1
}
$accountInfo = $account | ConvertFrom-Json
Write-Host "Logged in as: $($accountInfo.user.name)" -ForegroundColor Green
Write-Host "Subscription: $($accountInfo.name)" -ForegroundColor Green
Write-Host ""

# Create resource group
Write-Host "Creating resource group: $ResourceGroup" -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location
if (-not $?) {
    Write-Host "Failed to create resource group" -ForegroundColor Red
    exit 1
}

# Create storage account
Write-Host "Creating storage account: $StorageAccountName" -ForegroundColor Cyan
az storage account create `
    --resource-group $ResourceGroup `
    --name $StorageAccountName `
    --location $Location `
    --sku Standard_LRS `
    --https-only true
if (-not $?) {
    Write-Host "Failed to create storage account" -ForegroundColor Red
    exit 1
}

# Create table storage
Write-Host "Creating table storage: UrlMappings" -ForegroundColor Cyan
$storageConnectionString = az storage account show-connection-string `
    --name $StorageAccountName `
    --resource-group $ResourceGroup `
    --query connectionString -o tsv

az storage table create `
    --account-name $StorageAccountName `
    --name UrlMappings
if (-not $?) {
    Write-Host "Failed to create table storage" -ForegroundColor Red
    exit 1
}

# Create Application Insights
Write-Host "Creating Application Insights: $AppInsightsName" -ForegroundColor Cyan
az monitor app-insights component create `
    --app $AppInsightsName `
    --location $Location `
    --resource-group $ResourceGroup `
    --application-type web
if (-not $?) {
    Write-Host "Failed to create Application Insights" -ForegroundColor Red
    exit 1
}

$appInsightsConnectionString = az monitor app-insights component show `
    --app $AppInsightsName `
    --resource-group $ResourceGroup `
    --query connectionString -o tsv

# Create Function App
Write-Host "Creating Function App: $FunctionAppName" -ForegroundColor Cyan
az functionapp create `
    --resource-group $ResourceGroup `
    --consumption-plan-location $Location `
    --runtime dotnet-isolated `
    --runtime-version 8 `
    --functions-version 4 `
    --name $FunctionAppName `
    --storage-account $StorageAccountName `
    --disable-app-insights false
if (-not $?) {
    Write-Host "Failed to create Function App" -ForegroundColor Red
    exit 1
}

# Configure Function App settings
Write-Host "Configuring Function App settings..." -ForegroundColor Cyan
$functionUrl = "https://$FunctionAppName.azurewebsites.net"

az functionapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $FunctionAppName `
    --settings `
    TableStorageConnection="$storageConnectionString" `
    APPLICATIONINSIGHTS_CONNECTION_STRING="$appInsightsConnectionString" `
    ShortUrlBaseUrl="$functionUrl"

if (-not $?) {
    Write-Host "Failed to configure Function App settings" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Azure Resources Created Successfully!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Green
Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Green
Write-Host "Function App: $FunctionAppName" -ForegroundColor Green
Write-Host "Application Insights: $AppInsightsName" -ForegroundColor Green
Write-Host "Function URL: $functionUrl" -ForegroundColor Green
Write-Host ""

if ($Deploy) {
    Write-Host "Deploying function code..." -ForegroundColor Cyan

    # Build the project
    Write-Host "Building project..." -ForegroundColor Cyan
    Push-Location $ProjectPath
    dotnet publish -c Release -o ./bin/publish
    if (-not $?) {
        Write-Host "Failed to build project" -ForegroundColor Red
        Pop-Location
        exit 1
    }

    # Deploy using func CLI
    Write-Host "Publishing to Azure..." -ForegroundColor Cyan
    func azure functionapp publish $FunctionAppName --build-native-deps
    if (-not $?) {
        Write-Host "Failed to publish function" -ForegroundColor Red
        Pop-Location
        exit 1
    }

    Pop-Location

    Write-Host ""
    Write-Host "Deployment Complete!" -ForegroundColor Green
    Write-Host "Function is live at: $functionUrl" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Test the API:"
    Write-Host "   POST  $functionUrl/api/shorten"
    Write-Host "   GET   $functionUrl/api/redirect/{shortCode}"
    Write-Host "2. Monitor in Application Insights:"
    Write-Host "   https://portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/*/resourceGroups/$ResourceGroup/providers/microsoft.insights/components/$AppInsightsName"
    Write-Host "3. View logs:"
    Write-Host "   az monitor app-insights metrics show --app $AppInsightsName --resource-group $ResourceGroup"
} else {
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. To deploy the function code, run:"
    Write-Host "   $($MyInvocation.ScriptName) -ResourceGroup $ResourceGroup -Location $Location -Deploy"
    Write-Host ""
    Write-Host "2. Or manually deploy using:"
    Write-Host "   func azure functionapp publish $FunctionAppName"
}

Write-Host ""
Write-Host "Cleanup (if needed):" -ForegroundColor Yellow
Write-Host "az group delete --name $ResourceGroup --yes"
