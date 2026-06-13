# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## Project: workspaces

A tmux session manager for macOS Terminal.app. Replaces the default shell with an interactive picker that creates and attaches to tmux sessions.

**Key files:**
- `tmux-picker` — zsh script launched directly by Terminal.app as the startup command. Handles session listing, creation (with layout + directory picker), and kill with confirmation.
- `tmux.conf` — tmux config. No plugins; terminal/mouse/clipboard settings only.
- `install.sh` — idempotent setup script for a new Mac. Installs Homebrew, tmux, fzf, symlinks configs, patches `.zshrc`.

**Architecture:**
Terminal.app → `exec tmux-picker` → `exec tmux attach` (replaces process, no orphans)

`tmux-picker` uses fzf with output redirected to temp files — never inside `$()` — to avoid zsh's busy-wait spin loop on command substitution.

**Testing changes to `tmux-picker`:**
- Open a new terminal tab and observe behaviour directly — this is the only meaningful test
- Check for stuck zsh processes after closing a tab: `ps aux | awk '$3 > 90 && /zsh/ && $7 == "??"'`

**Shell conventions:**
- Script is zsh (`#!/bin/zsh`), not bash
- Use `exec` for all final tmux commands — never plain `tmux attach` or `tmux new-session` at the end of a flow
- Temp files over `$()` for any interactive command (fzf, user input)
- `&>/dev/null` to suppress all output from restore.sh
