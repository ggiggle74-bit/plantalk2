import { createPlantChatHandler } from './handler.ts';

Deno.serve(
  createPlantChatHandler({
    apiKey: Deno.env.get('GEMINI_API_KEY'),
  }),
);
