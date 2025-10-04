# Monorepo Architecture

## The Central Decision

This monorepo uses **two independent workspace roots** (`/python` and `/typescript`) instead of a unified structure with a shared root.

## Why Separate Roots

### The Problem
Python and TypeScript tooling have conflicting expectations:
- Both want a `packages/` directory at their workspace root
- Both want configuration files in predictable locations
- Both have different lockfile formats and dependency resolution strategies
- Neither was designed to coexist with the other in the same workspace

### The Trade-off
We chose explicit separation over attempted unification:

**What we gained:**
- Zero configuration conflicts between ecosystems
- Tool defaults work without overrides
- Clear ownership of every file
- Independent tool updates without cross-ecosystem impact
- Simpler mental model (work in one workspace at a time)

**What we accepted:**
- Cannot share dependencies across Python and TypeScript (acceptable - this should be rare)
- Must run commands from two different directories (acceptable - most development happens in one ecosystem at a time)
- Slight duplication in documentation (acceptable - each ecosystem has its own README section)

### Why This Matters for Maintainers

When you see `/python/packages/foo`, you know immediately:
- It's a Python package managed by uv
- Its dependencies are in `/python/uv.lock`
- Python tooling (ruff, ty) will find it automatically

When you see `/typescript/packages/bar`, you know immediately:
- It's a TypeScript package managed by pnpm
- Its dependencies are in `/typescript/pnpm-lock.yaml`
- TypeScript tooling (biome, tsc) will find it automatically

No ambiguity. No tool configuration needed. No mental overhead.

## What We Did NOT Do

### Rejected: Unified Root with `/packages`
```
/ (rejected structure)
├── packages/
│   ├── python-foo/
│   └── typescript-bar/
└── pyproject.toml + package.json at root
```

**Why rejected:**
- Requires extensive tool configuration overrides
- Creates ambiguous file ownership
- Risk of naming conflicts between ecosystems
- Tools fight over workspace root
- Every tool update risks breaking the other ecosystem

### Rejected: Language-Specific Subdirectories Under Unified `/packages`
```
/ (rejected structure)
├── packages/
│   ├── py/
│   │   └── foo/
│   └── ts/
│       └── bar/
└── pyproject.toml + package.json at root
```

**Why rejected:**
- Tools don't recognize `packages/py/*` as valid workspace members
- Requires complex glob patterns in workspace configs
- Breaks tool assumptions about package location
- Provides no benefit over separate roots

### Rejected: Monolithic Root with Everything Mixed
```
/ (rejected structure)
├── python_package_foo/
├── typescript_package_bar/
├── pyproject.toml
├── package.json
└── pnpm-workspace.yaml
```

**Why rejected:**
- Chaos - no clear organization principle
- Tools can't distinguish between package types
- Impossible to scope operations to one ecosystem
- Doesn't scale as packages grow

## Key Architectural Constraints

These constraints shaped the design:

1. **Tool defaults must work** - Overriding tool behavior creates maintenance burden
2. **Clear ownership** - Every file should have an obvious owner
3. **Independent evolution** - Python changes shouldn't affect TypeScript and vice versa
4. **Minimal configuration** - Less config means less to maintain and less to break

## Integration Points

Python and TypeScript code can interact through:
- HTTP APIs (if one workspace runs a server, the other can call it)
- CLI tools (if Python package exposes a CLI, TypeScript can invoke it)
- Build artifacts (if one builds output, the other can consume it)

These integration patterns work regardless of monorepo structure and don't require special workspace configuration.

## When to Reconsider

This architecture should be reconsidered if:
- A tool emerges that natively supports multi-language workspaces with zero configuration
- The project needs to share significant code between Python and TypeScript (consider using a different IPC mechanism)
- One ecosystem becomes dominant and the other is rarely used (consider separating repositories)

Until then, two roots provide the simplest working solution.
