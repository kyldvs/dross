"""Greeter package that depends on example."""

from example import hello as example_hello

__version__ = "0.1.0"


def greet() -> str:
    """Greet using the example package."""
    return f"Greeter says: {example_hello()}"
