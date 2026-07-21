# Gemini conversation fallback

Plantalk sends only non-empty conversation that the local router does not handle
to one remote API slot:

```text
ChatPanel -> ConversationOrchestrator -> Supabase plant-chat -> Gemini
```

DB-authored replies, condition-memory replies, local casual replies, and the
daily opening keyword remain ahead of this route. A remote timeout, invalid
response, blocked response, missing function, or provider error returns the
existing local fallback sentence.

## Security boundary

The Flutter app invokes only the authenticated Supabase function named
`plant-chat`. It never contains or receives the Gemini API key.

The Edge Function reads `GEMINI_API_KEY` from the Supabase function secret
store and calls the fixed `gemini-3.1-flash-lite` endpoint. The function:

- accepts POST requests with a bearer session only
- limits each bearer token to 12 requests per minute per function instance
- limits user input to 500 characters and provider output to 500 characters
- applies a seven-second provider timeout
- requests at most 180 output tokens
- returns sanitized errors without request, response, token, or key logging
- does not read or write `plant_memories`

The app sends plant name, optional species, optional mood, bounded friendship,
locale, and the current user message. It does not send the plant database ID,
condition memory, daily keyword document, or earlier conversation history.

## Production setup

Create a Gemini API key in Google AI Studio and restrict it to the Gemini API.
Do not place the key in Flutter source, GitHub Actions secrets, database rows,
or local shell history.

Set the secret and deploy with the Supabase CLI:

```powershell
$geminiKey = Read-Host "Gemini API 키 입력" -AsSecureString
$keyPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($geminiKey)

try {
    $plainKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPtr)
    supabase secrets set "GEMINI_API_KEY=$plainKey"
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPtr)
    Remove-Variable geminiKey, keyPtr, plainKey -ErrorAction SilentlyContinue
}

supabase functions deploy plant-chat
```

The deployed function must keep JWT verification enabled. Plantalk establishes
an anonymous Supabase session before opening the app, so the function invocation
uses that user session rather than a server secret.

Configure Gemini API quota and billing alerts before external testing.

## Validation

The Flutter tests use an injected function invoker and never initialize real
Supabase, access the network, or require credentials. The Edge Function handler
tests use an injected fetch implementation and never call Gemini.
