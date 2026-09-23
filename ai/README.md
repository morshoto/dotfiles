# Shared AI configuration

`ai/skills/` is the canonical source for skills shared by Codex and Claude
Code. Home Manager links that directory to both `~/.codex/skills` and
`~/.claude/skills`.

Tool-specific configuration stays in its own directory. Codex instructions
and rules live under `codex/`; Claude-only configuration can be added under
`claude/` without changing the shared skills source.

Authentication, session state, and other private configuration remain local
and are not stored in this repository.
