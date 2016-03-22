# [Nightli.es](https://nightli.es/)

Nightli.es provides automatic nightly builds for [Travis CI](https://travis-ci.org/).

## Why have nightly builds?

When developing a library, often some components like other libraries or the
language interpreter will use the latest available version. This can lead to
nasty situations when an upstream component releases a new version that breaks
your tests, but you don't find out until your next git push.  Nightli.es
ensures each project builds at least once every 24 hours so these failures will
be caught as soon as possible.

## Why does Nightli.es require so many GitHub permissions?

Nightli.es uses the Travis API to get the list of projects you have access to
and to kick off builds. Unfortunately Travis' GitHub authentication integration
requires that I request all the same permissions as Travis itself. Your GitHub
OAuth tokens are never stored server-side, only your Travis API token is stored
for use in starting builds via the API.
