## ADDED Requirements

### Requirement: Log access IP address on every redirect
The system SHALL capture and log the client IP address for every redirect request.

#### Scenario: IP logged on successful redirect
- **WHEN** a valid short code is accessed via `/api/redirect/{shortCode}`
- **THEN** the system logs the client's IP address along with the short code and timestamp

#### Scenario: IP logged on failed lookup
- **WHEN** an invalid short code is accessed
- **THEN** the system logs the client's IP address even though the redirect fails

### Requirement: Extract correct IP from requests
The system SHALL correctly extract the client IP address even when behind proxies or load balancers.

#### Scenario: Direct client connection
- **WHEN** a request comes directly from a client
- **THEN** the system logs the IP from the request's remote address

#### Scenario: Request behind proxy
- **WHEN** a request comes through a proxy (X-Forwarded-For header present)
- **THEN** the system logs the first IP from the `X-Forwarded-For` header as the client IP

### Requirement: Structured logging to Application Insights
The system SHALL log access data in structured format to Application Insights.

#### Scenario: Log entry contains required fields
- **WHEN** an access is logged
- **THEN** the log entry includes: clientIp, shortCode, originalUrl, timestamp, statusCode, and redirectLocation

#### Scenario: Logs are queryable in Application Insights
- **WHEN** logs are written
- **THEN** they are available in Azure Application Insights for querying and analysis

### Requirement: Timestamp accuracy
The system SHALL record UTC timestamp for each access.

#### Scenario: Timestamp recorded in UTC
- **WHEN** an access is logged
- **THEN** the timestamp is recorded in UTC ISO 8601 format

### Requirement: No personal data retention beyond access logs
The system SHALL NOT retain IP addresses longer than operational logs.

#### Scenario: Log retention policy
- **WHEN** logs are stored
- **THEN** they follow Azure's default retention policy (respecting GDPR and privacy regulations)

### Requirement: Handle IP extraction failures gracefully
The system SHALL log a placeholder value if IP cannot be determined.

#### Scenario: IP extraction failure
- **WHEN** client IP cannot be determined from request or headers
- **THEN** the system logs "unknown" or "0.0.0.0" as placeholder and does not throw an error
