package net.opensorcerers.game.server.content.species

class SpeciesProvider {
	static val speciesList = #[
		new Species(0, "Magical Creature")
	]

	static var SpeciesProvider instance = null

	static def getInstance() { return instance ?: (instance = new SpeciesProvider) }

	val Species[] speciesLookup

	protected new() {
		speciesLookup = newArrayOfSize(speciesList.map[id].max + 1)
		for (species : speciesList) {
			if (speciesLookup.get(species.id) !== null) {
				throw new IllegalStateException(
					'''Species «speciesLookup.get(species.id).name» and «species.name» both have id «species.id»'''
				)
			}
			speciesLookup.set(species.id, species)
		}
	}

	def getSpecies(int id) {
		if (id < 0 || id >= speciesLookup.length) {
			return null
		}
		return speciesLookup.get(id)
	}
}
