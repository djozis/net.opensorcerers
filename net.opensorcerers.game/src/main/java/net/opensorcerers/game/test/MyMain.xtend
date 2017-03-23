package net.opensorcerers.game.test

import com.mongodb.async.SingleResultCallback
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import javax.xml.ws.Holder
import net.opensorcerers.game.server.mongo.ApplicationDatabase
import net.opensorcerers.game.server.mongo.TestDatabaseConnectivity
import net.opensorcerers.mongoframework.lib.index.IndexStatementList

class MyMain {
	def static void main(String[] args) {
		var TestDatabaseConnectivity databaseConnectivity = null
		try {
			(databaseConnectivity = new TestDatabaseConnectivity)
			new ApplicationDatabase(databaseConnectivity.open.database).runTest
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

	def static runTest(ApplicationDatabase database) {
		val collection = database.myBeans
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
			collection.findWhere [
				another.mixedInString.exists && another.mixedInString == "mixed in!" && another.zzz == "Another value"
			].first(it)
		]._id)
		sync[
			collection.updateOneWhere([zzz == "TESTvalue"], [
				zzz.unset
				another.zzz = "Another!"
			], it)
		]
		println(sync[collection.find.first(it)].zzz)
		println(sync[collection.find.first(it)].another.zzz)
		sync[
			collection.updateOneWhere( [mixedInString == "donkey"], [
				mixedInString = "mixxy"
			], it)
		]
		println(sync[collection.find.first(it)].mixedInString)
		println(sync[collection.find.projection[mixedInString.include].first(it)].mixedInString)
		println(sync[collection.find.projection[mixedInString.include].first(it)].another)

		sync[
			collection.setIndexes([
				createIndex[
					mixedInString.ascending
					return
				].withOptions [
					expireAfter(5000l, TimeUnit.SECONDS)
					sparse(true)
					name("Awesome")
				]
			], it)
		]
		println("FIRST INDEXES:")
		sync[collection.listIndexes(IndexStatementList).forEach([println(it.toString)], it)]
		sync[
			collection.setIndexes([
				createIndex[
					mixedInString.ascending
					return
				].withOptions [
					expireAfter(2000l, TimeUnit.SECONDS)
					sparse(true)
					name("Awesome")
				]
			], it)
		]
		println("SECOND INDEXES:")
		sync[collection.listIndexes(IndexStatementList).forEach([println(it.toString)], it)]
	}
}
