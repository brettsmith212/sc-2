import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // Test table for connection verification
  test_entries: defineTable({
    name: v.string(),
    message: v.string(),
  }),
  
  // PoC tables from PRD - will be implemented later
  users: defineTable({
    auth_user_id: v.string(),
    display_name: v.optional(v.string()),
    email: v.optional(v.string()),
    nostr_pubkey: v.optional(v.string()),
    tos_accepted_at: v.optional(v.number()),
  }).index("by_auth_user_id", ["auth_user_id"])
    .index("by_nostr_pubkey", ["nostr_pubkey"]),
  
  addresses: defineTable({
    user_id: v.id("users"),
    label: v.string(),
    name: v.string(),
    phone: v.optional(v.string()),
    email: v.optional(v.string()),
    line1: v.string(),
    line2: v.optional(v.string()),
    city: v.string(),
    state: v.string(),
    postal_code: v.string(),
    country: v.string(),
    validated: v.boolean(),
    validation_meta: v.optional(v.any()),
  }).index("by_user_id", ["user_id"])
    .index("by_user_validated", ["user_id", "validated"]),
  
  packages: defineTable({
    user_id: v.id("users"),
    source: v.union(v.literal("ar"), v.literal("manual")),
    length_cm: v.number(),
    width_cm: v.number(),
    height_cm: v.number(),
    weight_kg: v.number(),
    packaging_type: v.union(
      v.literal("box"),
      v.literal("poly"),
      v.literal("envelope"),
      v.literal("tube"),
      v.literal("other")
    ),
    declared_value_cents: v.optional(v.number()),
    currency: v.string(),
    notes: v.optional(v.string()),
  }).index("by_user_id", ["user_id"]),
  
  rates: defineTable({
    user_id: v.id("users"),
    from_address_id: v.id("addresses"),
    to_address_id: v.id("addresses"),
    package_id: v.id("packages"),
    carrier: v.union(
      v.literal("ups"),
      v.literal("usps"),
      v.literal("fedex"),
      v.literal("dhl"),
      v.literal("other")
    ),
    service_level: v.string(),
    delivery_estimate_days: v.optional(v.number()),
    rate_cents: v.number(),
    currency: v.string(),
    surcharges: v.optional(v.any()),
    negotiated_rate_id: v.optional(v.string()),
    expires_at: v.number(),
  }).index("by_user_package", ["user_id", "package_id"])
    .index("by_expires_at", ["expires_at"]),
  
  payments: defineTable({
    user_id: v.id("users"),
    shipment_id: v.optional(v.id("shipments")),
    processor: v.union(
      v.literal("stripe"),
      v.literal("apple_pay"),
      v.literal("other")
    ),
    processor_payment_id: v.string(),
    amount_cents: v.number(),
    currency: v.string(),
    fee_cents: v.number(),
    status: v.union(
      v.literal("requires_action"),
      v.literal("succeeded"),
      v.literal("failed"),
      v.literal("refunded")
    ),
    error_code: v.optional(v.string()),
    receipt_url: v.optional(v.string()),
  }).index("by_user_id", ["user_id"])
    .index("by_processor_payment_id", ["processor_payment_id"])
    .index("by_status", ["status"]),
  
  shipments: defineTable({
    user_id: v.id("users"),
    from_address_id: v.id("addresses"),
    to_address_id: v.id("addresses"),
    package_id: v.id("packages"),
    carrier: v.union(
      v.literal("ups"),
      v.literal("usps"),
      v.literal("fedex"),
      v.literal("dhl"),
      v.literal("other")
    ),
    service_level: v.string(),
    tracking_number: v.optional(v.string()),
    label_pdf_url: v.optional(v.string()),
    qr_code_payload: v.optional(v.string()),
    insurance_cents: v.optional(v.number()),
    status: v.union(
      v.literal("purchased"),
      v.literal("in_transit"),
      v.literal("delivered"),
      v.literal("exception"),
      v.literal("cancelled")
    ),
    rate_cents: v.number(),
    currency: v.string(),
    purchased_at: v.number(),
  }).index("by_user_id", ["user_id"])
    .index("by_tracking_number", ["tracking_number"])
    .index("by_status", ["status"]),
  
  tracking_events: defineTable({
    shipment_id: v.id("shipments"),
    carrier: v.union(
      v.literal("ups"),
      v.literal("usps"),
      v.literal("fedex"),
      v.literal("dhl"),
      v.literal("other")
    ),
    code: v.string(),
    description: v.string(),
    occurs_at: v.number(),
    location: v.optional(v.any()),
  }).index("by_shipment_occurs_at", ["shipment_id", "occurs_at"]),
});
