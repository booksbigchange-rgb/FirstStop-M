# FirstStop-M — MVP project plan

## Product requirements
Manage one car wash and its coffee shop from a shared Flutter Android/Web app.
Roles planned: owner, manager, cashier, washer, barista.
Modules planned: authentication, wash queue, coffee POS, payments ledger (manual cash/Telebirr/bank), inventory, expenses, financial reporting.

## Technical requirements
Flutter / Dart; Supabase free-tier PostgreSQL and Authentication for production pilot.
Use Row Level Security for every business table. Never include service-role keys in Flutter builds.
Default currency ETB. No automated payment integration in MVP.
Flutter Web can be deployed on GitHub Pages after CI is verified.

## App flow
Login -> role-based dashboard -> wash queue or coffee POS -> create order -> mark paid -> reporting.
Owner/manager -> pricing, inventory, expenses and staff management.
All transactions require clear errors, retry protection and audit history.

## Design brief
Mobile-first Material 3. Large POS action targets, high contrast, blue wash identity and warm coffee identity.
English and Amharic from the start; ensure Ethiopian script glyph coverage and review translations with native speakers.

## Database and access design (planned)
businesses, profiles, wash_services, wash_jobs, products, orders, order_items,
payments, inventory_items, stock_movements, expenses, staff_shifts, audit_logs.
Enforce business_id scoping, RBAC and database policies. Never use only client UI checks for access.

## Testing and launch
Unit and widget tests; database permission tests (cross-user and role denied access),
payment duplicate prevention, money calculations, inventory deduction, end-of-day reconciliation,
backup/export and restore test, Android and Chrome manual tests.
Release requires validation on physical devices and confirmation of free-tier limitations.

## Stage 0 — current repository changes
UI-only local demo. Wash tickets and coffee orders exist only in memory and disappear on app restart.
No backend, role authentication, money movement or real financial totals yet.

## Delivery order
1. Flutter scaffold and bilingual preview
2. Supabase schema, RLS and auth
3. Car wash orders and lifecycle
4. Coffee checkout
5. Stock, expenses and dashboards
6. Backup/export, accessibility and pilot
