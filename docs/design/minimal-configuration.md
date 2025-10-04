# Minimal Configuration Philosophy

## The Principle

Every configuration file must justify its existence. Default behavior is preferred over explicit configuration.

## What We Configured (and Why)

### `/python/pyproject.toml`
```toml
[tool.uv.workspace]
members = ["packages/*"]
```

**Why this exists:**
uv needs to know which directories contain workspace packages. There's no default assumption.

**Why nothing else:**
uv's defaults are good. Don't override them without a specific reason.

### `/typescript/pnpm-workspace.yaml`
```yaml
packages:
  - 'packages/*'
  - 'apps/*'

catalog:
  typescript: ^5.3.0
  '@biomejs/biome': ^1.9.4
```

**Why this exists:**
pnpm needs to know which directories contain workspace packages. The catalog centralizes external dependency versions.

**Why these catalog entries:**
These are shared dev dependencies used across multiple packages. Centralizing versions prevents drift.

### `/typescript/package.json`
```json
{
  "name": "typescript-workspace",
  "private": true,
  "scripts": { /* convenience scripts */ },
  "devDependencies": { /* shared dev tools */ }
}
```

**Why this exists:**
pnpm workspaces require a root package.json. The shared dev dependencies (biome, typescript) are installed here so all packages can use them.

**Why `"private": true`:**
This root package should never be published to npm. The private flag prevents accidental publication.

### Per-package Configuration Files

Each package has its own `pyproject.toml` or `package.json` with project metadata (name, version, dependencies).

**Why these exist:**
Standard package metadata required by the ecosystem. Not optional.

## What We Did NOT Configure

### No `ruff.toml`
Ruff's defaults are sensible. Add this file only when:
- You need to disable specific rules
- You need to configure rule-specific options
- You have package-specific linting requirements

**Don't add it "just in case."**

### No `ty.toml`
ty auto-detects project layout by finding `pyproject.toml` files. Add this file only when:
- ty fails to auto-detect your structure
- You need to exclude specific directories
- You need to configure type checking behavior

**Don't add it "just in case."**

### No `biome.json`
Biome's defaults work well. Add this file only when:
- You need to customize formatting rules
- You need to disable specific linting rules
- You have team-specific code style requirements

**Don't add it "just in case."**

### No `tsconfig.json` (at workspace root)
Many modern tools (Vite, Next.js, Bun) don't require explicit TypeScript configuration. Add per-package `tsconfig.json` only when:
- Using `tsc` directly for compilation
- Tool explicitly requires it
- Need to configure TypeScript compiler options

**Don't add it "just in case."**

### No Test Framework Configuration
No Jest config, no pytest config, no vitest config.

**Why:**
Testing frameworks are out of scope for initial setup. Add them when you start writing tests.

**Don't add them "just in case."**

### No Build Tool Configuration
No webpack config, no rollup config, no esbuild config.

**Why:**
Packages might not need building. Apps will choose their own build tools based on their needs (Vite for SPAs, Next.js for React apps, etc.).

**Don't add them "just in case."**

### No CI/CD Configuration
No `.github/workflows`, no GitLab CI files, no CircleCI config.

**Why:**
These depend on deployment strategy, which isn't defined yet.

**Don't add them "just in case."**

### No Git Hooks
No husky, no pre-commit, no lint-staged.

**Why:**
Hook configuration is developer workflow preference, not repository requirement.

**Don't add them "just in case."**

### No IDE Configuration
No `.vscode/`, no `.idea/`, no editor configs.

**Why:**
Developer tool preferences are personal. Committing IDE configs imposes choices on others.

**Don't add them "just in case."**

## The Configuration Decision Tree

When considering adding a configuration file:

1. **Does the tool work without it?**
   - Yes: Don't add it yet
   - No: Continue

2. **Is the default behavior problematic?**
   - No: Don't add it yet
   - Yes: Continue

3. **Have you encountered the actual problem?**
   - No: Don't add it yet
   - Yes: Add minimal config to solve that specific problem

## Maintenance Cost of Configuration

Every configuration file has cost:
- Must be updated when tools update
- Must be understood by new contributors
- Can conflict with tool defaults that improve over time
- Can become stale and misleading
- Requires documentation explaining choices

**Configuration debt** accumulates like technical debt. Minimize it from the start.

## When Defaults Change

Tool defaults improve over time. When you override defaults, you lock yourself to the old behavior.

**Example:**
If ruff adds a new useful rule by default, you get it automatically - unless you have a `ruff.toml` that explicitly lists rules, in which case you miss the new rule.

Staying close to defaults means benefiting from tool improvements automatically.

## Adding Configuration Later

It's easier to add configuration than remove it:
- Adding: Solve a specific problem you've encountered
- Removing: Figure out what will break and why it was added in the first place

Start minimal. Add purposefully.
