package net.opensorcerers.game.server.database

import co.paralleluniverse.fibers.Fiber
import com.mongodb.async.client.MongoDatabase
import net.opensorcerers.game.server.database.entities.DBAuthenticationIdPassword
import net.opensorcerers.game.server.database.entities.DBUser
import net.opensorcerers.game.server.database.entities.DBUserSession
import net.opensorcerers.mongoframework.annotations.MongoBeanCollectionOf
import net.opensorcerers.mongoframework.annotations.MongoBeanCollectionsInitializer
import net.opensorcerers.mongoframework.lib.MongoBeanCodecRegistry

class ApplicationDatabase {
	@MongoBeanCollectionOf DBUser users
	@MongoBeanCollectionOf DBAuthenticationIdPassword authenticationIdPassword
	@MongoBeanCollectionOf DBUserSession userSessions

	@MongoBeanCollectionsInitializer def void createCollections(MongoDatabase database) {
		// Filled in by annotation
	}

	new(MongoDatabase rawDatabase) {
		rawDatabase.withCodecRegistry(MongoBeanCodecRegistry.create).createCollections

		new Fiber [
			userSessions.indexes = [
				createIndex[sessionId.ascending].withOptions[unique(true)]
			]
			authenticationIdPassword.indexes = [
				createIndex[loginId.ascending].withOptions[unique(true)]
			]
		].start.join
	}
}
