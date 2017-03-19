package net.opensorcerers.mongoframework.lib.filter

import org.bson.BsonReader
import org.bson.BsonWriter
import org.bson.codecs.Codec
import org.bson.codecs.DecoderContext
import org.bson.codecs.EncoderContext
import org.bson.codecs.configuration.CodecRegistry
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static extension org.bson.codecs.BsonValueCodecProvider.*

@FinalFieldsConstructor class FilterExpressionEncoder implements Codec<FilterExpression> {
	val CodecRegistry codecRegistry

	override getEncoderClass() { return FilterExpression }

	override encode(BsonWriter writer, FilterExpression value, EncoderContext encoderContext) {
		writer.writeStartDocument

		writer.writeName(value.key)
		encoderContext.encodeWithChildContext(
			codecRegistry.get(value.value.class) as Codec<Object>,
			writer,
			value.value
		)

		writer.writeEndDocument
	}

	/**
	 * This should really never be called. These filter expressions aren't supposed to be stored. But we to be a Codec so we can register for recursion.
	 */
	override decode(BsonReader reader, DecoderContext decoderContext) {
		reader.readStartDocument

		val key = reader.readName
		val value = codecRegistry.get(reader.currentBsonType.classForBsonType).decode(reader, decoderContext)

		reader.readEndDocument
		return new FilterExpression(key, value)
	}
}
