# Encurtador de Links - API Documentation

## Overview

The Encurtador de Links API provides two main endpoints for URL shortening and redirection with built-in analytics and IP tracking.

## Base URL

- **Local**: `http://localhost:7071`
- **Production**: `https://func-encurtador-links.azurewebsites.net` (adjust based on your deployment)

## Authentication

Currently, the API is publicly accessible without authentication. For production use, consider implementing:
- API Keys
- OAuth 2.0
- Azure AD integration
- API Management policies

## API Endpoints

### 1. Shorten URL

**Endpoint:** `POST /api/shorten`

Creates a short code for a long URL.

#### Request

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "url": "https://example.com/very/long/path/with/many/parameters?param1=value1&param2=value2"
}
```

#### Response

**Status: 200 OK**

```json
{
  "shortCode": "abc123",
  "shortUrl": "http://localhost:7071/api/redirect/abc123"
}
```

**Status: 400 Bad Request**

```json
{
  "error": "Invalid or missing URL"
}
```

**Status: 500 Internal Server Error**

```json
{
  "error": "Internal server error"
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| url | string | The long URL to shorten (required, must be valid HTTP/HTTPS URL) |
| shortCode | string | Generated short code (alphanumeric, 6+ characters) |
| shortUrl | string | Full URL for the shortened code |

#### Examples

**cURL:**
```bash
curl -X POST http://localhost:7071/api/shorten \
  -H "Content-Type: application/json" \
  -d '{"url":"https://github.com/microsoft/azure-functions-core-tools"}'
```

**PowerShell:**
```powershell
$body = @{
    url = "https://github.com/microsoft/azure-functions-core-tools"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:7071/api/shorten" `
  -Method Post `
  -Headers @{"Content-Type"="application/json"} `
  -Body $body
```

**JavaScript/Fetch:**
```javascript
const response = await fetch('http://localhost:7071/api/shorten', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ url: 'https://example.com/long/url' })
});
const data = await response.json();
console.log(data.shortUrl);
```

#### Idempotency

If you submit the same URL multiple times, you'll receive the same short code:

```bash
# First request
curl -X POST http://localhost:7071/api/shorten \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}'
# Returns: {"shortCode":"abc123","shortUrl":"..."}

# Second request with same URL
curl -X POST http://localhost:7071/api/shorten \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}'
# Also returns: {"shortCode":"abc123","shortUrl":"..."}
```

---

### 2. Redirect to URL

**Endpoint:** `GET /api/redirect/{shortCode}`

Redirects to the original long URL and logs the access.

#### Request

**Parameters:**
```
{shortCode}  : The short code returned from the shorten endpoint
```

**Headers** (optional):
```
X-Forwarded-For: IP address of the client (if behind proxy/load balancer)
User-Agent: Browser information
Referer: Source page
```

#### Response

**Status: 302 Found**

Returns redirect response with Location header pointing to original URL.

Headers:
```
Location: https://example.com/very/long/path
```

**Status: 404 Not Found**

```json
{
  "error": "Short code not found"
}
```

**Status: 400 Bad Request**

```json
{
  "error": "Short code is required"
}
```

**Status: 500 Internal Server Error**

```json
{
  "error": "Internal server error"
}
```

#### Examples

**Browser:**
```
Navigate to: http://localhost:7071/api/redirect/abc123
Browser follows redirect to original URL
```

**cURL:**
```bash
# Follow redirect automatically
curl -L http://localhost:7071/api/redirect/abc123

# Show redirect without following
curl -i http://localhost:7071/api/redirect/abc123
```

**PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:7071/api/redirect/abc123" `
  -MaximumRedirection 0 `
  -ErrorAction SilentlyContinue | Select-Object -Property StatusCode, @{Name="Location";Expression={$_.Headers['Location']}}
```

#### IP Logging

Every redirect access is logged with:
- Client IP address (from X-Forwarded-For or direct connection)
- Short code accessed
- Original URL destination
- HTTP status code (302 for successful redirect)
- Timestamp
- User-Agent (if provided)

Access logs are available in Application Insights:
```kql
customEvents
| where name == "UrlAccess"
| project TimeGenerated=timestamp, ClientIp=customDimensions.ClientIp, ShortCode=customDimensions.ShortCode
```

---

## HTTP Status Codes

| Code | Meaning | Condition |
|------|---------|-----------|
| 200 | OK | URL successfully shortened |
| 302 | Found | Redirect successful |
| 400 | Bad Request | Invalid input or missing required fields |
| 404 | Not Found | Short code doesn't exist |
| 500 | Internal Server Error | Unexpected server error |

## Error Handling

All error responses follow this format:

```json
{
  "error": "Human-readable error message"
}
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Invalid or missing URL" | URL is null, empty, or malformed | Provide valid HTTP/HTTPS URL |
| "Short code not found" | The code doesn't exist in database | Check code spelling, may have expired |
| "Internal server error" | Server or database error | Check Application Insights logs |
| "Short code is required" | Empty or missing {shortCode} parameter | Provide valid short code |

---

## Request/Response Examples

### Complete Flow

**Step 1: Create Short URL**

Request:
```bash
curl -X POST http://localhost:7071/api/shorten \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://learn.microsoft.com/en-us/azure/azure-functions/"
  }'
```

Response:
```json
{
  "shortCode": "2a4b5c",
  "shortUrl": "http://localhost:7071/api/redirect/2a4b5c"
}
```

**Step 2: Use Short URL**

Request:
```bash
curl -i http://localhost:7071/api/redirect/2a4b5c
```

Response:
```
HTTP/1.1 302 Found
Location: https://learn.microsoft.com/en-us/azure/azure-functions/
```

Browser automatically navigates to the original URL.

---

## Rate Limiting

Currently, the API has no built-in rate limiting. For production deployments, implement rate limiting through:
- Azure API Management
- Azure Front Door
- Azure Functions Premium Plan with built-in throttling

---

## CORS (Cross-Origin Resource Sharing)

The API currently has CORS disabled. To enable for web applications:

1. Enable CORS in Azure Functions settings
2. Or use Azure API Management as a gateway

---

## Monitoring and Analytics

### Access Metrics

Track usage through Application Insights:

**Total redirects by short code:**
```kql
customEvents
| where name == "UrlAccess"
| summarize Redirects=count() by ShortCode=tostring(customDimensions.ShortCode)
| sort by Redirects desc
```

**Top traffic sources (IPs):**
```kql
customEvents
| where name == "UrlAccess" and customDimensions.StatusCode == "302"
| summarize Count=count() by ClientIp=tostring(customDimensions.ClientIp)
| sort by Count desc
| limit 10
```

**Error rate:**
```kql
customEvents
| where name == "UrlAccess"
| extend StatusCode = toint(customDimensions.StatusCode)
| summarize ErrorCount=count(StatusCode != 302), SuccessCount=count(StatusCode == 302)
| extend ErrorRate = (100.0 * ErrorCount) / (ErrorCount + SuccessCount)
```

---

## Best Practices

1. **Validate URLs**: Always validate URL format before submission
2. **Handle Redirects**: Implement proper redirect handling in clients
3. **Monitor Usage**: Regularly check Application Insights for errors or unusual patterns
4. **Rate Limiting**: Implement client-side rate limiting if making many requests
5. **Error Handling**: Handle 404s gracefully (short code may be invalid or expired)
6. **Security**: Don't expose sensitive information in URLs before shortening
7. **Logging**: Log short codes for important links for audit trails

---

## Changelog

### Version 1.0.0 (Initial Release)

- URL shortening endpoint
- URL redirection with 302 status
- IP address logging
- Idempotency support
- Collision handling

---

## Support

For API issues or questions:
1. Check Application Insights logs
2. Verify URL format and encoding
3. Ensure function app is running
4. Check Azure status page for service health
