# `dross`

An autonomous assistant inspired by Cradle.

## Monorepo Structure

This repository is organized as a monorepo with separate Python and TypeScript workspaces:

- `/python` - Python workspace (uv)
- `/typescript` - TypeScript workspace (pnpm)

## Python Workspace

Location: `/python`

### Setup
```bash
cd python
uv sync
```

### Commands
```bash
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

Location: `/typescript`

### Setup
```bash
cd typescript
pnpm install
```

### Commands
```bash
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
```

### TypeScript Package

```bash
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

Add to `/typescript/pnpm-workspace.yaml` if not present:
```yaml
catalog:
  react: ^18.3.0
```

