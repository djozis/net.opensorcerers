package net.opensorcerers.database.entities

import java.util.UUID
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors class DBUser {
	UUID id

	String alias
}
