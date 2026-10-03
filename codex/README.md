# Codex configuration

Codex configuration has separate portable, project, and local ownership:

| File | Owner and purpose |
| --- | --- |
| `codex/portable.config.toml` | Tracked source for shared model, reasoning, personality, approval, sandbox, and feature preferences. |
| `.codex/config.toml` | Project-level link to the portable source. Codex reads it only after this repository is trusted. |
| `~/.codex/portable.config.toml` | Home Manager link to the same source, used when the CLI selects the `portable` profile. |
| `codex/config.toml` | Ignored machine-local user config, linked to `~/.codex/config.toml`. Keep host paths, project trust, MCP commands, and app-managed settings here. |

Authentication, sessions, caches, and plugin installation data stay in the
local Codex home and are not linked from the repository. The tracked profile
contains only reviewed portable settings; do not copy the full local config
into it.

## Apply and edit

On a new machine, apply Home Manager from this repository to link the portable
profile:

```bash
nix run "path:$PWD#switch"
```

In this repository, the project config layer uses the portable settings after
you trust the project. For CLI sessions in other repositories, select the
profile explicitly:

```bash
codex --profile portable
```

Codex applies that profile over the machine's `~/.codex/config.toml`. Project
settings and command-line overrides have higher precedence. Profile selection
is explicit for the CLI; the desktop app and IDE continue to use the trusted
project layer here and the local user config elsewhere.

Edit `codex/portable.config.toml` to change portable preferences. The project
link and Home Manager profile link point to that same file, so changes are
visible without copying app state. Edit the ignored `codex/config.toml` or use
Codex settings for machine-specific and app-managed values. Do not commit that
file.
