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
mkdir -p tasks/python tasks/ts tasks/repo
```

**Verification**:
```bash
ls -la tasks/
# Should show: python/ ts/ repo/
```

**Notes**:
- Create all directories at once
- No files yet, just structure

### Step 1.2: Create Python justfile

**Action**: Create `/tasks/python/justfile`

**Content**:
```just
# Sync Python dependencies
sync-py:
    cd python && uv sync

# Sync specific Python package
sync-py-pkg package:
    cd python && uv sync --package {{package}}

# Run Python package
run-py package:
    cd python && uv run {{package}}

# Lint Python code
lint-py:
    cd python && ruff check .

# Format Python code
format-py:
    cd python && ruff format .

# Type check Python code
check-py:
    cd python && ty check .
```

**Verification**:
```bash
cat tasks/python/justfile
# Should show the content above
```

**Notes**:
- Use exact spacing (4 spaces for recipe body)
- Comments are important for `just --list` output

### Step 1.3: Create TypeScript justfile

**Action**: Create `/tasks/ts/justfile`

**Content**:
```just
# Install TypeScript dependencies
install-ts:
    cd typescript && pnpm install

# Run dev in all TypeScript packages
dev-ts:
    cd typescript && pnpm -r run dev

# Run dev in specific TypeScript package
dev-ts-pkg package:
    cd typescript && pnpm --filter {{package}} run dev

# Lint TypeScript code
lint-ts:
    cd typescript && pnpm -r run lint

# Format TypeScript code
format-ts:
    cd typescript && pnpm -r run format

# Build TypeScript packages
build-ts:
    cd typescript && pnpm -r run build
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
lint: lint-py lint-ts

# Format everything
format: format-py format-ts

# Install/sync all dependencies
install: sync-py install-ts

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

**Important**: Uses `typescript` path in clean command (will update after rename)

### Step 1.5: Create root justfile

**Action**: Create `/justfile`

**Content**:
```just
# Import domain-specific task definitions
import 'tasks/python/justfile'
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
- `@` prefix suppresses command echo
- Default recipe runs when `just` is called with no arguments

### Step 1.6: Test justfiles with current structure

**Action**: Test each command works before making any structural changes

**Test Commands**:
```bash
# From repository root
just --list                    # Shows all commands
just sync-py                   # Syncs Python dependencies
just install-ts                # Installs TypeScript dependencies
just lint-py                   # Lints Python code
just lint-ts                   # Lints TypeScript code
just format-py                 # Formats Python code
just format-ts                 # Formats TypeScript code
just check-py                  # Type checks Python
just build-ts                  # Builds TypeScript packages
```

**Test Composite Commands**:
```bash
just install                   # Should run sync-py and install-ts
just lint                      # Should run lint-py and lint-ts
just format                    # Should run format-py and format-ts
```

**Test Parameterized Commands**:
```bash
# Replace 'example' with actual package name from your repo
just sync-py-pkg example       # Syncs specific Python package
just run-py example            # Runs Python package
just dev-ts-pkg example        # Runs dev for TypeScript package
```

**Verification**:
- All commands complete without errors
- Output matches direct tool invocation
- Exit codes are correct (0 for success)
- Can run any command from any directory in repo

**Troubleshooting**:
- If recipes not found: Check import paths in root justfile
- If cd fails: Verify workspace directories exist
- If tools fail: Verify dependencies installed

## Phase 2: Rename Directory

### Step 2.1: Rename typescript to ts

**Action**: Use git mv to rename directory and preserve history

**Command**:
```bash
git mv typescript ts
```

**Verification**:
```bash
ls -la
# Should show ts/ instead of typescript/
git status
# Should show: renamed: typescript/ -> ts/
```

**Notes**:
- git mv preserves file history
- This is a staged change, not yet committed
- All files inside are moved atomically

### Step 2.2: Update TypeScript justfile paths

**Action**: Edit `/tasks/ts/justfile` to use new `ts` path

**Changes**: Replace all instances of `typescript` with `ts`

**Result**:
```just
# Install TypeScript dependencies
install-ts:
    cd ts && pnpm install

# Run dev in all TypeScript packages
dev-ts:
    cd ts && pnpm -r run dev

# Run dev in specific TypeScript package
dev-ts-pkg package:
    cd ts && pnpm --filter {{package}} run dev

# Lint TypeScript code
lint-ts:
    cd ts && pnpm -r run lint

# Format TypeScript code
format-ts:
    cd ts && pnpm -r run format

# Build TypeScript packages
build-ts:
    cd ts && pnpm -r run build
```

**Verification**:
```bash
just install-ts
# Should work with new path
just lint-ts
# Should work with new path
```

### Step 2.3: Update repository justfile paths

**Action**: Edit `/tasks/repo/justfile` clean command to use new `ts` path

**Changes**: Replace `typescript` with `ts` in clean recipe

**Result**:
```just
# Lint everything
lint: lint-py lint-ts

# Format everything
format: format-py format-ts

# Install/sync all dependencies
install: sync-py install-ts

# Clean generated files
clean:
    rm -rf python/.venv python/**/__pycache__
    rm -rf ts/node_modules ts/**/node_modules ts/**/.next ts/**/.turbo
```

**Verification**:
```bash
just clean
# Should remove generated files from ts/ directory
ls ts/
# node_modules should be gone
```

### Step 2.4: Test all commands with new structure

**Action**: Re-run all test commands from Phase 1 Step 1.6

**Test Commands**:
```bash
just install
just lint
just format
just build-ts
just sync-py
just check-py
```

**Verification**:
- All commands work exactly as before
- No errors about missing directories
- Tools find their files correctly

## Phase 3: Update Documentation

### Step 3.1: Update .gitignore (if needed)

**Action**: Check if .gitignore has typescript-specific entries

**Command**:
```bash
grep -n "typescript" .gitignore
```

**If found**: Replace `typescript` with `ts`

**Verification**:
```bash
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
just dev-ts                    # All packages
just dev-ts-pkg example        # Specific package
just build-ts                  # Build all packages

# Python
just run-py example            # Run Python package
just sync-py                   # Sync all dependencies
just sync-py-pkg example       # Sync specific package
```

### Code Quality

```bash
just lint                      # Lint everything
just format                    # Format everything
just check-py                  # Type check Python
```

### Explore Commands

```bash
just --list                    # See all available commands
just help                      # Same as --list
```

### Direct Tool Usage

You can still use tools directly if needed:

```bash
cd python && uv sync
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
- `/tasks/python/justfile` - Python workspace commands
- `/tasks/ts/justfile` - TypeScript workspace commands
- `/tasks/repo/justfile` - Cross-cutting repository commands

### Design Principles

1. **Run from root**: Never need to cd into workspace directories
2. **Simple wrappers**: Just recipes wrap existing tool commands, no complex logic
3. **Domain separation**: Commands grouped by workspace for clarity
4. **Composition**: Combined commands (like `lint`) depend on workspace-specific commands

### Command Naming

- Workspace-specific: `<verb>-<workspace>` (e.g., `lint-py`, `dev-ts`)
- Package-specific: `<verb>-<workspace>-pkg` (e.g., `sync-py-pkg`, `dev-ts-pkg`)
- Repository-wide: `<verb>` (e.g., `lint`, `format`, `install`, `clean`)

### Adding Commands

To add new commands:

1. Identify the domain (python, ts, or repo)
2. Add recipe to appropriate justfile in `/tasks/`
3. Follow the `cd <workspace> && <command>` pattern
4. Keep it simple - just wrap the tool, don't add logic
5. Test from repository root
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

**Trade-off**: Slightly longer command names (`just lint-py` vs `cd python && ruff check`) for significantly better ergonomics. Worth it.

### Why Rename typescript to ts?

**Problem**: `typescript` is long to type and read in commands.

**Solution**: Rename to `ts`, the common abbreviation.

**Trade-off**: One-time update cost for long-term ergonomic benefit. The workspace is still TypeScript, the directory is just shorter.

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

**Changes**: Replace `typescript/` with `ts/` in structure diagrams

**Example**:
```markdown
## Directory Structure

```
/
├── python/              # Python workspace
│   ├── packages/       # Shared Python packages
│   └── apps/           # Python applications
├── ts/                 # TypeScript workspace
│   ├── packages/       # Shared TypeScript packages
│   └── apps/           # TypeScript applications
├── tasks/              # Just task definitions
│   ├── python/        # Python commands
│   ├── ts/            # TypeScript commands
│   └── repo/          # Repository commands
├── docs/               # Documentation
└── justfile            # Command entry point
```
```

**Verification**: Ensure all path references use `ts` not `typescript`

### Step 3.6: Update workspace-specific sections

**Action**: Find Python Workspace and TypeScript Workspace sections, add just references

**Python Workspace Section**:

Add after existing introduction:
```markdown
### Using Just Commands (Recommended)

```bash
just sync-py                   # Sync all dependencies
just sync-py-pkg example       # Sync specific package
just run-py example            # Run package
just lint-py                   # Lint code
just format-py                 # Format code
just check-py                  # Type check
```

### Direct Tool Usage

You can still use uv directly:

```bash
cd python
uv sync
uv run example
```
```

**TypeScript Workspace Section**:

Add after existing introduction:
```markdown
### Using Just Commands (Recommended)

```bash
just install-ts                # Install dependencies
just dev-ts                    # Run dev in all packages
just dev-ts-pkg example        # Run dev in specific package
just lint-ts                   # Lint code
just format-ts                 # Format code
just build-ts                  # Build all packages
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

### Step 3.7: Search for remaining typescript/ references

**Action**: Find and update any remaining references to old path

**Command**:
```bash
grep -r "typescript/" docs/
grep -r "typescript/" README.md
```

**Action**: Update each found reference to use `ts/`

**Verification**:
```bash
# Should find no results or only in historical context
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
rm -rf python/.venv ts/node_modules
```

**Verification**:
```bash
ls python/
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
ls python/.venv
# Should exist
ls ts/node_modules
# Should exist
```

### Step 4.3: Python commands test

**Action**: Test all Python commands

**Commands**:
```bash
just sync-py                   # Should sync dependencies
just lint-py                   # Should lint (may show issues)
just format-py                 # Should format code
just check-py                  # Should type check
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
just install-ts                # Should install (already done)
just lint-ts                   # Should lint
just format-ts                 # Should format
just build-ts                  # Should build packages
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
just sync-py-pkg <python-package-name>
just run-py <python-package-name>
just dev-ts-pkg <typescript-package-name>
```

**Verification**:
- Package-specific operations run
- Only specified package affected
- No errors about missing packages

### Step 4.7: Documentation test

**Action**: Review README.md for accuracy

**Checklist**:
- [ ] Quick Start section exists and is clear
- [ ] Command System section explains organization
- [ ] Design Decisions section explains choices
- [ ] Directory Structure uses `ts/` not `typescript/`
- [ ] Python Workspace section references just commands
- [ ] TypeScript Workspace section references just commands
- [ ] No broken references to `typescript/` directory
- [ ] Examples are concrete and testable

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

**Expected Output Format**:
```
Available recipes:
    build-ts             # Build TypeScript packages
    check-py            # Type check Python code
    clean               # Clean generated files
    default             # Default recipe: list available commands
    dev-ts              # Run dev in all TypeScript packages
    ...
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

- [ ] Directory renamed: `typescript/` → `ts/`
- [ ] Justfiles created: `/justfile`, `/tasks/python/justfile`, `/tasks/ts/justfile`, `/tasks/repo/justfile`
- [ ] All justfiles use `ts` path (not `typescript`)
- [ ] `just --list` shows all commands with descriptions
- [ ] `just install` installs both workspaces
- [ ] `just lint` lints both workspaces
- [ ] `just format` formats both workspaces
- [ ] `just clean` removes generated files
- [ ] Python commands work: `sync-py`, `run-py`, `lint-py`, `format-py`, `check-py`
- [ ] TypeScript commands work: `install-ts`, `dev-ts`, `lint-ts`, `format-ts`, `build-ts`
- [ ] Parameterized commands work: `sync-py-pkg`, `run-py`, `dev-ts-pkg`
- [ ] README.md has Quick Start section
- [ ] README.md has Command System section
- [ ] README.md has Design Decisions section
- [ ] README.md Directory Structure uses `ts/`
- [ ] README.md workspace sections reference just commands
- [ ] No remaining `typescript/` references (except historical)
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
