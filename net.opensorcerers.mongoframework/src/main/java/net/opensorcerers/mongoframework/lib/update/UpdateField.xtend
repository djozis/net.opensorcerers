package net.opensorcerers.mongoframework.lib.update

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class UpdateField {
	// Fields
	public static val OP_INCREMENT = "$inc" // Increments the value of the field by the specified amount.
	public static val OP_MULTIPLY = "$mul" // Multiplies the value of the field by the specified amount.
	public static val OP_RENAME = "$rename" // Renames a field.
	public static val OP_SET_ON_INSERT = "$setOnInsert" // Sets the value of a field if an update results in an insert of a document. Has no effect on update operations that modify existing documents.
	public static val OP_SET = "$set" // Sets the value of a field in a document.
	public static val OP_UNSET = "$unset" // Removes the specified field from a document.
	public static val OP_MIN = "$min" // Only updates the field if the specified value is less than the existing field value.
	public static val OP_MAX = "$max" // Only updates the field if the specified value is greater than the existing field value.
	public static val OP_CURRENT_DATE = "$currentDate" // Sets the value of a field to current date, either as a Date or a Timestamp.
	// Array
	public static val OP_INDEX = "$" // Acts as a placeholder to update the first element that matches the query condition in an update.
	public static val OP_ADD_TO_SET = "$addToSet" // Adds elements to an array only if they do not already exist in the set.
	public static val OP_POP = "$pop" // Removes the first or last item of an array.
	public static val OP_PULL_ALL = "$pullAll" // Removes all matching values from an array.
	public static val OP_PULL = "$pull" // Removes all array elements that match a specified query.
	public static val OP_PUSH_ALL = "$pushAll" // Deprecated. Adds several items to an array.
	public static val OP_PUSH = "$push" // Adds an item to an array.
	// Modifiers
	public static val OP_EACH = "$each" // Modifies the $push and $addToSet operators to append multiple items for array updates.
	public static val OP_SLICE = "$slice" // Modifies the $push operator to limit the size of updated arrays.
	public static val OP_SORT = "$sort" // Modifies the $push operator to reorder documents stored in an array.
	public static val OP_POSITION = "$position" // Modifies the $push operator to specify the position in the array to add elements.
	// Isolation
	public static val OP_ISOLATED = "$isolated" // Modifies the behavior of a write operation to increase the isolation of the operation.
	// Fields
	@Accessors(PROTECTED_GETTER) val UpdateStatementList updateStatementList
	@Accessors(PROTECTED_GETTER) val String fieldName

	protected def doOpToField(String op, Object value) {
		updateStatementList.add(new UpdateStatement(op, new UpdateStatement(fieldName, value)))
	}

	def set(Object value) { OP_SET.doOpToField(value) }

	def unset() { OP_UNSET.doOpToField(0) }

	def setOnInsert(Object other) { OP_SET_ON_INSERT.doOpToField(other) }
}
