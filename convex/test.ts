import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// Test connection ping
export const ping = mutation({
  args: {},
  handler: async (ctx) => {
    return {
      status: "connected",
      timestamp: Date.now(),
      message: "Convex backend is operational"
    };
  },
});

// Add a test entry
export const addTestEntry = mutation({
  args: {
    name: v.string(),
    message: v.string(),
  },
  handler: async (ctx, args) => {
    const testEntryId = await ctx.db.insert("test_entries", {
      name: args.name,
      message: args.message,
    });
    
    return {
      id: testEntryId,
      name: args.name,
      message: args.message,
      timestamp: Date.now(),
    };
  },
});

// Get all test entries
export const getTestEntries = query({
  args: {},
  handler: async (ctx) => {
    const entries = await ctx.db
      .query("test_entries")
      .order("desc")
      .take(10); // Limit to last 10 entries
    
    return entries;
  },
});

// Clear all test entries (useful for testing)
export const clearTestEntries = mutation({
  args: {},
  handler: async (ctx) => {
    const entries = await ctx.db.query("test_entries").collect();
    
    for (const entry of entries) {
      await ctx.db.delete(entry._id);
    }
    
    return { deleted: entries.length };
  },
});
