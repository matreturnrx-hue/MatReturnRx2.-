import { defineBackend } from "@aws-amplify/backend";
import { auth } from "./auth/resource.js";
import { data } from "./data/resource.js";
import { processAction } from "./functions/process-action/resource.js";
import { verifyPurchase } from "./functions/verify-purchase/resource.js";

defineBackend({
  auth,
  data,
  processAction,
  verifyPurchase,
});
