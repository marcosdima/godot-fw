# Entities

`Entity` is the common abstraction of the objects that exist in a `World`.

See WORLD.md for how entities are registered, spawned, removed and updated.

# Identity

Identity belongs to `Entity`, not to the `World`.

An `Entity` keeps its ID even if it eventually changes `World`.

To guarantee that each entity has its own identity, a static incremental counter belonging to `Entity` may be used. This is a temporary solution, not a final architectural decision; the definitive identity mechanism will be decided later.

# Composition over hierarchy

`Entity` must not be coupled to 2D, 3D, or concrete Godot nodes.

The project is oriented toward composition and capabilities instead of a rigid hierarchy.

# Modules Ownership

The entity owns its `Modules` object and delegates module lifecycle concerns to it.

The entity does not directly manage concrete modules; it communicates through `Modules`.

Modules are optional capabilities of an entity. See MODULES.md for the complete module model.

# World Relationship

The entity holds a reference to the `World` it currently belongs to. The entity is the source of truth for its current World.

`Entity.set_world(world)` is the only supported mechanism for changing it. The transition detaches active modules while still in the old world and attaches them in the new one.

See WORLD.md for how the World lifecycle methods maintain this relationship.

Status: identity through the temporary static counter, the `Modules` facade and the world relationship are implemented. Additional capabilities remain pending.