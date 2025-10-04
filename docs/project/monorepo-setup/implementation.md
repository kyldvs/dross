# Implementation Plan: Monorepo Setup

## Overview

This plan builds the monorepo structure incrementally. Each step produces working, testable code. Steps are ordered to enable validation at every stage.

## Prerequisites

Verify tools are installed:

```bash
# Check uv
uv --version

# Check pnpm
pnpm --version

# If missing, install:
# uv: curl -LsSf https://astral.sh/uv/install.sh | sh
# pnpm: curl -fsSL https://get.pnpm.io/install.sh | sh
```

## Step 1: Create Directory Structure

**Goal**: Establish workspace roots and package directories.

**Actions**:
```bash
cd /Users/kad/kyldvs/dross

# Python workspace
mkdir -p python/packages/example/src/example

# TypeScript workspace
mkdir -p typescript/packages/example/src
mkdir -p typescript/apps/example/src
```

**Validation**:
```bash
tree -L 3 -d python typescript
```

Expected output shows `python/packages/example` and `typescript/packages/example` and `typescript/apps/example`.

**Why this step**: Directories must exist before we add files.

---

## Step 2: Configure Python Workspace

**Goal**: Create minimal Python workspace configuration.

**Actions**:

Create `/Users/kad/kyldvs/dross/python/pyproject.toml`:
```toml
[tool.uv.workspace]
members = ["packages/*"]
```

Create `/Users/kad/kyldvs/dross/python/packages/example/pyproject.toml`:
```toml
[project]
name = "example"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

Create `/Users/kad/kyldvs/dross/python/packages/example/src/example/__init__.py`:
```python
"""Example Python package."""

__version__ = "0.1.0"


def hello() -> str:
    """Return a greeting."""
    return "Hello from Python workspace!"
```

**Validation**:
```bash
cd /Users/kad/kyldvs/dross/python
uv sync
uv run python -c "from example import hello; print(hello())"
```

Expected: Prints "Hello from Python workspace!"

**Why this step**: Proves Python workspace configuration is valid and packages are importable.

---

## Step 3: Configure TypeScript Workspace

**Goal**: Create minimal TypeScript workspace configuration.

**Actions**:

Create `/Users/kad/kyldvs/dross/typescript/pnpm-workspace.yaml`:
```yaml
packages:
  - 'packages/*'
  - 'apps/*'

catalog:
  typescript: ^5.3.0
  '@biomejs/biome': ^1.9.4
```

Create `/Users/kad/kyldvs/dross/typescript/package.json`:
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

Create `/Users/kad/kyldvs/dross/typescript/packages/example/package.json`:
```json
{
  "name": "@workspace/example",
  "version": "0.1.0",
  "type": "module",
  "main": "./src/index.ts",
  "scripts": {
    "lint": "biome lint .",
    "format": "biome format ."
  }
}
```

Create `/Users/kad/kyldvs/dross/typescript/packages/example/src/index.ts`:
```typescript
export function hello(): string {
  return "Hello from TypeScript workspace!";
}
```

**Validation**:
```bash
cd /Users/kad/kyldvs/dross/typescript
pnpm install
node --eval "import('./packages/example/src/index.ts').then(m => console.log(m.hello()))"
```

Expected: Prints "Hello from TypeScript workspace!"

**Why this step**: Proves TypeScript workspace configuration is valid and packages are importable.

---

## Step 4: Configure TypeScript App

**Goal**: Create example app to demonstrate app vs package distinction.

**Actions**:

Create `/Users/kad/kyldvs/dross/typescript/apps/example/package.json`:
```json
{
  "name": "@workspace/example-app",
  "version": "0.1.0",
  "type": "module",
  "private": true,
  "main": "./src/index.ts",
  "scripts": {
    "dev": "node ./src/index.ts",
    "lint": "biome lint .",
    "format": "biome format ."
  },
  "dependencies": {
    "@workspace/example": "workspace:*"
  }
}
```

Create `/Users/kad/kyldvs/dross/typescript/apps/example/src/index.ts`:
```typescript
import { hello } from "@workspace/example";

console.log(hello());
console.log("Running from app!");
```

**Validation**:
```bash
cd /Users/kad/kyldvs/dross/typescript
pnpm install
pnpm --filter @workspace/example-app dev
```

Expected: Prints both messages.

**Why this step**: Demonstrates workspace dependencies work correctly between packages and apps.

---

## Step 5: Add Python Internal Dependency

**Goal**: Show how Python packages depend on each other.

**Actions**:

Create `/Users/kad/kyldvs/dross/python/packages/greeter/pyproject.toml`:
```toml
[project]
name = "greeter"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["example"]

[tool.uv.sources]
example = { workspace = true }

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

Create `/Users/kad/kyldvs/dross/python/packages/greeter/src/greeter/__init__.py`:
```python
"""Greeter package that depends on example."""

from example import hello as example_hello

__version__ = "0.1.0"


def greet() -> str:
    """Greet using the example package."""
    return f"Greeter says: {example_hello()}"
```

**Validation**:
```bash
cd /Users/kad/kyldvs/dross/python
uv sync
uv run python -c "from greeter import greet; print(greet())"
```

Expected: Prints "Greeter says: Hello from Python workspace!"

**Why this step**: Proves Python workspace dependencies resolve correctly.

---

## Step 6: Create .gitignore

**Goal**: Prevent generated files from being committed.

**Actions**:

Create `/Users/kad/kyldvs/dross/.gitignore`:
```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
uv.lock
.venv/
*.egg-info/
dist/
build/

# TypeScript / Node
node_modules/
*.tsbuildinfo
dist/
build/
.next/
.turbo/
pnpm-lock.yaml

# Editors
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# OS
Thumbs.db
```

**Validation**:
```bash
cd /Users/kad/kyldvs/dross
git status
```

Expected: Generated files (node_modules, uv.lock, etc.) should not appear in untracked files.

**Why this step**: Clean git status is essential for development workflow.

---

## Step 7: Create README

**Goal**: Document workspace structure and basic usage.

**Actions**:

Create `/Users/kad/kyldvs/dross/README.md`:
```markdown
# Dross

A monorepo containing Python and TypeScript packages.

## Structure

- `/python` - Python workspace (uv)
- `/typescript` - TypeScript workspace (pnpm)

## Python Workspace

Location: `/python`

### Setup
\`\`\`bash
cd python
uv sync
\`\`\`

### Commands
\`\`\`bash
uv sync                    # Install/update dependencies
uv run <package>           # Run a package
ruff check .              # Lint
ruff format .             # Format
ty check .                # Type check
\`\`\`

### Packages

- `example` - Example Python package
- `greeter` - Example package with workspace dependency

## TypeScript Workspace

Location: `/typescript`

### Setup
\`\`\`bash
cd typescript
pnpm install
\`\`\`

### Commands
\`\`\`bash
pnpm install              # Install dependencies
pnpm -r run dev          # Run dev in all packages
pnpm --filter <pkg> dev  # Run dev in specific package
pnpm -r run lint         # Lint all packages
pnpm -r run format       # Format all packages
\`\`\`

### Packages

- `@workspace/example` - Example TypeScript package
- `@workspace/example-app` - Example app using workspace package

## Creating New Packages

### Python Package

\`\`\`bash
cd python/packages
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
\`\`\`

### TypeScript Package

\`\`\`bash
cd typescript/packages
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
\`\`\`

## Adding Dependencies

### Python Workspace Dependency

Edit `pyproject.toml`:
\`\`\`toml
[project]
dependencies = ["other-package"]

[tool.uv.sources]
other-package = { workspace = true }
\`\`\`

### TypeScript Workspace Dependency

Edit `package.json`:
\`\`\`json
{
  "dependencies": {
    "@workspace/other-package": "workspace:*"
  }
}
\`\`\`

### TypeScript Catalog Dependency

Edit `package.json`:
\`\`\`json
{
  "dependencies": {
    "react": "catalog:"
  }
}
\`\`\`

Add to `/typescript/pnpm-workspace.yaml` if not present:
\`\`\`yaml
catalog:
  react: ^18.3.0
\`\`\`
```

**Validation**:
```bash
cat /Users/kad/kyldvs/dross/README.md
```

Expected: File exists and is readable.

**Why this step**: Provides quick reference for common operations.

---

## Step 8: Final Validation

**Goal**: Verify entire setup works end-to-end.

**Actions**:

Run complete validation suite:

```bash
# Verify directory structure
tree -L 3 /Users/kad/kyldvs/dross

# Python workspace
cd /Users/kad/kyldvs/dross/python
uv sync
uv run python -c "from example import hello; print(hello())"
uv run python -c "from greeter import greet; print(greet())"

# TypeScript workspace
cd /Users/kad/kyldvs/dross/typescript
pnpm install
node --eval "import('./packages/example/src/index.ts').then(m => console.log(m.hello()))"
pnpm --filter @workspace/example-app dev

# Formatting (if tools installed)
cd /Users/kad/kyldvs/dross/python
uv tool install ruff
ruff format --check .

cd /Users/kad/kyldvs/dross/typescript
pnpm -r run format --write
```

**Expected**:
- All imports work
- All commands succeed
- No errors in output

**Why this step**: Confirms the entire monorepo is functional.

---

## Troubleshooting

### Python: "Package not found"

```bash
cd /Users/kad/kyldvs/dross/python
uv sync --verbose
```

Check that package is listed in `members` in workspace `pyproject.toml`.

### TypeScript: "Cannot find module"

```bash
cd /Users/kad/kyldvs/dross/typescript
pnpm install --force
```

Check that package is listed in `packages` in `pnpm-workspace.yaml`.

### Python: Workspace dependency not resolving

Verify `[tool.uv.sources]` section exists and uses `{ workspace = true }`.

### TypeScript: Workspace dependency not resolving

Verify dependency uses `workspace:*` protocol.

---

## What Happens Next

After this implementation:

1. **Workspace is ready**: Create packages in either ecosystem
2. **Dependencies work**: Internal references resolve correctly
3. **Tools work**: Lint, format, type-check commands function
4. **Git is clean**: Generated files are ignored

## What to Add Later (When Needed)

Do NOT add these proactively. Add only when you have a concrete need:

- `ruff.toml` - When you need custom lint rules
- `ty.toml` - When ty can't auto-detect project layout
- `biome.json` - When you need custom format/lint rules
- `tsconfig.base.json` - When multiple packages share TypeScript config
- Per-package `tsconfig.json` - When using tsc or tools requiring it
- Build tools - When packages need compilation
- Test frameworks - When writing tests
- CI/CD - When deploying

Start simple. Add complexity only when proven necessary.

---

## Summary of Deliverables

After completing all steps:

### Files Created
- `/python/pyproject.toml` - Workspace config
- `/python/packages/example/pyproject.toml` - Example package
- `/python/packages/example/src/example/__init__.py` - Example code
- `/python/packages/greeter/pyproject.toml` - Package with dependency
- `/python/packages/greeter/src/greeter/__init__.py` - Dependent code
- `/typescript/pnpm-workspace.yaml` - Workspace config
- `/typescript/package.json` - Root package
- `/typescript/packages/example/package.json` - Example package
- `/typescript/packages/example/src/index.ts` - Example code
- `/typescript/apps/example/package.json` - Example app
- `/typescript/apps/example/src/index.ts` - App code
- `/.gitignore` - Git exclusions
- `/README.md` - Documentation

### Generated Files (not committed)
- `/python/uv.lock` - Python lockfile
- `/typescript/pnpm-lock.yaml` - TypeScript lockfile
- `/typescript/node_modules/` - Dependencies

### Validation Commands
All commands in Step 8 should succeed without errors.
