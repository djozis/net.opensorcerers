package net.opensorcerers.game.server.bootstrap

import net.opensorcerers.database.bootstrap.H2DatabaseConnectivity
import net.opensorcerers.database.bootstrap.MySQLDatabaseConnectivity
import net.opensorcerers.game.server.ApplicationResources
import com.google.gwt.core.shared.GWT
import javax.servlet.ServletContextEvent
import javax.servlet.ServletContextListener
import javax.servlet.annotation.WebListener

import static net.opensorcerers.game.server.ApplicationResources.*

@WebListener class BootstrapListener implements ServletContextListener {
	ApplicationResources createdApplicationResources = null

	override contextInitialized(ServletContextEvent event) {
		if (ApplicationResources.instance === null) {
			ApplicationResources.instance = createdApplicationResources = createApplicationResources()
		}
	}

	def static ApplicationResources createApplicationResources() {
		if (GWT.isProdMode()) {
			return new ApplicationResources(
				new MySQLDatabaseConnectivity
			)
		} else {
			return new ApplicationResources(
				new H2DatabaseConnectivity
			)
		}
	}

	override contextDestroyed(ServletContextEvent event) { createdApplicationResources?.close }
}
