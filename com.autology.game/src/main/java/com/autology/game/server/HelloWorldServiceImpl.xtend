package com.autology.game.server

import com.autology.database.entities.DBUser
import de.itemis.xtend.auto.gwt.GwtService
import javax.servlet.annotation.WebServlet

import static extension com.autology.database.bootstrap.DatabaseExtensions.*

@GwtService @WebServlet("/app/helloWorldService") class HelloWorldServiceImpl {
	override String getMessage() {
		return ApplicationResources.instance.databaseConnectivity.withDatabaseConnectionReturn [
			queryClassWhere(
				DBUser
			).head?.alias ?: "No users found"
		]
	}
}
