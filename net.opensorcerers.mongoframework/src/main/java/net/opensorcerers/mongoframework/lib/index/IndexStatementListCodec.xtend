package net.opensorcerers.mongoframework.lib.index

import org.bson.BsonReader
import org.bson.BsonType
import org.bson.BsonWriter
import org.bson.codecs.Codec
import org.bson.codecs.DecoderContext
import org.bson.codecs.EncoderContext
import org.bson.codecs.configuration.CodecRegistry
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static extension org.bson.codecs.BsonValueCodecProvider.*

@FinalFieldsConstructor class IndexStatementListCodec implements Codec<IndexStatementList> {
	val CodecRegistry codecRegistry

	override getEncoderClass() { return IndexStatementList }

	override encode(BsonWriter writer, IndexStatementList value, EncoderContext encoderContext) {
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
		val result = new IndexStatementList

		reader.readStartDocument

		var BsonType currentBsonType
		while ((currentBsonType = reader.readBsonType) != BsonType.END_OF_DOCUMENT) {
			val key = reader.readName
			val value = codecRegistry.get(
				switch currentBsonType {
					case INT32: Integer
					case INT64: Long
					case STRING: String
					default: currentBsonType.classForBsonType
				} as Class<?>
			).decode(reader, decoderContext)
			result.add(new IndexStatement(key, value))
		}

		reader.readEndDocument
		return result
	}
}
