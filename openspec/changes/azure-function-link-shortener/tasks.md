## 1. Project Setup

- [x] 1.1 Create Azure Function project using `func init` with C#/.NET 8 runtime
- [x] 1.2 Add NuGet dependencies: Azure.Data.Tables, Microsoft.ApplicationInsights, and System.Net.Http.Json
- [x] 1.3 Create local.settings.json with AzureWebJobsStorage and other local configuration
- [x] 1.4 Create project folder structure: Models/, Services/, Functions/
- [x] 1.5 Add .gitignore for Azure Functions artifacts and local settings

## 2. Core Models and Utilities

- [x] 2.1 Create UrlMapping model class for table entity
- [x] 2.2 Create AccessLog model class for logging structure
- [x] 2.3 Implement Base62 encoding utility for short code generation
- [x] 2.4 Implement URL validation utility
- [x] 2.5 Implement IP extraction utility to handle X-Forwarded-For and direct connections

## 3. Data Layer and Azure Storage

- [x] 3.1 Create IUrlRepository interface
- [x] 3.2 Implement UrlRepository class using Azure Table Storage
- [x] 3.3 Add method to create/update URL mappings
- [x] 3.4 Add method to retrieve URL by short code
- [x] 3.5 Add collision detection logic
- [x] 3.6 Configure table storage client with connection string

## 4. Logging Service

- [x] 4.1 Create IAccessLogger interface
- [x] 4.2 Implement AccessLogger using Application Insights
- [x] 4.3 Add logging for successful redirects with client IP
- [x] 4.4 Add logging for failed lookups with client IP
- [x] 4.5 Add structured logging with all required fields

## 5. URL Shortening Function

- [x] 5.1 Create ShortenUrl HTTP-triggered function (POST /api/shorten)
- [x] 5.2 Add request body deserialization and validation
- [x] 5.3 Implement URL validation (required, valid format)
- [x] 5.4 Implement short code generation logic
- [x] 5.5 Add idempotency check (same URL returns same code)
- [x] 5.6 Implement retry logic for code collisions
- [x] 5.7 Add response formatting with shortCode and shortUrl
- [x] 5.8 Add error handling for storage failures

## 6. URL Redirect Function

- [x] 6.1 Create ResolveUrl HTTP-triggered function (GET /api/redirect/{shortCode})
- [x] 6.2 Extract shortCode from URL parameter
- [x] 6.3 Implement URL lookup in table storage
- [x] 6.4 Add 302 Found redirect response with Location header
- [x] 6.5 Add 404 response for non-existent codes
- [x] 6.6 Implement error handling for storage failures
- [x] 6.7 Integrate access logging before redirect

## 7. Access Logging Integration

- [x] 7.1 Extract client IP in ResolveUrl function
- [x] 7.2 Log access with IP, short code, timestamp, and result status
- [x] 7.3 Handle IP extraction failures gracefully
- [x] 7.4 Verify logs appear in Application Insights

## 8. Testing

- [ ] 8.1 Create unit tests for Base62 encoding utility
- [ ] 8.2 Create unit tests for URL validation utility
- [ ] 8.3 Create unit tests for IP extraction utility
- [ ] 8.4 Create integration tests for ShortenUrl function with mock table storage
- [ ] 8.5 Create integration tests for ResolveUrl function with mock table storage
- [ ] 8.6 Test idempotency (same URL twice returns same code)
- [ ] 8.7 Test collision handling
- [ ] 8.8 Test 404 for non-existent short codes
- [ ] 8.9 Test error responses for invalid input
- [ ] 8.10 Test access logging is called and structured correctly

## 9. Azure Infrastructure Setup

- [ ] 9.1 Create Azure Storage Account for table storage
- [ ] 9.2 Create table named "UrlMappings" in the storage account
- [ ] 9.3 Create Application Insights instance for logging
- [ ] 9.4 Create Azure Function App (Consumption plan)
- [ ] 9.5 Configure function app application settings with storage connection string
- [ ] 9.6 Configure function app settings with Application Insights instrumentation key
- [ ] 9.7 Test storage account and table access from local development environment

## 10. Deployment Configuration

- [x] 10.1 Create local.settings.json with all required connection strings
- [x] 10.2 Create publish profile for Azure Function App deployment
- [x] 10.3 Add Azure CLI or Visual Studio deployment scripts
- [x] 10.4 Document environment variables needed for deployment
- [x] 10.5 Create README with Azure prerequisites and deployment steps

## 11. End-to-End Testing and Deployment

- [ ] 11.1 Deploy to Azure staging environment
- [ ] 11.2 Test POST /api/shorten endpoint with sample URLs
- [ ] 11.3 Test GET /api/redirect/{shortCode} with generated codes
- [ ] 11.4 Verify IP logging in Application Insights
- [ ] 11.5 Test concurrent redirect requests
- [ ] 11.6 Verify 302 redirects work correctly in browser
- [ ] 11.7 Monitor function execution metrics and latency
- [ ] 11.8 Document any issues and resolve before production
- [ ] 11.9 Deploy to production environment
- [ ] 11.10 Create runbook for monitoring and troubleshooting

## 12. Documentation and Cleanup

- [x] 12.1 Create API documentation with endpoint examples
- [x] 12.2 Document URL shortening algorithm and collision handling
- [x] 12.3 Document IP logging approach and privacy considerations
- [x] 12.4 Add deployment guide for new environments
- [ ] 12.5 Clean up temporary files and ensure code quality
- [ ] 12.6 Verify all tests pass and code coverage is acceptable
