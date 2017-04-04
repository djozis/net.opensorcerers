package net.opensorcerers.game.server.database.entities

import net.opensorcerers.mongoframework.annotations.ImplementMongoBean
import org.bson.BsonObjectId
import org.eclipse.xtend.lib.annotations.Accessors

@ImplementMongoBean @Accessors class DBUserCharacter {
	BsonObjectId userId
	String name
	String position
}
