package net.opensorcerers.mongoframework.lib.update

import org.bson.BsonReader
import org.bson.BsonWriter
import org.bson.codecs.Codec
import org.bson.codecs.DecoderContext
import org.bson.codecs.EncoderContext
import org.bson.codecs.configuration.CodecRegistry
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static extension org.bson.codecs.BsonValueCodecProvider.*

@FinalFieldsConstructor class UpdateStatementListCodec implements Codec<UpdateStatementList> {
	val CodecRegistry codecRegistry

	override getEncoderClass() { return UpdateStatementList }

	override encode(BsonWriter writer, UpdateStatementList value, EncoderContext encoderContext) {
		writer.writeStartDocument

		for (statement : value.statements) {
			writer.writeName(statement.key)
			val expressionValue = statement.value
			encoderContext.encodeWithChildContext(
				codecRegistry.get(expressionValue.class) as Codec<Object>,
				writer,
				expressionValue
			)
		}

		writer.writeEndDocument
	}

	/**
	 * This should really never be called. These filter expressions aren't supposed to be stored. But we to be a Codec so we can register for recursion.
	 */
	override decode(BsonReader reader, DecoderContext decoderContext) {
		val result = new UpdateStatementList

		reader.readStartDocument

		val key = reader.readName
		val value = codecRegistry.get(reader.currentBsonType.classForBsonType).decode(reader, decoderContext)
		result.add(new UpdateStatement(key, value))

		reader.readEndDocument
		return result
	}
}
