# Status Module

`StatusModule` is the status capability of an entity, implemented as a Module. See MODULES.md for the module model.

It manages the quantitative state of the entity: its attributes and their current values.

Status remains optional: entities that never access their status module simply do not have one. The module is created lazily on first access through `entity.modules.status`.

`StatusModule` participates in no pipeline phase. Its data changes when effects are applied through it, not on a schedule of its own. If a future requirement needs the status to tick, for example modifier expiry, the module adds its own phase callback then.

Conceptually:

```
Entity
└── Modules
    └── StatusModule
        └── Status
            └── Attribute
                ├── base_value
                ├── current_value
                └── modifiers
```

# Status

`Status` administers the dictionary of attributes: lookup, configuration and valid mutation of its attributes.

* `add_attribute` / `remove_attribute` configure the attribute set.
* `get_attribute` / `has_attribute` / `get_attributes` provide lookup.
* `modify_attribute(attribute_id, delta)` adds a delta to an attribute's current value and returns whether the attribute exists.

Status does not know about effects, conditions or resolvers. Applying an effect to the status is decided outside of it, see RESOLVERS.md; Status only performs the mutation, clamping to the attribute's minimum value.

The actual attributes used by a game are game-specific.

# Attribute

An `Attribute` represents a measurable property of an entity.

An attribute has a base value and may have modifiers.

The base value should represent the underlying value.

`base_value` represents the original value and is never modified by the state module.

`current_value` represents the mutable current state of the attribute. Applied effects modify `current_value`.

Modifiers do not modify `current_value` directly. The effective value is calculated separately from `current_value` and the active modifiers.

# Modifier

A `Modifier` represents a temporary or contextual modification to an `Attribute`.

A modifier targets the attribute identified by `attribute_id` and contributes its additive `value` to that attribute's effective value.

For example:

```
Speed
base_value = 100

Slow modifier = -40

effective value = 60
```

When the modifier expires or is removed, the attribute returns to its previous effective value.

Modifiers should not permanently alter the underlying attribute value.

Modifiers do not have their own lifetime. They are applied and removed by the system that owns them: for example, the equipment module applies a modifier when its item is equipped and removes it on unequip, see EQUIPMENT.md. Timed modifier expiry remains a future possibility, see ARCHITECTURE.md.