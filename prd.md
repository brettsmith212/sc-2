# ShipComplete – Product Requirements Document (PRD)

## 1) Overview

**Product:** ShipComplete  
**Platform:** iOS (iPhone)  
**Goal:** Deliver a dead-simple shipping app that lets anyone access discounted DAP rates with a guided, “grandma-proof” flow.

**Key Differentiators**

- Minimal data entry and decisions
- AR-based box measurement (no tape measure)
- Instant rate calculation and 1-tap label purchase
- UPS QR code label option (print in-store)
- Passwordless auth (Apple / Google / NOSTR)

**Revenue Model:** Per-shipment cut from discounted DAP rates.

---

## 2) Target Users

- Individuals seeking cheaper shipping without business accounts
- Non-technical and elderly users who need a clear, guided workflow
- Casual shippers sending occasional packages

---

## 3) Core Features (with Convex backend notes)

### 3.1 Authentication (Passwordless)

- **Apple Sign-In** — Convex Auth issues/stores user identity and session.
- **Google Sign-In** — Convex Auth handles OAuth exchange and session.
- **NOSTR login** — Convex stores public key as the user identifier (no PII).

### 3.2 Address Management

- **Address validation** — Convex persists validated addresses in `addresses` and returns validation metadata.
- **Lightweight address book** — Convex queries `addresses` by user for quick re-use (sender/recipient).

### 3.3 Package Details

- **AR-based box measurement** — ARKit calculates dimensions; Convex saves results in `packages` with `source="ar"`.
- **Manual entry** — Same `packages` schema with `source="manual"`; editable fields for dimensions/weight.
- **Unit handling** — Store canonical (cm/kg) in Convex; convert in client UI.

### 3.4 Rate Calculation & Selection

- **Carrier rate comparison (DAP)** — Client requests Convex; Convex normalizes carrier quotes, caches in `rates` with `expires_at`.
- **Sort & filter (client-side)** — Client sorts returned rate list (e.g., cheapest/fastest/best value).

### 3.5 Label Creation

- **Purchase shipping label** — Convex buys label via carrier API and writes `shipments` with label metadata.
- **UPS QR code label** — Convex stores QR payload/string for in-app display at handoff time.
- **Email/PDF** — Convex persists `label_pdf_url` and can trigger an email send via a backend function.

### 3.6 Tracking (Basic for PoC)

- **Tracking number & status** — Convex stores `tracking_number` on `shipments` and optional timeline in `tracking_events`.
- **Manual refresh** — Client triggers a Convex function to fetch latest status and update `shipments`/`tracking_events`.

### 3.7 Payments

- **Processor integration** — Convex coordinates payment (e.g., Stripe or Apple Pay via processor), records in `payments`, then proceeds to label purchase on success.

### 3.8 Backend & Infrastructure

- **Backend:** Convex for authentication, storage, carrier integrations, and payment coordination.
- **Integrations:** DAP/carrier APIs; payment processor (TBD).

---

## 4) Proof of Concept (PoC) Scope – End-to-End

1. User signs in (Apple/Google/NOSTR) via Convex Auth
2. User saves validated sender & recipient addresses
3. User creates a package (manual or AR measurement)
4. App fetches discounted rates from Convex (normalized & cached)
5. User selects a rate and confirms purchase
6. Payment succeeds via processor and is recorded in Convex
7. Convex purchases label; app shows QR code and/or PDF
8. Shipment record and (optional) tracking events are viewable in history

---

## 5) Database Schema (PoC)

> Notes  
> • All docs include Convex system fields (`_id`, `_creationTime`).  
> • Types are illustrative; use enums where shown.  
> • Minimal indexes suggested for PoC queries.  
> • PII flagged to guide privacy/retention.

### 5.1 `users`

- `auth_user_id` (string, unique) — Convex Auth identifier
- `display_name` (string, optional)
- `email` (string, optional, PII)
- `nostr_pubkey` (string, optional, unique)
- `tos_accepted_at` (timestamp)  
  **Indexes:** by `auth_user_id`; by `nostr_pubkey` (if used)

### 5.2 `addresses`

- `user_id` (ref:`users`)
- `label` (string, e.g., “Home”)
- `name` (string, PII)
- `phone` (string, optional, PII)
- `email` (string, optional, PII)
- `line1` (string, PII)
- `line2` (string, optional, PII)
- `city` (string, PII)
- `state`/`province` (string, PII)
- `postal_code` (string, PII)
- `country` (string, ISO-2)
- `validated` (bool)
- `validation_meta` (object, optional: codes, messages)  
  **Indexes:** by `user_id`; (`user_id`,`validated`)

### 5.3 `packages`

- `user_id` (ref:`users`)
- `source` (enum: `ar|manual`)
- `length_cm` (number), `width_cm` (number), `height_cm` (number)
- `weight_kg` (number)
- `packaging_type` (enum: `box|poly|envelope|tube|other`)
- `declared_value_cents` (int, optional), `currency` (string, default `USD`)
- `notes` (string, optional)  
  **Indexes:** by `user_id`; (`user_id`,`_creationTime` desc)

### 5.4 `rates` (ephemeral cache)

- `user_id` (ref:`users`)
- `from_address_id` (ref:`addresses`)
- `to_address_id` (ref:`addresses`)
- `package_id` (ref:`packages`)
- `carrier` (enum: `ups|usps|fedex|dhl|other`)
- `service_level` (string, e.g., “UPS Ground”)
- `delivery_estimate_days` (int, optional)
- `rate_cents` (int), `currency` (string)
- `surcharges` (object, optional)
- `negotiated_rate_id` (string, optional)
- `expires_at` (timestamp)  
  **Indexes:** (`user_id`,`package_id`); by `expires_at` (TTL cleanup)

### 5.5 `payments`

- `user_id` (ref:`users`)
- `shipment_id` (ref:`shipments`, nullable until label purchase completes)
- `processor` (enum: `stripe|apple_pay|other`)
- `processor_payment_id` (string)
- `amount_cents` (int), `currency` (string)
- `fee_cents` (int) — app revenue
- `status` (enum: `requires_action|succeeded|failed|refunded`)
- `error_code` (string, optional)
- `receipt_url` (string, optional)  
  **Indexes:** by `user_id`; by `processor_payment_id`; by `status`

### 5.6 `shipments`

- `user_id` (ref:`users`)
- `from_address_id` (ref:`addresses`)
- `to_address_id` (ref:`addresses`)
- `package_id` (ref:`packages`)
- `carrier` (enum)
- `service_level` (string)
- `tracking_number` (string, optional until purchase returns)
- `label_pdf_url` (string, optional)
- `qr_code_payload` (string, optional)
- `insurance_cents` (int, optional)
- `status` (enum: `purchased|in_transit|delivered|exception|cancelled`)
- `rate_cents` (int), `currency` (string)
- `purchased_at` (timestamp)  
  **Indexes:** by `user_id`; by `tracking_number`; (`user_id`,`_creationTime` desc); by `status`

### 5.7 `tracking_events` (optional but included for PoC)

- `shipment_id` (ref:`shipments`)
- `carrier` (enum)
- `code` (string, e.g., “DELIVERED”)
- `description` (string)
- `occurs_at` (timestamp)
- `location` (object: city/state/country, optional)  
  **Indexes:** (`shipment_id`,`occurs_at` asc)

---

## 6) Relationships (PoC)

- `users` 1→N `addresses`, `packages`, `shipments`, `payments`
- `shipments` 1→N `tracking_events`
- `rates` are ephemeral and tied to `(user, from_address, to_address, package)`

---

## 7) PoC Implementation Checklist (Sequential)

> Implement in order; each step unblocks the next. Keep steps demo-able.

1. **Project & Backend Setup**  
   Initialize iOS app; add Convex SDK; create Convex project; define PoC tables (`users`, `addresses`, `packages`, `rates`, `payments`, `shipments`, `tracking_events`); set carrier/payment secrets.  
   **Done when:** App runs on device and a trivial Convex query/mutation succeeds.

2. **Authentication (Apple/Google; NOSTR optional)**  
   Implement Sign-In and persist user identity in Convex.  
   **Done when:** New user can sign in/out and `auth_user_id` is readable on client.

3. **Address Entry & Validation**  
   Build simple forms for Sender/Recipient; validate and persist to `addresses`; allow selecting saved addresses.  
   **Done when:** User can save validated From/To and re-use without re-typing.

4. **Package Creation (Manual First)**  
   Manual entry for dimensions/weight; persist to `packages` with unit conversions.  
   **Done when:** User can create/select a package record.

5. **AR Measurement (Upgrade Path)**  
   ARKit capture populates dimensions; save as `packages` with `source="ar"`.  
   **Done when:** User can measure a real box and save it.

6. **Rate Quoting (DAP)**  
   Convex normalizes carrier quotes; cache in `rates` with `expires_at`; UI list with sort.  
   **Done when:** With addresses + package, user sees at least one valid rate option.

7. **Rate Selection → Shipment Preview**  
   Select rate; show final cost (incl. app fee if used); confirm screen.  
   **Done when:** User can review details and confirm purchase.

8. **Payments**  
   Integrate processor; create `payments` row; handle success/failure/retry.  
   **Done when:** Test payment authorizes/captures and appears in `payments.status`.

9. **Label Purchase & Storage**  
   After payment success, Convex buys label; create `shipments` with `tracking_number`, `label_pdf_url`, `qr_code_payload`; receipt view.  
   **Done when:** A label (sandbox/test) is generated and QR/PDF is visible in-app.

10. **Basic Tracking (Manual Refresh)**  
    Store `tracking_number`; “Refresh” calls carrier tracking and writes `tracking_events`/`status`.  
    **Done when:** User sees current shipment status after tapping Refresh.

11. **Shipment History**  
    “My Shipments” list (latest first) with detail (open label, show QR, status).  
    **Done when:** User can return and access past shipments reliably.

12. **Hardening & PoC Readiness**  
    Empty/error states, minimal logging, simple privacy copy, on-device smoke test.  
    **Done when:** End-to-end demo works on a clean account without crashes.

---

## 8) Technical References

- Convex: https://docs.convex.dev
- ARKit: https://developer.apple.com/augmented-reality/
