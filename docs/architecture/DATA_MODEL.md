# Data model and migration boundary

## Verified existing deployment (2026-11-12, metadata only)

`public.training_states`: `user_id uuid PK → auth.users.id`, `revision bigint`, `payload jsonb`, `updated_at timestamptz`; RLS enabled. SELECT/INSERT/UPDATE policies use `auth.uid() = user_id`, UPDATE has both USING and WITH CHECK. `save_training_state(expected_revision,payload)` is SECURITY INVOKER, checks user/version, increments revision atomically, returns null on stale revision. No workout payloads read during audit.

**P0 schema drift:** live authenticated grants also include DELETE, TRUNCATE, REFERENCES and TRIGGER, beyond repository SQL's SELECT/INSERT/UPDATE. RLS does not scope TRUNCATE. Do not exercise this grant against production. Separate reviewed hardening task must revoke unnecessary privileges, verify function/table grants and default privileges, and test isolation in disposable local/staging data. No production change performed in M0.

This is a privilege-audit finding, not evidence of a successful remote attack or data loss. No public truncate RPC was observed; current Data API exploitability was not tested. Remove unnecessary privileges before expanding the cloud surface.

Legacy payload v2 nests profiles, plans (`templateId`, ordered generated session keys `wN-slot`, append-only records), recovery, imported workouts, sleep fields and `activeLive` draft. Several local named profiles can belong to one cloud account; a local profile ID is not an auth identity. Import migration must retain both identifiers and plan context.

## Proposed normalized schema (design only; no migration applied)

All IDs UUID unless specified; timestamps UTC plus original timezone/day semantics where required. Private tables have owner-scoped RLS on read/insert/update/delete, with both USING/WITH CHECK and FK ownership checks; defaults private. Use composite owner+ID FKs where needed to prevent cross-owner association.

| Model | Fields/relations and access |
|---|---|
| profiles | auth user FK, legacy local-profile ID nullable, display name, unique username, avatar key, bio; public projection contains only opted-in fields; private account settings separate |
| plan_templates / template_sessions | versioned catalog, program key, ordered ordinal, prescription components; immutable versions; reviewed public catalog |
| training_plans / plan_sessions | owner, profile, template version, active state, enrolled timestamp; independent plans; unique plan/ordinal |
| session_attempts / component_logs | owner, plan session, status completed/partial/skipped, skip confirmation timestamp, component sets/reps, RPE/notes, client event UUID, timestamps; append-only audit |
| workouts | owner/profile, optional attempt, kind/start/end/timezone/duration/distance/energy, source/source UUID/version; visibility private default; unique owner/source/source UUID |
| activity_routes / route_points | workout/owner, recorded coordinates/timestamps, private encrypted/local original; separately sanitized published route artifact; never automatic public join |
| daily_health_summaries | owner/local date/timezone, metric values/units/sample counts/coverage/source references, consent version; private opt-in sync only |
| sleep_records | owner/source UUID, interval/stage/source revision/timezone; normalized intervals plus aggregation version; deleted sample tombstones |
| scoring_results | owner/day/type/model version, nullable value, missing/baseline/provisional/available state, confidence, explanation and input references; private |
| social_posts / post_media | author, explicit publish timestamp, safe activity summary, description, sanitized media/map keys, moderation state; public only if published and not blocked/removed |
| likes / comments | post/author, unique post+liker, timestamps, bounded text; enforce visibility and blocks on read/write |
| user_blocks / content_reports | blocker/blocked unique pair; reports target/reason/status; only reporter and authorized moderators see reports |
| consent_events / privacy_preferences | owner, purpose/category/version/granted/revoked timestamp, scope; append-only consent history; health sync, AI and public sharing separate |
| sync_outbox / legacy_import_map | local owner, idempotency key/version/retry state; import mapping unique owner+legacy profile+plan+record prevents duplicates |

## Migration/rollback/verification plan

M1: inventory deployed schema/grants/auth settings; export owner-controlled backups without committing them. Design additive versioned SQL and explicit grants; test in disposable local/staging Postgres with two users and anon, cross-owner FKs, wrong-user RPC, stale revisions and malicious ownership updates. Preserve legacy payload and revision; native adapter first reads a validated copy into owner-local storage. Dry-run counts/checksums and provenance map; opt-in dual-read comparison before any write cutover. Never regenerate completed history as new sessions or treat imports as completion.

Rollback disables normalized writes via feature flag and resumes legacy adapter; retain new records/outbox for reconciliation, no destructive rollback of production history. Reviewer approves rollback and cross-client compatibility before deployment. Auth redirects, real email login and two-device sync remain separately unverified. Security hardening precedes expanding cloud features.
