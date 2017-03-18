package net.opensorcerers.game.test

import com.mongodb.async.SingleResultCallback
import com.mongodb.async.client.MongoDatabase
import java.util.concurrent.CountDownLatch
import javax.xml.ws.Holder
import net.opensorcerers.game.server.mongo.TestDatabaseConnectivity
import net.opensorcerers.mongoframework.lib.MongoBeanCodecProvider
import org.bson.codecs.BsonValueCodecProvider
import org.bson.codecs.DocumentCodecProvider
import org.bson.codecs.ValueCodecProvider
import org.bson.codecs.configuration.CodecRegistries

class MyMain {
	def static void main(String[] args) {
		var TestDatabaseConnectivity databaseConnectivity = null
		try {
			databaseConnectivity = new TestDatabaseConnectivity
			databaseConnectivity.open
			databaseConnectivity.database.withCodecRegistry(CodecRegistries.fromProviders(
				new MongoBeanCodecProvider,
				new ValueCodecProvider,
				new DocumentCodecProvider,
				new BsonValueCodecProvider
			)).runTest
		} finally {
			databaseConnectivity?.close
		}
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

	def static runTest(MongoDatabase database) {
		val collection = database.getCollection("col", MyBean)
		sync[collection.insertOne(new MyBean() =>[
			zzz = "TESTvalue"
		], it)]
		println(sync[collection.find.first(it)].zzz)
		println(sync[collection.find.first(it)]._id)
		println("OK")
	}
}
