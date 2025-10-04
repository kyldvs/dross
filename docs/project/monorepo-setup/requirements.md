# Requirements: Monorepo Setup

## Project Name

`monorepo-setup`

## Core Principle

Create the simplest possible monorepo structure that enables productive development with modern Python and TypeScript tooling. Every configuration file must justify its existence. Every directory must serve a clear purpose.

## Directory Structure

### MUST Have

```
/
├── python/                    # Python workspace root
│   ├── pyproject.toml        # Workspace configuration
│   └── packages/             # Python packages
│       └── example/
│           └── pyproject.toml
│
├── typescript/               # TypeScript workspace root
│   ├── pnpm-workspace.yaml   # Workspace + catalog configuration
│   ├── package.json          # Root package with shared dev deps
│   ├── packages/             # Shared libraries
│   │   └── example/
│   │       └── package.json
│   └── apps/                 # Applications
│       └── example/
│           └── package.json
│
├── .gitignore               # Version control exclusions
└── README.md                # Project overview
```

### MUST NOT Have

- No `/src` at root (ambiguous ownership)
- No `/packages` at root (conflicts between ecosystems)
- No `/libs`, `/modules`, or other generic names at root
- No configuration files at root for Python/TypeScript tools
- No `.vscode`, `.idea`, or IDE-specific folders (user responsibility)
- No `Dockerfile`, `docker-compose.yml` (out of scope)
- No `.github/workflows` (out of scope)
- No test framework configuration (out of scope)

## Python Configuration

### MUST Have

1. **Root workspace `pyproject.toml`** (`/python/pyproject.toml`):
   ```toml
   [tool.uv.workspace]
   members = ["packages/*"]
   ```
   - Defines workspace members
   - No project metadata (not a package itself)
   - Minimal configuration, rely on uv defaults

2. **Package `pyproject.toml`** (e.g., `/python/packages/example/pyproject.toml`):
   ```toml
   [project]
   name = "example"
   version = "0.1.0"
   requires-python = ">=3.12"
   dependencies = []

   [tool.uv.sources]
   # Add workspace dependencies with: { workspace = true }
   ```
   - Standard Python package metadata
   - Explicit Python version requirement
   - Use `workspace = true` for internal dependencies

3. **Optional: `ruff.toml`** (at root or package level):
   - Only if overriding defaults
   - Prefer package-level for package-specific rules
   - Let hierarchical config do the work

4. **Optional: `ty.toml`** (at root or package level):
   - Only if overriding defaults
   - ty auto-detects project layout
   - Add only when needed

### MUST NOT Have

- No `requirements.txt` at root (use `uv` for everything)
- No `setup.py` (legacy, use `pyproject.toml`)
- No `poetry.lock` or `Pipfile.lock` (use `uv.lock`)
- No `.python-version` (specify in `pyproject.toml`)
- No per-package lockfiles (workspace shares one)
- No `tox.ini`, `setup.cfg`, or other legacy config files

## TypeScript Configuration

### MUST Have

1. **Workspace configuration** (`/typescript/pnpm-workspace.yaml`):
   ```yaml
   packages:
     - 'packages/*'
     - 'apps/*'

   catalog:
     react: ^18.3.0
     react-dom: ^18.3.0
     typescript: ^5.3.0
     # Add more shared dependencies
   ```
   - Defines workspace packages
   - Centralizes dependency versions via catalog
   - Keep catalog minimal, add versions as needed

2. **Root `package.json`** (`/typescript/package.json`):
   ```json
   {
     "name": "typescript-workspace",
     "private": true,
     "scripts": {
       "dev": "pnpm --recursive run dev",
       "build": "pnpm --recursive run build",
       "lint": "pnpm --recursive run lint",
       "format": "pnpm --recursive run format"
     },
     "devDependencies": {
       "@biomejs/biome": "catalog:",
       "typescript": "catalog:"
     }
   }
   ```
   - Private (never published)
   - Shared dev dependencies only
   - Convenience scripts for workspace-wide commands

3. **Package `package.json`** (e.g., `/typescript/packages/example/package.json`):
   ```json
   {
     "name": "@workspace/example",
     "version": "0.1.0",
     "type": "module",
     "scripts": {
       "dev": "...",
       "build": "...",
       "lint": "biome lint .",
       "format": "biome format ."
     },
     "dependencies": {
       "react": "catalog:",
       "@workspace/other": "workspace:*"
     }
   }
   ```
   - Scoped name (`@workspace/`) for clarity
   - Use `catalog:` for shared versions
   - Use `workspace:*` for internal packages
   - ESM by default (`"type": "module"`)

4. **Optional: `biome.json`** (at root or package level):
   ```json
   {
     "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
     "formatter": {
       "enabled": true
     },
     "linter": {
       "enabled": true
     }
   }
   ```
   - Only if overriding defaults
   - Biome works well without configuration

5. **Optional: `tsconfig.json`** (per package):
   ```json
   {
     "extends": "../../tsconfig.base.json",
     "compilerOptions": {
       "outDir": "./dist",
       "rootDir": "./src"
     }
   }
   ```
   - Only if using TypeScript compiler
   - Consider shared base config
   - Many tools (Vite, Next.js) provide defaults

### MUST NOT Have

- No `node_modules` in packages (workspace hoisting)
- No per-package lockfiles (workspace uses one `pnpm-lock.yaml`)
- No `yarn.lock` or `package-lock.json` (use pnpm)
- No `.eslintrc`, `.prettierrc` (use Biome)
- No duplicate dependency versions (use catalog)
- No `lerna.json` (use native pnpm workspaces)

## Tool Installation

### Python Tools

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install ruff (via uv)
uv tool install ruff

# Install ty (via uv)
uv tool install ty
```

### TypeScript Tools

```bash
# Install pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh

# Install Biome (via pnpm in workspace root)
cd typescript && pnpm add -D @biomejs/biome
```

### MUST NOT Install

- No global npm packages (use pnpm)
- No pip packages globally (use uv)
- No version managers (nvm, pyenv) required if using uv
- No additional formatters/linters (tools are comprehensive)

## Workspace Commands

### Python

```bash
# From /python directory
uv sync                    # Sync all workspace packages
uv sync --package example  # Sync specific package
uv run example             # Run package
uv lock                    # Update lockfile
ruff check .              # Lint workspace
ruff format .             # Format workspace
ty check .                # Type check workspace
```

### TypeScript

```bash
# From /typescript directory
pnpm install              # Install all dependencies
pnpm -r run dev          # Run dev in all packages
pnpm --filter example dev # Run dev in specific package
pnpm -r run lint         # Lint all packages
pnpm -r run format       # Format all packages
```

### MUST NOT Use

- No `npm install` (use pnpm)
- No `pip install` (use uv)
- No `python -m venv` (uv handles environments)
- No workspace-wide test commands (out of scope)

## Minimal Viable Setup

The absolute minimum to get started:

1. Create directory structure
2. Write `/python/pyproject.toml` with workspace config
3. Write `/typescript/pnpm-workspace.yaml` with workspace config
4. Write `/typescript/package.json` with private flag
5. Create one example package in each ecosystem
6. Run `uv sync` in Python workspace
7. Run `pnpm install` in TypeScript workspace

Everything else is optional until proven necessary.

## What Is Out of Scope

### Explicitly NOT Included

1. **Testing**: No Jest, pytest, vitest, or test runners
2. **Building**: No build tools, bundlers, or compilers beyond what packages need
3. **CI/CD**: No GitHub Actions, GitLab CI, or deployment pipelines
4. **Documentation**: No Sphinx, Docusaurus, or doc generators
5. **Containerization**: No Docker, Compose, or Kubernetes
6. **Versioning**: No changesets, semantic-release, or version management
7. **Git Hooks**: No husky, pre-commit, or lint-staged
8. **IDE Config**: No .vscode, .idea, or editor settings
9. **Environment Variables**: No .env files or secrets management
10. **Databases**: No migration tools or database configs
11. **Logging**: No structured logging or observability
12. **Monitoring**: No error tracking or APM
13. **Security**: No dependency scanning or SAST tools
14. **Performance**: No profiling or optimization tools
15. **Internationalization**: No i18n frameworks

### Why These Are Out of Scope

Each of these is a valid concern for production systems, but they should be added incrementally based on actual needs. Starting with them would be premature optimization and violate the "less but better" principle.

The goal is a foundation that doesn't prevent these additions but doesn't mandate them either.

## Success Criteria

A successful minimal setup enables:

1. Creating new Python packages in `/python/packages/`
2. Creating new TypeScript packages in `/typescript/packages/`
3. Creating new TypeScript apps in `/typescript/apps/`
4. Cross-package dependencies within each ecosystem
5. Consistent dependency versions via catalog (TypeScript) and workspace (Python)
6. Running lint, format, and type check commands
7. Zero configuration for common use cases
8. Clear separation between Python and TypeScript concerns

## Anti-Patterns to Avoid

1. **Over-configuration**: Adding config "just in case"
2. **Tool proliferation**: More tools than necessary
3. **Premature optimization**: Performance tuning without evidence
4. **Assumed requirements**: Features nobody asked for
5. **Copy-paste configs**: Configurations copied without understanding
6. **Root clutter**: Config files that belong in subdirectories
7. **Version duplication**: Hardcoding versions in multiple places
8. **Build complexity**: Complex build pipelines for simple needs

## Questions to Ask Before Adding Anything

1. Is this absolutely required for basic development?
2. Does this solve a problem we actually have?
3. Can the tools' defaults handle this?
4. Will this create future maintenance burden?
5. Is there a simpler alternative?

If the answer to any question is "no" or "maybe," don't add it yet.
