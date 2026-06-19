## Why

URL shortening is a common requirement for sharing links in limited-character environments and tracking click-through analytics. Building this as an Azure Function allows for serverless, scalable infrastructure that only charges for actual executions, making it cost-effective for variable traffic patterns. Integrating access logging enables monitoring and analytics on which links are being used and from where.

## What Changes

- Create a new Azure Function application with two HTTP-triggered endpoints
- Implement URL shortening endpoint that generates a unique short code for a given long URL
- Implement redirect endpoint that resolves a short code and redirects to the original URL
- Add access logging to capture IP addresses of all redirects
- Configure the application for cloud-native Azure deployment with appropriate configuration management

## Capabilities

### New Capabilities
- `url-shortening-endpoint`: HTTP endpoint that accepts a long URL and returns a short code
- `url-redirect-endpoint`: HTTP endpoint that resolves a short code, logs the access IP, and redirects to the original URL
- `access-logging`: IP address logging for all redirect operations to track usage and analytics

### Modified Capabilities
<!-- None - this is a new feature set -->

## Impact

- New Azure Function project structure and dependencies
- Cloud-native deployment configuration (function app settings, Azure resources)
- Data persistence layer for storing URL mappings
- HTTP request/response handling and logging infrastructure
- Azure platform-specific authentication and authorization (if needed)
