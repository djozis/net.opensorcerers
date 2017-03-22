package net.opensorcerers.game.test

import com.mongodb.async.SingleResultCallback
import com.mongodb.async.client.MongoDatabase
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import javax.xml.ws.Holder
import net.opensorcerers.game.server.mongo.TestDatabaseConnectivity
import net.opensorcerers.mongoframework.lib.MongoBeanCodecProvider
import net.opensorcerers.mongoframework.lib.index.IndexModelExtended
import net.opensorcerers.mongoframework.lib.index.IndexStatementList
import net.opensorcerers.mongoframework.lib.index.IndexesHelper
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
		sync[
			collection.insertOne(new MyBean => [
				zzz = "TESTvalue"
				another = new MyBean => [
					zzz = "Another value"
					mixedInString = "mixed in!"
				]
				mixedInString = "donkey"
			], it)
		]
		println(sync[collection.find.first(it)].zzz)
		println(sync[collection.find.first(it)]._id)
		println((sync[collection.find.first(it)].another as MyBeanMixin).mixedInString)
		println("OK")
		println(sync[
			collection.find(MyBean.Utils.filter [
				another.mixedInString.exists && another.mixedInString == "mixed in!" && another.zzz == "Another value"
			]).first(it)
		]._id)
		sync[
			collection.updateOne(MyBean.Utils.filter[zzz == "TESTvalue"], MyBean.Utils.update [
				zzz.unset
				another.zzz = "Another!"
			], it)
		]
		println(sync[collection.find.first(it)].zzz)
		println(sync[collection.find.first(it)].another.zzz)
		sync[
			collection.updateOne(MyBeanMixin.Utils.filter[mixedInString == "donkey"], MyBeanMixin.Utils.update [
				mixedInString = "mixxy"
			], it)
		]
		println(sync[collection.find.first(it)].mixedInString)
		println(
			sync[collection.find.projection(MyBeanMixin.Utils.project[mixedInString.include]).first(it)].mixedInString)
		println(sync[collection.find.projection(MyBeanMixin.Utils.project[mixedInString.include]).first(it)].another)

		println("Created Index: " + sync[
			collection.createIndexes(#[MyBeanMixin.Utils.index [
				mixedInString.ascending
			].withOptions [
				expireAfter(5000l, TimeUnit.SECONDS)
				sparse(true)
				name("Awesome")
			]], it)
		])
		sync[collection.listIndexes(IndexStatementList).forEach([println(it.toString)], it)]
		sync[
			IndexesHelper.setIndexes(collection, #[MyBeanMixin.Utils.index [
				mixedInString.ascending
			].withOptions [
				expireAfter(2000l, TimeUnit.SECONDS)
				sparse(true)
				name("Awesome")
			]], it)
		]
		sync[collection.listIndexes(IndexStatementList).forEach([println(it.toString)], it)]
	}
}
