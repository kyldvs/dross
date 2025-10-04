# Research: Monorepo Iteration

## Current State

### Directory Structure
```
/Users/kad/kyldvs/dross/
├── python/                      # Python workspace
│   ├── pyproject.toml          # Workspace config: members = ["packages/*"]
│   ├── packages/
│   │   ├── example/            # Basic package
│   │   └── greeter/            # Package with workspace dependency
│   └── uv.lock                 # Workspace lockfile
│
├── typescript/                  # TypeScript workspace
│   ├── package.json            # Root package with shared dev deps
│   ├── pnpm-workspace.yaml     # Workspace + catalog config
│   ├── packages/
│   │   └── example/            # Shared library (@workspace/example)
│   ├── apps/
│   │   └── example/            # App using workspace package
│   ├── pnpm-lock.yaml          # Workspace lockfile
│   └── node_modules/           # Hoisted dependencies
│
├── docs/                       # Documentation
│   ├── design/                 # Design decisions
│   ├── project/                # Project-specific docs
│   └── principles/             # Core principles
│
├── README.md                   # Project overview
├── CLAUDE.md                   # Claude Code instructions
└── .gitignore                  # Version control exclusions
```

### Current Command Patterns

#### Python (run from `/python`)
```bash
cd python
uv sync                    # Install/update dependencies
uv run <package>           # Run a package
ruff check .              # Lint
ruff format .             # Format
ty check .                # Type check
```

#### TypeScript (run from `/typescript`)
```bash
cd typescript
pnpm install              # Install dependencies
pnpm -r run dev          # Run dev in all packages
pnpm --filter <pkg> dev  # Run dev in specific package
pnpm -r run lint         # Lint all packages
pnpm -r run format       # Format all packages
```

### Existing Task Automation
- **None**: No justfile, Makefile, or other task automation exists
- Commands are documented in README.md
- All commands require `cd` into workspace directory first
- No centralized command runner

### Tool Availability
- `just` is installed: version 1.40.0
- Supports:
  - Modularity via `import` directives
  - Running recipes from any directory with `--working-directory`
  - Recipe dependencies and parameters
  - Cross-platform compatibility

### Package Management

#### Python Workspace
- Tool: `uv` (modern, fast Python package manager)
- Lockfile: `uv.lock` (single workspace lockfile)
- Commands work recursively from workspace root
- No per-package commands needed (uv handles workspace)

#### TypeScript Workspace
- Tool: `pnpm` (fast, disk-efficient package manager)
- Lockfile: `pnpm-lock.yaml` (single workspace lockfile)
- Catalog: Centralized version management in `pnpm-workspace.yaml`
- Commands:
  - `-r` (recursive): run in all packages
  - `--filter <pkg>`: run in specific package
  - Root scripts proxy to workspace commands

### Common Development Commands

Based on existing package.json and documentation:

1. **Install/Setup**
   - Python: `uv sync`
   - TypeScript: `pnpm install`

2. **Development**
   - TypeScript: `pnpm -r run dev` or `pnpm --filter <pkg> dev`
   - Python: `uv run <package>`

3. **Code Quality**
   - Lint:
     - Python: `ruff check .`
     - TypeScript: `pnpm -r run lint` (uses Biome)
   - Format:
     - Python: `ruff format .`
     - TypeScript: `pnpm -r run format` (uses Biome)
   - Type check:
     - Python: `ty check .`
     - TypeScript: `tsc` (if configured per-package)

4. **Build** (TypeScript only, per-package basis)
   - `pnpm -r run build`

### Workspace Dependencies

#### Python
- Uses `{ workspace = true }` in `[tool.uv.sources]`
- Example: `greeter` depends on `example`
- Resolved at workspace level, not via npm-style linking

#### TypeScript
- Uses `workspace:*` protocol
- Example: `@workspace/example-app` depends on `@workspace/example`
- Linked via pnpm workspace feature
- Catalog for shared external dependencies

### Design Decisions (from existing docs)

1. **Separate workspace roots**: Python and TypeScript are independent
2. **Minimal configuration**: Rely on tool defaults
3. **Less but better**: Only add what's necessary
4. **No root-level build tools**: Each workspace manages its own
5. **Clear ownership**: Every file belongs to one ecosystem

## Key Findings

### What Needs to Change
1. **Rename `typescript/` to `ts/`**: Simpler, less typing
2. **Centralize commands at root**: No more `cd` required
3. **Add justfile structure**: Root justfile imports domain-specific justfiles
4. **Update README.md**: Document the command-from-root pattern

### What Should Stay the Same
1. Separate workspace roots (Python and TypeScript independence)
2. Minimal configuration philosophy
3. Tool choices (uv, pnpm, ruff, biome)
4. Workspace dependency patterns
5. No build configuration (let packages handle their own needs)

### Design Constraints

1. **Just recipes must handle paths correctly**
   - Recipes run from root, must specify correct working directory
   - Use `--working-directory` or `cd` in recipes
   - Absolute paths safer than relative paths

2. **Tool commands expect to run from workspace root**
   - Python tools: expect to run from `/python`
   - TypeScript tools: expect to run from `/typescript` (soon `/ts`)
   - Just recipes must invoke commands in correct directory

3. **Workspace-relative commands**
   - `uv sync` works from Python workspace root
   - `pnpm` commands work from TypeScript workspace root
   - Per-package commands need filtering (`pnpm --filter`)

4. **Cross-platform compatibility**
   - Use just's cross-platform features
   - Avoid bash-specific syntax in recipes
   - Test on multiple platforms or stick to portable commands

## Questions Answered

### Can we run all commands from root?
**Yes**, via justfile recipes that invoke commands in the correct workspace directory.

### Where should justfiles live?
- **Root**: `/Users/kad/kyldvs/dross/justfile` - Main entry point, imports others
- **Domain-specific**: `/Users/kad/kyldvs/dross/tasks/<domain>/justfile` - Organized by concern
  - Example: `/tasks/python/justfile`, `/tasks/typescript/justfile`

### What commands are most common?
1. Install/sync dependencies
2. Lint and format
3. Type check
4. Run development servers
5. Clean (remove generated files)

### Do we need build commands?
**Not at workspace level**. Build is package-specific and varies widely. Let packages define their own build processes. We can add recipes if specific build patterns emerge.

### Should we support package-specific commands?
**Yes**, via parameters to recipes. Example:
```just
# Run dev in specific TypeScript package
dev-ts package:
    cd ts && pnpm --filter {{package}} run dev
```

## Implications for Design

1. **Rename is straightforward**: `typescript/` → `ts/` is a simple move
2. **Justfile organization**:
   - Keep root justfile minimal - just imports and top-level commands
   - Split by domain: `tasks/python/`, `tasks/ts/`, `tasks/docs/`
   - Each justfile contains recipes for its domain
3. **Recipe naming convention**:
   - Prefix with domain when ambiguous: `lint-py`, `lint-ts`, `lint` (all)
   - Or use justfile namespacing if available
4. **Documentation updates**:
   - README.md should show just commands, not direct tool commands
   - Keep workspace-specific instructions for context
   - Add justfile recipe listing command

## What We Won't Do

1. **Unified workspace**: Keep Python and TypeScript separate
2. **Complex build orchestration**: No Nx, Turborepo, or similar
3. **Watch mode orchestration**: Let tools handle their own watching
4. **Dependency graph analysis**: Not needed at this scale
5. **Monorepo-specific tooling**: Standard tools work fine
6. **Cross-language dependencies**: Out of scope, architecturally avoided

## References

- Just manual: https://just.systems/man/en/
- uv documentation: https://docs.astral.sh/uv/
- pnpm workspaces: https://pnpm.io/workspaces
- Existing requirements: `/Users/kad/kyldvs/dross/docs/project/monorepo-setup/requirements.md`
- Existing architecture: `/Users/kad/kyldvs/dross/docs/design/monorepo-architecture.md`
