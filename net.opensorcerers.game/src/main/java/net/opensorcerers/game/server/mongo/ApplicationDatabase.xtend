package net.opensorcerers.game.server.mongo

import com.mongodb.async.client.MongoDatabase
import net.opensorcerers.game.test.MyBean
import net.opensorcerers.mongoframework.annotations.MongoBeanCollectionOf
import net.opensorcerers.mongoframework.annotations.MongoBeanCollectionsInitializer
import net.opensorcerers.mongoframework.lib.MongoBeanCodecRegistry

class ApplicationDatabase {
	@MongoBeanCollectionOf MyBean myBeans
	
	@MongoBeanCollectionsInitializer def void createCollections(MongoDatabase database) {
		// Filled in by annotation
	}

	new(MongoDatabase rawDatabase) {
		rawDatabase.withCodecRegistry(MongoBeanCodecRegistry.create).createCollections
	}
}
