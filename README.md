# `dross`

An autonomous assistant inspired by Cradle.

## Quick Start

All commands run from the repository root using `just`:

### Install Dependencies

```bash
just install
```

### Development

```bash
# TypeScript
just ts dev                    # All packages
just ts-pkg dev example        # Specific package
just ts build                  # Build all packages

# Python
just py-pkg run example        # Run Python package
just py sync                   # Sync all dependencies
just py-pkg sync example       # Sync specific package
```

### Code Quality

```bash
just lint                      # Lint everything
just format                    # Format everything
just py check                  # Type check Python
```

### Explore Commands

```bash
just --list                    # See all available commands
just help                      # Same as --list
```

### Direct Tool Usage

You can still use tools directly if needed:

```bash
cd py && uv sync
cd ts && pnpm install
```

Both approaches work. Use `just` commands for convenience, direct tools for specific needs.

## Monorepo Structure

This repository is organized as a monorepo with separate Python and TypeScript workspaces:

- `/py` - Python workspace (uv)
- `/ts` - TypeScript workspace (pnpm)
- `/tasks` - Just task definitions organized by domain

## Python Workspace

Location: `/py`

### Using Just Commands (Recommended)

```bash
just py sync                   # Sync all dependencies
just py-pkg sync example       # Sync specific package
just py-pkg run example        # Run package
just py lint                   # Lint code
just py format                 # Format code
just py check                  # Type check
```

### Direct Tool Usage

You can still use uv directly:

```bash
cd py
uv sync                    # Install/update dependencies
uv run <package>           # Run a package
ruff check .              # Lint
ruff format .             # Format
ty check .                # Type check
```

### Packages

- `example` - Example Python package
- `greeter` - Example package with workspace dependency

## TypeScript Workspace

Location: `/ts`

### Using Just Commands (Recommended)

```bash
just ts install                # Install dependencies
just ts dev                    # Run dev in all packages
just ts-pkg dev example        # Run dev in specific package
just ts lint                   # Lint code
just ts format                 # Format code
just ts build                  # Build all packages
```

### Direct Tool Usage

You can still use pnpm directly:

```bash
cd ts
pnpm install              # Install dependencies
pnpm -r run dev          # Run dev in all packages
pnpm --filter <pkg> dev  # Run dev in specific package
pnpm -r run lint         # Lint all packages
pnpm -r run format       # Format all packages
```

### Packages

- `@workspace/example` - Example TypeScript package
- `@workspace/example-app` - Example app using workspace package

## Creating New Packages

### Python Package

```bash
cd py/packages
mkdir my-package
cd my-package
mkdir -p src/my_package
touch src/my_package/__init__.py

cat > pyproject.toml << 'EOF'
[project]
name = "my-package"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
EOF

cd ../..
uv sync
```

### TypeScript Package

```bash
cd ts/packages
mkdir my-package
cd my-package
mkdir src
touch src/index.ts

cat > package.json << 'EOF'
{
  "name": "@workspace/my-package",
  "version": "0.1.0",
  "type": "module",
  "main": "./src/index.ts",
  "scripts": {
    "lint": "biome lint .",
    "format": "biome format ."
  },
  "dependencies": {}
}
EOF

cd ../..
pnpm install
```

## Adding Dependencies

### Python Workspace Dependency

Edit `pyproject.toml`:
```toml
[project]
dependencies = ["other-package"]

[tool.uv.sources]
other-package = { workspace = true }
```

### TypeScript Workspace Dependency

Edit `package.json`:
```json
{
  "dependencies": {
    "@workspace/other-package": "workspace:*"
  }
}
```

### TypeScript Catalog Dependency

Edit `package.json`:
```json
{
  "dependencies": {
    "react": "catalog:"
  }
}
```

Add to `/ts/pnpm-workspace.yaml` if not present:
```yaml
catalog:
  react: ^18.3.0
```

## Command System

This repository uses `just` as a command runner to centralize all operations at the root level.

### Organization

Commands are organized by domain in separate justfiles:

- `/justfile` - Entry point that imports domain justfiles
- `/tasks/py/justfile` - Python workspace commands
- `/tasks/ts/justfile` - TypeScript workspace commands
- `/tasks/repo/justfile` - Cross-cutting repository commands

### Design Principles

1. **Run from root**: Never need to cd into workspace directories
2. **Simple wrappers**: Just recipes wrap existing tool commands, no complex logic
3. **Namespace-style**: Commands use `just <workspace> <command>` pattern (e.g., `just py lint`)
4. **Domain separation**: Commands grouped by workspace for clarity
5. **Composition**: Combined commands (like `lint`) call workspace-specific commands

### Command Naming

- Workspace commands: `just <workspace> <command>` (e.g., `just py lint`, `just ts dev`)
- Package commands: `just <workspace>-pkg <command> <package>` (e.g., `just py-pkg run example`)
- Repository-wide: `just <command>` (e.g., `just lint`, `just format`, `just install`, `just clean`)

### Adding Commands

To add new commands:

1. Identify the domain (py, ts, or repo)
2. Edit the appropriate justfile in `/tasks/`
3. For workspace commands: Add a new case in the existing case statement
4. For repo commands: Add a new recipe that calls workspace commands
5. Keep it simple - just wrap the tool, don't add logic
6. Test from repository root

## Design Decisions

### Why Run From Root?

**Problem**: Developers had to remember which directory to cd into for each command.

**Solution**: Use `just` to run all commands from repository root.

**Trade-off**: Slightly longer command names (`just py lint` vs `cd py && ruff check`) for significantly better ergonomics. Worth it.

### Why Rename python to py and typescript to ts?

**Problem**: `python` and `typescript` are long to type and read in commands.

**Solution**: Rename to `py` and `ts`, the common abbreviations.

**Trade-off**: One-time update cost for long-term ergonomic benefit. The workspaces are still Python and TypeScript, the directories are just shorter.

**Consistency**: Both workspaces use 2-character names, creating a consistent pattern.

### Why Namespace-Style Commands?

**Problem**: Proliferation of separate recipes (lint-py, format-py, check-py, etc.) creates noise.

**Solution**: Use recipe parameters to create namespace-style commands (`just py lint`, `just ts build`).

**Trade-off**: Slightly more complex recipe implementation (case statements) for cleaner command interface. Scales much better.

**Benefits**:
- Natural to read and type (workspace first, then action)
- Easy to discover (error messages show available commands)
- Simple to extend (add new cases, don't create new recipes)
- Consistent with modern CLIs (git, kubectl, docker, etc.)

### Why Split Justfiles By Domain?

**Problem**: One large justfile becomes hard to navigate and maintain.

**Solution**: Split into domain-specific files in `/tasks/` directory.

**Trade-off**: Slightly more complex structure for better organization. Scales better as commands are added.

**Alternatives considered**:
- One large justfile: Would become unwieldy
- Justfiles in workspace dirs: Breaks "run from root" principle
- No organization: Hard to find relevant commands

### Why Not Build Orchestration?

**Problem**: Could we add task dependencies, caching, smart rebuilds?

**Decision**: No. Keep it simple.

**Rationale**:
- Tools (pnpm, vite, etc.) already handle their own caching and watching
- Build orchestration adds significant complexity
- Not needed for current workflows
- Can add later if pain points emerge

**Principle**: Boring solutions for boring problems. Add features incrementally when actually needed.

### Why These Tools?

Just is a command runner, not a build system. It's simple, fast, and cross-platform. Perfect for wrapping existing commands without adding complexity.

Alternatives considered:
- Make: Complex syntax, platform differences
- npm scripts: Limited to package.json, not monorepo-friendly at root
- Bash scripts: Hard to discover, no built-in help
- Turborepo/Nx: Way too much orchestration for our needs

