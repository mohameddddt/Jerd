# Jerd — offline-first stock control for a small shop

> **Jerd** (جرد) is the Arabic word for a stock count — the one job this app has to do well.

A capstone project specification for the ENSIA Mobile Development course. It is scoped so that a
single small app exercises every topic in the module, from the business case in Lecture 2 to the
signed release bundle in Lecture 13.

**The app in one sentence:** a shop owner scans a barcode, records `+12 received` or `−1 sold`, and
the app keeps a running stock level per product — working all day with no signal, reconciling with
the backend when it gets one, while the backend pushes a notification when something is about to
run out.

---

## Table of contents

1. [Why this idea](#why-this-idea)
2. [Scope guard](#scope-guard)
3. [Features by screen](#features-by-screen)
4. [Data model](#data-model)
5. [Architecture](#architecture)
6. [The sync design](#the-sync-design)
7. [Cloud services](#cloud-services)
8. [Dependencies](#dependencies)
9. [Non-functional requirements](#non-functional-requirements)
10. [Course coverage](#course-coverage)
11. [Milestones](#milestones)
12. [Decisions to make first](#decisions-to-make-first)
13. [Deliverables checklist](#deliverables-checklist)

---

## Why this idea

- **The offline requirement is genuine, not decorative.** A shop in a basement or on a market street
  has no reliable data, but the count must never be lost — so the local SQLite database is the
  source of truth and the server is a follower. That is exactly the architecture Lectures 6, 10 and
  11 build toward.
- **The interesting logic is pure arithmetic on a ledger**, which is trivial to unit test and
  impossible to test if written inside a widget. It gives Lecture 12 something real to bite on.
- **It is a business, not a toy** — a subscription per shop, priced against the cost of running out
  of stock. Lecture 2's argument applies without having to invent it.
- **Private APK distribution to a handful of shops** maps directly onto the 2025/26 final exam's
  upgrade question, so the problem is lived rather than revised.

---

## Scope guard

The most likely way this project goes wrong is feature creep. The boundary is fixed here.

**In scope for v1**

- Products
- Stock movements and a running quantity
- Barcode scanning
- Offline queue and sync
- Low-stock alerts
- One shop with two or three staff accounts
- A simple daily summary

**Explicitly out of v1**

- Sales receipts and invoicing
- Prices and profit reporting
- Customers
- Multi-branch transfers
- Returns and refunds
- Printing

> Keep this exclusion list in the final report. Deliberately excluded scope reads as engineering
> judgement; forgotten scope reads as an unfinished app.

---

## Features by screen

| Screen | What the user does | Course machinery it exercises |
|---|---|---|
| **Login** | Email + password; stays logged in | Form validation, auth cubit with Initial / Loading / Success / Error, SharedPreferences flag |
| **Products list (home)** | Search, filter to "low stock only", pull to refresh, drawer, FAB to add | `ListView.builder`, `RefreshIndicator`, cubit state with loading / error / empty branches |
| **Scan** | Camera scans a barcode, jumps to that product or offers to create it | Hardware permission, camera plugin, navigation with a returned value |
| **Product detail** | Current quantity, reorder threshold, movement history, photo | Parent→child argument passing, image from cloud storage |
| **Add / edit product** | Name, barcode, unit, reorder point, photo from camera or gallery | Two-layer validation (form + repository), progress button, confirmation dialog on delete |
| **Record movement** | `+ received` / `− sold` / adjust, quantity, optional note | The core write path; every write also enqueues a sync job |
| **Stock count mode** | Walk the shelves scanning; the app lists differences between counted and expected, then commits them as one adjustment batch | Batch business logic, a timer showing count duration, an unsaved-work guard |
| **Alerts** | Items at or below their reorder point, sorted by urgency | Data derived by a pure function, never stored |
| **Sync status** | Pending items, last sync time, "sync now", conflict list | Connectivity cubit, background job status, offline banner |
| **Settings** | Language (AR / FR / EN), theme, staff accounts, sign out | Localisation with RTL, theme cubit, SharedPreferences |

---

## Data model

### Local — SQLite, the source of truth

| Table | Purpose | Key fields |
|---|---|---|
| `products` | One row per item | `uuid` (PK), `barcode`, `name`, `unit`, `reorder_point`, `image_url`, `updated_at`, `deleted` |
| `movements` | Append-only ledger of every `+`, `−` and adjustment | `uuid`, `product_uuid`, `delta`, `reason`, `note`, `created_at`, `user_id`, `synced` |
| `stock_counts` | One row per stock-take session | `uuid`, `started_at`, `finished_at`, `status` |
| `count_lines` | Counted quantity per product within a session | `count_uuid`, `product_uuid`, `counted_qty` |
| `sync_queue` | Outbox of local changes not yet accepted by the server | `entity`, `entity_uuid`, `operation`, `payload`, `attempts`, `last_error` |
| `settings` | Anything not worth a preference key | optional |

**Two design decisions worth defending in the report**

1. **The quantity is never a column you overwrite.** It is the sum of the movement ledger. Two
   devices can then add movements independently and both remain correct when merged — no lost
   update. Cache the computed total for display speed, but treat the ledger as truth.
2. **Primary keys are UUIDs generated on the device**, not auto-increment integers. A device offline
   for six hours must create rows that can never collide with rows another device created meanwhile.

### SharedPreferences

Logged-in flag and user id · theme · language · `last_sync_at` · id of an in-progress stock count ·
whether the offline banner was dismissed.

### Backend — PostgreSQL via Supabase, reached only through the API

The same tables, plus `users`, `shops` and `device_tokens` for push.

### API endpoints

| Endpoint | Purpose |
|---|---|
| `auth.login` | Exchange credentials for a session token |
| `products.get` | Everything changed since a timestamp |
| `products.upsert` | Create or update a product |
| `movements.push` | Accepts a **batch** of movements |
| `movements.get` | Ledger rows changed since a timestamp |
| `alerts.get` | Items at or below their reorder point |
| `device.register` | Register an FCM token for this device |

Everything that writes takes a client-generated UUID, so a retried request cannot double-apply.
That idempotency rule is what makes offline sync safe.

---

## Architecture

Four layers, one direction of dependency.

| Layer | Contains | Must not contain |
|---|---|---|
| **Presentation** | Screens, reusable widgets. Reads state, dispatches intent | Business rules, SQL |
| **Logic** | Cubits, plus a `domain` folder of pure functions | Any Flutter import in `domain` |
| **Data** | Repositories behind abstract interfaces, plus the sync service | UI concerns |
| **Infrastructure** | SQLite helper, HTTP client, storage upload, messaging, logging | Business rules |

Each repository has three implementations: **dummy** for early UI work, **SQLite** for real use, and
**API** for the server. Swapping between them must be a one-line change in the service locator.

### Folder structure

```
lib/
  data/
    databases/        dbhelper · db_base · db_products · db_movements · db_sync_queue
    models/           product · movement · stock_count · count_line
    repositories/     products_repo (abstract) · products_dummy · products_db · products_api
                      movements_repo (abstract) · movements_dummy · movements_db · movements_api
    services/         sync_service · storage_service · messaging_service
  logic/
    cubits/           auth · products · product_detail · stock_count · sync · connectivity
                      theme · locale
    domain/           stock_from_ledger · low_stock · reconcile_count · sync_backoff
  presentation/
    screens/          auth/ · products/ · scan/ · movement/ · count/ · alerts/ · sync/ · settings/
    widgets/          progress_button · my_snackbar · confirmation_dialog · product_card
                      offline_banner
    themes/           colors · styles · themes
  l10n/               app_en.arb · app_fr.arb · app_ar.arb
  main.dart           stays minimal
```

### Dependency wiring

GetIt registers the repositories, the sync service and the database helper as lazy singletons inside
an `init_my_app()` that runs from `main` before the app starts. Cubits resolve what they need from
GetIt rather than receiving it through constructors passed down the widget tree.

### Cubits and their states

| Cubit | States | Provided |
|---|---|---|
| `AuthCubit` | Initial · Loading · Authenticated · Error | Globally |
| `ProductsCubit` | Loading · Loaded(list, filter) · Empty · Error | Globally |
| `ProductDetailCubit` | Loading · Loaded(product, movements) · Error | Per screen |
| `StockCountCubit` | Idle · Counting(lines, elapsed) · Reconciling(differences) · Committed | Per screen |
| `SyncCubit` | Idle · Syncing(progress) · Failed(reason) · Conflicts(list) | Globally |
| `ConnectivityCubit` | online / offline | Globally |
| `ThemeCubit`, `LocaleCubit` | ThemeData / Locale | Globally |

Use state **classes**, not maps — the final exams ask for exactly that, and `Equatable` gives correct
rebuild behaviour for free.

> **One rule to hold to:** UI side effects — snackbars, dialogs, navigation — live in a
> `BlocListener`, never inside a cubit. A cubit that shows a snackbar cannot be unit tested, which is
> the whole point of Lecture 8.

---

## The sync design

This is where most of the marks and all of the difficulty are.

### Writing

Every local write does two things in one transaction: change the local tables, and append a row to
`sync_queue`. The UI is finished at that moment — it never waits for the network. This is what makes
the app feel instant on a bad connection.

### Draining the queue

A worker takes queued items oldest first, batches them, and posts them.

- On success: delete the queue rows, mark the records synced.
- On failure: increment `attempts` and back off exponentially.

It runs when the app starts, when connectivity returns, when the user taps "sync now", and every
15 minutes via `workmanager` — 15 minutes being the platform floor.

### Pulling

Ask the server for everything changed since `last_sync_at`, apply it locally, then advance the
timestamp **only after** the local write succeeds. Never advance it first.

### Conflicts

- **Movements never conflict.** They are append-only, so both sides' rows are simply kept.
- **Products can conflict** — two people rename the same item. Resolve with last-write-wins on
  `updated_at`, but record the losing version in a conflicts list the user can inspect on the sync
  screen.

State plainly in the report why last-write-wins is safe for product metadata and would **not** be
safe for quantities.

### Pushing down

The backend recomputes stock after each batch and, when an item crosses its reorder point, sends an
FCM message to that shop's topic. A nightly scheduled job sends a digest. The device never polls for
alerts — Lecture 6's point that polling costs battery, bandwidth and server time.

---

## Cloud services

Five, against a course requirement of four.

| Service | Role |
|---|---|
| **Supabase** | PostgreSQL behind the Flask API — never reached directly from the app |
| **Cloudinary** (or Firebase Storage) | Product photos; the app uploads and stores only the returned URL |
| **Firebase Cloud Messaging** | Low-stock alerts, the nightly digest, version-upgrade notices |
| **Sentry** | Crash and error reporting from devices you do not have in your hand |
| **Gemini API** | Scan an unknown barcode → suggest a product name and category from a photo of the label; also drafts reorder suggestions from recent movement history |

The backend is a **Flask** app on **Render** or **LeapCell**, deployed from GitHub on push.

---

## Dependencies

| Purpose | Package |
|---|---|
| State management | `flutter_bloc`, `equatable` |
| Service locator | `get_it` |
| Local database | `sqflite`, `path`, `sqflite_common_ffi` (desktop) |
| Key-value storage | `shared_preferences` |
| Network | `http` (or `dio`) |
| Barcode / camera | a barcode scanner plugin, `image_picker` |
| Permissions | `permission_handler` |
| Background work | `workmanager`, optionally `cron` |
| Messaging | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| Logging / monitoring | `logger`, `sentry_flutter` |
| Localisation | `flutter_localizations`, `intl`, with `generate: true` |
| Identifiers | a UUID package |
| Testing | `flutter_test`, `test`, `bloc_test`, `mocktail`, `golden_toolkit`, `integration_test` |
| Release | `flutter_launcher_icons` |

---

## Non-functional requirements

Targets to test against, not aspirations.

| Attribute | Target |
|---|---|
| **Offline** | Every read and write works with the radio off; nothing is lost after a force-close |
| **Performance** | The product list stays smooth at 2,000 products — `ListView.builder` plus an index on `barcode` |
| **Latency** | A scan resolves to a product in under one second |
| **Correctness** | Displayed stock always equals the sum of the ledger — asserted in a test |
| **Security** | Credentials live only on the backend; the app holds a session token, never database keys |
| **Usability** | The scan-then-record loop is reachable with one hand in no more than three taps |
| **Reliability** | A retried sync can never double-apply a movement |
| **Reach** | AR / FR / EN with correct RTL layout |

---

## Course coverage

| Lectures | Where it shows up in Jerd |
|---|---|
| **L1–L2** | App type choice, target user study (shopkeepers, low technical skill, poor connectivity, one-handed use), subscription business model |
| **L3–L4** | Widget catalogue, custom product card, navigation and returned values from the scanner |
| **L5** | Async loads, `FutureBuilder` in the early milestones, form validation, the Flask backend on serverless hosting |
| **L6** | SharedPreferences, SQLite schema, a migration when v2 adds supplier fields, repository and singleton patterns, and the data-sync questions answered concretely |
| **L7–L9** | Cubits across many widgets, GetIt, layered folders, localisation, reusable progress button / snackbar / confirmation dialog |
| **L10–L11** | Cloud storage, Supabase behind the backend, direct-vs-backend argued and decided, background jobs, FCM, camera permission |
| **L12** | Unit tests on the pure domain functions, `blocTest` on sync and stock-count cubits, widget tests on the product card, one end-to-end flow |
| **L13** | Identifier, versioning, launcher icon, signing keystore, obfuscated AAB, private distribution with an in-app upgrade check |

---

## Milestones

Each milestone is demoable on its own. Do not start the next until the current one runs.

| # | Milestone | Demoable when |
|---|---|---|
| 0 | Skeleton, folders, theme, GetIt, minimal main | An empty products screen renders |
| 1 | Products and movements on a dummy repository, all screens navigable | You can walk the whole app with fake data |
| 2 | Forms, validation, progress button, confirm dialog, snackbars | Create, edit and delete feel finished |
| 3 | Swap the dummy repository for SQLite — no UI changes | Data survives a restart; the swap was one line |
| 4 | The domain functions and their unit tests | Stock from ledger, low-stock, reconciliation — all green |
| 5 | Cubits replace `setState`; two widgets react to one change | The list and the alert badge update together |
| 6 | Barcode scanning and photos with permissions | Scan a real item on a real phone |
| 7 | Flask backend and Supabase; the API repository | Endpoints return JSON in a browser |
| 8 | Sync queue, connectivity cubit, `workmanager` | Airplane mode → record → reconnect → it is on the server |
| 9 | FCM low-stock alerts with tap-through to the product | A push from a Python script opens the right screen |
| 10 | Stock count mode with reconciliation | A full shelf count commits as one batch |
| 11 | Localisation, Sentry, Gemini suggestion | Arabic RTL correct; a forced crash appears in Sentry |
| 12 | Widget, bloc and E2E tests; signing and an obfuscated AAB | `flutter test` green; a signed bundle plus an upgrade path |

---

## Decisions to make first

**1. Who can use one shop's data?**
Single user is simpler and still demonstrates everything. Multi-user needs roles and makes conflicts
real — choose it only if you want the harder conflict story in the demo.

**2. Does a stock count block normal movements while it runs?**
Blocking is simpler to reason about. Allowing both means reconciling against a moving target. Either
is defensible, but decide before building `StockCountCubit`, because it shapes that cubit.

---

## Deliverables checklist

Drawn from the Week 11 and Week 15 checkpoints in the lab sheets.

**Week 11 — MVP**

- [ ] Primary use cases implemented
- [ ] Minimal backend
- [ ] Minimal business logic
- [ ] State management in use
- [ ] Local relational database

**Week 15 — final demo, max 10 minutes**

- [ ] Primary implemented features
- [ ] Architecture, clean-code principles, state management
- [ ] Custom backend
- [ ] Integration with external cloud services (four or more)
- [ ] Use of Firebase Cloud Messaging
- [ ] Testing and QA
- [ ] Distribution and publishing to real users
- [ ] Promotion and branding of the app

**Course rules this satisfies**

- [x] Backend server — Flask on Render/LeapCell
- [x] Local relational database — SQLite via sqflite
- [x] At least four cloud services — five listed above
- [x] No direct database access from the app — everything goes through the API
