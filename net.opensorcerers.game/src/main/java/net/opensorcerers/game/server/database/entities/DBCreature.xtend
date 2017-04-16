package net.opensorcerers.game.server.database.entities

import net.opensorcerers.mongoframework.annotations.ImplementMongoBean
import org.bson.BsonObjectId
import org.eclipse.xtend.lib.annotations.Accessors
import net.opensorcerers.game.server.content.species.SpeciesProvider

@ImplementMongoBean @Accessors class DBCreature {
	BsonObjectId owningCharacter
	Integer speciesId
	String name
	Integer hitpoints
	Integer maxHitpoints

	def getSpecies() { return SpeciesProvider.instance.getSpecies(this.speciesId) }
}
