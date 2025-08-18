import { v } from "convex/values";
import { mutation, query, internalMutation, internalQuery } from "./_generated/server";
import { requireLogin, getUserId } from "./authHelpers";

/**
 * Internal function to create a validated address (used by HTTP endpoints)
 */
export const createValidatedAddressInternal = internalMutation({
  args: {
    userId: v.id("users"),
    label: v.string(),
    name: v.string(),
    phone: v.optional(v.string()),
    email: v.optional(v.string()),
    line1: v.string(),
    line2: v.optional(v.string()),
    city: v.string(),
    state: v.string(),
    postalCode: v.string(),
    country: v.string(),
    validationMeta: v.optional(v.any()),
  },
  handler: async (ctx, args) => {
    const userId = args.userId;

    // Check for duplicates (simple deduplication by line1 + postal_code)
    const existing = await ctx.db
      .query("addresses")
      .withIndex("by_user_id", (q) => q.eq("user_id", userId))
      .filter((q) =>
        q.and(
          q.eq(q.field("line1"), args.line1),
          q.eq(q.field("postal_code"), args.postalCode),
          q.eq(q.field("country"), args.country)
        )
      )
      .first();

    if (existing) {
      // Return existing address ID instead of creating duplicate
      return existing._id;
    }

    // Check max addresses per user (PoC limit: 20)
    const addressCount = await ctx.db
      .query("addresses")
      .withIndex("by_user_id", (q) => q.eq("user_id", userId))
      .collect()
      .then((addresses) => addresses.length);

    if (addressCount >= 20) {
      throw new Error("Maximum of 20 addresses allowed per user");
    }

    // Create new validated address
    const addressId = await ctx.db.insert("addresses", {
      user_id: userId,
      label: args.label,
      name: args.name,
      phone: args.phone,
      email: args.email,
      line1: args.line1,
      line2: args.line2,
      city: args.city,
      state: args.state,
      postal_code: args.postalCode,
      country: args.country,
      validated: true,
      validation_meta: args.validationMeta,
    });

    return addressId;
  },
});

/**
 * Creates a validated address in the user's address book (with auth)
 */
export const createValidatedAddress = mutation({
  args: {
    label: v.string(),
    name: v.string(),
    phone: v.optional(v.string()),
    email: v.optional(v.string()),
    line1: v.string(),
    line2: v.optional(v.string()),
    city: v.string(),
    state: v.string(),
    postalCode: v.string(),
    country: v.string(),
    validationMeta: v.optional(v.any()), // Store UPS validation response
  },
  handler: async (ctx, args) => {
    const userId = getUserId(ctx);

    // Check for duplicates (simple deduplication by line1 + postal_code)
    const existing = await ctx.db
      .query("addresses")
      .withIndex("by_user_id", (q) => q.eq("user_id", userId))
      .filter((q) =>
        q.and(
          q.eq(q.field("line1"), args.line1),
          q.eq(q.field("postal_code"), args.postalCode),
          q.eq(q.field("country"), args.country)
        )
      )
      .first();

    if (existing) {
      // Return existing address ID instead of creating duplicate
      return existing._id;
    }

    // Check max addresses per user (PoC limit: 20)
    const addressCount = await ctx.db
      .query("addresses")
      .withIndex("by_user_id", (q) => q.eq("user_id", userId))
      .collect()
      .then((addresses) => addresses.length);

    if (addressCount >= 20) {
      throw new Error("Maximum of 20 addresses allowed per user");
    }

    // Create new validated address
    const addressId = await ctx.db.insert("addresses", {
      user_id: userId,
      label: args.label,
      name: args.name,
      phone: args.phone,
      email: args.email,
      line1: args.line1,
      line2: args.line2,
      city: args.city,
      state: args.state,
      postal_code: args.postalCode,
      country: args.country,
      validated: true,
      validation_meta: args.validationMeta,
    });

    return addressId;
  },
});

/**
 * Internal function to list addresses (used by HTTP endpoints)
 */
export const listAddressesInternal = internalQuery({
  args: {
    userId: v.id("users"),
    validatedOnly: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    const userId = args.userId;

    let query = ctx.db
      .query("addresses")
      .withIndex("by_user_id", (q) => q.eq("user_id", userId));

    if (args.validatedOnly === true) {
      query = query.filter((q) => q.eq(q.field("validated"), true));
    }

    const addresses = await query
      .order("desc") // Most recent first
      .collect();

    // Return minimal projection for UI
    return addresses.map((addr) => ({
      _id: addr._id,
      label: addr.label,
      name: addr.name,
      phone: addr.phone,
      email: addr.email,
      line1: addr.line1,
      line2: addr.line2,
      city: addr.city,
      state: addr.state,
      postal_code: addr.postal_code,
      country: addr.country,
      validated: addr.validated,
      _creationTime: addr._creationTime,
    }));
  },
});

/**
 * Lists user's saved addresses (with auth)
 */
export const listAddresses = query({
  args: {
    validatedOnly: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    const userId = getUserId(ctx);

    let query = ctx.db
      .query("addresses")
      .withIndex("by_user_id", (q) => q.eq("user_id", userId));

    if (args.validatedOnly === true) {
      query = query.filter((q) => q.eq(q.field("validated"), true));
    }

    const addresses = await query
      .order("desc") // Most recent first
      .collect();

    // Return minimal projection for UI
    return addresses.map((addr) => ({
      _id: addr._id,
      label: addr.label,
      name: addr.name,
      phone: addr.phone,
      email: addr.email,
      line1: addr.line1,
      line2: addr.line2,
      city: addr.city,
      state: addr.state,
      postal_code: addr.postal_code,
      country: addr.country,
      validated: addr.validated,
      _creationTime: addr._creationTime,
    }));
  },
});

/**
 * Gets a specific address by ID (for address details/editing)
 */
export const getAddress = query({
  args: {
    addressId: v.id("addresses"),
  },
  handler: async (ctx, args) => {
    const userId = getUserId(ctx);

    const address = await ctx.db.get(args.addressId);
    if (!address) {
      throw new Error("Address not found");
    }

    // Verify ownership
    if (address.user_id !== userId) {
      throw new Error("Not authorized to access this address");
    }

    return address;
  },
});

/**
 * Updates an existing address (optional for PoC)
 */
export const updateAddress = mutation({
  args: {
    addressId: v.id("addresses"),
    label: v.optional(v.string()),
    name: v.optional(v.string()),
    phone: v.optional(v.string()),
    email: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const userId = getUserId(ctx);

    const address = await ctx.db.get(args.addressId);
    if (!address) {
      throw new Error("Address not found");
    }

    // Verify ownership
    if (address.user_id !== userId) {
      throw new Error("Not authorized to update this address");
    }

    const updates: any = {};
    if (args.label !== undefined) updates.label = args.label;
    if (args.name !== undefined) updates.name = args.name;
    if (args.phone !== undefined) updates.phone = args.phone;
    if (args.email !== undefined) updates.email = args.email;

    await ctx.db.patch(args.addressId, updates);
    return args.addressId;
  },
});

/**
 * Deletes an address (soft delete - marks as deleted)
 */
export const deleteAddress = mutation({
  args: {
    addressId: v.id("addresses"),
  },
  handler: async (ctx, args) => {
    const userId = getUserId(ctx);

    const address = await ctx.db.get(args.addressId);
    if (!address) {
      throw new Error("Address not found");
    }

    // Verify ownership
    if (address.user_id !== userId) {
      throw new Error("Not authorized to delete this address");
    }

    // For PoC, we'll do hard delete. In production, consider soft delete
    // to preserve historical shipment references
    await ctx.db.delete(args.addressId);
    return true;
  },
});
