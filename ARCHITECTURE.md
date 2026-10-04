# Architecture

Lucid Vehicle Services is a Rails 7.1 full-stack monolith. Customer, vehicle, registration, tag, lien, title, and delivery records are persisted in SQLite; shared services implement domain operations for both server-rendered pages and JSON endpoints. Jurisdiction rules are kept in a registry rather than in controllers.

## Domain boundaries

| Namespace | Models | Controllers and services | Routes |
|---|---|---|---|
| `CustomerAccounts` | `Customer`, `Vehicle` | `CustomersController`, `VehiclesController` | `/customers`, `/vehicles/:id` |
| `Registrations` | `Registration` | `RegistrationsController`, `FeeCalculator`, `SubmissionService` | `/registrations`, `/registrations/:id/submit` |
| `TempTags` | `TempTag` | `TempTagsController`, `IssueService` | `/temp_tags`, `/temp_tags/:id/void` |
| `LienFilings` | `LienFiling` | `LienFilingsController`, `DeterminationService` | `/lien_filings` |
| `Titling` | `TitleApplication` | `TitleApplicationsController`, `StatusTracker` | `/title_applications`, `/title_applications/:id/advance_status` |
| `DealerPortal` | `Delivery` | `DeliveriesController`, `PendingRegistrationsQuery` | `/dealer_portal/deliveries` |
| `Jurisdictions` | Registry and rule classes | `JurisdictionsController`, registry lookups and quote rules | `/jurisdictions`, `/api/v1/jurisdictions` |
| `Dmv` | — | `Gateway`, `Adapters::FakeAdapter` | Called by registration submission |

`Customer` has many vehicles. A vehicle belongs to one customer and can have registrations, temporary tags, lien filings, title applications, and deliveries. Registration and title records retain fee/status snapshots so later rule changes do not rewrite previously recorded workflow data.

## Jurisdiction rules

`Jurisdictions::Registry` maps 54 codes to rule classes; `QuoteInput` supplies a shared, validated input shape. Six Tier-1 implementations—CA, TX, FL, NY, WA, and ON—live in individual files under `app/services/jurisdictions/` and define their specific fee, tag, or lien calculations. The other 48 classes use `StandardRules` and per-jurisdiction data such as weight brackets, rates, surcharges, tag durations, and ELT availability.

The rule interface exposes `code`, `display_name`, `country`, `currency`, and `tier`; `weight_tiers`, `weight_tier_label`, and `metadata`; `fee_line_items(input)`, `registration_fee_cents(input)`, `ev_surcharge_cents(input)`, and `total_cents(input)`; `temp_tag_valid_days(input)` and `temp_tag_expires_on(input)`; `elt_available?`, `lease_lien_required?`, `lien_filing_required?(input)`, `lien_filing_method(input)`, and `lien_reason(input)`; and `title_fee_cents`. Shared helpers provide cent rounding and optional positive line items. All money amounts are integer cents in the jurisdiction currency.

Three related rule definitions intentionally live outside the jurisdiction service directory: Ontario currency and tax calculations are in `app/models/concerns/ontario_rules.rb`; the Texas in-transit controller override is in `app/controllers/concerns/texas_in_transit_override.rb`; and Washington RTA county values are exposed as `CustomerAccounts::Vehicle::WA_RTA_COUNTIES` in `app/models/customer_accounts/vehicle.rb`.

## Request flows

- **HTML:** Rails routes dispatch to domain controllers using the full-stack `ApplicationController`. Controllers load records or call shared services, then render ERB templates through the application layout.
- **JSON API:** `/api/v1` controllers inherit from `Api::V1::BaseController`. It enforces JSON request content type, validates field types and constraints, and returns success/error envelopes with request IDs. API controllers use the jurisdiction rules and domain services; an API error controller handles unknown API routes.
- **Compatibility:** `POST /registration_quotes` uses `RegistrationQuotesController < ActionController::API` with parameter wrapping disabled. `RegistrationQuoteService` accepts all 54 registered jurisdictions and returns the established unwrapped response. This endpoint is frozen as the comparison contract, and the California response contract is unchanged.

`GoRouting::QuoteRouter` computes the compatibility response and applies the per-jurisdiction mode. Shadow mode returns that response and queues a comparison; Go mode calls the configured local service and falls back when the service is unavailable or reports a jurisdiction as not migrated. `GO_ROUTING_KILL_SWITCH=1` forces compatibility responses, and `/go_routing` manages route modes and comparisons.

## Data and integrations

`Registrations::FeeCalculator` snapshots fee lines, currency, and totals onto each registration. `TempTags::IssueService` persists issue and expiry dates; `LienFilings::DeterminationService` records the filing requirement and method; and `Titling::StatusTracker` advances title history. The dealer portal query composes deliveries with registration state to identify pending work. The dashboard reads across these domains.

Registration submissions pass through `Dmv::Gateway` to `Dmv::Adapters::FakeAdapter`. The adapter produces a deterministic confirmation number without network calls or external side effects. The separate `registration-go` repository is read-only in this workflow and is used as the comparison implementation for shadowdiff. The Rails compatibility endpoint remains available to compare the two implementations without changing the California contract.
