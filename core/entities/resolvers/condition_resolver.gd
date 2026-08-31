extends Resolver
class_name ConditionResolver


## Resolves the given condition in the context of its entity and returns the
## condition to add, possibly modified, or null to reject it. Resolvers return
## results; they never add conditions to the state module themselves. The base
## implementation returns the condition unchanged.
func resolve(condition: Condition) -> Condition:
	return condition