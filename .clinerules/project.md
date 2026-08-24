# Project Development Rules

## 1. Architecture

Follow the architecture defined in `docs/ARCHITECTURE.md`.

Do not contradict architectural decisions documented there.

Do not introduce new architectural patterns, systems, managers, services, global buses, or abstractions unless they are explicitly requested or a concrete problem requires them.

Do not assume that a common game-development pattern is appropriate simply because it is common.

Prefer simple solutions over abstractions introduced for hypothetical future requirements.

If an architectural decision is ambiguous, stop and propose alternatives before implementing it.

## 2. Core / Game Separation

`core` must never depend on `game`.

Game-specific logic belongs in `game`.

Do not modify `core` to directly reference a concrete game mechanic.

If a game requirement appears to require a change to `core`, explain the reason and propose the smallest generic abstraction that could support it.

## 3. Composition and Inheritance

Prefer composition over inheritance when representing capabilities.

Do not create inheritance relationships solely for code reuse.

Use inheritance when there is a genuine specialization relationship.

Avoid deep inheritance hierarchies.

Before introducing a new base class, consider whether composition or a smaller abstraction would be more appropriate.

## 4. Folder Organization

Group two or more related files into a subdirectory.

Domain-specific classes belong to their respective domain folder.

Module implementations live under `entities/modules/<module>/`.

Do not create folders solely to group classes by inheritance.

Do not create a generic `handlers/` folder when the handler belongs clearly to a domain.

## 5. Identifiers

Never use unexplained numeric literals for game-specific identifiers.

Use enums defined by the game.

Do not introduce string identifiers when an enum is appropriate.

Example:

```gdscript
enum AttributeId {
    HEALTH,
    SPEED,
}
```

Prefer:

```gdscript
AttributeId.HEALTH
```

over:

```gdscript
1
```

## 6. GDScript Style

Use GDScript with explicit type annotations where they improve clarity.

Use `class_name` when a class is intended to be globally identifiable within the project.

If the class extends another class, declare `extends` first and `class_name` immediately below it.

Use descriptive names.

Avoid unnecessary abbreviations.

### Godot Parse Order

When a global class extends another global class, Godot may report `Could not find base class` during parsing because the base class has not yet been registered.

This is a known parse-order issue and is expected during project scanning.

Do not introduce architectural changes or workarounds solely to address this error. Re-evaluate after the project has completed scanning and all classes are registered.

## 7. Functions

Every function must have a documentation comment using `##` describing what the function does.

Example:

```gdscript
## Returns the attribute associated with the given identifier.

func get_attribute(attribute_id: int) -> Attribute:
    ...
```

Use two blank lines between methods.

## 8. Comments

Prefer readable code over comments.

Inline comments should only be used when something requires additional explanation that cannot be expressed clearly through the code itself.

Do not add comments that merely restate what the code obviously does.

Bad:

```gdscript
# Add condition
conditions.add(condition)
```

Good:

```gdscript
# Conditions are activated separately so their applications are only registered once.
conditions.add(condition)
```

Do not add comments solely to increase documentation density.

## 9. Formatting

Preserve the existing formatting style of the project.

Do not reformat unrelated code.

When modifying a file, change only what is necessary for the requested task.

Do not perform broad formatting changes as a side effect of implementing a feature.

Maintain:

* two blank lines between methods;
* one blank line between logical declaration groups;
* consistent indentation;
* consistent type annotations.

## 10. Language

Code must use English for everything.

This includes:

* class names;
* function names;
* variables;
* enums;
* comments;
* documentation;
* resource names;
* file names.

## 11. Scope

Before modifying files, understand the requested task and identify the minimum set of files that need to change.

Do not modify unrelated files.

Do not create additional systems simply because they might be useful later.

Do not remove existing code unless the task explicitly requires it or the removal is necessary to preserve the requested architecture.

## 12. Environment and Tooling

Do not assume that development tools are installed through a specific package manager or available directly in `PATH`.

Godot may be installed through Snap or another package manager.

Before running Godot commands, determine the available executable and invocation method when necessary.

For example, if the `godot` command is unavailable, check whether Godot is installed through Snap before assuming that Godot is not installed.

Do not modify the development environment or install software without explicit permission.

Environment-specific issues should be reported separately from code or architectural issues.

## 13. Verification

After implementing a change:

1. Review the modified code.
2. Check that it follows `docs/ARCHITECTURE.md`.
3. Check that it follows these rules.
4. Run relevant tests or validation when available.
5. Report problems rather than silently introducing unrelated fixes.

If a test or validation reveals an architectural problem, explain it before making a broad architectural change.

## 14. Agent Behavior

Do not silently make architectural decisions that were not specified.

If multiple reasonable solutions exist and the choice affects the architecture, explain the alternatives and ask for a decision.

If the requested implementation conflicts with the architecture, point out the conflict before modifying the architecture.

Prioritize correctness and architectural consistency over speed.

Do not assume that more abstraction is better.

Do not optimize prematurely.
