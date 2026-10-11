# FirstStop-M

**Work-in-progress:** zero-budget Flutter car wash + coffee shop management app.
Flutter Web is ready for an owner sign-in pilot; **do not use for real checkout yet**.

## Features currently implemented
- Responsive Flutter starter and a bilingual English / Amharic interface.
- Supabase email/password sign-in when built with a project configuration.
- Owner / manager / cashier / washer / barista permissions backed by PostgreSQL RLS.
- Read-only car wash queue, café order list, staff roster and owner-only staff assignment.
- In-memory demonstration mode when no Supabase build configuration is provided.
- Flutter analyzer, widget tests and a compiled web build in GitHub Actions.

## Live environment
Existing Supabase project: `oqsniminuhewtvafetmt` (free tier). Its database was created and provisioned separately. Do **not** rerun `0001_initial.sql` on this existing project. Migrations `0002` and `0003` have already been applied there.

## Preview
A browser-preview workflow lives at `.github/workflows/pages-preview.yml` on the development branch.
It builds with `--base-href /FirstStop-M/` and uses only the publishable Supabase configuration.
GitHub Pages must be configured to use GitHub Actions for deployment; confirm the workflow's deployment result before sharing a URL.

## Local run
```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --dart-define-from-file=config/project.json
```

The file `config/project.json` has the publicly distributable project URL and publishable key, **not** administrator credentials. Do not commit passwords, session tokens or service-role keys. Use a password only in Supabase authentication screens.

## Project status
See `docs/SETUP_STATUS.md` and `docs/VERIFICATION_CHECKLIST.md`.
Payments, stock changes, expenses, invoice exports, employee logins beyond the owner and Android builds are **not verified or delivered**.
