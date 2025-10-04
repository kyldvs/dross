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

### 1. Directory Rename: typescript → ts

**Decision**: Rename `typescript/` to `ts/`

**Rationale**:
- Simpler to type (10 chars → 2 chars)
- Matches common abbreviation conventions
- Reduces cognitive load
- No technical advantage, pure ergonomics

**Trade-offs**:
- Short term: Need to update references
- Long term: Better developer experience

**What Changes**:
- Directory name on filesystem
- README.md documentation
- Any other markdown files referencing the path
- Justfile paths (if created first, update after rename)
- .gitignore entries (if any)

**What Does NOT Change**:
- Package names (@workspace/*)
- pnpm-workspace.yaml configuration
- package.json files
- Lock files
- Tool configurations (biome, tsconfig, etc.)
- Actual code

**Why These Don't Change**: The directory name is just a container. The TypeScript workspace configuration uses `packages` and `apps` paths, not the parent directory name.

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
    ├── python/justfile         # Python commands
    ├── ts/justfile             # TypeScript commands
    └── repo/justfile           # Cross-cutting commands
```

**Why `/tasks/` directory**:
- Clear purpose: these are task definitions
- Out of the way at root level
- Follows existing conventions (docs/, python/, ts/)

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
import 'tasks/python/justfile'
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

**Path**: `/tasks/python/justfile`

**Purpose**: Python workspace commands

**Recipes**:

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

**Design Notes**:
- All recipes use `cd python &&` pattern for clarity
- No error handling: let tools fail naturally
- No complex bash: one command per recipe
- Parameters use just's `{{variable}}` syntax
- Recipe names use `-py` suffix for workspace disambiguation

**Why This Works**:
- `cd python &&` runs in a subshell, doesn't affect caller
- Tool output goes directly to terminal
- Exit codes propagate correctly
- Simple to understand and modify

#### TypeScript Justfile Specification

**Path**: `/tasks/ts/justfile`

**Purpose**: TypeScript workspace commands

**Recipes**:

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

**Design Notes**:
- Uses `ts/` path (assumes rename completed or updated after rename)
- Wraps pnpm commands directly
- `-r` flag for recursive workspace operations
- `--filter` for package-specific operations
- Recipe names use `-ts` suffix

**Why pnpm Commands**:
- pnpm already handles workspace coordination
- `-r` recursively runs in all packages
- `--filter` targets specific packages
- No need to reinvent what pnpm does

#### Repository Justfile Specification

**Path**: `/tasks/repo/justfile`

**Purpose**: Cross-cutting repository commands

**Recipes**:

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

**Design Notes**:
- Composite recipes depend on domain recipes
- `clean` is destructive but safe (only generated files)
- Uses just's dependency syntax (`: dep1 dep2`)
- No logic beyond basic cleanup

**Why Dependencies Work**:
- just runs dependencies first
- Natural way to compose commands
- Clear what "lint everything" means

**Clean Command Safety**:
- Only removes generated directories
- Paths are explicit, no wildcards at root
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
   - Change `typescript/` → `ts/`
   - Keep structure otherwise

2. **Python Workspace** section:
   - Add references to `just` commands
   - Keep direct commands for reference
   - Note: both approaches work

3. **TypeScript Workspace** section:
   - Same pattern as Python section
   - Update path to `ts/`

**What NOT to Change**:
- Keep workspace-specific details
- Keep tool documentation
- Keep philosophy sections

## Configuration File Updates

### Files That Change

1. **README.md**: Path updates, new sections (described above)

### Files That DO NOT Change

These files are NOT affected by the rename:

- `pnpm-workspace.yaml`: Uses relative paths from ts/ root
- `package.json` files: Use @workspace/* names, not paths
- `biome.json`: Lives in ts/, no parent references
- `tsconfig.json` files: Use relative paths within ts/
- `.gitignore`: May have `typescript/` entries to update
- `pyproject.toml`: No TypeScript references
- Any Python config: No TypeScript references

### Why These Don't Change

The TypeScript workspace is self-contained. Configs inside `ts/` use relative paths. The parent directory name is irrelevant to the tools.

## Recipe Naming Convention

**Pattern**: `<verb>-<workspace>` or `<verb>-<workspace>-pkg`

**Examples**:
- `lint-py`: Lint Python workspace
- `dev-ts`: Run dev in TypeScript workspace
- `sync-py-pkg`: Sync specific Python package

**Rationale**:
- Verb-first is action-oriented
- Workspace suffix disambiguates
- `-pkg` suffix indicates package parameter
- Natural to type and read

**Special Cases**:
- `install`: No suffix, clearly means "everything"
- `lint`: No suffix, clearly means "everything"
- `format`: No suffix, clearly means "everything"
- `clean`: No suffix, clearly means "everything"

## Execution Model

**Pattern**: `cd <workspace> && <command>`

**Why This Works**:
- Explicit about where command runs
- Works from any directory
- Subshell doesn't affect caller
- Exit codes propagate
- Output goes to terminal

**Example**:
```just
lint-py:
    cd python && ruff check .
```

**What Happens**:
1. Just runs from root
2. Command changes to python/ directory
3. ruff check runs in that context
4. Output shows in terminal
5. Exit code returns to just
6. Subshell exits, we're back at root

## Implementation Order

**Order Matters**: This is a safe, incremental approach

1. **Create justfiles first** (using `typescript/` path if directory not renamed yet)
2. **Test all recipes work** with current structure
3. **Rename typescript/ → ts/** (simple directory move)
4. **Update justfile paths** (change typescript to ts)
5. **Update README.md** (paths and new sections)
6. **Test everything again**

**Why This Order**:
- Justfiles are additive, non-breaking
- Can test before changing anything
- Rename is atomic (git mv)
- Update paths after rename confirmed
- Documentation last ensures accuracy

## Validation Approach

**Validation Criteria**: Each command must:
1. Run successfully from repository root
2. Produce expected output
3. Return correct exit code
4. Work in both Python and TypeScript workspaces

**Test Matrix**:
```
just install     → Both workspaces sync
just lint        → Both workspaces lint
just format      → Both workspaces format
just sync-py     → Python syncs
just install-ts  → TypeScript installs
just run-py pkg  → Python package runs
just dev-ts      → TypeScript dev starts
just clean       → Generated files removed
```

**How to Test**:
1. Start from clean state (just clean)
2. Run just install
3. Run each command individually
4. Verify output matches tool expectations
5. Check exit codes (should be 0 for success)

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
3. Developer runs `just dev-ts-pkg example` and dev server starts
4. Developer reads README and understands the workflow
5. No existing workflows break
6. No tool configuration changes required
7. Justfiles are obvious and self-documenting

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
