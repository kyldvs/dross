# Requirements: Monorepo Iteration

## Project Name

`monorepo-iteration`

## Core Principle

Simplify the monorepo by making it easier to use. All commands should run from root. The developer should never need to remember which directory to `cd` into. Less typing, less context switching, more focus on actual work.

## The Three Changes

### 1. Rename `typescript/` to `ts/`

**Why**: Simpler, less typing, matches common abbreviation conventions.

**What changes**:
- Directory name: `typescript/` → `ts/`
- README.md references
- Any documentation mentioning the path
- .gitignore if it has typescript-specific entries

**What stays the same**:
- Package names (still `@workspace/*`)
- pnpm-workspace.yaml structure
- All tooling configuration
- Workspace dependencies

### 2. Add Justfile-Based Command System

**Why**: Centralize all commands at root so developers never need to `cd` into subdirectories.

**Structure**:
```
/
├── justfile                    # Root justfile (imports others)
└── tasks/                      # Domain-specific justfiles
    ├── python/justfile         # Python workspace commands
    ├── ts/justfile             # TypeScript workspace commands
    └── repo/justfile           # Repository-wide commands
```

**Root justfile** (`/justfile`):
- Imports domain-specific justfiles
- Provides top-level convenience recipes
- Lists available commands (default recipe)
- Minimal - mostly delegation

**Domain justfiles**:
- `tasks/python/justfile`: Python-specific commands
- `tasks/ts/justfile`: TypeScript-specific commands
- `tasks/repo/justfile`: Cross-cutting concerns (git, docs, cleanup)

**Commands to implement**:

#### Python commands (tasks/python/justfile)
```just
# Sync Python dependencies
sync-py:
    cd python && uv sync

# Sync specific Python package
sync-py-pkg package:
    cd python && uv sync --package {{package}}

# Run Python package
run-py package:
    cd python && uv run {{package}}

# Lint Python code
lint-py:
    cd python && ruff check .

# Format Python code
format-py:
    cd python && ruff format .

# Type check Python code
check-py:
    cd python && ty check .
```

#### TypeScript commands (tasks/ts/justfile)
```just
# Install TypeScript dependencies
install-ts:
    cd ts && pnpm install

# Run dev in all TypeScript packages
dev-ts:
    cd ts && pnpm -r run dev

# Run dev in specific TypeScript package
dev-ts-pkg package:
    cd ts && pnpm --filter {{package}} run dev

# Lint TypeScript code
lint-ts:
    cd ts && pnpm -r run lint

# Format TypeScript code
format-ts:
    cd ts && pnpm -r run format

# Build TypeScript packages
build-ts:
    cd ts && pnpm -r run build
```

#### Repository commands (tasks/repo/justfile)
```just
# Lint everything
lint: lint-py lint-ts

# Format everything
format: format-py format-ts

# Install/sync all dependencies
install: sync-py install-ts

# Clean generated files
clean:
    rm -rf python/.venv python/**/__pycache__
    rm -rf ts/node_modules ts/**/node_modules ts/**/.next ts/**/.turbo
```

#### Root justfile recipes
```just
# Import domain justfiles
import 'tasks/python/justfile'
import 'tasks/ts/justfile'
import 'tasks/repo/justfile'

# Default recipe: list available commands
default:
    @just --list

# Show this help
help:
    @just --list
```

### 3. Update README.md

**Why**: Document the new workflow so developers know to use just commands from root.

**What to add**:
1. **Quick start section** at the top showing `just` commands
2. **Design decision** explaining "run from root" approach
3. **Available commands** section (can reference `just --list`)
4. Keep existing workspace-specific sections for context/reference

**New sections**:
```markdown
## Quick Start

All commands run from the repository root using `just`:

# Install dependencies
just install

# Development
just dev-ts              # All TypeScript packages
just dev-ts-pkg example  # Specific package
just run-py example      # Python package

# Code quality
just lint                # Lint everything
just format              # Format everything
just check-py            # Type check Python

# See all commands
just --list
```

## What Must NOT Change

1. **Workspace separation**: Python and TypeScript remain independent
2. **Tool choices**: Keep uv, pnpm, ruff, biome, ty
3. **Minimal configuration philosophy**: No unnecessary config files
4. **Package structure**: packages/ and apps/ organization
5. **Dependency patterns**: workspace: and catalog: remain unchanged
6. **Lockfiles**: One per workspace, not at root

## What Is Out of Scope

### Explicitly NOT Included

1. **Build orchestration**: No task dependencies, caching, or smart rebuilds
2. **Watch mode**: Let tools (pnpm, vite, etc.) handle watching
3. **Test commands**: Testing not yet defined in monorepo
4. **CI/CD integration**: Just focus on local development
5. **Release/versioning**: Not part of this iteration
6. **Git hooks**: No pre-commit, lint-staged, etc.
7. **Environment management**: No .env handling
8. **Docker**: No container-related commands
9. **Database**: No migration or DB commands
10. **Deployment**: No deploy recipes

### Why These Are Out of Scope

This iteration is about simplifying the developer experience for existing workflows. We're not adding new capabilities, just making existing commands easier to run. Additional features should be added incrementally when actually needed.

## Success Criteria

A successful iteration means:

1. Developer can run any command from repository root
2. `typescript/` is renamed to `ts/` everywhere
3. README.md clearly documents the "run from root" pattern
4. Justfiles are organized by domain, not mixed together
5. All existing commands work via just recipes
6. No change to underlying tools or configurations
7. No breaking changes to package dependencies
8. Documentation clearly explains design decisions

## Design Decisions

### Justfile Organization

**Decision**: Split justfiles by domain in `/tasks/` subdirectory.

**Why**:
- Clear separation of concerns
- Easy to find relevant commands
- Scales better than one large justfile
- Matches existing docs/ organization pattern

**Alternatives considered**:
- Single root justfile: Would become large and hard to navigate
- Per-workspace justfiles: Less discoverable, doesn't centralize
- Nested in workspace dirs: Breaks "run from root" principle

### Recipe Naming Convention

**Decision**: Suffix with workspace identifier when ambiguous (e.g., `lint-py`, `lint-ts`).

**Why**:
- Clear which workspace a command applies to
- Allows workspace-specific and combined commands
- Natural for developers: `lint-py` obviously means Python linting

**Alternatives considered**:
- Prefix (e.g., `py-lint`): Less natural to type/read
- No suffix (e.g., just `lint`): Ambiguous for workspace-specific commands
- Module syntax (e.g., `python::lint`): Just doesn't support this well

### Root vs Workspace Execution

**Decision**: Recipes run from root, then `cd` into workspace.

**Why**:
- Just recipes can run from any directory via `just` command
- Explicit `cd` in recipes is clear about where commands run
- Matches developer mental model: "I'm at root, running Python command"

**Alternatives considered**:
- Set working directory in root: Requires complex just syntax
- Relative paths: Fragile, breaks if cwd changes
- Absolute paths: Not portable across machines

## Migration Path

### Step 1: Add Justfiles (Non-breaking)
1. Create `/tasks/python/justfile`
2. Create `/tasks/ts/justfile` (uses old `typescript/` path)
3. Create `/tasks/repo/justfile`
4. Create `/justfile` with imports
5. Test all recipes work

### Step 2: Rename Directory
1. Move `typescript/` → `ts/`
2. Update justfiles to use new path
3. Update README.md paths
4. Update any other documentation
5. Test all commands still work

### Step 3: Update Documentation
1. Add "Quick Start" section to README.md
2. Add "Design Decisions" section explaining "run from root"
3. Update workspace-specific sections with justfile references
4. Ensure all path references use `ts/` not `typescript/`

### Step 4: Validation
1. Run all commands from root via just
2. Verify Python commands work
3. Verify TypeScript commands work
4. Verify combined commands (lint, format, install) work
5. Check documentation accuracy

## Anti-Patterns to Avoid

1. **Complex recipes**: Keep recipes simple, just invoke the tool
2. **Logic in justfiles**: Don't add conditionals, loops, or complex bash
3. **Duplicate commands**: Don't recreate what tools already do
4. **Hidden behavior**: Every recipe should be obvious from its name
5. **Build orchestration**: Don't try to be Turborepo or Nx
6. **Cross-platform issues**: Test commands work on macOS and Linux
7. **Breaking workspace commands**: Direct tool commands should still work

## Validation Questions

Before marking this complete, verify:

1. Can I install all dependencies with one command? (`just install`)
2. Can I lint everything with one command? (`just lint`)
3. Can I format everything with one command? (`just format`)
4. Can I run TypeScript dev servers from root? (`just dev-ts`)
5. Can I run Python packages from root? (`just run-py example`)
6. Does `just --list` show all available commands?
7. Does README.md explain the new workflow?
8. Does README.md document the "run from root" design decision?
9. Are all references to `typescript/` changed to `ts/`?
10. Do all existing workflows still function?

## Questions to Ask Before Adding More

1. Is this command frequently used?
2. Does it work better from root than from workspace?
3. Is the recipe simple (just invoke tool, don't add logic)?
4. Does it fit in an existing domain justfile?
5. Would a developer expect to find this command?

If any answer is "no" or "maybe," don't add it yet. Keep it minimal.
