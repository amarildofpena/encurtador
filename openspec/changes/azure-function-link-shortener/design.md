## Context

Building a URL shortening service as a serverless Azure Function allows for cost-effective, auto-scaling infrastructure. The service will handle two main operations: creating short URLs and resolving them with analytics. All access patterns must be logged for monitoring and analytics purposes. The application targets Azure cloud deployment with standard cloud-native practices.

## Goals / Non-Goals

**Goals:**
- Create a stateless, scalable Azure Function application that handles URL shortening and redirection
- Implement access logging that captures client IP addresses for all redirect operations
- Store URL mappings persistently and retrieve them efficiently
- Provide a cloud-native deployment configuration ready for Azure
- Design for production deployment with proper error handling and monitoring

**Non-Goals:**
- Building a web UI or admin dashboard (API-only service)
- Implementing rate limiting or authentication (can be added later via API Management)
- Custom short code generation algorithms (use simple alphanumeric encoding)
- Multi-region replication or disaster recovery failover

## Decisions

### 1. Technology Stack: C# with .NET
**Rationale**: Project directory indicates .NET ecosystem. C# provides strong type safety, performance, and excellent Azure integration through official SDKs. Azure Functions have first-class .NET support with good documentation and tooling.
**Alternatives Considered**: 
- Python: Lighter weight but less type safety for this data-critical application
- Node.js: Good Azure support but less native type checking

### 2. Data Storage: Azure Table Storage
**Rationale**: Table Storage is cost-effective, serverless, and provides high availability for key-value queries (short code → long URL). Scales automatically with demand. No need to manage databases.
**Alternatives Considered**:
- Cosmos DB: More expensive, unnecessary complexity for simple key-value lookups
- SQL Database: Requires provisioning and management overhead

### 3. Logging: Application Insights + Console Logs
**Rationale**: Application Insights integrates natively with Azure Functions, captures request traces, and allows IP logging via custom events. Console logs stream directly to Azure Logs.
**Alternatives Considered**:
- EventHub + custom log storage: Overkill for current requirements
- File-based logging: Not practical in serverless environment (no persistent disk)

### 4. Short Code Generation: Base62 Encoding
**Rationale**: Simple, collision-resistant encoding scheme that generates compact short codes. Deterministic (same URL → same code) simplifies lookups and deduplication.
**Alternatives Considered**:
- Random UUIDs: Longer codes, unnecessary complexity
- Random alphanumeric with collision detection: More complex implementation

### 5. Project Structure
**Rationale**: 
- Single Function App with two HTTP-triggered functions (ShortenUrl, ResolveUrl)
- Local.settings.json for development configuration (Azure Storage connection)
- Azure Functions runtime v4 for latest .NET support
- Dependency injection for service layer (URL service, logging service)

### 6. HTTP Endpoints
- `POST /api/shorten` - Request body: `{ "url": "https://example.com/long/path" }`, Response: `{ "shortCode": "abc123", "shortUrl": "https://short.link/abc123" }`
- `GET /api/redirect/{shortCode}` - Redirects to original URL with 302 status, logs client IP

## Risks / Trade-offs

**[Risk] Table Storage latency for high-traffic scenario** → Mitigation: Table Storage provides sub-100ms response times; if this becomes bottleneck, upgrade to Cosmos DB with minimal code changes.

**[Risk] Short code collision (rare but possible)** → Mitigation: Implement retry logic in shortenUrl function to regenerate code on collision.

**[Risk] Client IP may be obscured behind load balancer/proxy** → Mitigation: Check `X-Forwarded-For` header and function context for actual client IP; document this limitation.

**[Risk] Cold starts impact latency on Azure Functions** → Mitigation: Accept cold starts as acceptable tradeoff for serverless cost-efficiency; optimize with code trimming and dependency injection.

**[Trade-off] No authentication on endpoints** → Keep public for simplicity initially; can layer API Management authentication later without changing core logic.

## Migration Plan

1. Create Azure Storage Account and Table Storage table for URL mappings
2. Create Azure Function App with consumption plan
3. Deploy functions via VS Publish or Azure CLI
4. Configure Application Insights binding
5. Test endpoints with sample URLs
6. Monitor logs and latency metrics
7. Scale endpoints as needed (no config required - automatic)

## Open Questions

- Should short codes include custom vanity keywords (e.g., `/my-campaign`)? (Deferred to future enhancement)
- Need authentication/API keys for the shorten endpoint to prevent abuse? (Deferred - can add via API Management)
- Desired retention policy for URL mappings? (Assuming indefinite for now)
