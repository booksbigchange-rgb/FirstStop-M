# FirstStop-M manual verification checklist

**Environment:** Supabase `oqsniminuhewtvafetmt`; Flutter branch `feat/supabase-setup-verified`.

## Mandatory owner-browser checks
- [ ] GitHub Pages deployment workflow succeeds and preview site loads without errors.
- [ ] Login screen shows email/password (do not share credentials).
- [ ] Switching to **አማርኛ** changes labels without garbled characters.
- [ ] Invalid/blank login shows an understandable error and never displays business information.
- [ ] Real owner login succeeds with the separately provisioned confirmed account.
- [ ] Role displays **Owner / ባለቤት** and staff management controls are visible.
- [ ] Empty wash/coffee lists are correctly shown; there are no fake sales totals.
- [ ] Language preference remains after sign-out/sign-in.
- [ ] Sign out hides data and returns to login.
- [ ] Unassigned user cannot see business data.

## Existing automated verification
- `flutter analyze` (passed).
- `flutter test` (passed).
- Flutter web build (passed on the CI validation branch).
- Supabase 8 public tables with RLS, one confirmed owner profile, no operational records (audited via Supabase).
- Authenticated API users have SELECT-only grants on business tables; operational writes are disabled pending controlled server functions.

## Known limits
A green CI build does not prove end-to-end login from a real browser. We cannot perform that with the owner's password. Supabase Auth and the GitHub Pages origin must be tested on an actual browser. Do not share credentials in issues, screenshots or chats.

No wash payment, coffee checkout, inventory deduction or live financial reporting is operational yet. Treat the preview as a read-only access/security pilot.
