# Primitives

Base abstractions shared by all domains.

Specialized handlers belong to their respective domain documents. This document grows as new primitives emerge.

# Element

`Element` is the common base abstraction for identifiable elements.

It provides:

* `id`
* `name`
* common string representation

Elements should share common behavior through this abstraction when appropriate.

Do not add functionality to `Element` merely because multiple classes could theoretically use it.

# Handler

Handlers provide generic management of collections of `Element` instances.

The base `Handler` provides operations such as:

* add
* remove
* lookup by ID
* contains
* clear
* get value
* set value
* get elements

Specialized handlers may extend this behavior when domain-specific operations are required.

Examples:

```
Handler
├── EntityHandler
├── ConditionHandler
└── EffectHandler
```

Handlers should remain focused on managing their respective data and should not become general-purpose managers.