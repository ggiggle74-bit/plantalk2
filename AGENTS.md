# Repository Agent Instructions

- Always inspect git status before editing.
- Preserve user changes and untracked files.
- Never reset, restore, clean, stash, commit, or push unless explicitly asked.
- Preserve UTF-8 Korean text.
- Use Get-Content -Encoding utf8 when inspecting Korean files in PowerShell.
- Do not infer source corruption from default PowerShell rendering.
- Keep plant_identification separate from plant_analysis.
- Do not modify main.dart, plant_service.dart, database schema, or Supabase Edge Functions unless the task explicitly requires it.
- Unit and widget tests must not depend on real Supabase initialization, external network access, or production credentials.
- Run project validation through: dart run tool/codex_validate.dart
- Do not run flutter run as validation.
- If validation times out, report the timeout as a failure rather than waiting.
- At completion report files changed, behavior, commands, results, and remaining manual checks.
