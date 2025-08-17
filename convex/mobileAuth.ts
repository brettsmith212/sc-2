import { httpAction } from "./_generated/server";
import { internal } from "./_generated/api";

// Simple endpoint for iOS to register authenticated users
export const registerMobileUser = httpAction(async (ctx, request) => {
  try {
    const body = await request.json();
    const { email, displayName, authProvider, authToken } = body;
    
    // For now, just validate that we have required fields
    if (!email || !authProvider) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }
    
    // Create a simple user record
    const userId = await ctx.runMutation(internal.users.createUser, {
      email,
      displayName,
      authProvider
    });
    
    return new Response(JSON.stringify({ 
      success: true, 
      userId,
      message: "User registered successfully" 
    }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({ 
      error: "Registration failed", 
      details: error.message 
    }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
});
