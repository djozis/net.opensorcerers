package net.opensorcerers.game.server

import io.vertx.core.Verticle
import io.vertx.core.Vertx
import java.io.Closeable
import java.io.IOException
import java.util.concurrent.CountDownLatch
import javax.xml.ws.Holder
import net.opensorcerers.framework.server.FrameworkServerServiceBase
import net.opensorcerers.game.server.bootstrap.SockJSEventBusVerticle
import net.opensorcerers.game.server.database.ApplicationDatabase
import net.opensorcerers.game.server.database.DatabaseConnectivity
import net.opensorcerers.game.server.services.AuthenticationServiceImpl
import net.opensorcerers.util.ReflectionsBootstrap
import org.eclipse.xtend.lib.annotations.Accessors
import org.reflections.Reflections
import org.reflections.scanners.SubTypesScanner

/**
 * Static fields can be overridden in unit testing.
 */
class ApplicationResources implements Closeable {
	@Accessors static ApplicationResources instance = null

	@Accessors val DatabaseConnectivity databaseConnectivity
	@Accessors val ApplicationDatabase database
	val Vertx vertx

	new(DatabaseConnectivity databaseConnectivity) {
		ReflectionsBootstrap.checkBootstrap
		this.databaseConnectivity = databaseConnectivity.open
		this.database = new ApplicationDatabase(databaseConnectivity.database)
		this.vertx = Vertx.vertx.deployVerticles(
			new SockJSEventBusVerticle,
			new AuthenticationServiceImpl
		).deployVerticles(
			new Reflections(
				"net.opensorcerers.game.server.services",
				ReflectionsBootstrap.urls,
				new SubTypesScanner
			).getSubTypesOf(FrameworkServerServiceBase).map [
				constructor.newInstance
			]
		)
	}

	def static deployVerticles(Vertx vertx, Verticle... verticles) {
		val latch = new CountDownLatch(verticles.length)
		val exceptionHolder = new Holder<Throwable>
		for (verticle : verticles) {
			vertx.deployVerticle(verticle) [
				if (cause !== null && exceptionHolder.value !== null) {
					exceptionHolder.value = cause
				}
				latch.countDown
			]
		}
		latch.await
		if (exceptionHolder.value !== null) {
			throw exceptionHolder.value
		}
		return vertx
	}

	override close() throws IOException {
		if (instance == this) {
			instance = null
		}
		vertx.close [
			println("Closed Vertx: " + it.succeeded)
		]
		databaseConnectivity.close
	}
}
