package net.opensorcerers.game.server.database.entities

import co.paralleluniverse.fibers.Suspendable
import net.opensorcerers.game.server.ApplicationResources
import net.opensorcerers.mongoframework.annotations.ImplementMongoBean
import org.bson.BsonObjectId
import org.eclipse.xtend.lib.annotations.Accessors

@ImplementMongoBean @Accessors class DBUserCharacter {
	BsonObjectId userId
	String name
	String position
	BsonObjectId currentCreature

	@Suspendable def loadCreatures() {
		return ApplicationResources.instance.database.userCreatures.findWhere [
			it.owner == this._id
		].toArrayList
	}
}
