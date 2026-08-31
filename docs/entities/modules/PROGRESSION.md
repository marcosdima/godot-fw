# Progression

`ProgressionModule` is the progression capability of an entity, implemented as a Module. See MODULES.md for the module model.

It stores progression values: a dictionary of integers keyed by progression identifiers. Examples of possible progressions: `FIRE_RESISTANCE`, `KNIFE_PROFICIENCY`. The concrete identifiers belong to the game.

Progression is independent of State. It does not know about conditions, effects or attributes. Its values change through its own API or through game configuration, not as a side effect of state processing.

The module is created lazily on first access through `entity.modules.progression` and participates in no pipeline phase.

Conceptually:

```
Entity
└── Modules
    └── ProgressionModule
        └── Progression
            └── progression_id -> int
```

# Progression

`Progression` administers the dictionary of progression values:

* `set_value(progression_id, value)` sets the value of a progression.
* `get_value(progression_id)` returns the value, or 0 when the progression does not exist.
* `contains(progression_id)` returns whether the progression exists.
* `advance(progression_id, amount)` adds an amount to a progression, creating it when absent.

# Relationship with State

State does not read or write Progression. When gameplay requires connecting them, for example an effect reduced by fire resistance or a progression advancing when an effect is applied, the connection happens through entity resolvers and signal connections owned by the game. See RESOLVERS.md.