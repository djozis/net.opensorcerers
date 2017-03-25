package net.opensorcerers.game.test

import co.paralleluniverse.fibers.Fiber
import net.opensorcerers.game.server.mongo.ApplicationDatabase
import net.opensorcerers.game.server.mongo.TestDatabaseConnectivity

class Test {
	def static void main(String[] args) {
		val databaseConnectivity = new TestDatabaseConnectivity
		try {
			databaseConnectivity.open
			val database = new ApplicationDatabase(databaseConnectivity.database)
			new Fiber [
				println('hi')
				database.authenticationIdPassword.insertOne[loginId = "Kitten"]
				println('hiz')
			].start.join
		} finally {
			databaseConnectivity.close
		}
	}
}
