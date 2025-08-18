import { httpRouter } from "convex/server";
import { registerMobileUser } from "./mobileAuth.js";

const http = httpRouter();

// Mobile-specific auth endpoint (still needed for Apple/Google Sign-In)
http.route({
  path: "/mobile/register-user",
  method: "POST", 
  handler: registerMobileUser,
});

export default http;
