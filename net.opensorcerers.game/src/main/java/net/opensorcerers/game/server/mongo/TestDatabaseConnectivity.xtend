package net.opensorcerers.game.server.mongo

import de.flapdoodle.embed.mongo.config.IMongodConfig
import de.flapdoodle.embed.mongo.config.MongoCmdOptionsBuilder
import de.flapdoodle.embed.mongo.config.MongodConfigBuilder
import de.flapdoodle.embed.mongo.config.Net
import de.flapdoodle.embed.mongo.config.Storage
import de.flapdoodle.embed.mongo.distribution.Version
import de.flapdoodle.embed.process.runtime.Network
import java.util.concurrent.CountDownLatch

class TestDatabaseConnectivity extends NormalDatabaseConnectivity {
	val IMongodConfig mongoConfiguration = (new MongodConfigBuilder => [
		version(Version.Main.PRODUCTION)
		net(new Net("localhost", 27017, Network.localhostIsIPv6))
		replication(new Storage("build/junitdb", null, 0))
		cmdOptions((new MongoCmdOptionsBuilder => [
			useNoJournal(true)
			useStorageEngine("ephemeralForTest")
		]).build)
	]).build

	override getMongoConfiguration() { return mongoConfiguration }

	def clearDatabase() {
		val latch = new CountDownLatch(1)
		database.drop[latch.countDown]
		latch.await
	}
}
