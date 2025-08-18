import { UserIdentity } from "convex/server";
import { QueryCtx, MutationCtx } from "./_generated/server";

/**
 * Requires user to be authenticated and returns their identity
 * @param ctx Query or Mutation context
 * @returns UserIdentity if authenticated
 * @throws Error if not authenticated
 */
export async function requireLogin(ctx: QueryCtx | MutationCtx): Promise<UserIdentity> {
  const user = await ctx.auth.getUserIdentity();
  if (!user) {
    throw new Error("Not authenticated");
  }
  return user;
}

/**
 * Gets the user ID from authentication context
 * @param ctx Query or Mutation context
 * @returns User ID string
 * @throws Error if not authenticated
 */
export async function getUserId(ctx: QueryCtx | MutationCtx): Promise<string> {
  const user = await requireLogin(ctx);
  return user.subject;
}
