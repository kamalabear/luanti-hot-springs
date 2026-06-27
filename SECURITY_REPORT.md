# Security Report

Audit date: 2026-05-24

## Scope

Static review of this Luanti mod for local secrets, command execution, network access, file access, formspec/input handlers, chatcommands, unsafe deserialization, and broad denial-of-service risks.

## Findings

No project-specific security findings were identified in the quick audit.

## Notes

- No committed secrets or credential files were found.
- No shell execution, HTTP API use, arbitrary code loading, file writes, chatcommands, or formspec receive handlers were found.
- The VS Code task deploys the whole workspace folder to a local mods directory. That is convenient locally, but should not be used against a shared or production mods path without reviewing what will be copied.

## Recommendations

- Keep settings namespaced and clamp numeric settings.
- Treat deployment tasks as local-development utilities only.
- Escape any future player-controlled formspec text with `minetest.formspec_escape`.
