# Documentation Index

## Design Documentation
```
docs/design/
├── monorepo-architecture.md          Why separate Python/TypeScript roots, trade-offs made
├── workspace-dependencies.md          How and why internal dependencies work the way they do
├── minimal-configuration.md           Philosophy of avoiding configuration files
└── justfile-command-system.md         Why namespace-style commands from root, design decisions
```

## Principles
```
docs/principles/
├── full.md                           Complete "Less but Better" design philosophy
└── short.md                          Condensed version of design principles
```

## Project Documentation
```
docs/project/
├── monorepo-setup/
│   ├── research.md                   Initial research on Python/TypeScript tooling
│   ├── requirements.md               What the monorepo must and must not have
│   ├── spec.md                       Technical specification of the architecture
│   ├── implementation.md             Step-by-step implementation plan
│   └── validation.md                 How to verify the setup works correctly
└── monorepo-iteration/
    ├── research.md                   Analysis of command patterns and justfile approach
    ├── requirements.md               Goals for justfile system and directory renames
    ├── spec.md                       Technical specification of namespace-style commands
    ├── implementation.md             Step-by-step implementation with directory renames
    └── validation.md                 Validation of justfile system and new directory structure
```

## Quick Navigation

**For understanding architectural decisions:** Start with `design/monorepo-architecture.md`

**For working with dependencies:** See `design/workspace-dependencies.md`

**For adding configuration:** Read `design/minimal-configuration.md` first

**For running commands:** See `design/justfile-command-system.md`

**For implementation details:** See `project/monorepo-setup/` and `project/monorepo-iteration/` documents

**For philosophical context:** Read `principles/short.md`
