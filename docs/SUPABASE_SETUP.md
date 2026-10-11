# Supabase foundation — Milestone 2

This migration is committed but **not yet applied to a live Supabase project**.

## Setup checklist
1. Create a new Supabase Free project under the business owner's account.
2. Open SQL Editor and apply `supabase/migrations/0001_initial.sql`.
3. Create a test user in Supabase Authentication.
4. Provision one `businesses` row and one owner `profiles` row using trusted administrator SQL (never exposed in Flutter).
5. Verify login and permissions from two separate test accounts and unrelated businesses.
6. Only then add the public project URL and publishable key via runtime configuration; never commit secret or service-role keys.

## Access model
- All operations are denied by default unless an RLS policy permits them.
- Authenticated staff may read rows belonging to their own business.
- No clients may directly mutate transactions, pricing, profiles or payment records yet.
- Roles are stored centrally and must be enforced in transactional server-side functions.
- Database contents are not currently synchronized to Flutter.

## Upcoming work
Implement controlled `create_wash_job`, `create_cafe_order`, `update_job_status`
and checkout functions with validation, tenant scoping, trusted price snapshots,
audit trail and idempotency. Add inventory and payment ledger after the checkout
model is reviewed. Write RLS tests for roles and cross-business access.

## Budget and safety
Free tier is for development/pilot only. Backups and recovery must be tested
before business use. Manual Telebirr entries are not verified electronic payments.
