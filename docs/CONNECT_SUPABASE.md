# Connect FirstStop-M to Supabase

The Flutter application accepts configuration at build/run time:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

For web production builds, pass the same --dart-define flags to `flutter build web`. Publishable keys are designed for public clients; **never provide a Supabase secret/service_role key**. Never commit a database password.

Until both flags are present, FirstStop-M remains in local-demo mode. Even when configured, it only initializes the Supabase client: login, queries, migrations, and secured order writes are **not yet connected**. Do not use for business transactions yet.

Supabase Dashboard -> SQL Editor: after reviewing migration in draft PR #2, run it in the project and provision owner account using privileged SQL. Do not run the Supabase Todos sample: FirstStop-M has a different schema.
