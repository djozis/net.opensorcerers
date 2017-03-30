package net.opensorcerers.mongoframework.lib.filter

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.bson.BsonType

@FinalFieldsConstructor class FilterField {
	// Comparison
	public static val OP_EQUALS = "$eq" // Matches values that are equal to a specified value.
	public static val OP_NOT_EQUALS = "$ne" // Matches all values that are not equal to a specified value.
	public static val OP_GRATHER_THAN = "$gt" // Matches values that are greater than a specified value.
	public static val OP_GREATHER_THAN_EQUALS = "$gte" // Matches values that are greater than or equal to a specified value.
	public static val OP_LESS_THAN = "$lt" // Matches values that are less than a specified value.
	public static val OP_LESS_THAN_EQUALS = "$lte" // Matches values that are less than or equal to a specified value.
	public static val OP_IN = "$in" // Matches any of the values specified in an array.
	public static val OP_NOT_IN = "$nin" // Matches none of the values specified in an array.
	// Logical
	public static val OP_AND = "$and" // Joins query clauses with a logical OR returns all documents that match the conditions of either clause.
	public static val OP_OR = "$or" // Joins query clauses with a logical AND returns all documents that match the conditions of both clauses.
	public static val OP_NOT = "$not" // Inverts the effect of a query expression and returns documents that do not match the query expression.
	public static val OP_NOR = "$nor" // Joins query clauses with a logical NOR returns all documents that fail to match both clauses.
	// Element
	public static val OP_EXISTS = "$exists" // Matches documents that have the specified field.
	public static val OP_TYPE = "$type" // Selects documents if a field is of the specified type.
	// Evaluation
	public static val OP_MOD = "$mod" // Performs a modulo operation on the value of a field and selects documents with a specified result.
	public static val OP_REGEX = "$regex" // Selects documents where values match a specified regular expression.
	public static val OP_TEXT = "$text" // Performs text search.
	public static val OP_WHERE = "$where" // Matches documents that satisfy a JavaScript expression.
	// Array
	public static val OP_ALL = "$all" // Matches arrays that contain all elements specified in the query.
	public static val OP_ELEMENT_MATCH = "$elemMatch" // Selects documents if element in the array field matches all the specified $elemMatch conditions.
	public static val OP_SIZE = "$size" // Selects documents if the array field is a specified size.
	// Fields
	@Accessors(PROTECTED_GETTER) val String fieldName

	protected def compareExpression(String operator, Object value) {
		return new FilterExpression(fieldName, new FilterExpression(operator, value))
	}

	def exists() { return exists(true) }

	def exists(boolean existance) { return OP_EXISTS.compareExpression(existance) }

	def type(BsonType type) { return OP_TYPE.compareExpression(type.ordinal) }

	def ==(Object other) { return new FilterExpression(fieldName, other) }

	def !=(Object other) { return OP_NOT_EQUALS.compareExpression(other) }
}
