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
- Codex may run formatters, analyzers, and tests when relevant to the current task.
- For focused feature tasks, prefer focused validation: format only Dart files modified by the task, run focused tests related to changed files, and run flutter analyze when explicitly allowed or needed.
- Full repository formatting or full repository validation may run only when explicitly requested, or for repository-wide cleanup, release validation, or validation-tooling tasks.
- If full formatting detects unrelated pre-existing formatting debt, report it separately and do not modify unrelated files without explicit approval.
- Do not treat unrelated pre-existing formatting debt as a failure of the current focused feature change.
- Do not run flutter run, flutter build, flutter upgrade, or flutter pub upgrade as validation unless explicitly requested.
- If a terminal command stalls or completion cannot be confirmed, interrupt it and report it as not completed. Do not retry stalled commands indefinitely.
- At completion, report files changed, behavior or policy changed, commands run, validation results, interrupted commands if any, and remaining manual checks.
