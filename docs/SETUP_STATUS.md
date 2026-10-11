# FirstStop-M setup — 11 October 2026

## Verified live
- Project `oqsniminuhewtvafetmt`, organization subscription `free`.
- Original seven-table foundation was already applied manually, with no migration history.
- `0002_staff_access.sql` and `0003_revoke_anon_helpers.sql` applied through Supabase migrations.
- One FirstStop-M business and confirmed owner account provisioned. No credentials are in source control.
- `supabase/tests/access.sql` passed against the live database inside a rolled-back transaction. No test users or orders remain. A real anonymous HTTP request to the REST API returned 401 / permission denied, as expected.
- Business tables have RLS. Anonymous table access and direct client writes are revoked.

## Access matrix
| Role | Wash data | Cafe data | Staff list | Assign/disable staff |
|---|---|---|---|---|
| Owner | Yes | Yes | Yes | Yes |
| Manager | Yes | Yes | Yes | No |
| Cashier | Yes | Yes | Own profile | No |
| Washer | Yes | No | Own profile | No |
| Barista | No | Yes | Own profile | No |

All access is restricted to the current business. Disabled or unassigned accounts have no business access. Only a trusted administrator can create or transfer an owner. Owners cannot demote themselves or claim another business's staff. Changes to staff access are recorded in `staff_audit`.

## Run
Use the existing Flutter SDK (do not reinstall it):

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --dart-define-from-file=config/project.json
flutter build web --release --dart-define-from-file=config/project.json
```

`config/project.json` intentionally contains only the public project URL and publishable key. These are client configuration, not administrator credentials. Never add service-role keys, database passwords, access tokens or user passwords.

Without build configuration, the original in-memory demo remains available. With configuration, the app requires Supabase login, loads the assigned role and displays live data. Language preference is saved for active accounts. Failed refreshes clear previously loaded business data.

## Staff onboarding
1. Create each staff login under Supabase Authentication, using a unique email and password, and confirm the account. Do not share the owner password.
2. Sign in as owner in the app.
3. Enter the confirmed staff email, name and job role under Set staff access; save.
4. Test that staff login. To revoke business access, save the same email with Account enabled off.

No real staff accounts were invented. Their names and email addresses are still required.

## Budget and remaining scope
No paid plan, database branch, SMTP service, SMS service, payment API or hosting subscription has been enabled. Use local development and the existing Free Supabase project. Check quotas before a pilot; the free service may pause and is not an availability guarantee.

Operational writes, payment processing, stock, expenses, financial reports and backup/restore are not implemented. The connected app deliberately shows read-only orders. This is authentication and access setup, not a complete POS release.

The security advisor's authenticated SECURITY DEFINER notices describe intentional, tested RPCs. Leaked-password protection remains disabled; do not upgrade to a paid plan to enable it under the $0 constraint. Amharic text is implemented but needs native-speaker review before release.

Local Flutter execution was blocked by Windows SDK file access. GitHub CI is prepared to validate analysis, widget tests and the configured web build. Public branch and draft PR upload approved by the owner. Flutter build and widget-test results are pending. A physical Android test remains a separate requirement before an Android release; the repository does not yet contain an Android runner.

For a fresh database apply migrations in order. On the current project do not rerun `0001_initial.sql`: it was already applied manually. The original setup docs describe the earlier milestone; this document records the current setup.

Security advisor references: [intentional authenticated functions](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable), [leaked-password protection requires Pro](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).
