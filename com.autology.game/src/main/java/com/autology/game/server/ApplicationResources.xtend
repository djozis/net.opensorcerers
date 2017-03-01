package com.autology.game.server

import com.autology.database.bootstrap.DatabaseConnectivity
import java.io.Closeable
import java.io.IOException
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * Static fields can be overridden in unit testing.
 */
class ApplicationResources implements Closeable {
	@Accessors static ApplicationResources instance = null

	@Accessors val DatabaseConnectivity databaseConnectivity

	new(DatabaseConnectivity databaseConnectivity) {
		this.databaseConnectivity = databaseConnectivity.open
	}

	override close() throws IOException {
		if (instance == this) {
			instance = null
		}
		databaseConnectivity.close
	}
}
