package net.opensorcerers.game.server.database

import com.mongodb.async.client.MongoClient
import com.mongodb.async.client.MongoClients
import com.mongodb.async.client.MongoDatabase
import de.flapdoodle.embed.mongo.Command
import de.flapdoodle.embed.mongo.MongodExecutable
import de.flapdoodle.embed.mongo.MongodStarter
import de.flapdoodle.embed.mongo.config.ExtractedArtifactStoreBuilder
import de.flapdoodle.embed.mongo.config.IMongodConfig
import de.flapdoodle.embed.mongo.config.MongodConfigBuilder
import de.flapdoodle.embed.mongo.config.Net
import de.flapdoodle.embed.mongo.config.RuntimeConfigBuilder
import de.flapdoodle.embed.mongo.config.Storage
import de.flapdoodle.embed.mongo.distribution.Version
import de.flapdoodle.embed.process.io.directories.PlatformTempDir
import de.flapdoodle.embed.process.runtime.Network
import java.io.IOException
import org.eclipse.xtend.lib.annotations.Accessors
import java.io.File
import de.flapdoodle.embed.mongo.config.MongoCmdOptionsBuilder

class NormalDatabaseConnectivity extends DatabaseConnectivity {
	var MongodExecutable mongodExecutable = null
	var MongoClient client
	@Accessors(PUBLIC_GETTER) var MongoDatabase database

	override open() {
		if (mongodExecutable === null) {
			val command = Command.MongoD
			mongodExecutable = MongodStarter.getInstance(
				new RuntimeConfigBuilder().defaults(command).artifactStore(
					new ExtractedArtifactStoreBuilder => [
						defaults(command)
						tempDir(new PlatformTempDir {
							// This override fixes relatives tmpdir paths showing up twice in executable path
							override File asFile() { return super.asFile.absoluteFile }
						})
					]
				).build
			).prepare(getMongoConfiguration)
		}

		try {
			mongodExecutable.start
		} catch (IOException e) {
			// This can happen in dev mode when terminating the server from Ecipse.
			// The servlet listener doesn't get a chance to clean up the Mongod process.
			// Try again...
			if (e.message.contains("Could not start process")) {
				mongodExecutable.start
			}
		}
		client = MongoClients.create("mongodb://localhost:27017")
		database = client.getDatabase("opensorcerers")

		return this
	}

	@Accessors(PROTECTED_GETTER) val IMongodConfig mongoConfiguration = (new MongodConfigBuilder => [
		version(Version.Main.PRODUCTION)
		net(new Net("localhost", 27017, Network.localhostIsIPv6))
		replication(new Storage("db", null, 0))
		cmdOptions(
			(new MongoCmdOptionsBuilder => [
				useSmallFiles(true)
				useNoJournal(false)
			]).build
		)
	]).build

	override close() throws IOException {
		database = null
		client.close
		mongodExecutable.stop
	}

	override getDatabase() { return client.getDatabase("opensorcerers") }
}
