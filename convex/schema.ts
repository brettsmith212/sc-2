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
});
