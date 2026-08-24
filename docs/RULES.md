# Rules

`Rule` represents an abstract interaction or modification involving conditions.

Rules exist to prevent condition interactions from being hardcoded into the state module.

For example, the interaction between `Burn` and `Wet` should not be implemented as:

```
if Burn and Wet:
    remove Burn
```

Instead, the game should be able to define a rule describing that interaction.

Example conceptual rule:

```
WeakenRule

target = Burn
presence = Wet
factor = 0.5
```

Rules operate on the conditions owned by a `StateModule`. See STATE_MODULE.md for how conditions, intensity and the state update cycle work.

## Scope

Rules operate at the `StateModule` level.

A `StateModule` may have its own rules, specific to that entity.

The `World` may eventually define a set of general rules applicable to StateModules. See Future in ARCHITECTURE.md.

Rules must not depend on `Entity` or `World`.

## Rule Inputs

Rules operate only on Conditions.

They do not operate on Attributes or Effects.

Effects are transient results and do not independently represent state to react to.

## Rule Effects

Rules primarily operate on condition intensity. For the initial implementation, rules may modify only `Condition.intensity`.

Rules do not directly modify the `ConditionHandler`. The `StateModule` evaluates rules and performs the necessary structural changes through the `ConditionHandler`.

Reducing a condition's intensity to zero or below is the mechanism for removing it. A rule that cancels a condition this way is a valid rule concept.

When a rule brings a condition to an intensity that is no longer alive, that condition and its effect applications leave the circuit before effect applications are processed in that same tick.

## Evaluation

The `StateModule` evaluates rules sequentially, in priority order.

Each rule receives the current conditions and may modify their intensity directly.

Rules evaluated later observe modifications made by rules evaluated earlier.

## Priority

Rules have an integer priority. Higher numeric priority executes first.

Ordering is deterministic and shared by all StateModules. Rules with equal priority are ordered by ascending identifier.

Registration order must not affect evaluation order.

## RuleHandler

`RuleHandler` extends the generic `Handler` primitive (see PRIMITIVES.md) and stores the rules evaluated by a `StateModule`.

It provides evaluation order through `get_rules_by_priority()`: rules sorted by descending priority, breaking ties by ascending identifier.

## Generic Implementations

The generic rule implementations `IdleRule`, `WeakenRule` and `CancelRule` belong to `core`.

They are parameterized mechanisms: they act on whatever target condition they are bound to, without knowledge of concrete game conditions.

* **IdleRule**: reduces the target intensity proportionally on every evaluation.
* **WeakenRule**: reduces the target intensity proportionally while a presence condition is present and alive.
* **CancelRule**: brings the target intensity directly to zero.

## Ownership

The rule infrastructure (`Rule`, `RuleHandler`) and the generic rule implementations belong to `core`.

What belongs to `game` is the definition of the relationships between conditions and rules: binding concrete rules to the game's conditions.

For example, `game` defines that a `CancelRule` targets `Burn`, or that a `WeakenRule` relates `Burn` and `Wet`.