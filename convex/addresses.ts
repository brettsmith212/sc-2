import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

/**
 * Public query to list addresses by userId (for real-time subscriptions)
 */
export const listAddressesByUserId = query({
  args: {
    userId: v.string(), // We'll pass the userId as a string from the client
    validatedOnly: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    // Cast userId to the proper type for internal query
    const addresses = await ctx.db
      .query("addresses")
      .withIndex("by_user_id", (q) => q.eq("user_id", args.userId as any))
      .collect();

    // Filter by validated if requested
    const filteredAddresses = args.validatedOnly 
      ? addresses.filter(addr => addr.validated)
      : addresses;

    // Sort by creation time (most recent first)
    const sortedAddresses = filteredAddresses.sort((a, b) => b._creationTime - a._creationTime);

    // Return minimal projection for UI
    return sortedAddresses.map((addr) => ({
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
 * Public mutation to create a validated address (for real-time client calls)
 */
export const createAddressByUserId = mutation({
  args: {
    userId: v.string(), // Pass userId as string from client
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
    const userId = args.userId as any; // Cast for type compatibility

    // Check for duplicates
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
