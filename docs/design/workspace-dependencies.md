# Workspace Dependencies

## The Pattern

Internal dependencies use special syntax to signal "resolve from workspace, not from registry":

**Python:**
```toml
[project]
dependencies = ["other-package"]

[tool.uv.sources]
other-package = { workspace = true }
```

**TypeScript:**
```json
{
  "dependencies": {
    "@workspace/other-package": "workspace:*"
  }
}
```

## Why This Syntax

### Python: `{ workspace = true }`

Without this, uv would try to fetch `other-package` from PyPI. The `[tool.uv.sources]` section tells uv: "resolve this dependency from the workspace instead of the registry."

This is explicit and intentional. There's no implicit workspace resolution in uv.

**Why this matters:**
- Prevents accidental shadowing (workspace package won't be masked by PyPI package with same name)
- Makes dependencies obvious (you can see which are internal vs external)
- Works with private packages (don't need to publish to use)

### TypeScript: `workspace:*`

The `workspace:*` protocol tells pnpm: "resolve this from the workspace at any version." The `*` means "whatever version is currently in the workspace."

**Why this matters:**
- Version synchronization happens automatically
- No need to update version numbers during development
- Published packages get rewritten to actual version numbers

## Why NOT Use Symlinks or Path References

You might think: "Why not just use file paths?"

```toml
# DON'T DO THIS
[tool.uv.sources]
other-package = { path = "../other-package" }
```

```json
// DON'T DO THIS
{
  "dependencies": {
    "other-package": "file:../other-package"
  }
}
```

**Problems with paths:**
- Fragile - breaks if you move packages
- Tool-specific resolution behavior
- Harder to switch between workspace and published versions
- Doesn't work well with lockfiles

Workspace protocols are designed specifically for monorepo use cases. Use them.

## Dependency Scoping in TypeScript

TypeScript packages use the `@workspace/` scope:

```json
{
  "name": "@workspace/example"
}
```

**Why a scope:**
- Makes workspace packages visually distinct from external packages
- Prevents naming conflicts with npm packages
- Groups related packages together in tooling
- Can be published to npm under organization scope if needed

**Why `@workspace` specifically:**
- Clearly signals "this is internal to this workspace"
- Short and unambiguous
- Not tied to any specific organization or product

You can rename this scope if the project has a specific organization name (like `@dross/example`), but `@workspace` works as a generic placeholder.

## Version Management

### Python
Each package declares its own version in `pyproject.toml`. These versions are independent. The workspace doesn't enforce synchronization.

**Why:**
- Packages evolve at different rates
- Semantic versioning should reflect actual changes
- No automated versioning tool is in scope yet

### TypeScript
Same principle - each package has independent versions. The catalog in `pnpm-workspace.yaml` controls external dependency versions, not internal package versions.

**When versions matter:**
If you want synchronized versions across all packages, add a versioning tool later (like changesets). Don't start with one.

## Circular Dependencies

**Don't create them.**

If package A depends on package B, and package B depends on package A, you have a circular dependency. Most tools will error or behave unpredictably.

**How to avoid:**
- Extract shared code to a third package that both depend on
- Rethink the dependency direction
- Consider if these should actually be one package

## External Dependencies

Use package managers normally:

**Python:**
```toml
[project]
dependencies = [
    "requests>=2.31.0",
]
```

**TypeScript (using catalog):**
```json
{
  "dependencies": {
    "react": "catalog:"
  }
}
```

The catalog in `pnpm-workspace.yaml` centralizes versions for TypeScript dependencies. This ensures consistency across packages without manual synchronization.

## When to Split vs Merge Packages

**Split when:**
- Clear separation of concerns
- Independent release cycles needed
- Different teams own different parts
- One package can be useful without the other

**Merge when:**
- Always change together
- No clear boundary between them
- Splitting creates artificial coupling
- Dependency management overhead exceeds value

Start with fewer packages. Split only when proven necessary.
