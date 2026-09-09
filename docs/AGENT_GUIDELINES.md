# Agent Guidelines

These guidelines define the process an implementation agent follows in this repository: how to discover, how to reason, how to implement, how to verify and when to escalate. They are a process, not a checklist, and they apply to any change touching `core` or `docs/`.

The companion documents:

* [ARCHITECTURE.md](ARCHITECTURE.md) maps the systems.
* [CORE_CONTRACT.md](CORE_CONTRACT.md) records what must not be changed silently.
* `.clinerules/project.md` records the coding conventions.
* The domain documents under `docs/` describe each subsystem in detail.

# 1. Discover Before You Change

Before modifying anything:

* Read ARCHITECTURE.md for the system map.
* Read CORE_CONTRACT.md for the invariants and strong contracts that affect the change.
* Read the relevant domain document for the subsystem you are touching.
* Read the tests that cover the code you are changing, and run them.
* Read the adjacent source to follow local conventions.

"Documentation missing" is not a sufficient reason to stop. Investigate the code and tests first; if the documented behavior and the code disagree, that is an escalation trigger, not a reason to guess.

# 2. Preserve the Core/Game Boundary

* `core` must never depend on `game`.
* When modifying `core`, no game types or game-specific identifiers may appear.
* When modifying game-layer code, extend `core` freely, but do not modify `core` as a side effect.
* When game-layer code needs a change in `core`, explain the requirement and propose the smallest generic abstraction. Do not paste game-specific logic into `core` to make it work.

# 3. Respect Ownership and Lifetime

* Avoid ownership cycles: back-references owned by an entity are weak.
* The current mechanism is `WeakRef`. The invariant is what matters; do not introduce strong back-references to "fix" a symptom.
* When creating a new class owned by an entity, check the reference chain and store the entity reference weakly.

# 4. Resolvers Are Decision Points

* Resolvers decide conditions and effects in the context of an entity; they are collaborators, not modules.
* Place a resolver in `core/` when it is generic, in game code when it is game-specific. Game resolvers are installed by assignment on the entity facade.
* A resolver must not add conditions to the state module from inside `resolve()`; that would recurse.

# 5. Modules That Need Other Modules

* Access sibling modules at operation time through `entity.modules.<name>`, never at construction.
* If a correct design seems to require a sibling at construction or `attach()` time, reconsider the design before writing it.
* Do not build dependency declaration, injection, registries or locators for modules.

# 6. The Tick Cycle Has a Defined Order

* The state tick order is decay → remove dead → activate new → process effects. See STATE_MODULE.md and CORE_CONTRACT.md.
* Dead conditions do not fire effects in the same tick they expire.
* Do not change the order to make one feature work; escalate if the contract appears wrong.

# 7. Signals Are Per-Entity and Effective

* Emit on the module that owns the state change.
* Consumers connect directly to the source signal.
* Emit only when the state actually changes, not on failed attempts.
* Do not introduce a global event bus unless a concrete architectural need requires it.

# 8. Escalate Rather Than Invent

Escalate when:

* A feature conflicts with CORE_CONTRACT.md or with an established domain contract.
* More than one reasonable approach exists and the choice affects the architecture.
* It is unclear whether something belongs in `core` or in game code.
* A contract change appears necessary.
* The code contradicts the documentation or the tests contradict the code.

Investigating the code and tests before escalating is expected. Escalating early is better than inventing a workaround.

# 9. Contracts May Evolve, But Not Silently

* Do not change a contract to make a feature easier.
* Contract changes must be deliberate: discussed, agreed, documented and tested.
* Update CORE_CONTRACT.md and the affected domain documents when a contract changes.

# 10. Verify

* Review the change against ARCHITECTURE.md, CORE_CONTRACT.md and the relevant domain document.
* Follow the coding conventions in `.clinerules/project.md`.
* Run the tests that cover the change.
* Report problems you find; do not silently fix unrelated issues.

# 11. Scope Discipline

* Change the minimum set of files that satisfies the requirement.
* Do not modify unrelated files.
* Do not create speculative systems or abstractions.
* Do not remove code unless the requirement demands it.
* Do not reformat unrelated code while making a change.

# 12. When Modifying core/

* Explain why the change belongs in `core` and is generic.
* Keep the change consistent with CORE_CONTRACT.md.
* Run the full test suite and confirm it passes.
* Update the affected domain documentation if the change affects documented behavior.
* Escalate if the change conflicts with CORE_CONTRACT.md instead of weakening the contract.

# 13. Environment and Tooling

* Do not assume how a tool is installed or invoked; check the repository and the tests for the established way.
* Do not modify the development environment (installs, config, engine settings) without permission.
* Report environment problems separately from code problems.