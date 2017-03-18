package net.opensorcerers.database.entities

import org.eclipse.xtend.lib.annotations.Accessors

@Accessors class DBUserSession {
	String id

	DBUser user
}
