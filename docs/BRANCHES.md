# Branches

Work in this repository happens through categorized branches.

Each branch belongs to exactly one category, and the category defines its relationship with `core`: what it may consume, what it may modify and how its outcome returns to `main`.

`main` is the source of truth of the project. It holds the framework (`core`), its tests and the documentation in `docs/`.

Branches are working contexts. Neither category is expected to merge back into `main` as a whole; outcomes return to `main` deliberately, through evaluated changes.

# Categories

## Experiment

An experiment is an integrative test whose implementation must not require changes to `core`.

Its purpose is to verify whether the existing framework can express a concept.

* An experiment consumes `core` from the outside and never modifies it.
* `core/`, `tests/core/` and framework documentation must remain untouched.
* If an experiment hits a limitation of `core`, the limitation is recorded and reported. It does not justify modifying `core` inside the branch.
* Bugs found in `core` are fixed on `main` or through a dedicated fix, never as part of the experiment.

The direction of an experiment is one-way: the experiment adapts to `core`.

## Prototype

A prototype builds a realistic context on top of `core` to discover, through implementation, which abstractions and patterns are actually worth extracting.

* A prototype depends on `core` and on engine integration (nodes, scenes, resources, physics, input).
* Prototype code is disposable: it may be reorganized, replaced or discarded when the prototype reveals better solutions.
* A prototype may modify `core` when implementation reveals a deficiency or a necessary improvement. Each modification must be identified explicitly and documented inside the branch.
* Prototype branches are not expected to merge back into `main`. When the prototype ends, its results are analyzed and only what proves valuable is promoted to `main` deliberately.
* Prototype code must not silently become part of `core`.

The direction differs from an experiment: a prototype may reveal that `core` should adapt to reality.

    Experiment → the experiment adapts to core
    Prototype  → the prototype may reveal that core should adapt to reality

# Comparison

|                      | Experiment                          | Prototype                               |
| -------------------- | ----------------------------------- | --------------------------------------- |
| Purpose              | verify `core` can express a concept | exercise `core` in realistic conditions |
| `core` modifications | never                               | only explicit, documented changes       |
| Engine integration   | incidental                          | central                                 |
| Code lifetime        | disposable                          | disposable                              |
| Direction            | the experiment adapts to `core`     | reality may reveal `core` should evolve |

# Conventions

* Branches are named `<category>/<topic>`. Examples: `experiment/entity-state`, `prototype/hotline`.
* Each branch documents its own specifics inside its own workspace, not here. Game-layer work documents itself in `game/README.md` inside its branch.
* This document defines what branch categories are, not what any concrete branch does.

# Active Branches

| Branch                    | Category   | Own documentation          |
| ------------------------- | ---------- | -------------------------- |
| `experiment/entity-state` | Experiment | —                          |
| `prototype/hotline`       | Prototype  | `game/README.md` (branch)  |
