# Domain coupling report

This report describes how the domains in this Rails monolith depend on each other through tables, callbacks, and transactions. It covers the code as it stands at `407ca07`. All file:line references are relative to the repository root.

Domains are the namespaces listed in [ARCHITECTURE.md](../ARCHITECTURE.md). There are a few more actors: `GoRouting` (quote routing), the `Dashboard`, and `db/seeds.rb`. The shared `StatusEvent` model sits at the top level and no namespace owns it.

All tables live in one SQLite database per environment (`config/database.yml:14`, `:21`, `:25`), and every model inherits from `ApplicationRecord`. Every domain table has a foreign key to `customer_accounts_vehicles` (`db/schema.rb:164-169`). Rails 7.1's SQLite adapter enforces these keys because it runs `PRAGMA foreign_keys = ON` on connect.

## 1. Table read/write matrix

Legend: **RW** = reads and writes · **W** = writes · **R** = reads · **D** = deletes through a declared `dependent: :destroy` cascade (no controller action reaches it today) · blank = no access.

| Domain ↓ / Table → | `customer_accounts_customers` | `customer_accounts_vehicles` | `registrations` | `temp_tags` | `lien_filings` | `title_applications` | `dealer_portal_deliveries` | `status_events` | `go_routing_routes` | `go_routing_comparisons` |
|---|---|---|---|---|---|---|---|---|---|---|
| CustomerAccounts | RW | R, D | R, D | R, D | R, D | R, D | R, D | R | | |
| Registrations | R | R | RW | | **RW** | **RW** | | **W** | | |
| TempTags | R | R | | RW | | | **W** | **W** | | |
| LienFilings | R | R | | | RW | | | **W** | | |
| Titling | R | R | | | **R** | RW | | **W** | | |
| DealerPortal | R | R | **R** | | | | R | | | |
| Jurisdictions | | | | | | | | | | |
| Dmv | | | | | | | | | | |
| GoRouting / compatibility quote | | | | | | | | | RW | RW |
| Dashboard | R | R | R | R | R | R | | | | |
| `db/seeds.rb` | W | W | W | W | W | W | W | W | W | |

Bold cells are where one domain writes or gates on another domain's table. Reads of customers and vehicles are bold nowhere because every domain does them.

Evidence for each non-trivial cell:

- **CustomerAccounts**
  - Customers RW: `app/controllers/customer_accounts/customers_controller.rb:4-8`, `:21-22`, `:34-35`.
  - Vehicles R: `app/controllers/customer_accounts/vehicles_controller.rb:4`. There is no controller write path for vehicles; only `db/seeds.rb:181` creates them.
  - Reads every other domain table through preloads: `customers_controller.rb:13` and `vehicles_controller.rb:4`. The views render them at `app/views/customer_accounts/customers/show.html.erb:15-18` and `app/views/customer_accounts/vehicles/show.html.erb:9-32`.
  - `status_events` R: `vehicles_controller.rb:5`.
  - D: `app/models/customer_accounts/customer.rb:5` and `app/models/customer_accounts/vehicle.rb:8-12`. `has_many :status_events` (`vehicle.rb:13`) has no `dependent:` option.
- **Registrations**
  - Registrations RW: `app/controllers/registrations/registrations_controller.rb:4-10`, `:28-38`, `:47`, and `app/services/registrations/submission_service.rb:7`.
  - Reads vehicles and customers: `registrations_controller.rb:15`, `:20`, and `app/services/registrations/fee_calculator.rb:6-14`. The jurisdiction comes from the customer through `vehicle.rb:22-24`.
  - Lien filings RW: `app/models/registrations/registration.rb:27` (read) and `:29-39` (create).
  - Title applications RW: `registration.rb:52` (read), `:57` (`TitleApplication.count`), and `:54-60` (create).
  - Status events W: `submission_service.rb:12`, `registration.rb:40`, `registration.rb:61`.
- **TempTags**
  - Temp tags RW: `app/services/temp_tags/issue_service.rb:19` (`TempTag.count`), `:22`; `app/controllers/temp_tags/temp_tags_controller.rb:6-11`, `:41-42`; `app/controllers/api/v1/temp_tags_controller.rb:41`.
  - Reads vehicles and customers: `temp_tags_controller.rb:19`, `api/v1/temp_tags_controller.rb:17`.
  - Deliveries W: `issue_service.rb:40` (`update_all`).
  - Status events W: `issue_service.rb:31`.
- **LienFilings**
  - Lien filings RW: `app/controllers/lien_filings/lien_filings_controller.rb:4-8`, `:25-35`, `:40`, and `app/services/lien_filings/filing_service.rb:9`.
  - Reads vehicles and customers: `lien_filings_controller.rb:12`, `:17`.
  - Status events W: `filing_service.rb:10`.
  - `POST /api/v1/lien_determinations` touches no table: `app/controllers/api/v1/lien_determinations_controller.rb:16-30` and `app/services/lien_filings/determination_service.rb:5-14`.
- **Titling**
  - Title applications RW: `app/controllers/titling/title_applications_controller.rb:4-8`, `:18-24`, `:29`, and `app/services/titling/status_tracker.rb:25`.
  - Reads vehicles: `title_applications_controller.rb:12`, `:16`.
  - Lien filings R (gate): `status_tracker.rb:15`.
  - Status events W: `status_tracker.rb:26`.
- **DealerPortal**
  - Reads deliveries, vehicles, and registrations: `app/services/dealer_portal/pending_registrations_query.rb:4-6`.
  - Reads customers: `app/views/dealer_portal/deliveries/index.html.erb:4`.
  - The app's only writer of its own table is TempTags (`issue_service.rb:40`); otherwise only seeds write it (`db/seeds.rb:292`).
- **Jurisdictions**
  - No table access. It still has code coupling to `CustomerAccounts`: `app/services/jurisdictions/washington.rb:17` reads `CustomerAccounts::Vehicle::WA_RTA_COUNTIES`, defined at `vehicle.rb:4`.
  - `Customer` validates against `Jurisdictions.codes` (`customer.rb:8`).
- **Dmv**
  - No table access. `app/services/dmv/adapters/fake_adapter.rb:7-8` reads only `record.id` and `record.jurisdiction_code`.
- **GoRouting / compatibility quote**
  - Routes RW: `app/controllers/go_routing/routes_controller.rb:4-5`, `:13-14`, `:19`, and `app/services/go_routing/quote_router.rb:10`.
  - Comparisons RW: `quote_router.rb:37` (also used by `app/jobs/go_routing/shadow_compare_job.rb:11`, `:23`) and `routes_controller.rb:7-8`.
  - `RegistrationQuoteService` (`app/services/registration_quote_service.rb:14-44`) and `POST /api/v1/registration_quotes` (`app/controllers/api/v1/registration_quotes_controller.rb:4-59`) touch no table.
- **Dashboard**
  - `app/controllers/dashboard_controller.rb:3-8`.
- **Seeds**
  - `db/seeds.rb:140`, `:181`, `:187`, `:198`, `:227`, `:238`, `:249`, `:262`, `:267`, `:274`, `:292`, `:300-304`.

## 2. Cross-domain callbacks

| # | Callback | Trigger | Effect outside its own domain |
|---|---|---|---|
| C1 | `Registrations::Registration after_commit :create_submission_records` (`app/models/registrations/registration.rb:9`, `:17-23`) | Any committed update that changes `status` to `"submitted"` (`registration.rb:13-15`), whether or not it goes through `SubmissionService` | Recomputes the quote from live vehicle and customer data (`registration.rb:18`). Creates a pending `LienFilings::LienFiling` (`:29-39`) plus a `lien_filings` status event (`:40-48`), unless a pending or filed lien already exists (`:27`). Creates a draft `Titling::TitleApplication` (`:54-60`) plus a `titling` status event (`:61-69`), unless a non-rejected application exists (`:52`). |
| C2 | `Registrations::Registration before_save :stamp_ontario_currency` (`registration.rb:8`, `:72-74`) | Every save | A jurisdiction-code check inside the Registrations model. The other currency value comes from the jurisdiction class (`registrations_controller.rb:32`). |

C1 is the main source of coupling, for these reasons:

- **Registrations writes LienFilings and Titling data directly.** C1 copies the creation logic of `LienFilingsController#create` (`lien_filings_controller.rb:25-35`) and `TitleApplicationsController#create` (`title_applications_controller.rb:18-24`) instead of calling them.
  - The application-number format `"TA-<code>-<count+1>"` appears in three places: `registration.rb:57`, `title_applications_controller.rb:21`, and `db/seeds.rb:270`.
  - The two controller paths write no `status_events` row. The C1 path writes one.
- **The two records it creates get their jurisdiction from different sources.**
  - The lien uses `jurisdiction.code`, which comes from the vehicle's customer through `FeeCalculator` (`registration.rb:31`, `fee_calculator.rb:6`).
  - The title uses the registration row's own `jurisdiction_code` column (`registration.rb:56`).
- **C1 runs after the transaction, not inside it.** C1 is an `after_commit`, so it runs after `SubmissionService`'s `Registration.transaction` has committed (`submission_service.rb:6-22`). By then the DMV call (`submission_service.rb:4`) and the registration update are final.
  - Its four inserts (lien, lien event, title, title event) each autocommit separately. No transaction wraps them.
  - If one insert fails, the earlier ones stay committed and the later ones never run.

There are no other ActiveRecord callbacks in `app/models` besides C1 and C2. `TempTags::TempTag#status` (`app/models/temp_tags/temp_tag.rb:10-14`) derives `expired` at read time; it is not a callback.

Some cross-domain side effects are written directly in service code rather than as callbacks:

| # | Location | Effect |
|---|---|---|
| S1 | `app/services/temp_tags/issue_service.rb:40` | Issuing a temp tag sets every `scheduled` delivery for the vehicle to `delivered`. It uses `update_all`, so `DealerPortal::Delivery` validations and callbacks are skipped. |
| S2 | `app/services/titling/status_tracker.rb:15-17` | Titling refuses `in_review → issued` while the vehicle has any `pending` lien filing. It raises `LienPending`, which is rescued at `title_applications_controller.rb:32-33`. |
| S3 | `app/services/dealer_portal/pending_registrations_query.rb:4-6` | DealerPortal decides what is "pending" by loading every vehicle's registrations and filtering in Ruby on `submitted` or `approved`. |

Jurisdiction rules also live outside `app/services/jurisdictions/`. These are the three placements listed in ARCHITECTURE.md:

- `app/models/concerns/ontario_rules.rb`, included and extended at `app/services/jurisdictions/ontario.rb:5`, `:20`.
- `app/controllers/concerns/texas_in_transit_override.rb:2-6`, included at `app/controllers/temp_tags/temp_tags_controller.rb:3` and `app/controllers/api/v1/temp_tags_controller.rb:4`, then used at `:35` and `:29` respectively.
- `CustomerAccounts::Vehicle::WA_RTA_COUNTIES` (`vehicle.rb:4`), read by `jurisdictions/washington.rb:17` and `db/seeds.rb:110`.

Temp-tag validity is therefore computed in two layers. The controller decides the days (`temp_tags_controller.rb:35`) and hands them to `IssueService`, which computes `default_days` again (`issue_service.rb:17-18`, `:28`).

## 3. Shared transactions

| # | Transaction | Tables written atomically | Outside call |
|---|---|---|---|
| T1 | `Registration.transaction` in `app/services/registrations/submission_service.rb:6-22` | `registrations`, `status_events` | `Dmv::Gateway.submit("registration", …)` at `:4`, **before** the transaction |
| T2 | `LienFiling.transaction` in `app/services/lien_filings/filing_service.rb:8-20` | `lien_filings`, `status_events` | `Dmv::Gateway.submit("lien_filing", …)` at `:6`, **before** the transaction. The only idempotency guard is `return filing if filing.status == "filed"` (`:4`) |
| T3 | `ApplicationRecord.transaction` in `app/services/temp_tags/issue_service.rb:21-41` | `temp_tags`, `status_events`, `dealer_portal_deliveries` | none |
| T4 | `ApplicationRecord.transaction` in `app/services/titling/status_tracker.rb:24-36` | `title_applications`, `status_events` | none. The lien gate read (`:15`) happens **before** the transaction |

Notes:

- All four use the same connection today, so whether they are written `Registration.transaction`, `LienFiling.transaction`, or `ApplicationRecord.transaction` makes no difference. That stops being true once any of these classes connects to a different database.
- In both DMV paths (T1, T2), the outside agency call happens before the local write. A DB failure afterward leaves a DMV submission with no local record of it.
- Some multi-row writes run with no transaction at all:
  - C1 (above).
  - `db/seeds.rb:238-258`: a lien plus its event.
  - `db/seeds.rb:267-284`: a title plus its event.
  - `TempTagsController#void` (`temp_tags_controller.rb:42`) changes status and writes no event.
- Number generation reads `COUNT(*)` outside any lock or transaction: `issue_service.rb:19`, `registration.rb:57`, `title_applications_controller.rb:21`. Uniqueness is enforced by the unique indexes at `db/schema.rb:144` (`temp_tags.tag_number`) and `db/schema.rb:159` (`title_applications.application_number`).

## 4. Shared tables

| Table | Owner (by namespace) | Written by | Read by |
|---|---|---|---|
| `status_events` | none (top-level `StatusEvent`, `app/models/status_event.rb:1-6`) | Registrations (T1, C1 on behalf of LienFilings and Titling), LienFilings (T2), TempTags (T3), Titling (T4), seeds (`db/seeds.rb:249`, `:274`) | CustomerAccounts vehicle activity feed (`vehicles_controller.rb:5`, `vehicles/show.html.erb:29-32`) |
| `customer_accounts_vehicles` / `customer_accounts_customers` | CustomerAccounts | CustomerAccounts (customers), seeds (vehicles) | Every domain, both for display and as rule input. `FeeCalculator`, `IssueService`, and `LienFilingsController#create` build a `Jurisdictions::QuoteInput` from vehicle columns, and the jurisdiction comes from `customer.jurisdiction_code` (`vehicle.rb:22-24`). |
| `lien_filings` | LienFilings | LienFilings, Registrations (C1) | Titling (S2), Registrations (C1 guard, `registration.rb:27`), CustomerAccounts, Dashboard |
| `title_applications` | Titling | Titling, Registrations (C1) | Registrations (C1 guard and count, `registration.rb:52`, `:57`), CustomerAccounts, Dashboard |
| `dealer_portal_deliveries` | DealerPortal | TempTags (S1), seeds | DealerPortal, CustomerAccounts |
| `registrations` | Registrations | Registrations, seeds | DealerPortal (S3), Dashboard, CustomerAccounts |

`status_events` details:

- It accepts a fixed list of domains (`status_event.rb:4`).
- It has a real foreign key to vehicles (`db/schema.rb:167`).
- Its subject reference is a free-form `subject_type`/`subject_id` pair with no foreign key (`db/schema.rb:119-131`).
- `Vehicle has_many :status_events` has no `dependent:` option (`vehicle.rb:13`). Every other vehicle association uses `dependent: :destroy` (`vehicle.rb:8-12`).

The `go_routing_*` tables are used only by GoRouting. They reference jurisdiction codes through `RegistrationQuoteService::SUPPORTED_STATES` (`app/models/go_routing/route.rb:6`, `app/models/go_routing/comparison.rb:6`), not through foreign keys.

## 5. What would break if `registrations` moved to its own database

This assumes `Registrations::Registration` moves to a second database (for example an abstract `RegistrationsRecord` with `connects_to`) while everything else stays on the primary.

**Breaks or changes behavior**

1. **Foreign key.** `registrations.vehicle_id → customer_accounts_vehicles` (`db/schema.rb:166`, created by `t.references … foreign_key:` in `db/migrate/20261004000000_create_lucid_vehicle_services_tables.rb`) can't exist across databases. Referential integrity becomes the application's job.
2. **T1 stops being atomic.** `Registration.transaction` (`submission_service.rb:6`) would open a transaction on the registrations database only. The `StatusEvent.create!` at `:12` would autocommit on the primary.
   - If the event insert fails, the registration update rolls back, but the DMV call (`:4`) has already happened.
   - If the registrations commit fails after the event committed, the activity feed shows a `submitted` change that never happened.
3. **C1 becomes a cross-database fan-out with no transaction.** C1 would fire on commit of the registrations database. It then reads and writes `lien_filings`, `title_applications`, and `status_events` on the primary (`registration.rb:27-69`). It also reads `vehicle`/`customer` again through `FeeCalculator` (`:18`) and `TitleApplication.count` (`:57`). Today's partial-failure window still exists, now across two databases. Registrations would also still need write access to two other domains' tables.
4. **Cascading deletes.** `Vehicle has_many :registrations, dependent: :destroy` (`vehicle.rb:8`), reached from `Customer` (`customer.rb:5`), would delete rows in another database outside the vehicle's transaction.
5. **Schema, config, seeds, and tests assume one database.**
   - `config/database.yml` defines one database per environment.
   - `db/schema.rb` holds every table.
   - `Registrations::Registration < ApplicationRecord` (`registration.rb:2`).
   - Seeds create registrations, then drive C1 through `SubmissionService` in the same loop as vehicles, liens, and titles (`db/seeds.rb:185-201`).
   - `spec/services/status_events_spec.rb:26-61` asserts that one submit yields events in three domains. With `use_transactional_fixtures` (`spec/rails_helper.rb:41`), it would need both connections wrapped.
6. **Shared `status_events` ownership.** `registrations` events (`submission_service.rb:12-21`) are written to a primary-database table and read by the vehicle feed (`vehicles_controller.rb:5`). Either Registrations keeps writing cross-database, or its events move out and the feed has to merge two sources.

**Keeps working, but becomes cross-database**

- The codebase never uses `joins`, `references`, or SQL that touches `registrations` together with another table. Every cross-table read is an `includes` preload or a separate query, and Rails can run those against separate connections:
  - `registrations_controller.rb:4`, `:10` (`includes(vehicle: :customer)`)
  - `dashboard_controller.rb:3`, `:7`
  - `customers_controller.rb:13`
  - `vehicles_controller.rb:4`
  - `pending_registrations_query.rb:4`
- `PendingRegistrationsQuery` (`pending_registrations_query.rb:4-6`) already filters in Ruby, so it keeps working. It can never become a single SQL anti-join, though, and it loads every registration for every delivery vehicle.
- `FeeCalculator` (`fee_calculator.rb:6-14`) and the `new`/`create` vehicle pickers (`registrations_controller.rb:15`, `:20`, `:23`, `:41`) read vehicle and customer data from the primary.
- `Dmv::FakeAdapter` uses only `record.id` and `record.jurisdiction_code` (`fake_adapter.rb:7-8`), so it doesn't care where the row lives.

**Unaffected**

- `POST /registration_quotes`, `RegistrationQuoteService`, `GoRouting`, and `POST /api/v1/registration_quotes`. Despite the name, none of these touch the `registrations` table (§1).

## 6. Suggested extraction order

How each domain uses data and outside services:

| Domain | Nature | Owns tables | Writes others' tables | Outside calls | Inbound coupling |
|---|---|---|---|---|---|
| Jurisdictions | Pure calculation | none | none | none | Used by every domain. `WA_RTA_COUNTIES`, `OntarioRules`, and `TexasInTransitOverride` sit outside it |
| Compatibility quote (`RegistrationQuoteService`, `/api/v1/registration_quotes`, `/api/v1/lien_determinations`) | Pure calculation | none | none | GoRouting calls registration-go (`go_routing/client.rb:11-23`) | Frozen contract. Already shadowed per jurisdiction |
| GoRouting | Ops tooling for the above | `go_routing_*` | none | registration-go over HTTP. Shadow mode uses ActiveJob's default `:async` adapter in-process, since no `queue_adapter` is configured | none |
| DealerPortal | Read model | `dealer_portal_deliveries` (no app writer of its own) | none | none | Its table is written by TempTags (S1) |
| TempTags | Writes data, calculation-heavy | `temp_tags` | `dealer_portal_deliveries`, `status_events` | none | Read-only (CustomerAccounts, Dashboard) |
| Titling | Writes data, workflow | `title_applications` | `status_events` | none | Created by Registrations (C1); gates on `lien_filings` (S2) |
| LienFilings | Writes data, calls DMV | `lien_filings` | `status_events` | DMV (`filing_service.rb:6`) | Created by Registrations (C1); read by Titling (S2) |
| Registrations | Writes data, calls DMV, orchestrates | `registrations` | `lien_filings`, `title_applications`, `status_events` | DMV (`submission_service.rb:4`) | Read by DealerPortal, Dashboard, CustomerAccounts |
| CustomerAccounts | Reference data hub | customers, vehicles | (cascade deletes) | none | Every table has a foreign key to vehicles |

**Step 0: decouple inside the monolith first.** None of this needs a second database.

- Give `status_events` an owner and a single write API (or a per-domain outbox) so domains stop inserting into it directly.
- Replace C1 with explicit calls from the Registrations flow into LienFilings and Titling services, so each domain owns its own create logic and the multi-row write is visible.
- Move the three jurisdiction-rule placements and C2 into `app/services/jurisdictions/`.
- Make the DMV calls in T1 and T2 idempotent (or record intent before calling), since both happen before the local write.

**Suggested order**

1. **Jurisdictions and the compatibility quote endpoints.**
   - These are pure calculations: no tables, no outside agency calls.
   - They already sit behind `GoRouting::QuoteRouter` with per-jurisdiction legacy/shadow/go modes and a kill switch.
   - The lien-determination API is pure too, so it moves with them.
   - The only prerequisite is relocating the rule placements listed in Step 0. GoRouting retires once every route is `go`.
2. **TempTags.**
   - The only writer with no outside agency call and no inbound writes from other domains.
   - Its logic is mostly a rules lookup (step 1).
   - Its one outbound write, S1 (`issue_service.rb:40`), becomes a `TempTagIssued` event that DealerPortal consumes.
   - This proves the event and outbox pattern before any DMV-calling domain moves.
3. **Titling.**
   - Writes data but calls no outside agency.
   - Needs two seams: a "create draft title" command to replace C1's insert, and a "pending liens for vehicle?" query to replace S2 (`status_tracker.rb:15`). The query can be answered by the monolith until LienFilings moves.
4. **LienFilings.**
   - The first DMV caller to move (`filing_service.rb:6`).
   - Should go once the outbox and idempotency approach from steps 2–3 is proven, because a duplicate DMV submission can't be rolled back.
   - Needs a "create pending lien" command (replacing C1 at `registration.rb:29-48`) and must serve Titling's lien-status query.
5. **Registrations.**
   - Moves last among the writers. It calls the DMV, orchestrates two other domains (C1), and has the most inbound readers (DealerPortal, Dashboard, CustomerAccounts).
   - By this point C1 should already be commands into the extracted Titling and LienFilings services. §5 lists what remains: the foreign key, T1 atomicity, cascades, seeds, and specs.
6. **DealerPortal and the Dashboard.**
   - Both read across domains (S3, `dashboard_controller.rb:3-8`). Rebuild them as projections fed by the events introduced above, rather than moving them as-is.
7. **CustomerAccounts stays as the system of record.**
   - Every table has a foreign key to vehicles, and every rule input comes from vehicle and customer columns. Other domains should reference it by `vehicle_id` through an API or a replicated read model, not extract it.
