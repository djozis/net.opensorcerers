package net.opensorcerers.mongoframework.lib.index

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class IndexField {
	// Operators
	public static val OP_ASCENDING = 1
	public static val OP_DESCENDING = -1
	public static val OP_TEXT = "text"
	// Fields
	@Accessors(PROTECTED_GETTER) val IndexStatementList indexStatementList
	@Accessors(PROTECTED_GETTER) val String fieldName

	protected def doOpToField(String op, Object value) {
		indexStatementList.add(new IndexStatement(op, new IndexStatement(fieldName, value)))
	}

	def ascending() { indexStatementList.add(new IndexStatement(fieldName, OP_ASCENDING)) }

	def descending() { indexStatementList.add(new IndexStatement(fieldName, OP_DESCENDING)) }

	def text() { indexStatementList.add(new IndexStatement(fieldName, OP_TEXT)) }
}
