package net.opensorcerers.game.server

import io.vertx.core.Vertx
import java.io.Closeable
import java.io.IOException
import net.opensorcerers.database.bootstrap.DatabaseConnectivity
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * Static fields can be overridden in unit testing.
 */
class ApplicationResources implements Closeable {
	@Accessors static ApplicationResources instance = null

	@Accessors val DatabaseConnectivity databaseConnectivity
	val Vertx vertx

	new(DatabaseConnectivity databaseConnectivity) {
		this.databaseConnectivity = databaseConnectivity.open
		this.vertx = Vertx.vertx => [
			deployVerticle(new HelloWorldServiceVerticle) [
				println("Deployed to Vertx: " + it.succeeded)
			]
		]
	}

	override close() throws IOException {
		if (instance == this) {
			instance = null
		}
		vertx.close [
			println("Closed Vertx: " + it)
		]
		databaseConnectivity.close
	}
}
