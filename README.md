# Lucid Vehicle Services

Lucid Vehicle Services is a full-stack demo legacy system for vehicle registration, titling, and dealer operations. It provides server-rendered operational workflows and JSON APIs over fictional rules for US and Canadian jurisdictions.

## Setup

Requirements: Ruby 3.3.6 and SQLite.

```sh
bundle install
bin/rails db:setup
bin/rails tailwindcss:build
bin/rails s
```

The seed data is deterministic and may be loaded again with `bin/rails db:seed`. For local development, run `bin/dev` if available, or run the asset build and Rails server commands above. Preview hosts may be allowed in development with `RAILS_DEVELOPMENT_HOSTS=.preview.devinapps.com`.

All DMV submissions use a deterministic fake adapter and do not call external services.

## Tests and fixtures

```sh
bundle exec rspec
bundle exec rake golden:capture
```

The golden capture task replays `fixtures/recorded_requests.json` and writes `fixtures/expected_responses.json`.

## Documentation

See [docs/API.md](docs/API.md) for the JSON API and [ARCHITECTURE.md](ARCHITECTURE.md) for domain boundaries and service design.
