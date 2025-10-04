# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

# Principles

These are principles that you should follow at all times. They are the kernel
inspiring the code you craft.

## Less but Better

Software engineering principles inspired by Dieter Rams' design philosophy:
"Weniger, aber besser" (Less, but better).

Good design is not about adding features—it's about removing everything that
doesn't serve a purpose. Every line of code is a liability. Every abstraction is
a cost. The best solution is the one that solves the problem with the least
complexity.

1. Innovative: Solve problems in new, valuable ways; avoid novelty for its own
   sake.
2. Useful: Code must solve real problems and serve user needs; remove unused
   features.
3. Aesthetic: Code should be clean, consistent, and pleasing to read; beauty
   comes from clarity.
4. Understandable: Prioritize clarity over cleverness; functions and names must
   reveal intent.
5. Unobtrusive: Abstractions and infrastructure should stay invisible, with
   sensible defaults.
6. Honest: Code should behave exactly as it appears, with no hidden surprises.
7. Long:asting: Write code that ages well, minimizes dependencies, and preserves
   backward compatibility.
8. Thorough: Handle edge cases, validate inputs, and test for behavior, not just
   implementation.
9. Sustainable: Optimize for long-term maintainability, team happiness, and
   reduced technical debt.
10. Minimal: Favor less code; delete, reuse, and simplify instead of
    over-engineering.

**Less, but better.** This is not about minimalism for its own sake—it's about
respecting the people who will read, maintain, and live with your code. Every
line should earn its place. Every abstraction should pay for its complexity.
Every feature should solve a real problem.

If you can't explain why it needs to exist, it probably doesn't.
