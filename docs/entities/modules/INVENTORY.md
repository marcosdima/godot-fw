# Inventory Module

`InventoryModule` is the inventory capability of an entity, implemented as a Module. See MODULES.md for the module model.

It stores the items the entity carries. It is a plain container: it does not interpret items and holds no semantics beyond membership.

Inventory remains optional: entities that never access their inventory module simply do not have one. The module is created lazily on first access through `entity.modules.inventory`.

`InventoryModule` participates in no pipeline phase. Its state changes only when items are added or removed.

# Items

Items are opaque `Object` references keyed by instance identity: the same instance is held at most once and two distinct instances are distinct items, even if they represent the same game item.

Items are kept in insertion order. `add` rejects an item that is already held with an error. `remove` of a non-held item is ignored with an error. `get_items` returns a copy in that order; the instances it contains are the same references the module holds.

# Scope

The inventory has no capacity, stacking or slot semantics. These are deferred until a concrete need appears.

# Signals

* `item_added(item)`: an item was added to the inventory.
* `item_removed(item)`: an item was removed from the inventory.