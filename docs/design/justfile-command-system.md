# Justfile Command System

## What It Is

A centralized command system that lets developers run all monorepo operations from the repository root without needing to cd into workspace directories.

## The Problem We Solved

Developers had to remember which directory to run commands in:

```bash
cd py && uv sync              # Python
cd ts && pnpm install         # TypeScript
cd .. && cd py && ruff check  # Switching back and forth
```

This context switching is tedious and error-prone.

## The Solution

Run everything from root using namespace-style commands:

```bash
just py sync                  # Python dependencies
just ts install               # TypeScript dependencies
just lint                     # Everything
```

## Key Decisions

### Why Namespace-Style Commands?

**Decision**: Use `just <workspace> <command>` pattern (e.g., `just py lint`, `just ts dev`)

**Why**: Clean, intuitive interface that scales. Alternative was proliferating recipes (`lint-py`, `format-py`, `check-py`, etc.) which clutters `just --list` output.

**Implementation**: Recipe parameters with case statements:

```just
py command:
    #!/usr/bin/env bash
    cd py
    case "{{command}}" in
        lint) ruff check . ;;
        format) ruff format . ;;
        *)
            echo "Unknown py command: {{command}}"
            exit 1
            ;;
    esac
```

**Trade-off**: Slightly more complex recipe implementation for much cleaner command interface. Worth it.

### Why Split Justfiles by Domain?

**Decision**: Organize justfiles in `/tasks/` directory by workspace:
- `/tasks/py/justfile` - Python commands
- `/tasks/ts/justfile` - TypeScript commands
- `/tasks/repo/justfile` - Cross-cutting commands

**Why**: Scales better than one large justfile. Easy to find relevant commands. Follows existing docs/ organization pattern.

**Alternative considered**: Single root justfile. Would become large and hard to navigate as commands grow.

### Why Just, Not Make or npm Scripts?

**Decision**: Use `just` as the command runner

**Why**:
- Simple syntax (easier than Make)
- Cross-platform (unlike Make's platform quirks)
- Built-in help via `just --list`
- Import system for modular organization
- Not tied to package managers (unlike npm scripts)

**What we're NOT doing**: Build orchestration, task dependencies, caching, or smart rebuilds. Just is a command runner, not a build system. Tools (pnpm, vite) already handle their own caching and watching.

### Why Rename to py/ and ts/?

**Decision**: Rename `python/` → `py/` and `typescript/` → `ts/`

**Why**: Developer ergonomics. Typing `python` and `typescript` repeatedly is tedious. The abbreviations are standard and save significant keystrokes.

**Impact**: One-time update cost for long-term benefit. Workspaces are still Python and TypeScript - the directories are just shorter containers.

## How to Extend

### Adding a New Workspace Command

Edit the appropriate justfile in `/tasks/` and add a case to the existing case statement:

```just
# In tasks/py/justfile
py command:
    cd py
    case "{{command}}" in
        # ... existing cases ...
        test)
            pytest .
            ;;
```

### Adding a Cross-Cutting Command

Edit `/tasks/repo/justfile` to compose workspace commands:

```just
test:
    just py test
    just ts test
```

### Keep It Simple

Don't add:
- Complex conditionals or loops
- Logic that belongs in tools
- Commands that only wrap one other command slightly differently
- Build orchestration (dependency graphs, caching)

Do add:
- Frequently used commands
- Commands that benefit from running at root
- Simple wrappers that call tools directly

## What We Intentionally Left Out

1. **Build orchestration**: No task dependencies, caching, or smart rebuilds
2. **Watch mode coordination**: Tools handle their own watching
3. **Test commands**: Not yet defined in monorepo (add when needed)
4. **CI/CD integration**: Focus is local development
5. **Environment management**: No .env handling
6. **Git hooks**: No pre-commit automation

**Why**: Keep it minimal. Add features incrementally when pain points emerge. Don't build for imagined future needs.

## Implementation Details

### Recipe Pattern

All workspace recipes follow this pattern:

```just
<workspace> command:
    #!/usr/bin/env bash
    set -euo pipefail
    cd <workspace>
    case "{{command}}" in
        action) tool command ;;
        *) echo "Unknown command"; exit 1 ;;
    esac
```

**Why this works**:
- `set -euo pipefail` ensures errors propagate correctly
- `cd` into workspace where tools expect to run
- Case statement maps command names to tool invocations
- Clear error messages for unknown commands
- Exit codes propagate to just (0 for success, non-zero for failure)

### Composite Commands

Repository-wide commands compose workspace commands:

```just
lint:
    just py lint
    just ts lint
```

Simple sequential execution. If one fails, the whole command fails. No parallelization or orchestration needed.

## Constraints

### Tools Must Run in Workspace Root

Python and TypeScript tools expect to run from their workspace root (`py/` or `ts/`), not from repository root. The justfile recipes handle this with `cd` commands.

### No Cross-Workspace Dependencies

Python and TypeScript workspaces are independent. Commands don't coordinate between them. This is by design - the workspaces are separate for a reason.

### Exit Codes Matter

Commands must return correct exit codes. The `set -euo pipefail` ensures bash scripts exit on errors. Tools already do this correctly.

## Examples

### Common Workflows

```bash
# Fresh start
just install          # Install everything
just lint             # Check code quality
just format           # Fix formatting

# Development
just ts dev           # Run all TypeScript dev servers
just ts-pkg dev app   # Run specific app's dev server
just py-pkg run tool  # Run Python package

# Code quality
just py lint          # Check Python code
just ts format        # Format TypeScript code
```

### Error Handling

Unknown commands show helpful messages:

```bash
$ just py unknown
Unknown py command: unknown
Available: sync, lint, format, check
error: Recipe `py` failed with exit code 1
```

This makes commands discoverable through usage.
