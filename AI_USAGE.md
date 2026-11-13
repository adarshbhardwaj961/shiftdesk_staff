# AI usage

Tools: ChatGPT was used to help scaffold the folder structure, draft the GetX wiring, and review the claim-rule and pagination approach. Follow-up assistance was used to trace duplicate timestamps, stabilize cursor paging, add date-range filtering, and create regression tests.

Mostly AI-assisted: initial boilerplate, screen scaffolding, tests and Part 2 reference implementations.

Developer responsibility: review every file, run formatting/analyzer/tests, validate behavior on an emulator, and adjust code to the exact Flutter/Dart version and starter repository. The final validation run uses the repository's complete Flutter test suite and static analyzer; emulator verification remains a separate manual check.

Example of an AI output requiring review: an initial overlap check can accidentally treat adjacent shifts as overlapping. I used half-open interval comparison (`aStart < bEnd && bStart < aEnd`) so a shift ending at 14:00 and another starting at 14:00 are allowed. The same review is needed for week-boundary and overnight-shift calculations.
