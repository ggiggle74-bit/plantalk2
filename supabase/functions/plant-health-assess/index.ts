import { createPlantHealthAssessHandler } from "./handler.ts";

Deno.serve(
  createPlantHealthAssessHandler({
    getEnv: (name) => Deno.env.get(name),
  }),
);
