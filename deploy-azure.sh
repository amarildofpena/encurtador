#!/bin/bash

# Azure Deployment Script for Encurtador de Links
# This script creates all necessary Azure resources and deploys the function

set -e

# Default values
LOCATION=${LOCATION:-"eastus"}
DEPLOY=${DEPLOY:-false}
PROJECT_PATH=${PROJECT_PATH:-"."}
RANDOM_SUFFIX=$((RANDOM % 10000))

# Get parameters
RESOURCE_GROUP=${1:-"rg-encurtador-links"}
FUNCTION_APP_NAME=${2:-"func-encurtador-links-$RANDOM_SUFFIX"}
STORAGE_ACCOUNT_NAME=${3:-"saencurtadorlinks${RANDOM_SUFFIX}"}
APP_INSIGHTS_NAME=${4:-"appi-encurtador-links"}

echo ""
echo "==========================================="
echo "Azure Deployment for Encurtador de Links"
echo "==========================================="
echo ""

# Check Azure CLI
echo "Checking Azure CLI..."
if ! command -v az &> /dev/null; then
    echo "Azure CLI not found. Please install from https://docs.microsoft.com/en-us/cli/azure/"
    exit 1
fi

# Check Azure subscription
echo "Checking Azure subscription..."
ACCOUNT=$(az account show 2>/dev/null) || {
    echo "Not logged in to Azure. Run: az login"
    exit 1
}

ACCOUNT_NAME=$(echo "$ACCOUNT" | jq -r '.user.name')
SUBSCRIPTION_NAME=$(echo "$ACCOUNT" | jq -r '.name')
echo "Logged in as: $ACCOUNT_NAME"
echo "Subscription: $SUBSCRIPTION_NAME"
echo ""

# Create resource group
echo "Creating resource group: $RESOURCE_GROUP"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Create storage account
echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$STORAGE_ACCOUNT_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --https-only true

# Create table storage
echo "Creating table storage: UrlMappings"
az storage table create \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --name UrlMappings

STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query connectionString -o tsv)

# Create Application Insights
echo "Creating Application Insights: $APP_INSIGHTS_NAME"
az monitor app-insights component create \
    --app "$APP_INSIGHTS_NAME" \
    --location "$LOCATION" \
    --resource-group "$RESOURCE_GROUP" \
    --application-type web

APP_INSIGHTS_CONNECTION_STRING=$(az monitor app-insights component show \
    --app "$APP_INSIGHTS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query connectionString -o tsv)

# Create Function App
echo "Creating Function App: $FUNCTION_APP_NAME"
az functionapp create \
    --resource-group "$RESOURCE_GROUP" \
    --consumption-plan-location "$LOCATION" \
    --runtime dotnet-isolated \
    --runtime-version 8 \
    --functions-version 4 \
    --name "$FUNCTION_APP_NAME" \
    --storage-account "$STORAGE_ACCOUNT_NAME" \
    --disable-app-insights false

# Configure Function App settings
echo "Configuring Function App settings..."
FUNCTION_URL="https://$FUNCTION_APP_NAME.azurewebsites.net"

az functionapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$FUNCTION_APP_NAME" \
    --settings \
    "TableStorageConnection=$STORAGE_CONNECTION_STRING" \
    "APPLICATIONINSIGHTS_CONNECTION_STRING=$APP_INSIGHTS_CONNECTION_STRING" \
    "ShortUrlBaseUrl=$FUNCTION_URL"

echo ""
echo "=========================================="
echo "Azure Resources Created Successfully!"
echo "=========================================="
echo ""
echo "Resource Group: $RESOURCE_GROUP"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Function App: $FUNCTION_APP_NAME"
echo "Application Insights: $APP_INSIGHTS_NAME"
echo "Function URL: $FUNCTION_URL"
echo ""

if [ "$DEPLOY" = "true" ]; then
    echo "Deploying function code..."

    # Build the project
    echo "Building project..."
    pushd "$PROJECT_PATH"
    dotnet publish -c Release -o ./bin/publish

    # Deploy using func CLI
    echo "Publishing to Azure..."
    func azure functionapp publish "$FUNCTION_APP_NAME" --build-native-deps

    popd

    echo ""
    echo "=========================================="
    echo "Deployment Complete!"
    echo "=========================================="
    echo "Function is live at: $FUNCTION_URL"
    echo ""
    echo "Next steps:"
    echo "1. Test the API:"
    echo "   POST  $FUNCTION_URL/api/shorten"
    echo "   GET   $FUNCTION_URL/api/redirect/{shortCode}"
    echo "2. Monitor in Application Insights"
    echo "3. View logs: az monitor app-insights metrics show --app $APP_INSIGHTS_NAME --resource-group $RESOURCE_GROUP"
else
    echo "Next steps:"
    echo "1. To deploy the function code, run:"
    echo "   DEPLOY=true $0 $RESOURCE_GROUP $FUNCTION_APP_NAME $STORAGE_ACCOUNT_NAME $APP_INSIGHTS_NAME"
    echo ""
    echo "2. Or manually deploy using:"
    echo "   func azure functionapp publish $FUNCTION_APP_NAME"
fi

echo ""
echo "Cleanup (if needed):"
echo "az group delete --name $RESOURCE_GROUP --yes"
echo ""
