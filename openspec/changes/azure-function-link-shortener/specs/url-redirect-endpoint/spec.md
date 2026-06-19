## ADDED Requirements

### Requirement: HTTP endpoint resolves short codes and redirects
The system SHALL provide an HTTP GET endpoint at `/api/redirect/{shortCode}` that resolves the short code and redirects to the original URL.

#### Scenario: Valid short code redirect
- **WHEN** a GET request is sent to `/api/redirect/abc123` where `abc123` maps to a stored URL
- **THEN** the system returns HTTP 302 Found with Location header pointing to the original URL

#### Scenario: Non-existent short code
- **WHEN** a GET request is sent to `/api/redirect/invalid` where no mapping exists
- **THEN** the system returns HTTP 404 Not Found with error message

#### Scenario: Malformed short code parameter
- **WHEN** a GET request is sent to `/api/redirect/` with empty short code
- **THEN** the system returns HTTP 400 Bad Request or 404 Not Found

### Requirement: Redirect response uses correct HTTP semantics
The system SHALL use HTTP 302 (temporary redirect) status code with Location header.

#### Scenario: HTTP 302 status code
- **WHEN** a valid short code is resolved
- **THEN** the HTTP response status is 302 Found (not 301 or 307)

#### Scenario: Location header is set
- **WHEN** a valid short code is resolved
- **THEN** the response includes `Location: <original_url>` header

### Requirement: Lookup speed for redirects
The system SHALL resolve short codes with minimal latency (<500ms p99).

#### Scenario: Fast redirect response
- **WHEN** a short code is looked up in Table Storage
- **THEN** the response time is under 500ms for the 99th percentile

### Requirement: Handle concurrent redirect requests
The system SHALL safely handle multiple simultaneous requests to the same short code.

#### Scenario: Concurrent access to same short code
- **WHEN** 10 simultaneous requests access the same short code
- **THEN** all requests receive the correct redirect response with no corruption or errors

### Requirement: Case sensitivity
The system SHALL treat short codes as case-sensitive.

#### Scenario: Case-sensitive lookup
- **WHEN** a short code is looked up with different casing (e.g., `abc123` vs `ABC123`)
- **THEN** only the exact case match returns the URL; mismatched case returns 404
