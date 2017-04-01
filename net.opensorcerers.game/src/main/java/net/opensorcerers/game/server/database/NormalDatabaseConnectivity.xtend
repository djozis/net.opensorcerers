package net.opensorcerers.game.server.database

import com.mongodb.async.client.MongoClient
import com.mongodb.async.client.MongoClients
import com.mongodb.async.client.MongoDatabase
import de.flapdoodle.embed.mongo.MongodExecutable
import de.flapdoodle.embed.mongo.MongodStarter
import de.flapdoodle.embed.mongo.config.IMongodConfig
import de.flapdoodle.embed.mongo.config.MongodConfigBuilder
import de.flapdoodle.embed.mongo.config.Net
import de.flapdoodle.embed.mongo.config.Storage
import de.flapdoodle.embed.mongo.distribution.Version
import de.flapdoodle.embed.process.runtime.Network
import java.io.IOException
import org.eclipse.xtend.lib.annotations.Accessors

class NormalDatabaseConnectivity extends DatabaseConnectivity {
	var MongodExecutable mongodExecutable = null
	var MongoClient client
	@Accessors(PUBLIC_GETTER) var MongoDatabase database

	override open() {
		if (mongodExecutable === null) {
			mongodExecutable = MongodStarter.defaultInstance.prepare(getMongoConfiguration)
		}

		mongodExecutable.start
		client = MongoClients.create("mongodb://localhost:27017")
		database = client.getDatabase("opensorcerers")

		return this
	}

	@Accessors(PROTECTED_GETTER) val IMongodConfig mongoConfiguration = (new MongodConfigBuilder => [
		version(Version.Main.PRODUCTION)
		net(new Net("localhost", 27017, Network.localhostIsIPv6))
		replication(new Storage("db", null, 0))
	]).build

	override close() throws IOException {
		database = null
		client.close
		mongodExecutable.stop
	}

	override getDatabase() { return client.getDatabase("opensorcerers") }
}
