package net.opensorcerers.mongoframework.lib.filter

import java.util.ArrayList
import java.util.List
import org.bson.BsonDocumentWrapper
import org.bson.codecs.configuration.CodecRegistry
import org.bson.conversions.Bson
import org.eclipse.xtend.lib.annotations.Accessors

import static net.opensorcerers.mongoframework.lib.filter.FilterField.*

@Accessors class FilterExpression implements Bson {
	val String key
	val Object value

	new(String key, Object value) {
		if (value instanceof FilterField) {
			throw new IllegalArgumentException(
				'''FilterExpression value cannot be FilterField but was FilterField for «value.fieldName»'''
			)
		}
		this.key = key
		this.value = value
	}

	def protected FilterExpression join(String key, FilterExpression other) {
		if (this.key === key) {
			(value as List<FilterExpression>).add(other)
			return this
		} else {
			val resultValue = new ArrayList<FilterExpression>(4)
			resultValue.add(this)
			resultValue.add(other)
			return new FilterExpression(key, resultValue)
		}
	}

	def &&(FilterExpression other) { OP_AND.join(other) }

	def ||(FilterExpression other) { OP_OR.join(other) }

	def !() { return new FilterExpression(OP_NOT, this) }

	def nor(FilterExpression other) { OP_NOR.join(other) }

	override <TDocument> toBsonDocument(Class<TDocument> documentClass, CodecRegistry codecRegistry) {
		return new BsonDocumentWrapper(this, codecRegistry.get(FilterExpression))
	}
}
