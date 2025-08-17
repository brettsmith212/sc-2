import { mutation, query, internalMutation } from "./_generated/server";
import { v } from "convex/values";

// Simple user creation for mobile apps (internal use only)
export const createUser = internalMutation({
  args: {
    email: v.string(),
    displayName: v.optional(v.string()),
    authProvider: v.string(),
  },
  handler: async (ctx, args) => {
    // Check if user already exists by email
    const existingUser = await ctx.db
      .query("users")
      .filter((q) => q.eq(q.field("email"), args.email))
      .first();

    if (existingUser) {
      // Update existing user
      await ctx.db.patch(existingUser._id, {
        display_name: args.displayName,
      });
      return existingUser._id;
    } else {
      // Create new user
      const newUserId = await ctx.db.insert("users", {
        auth_user_id: `${args.authProvider}:${args.email}`,
        display_name: args.displayName,
        email: args.email,
        tos_accepted_at: Date.now(),
      });
      return newUserId;
    }
  },
});

// Get user by email (for mobile auth)
export const getUserByEmail = query({
  args: {
    email: v.string(),
  },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("users")
      .filter((q) => q.eq(q.field("email"), args.email))
      .first();
  },
});
