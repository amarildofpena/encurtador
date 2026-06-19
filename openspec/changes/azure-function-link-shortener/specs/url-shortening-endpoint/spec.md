## ADDED Requirements

### Requirement: HTTP endpoint accepts URL shortening requests
The system SHALL provide an HTTP POST endpoint at `/api/shorten` that accepts a JSON request containing a long URL and returns a short code.

#### Scenario: Valid long URL submission
- **WHEN** a POST request is sent to `/api/shorten` with body `{ "url": "https://example.com/very/long/path" }`
- **THEN** the system returns HTTP 200 with response `{ "shortCode": "<generated_code>", "shortUrl": "https://short.link/<generated_code>" }`

#### Scenario: Missing URL parameter
- **WHEN** a POST request is sent to `/api/shorten` with an empty or missing `url` field
- **THEN** the system returns HTTP 400 Bad Request with error message

#### Scenario: Invalid URL format
- **WHEN** a POST request is sent to `/api/shorten` with malformed URL (e.g., "not a url")
- **THEN** the system returns HTTP 400 Bad Request with validation error message

### Requirement: Generate unique short codes
The system SHALL generate a unique, compact short code (alphanumeric, case-sensitive) for each URL.

#### Scenario: Deterministic code generation
- **WHEN** the same URL is submitted twice
- **THEN** the system returns the same short code both times (idempotent behavior)

#### Scenario: Different URLs get different codes
- **WHEN** two different URLs are submitted
- **THEN** the system returns different short codes for each

### Requirement: Persist URL mappings
The system SHALL store the mapping between short codes and original URLs in persistent storage.

#### Scenario: URL mapping stored successfully
- **WHEN** a short code is generated
- **THEN** the mapping (short code → long URL) is saved to Table Storage and survives application restarts

#### Scenario: URL can be retrieved after storage
- **WHEN** a short code that was previously generated is queried
- **THEN** the system can retrieve and return the original URL

### Requirement: Handle storage conflicts gracefully
The system SHALL handle cases where multiple requests generate the same short code (collision).

#### Scenario: Collision is retried
- **WHEN** a collision is detected (short code already exists)
- **THEN** the system generates a new short code and retries storage

### Requirement: Endpoint returns correct response format
The system SHALL return JSON responses with proper HTTP status codes and error messages.

#### Scenario: Successful response structure
- **WHEN** a URL is successfully shortened
- **THEN** response includes `shortCode` (string) and `shortUrl` (string) fields

#### Scenario: Error response structure
- **WHEN** a request fails validation
- **THEN** response includes `error` field with descriptive message and appropriate HTTP status code (400, 500, etc.)
