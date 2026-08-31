# Rules

`Rule` represents an abstract interaction or modification involving conditions.

Rules exist to prevent condition interactions from being hardcoded into the state module.

Rules are an independent system. They live in `core/rules/`, depend only on conditions and are not owned or evaluated by `StateModule`. Nothing in `core` evaluates rules yet.

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

Rules operate on the conditions of an entity's state module, obtained through its condition handler.

The `World` may eventually define a set of general rules applicable to entities. See Future in ARCHITECTURE.md.

Rules must not depend on `Entity` or `World`.

## Rule Inputs

Rules operate only on Conditions.

They do not operate on Attributes or Effects.

Effects are transient results and do not independently represent state to react to.

## Rule Effects

Rules primarily operate on condition intensity. For the initial implementation, rules may modify only `Condition.intensity`.

Rules do not directly modify the `ConditionHandler`. They only mutate condition intensity; the state module update cycle performs the structural changes, removing conditions that are no longer alive together with their applications.

Reducing a condition's intensity to zero or below is the mechanism for removing it. A rule that cancels a condition this way is a valid rule concept.

Proportional reductions such as those performed by `WeakenRule` do not need to reach zero. A condition dies when its intensity falls to or below its death threshold, which is `0.1` by default. See STATE_MODULE.md for how condition liveness is defined.

When a rule leaves a condition with an intensity that is no longer alive, that condition and its effect applications are removed by the state module update cycle before its effect applications are processed.

## Condition Expiry Is Not a Rule

Conditions expire on their own through decay, see STATE_MODULE.md. Registering rules is never required for a condition to be able to expire.

The former `IdleRule` was removed when rules were decoupled from the state module: its behavior is now the built-in condition decay.

## Evaluation

Rules are not evaluated inside the state module. An evaluator applies rules sequentially, in priority order, over the current conditions.

Rules evaluated later observe modifications made by rules evaluated earlier.

Who provides the evaluator is deliberately deferred until a concrete need exists. See Future in ARCHITECTURE.md.

## Priority

Rules have an integer priority. Higher numeric priority executes first.

Ordering is deterministic. Rules with equal priority are ordered by ascending identifier.

Registration order must not affect evaluation order.

## RuleHandler

`RuleHandler` extends the generic `Handler` primitive (see PRIMITIVES.md) and stores the rules of the rules system, ready to be evaluated by an evaluator.

It provides evaluation order through `get_rules_by_priority()`: rules sorted by descending priority, breaking ties by ascending identifier.

## Generic Implementations

The generic rule implementations `WeakenRule` and `CancelRule` belong to `core`.

They are parameterized mechanisms: they act on whatever target condition they are bound to, without knowledge of concrete game conditions.

* **WeakenRule**: reduces the target intensity proportionally while a presence condition is present and alive.
* **CancelRule**: brings the target intensity directly to zero.

## Ownership

The rule infrastructure (`Rule`, `RuleHandler`) and the generic rule implementations belong to `core`.

What belongs to `game` is the definition of the relationships between conditions and rules: binding concrete rules to the game's conditions.

For example, `game` defines that a `CancelRule` targets `Burn`, or that a `WeakenRule` relates `Burn` and `Wet`.