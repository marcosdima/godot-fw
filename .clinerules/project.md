# Project Conventions

This file contains the concrete coding and project conventions of this repository.

It intentionally does not repeat architecture decisions or the agent process. Those live in their own documents:

* [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md): system map and general design principles.
* [docs/CORE_CONTRACT.md](../docs/CORE_CONTRACT.md): invariants and strong contracts.
* [docs/AGENT_GUIDELINES.md](../docs/AGENT_GUIDELINES.md): how implementation work is discovered, executed, verified and escalated.

## 1. Folder Organization

Group two or more related files into a subdirectory.

Domain-specific classes belong to their respective domain folder.

Module implementations live under `entities/modules/<module>/`.

Do not create folders solely to group classes by inheritance.

Do not create a generic `handlers/` folder when the handler belongs clearly to a domain.

## 2. Identifiers

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

## 3. GDScript Style

Use GDScript with explicit type annotations where they improve clarity.

Use `class_name` when a class is intended to be globally identifiable within the project.

If the class extends another class, declare `extends` first and `class_name` immediately below it.

Use descriptive names.

Avoid unnecessary abbreviations.

### Godot Parse Order

When a global class extends another global class, Godot may report `Could not find base class` during parsing because the base class has not yet been registered.

This is a known parse-order issue and is expected during project scanning.

Do not introduce architectural changes or workarounds solely to address this error. Re-evaluate after the project has completed scanning and all classes are registered.

## 4. Functions

Every function must have a documentation comment using `##` describing what the function does.

Example:

```gdscript
## Returns the attribute associated with the given identifier.

func get_attribute(attribute_id: int) -> Attribute:
    ...
```

Use two blank lines between methods.

## 5. Comments

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

## 6. Formatting

Preserve the existing formatting style of the project.

Do not reformat unrelated code.

When modifying a file, change only what is necessary for the requested task.

Do not perform broad formatting changes as a side effect of implementing a feature.

Maintain:

* two blank lines between methods;
* one blank line between logical declaration groups;
* consistent indentation;
* consistent type annotations.

## 7. Language

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