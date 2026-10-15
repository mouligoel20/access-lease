# MUJ SLCM adapter: what is ready and what is still needed

The Sentinel ingestion API is implemented and tested. **An actual connection to
Manipal University Jaipur SLCM is not configured.** The university must provide
an authorized API or export and its field definitions before a bridge can be
implemented against that source. A student portal login is not an API contract.

MUJ links to https://mujslcm.jaipur.manipal.edu/ on its official website:
https://jaipur.manipal.edu/pay-fee-online.php

## Supported flow

University-approved API/export → authorized mapping bridge → Sentinel ingest API
→ atomic database update + policy scan → dashboard refresh within 10 seconds.

The bridge runs in your approved environment. Sentinel does not scrape the
portal, store university credentials or call an invented upstream endpoint.
No reverse/write-back integration exists: revoking in Sentinel does not revoke
an actual university account or permission.

## Configure the Sentinel side

1. Open Admin dashboard and sign in.
2. Select SLCM integration.
3. Generate an ingest key. It is displayed once; rotating it invalidates the old
   key. Store it as `SLCM_SYNC_TOKEN` in your approved bridge environment.
4. Map your approved export to the contract below.
5. Send JSON to `POST /api/integrations/slcm/sync`, with
   `Authorization: Bearer <ingest key>` and `Content-Type: application/json`.
6. Check the response and adapter status. Schedule the approved bridge at an
   interval permitted by the university API once that API is available.

For a local manual demonstration, download the **synthetic payload example**
from the integration page and paste it into the mapped-export form. No university
record is included in that example. Update its dates and `snapshot_at` when
using it on a later day. The form uses your existing admin session.

## Contract (Sentinel fields, not claimed MUJ field names)

| Section | Required fields | Notes |
|---|---|---|
| Root | `snapshot_at` | ISO 8601 timestamp with timezone; strictly newer than the last accepted snapshot |
| `users[]` | `external_id`, `username`, `full_name`, `email`, `department` | `user_type` defaults to `student`; max 500 per batch |
| `resources[]` | `external_id`, `name`, `department` | `resource_type` defaults to `application`; `sensitivity` defaults to `STANDARD`; max 500 |
| `grants[]` | `external_id`, `user_external_id`, `resource_external_id`, `permission_level`, `owner`, `purpose`, `granted_date` | Optional `expiry_date`, `is_temporary`, `status`; max 1,000 |

Permission levels: `READ`, `WRITE`, `EXECUTE`, `ADMIN`.
Grant status: `ACTIVE` or `REVOKED`.
Dates: `YYYY-MM-DD`. Historical expired dates are allowed in exports so policy
scans can detect stale access. Future grant dates and expiry-before-grant dates
are rejected. Other enums and exact limits appear in `/docs`.

External IDs must be stable, unique within each entity type, and refer to the
same identity in future batches. Referenced users/resources may be included in
the same batch or have been synced previously. No student-to-resource permission
is inferred merely from a person's enrollment or department; the approved source
must provide or authorize each access relationship.

## Import guarantees

- An identical payload is a no-op and returns `duplicate: true`.
- Older or same-time changed snapshots are rejected with HTTP 409.
- A batch is all-or-nothing: invalid references/conflicts roll back records,
  mappings and audit entries.
- Local and imported revoked grants stay revoked when a later payload says
  `ACTIVE`. The response counts these as `revocations_preserved`.
- Omitted records are not removed or revoked. Send explicit `REVOKED` for a known
  external grant. This is an upsert feed, not a destructive full reconciliation.
- Local username/email/resource-name collisions return HTTP 409. The adapter
  never silently links an existing manual/demo identity to an external record.
- A grant's external ID cannot switch to another user or resource.
- The key is scoped to this import route. It cannot sign in or invoke unrelated
  admin mutations. Only its hash is stored server-side.

## What to obtain from MUJ IT

The approved endpoint/export, stable identity/resource/grant IDs, field schema,
authentication method, permitted sync frequency, and whether permission changes
may ever be written back. Do not put credentials into the repository or chat.
Until those are supplied, the UI correctly describes an ingest adapter with an
unconfigured university connection.
