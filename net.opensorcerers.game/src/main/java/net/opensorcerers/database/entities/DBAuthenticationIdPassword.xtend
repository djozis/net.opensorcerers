package net.opensorcerers.database.entities

import org.eclipse.xtend.lib.annotations.Accessors

@Accessors  class DBAuthenticationIdPassword {
	String id

	byte[] digest

	DBUser user
}
