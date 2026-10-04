# HTTP API

The API is rooted at `/api/v1`. Successful responses use a `data` object and `meta.request_id`; errors use an `error` object and the same `meta.request_id`. Each request ID is also returned in the `X-Request-Id` header. Monetary values are integer cents in the jurisdiction's currency. JSON request and response bodies below are pretty-printed with `jq`.

POST endpoints under `/api/v1` accept `Content-Type: application/json` only. Unknown JSON keys are ignored. Values are validated without converting JSON strings into numbers or booleans.

## Jurisdictions

### `GET /api/v1/jurisdictions`

Lists the registered jurisdictions.

| Field | Type | Required | Constraint/default |
|---|---|---:|---|
| — | — | — | No request fields |

Example:

```sh
curl -i http://localhost:3000/api/v1/jurisdictions
```

Captured response excerpt (54 entries):

```json
{
  "data": [
    {
      "code": "CA",
      "name": "California",
      "country": "US",
      "currency": "USD",
      "tier": 1
    },
    {
      "code": "TX",
      "name": "Texas",
      "country": "US",
      "currency": "USD",
      "tier": 1
    },
    {
      "code": "FL",
      "name": "Florida",
      "country": "US",
      "currency": "USD",
      "tier": 1
    },
    ...
  ],
  "meta": {
    "request_id": "47064d6b-1489-4487-b194-91c618f07421"
  }
}
```

### `GET /api/v1/jurisdictions/:code`

Returns jurisdiction details, including weight tiers, EV surcharge, temporary-tag duration, and ELT availability.

| Field | Type | Required | Constraint/default |
|---|---|---:|---|
| `code` | string | Yes | A registered jurisdiction code |

Example:

```sh
curl -i http://localhost:3000/api/v1/jurisdictions/CA
```

Captured response:

```json
{
  "data": {
    "code": "CA",
    "name": "California",
    "country": "US",
    "currency": "USD",
    "tier": 1,
    "weight_tiers": [
      [2999, 6500],
      [4499, 8500],
      [5999, 11000],
      [null, 15000]
    ],
    "ev_surcharge_cents": 10000,
    "temp_tag_days": 90,
    "elt": true
  },
  "meta": {
    "request_id": "7c747272-e4ee-4749-9c77-43c6bdca4639"
  }
}
```

## Registration quotes

### `POST /api/v1/registration_quotes`

Calculates a quote without persisting a registration.

| Field | Type | Required | Constraint/default |
|---|---|---:|---|
| `jurisdiction` | string | Yes | Registered jurisdiction code |
| `weight_lbs` | integer | Yes | 1–20,000 |
| `purchase_price_cents` | integer | Yes | 0–1,000,000,000 |
| `delivery_date` | string | Yes | Real date in `YYYY-MM-DD` format |
| `powertrain` | string | No | `bev`, `phev`, or `ice`; defaults to `bev` |
| `financing` | string | No | `cash`, `loan`, `lease`, or `refinance`; defaults to `cash` |
| `lienholder_elt` | boolean | No | JSON `true` or `false`; defaults to `true` |
| `buyer_jurisdiction` | string | No | Registered jurisdiction code; defaults to `jurisdiction` |
| `county` | string | No | At most 64 characters |
| `usage` | string | No | `personal` or `commercial`; defaults to `personal` |

Example:

```sh
curl -i -X POST http://localhost:3000/api/v1/registration_quotes \
  -H 'Content-Type: application/json' \
  -d '{
    "jurisdiction": "CA",
    "weight_lbs": 4200,
    "purchase_price_cents": 4899000,
    "delivery_date": "2025-06-10"
  }'
```

Captured response:

```json
{
  "data": {
    "jurisdiction": "CA",
    "jurisdiction_name": "California",
    "currency": "USD",
    "line_items": [
      {
        "code": "registration",
        "label": "Registration",
        "amount_cents": 8500
      },
      {
        "code": "ev_surcharge",
        "label": "EV surcharge",
        "amount_cents": 10000
      }
    ],
    "registration_fee_cents": 8500,
    "ev_surcharge_cents": 10000,
    "total_cents": 18500,
    "temp_tag": {
      "valid_days": 90,
      "expires_on": "2025-09-08"
    },
    "lien": {
      "required": false,
      "filing_method": null,
      "reason": "No lien to record"
    }
  },
  "meta": {
    "request_id": "ab8c2aed-d11f-4068-b313-f43011a1ed57"
  }
}
```

## Temporary tags

### `POST /api/v1/temp_tags`

Issues and persists a temporary tag for an existing vehicle. The vehicle owner determines the jurisdiction.

| Field | Type | Required | Constraint/default |
|---|---|---:|---|
| `vin` | string | Yes | VIN of an existing vehicle |
| `issue_date` | string | Yes | Real date in `YYYY-MM-DD` format |
| `usage` | string | No | `personal` or `commercial`; defaults to the vehicle's usage |
| `buyer_jurisdiction` | string | No | Registered jurisdiction code; defaults to the vehicle owner's jurisdiction |

Example:

```sh
curl -i -X POST http://localhost:3000/api/v1/temp_tags \
  -H 'Content-Type: application/json' \
  -d '{
    "vin": "5LVY801E9MAFNZUL0",
    "issue_date": "2025-06-10"
  }'
```

Captured response:

```json
{
  "data": {
    "tag_number": "FL-T-000011",
    "vin": "5LVY801E9MAFNZUL0",
    "jurisdiction": "FL",
    "issued_on": "2025-06-10",
    "valid_days": 30,
    "expires_on": "2025-07-09",
    "status": "expired"
  },
  "meta": {
    "request_id": "96eabe90-5da3-42f6-a706-09b80301d7ce"
  }
}
```

### `GET /api/v1/temp_tags/:tag_number`

Returns a previously issued tag.

| Field | Type | Required | Constraint/default |
|---|---|---:|---|
| `tag_number` | string | Yes | Existing tag number |

Example:

```sh
curl -i http://localhost:3000/api/v1/temp_tags/FL-T-000011
```

Captured response:

```json
{
  "data": {
    "tag_number": "FL-T-000011",
    "vin": "5LVY801E9MAFNZUL0",
    "jurisdiction": "FL",
    "issued_on": "2025-06-10",
    "valid_days": 30,
    "expires_on": "2025-07-09",
    "status": "expired"
  },
  "meta": {
    "request_id": "56906b9e-1ac6-4865-af6f-70e9b6a1a97e"
  }
}
```

## Lien determinations

### `POST /api/v1/lien_determinations`

Returns a filing decision without persisting a lien filing.

| Field | Type | Required | Constraint/default |
|---|---|---:|---|
| `jurisdiction` | string | Yes | Registered jurisdiction code |
| `financing` | string | Yes | `cash`, `loan`, `lease`, or `refinance` |
| `lienholder_elt` | boolean | No | JSON `true` or `false`; defaults to `true` |
| `buyer_jurisdiction` | string | No | Registered jurisdiction code; defaults to `jurisdiction` |

Example:

```sh
curl -i -X POST http://localhost:3000/api/v1/lien_determinations \
  -H 'Content-Type: application/json' \
  -d '{
    "jurisdiction": "CA",
    "financing": "loan",
    "lienholder_elt": true
  }'
```

Captured response:

```json
{
  "data": {
    "jurisdiction": "CA",
    "financing": "loan",
    "lien_filing_required": true,
    "filing_method": "electronic",
    "elt_available": true,
    "reason": "Electronic filing via California ELT"
  },
  "meta": {
    "request_id": "817dcf96-232a-4540-a034-c8e1c7aa0e3e"
  }
}
```

## Compatibility and health routes

### `POST /registration_quotes`

The compatibility endpoint accepts the established quote fields and returns its unwrapped response body. Its supported jurisdiction codes are `CA`, `TX`, `FL`, `NY`, `WA`, and `ON`.

| Field | Type | Required | Constraint/default |
|---|---|---:|---|
| `state` | string | Yes | One of the supported compatibility codes |
| `vehicle_weight_lbs` | integer | Yes | Greater than zero |
| `vehicle_price_usd` | number | Yes | Non-negative amount in dollars |
| `delivery_date` | string | Yes | Date in `YYYY-MM-DD` format |
| `financed` | boolean | No | Defaults to `false` |
| `buyer_state` | string | No | Supported compatibility code; defaults to `state` |

Example:

```sh
curl -i -X POST http://localhost:3000/registration_quotes \
  -H 'Content-Type: application/json' \
  -d '{
    "state": "CA",
    "vehicle_weight_lbs": 4200,
    "vehicle_price_usd": 48990,
    "financed": true,
    "buyer_state": "CA",
    "delivery_date": "2025-06-10"
  }'
```

Captured response:

```json
{
  "registration_fee_cents": 8500,
  "ev_surcharge_cents": 10000,
  "temp_tag_valid_days": 90,
  "temp_tag_expires_on": "2025-09-08",
  "lien_filing_required": true,
  "lien_filing_method": "electronic",
  "total_cents": 18500
}
```

### `GET /up`

Returns the Rails health-check page.

| Field | Type | Required | Constraint/default |
|---|---|---:|---|
| — | — | — | No request fields |

Example:

```sh
curl -i http://localhost:3000/up
```

Captured response:

```http
HTTP/1.1 200 OK
<!DOCTYPE html><html><body style="background-color: green"></body></html>
```

## Errors

All `/api/v1` errors use the same envelope and include a request ID:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Validation failed",
    "details": [
      {
        "field": "weight_lbs",
        "message": "must be an integer"
      }
    ]
  },
  "meta": {
    "request_id": "354cca7f-0fd7-4715-bc56-06bcb776002d"
  }
}
```

| Code | HTTP status | Meaning |
|---|---:|---|
| `malformed_json` | 400 | The request body is not valid JSON |
| `unsupported_media_type` | 415 | A POST uses a content type other than `application/json` |
| `validation_failed` | 422 | A field is missing or fails type/constraint validation |
| `unknown_jurisdiction` | 422 | A jurisdiction code is not registered; `details` identifies `jurisdiction` |
| `not_found` | 404 | The requested resource or API route does not exist |
| `internal_error` | 500 | An unexpected server-side error; the response body contains no exception details or backtrace |

Captured examples:

```text
POST /api/v1/registration_quotes
Content-Type: application/json
Body (intentionally malformed): {"jurisdiction":
HTTP/1.1 400 Bad Request
```

```json
{
  "error": {
    "code": "malformed_json",
    "message": "Malformed JSON request",
    "details": []
  },
  "meta": {
    "request_id": "e6a09a44-e820-4d7a-adf7-460b4e759be0"
  }
}
```

```text
POST /api/v1/registration_quotes
Content-Type: text/plain
Body: hello
HTTP/1.1 415 Unsupported Media Type
```

```json
{
  "error": {
    "code": "unsupported_media_type",
    "message": "Content-Type must be application/json",
    "details": []
  },
  "meta": {
    "request_id": "01240c54-d065-4120-9fc9-8d9f67dbbb1a"
  }
}
```

```text
POST /api/v1/registration_quotes
Content-Type: application/json
Body:
```

```json
{
  "jurisdiction": "CA",
  "weight_lbs": "4200",
  "purchase_price_cents": 20000000,
  "delivery_date": "2025-06-10"
}
```

```text
HTTP/1.1 422 Unprocessable Content
```

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Validation failed",
    "details": [
      {
        "field": "weight_lbs",
        "message": "must be an integer"
      }
    ]
  },
  "meta": {
    "request_id": "354cca7f-0fd7-4715-bc56-06bcb776002d"
  }
}
```

```text
POST /api/v1/registration_quotes
Content-Type: application/json
Body:
```

```json
{
  "jurisdiction": "ZZ",
  "weight_lbs": 4200,
  "purchase_price_cents": 20000000,
  "delivery_date": "2025-06-10"
}
```

```text
HTTP/1.1 422 Unprocessable Content
```

```json
{
  "error": {
    "code": "unknown_jurisdiction",
    "message": "Unknown jurisdiction: ZZ",
    "details": [
      {
        "field": "jurisdiction",
        "message": "Unknown jurisdiction: ZZ"
      }
    ]
  },
  "meta": {
    "request_id": "1964b0ec-aa46-4a61-9f36-9cdd69ec05a0"
  }
}
```

```text
GET /api/v1/temp_tags/NOT-A-TAG
HTTP/1.1 404 Not Found
```

```json
{
  "error": {
    "code": "not_found",
    "message": "Resource not found",
    "details": []
  },
  "meta": {
    "request_id": "bd15c569-dce9-461d-835b-9e8667b31dd9"
  }
}
```

```text
GET /api/v1/temp_tags/NOT-A-TAG
HTTP/1.1 500 Internal Server Error
```

```json
{
  "error": {
    "code": "internal_error",
    "message": "Internal server error",
    "details": []
  },
  "meta": {
    "request_id": "7606b31d-2b78-4c20-6160-ac359755"
  }
}
```

The 500 example was captured with `curl` against an isolated development server using a separate SQLite database with its `temp_tags` table removed. This exercises the API exception handler without altering the seeded application database.
