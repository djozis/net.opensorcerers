package net.opensorcerers.mongoframework.lib.index

import com.mongodb.client.model.IndexOptions
import java.util.concurrent.TimeUnit
import org.bson.BsonDocument
import org.bson.BsonReader
import org.bson.BsonType
import org.bson.BsonWriter
import org.bson.codecs.Codec
import org.bson.codecs.DecoderContext
import org.bson.codecs.EncoderContext
import org.bson.codecs.configuration.CodecRegistry
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class IndexModelExtendedCodec implements Codec<IndexModelExtended> {
	val CodecRegistry codecRegistry

	override getEncoderClass() { return IndexModelExtended }

	override encode(BsonWriter writer, IndexModelExtended value, EncoderContext encoderContext) {
		throw new UnsupportedOperationException("I don't have a use-case for this right now")
	}

	@FinalFieldsConstructor protected static class Decoder {
		val CodecRegistry codecRegistry
		val BsonReader reader
		val DecoderContext decoderContext

		def <T> T decode(Class<T> clazz) { return codecRegistry.get(clazz).decode(reader, decoderContext) }
	}

	/**
	 * This should really never be called. These filter expressions aren't supposed to be stored. But we to be a Codec so we can register for recursion.
	 */
	override decode(BsonReader reader, DecoderContext decoderContext) {
		var keys = new IndexStatementList
		val options = new IndexOptions

		reader.readStartDocument

		extension val Decoder = new Decoder(codecRegistry, reader, decoderContext)

		var BsonType currentBsonType
		while ((currentBsonType = reader.readBsonType) != BsonType.END_OF_DOCUMENT) {
			val fieldName = reader.readName
			switch fieldName {
				case "key":
					keys = IndexStatementList.decode
				case "name":
					options.name(String.decode)
				case "ns":
					String.decode // Ignore
				case "background":
					options.background(Boolean.decode)
				case "unique":
					options.unique(Boolean.decode)
				case "sparse":
					options.sparse(Boolean.decode)
				case "expireAfterSeconds":
					options.expireAfter(Long.decode, TimeUnit.SECONDS)
				case "v":
					options.version(Integer.decode)
				case "weights":
					options.weights(BsonDocument.decode)
				case "default_language":
					options.defaultLanguage(String.decode)
				case "language_override":
					options.languageOverride(String.decode)
				case "textIndexVersion":
					options.textVersion(Integer.decode)
				case "2dsphereIndexVersion":
					options.sphereVersion(Integer.decode)
				case "bits":
					options.bits(Integer.decode)
				case "min":
					options.min(Double.decode)
				case "max":
					options.max(Double.decode)
				case "bucketSize":
					options.bucketSize(Double.decode)
				case "dropDups":
					Boolean.decode // Ignore
				case "storageEngine":
					options.storageEngine(BsonDocument.decode)
				default:
					throw new IllegalStateException('''Couldn't determine what to do with field name: «fieldName»''')
			}
		}

		reader.readEndDocument
		return new IndexModelExtended(keys, options)
	}
}
