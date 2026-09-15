# Running Jerd

Jerd has two parts: the Flutter app (`lib/`) and the Flask backend (`backend/`).
The app works fully offline without any backend, so you can start with step 1
alone.

## 1. The app, offline demo (no accounts needed)

```bash
flutter pub get
flutter run            # Android phone/emulator, or -d windows
```

Sign in with `karim@example.com` / `123456` (owner) or `amina@example.com` /
`123456` (staff). A sample shop is loaded into the local SQLite database. The
Sync tab shows "Demo mode" because no server is configured.

### Choosing the data source

`DATA_SOURCE` picks the repositories in `lib/di/service_locator.dart` —
switching is one line there, or a flag here:

| Value | Repositories | Use |
|---|---|---|
| `db` (default) | SQLite + sync queue | Real use, offline-first |
| `dummy` | In-memory | Early UI work, demos without state |
| `api` | Straight to the backend | Online-only comparison |

```bash
flutter run --dart-define=DATA_SOURCE=dummy
```

## 2. The backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate          # macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
copy .env.example .env          # then edit it
python -m scripts.seed --shop "My shop" --name Karim --email karim@example.com --password secret123
python wsgi.py                  # http://localhost:5000/health
pytest                          # 14 API tests
```

Point the app at it (the Android emulator reaches your PC at `10.0.2.2`):

```bash
copy config\dev.example.json config\dev.json
flutter run --dart-define-from-file=config/dev.json
```

### Deploying to Render + Supabase

1. **Supabase**: create a project, open the SQL editor and run
   `backend/schema.sql`. Copy the connection string (Project settings →
   Database → URI).
2. **Render**: New → Blueprint → select this repo. `render.yaml` creates the
   API and the nightly digest cron job. Fill `DATABASE_URL` and the other
   secret variables. Every push to GitHub redeploys.
3. Run the seed script once with `DATABASE_URL` pointing at Supabase.
4. Build the app with `API_BASE_URL=https://<your-service>.onrender.com`.

## 3. Cloud services

Each one is optional; the app keeps working without it.

| Service | Where the key goes | What to do |
|---|---|---|
| **Supabase** | Backend `DATABASE_URL` | See above |
| **Firebase Cloud Messaging** | `android/app/google-services.json` (app) and `FIREBASE_CREDENTIALS` (backend) | Create a Firebase project, add the Android app `dz.jerd.app`, download `google-services.json`. Generate a service-account key for the backend. Test with `python -m scripts.send_test_push --shop <id> --product <uuid>`. |
| **Cloudinary** | `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_UPLOAD_PRESET` (app) | Settings → Upload → add an **unsigned** preset. Photos are kept on the phone and uploaded on the next sync. |
| **Sentry** | `SENTRY_DSN` (app and backend) | Create a Flutter and a Flask project. |
| **Gemini** | `GEMINI_API_KEY` (backend only) | Google AI Studio → API key. Enables "Suggest name from photo" and "Reorder ideas". |

No secret is compiled into the app: the database, Firebase admin and Gemini
keys live only on the server. The Cloudinary preset is unsigned by design.

## 4. Tests

```bash
flutter test                         # domain, SQLite + sync, cubits, widgets
flutter test integration_test -d windows   # end-to-end on a device or desktop
cd backend && pytest
```
