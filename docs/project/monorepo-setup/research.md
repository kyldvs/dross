# Research: Monorepo Setup

## Problem Statement

Set up a modern monorepo that supports both Python and TypeScript development with:
- Python: uv, ruff, ty
- TypeScript: pnpm, Biome, React
- Minimal root clutter through organized subdirectories

## Tool Research

### Python Toolchain

#### uv (Package Manager)

**What it is**: Extremely fast Python package and project manager written in Rust by Astral.

**Workspace Support**:
- Inspired by Cargo's workspace concept
- Multiple packages share a single lockfile for consistency
- Each package has its own `pyproject.toml`
- Commands like `uv lock` operate on entire workspace
- `uv run` and `uv sync` support `--package` flag for specific members

**Configuration Pattern**:
```toml
[tool.uv.workspace]
members = ["packages/*"]
exclude = ["packages/excluded-dir"]

[tool.uv.sources]
internal-package = { workspace = true }
```

**Key Insight**: The `workspace = true` in `tool.uv.sources` indicates dependency should come from workspace, not PyPI.

**Status**: Feature is functional but documentation is evolving (as of Jan 2025).

#### ruff (Linter & Formatter)

**What it is**: Extremely fast Python linter and code formatter written in Rust.

**Monorepo Features**:
- Hierarchical and cascading configuration
- Multiple `pyproject.toml` files at different levels
- Automatically picks up closest configuration
- 800+ built-in rules, 10-100x faster than existing tools
- Replaces: Flake8, isort, Black, pyupgrade, autoflake

**Configuration Files**: `pyproject.toml`, `ruff.toml`, or `.ruff.toml`

**Key Insight**: Subdirectories can override parent settings, making it ideal for monorepos with different package requirements.

#### ty (Type Checker)

**What it is**: Extremely fast Python type checker written in Rust by Astral. Currently in pre-alpha.

**Configuration**:
- Preferred file: `ty.toml` (though `pyproject.toml` works)
- Auto-detects src layout or flat layout
- Supports per-directory overrides via glob patterns
- Inline ignores: `# ty: ignore[rule1, rule2]`

**Key Settings**:
- Python version affects syntax and stdlib types
- Root paths for finding first-party modules
- Rule levels (error, warn, ignore)
- File exclusions via gitignore-style globs

**Key Insight**: Auto-detection of project layouts reduces configuration needs.

### TypeScript Toolchain

#### pnpm (Package Manager)

**Workspace Features**:
- Standard workspace configuration via `pnpm-workspace.yaml`
- Packages reference each other via `workspace:` protocol
- Centralized dependency management

**Catalog Feature** (Key Discovery):
- Define dependency versions as reusable constants in `pnpm-workspace.yaml`
- Reference via `catalog:` protocol in `package.json`
- Three modes: strict (only catalog), prefer (catalog fallback), manual (default)
- Reduces version duplication across workspace packages
- Both `catalog:` and `workspace:` protocols are removed during `pnpm publish`

**Configuration Pattern**:
```yaml
packages:
  - 'packages/*'
  - 'apps/*'

catalog:
  react: ^18.3.0
  typescript: ^5.3.0
```

**Key Insight**: Catalog feature is essential for maintaining consistent versions across monorepo.

#### Biome (Linter & Formatter)

**What it is**: Fast toolchain for JavaScript, TypeScript, JSX, TSX, JSON, HTML, CSS, GraphQL.

**Features**:
- 97% Prettier compatibility
- 360+ rules from ESLint, TypeScript ESLint
- Linter + Formatter + Import sorter in one tool
- Sane defaults, minimal configuration required
- Commands: `lint`, `format`, or `check` (both)

**Configuration**: `biome.json` recommended for consistency between CLI and LSP

**React Support**: Configurable JSX runtime (reactClassic for legacy React requiring imports)

**Key Insight**: "Works out of the box" philosophy reduces configuration overhead.

## Monorepo Structure Patterns

### Minimizing Root Clutter

**Python Recommendations**:
- Group packages under `/python` or `/packages` directory
- Each package has own `pyproject.toml`
- Root `pyproject.toml` defines workspace
- Shared `requirements.txt` at root for dev environment

**TypeScript Recommendations**:
- Separate `/packages` and `/apps` directories
- Shared packages go in `/packages`
- Applications go in `/apps`
- Shared dev dependencies in root `package.json`
- Per-package `package.json` for runtime dependencies

**Universal Principles**:
1. Keep configuration at appropriate levels (workspace root vs package)
2. Use workspace protocols to link internal packages
3. Single lockfile per language ecosystem
4. Avoid duplicating tool configs across packages

## Key Decisions Affecting Design

### 1. Workspace Organization
- **Decision**: Separate top-level directories for Python (`/python`) and TypeScript (`/typescript` or `/packages` + `/apps`)
- **Reason**: Prevents confusion between ecosystems, reduces root clutter
- **Impact**: Each ecosystem has its own clear boundary

### 2. Configuration Strategy
- **Decision**: Minimal root configuration, delegate to tools' defaults
- **Reason**: Modern tools (uv, pnpm, ruff, biome) have excellent defaults
- **Impact**: Less maintenance, easier upgrades, clearer intent

### 3. Shared Dependencies
- **Decision**: Use catalog feature (pnpm) and workspace sources (uv)
- **Reason**: Ensures version consistency without duplication
- **Impact**: Single source of truth for dependency versions

### 4. Tool Selection Rationale
- All tools are Rust-based for speed (uv, ruff, ty, Biome)
- All tools have monorepo/workspace awareness
- All tools follow "sane defaults" philosophy
- All tools are actively maintained by reputable organizations

## What Was NOT Researched

The following were deliberately not researched to avoid over-engineering:

- Build systems (Bazel, Nx, Turborepo, Pants)
- CI/CD configuration
- Docker containerization
- Testing frameworks
- Documentation generators
- Versioning strategies (changesets, semantic-release)
- IDE-specific configurations
- Pre-commit hooks
- Git workflow strategies

These are all valid concerns but are not essential for initial monorepo setup. They can be added incrementally as needs arise.

## Simplified Mental Model

**Python Side**:
```
/python (workspace root with pyproject.toml)
  /package-a (pyproject.toml)
  /package-b (pyproject.toml)
  uv.lock (shared)
```

**TypeScript Side**:
```
/packages (workspace packages)
  /lib-a (package.json)
  /lib-b (package.json)
/apps (applications)
  /app-a (package.json)
pnpm-workspace.yaml (defines workspace + catalog)
pnpm-lock.yaml (shared)
```

This structure keeps each ecosystem self-contained while maintaining clarity about internal dependencies.
