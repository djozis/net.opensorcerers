package net.opensorcerers.game.server

import net.opensorcerers.database.entities.DBUser
import de.itemis.xtend.auto.gwt.GwtService
import javax.servlet.annotation.WebServlet

import static extension net.opensorcerers.database.bootstrap.DatabaseExtensions.*

@GwtService @WebServlet("/app/helloWorldService") class HelloWorldServiceImpl {
	override String getMessage() {
		return ApplicationResources.instance.databaseConnectivity.withDatabaseConnectionReturn [
			queryClassWhere(
				DBUser
			).head?.alias ?: "No users found"
		]
	}
}
