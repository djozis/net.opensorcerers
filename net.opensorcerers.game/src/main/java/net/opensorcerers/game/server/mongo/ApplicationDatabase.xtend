package net.opensorcerers.game.server.mongo

import com.mongodb.async.SingleResultCallback
import com.mongodb.async.client.MongoDatabase
import java.util.concurrent.CountDownLatch
import javax.xml.ws.Holder
import net.opensorcerers.database.entities.DBAuthenticationIdPassword
import net.opensorcerers.database.entities.DBUser
import net.opensorcerers.database.entities.DBUserSession
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

		sync[userSessions.setIndexes([createIndex[sessionId.ascending].withOptions[unique(true)]], it)]
		sync[authenticationIdPassword.setIndexes([createIndex[loginId.ascending].withOptions[unique(true)]], it)]
	}

	def static <T> sync((SingleResultCallback<T>)=>void operation) {
		val latch = new CountDownLatch(1)
		val holder = new Holder<T>
		val exceptionHolder = new Holder<Throwable>
		operation.apply [ result, cause |
			holder.value = result
			exceptionHolder.value = cause
			latch.countDown
		]
		latch.await
		if (exceptionHolder.value !== null) {
			throw exceptionHolder.value
		} else {
			return holder.value
		}
	}
}
