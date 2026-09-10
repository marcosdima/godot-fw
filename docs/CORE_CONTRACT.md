# Core Contract

This document records the established architectural invariants and the strong current contracts of the framework.

Contracts protect architectural intent, not implementation details. They may evolve, but only deliberately: changing a contract without discussion, or to make a single feature easier, breaks the consensus this document represents.

* Invariants are absolute. They are not expected to change.
* Strong contracts are established and intentional. Changing them requires explicit escalation, agreement and updates to the affected documentation and tests.

# Core/Game Boundary

* `core` must never depend on `game`. This is the only absolute boundary of the project.
* `game` may depend on `core`.
* Generic systems must not contain knowledge of concrete game mechanics.
* When `game` needs something `core` does not provide, the requirement is evaluated as a potential generic extension of `core`, never as a `core` dependency on game-specific types.

# Ownership and Lifetime

* Avoid ownership cycles and unintended lifetime cycles: owned objects must not keep their owner alive.
* Owner-to-owned references are strong: `Entity -> Modules`, `Entity -> EntityResolvers`, `Modules -> Module`, `EntityResolvers -> Resolver`, `RulesModule -> Rule`.
* Back-references to the owner are weak: `Module.entity`, `Resolver.entity`, `Rule._entity`, the facade references, `EffectApplication.condition` (back to its owning condition), `UIElement.parent` and `UIAnimationPlayback.element`.
* `WeakRef` is the current mechanism that realizes this invariant. The invariant is the contract; the mechanism may change if a better one appears.
* A strong back-reference would form a `RefCounted` cycle: the objects in the cycle would never reach a zero reference count and entities would never be freed.

# Module Lifecycle

* Modules are optional capabilities of an entity, accessed only through `entity.modules.<name>`.
* Modules are created lazily on first access.
* A module is permanent once instantiated: it remains alive for the lifetime of its entity.
* There is no individual module removal or deactivation API. If suspension or deactivation becomes necessary, it is introduced deliberately when the concrete requirement appears.
* `Module.new(entity)` produces a usable active module. There is no separate setup or initialization step.
* `attach()` is called even when `entity.world == null`; a module with no World simply has nothing to connect to and returns normally.

# Module Dependencies

* Modules may access sibling modules directly through `entity.modules.<name>` at operation time.
* There is no dependency declaration system, no dependency injection, no registries and no service locators.
* Accessing a non-instantiated sibling lazily creates it. This is intentional.
* Avoid accessing sibling modules during construction, `attach()` or `detach()`; lazy resolution during those windows can recurse.
* Direct coupling between modules is allowed when it is sensible. Do not introduce artificial indirection preemptively.

# Resolvers

* Resolvers are per-entity collaborators of `Entity`, not modules. They participate in no pipeline phase.
* Resolvers are replaceable by game code through assignment, for example `entity.resolvers.effect = FireEffectResolver.new(entity)`.
* Resolvers are pure decision points: they receive a fact, may consult modules, and return a result. They never mutate state themselves.
* A resolver must not add conditions to the state module from inside `resolve()`; that would recurse.
* There is no dependency injection, registry or locator for resolvers.

# State/Status Separation

* The current separation between `StateModule` (conditions, effects, effect applications) and `StatusModule` (attributes, modifiers) is the preferred architecture.
* It is not immutable: it may be reconsidered deliberately if implementation evidence points that way. It must not be changed as a side effect of a feature.

# State Tick Cycle

* The `StateModule.tick()` order is: decay → remove dead → activate new → process effects.
* Dead conditions do not fire effects in the same tick they expire.
* Freshly activated conditions have their effects resolved in the same tick.
* This order is a behavioral contract. Do not change it without understanding why it is the way it is.

# Effect Contract

* `Effect` is lightweight data: it carries no reference to `Entity`, `Status` or `Attribute`.
* `EffectApplication` is the single abstraction through which effects are resolved and applied. This is the preferred design and is revisable.
* Effects are resolved before they are applied to the status: `EffectApplication -> Effect -> EffectResolver -> Status.modify_attribute`.

# Conditions

* A condition is identified by one `ConditionId` per condition; each ID currently holds a single condition instance per entity.
* One-condition-per-ID is the current behavior, not the final contract. Stacking and merging semantics may evolve deliberately.

# Update Pipeline

* `World` owns and executes the pipeline from its update cycle. The update flow goes exclusively through `update_pipeline.update()`.
* The pipeline is intentionally decoupled from concrete modules: the World and the pipeline do not know which modules exist, and there is no module registration system.
* Modules connect directly to the signals of the phases they need, through the participations they declare.
* Connection order to a phase signal carries no architectural meaning. If a phase requires ordering, it must be resolved through an explicit mechanism.
* Reactive modules (Status, Progression, Interaction, Equipment, Inventory, Rules) do not need pipeline participation.

# Interaction

* The availability model is source-based and multi-reason: an interaction is available if any source presents it, and the reasons are tracked per source.
* Manual addition and source presentation coexist.
* The game must retract its sources before destroying the objects that present them; core does not sweep stale sources.

# Equipment

* Equipping is atomic: all targets are validated before any mutation; a failed equip leaves the entity unchanged.
* Unequip removes exactly the modifier instances that were applied by that equip. No other modifiers are affected.

# Rules

* Rules are reactive and signal-driven. They react to facts that already happened; they decide nothing about whether a fact should have happened.
* A rule produces consequences by calling public module APIs. Rules never mutate module internals directly.
* There are no identifiers, priorities or evaluation order for rules. Rules reacting to the same fact run in connection order, and core guarantees no ordering across them.

# UI

* `core/ui` is engine-light: its classes extend `RefCounted`, never `Node`, and must not read engine clocks, start timers or spawn threads. The engine, the clock and the input mapping belong to `game`.
* UI signals are effective-only: emitted when state actually changes, not on every attempt.
* The adapter applies the model to the view one way. Measured or computed layout geometry is never written back into the model.
* `full_view` containers fill their parent: their authored position and size are presentation-agnostic and ignored by the adapter.
* The model has no input bus, no UI manager and no global event system. Submit is resolved by the game as `focused.press()`, never by an implicit widget activation.
* Text entry keeps everything that is not committed text in the engine: the model holds only the committed `UIInput.text` and `placeholder`, while the draft and its caret/selection/clipboard/IME mechanics live in the adapter's native field. Commits flow model-ward (submit, focus loss); cancel restores the committed value without re-committing it.
* Playbacks are pure: advancing them is the game's responsibility through `advance(delta)`, and the game chooses the clock. `core/ui` never owns a loop.
* The animation track target set is whitelisted (`ANIMATABLE_PROPERTIES`); animation is restricted to visually meaningful properties and must not animate model semantics.

# Cross-Module Coupling

* Direct module-to-module access at operation time is allowed when sensible.
* Do not introduce dependency infrastructure preemptively. Escalate only if a concrete problem demonstrates the need.

# Global Systems

* Global systems (singletons, event buses, service locators) are avoided by default, not absolutely forbidden.
* They may be considered if a concrete architectural need for decoupled communication appears, and only as a deliberate decision.

# Smallest Abstraction

* Prefer the smallest abstraction that solves the actual requirement.
* Do not let this preference prevent a larger abstraction when evidence genuinely requires one. When a requirement conflicts with the current architecture, escalate rather than work around it silently.

# Open Questions

Deliberately undecided. These are not necessarily problems; they are areas expected to evolve when concrete requirements appear.

* The definitive entity identity mechanism (the static incremental counter is temporary).
* Condition stacking and merging semantics (one-condition-per-ID is current behavior, not final).
* The future of the State/Status separation.
* The future of the single `EffectApplication` abstraction.
* The future architecture of the pipeline (new phases, ordering, priorities).
* Constraints on cross-module coupling, if direct access ever proves insufficient.
* UI: whether the adapter should delegate to Godot `Container`/`Control` layout instead of its bespoke `arrange`, and which high-level widget types (text input, scroll, panels) the model will need.