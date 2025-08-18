import { httpAction } from "./_generated/server";
import { internal } from "./_generated/api";

export const saveMobileAddress = httpAction(async (ctx, request) => {
  const body = await request.json();
  
  const { userId, label, name, phone, email, line1, line2, city, state, postalCode, country } = body;
  
  if (!userId || !label || !name || !line1 || !city || !state || !postalCode || !country) {
    return new Response(JSON.stringify({ 
      success: false, 
      error: "Missing required fields" 
    }), {
      status: 400,
      headers: { "Content-Type": "application/json" }
    });
  }
  
  try {
    // Create the address using internal mutation, passing userId directly  
    const addressId = await ctx.runMutation(internal.addresses.createValidatedAddressInternal, {
      userId: userId as any, // Cast to bypass type checking since we know this is a valid user ID
      label,
      name,
      phone: phone || undefined,
      email: email || undefined,
      line1,
      line2: line2 || undefined,
      city,
      state,
      postalCode,
      country,
      validationMeta: undefined
    });
    
    return new Response(JSON.stringify({ 
      success: true, 
      addressId 
    }), {
      headers: { "Content-Type": "application/json" }
    });
    
  } catch (error) {
    console.error("Failed to save address:", error);
    return new Response(JSON.stringify({ 
      success: false, 
      error: error instanceof Error ? error.message : "Unknown error" 
    }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
});

export const listMobileAddresses = httpAction(async (ctx, request) => {
  const body = await request.json();
  const { userId } = body;
  
  if (!userId) {
    return new Response(JSON.stringify({ 
      success: false, 
      error: "Missing userId" 
    }), {
      status: 400,
      headers: { "Content-Type": "application/json" }
    });
  }
  
  try {
    // Get addresses using internal query
    const addresses = await ctx.runQuery(internal.addresses.listAddressesInternal, {
      userId: userId as any,
      validatedOnly: true
    });
    
    return new Response(JSON.stringify({ 
      success: true, 
      addresses 
    }), {
      headers: { "Content-Type": "application/json" }
    });
    
  } catch (error) {
    console.error("Failed to list addresses:", error);
    return new Response(JSON.stringify({ 
      success: false, 
      error: error instanceof Error ? error.message : "Unknown error" 
    }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
});
