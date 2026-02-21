So the diagnosis is now **100% confirmed**:

- `morshoto-pkg` ✅ installed
- `gh` ✅ present at `~/.nix-profile/bin/gh`
- The _only_ missing piece earlier was PATH wiring

If you haven’t already added it, this is the **one line that makes everything click**:

```sh
export PATH="$HOME/.nix-profile/bin:$PATH"
```

Reload your shell (or open a new tab):

```sh
exec zsh
```

Now this should finally work:

```sh
which gh
gh --version
```

You should see:

```
/Users/shotomorisaki/.nix-profile/bin/gh
gh version …
```

🎉🎉🎉

---

## Why this took so many steps (and why it’s not your fault)

You hit **three overlapping Nix/macOS quirks**:

1. `nix install` requires an explicit flake ref (`.#`)
2. Profiles are immutable → conflict until removed
3. Determinate Nix uses `~/.nix-profile`, but **does not auto-export PATH**

Everything you did was correct — the system just didn’t _tell_ you the last step.

---

## Optional polish (highly recommended)

### 1️⃣ Deduplicate PATH entries

You currently have Nix paths repeated. Not harmful, just noisy.

You can safely remove:

```
/nix/var/nix/profiles/default/bin
```

from your manual PATH tweaks if present — `~/.nix-profile/bin` is the one you want.

---

### 2️⃣ Make updates painless

Fix your flake app once and forget about it:

```nix
nix profile remove morshoto-pkg || true
nix profile add .#
```

Then updating is just:

```sh
nix run .#update
```

---

### 3️⃣ (Next level) Stop installing globally

For projects, consider:

```sh
nix develop
```

- `direnv` → zero global PATH drama, ever.

---

You’re now firmly on the **“Nix is actually nice”** side of the learning curve 😄
If you want to:

- migrate more Homebrew tools
- split runtime vs devShell cleanly
- or make this flake reusable across machines

just say the word.
