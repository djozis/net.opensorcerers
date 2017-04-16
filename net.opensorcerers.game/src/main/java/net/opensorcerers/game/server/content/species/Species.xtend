package net.opensorcerers.game.server.content.species

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import net.opensorcerers.game.server.database.entities.DBCreature

@FinalFieldsConstructor class Species {
	@Accessors val int id
	@Accessors val String name

	def generateWildCreature() {
		return new DBCreature => [
			it.speciesId = this.id
			it.name = '''Wild «this.name»'''
			it.maxHitpoints = 10
			it.hitpoints = maxHitpoints
		]
	}
}
