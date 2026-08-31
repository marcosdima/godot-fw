# Entity Resolvers

Resolvers interpret gameplay facts in the context of a single entity before they affect its state. Resolvers live under `entities/resolvers/` and belong to the entity: each entity owns one set of resolvers through its `EntityResolvers` facade, created at construction and accessed through `entity.resolvers`.

Resolvers are not modules: they participate in no pipeline phase and have no lifecycle beyond their entity.

# Resolver Base

Resolvers extend the `Resolver` base class, defined in `entities/resolvers/resolver.gd`. It mirrors `Module`: the entity is assigned at construction and never changes, and it is held weakly, so the reference chain between an entity and its resolvers does not form a `RefCounted` cycle. See Entity back-references in ARCHITECTURE.md.

# Contract

Resolvers are pure decision points:

* They receive a fact: a condition to add, an effect to apply.
* They may consult the entity's modules, such as Status or Progression.
* They return a result: the same object, a modified object, or null to reject it.
* They never mutate the state module themselves. `StateModule.add_condition` and the effect processing flow consume their results.

A resolver must not add conditions to the state module from inside `resolve()`; that would recurse.

# EffectResolver

`EffectResolver.resolve(effect)` interprets an effect before it modifies the entity's status. It returns the effect to apply, possibly modified, or null to reject it.

The flow of an effect is:

```
EffectApplication -> Effect -> EffectResolver -> Status.modify_attribute
```

The base implementation returns the effect unchanged. Games replace the resolver with a subclass to implement concrete semantics, such as fire damage reduced by fire resistance.

# ConditionResolver

`ConditionResolver.resolve(condition)` decides how a condition is incorporated into the entity's state. It returns the condition to add, possibly modified, or null to reject it.

`StateModule.add_condition()` consults this resolver; there is no other entry point for conditions. The base implementation returns the condition unchanged.

# Replacement by games

The facade pre-creates base resolvers. Games replace them by assignment when they configure an entity:

```
entity.resolvers.effect = FireEffectResolver.new(entity)
```

There is no dependency injection, registry or locator. Resolvers are constructed with their entity and access other modules through it at call time.

Resolvers must not become a global state controller: each resolver consults only the modules its decision requires, and decisions that belong to another system stay there.