package net.opensorcerers.database.entities

import net.opensorcerers.mongoframework.annotations.ImplementMongoBean
import org.eclipse.xtend.lib.annotations.Accessors

@ImplementMongoBean @Accessors class DBUser {
	def getId() { _id }

	String alias
}
