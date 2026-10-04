---
name: lucid-vehicle-services-runtime-testing
description: Run the Rails vehicle-services demo and verify browser workflows with seeded jurisdiction data.
---

# Local runtime

- Use Ruby 3.3.6 from `~/.rubies/3.3.6/bin` and run `bundle install`.
- Build styles with `bin/rails tailwindcss:build`. Start with `RAILS_DEVELOPMENT_HOSTS=.preview.devinapps.com bundle exec rails s -b 0.0.0.0`.
- Reuse an existing port 3000 server when available. If explicitly replacing it, target the port with `fuser -k 3000/tcp`, not a broad process-name kill.
- The demo has no login. `bin/rails db:reset` restores deterministic seeds but destroys test mutations; only do this when authorized.
- Browser routes are `/`, `/registrations`, `/temp_tags`, `/lien_filings`, `/title_applications`, `/dealer_portal/deliveries`, `/customers`, and `/jurisdictions`.
- API requests are documented in `docs/API.md`; quotes use `/api/v1/registration_quotes`.

# Evidence and pitfalls

- Dealer Portal links preselect vehicles on registration and temporary-tag forms.
- Use a personal-use CA vehicle for 90-day temporary-tag checks; not all seeded CA vehicles have personal usage.
- Title applications already issued cannot demonstrate transitions; choose a draft and advance to submitted, in_review, issued.
- Fake DMV submissions log `[FakeDMV] submitted registration <id>` in `log/development.log`. This proves adapter invocation, not syscall-level network absence. Attaching strace to an existing process may be denied by ptrace policy.
- Chrome date inputs advance segments automatically after complete month/day input. Screenshot the entered date before submitting to avoid unintended seed mutations.

## Devin Secrets Needed

None for the local seeded demo.
