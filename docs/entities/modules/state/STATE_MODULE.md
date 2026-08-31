# State Module

`StateModule` is the state capability of an entity, implemented as a Module. See MODULES.md for the module model.

It manages the conditions acquired by an entity, their lifecycle and the processing of their effect applications.

State remains optional: entities that never access their state module simply do not have one.

An entity gains state by accessing its state module (`entity.modules.state`), which creates it lazily on first access.

`StateModule` holds a reference to its owning entity through the `Module` base. This does not couple it to 2D, 3D, physics, or a specific entity implementation.

`StateModule` is tick-based. Its update cycle advances in discrete ticks rather than continuous time. The module participates in `UpdatePipeline.Phase.STATE` with its `tick()` method, so its ticks arrive through its world pipeline connection. `tick()` remains available for driving the module directly, which is how logic is exercised without a world.

Conceptually:

```
Entity
└── Modules
    └── StateModule
        ├── ConditionHandler
        └── EffectHandler
```

Rules are an independent system that does not live inside the state module, see RULES.md.

`StateModule` should not depend on concrete game-specific types.

The handlers used by the state module are built on the generic `Handler` primitive. See PRIMITIVES.md.

# Conditions

A `Condition` represents a state acquired by an entity during gameplay.

Conditions generally have:

* an identity;
* an intensity;
* one or more `EffectApplication`s;
* a lifetime determined by their intensity/state.

Examples:

* Burn
* Wet
* Poison
* Frozen

The base `Condition` class belongs to `core`.

Concrete conditions belong to `game`.

Example:

```
core
└── Condition

game
└── BurnCondition
```

`StateModule` must not contain knowledge of concrete conditions.

## Condition Intensity

Intensity represents the remaining strength/lifetime of a condition.

When a condition reaches a state where its intensity is no longer sufficient to remain alive, it should be removed from the state module.

A condition is alive while its intensity is greater than its death threshold. `Condition.is_alive()` is defined as `intensity > death_threshold` and encapsulates this rule so that `StateModule` does not need to know how condition lifetime is represented. `StateModule` must use `is_alive()` instead of directly checking intensity.

The default death threshold is `0.1` (`Condition.DEFAULT_DEATH_THRESHOLD`). A condition decays by its `decay_rate` on every state module tick. A decay rate of `0.0` means the condition does not decay on its own. Decay is the way conditions expire: registering rules is never required for a condition to be able to die.

A condition whose intensity is at or below its death threshold when it is added is removed on the next state module tick without being activated.

A game that requires a condition to remain alive until its intensity reaches exactly zero creates it explicitly with a death threshold of `0.0`.

# Effects

An `Effect` is a transient data representation of an effect applied at a particular moment.

It contains information such as:

* gameplay kind;
* target identifier;
* value.

An `Effect` should remain a lightweight data object and should not contain complex behavior.

An `Effect` must not reference an `Attribute`, `Status`, or `Entity`. It only carries the kind, the target identifier and the value to apply.

The `kind` identifies the gameplay semantics of the effect, such as a damage type. Core stores the kind without interpreting it; concrete kinds are defined by the game.

Once processed, an `Effect` does not need to remain registered.

For example:

```
Effect
target = Health
value = -5
```

The concrete meaning of an effect is determined by the game through its resolvers.

# Effect Applications

`EffectApplication` describes how an effect is generated and applied over time.

It is the persistent/process-level abstraction. It can persist across multiple `StateModule` ticks.

It may belong to a `Condition`, but does not inherently require one. It may also represent an instant effect submitted directly to `EffectHandler`.

An application added to a condition is bound to it: `application.condition` returns the owning condition, or null for instant applications. Concrete applications may calculate their effects from the condition's intensity. The binding is held weakly so the condition and its applications do not form a reference cycle.

Its rate is expressed in `StateModule` ticks, not seconds.

Do not introduce separate `InstantEffectApplication` / `PersistentEffectApplication` classes. A single `EffectApplication` abstraction covers both cases.

This distinction is intentional:

```
Condition
└── EffectApplication
    └── Effect
```

`EffectApplication` represents the process or definition of applying an effect.

`Effect` represents the concrete result at a particular moment.

An application may calculate different effects depending on the current state of its associated condition.

For example:

```
BurnCondition
intensity = 10

    ↓

FireDamageApplication

    ↓

Effect
target = Health
value = calculated from Burn intensity
```

Concrete effect applications may belong to `game` when their behavior is game-specific.

## EffectApplication Sources

`EffectApplication`s can originate from two sources:

* **Conditions**, for persistent effects that last as long as the condition is alive.
* **Direct gameplay actions**, for instant effects submitted directly to `EffectHandler`.

# State Handlers

The state module manages its collections through specialized handlers built on the generic `Handler` primitive. See PRIMITIVES.md.

## EffectHandler

`EffectHandler` remains a `Handler` because it stores active `EffectApplication`s and their processing state.

It processes applications on `StateModule` ticks and returns the `Effect`s generated on each tick. It does not resolve targets or modify attributes.

Applications associated with a `Condition` are removed when that `Condition` is removed.

`ConditionHandler` provides typed access to conditions.

# Effect Processing

The flow of an effect is:

```
EffectApplication -> Effect -> EffectResolver -> Status
```

`StateModule` resolves each generated effect through the entity's `EffectResolver`, see RESOLVERS.md, and applies the resolved effect through `Status.modify_attribute`. Rejected effects are not applied.

# Signals

`StateModule` emits signals describing facts that already happened:

* `condition_added(condition)`: emitted after a condition has been added, reporting the resolved condition.
* `condition_removed(condition)`: emitted after a condition has been removed.
* `effect_applied(effect)`: emitted after a resolved effect has been applied to the entity's status, reporting the applied effect.

Rejected conditions and effects do not emit signals. Consumers connect directly to the state module of the entity they are interested in.

# Update Cycle

The conceptual update order is:

```
1. Apply condition decay.
2. Remove conditions that are no longer alive, together with their registered effect applications.
3. Activate newly active conditions.
4. Register their effect applications.
5. Process effect applications: generate effects, resolve them through the entity's EffectResolver and apply the results to the entity's status.
```

Conditions brought to a dead state by decay exit the circuit at step 2, before their effect applications are processed in that same tick.

The exact implementation may evolve.

The update system should remain generic and must not contain game-specific condition logic.