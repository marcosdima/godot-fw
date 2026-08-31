extends Resolver
class_name EffectResolver


## Resolves the given effect in the context of its entity and returns the effect to
## apply, possibly modified, or null to reject it. Resolvers return results; they
## never apply effects themselves. The base implementation returns the effect unchanged.
func resolve(effect: Effect) -> Effect:
	return effect