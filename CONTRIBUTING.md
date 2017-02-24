## Dependencies

- Ruby 2.3.x (2.4.0 currently fails a `json` gem issue)
- Postgresql 9.x

## Env Vars

- `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET`
- `DATABASE_URL=postgres://localhost` or whatever appropriate location your database is at.

## Get going

1. Install deps:  `bundle install`
1. Init the db schema: `rake schema`
1. Run the app: `bundle exec ruby app.rb`
1. Load the website: http://localhost:4567
