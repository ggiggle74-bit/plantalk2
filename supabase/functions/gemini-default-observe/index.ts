import { createGeminiDefaultObserveHandler } from "./handler.ts";

Deno.serve(
  createGeminiDefaultObserveHandler({
    getEnv: (name) => Deno.env.get(name),
  }),
);
