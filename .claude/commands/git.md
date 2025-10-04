---
description: Git commit and push
allowed-tools: Bash(git:*)
---

Commit and push the current changes.

## Workflow

1. Analyze
2. Add & Commit
3. Push

## Commit Message Format

Only use single line commits. Do not add a detailed description. Follow
Conventional commits message format: `type: description`

**Types:**

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test changes
- `refactor:` - Code refactoring
- `chore:` - Build/config changes

**Examples:**

```bash
git add -A && git commit -am "feat: add git installation to bootstrap"
git add -A && git commit -am "fix: correct idempotency check in init"
git add -A && git commit -am "docs: update docs/tasks with next steps"
git add -A && git commit -am "refactor: improve platform dispatch pattern"
```

## Analyze Phase

Before committing, analyze changes:

```bash
git status             # See all changes
git diff               # Review unstaged changes
git diff --staged      # Review staged changes
git log --oneline -5   # Recent commits for context
```

## Add & Commit Phase

Always prefer to use a command like:

```bash
git add -A && git commit -am "type: message"
```

## Push Phase

```bash
git push
```

## Key Reminders

- Single-line commit messages only
- Complex git commands are very rarely needed. If you get stuck stop and ask for
  help. Never try to force things through.
- If stuck or running into a complex situation ask for how to proceed.

## Final Report

- When done report the commit hash (short) of the pushed code.
