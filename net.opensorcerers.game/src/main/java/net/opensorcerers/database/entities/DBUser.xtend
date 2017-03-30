package net.opensorcerers.database.entities

import net.opensorcerers.mongoframework.annotations.ImplementMongoBean
import org.eclipse.xtend.lib.annotations.Accessors

@ImplementMongoBean @Accessors class DBUser {
	String alias
}
