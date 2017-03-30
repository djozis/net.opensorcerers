package net.opensorcerers.mongoframework.lib.index

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor @Accessors class IndexStatement {
	val String key
	val Object value

	override equals(Object other) {
		if (other instanceof IndexStatement) {
			return key == other.key && value == other.value
		} else {
			return false
		}
	}
}
