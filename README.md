# moon_guard_flutter

Moon Guard (Flutter) — same flows as the Expo app in this repo, with Supabase.

## Supabase key (required — or you only see “Supabase key required”)

**Recommended:** one-time `env.json` in **this** folder (same key as `EXPO_PUBLIC_SUPABASE_ANON_KEY`).

1. Copy `env.json.example` → `env.json`.
2. Set **`SUPABASE_URL`** to your project URL and **`SUPABASE_ANON_KEY`** to the **anon** public key (Dashboard → **Project Settings** → **API**).  
   `env.json` is gitignored — do not commit it.

## Database (Supabase)

Run the SQL in **`supabase/migrations/20260427000000_moon_guard_profiles.sql`** once (Dashboard → **SQL** → **New query** → Run). It creates:

- **`public.profiles`** — columns match the Flutter `Profile` model; **RLS** so users only read/update their own row
- **`get_parent_id_by_key(text)`** — used when a child links with a parent code (avoids wide-open table scans)

If you already have a `profiles` table, compare columns before running; for a new project, run the script as-is.

2. **Feature tables** (children, map, chat, safety, routines): run **`supabase/migrations/20260427120000_moon_guard_features.sql`**. It adds `child_profiles` (max **5** per parent in the app), `location_points`, `chat_messages` (with Realtime), `blocked_keywords`, `filter_block_logs`, `blocked_apps`, `routines`, and a private **`chat-media`** storage bucket. Then in Supabase **Database → Replication**, enable **Realtime** for `chat_messages` (and optionally `location_points`) if you want live updates.

3. **Retention (7d locations / 30d chat)** is commented at the end of the features migration; schedule those deletes (e.g. **pg_cron** or a weekly **Edge Function**).

4. **Geofence, alerts, strict app lock (columns + `parent_alerts` table):** run **`supabase/migrations/20260428120000_geofence_alerts_pin.sql`**. Then enable **Realtime** for `location_points` if the parent app should get live map updates from the child’s device.

**Then run (Chrome, local web server, Windows, or phone):**

```text
cd moon_guard_flutter
flutter pub get
```

**Localhost web (stable URL for Google / Supabase redirects — recommended):**  
Add **`http://localhost:8080`** to Supabase → **Authentication** → **URL Configuration** → **Redirect URLs** (and keep **Site URL** compatible, e.g. `http://localhost:8080` for dev).

```text
.\run_web_local.ps1
```

**Or** Chrome (port changes each run unless you add flags):

```text
flutter run -d chrome --dart-define-from-file=env.json
```

**Or** Windows: **`.\run_with_env.ps1 -d chrome`** / **`.\run_with_env.bat -d chrome`**

For a **physical Android** device, use `-d <id>` from `flutter devices`.

### Android Studio

1. **File → Open** the **`moon_guard_flutter`** folder (where `env.json` and `pubspec.yaml` live), not the parent monorepo only.
2. **Run → Edit Configurations** → Flutter → **Additional run args**:
   ```text
   --dart-define-from-file=env.json
   ```
3. If you opened the **parent** folder in the IDE, set **Run configuration** working directory to `moon_guard_flutter`, or use an **absolute** path to `env.json` in Additional run args, e.g. ` --dart-define-from-file=C:\path\to\moon_guard_flutter\env.json`
4. **Flutter & Dart** plugins, Flutter SDK, and `flutter pub get` as usual. First Gradle/NDK download can take a long time.

**Without `env.json`:** you can still pass the key once:

`flutter run --dart-define=SUPABASE_ANON_KEY=eyJ...`

## Android Studio / Windows notes

- **flutter.sdk** in `android/local.properties` — set in **File → Settings → Languages & Frameworks → Flutter** if missing.
- **Developer Mode** (symlink support for some plugins): `Win` + `R` → `ms-settings:developers` → enable **Developer mode**.
- App id: **`com.moonguard.app`**, OAuth callback scheme **`com.moonguard.app://login-callback/`** (in `android/app/src/main/AndroidManifest.xml`).

## Command line (single-line key)

```text
cd moon_guard_flutter
flutter pub get
flutter run --dart-define=SUPABASE_ANON_KEY=your_key
```

[Flutter documentation](https://docs.flutter.dev/)
