package net.opensorcerers.mongoframework.lib.project

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class ProjectField {
	// Operators
	public static val OP_FIRST_ELEMENT = "$" // Projects the first element in an array that matches the query condition.
	public static val OP_FIRST_ELEMENT_MATCHING = "$elemMatch" // Projects the first element in an array that matches the specified $elemMatch condition.
	public static val OP_META = "$meta" // Projects the document’s score assigned during $text operation.
	public static val OP_SLICE = "$slice" // Limits the number of elements projected from an array. Supports skip and limit slices.
	// Fields
	@Accessors(PROTECTED_GETTER) val ProjectStatementList projectStatementList
	@Accessors(PROTECTED_GETTER) val String fieldName

	protected def doOpToField(String op, Object value) {
		projectStatementList.add(new ProjectStatement(op, new ProjectStatement(fieldName, value)))
	}

	def include() { projectStatementList.add(new ProjectStatement(fieldName, 1)) }

	def exclude() { projectStatementList.add(new ProjectStatement(fieldName, 0)) }
}
