# Implementation Plan: Monorepo Iteration

## Overview

This document provides step-by-step instructions to implement the monorepo iteration. Each step is independent and testable. The order matters for safety.

## Prerequisites

- just installed (`brew install just` on macOS)
- Repository at clean state (git status clean)
- Both workspaces functional (can run existing commands)

## Phase 1: Create Justfiles (Non-Breaking)

### Step 1.1: Create tasks directory structure

**Action**: Create the tasks directory and subdirectories

**Command**:
```bash
mkdir -p tasks/py tasks/ts tasks/repo
```

**Verification**:
```bash
ls -la tasks/
# Should show: py/ ts/ repo/
```

**Notes**:
- Create all directories at once
- Uses `py/` and `ts/` to match the workspace naming we'll use
- No files yet, just structure

### Step 1.2: Create Python justfile

**Action**: Create `/tasks/py/justfile`

**Content**:
```just
# Python workspace commands
py command:
    #!/usr/bin/env bash
    set -euo pipefail
    cd python
    case "{{command}}" in
        sync)
            uv sync
            ;;
        lint)
            ruff check .
            ;;
        format)
            ruff format .
            ;;
        check)
            ty check .
            ;;
        *)
            echo "Unknown py command: {{command}}"
            echo "Available: sync, lint, format, check"
            exit 1
            ;;
    esac

# Python package-specific commands
py-pkg command package:
    #!/usr/bin/env bash
    set -euo pipefail
    cd python
    case "{{command}}" in
        sync)
            uv sync --package {{package}}
            ;;
        run)
            uv run {{package}}
            ;;
        *)
            echo "Unknown py-pkg command: {{command}}"
            echo "Available: sync, run"
            exit 1
            ;;
    esac
```

**Verification**:
```bash
cat tasks/py/justfile
# Should show the content above
```

**Notes**:
- Uses namespace-style recipes with parameters
- Uses `python` directory path (will update after rename)
- Bash shebang allows multi-line scripts
- `set -euo pipefail` ensures errors propagate
- Case statement maps commands to tools

### Step 1.3: Create TypeScript justfile

**Action**: Create `/tasks/ts/justfile`

**Content**:
```just
# TypeScript workspace commands
ts command:
    #!/usr/bin/env bash
    set -euo pipefail
    cd typescript
    case "{{command}}" in
        install)
            pnpm install
            ;;
        dev)
            pnpm -r run dev
            ;;
        lint)
            pnpm -r run lint
            ;;
        format)
            pnpm -r run format
            ;;
        build)
            pnpm -r run build
            ;;
        *)
            echo "Unknown ts command: {{command}}"
            echo "Available: install, dev, lint, format, build"
            exit 1
            ;;
    esac

# TypeScript package-specific commands
ts-pkg command package:
    #!/usr/bin/env bash
    set -euo pipefail
    cd typescript
    case "{{command}}" in
        dev)
            pnpm --filter {{package}} run dev
            ;;
        build)
            pnpm --filter {{package}} run build
            ;;
        *)
            echo "Unknown ts-pkg command: {{command}}"
            echo "Available: dev, build"
            exit 1
            ;;
    esac
```

**Verification**:
```bash
cat tasks/ts/justfile
# Should show the content above
```

**Important**: Uses `typescript` path for now (will update after rename)

### Step 1.4: Create repository justfile

**Action**: Create `/tasks/repo/justfile`

**Content**:
```just
# Lint everything
lint:
    just py lint
    just ts lint

# Format everything
format:
    just py format
    just ts format

# Install/sync all dependencies
install:
    just py sync
    just ts install

# Clean generated files
clean:
    rm -rf python/.venv python/**/__pycache__
    rm -rf typescript/node_modules typescript/**/node_modules typescript/**/.next typescript/**/.turbo
```

**Verification**:
```bash
cat tasks/repo/justfile
# Should show the content above
```

**Important**: Uses `python` and `typescript` paths in clean command (will update after rename)

### Step 1.5: Create root justfile

**Action**: Create `/justfile`

**Content**:
```just
# Import domain-specific task definitions
import 'tasks/py/justfile'
import 'tasks/ts/justfile'
import 'tasks/repo/justfile'

# Default recipe: list available commands
default:
    @just --list

# Show available commands
help:
    @just --list
```

**Verification**:
```bash
cat justfile
# Should show the content above
just --list
# Should show all imported recipes
```

**Notes**:
- Import paths are relative to root justfile
- Imports from `tasks/py/` and `tasks/ts/` (matching directory structure)
- `@` prefix suppresses command echo
- Default recipe runs when `just` is called with no arguments

### Step 1.6: Test justfiles with current structure

**Action**: Test each command works before making any structural changes

**Test Commands**:
```bash
# From repository root
just --list                    # Shows all commands

# Test Python commands
just py sync                   # Syncs Python dependencies
just py lint                   # Lints Python code
just py format                 # Formats Python code
just py check                  # Type checks Python

# Test TypeScript commands
just ts install                # Installs TypeScript dependencies
just ts dev                    # Runs dev in all packages (will start dev servers)
just ts lint                   # Lints TypeScript code
just ts format                 # Formats TypeScript code
just ts build                  # Builds TypeScript packages
```

**Test Composite Commands**:
```bash
just install                   # Should run py sync and ts install
just lint                      # Should run py lint and ts lint
just format                    # Should run py format and ts format
```

**Test Parameterized Commands**:
```bash
# Replace 'example' with actual package name from your repo
just py-pkg sync example       # Syncs specific Python package
just py-pkg run example        # Runs Python package
just ts-pkg dev example        # Runs dev for TypeScript package
just ts-pkg build example      # Builds specific TypeScript package
```

**Test Error Handling**:
```bash
just py unknown                # Should show error: "Unknown py command: unknown"
just ts-pkg invalid pkg        # Should show error: "Unknown ts-pkg command: invalid"
```

**Verification**:
- All commands complete without errors
- Output matches direct tool invocation
- Exit codes are correct (0 for success)
- Can run any command from any directory in repo
- Unknown commands show helpful error messages

**Troubleshooting**:
- If recipes not found: Check import paths in root justfile
- If cd fails: Verify workspace directories exist (python/ and typescript/)
- If tools fail: Verify dependencies installed
- If bash script fails: Ensure bash is available and executable

## Phase 2: Rename Directories

### Step 2.1: Rename both workspace directories

**Action**: Use git mv to rename directories and preserve history

**Commands**:
```bash
git mv python py
git mv typescript ts
```

**Verification**:
```bash
ls -la
# Should show py/ and ts/ instead of python/ and typescript/
git status
# Should show:
# renamed: python/ -> py/
# renamed: typescript/ -> ts/
```

**Notes**:
- git mv preserves file history
- These are staged changes, not yet committed
- All files inside are moved atomically
- Both renames can be done in one step

### Step 2.2: Update Python justfile paths

**Action**: Edit `/tasks/py/justfile` to use new `py` path

**Changes**: Replace all instances of `python` with `py` in the `cd` commands

**Result**:
```just
# Python workspace commands
py command:
    #!/usr/bin/env bash
    set -euo pipefail
    cd py
    case "{{command}}" in
        sync)
            uv sync
            ;;
        lint)
            ruff check .
            ;;
        format)
            ruff format .
            ;;
        check)
            ty check .
            ;;
        *)
            echo "Unknown py command: {{command}}"
            echo "Available: sync, lint, format, check"
            exit 1
            ;;
    esac

# Python package-specific commands
py-pkg command package:
    #!/usr/bin/env bash
    set -euo pipefail
    cd py
    case "{{command}}" in
        sync)
            uv sync --package {{package}}
            ;;
        run)
            uv run {{package}}
            ;;
        *)
            echo "Unknown py-pkg command: {{command}}"
            echo "Available: sync, run"
            exit 1
            ;;
    esac
```

**Verification**:
```bash
just py sync
# Should work with new path
just py lint
# Should work with new path
```

### Step 2.3: Update TypeScript justfile paths

**Action**: Edit `/tasks/ts/justfile` to use new `ts` path

**Changes**: Replace all instances of `typescript` with `ts` in the `cd` commands

**Result**:
```just
# TypeScript workspace commands
ts command:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ts
    case "{{command}}" in
        install)
            pnpm install
            ;;
        dev)
            pnpm -r run dev
            ;;
        lint)
            pnpm -r run lint
            ;;
        format)
            pnpm -r run format
            ;;
        build)
            pnpm -r run build
            ;;
        *)
            echo "Unknown ts command: {{command}}"
            echo "Available: install, dev, lint, format, build"
            exit 1
            ;;
    esac

# TypeScript package-specific commands
ts-pkg command package:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ts
    case "{{command}}" in
        dev)
            pnpm --filter {{package}} run dev
            ;;
        build)
            pnpm --filter {{package}} run build
            ;;
        *)
            echo "Unknown ts-pkg command: {{command}}"
            echo "Available: dev, build"
            exit 1
            ;;
    esac
```

**Verification**:
```bash
just ts install
# Should work with new path
just ts lint
# Should work with new path
```

### Step 2.4: Update repository justfile paths

**Action**: Edit `/tasks/repo/justfile` clean command to use new `py` and `ts` paths

**Changes**: Replace `python` with `py` and `typescript` with `ts` in clean recipe

**Result**:
```just
# Lint everything
lint:
    just py lint
    just ts lint

# Format everything
format:
    just py format
    just ts format

# Install/sync all dependencies
install:
    just py sync
    just ts install

# Clean generated files
clean:
    rm -rf py/.venv py/**/__pycache__
    rm -rf ts/node_modules ts/**/node_modules ts/**/.next ts/**/.turbo
```

**Verification**:
```bash
just clean
# Should remove generated files from both py/ and ts/ directories
ls py/
# .venv should be gone
ls ts/
# node_modules should be gone
```

### Step 2.5: Test all commands with new structure

**Action**: Re-run all test commands from Phase 1 Step 1.6

**Test Commands**:
```bash
just install
just lint
just format
just py sync
just py check
just ts build
```

**Verification**:
- All commands work exactly as before
- No errors about missing directories
- Tools find their files correctly in py/ and ts/

## Phase 3: Update Documentation

### Step 3.1: Update .gitignore (if needed)

**Action**: Check if .gitignore has python or typescript-specific entries

**Commands**:
```bash
grep -n "python" .gitignore
grep -n "typescript" .gitignore
```

**If found**: Replace `python` with `py` and `typescript` with `ts`

**Verification**:
```bash
grep -n "py" .gitignore
grep -n "ts" .gitignore
# Should show updated entries
```

**Notes**: May not be needed if .gitignore uses workspace-relative paths

### Step 3.2: Add Quick Start section to README.md

**Action**: Add new section after the overview/introduction

**Location**: Near top of README.md, before detailed workspace sections

**Content to Add**:
```markdown
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
```

**Verification**: Read the section to ensure it makes sense

### Step 3.3: Add Command System section to README.md

**Action**: Add new section explaining justfile organization

**Location**: After Quick Start, before or after existing architecture sections

**Content to Add**:
```markdown
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
```

**Verification**: Read the section to ensure it makes sense

### Step 3.4: Add Design Decisions section to README.md

**Action**: Document why we made these choices

**Location**: Near end of README.md, before or in existing design/philosophy sections

**Content to Add**:
```markdown
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
```

**Verification**: Read the section to ensure it makes sense

### Step 3.5: Update Directory Structure section

**Action**: Find existing directory structure documentation and update paths

**Changes**: Replace `python/` with `py/` and `typescript/` with `ts/` in structure diagrams

**Example**:
```markdown
## Directory Structure

```
/
├── py/                 # Python workspace
│   ├── packages/       # Shared Python packages
│   └── apps/           # Python applications
├── ts/                 # TypeScript workspace
│   ├── packages/       # Shared TypeScript packages
│   └── apps/           # TypeScript applications
├── tasks/              # Just task definitions
│   ├── py/            # Python commands
│   ├── ts/            # TypeScript commands
│   └── repo/          # Repository commands
├── docs/               # Documentation
└── justfile            # Command entry point
```
```

**Verification**: Ensure all path references use `py` and `ts` not `python` and `typescript`

### Step 3.6: Update workspace-specific sections

**Action**: Find Python Workspace and TypeScript Workspace sections, add just references

**Python Workspace Section**:

Add after existing introduction:
```markdown
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
uv sync
uv run example
```
```

**TypeScript Workspace Section**:

Add after existing introduction:
```markdown
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
pnpm install
pnpm -r run dev
```
```

**Verification**: Ensure both approaches are documented clearly

### Step 3.7: Search for remaining python/ and typescript/ references

**Action**: Find and update any remaining references to old paths

**Commands**:
```bash
grep -r "python/" docs/
grep -r "python/" README.md
grep -r "typescript/" docs/
grep -r "typescript/" README.md
```

**Action**: Update each found reference to use `py/` and `ts/`

**Verification**:
```bash
# Should find no results or only in historical context
grep -r "python/" docs/
grep -r "python/" README.md
grep -r "typescript/" docs/
grep -r "typescript/" README.md
```

**Notes**: Some historical references may be okay in commit messages or changelogs

## Phase 4: Validation

### Step 4.1: Clean state test

**Action**: Start from completely clean state

**Commands**:
```bash
just clean
rm -rf py/.venv ts/node_modules
```

**Verification**:
```bash
ls py/
# Should not show .venv
ls ts/
# Should not show node_modules
```

### Step 4.2: Full installation test

**Action**: Install everything from scratch

**Command**:
```bash
just install
```

**Verification**:
- Python .venv created
- TypeScript node_modules created
- No errors during installation
- Exit code is 0

**Success Criteria**:
```bash
ls py/.venv
# Should exist
ls ts/node_modules
# Should exist
```

### Step 4.3: Python commands test

**Action**: Test all Python commands

**Commands**:
```bash
just py sync                   # Should sync dependencies
just py lint                   # Should lint (may show issues)
just py format                 # Should format code
just py check                  # Should type check
```

**Verification**:
- Commands run without errors
- Output shows expected results
- Exit codes correct (0 or tool-specific)

**Note**: Lint may show issues, that's okay. We're testing the command works.

### Step 4.4: TypeScript commands test

**Action**: Test all TypeScript commands

**Commands**:
```bash
just ts install                # Should install (already done)
just ts lint                   # Should lint
just ts format                 # Should format
just ts build                  # Should build packages
```

**Verification**:
- Commands run without errors
- Build artifacts created
- Exit codes correct

### Step 4.5: Composite commands test

**Action**: Test repository-wide commands

**Commands**:
```bash
just lint                      # Should lint both workspaces
just format                    # Should format both workspaces
```

**Verification**:
- Both Python and TypeScript operations run
- See output from both workspaces
- Exit code reflects success/failure of all operations

### Step 4.6: Parameterized commands test

**Action**: Test commands that take parameters

**Commands** (replace 'example' with actual package names):
```bash
just py-pkg sync <python-package-name>
just py-pkg run <python-package-name>
just ts-pkg dev <typescript-package-name>
just ts-pkg build <typescript-package-name>
```

**Verification**:
- Package-specific operations run
- Only specified package affected
- No errors about missing packages

**Test Error Handling**:
```bash
just py unknown                # Should show "Unknown py command: unknown"
just ts invalid                # Should show "Unknown ts command: invalid"
just py-pkg badcmd pkg         # Should show "Unknown py-pkg command: badcmd"
```

### Step 4.7: Documentation test

**Action**: Review README.md for accuracy

**Checklist**:
- [ ] Quick Start section exists and is clear
- [ ] Command System section explains organization
- [ ] Design Decisions section explains choices (including namespace-style)
- [ ] Directory Structure uses `py/` and `ts/` not `python/` and `typescript/`
- [ ] Python Workspace section references namespace-style just commands
- [ ] TypeScript Workspace section references namespace-style just commands
- [ ] No broken references to `python/` or `typescript/` directories
- [ ] Examples are concrete and testable
- [ ] Namespace-style commands are documented (`just py lint`, `just ts dev`)

**Method**: Read through README.md as if you're a new developer

### Step 4.8: Command discovery test

**Action**: Test that commands are discoverable

**Command**:
```bash
just --list
```

**Verification**:
- All commands show with descriptions
- Commands grouped logically
- Descriptions match comment lines from justfiles
- Namespace recipes appear (py, ts, py-pkg, ts-pkg)

**Expected Output Format**:
```
Available recipes:
    clean               # Clean generated files
    default             # Default recipe: list available commands
    format              # Format everything
    help                # Show available commands
    install             # Install/sync all dependencies
    lint                # Lint everything
    py command          # Python workspace commands
    py-pkg command package # Python package-specific commands
    ts command          # TypeScript workspace commands
    ts-pkg command package # TypeScript package-specific commands
```

### Step 4.9: Cross-platform test (if applicable)

**Action**: If possible, test on both macOS and Linux

**Commands**: Run same test suite from Steps 4.2-4.6

**Verification**:
- All commands work on both platforms
- No platform-specific issues
- Paths resolve correctly

**Note**: Windows testing is out of scope

## Phase 5: Finalization

### Step 5.1: Review changes

**Action**: Review all modified and new files

**Command**:
```bash
git status
git diff
```

**Checklist**:
- [ ] New justfiles created in `/tasks/`
- [ ] Root justfile created
- [ ] Directory renamed (typescript → ts)
- [ ] README.md updated with new sections
- [ ] No unintended changes
- [ ] .gitignore updated if needed

### Step 5.2: Commit changes

**Action**: Create clean commit history

**Recommended Commit Structure**:

```bash
# Option 1: Single commit (simple, recommended)
git add .
git commit -m "feat: add justfile command system and rename typescript to ts

- Add justfile-based command system for running all commands from root
- Organize commands by domain: python, ts, repo
- Rename typescript/ to ts/ for brevity
- Update README.md with Quick Start and Design Decisions sections
- All commands tested and working

Commands now run from root:
- just install (install all dependencies)
- just lint (lint all workspaces)
- just dev-ts (run TypeScript dev servers)
- just run-py <pkg> (run Python packages)
- See 'just --list' for all commands"

# Option 2: Multiple commits (for easier review)
# Commit 1: Add justfiles
git add justfile tasks/
git commit -m "feat: add justfile-based command system

- Add justfiles organized by domain (python, ts, repo)
- Import from root justfile
- All existing commands wrapped in just recipes
- Commands tested with current structure"

# Commit 2: Rename directory
git add .
git commit -m "refactor: rename typescript/ to ts/

- Rename typescript/ directory to ts/ for brevity
- Update justfile paths to use new directory name
- Tested all commands work with new structure"

# Commit 3: Update documentation
git add README.md docs/ .gitignore
git commit -m "docs: update README for justfile commands and ts/ rename

- Add Quick Start section showing just commands
- Add Command System section explaining organization
- Add Design Decisions section documenting choices
- Update all typescript/ references to ts/
- Update workspace sections with just command examples"
```

**Choose based on**:
- Single commit: Simple, atomic change
- Multiple commits: Easier to review, clearer history

### Step 5.3: Final verification

**Action**: After committing, test one more time from clean state

**Commands**:
```bash
just clean
just install
just lint
just --list
```

**Verification**:
- Everything still works after commit
- No uncommitted changes needed
- Documentation accurate

### Step 5.4: Push changes (if applicable)

**Action**: Push to remote repository

**Command**:
```bash
git push origin main
# or your branch name
```

**Notes**:
- Only push if you have permission
- Consider creating PR if working in shared repo
- Include test results in PR description

## Troubleshooting Guide

### Just not found

**Symptom**: `just: command not found`

**Solution**: Install just
```bash
# macOS
brew install just

# Linux
cargo install just
```

### Recipes not found

**Symptom**: `error: Justfile does not contain recipe 'lint-py'`

**Solution**: Check import paths in root justfile
```bash
cat justfile
# Verify imports are correct
just --list
# Should show all recipes
```

### CD fails

**Symptom**: `cd: no such file or directory: python`

**Solution**: Verify you're running from repository root
```bash
pwd
# Should show repo root path
ls
# Should show python/, ts/, justfile
```

### Wrong directory name

**Symptom**: `cd: no such file or directory: typescript`

**Solution**: Update justfile to use `ts` instead of `typescript`
```bash
grep -r "typescript" tasks/
# Find and replace with ts
```

### Tool not found

**Symptom**: `uv: command not found` or `pnpm: command not found`

**Solution**: Install required tools
```bash
# uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# pnpm
npm install -g pnpm
```

### Permissions error

**Symptom**: `Permission denied` when running commands

**Solution**: Check file permissions
```bash
ls -la justfile tasks/
# Should be readable
chmod +x justfile
# If needed
```

### Git mv issues

**Symptom**: Git doesn't recognize rename

**Solution**: Use git mv, not mv
```bash
# Wrong
mv typescript ts

# Right
git mv typescript ts
```

## Success Checklist

Use this to verify implementation is complete:

- [ ] Directories renamed: `python/` → `py/` and `typescript/` → `ts/`
- [ ] Justfiles created: `/justfile`, `/tasks/py/justfile`, `/tasks/ts/justfile`, `/tasks/repo/justfile`
- [ ] All justfiles use `py` and `ts` paths (not `python` and `typescript`)
- [ ] Justfiles use namespace-style recipes with case statements
- [ ] `just --list` shows all commands with descriptions
- [ ] `just install` installs both workspaces
- [ ] `just lint` lints both workspaces
- [ ] `just format` formats both workspaces
- [ ] `just clean` removes generated files
- [ ] Python commands work: `py sync`, `py lint`, `py format`, `py check`
- [ ] TypeScript commands work: `ts install`, `ts dev`, `ts lint`, `ts format`, `ts build`
- [ ] Parameterized commands work: `py-pkg sync`, `py-pkg run`, `ts-pkg dev`, `ts-pkg build`
- [ ] Error handling works: unknown commands show helpful messages
- [ ] README.md has Quick Start section with namespace-style commands
- [ ] README.md has Command System section explaining namespace approach
- [ ] README.md has Design Decisions section (including namespace rationale)
- [ ] README.md Directory Structure uses `py/` and `ts/`
- [ ] README.md workspace sections reference namespace-style just commands
- [ ] No remaining `python/` or `typescript/` references (except historical)
- [ ] .gitignore updated (if needed)
- [ ] All changes committed
- [ ] Final test from clean state passes

## Estimated Time

- **Phase 1** (Create Justfiles): 30-45 minutes
- **Phase 2** (Rename Directory): 10-15 minutes
- **Phase 3** (Update Documentation): 30-45 minutes
- **Phase 4** (Validation): 20-30 minutes
- **Phase 5** (Finalization): 10-15 minutes

**Total**: 1.5-2.5 hours depending on familiarity and repo size

## Notes

- Work methodically through each phase
- Test after each major step
- Don't skip validation steps
- Keep commits atomic and well-described
- If something breaks, git revert and retry
- When in doubt, test more

## Support

If issues arise:
1. Check troubleshooting guide above
2. Review spec.md for design rationale
3. Review requirements.md for original goals
4. Test commands individually to isolate issues
5. Use `just --evaluate` to debug recipe expansion
