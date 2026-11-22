# First release: duplication audit and iPhone installation

- Trace routes, modal entry points and data writes. Keep shortcuts that serve different contexts; remove duplicate controls, dead widgets and duplicated save flows.
- Keep intentional identical meals/sets possible; make retries of one draft use the same identity instead of content-based deduplication.
- Verify app route coverage, regression tests, signed iOS Release installation and startup. Record limitations for production acceptance; do not submit to stores or mutate user records for QA.
