package net.opensorcerers.game.server.database

import com.mongodb.async.client.MongoDatabase
import java.io.Closeable

abstract class DatabaseConnectivity implements Closeable {
	def DatabaseConnectivity open()

	def MongoDatabase getDatabase()
}
