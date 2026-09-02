# Equipment Module

`EquipmentModule` is the equipment capability of an entity, implemented as a Module. See MODULES.md for the module model.

It manages what the entity currently has equipped: items held in slots and the status modifiers each item applies while equipped.

Equipment remains optional: entities that never access their equipment module simply do not have one. The module is created lazily on first access through `entity.modules.equipment`.

`EquipmentModule` participates in no pipeline phase. Its state changes only when items are equipped or unequipped, not on a schedule of its own.

Conceptually:

```
Entity
└── Modules
    └── EquipmentModule
        └── slot
            ├── item
            └── applied modifiers
```

# Slots

A slot is identified by an integer defined by the game. The module does not interpret slots: any slot may hold any item.

Each slot holds at most one item. Equipping an occupied slot unequips its current item first and then equips the new one. Slots are independent of each other.

# Items

An item is an opaque `Object`. The module never inspects it: it only keeps the reference for state queries and signals. What an item means and which modifiers it grants are game decisions.

# Modifiers

Modifiers are passed explicitly on equip, see STATUS_MODULE.md. Each modifier targets the attribute identified by its `attribute_id` and is applied to that attribute through the entity's `StatusModule`, which is accessed lazily.

Equipping is atomic: every modifier target is validated against the status before anything is applied. When any attribute is missing, the whole equip is rejected with an error and nothing changes, including the current item of an occupied slot.

The module remembers exactly the modifier instances it applied and removes those instances on unequip. Modifier instances must be unique within an equip call: the module applies what it receives, keyed by instance identity.

Unequip of an empty slot is ignored with an error. Removing a modifier restores the attribute's previous effective value; changes made to `current_value` while equipped are not affected.

# Signals

* `equipped(slot, item)`: an item was equipped in the slot, after any swap unequip.
* `unequipped(slot, item)`: the item was removed from the slot, including by a swap.