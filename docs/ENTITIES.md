# Entities

`Entity` is the common abstraction of the objects that exist in a `World`.

See WORLD.md for how entities are registered, spawned, removed and updated.

# Identity

Identity belongs to `Entity`, not to the `World`.

An `Entity` keeps its ID even if it eventually changes `World`.

To guarantee that each entity has its own identity, a static incremental counter belonging to `Entity` may be used. This is a temporary solution, not a final architectural decision; the definitive identity mechanism will be decided later.

# Composition over hierarchy

`Entity` must not be coupled to 2D, 3D, or concrete Godot nodes.

`Static`, `Dynamic` and `Area` must not form the fundamental hierarchy of `Entity`.

The project is oriented toward composition and capabilities instead of a rigid hierarchy.

Modules/capabilities are optional parts of an entity.

A complete module API is deliberately not defined yet; it will be designed later.

Status: identity through the temporary static counter is implemented. Composition, capabilities and the module API remain pending.
