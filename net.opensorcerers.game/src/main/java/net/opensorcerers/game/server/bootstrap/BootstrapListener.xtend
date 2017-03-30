package net.opensorcerers.game.server.bootstrap

import net.opensorcerers.game.server.ApplicationResources
import javax.servlet.ServletContextEvent
import javax.servlet.ServletContextListener
import javax.servlet.annotation.WebListener

import static net.opensorcerers.game.server.ApplicationResources.*
import net.opensorcerers.game.server.mongo.NormalDatabaseConnectivity

@WebListener class BootstrapListener implements ServletContextListener {
	ApplicationResources createdApplicationResources = null

	override contextInitialized(ServletContextEvent event) {
		if (ApplicationResources.instance === null) {
			ApplicationResources.instance = createdApplicationResources = createApplicationResources()
		}
	}

	def static ApplicationResources createApplicationResources() {
		return new ApplicationResources(
			new NormalDatabaseConnectivity
		)
	}

	override contextDestroyed(ServletContextEvent event) { createdApplicationResources?.close }
}
