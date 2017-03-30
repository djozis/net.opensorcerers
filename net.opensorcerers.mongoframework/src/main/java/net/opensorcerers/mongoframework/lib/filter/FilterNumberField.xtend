package net.opensorcerers.mongoframework.lib.filter

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class FilterNumberField extends FilterField {
	def >(Number other) { return OP_GRATHER_THAN.compareExpression(other) }

	def >=(Number other) { return OP_GREATHER_THAN_EQUALS.compareExpression(other) }

	def <(Number other) { return OP_LESS_THAN.compareExpression(other) }

	def <=(Number other) { return OP_LESS_THAN_EQUALS.compareExpression(other) }
}
