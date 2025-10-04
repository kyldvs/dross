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
