# Technical Specification: Monorepo Iteration

## Overview

This specification describes how to simplify the monorepo by enabling all commands to run from the repository root using `just` as a command runner. The core principle is: **developers never need to remember which directory to cd into**.

## Design Philosophy

**Boring is good**. We're not building a task orchestrator. We're wrapping existing commands with a convenient interface. Just is a command runner, not a build system.

### What We're NOT Doing

- Build caching or dependency graphs
- Watch mode coordination
- Complex task orchestration
- Smart rebuilds
- Anything clever

### What We ARE Doing

- Making existing commands easier to run
- Organizing commands by domain
- Documenting the workflow clearly

## Changes

### 1. Directory Renames

**Decision**: Rename `python/` to `py/` and `typescript/` to `ts/`

**Rationale**:
- Dramatically simpler to type (python: 6 chars → 2 chars, typescript: 10 chars → 2 chars)
- Matches common abbreviation conventions (py, ts)
- Reduces cognitive load
- Consistent brevity across both workspaces
- No technical advantage, pure ergonomics

**Trade-offs**:
- Short term: Need to update references
- Long term: Better developer experience

**What Changes**:
- Directory names on filesystem
- README.md documentation
- Any other markdown files referencing the paths
- Justfile paths (if created first, update after rename)
- .gitignore entries (if any)

**What Does NOT Change**:
- Python package names or configuration
- TypeScript package names (@workspace/*)
- pnpm-workspace.yaml configuration (uses relative paths from ts/ root)
- package.json files
- Lock files (pyproject.toml, pnpm-lock.yaml)
- Tool configurations (biome, tsconfig, pyproject.toml, ruff.toml, etc.)
- Actual code

**Why These Don't Change**: The directory names are just containers. Workspace configurations use relative paths from their roots, not the parent directory names.

### 2. Justfile Command System

**Decision**: Split justfiles by domain in `/tasks/` directory, import from root

**Rationale**:
- Clear separation of concerns
- Easy to find relevant commands
- Scales as commands are added
- Matches existing docs/ organization pattern

**Trade-offs**:
- Slightly more complex structure vs one file
- Import syntax required in root justfile
- Worth it: keeps each file focused and navigable

**Structure**:

```
/
├── justfile                    # Entry point, imports others
└── tasks/
    ├── py/justfile             # Python commands
    ├── ts/justfile             # TypeScript commands
    └── repo/justfile           # Cross-cutting commands
```

**Why `/tasks/` directory**:
- Clear purpose: these are task definitions
- Out of the way at root level
- Follows existing conventions (docs/, py/, ts/)

**Alternatives Considered**:
- `.just/`: Hidden directories are harder to discover
- `just/`: Too generic
- No directory: Clutters root with multiple justfiles

#### Root Justfile Specification

**Path**: `/justfile`

**Purpose**: Entry point that imports domain justfiles and provides top-level convenience commands

**Content**:
```just
# Import domain-specific task definitions
import 'tasks/py/justfile'
import 'tasks/ts/justfile'
import 'tasks/repo/justfile'

# Default recipe: list available commands
default:
    @just --list

# Show available commands
help:
    @just --list
```

**Design Notes**:
- Minimal: only imports and help
- Default recipe shows commands (good UX when running bare `just`)
- `help` alias for discoverability
- No logic here, all logic in domain files

#### Python Justfile Specification

**Path**: `/tasks/py/justfile`

**Purpose**: Python workspace commands using namespace-style organization

**Recipes**:

```just
# Sync Python dependencies
py command:
    #!/usr/bin/env bash
    set -euo pipefail
    cd py
    case "{{command}}" in
        sync)
            uv sync
            ;;
        lint)
            ruff check .
            ;;
        format)
            ruff format .
            ;;
        check)
            ty check .
            ;;
        *)
            echo "Unknown py command: {{command}}"
            echo "Available: sync, lint, format, check"
            exit 1
            ;;
    esac

# Sync specific Python package
py-pkg command package:
    #!/usr/bin/env bash
    set -euo pipefail
    cd py
    case "{{command}}" in
        sync)
            uv sync --package {{package}}
            ;;
        run)
            uv run {{package}}
            ;;
        *)
            echo "Unknown py-pkg command: {{command}}"
            echo "Available: sync, run"
            exit 1
            ;;
    esac
```

**Design Notes**:
- Uses recipe parameters to create namespace-like commands
- Single `py` recipe handles common commands via case statement
- `py-pkg` recipe handles package-specific operations
- All recipes use `cd py` to enter workspace
- `set -euo pipefail` ensures errors propagate correctly
- Clear error messages for unknown commands

**Why This Works**:
- `just py lint` reads naturally as "run py workspace lint command"
- `just py-pkg run example` reads as "run example in py workspace"
- Case statement is simple, explicit, and easy to extend
- Bash shebang allows multi-line logic while keeping recipes readable
- Exit codes propagate correctly from tools

**Usage Examples**:
```bash
just py sync        # Sync all dependencies
just py lint        # Lint Python code
just py format      # Format Python code
just py check       # Type check Python code
just py-pkg sync example    # Sync specific package
just py-pkg run example     # Run Python package
```

#### TypeScript Justfile Specification

**Path**: `/tasks/ts/justfile`

**Purpose**: TypeScript workspace commands using namespace-style organization

**Recipes**:

```just
# TypeScript workspace commands
ts command:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ts
    case "{{command}}" in
        install)
            pnpm install
            ;;
        dev)
            pnpm -r run dev
            ;;
        lint)
            pnpm -r run lint
            ;;
        format)
            pnpm -r run format
            ;;
        build)
            pnpm -r run build
            ;;
        *)
            echo "Unknown ts command: {{command}}"
            echo "Available: install, dev, lint, format, build"
            exit 1
            ;;
    esac

# TypeScript package-specific commands
ts-pkg command package:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ts
    case "{{command}}" in
        dev)
            pnpm --filter {{package}} run dev
            ;;
        build)
            pnpm --filter {{package}} run build
            ;;
        *)
            echo "Unknown ts-pkg command: {{command}}"
            echo "Available: dev, build"
            exit 1
            ;;
    esac
```

**Design Notes**:
- Uses recipe parameters to create namespace-like commands
- Single `ts` recipe handles common workspace commands
- `ts-pkg` recipe handles package-specific operations
- All recipes use `cd ts` to enter workspace
- Wraps pnpm commands directly
- `-r` flag for recursive workspace operations
- `--filter` for package-specific operations

**Why pnpm Commands**:
- pnpm already handles workspace coordination
- `-r` recursively runs in all packages
- `--filter` targets specific packages
- No need to reinvent what pnpm does

**Usage Examples**:
```bash
just ts install             # Install all dependencies
just ts dev                 # Run dev in all packages
just ts lint                # Lint all packages
just ts format              # Format all packages
just ts build               # Build all packages
just ts-pkg dev example     # Run dev for specific package
just ts-pkg build example   # Build specific package
```

#### Repository Justfile Specification

**Path**: `/tasks/repo/justfile`

**Purpose**: Cross-cutting repository commands that coordinate across workspaces

**Recipes**:

```just
# Lint everything
lint:
    just py lint
    just ts lint

# Format everything
format:
    just py format
    just ts format

# Install/sync all dependencies
install:
    just py sync
    just ts install

# Clean generated files
clean:
    rm -rf py/.venv py/**/__pycache__
    rm -rf ts/node_modules ts/**/node_modules ts/**/.next ts/**/.turbo
```

**Design Notes**:
- Composite recipes call workspace-specific commands
- Uses `just <namespace> <command>` pattern to invoke other recipes
- `clean` is destructive but safe (only generated files)
- Simple sequential execution
- No complex dependency syntax needed

**Why This Works**:
- Clear what "lint everything" means (py lint, then ts lint)
- Explicit execution order
- Easy to add new workspaces
- Natural composition pattern

**Clean Command Safety**:
- Only removes generated directories
- Paths use `py/` and `ts/` directory names
- User can recreate with `just install`
- Standard monorepo cleanup pattern

### 3. README.md Updates

**Decision**: Add "Quick Start" section at top, document design decisions

**Rationale**:
- New developers need immediate context
- "Quick Start" is the entry point
- Design decisions explain the "why"

**Trade-offs**:
- Longer README
- Worth it: better onboarding experience

**Sections to Add**:

1. **Quick Start** (near top, after overview):
   - Most common commands
   - Shows the "run from root" pattern
   - References `just --list` for discovery
   - Concrete examples for both workspaces

2. **Command System** (new section):
   - Explains justfile organization
   - Documents the domain split
   - References individual justfiles for details

3. **Design Decisions** (new section):
   - Why "run from root"
   - Why domain-split justfiles
   - Why we don't do orchestration

**Sections to Update**:

1. **Directory Structure**:
   - Change `python/` → `py/` and `typescript/` → `ts/`
   - Add `tasks/` directory with subdirectories
   - Keep structure otherwise

2. **Python Workspace** section:
   - Add references to namespace-style `just py` commands
   - Keep direct commands for reference
   - Note: both approaches work

3. **TypeScript Workspace** section:
   - Same pattern as Python section
   - Update path to `ts/`
   - Show namespace-style `just ts` commands

**What NOT to Change**:
- Keep workspace-specific details
- Keep tool documentation
- Keep philosophy sections

## Configuration File Updates

### Files That Change

1. **README.md**: Path updates, new sections (described above)
2. **.gitignore**: May need `python/` → `py/` and `typescript/` → `ts/` updates

### Files That DO NOT Change

These files are NOT affected by the renames:

- `pnpm-workspace.yaml`: Uses relative paths from ts/ root
- `package.json` files: Use @workspace/* names, not paths
- `biome.json`: Lives in ts/, no parent references
- `tsconfig.json` files: Use relative paths within ts/
- `pyproject.toml`: Workspace-relative paths
- `ruff.toml`: Workspace-relative paths
- Any tool configs: Use workspace-relative paths

### Why These Don't Change

Both workspaces are self-contained. Configs inside `py/` and `ts/` use relative paths. The parent directory names are irrelevant to the tools.

## Recipe Naming Convention

**Pattern**: Namespace-style using recipe parameters

**Examples**:
- `just py lint`: Lint Python workspace
- `just ts dev`: Run dev in TypeScript workspace
- `just py-pkg sync example`: Sync specific Python package
- `just ts-pkg build example`: Build specific TypeScript package

**Rationale**:
- Namespace-first is intuitive (reads left-to-right: workspace then action)
- Clean separation: workspace is the namespace, command is the action
- Natural to type and discover
- Consistent with other modern CLIs (git, kubectl, etc.)
- Easy to extend with new commands

**Repository-wide Commands**:
- `just install`: Install all dependencies (calls `py sync` and `ts install`)
- `just lint`: Lint all workspaces (calls `py lint` and `ts lint`)
- `just format`: Format all workspaces (calls `py format` and `ts format`)
- `just clean`: Remove all generated files

**Package-specific Commands**:
- `just py-pkg <command> <package>`: Python package operations
- `just ts-pkg <command> <package>`: TypeScript package operations

## Execution Model

**Pattern**: Case statement with bash shebang in recipe

**Why This Works**:
- Explicit about where command runs (`cd py` or `cd ts`)
- Case statement maps command name to tool invocation
- Works from any directory
- Exit codes propagate correctly (`set -euo pipefail`)
- Clear error messages for unknown commands
- Simple to extend with new commands

**Example**:
```just
py command:
    #!/usr/bin/env bash
    set -euo pipefail
    cd py
    case "{{command}}" in
        lint)
            ruff check .
            ;;
        *)
            echo "Unknown py command: {{command}}"
            exit 1
            ;;
    esac
```

**What Happens**:
1. User runs `just py lint`
2. Just invokes `py` recipe with `command="lint"`
3. Bash script changes to `py/` directory
4. Case statement matches "lint" and runs `ruff check .`
5. Output shows in terminal
6. Exit code propagates to just (fails on errors due to `set -euo pipefail`)
7. Script exits, back at root

**Benefits**:
- Single recipe per workspace (not one per command)
- Discoverable via error messages
- Easy to add new commands
- Type-safe (parameters validated by just)

## Implementation Order

**Order Matters**: This is a safe, incremental approach

1. **Create justfiles first** (using `python/` and `typescript/` paths if directories not renamed yet)
2. **Test all recipes work** with current structure
3. **Rename directories**: `python/` → `py/` and `typescript/` → `ts/` (simple directory moves)
4. **Update justfile paths** (change python to py, typescript to ts)
5. **Update README.md** (paths and new sections)
6. **Test everything again**

**Why This Order**:
- Justfiles are additive, non-breaking
- Can test before changing anything
- Renames are atomic (git mv)
- Update paths after renames confirmed
- Documentation last ensures accuracy

## Validation Approach

**Validation Criteria**: Each command must:
1. Run successfully from repository root
2. Produce expected output
3. Return correct exit code
4. Work in both Python and TypeScript workspaces

**Test Matrix**:
```
just install          → Both workspaces sync/install
just lint             → Both workspaces lint
just format           → Both workspaces format
just py sync          → Python syncs
just py lint          → Python lints
just py format        → Python formats
just py check         → Python type checks
just ts install       → TypeScript installs
just ts dev           → TypeScript dev starts
just ts lint          → TypeScript lints
just ts format        → TypeScript formats
just ts build         → TypeScript builds
just py-pkg sync pkg  → Python package syncs
just py-pkg run pkg   → Python package runs
just ts-pkg dev pkg   → TypeScript package dev
just clean            → Generated files removed
```

**How to Test**:
1. Start from clean state (just clean)
2. Run just install
3. Run each command individually
4. Verify output matches tool expectations
5. Check exit codes (should be 0 for success)
6. Test error cases (unknown commands should show help and exit 1)

## Cross-Platform Considerations

**Platforms**: macOS and Linux (primary development environments)

**Compatibility**:
- `cd` is universal
- `rm -rf` is standard
- `pnpm`, `uv`, `ruff`, `ty` are cross-platform tools
- Just syntax is platform-agnostic

**Not Tested**: Windows (out of scope)

## Migration Risk Assessment

**Low Risk Changes**:
- Adding justfiles (additive only)
- README updates (documentation only)

**Medium Risk Changes**:
- Directory rename (atomic but affects paths)
- Justfile path updates (simple find/replace)

**Mitigation**:
- Test justfiles before rename
- Use git mv for rename (preserves history)
- Update paths in one commit
- Test everything after each step

**Rollback Strategy**:
- Git revert if issues found
- Rename is atomic, easy to reverse
- Justfiles can be deleted without side effects

## Success Metrics

This design succeeds if:

1. Developer runs `just install` and all dependencies install
2. Developer runs `just lint` and all code lints
3. Developer runs `just py lint` and Python code lints
4. Developer runs `just ts dev` and dev servers start
5. Developer runs `just ts-pkg dev example` and specific dev server starts
6. Developer reads README and understands the workflow
7. Commands are discoverable (`just --list` shows all commands)
8. Unknown commands show helpful error messages
9. No existing workflows break
10. No tool configuration changes required
11. Justfiles are obvious and self-documenting
12. Namespace pattern feels natural and intuitive

## Explicit Non-Goals

Documenting what we're NOT doing:

1. **No build orchestration**: Not tracking dependencies between tasks
2. **No caching**: Tools handle their own caching
3. **No watch mode**: Tools handle their own watching
4. **No parallelization**: Dependencies run sequentially
5. **No environment management**: Not handling .env files
6. **No git hooks**: Not automating pre-commit, etc.
7. **No CI/CD integration**: Focused on local development
8. **No testing framework**: Not defining test commands yet

**Why**: Keep it simple. Add features when actually needed. Boring solutions for boring problems.

## Future Considerations

**Not in this iteration, but noted for future**:

- Test commands when testing strategy defined
- CI recipe when CI is configured
- Docker commands if containers added
- Database commands if databases added

**Principle**: Add incrementally when pain points emerge. Don't build for imagined future needs.
