package net.opensorcerers.mongoframework.lib.update

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor @Accessors class UpdateStatement {
	val String key
	val Object value
}
