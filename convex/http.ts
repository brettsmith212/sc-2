import { httpRouter } from "convex/server";
import { registerMobileUser } from "./mobileAuth.js";
import { saveMobileAddress, listMobileAddresses } from "./mobileAddresses.js";

const http = httpRouter();

// Mobile-specific auth endpoint
http.route({
  path: "/mobile/register-user",
  method: "POST", 
  handler: registerMobileUser,
});

// Mobile-specific address endpoints
http.route({
  path: "/mobile/save-address",
  method: "POST",
  handler: saveMobileAddress,
});

http.route({
  path: "/mobile/list-addresses",
  method: "POST",
  handler: listMobileAddresses,
});

export default http;
