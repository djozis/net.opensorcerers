package net.opensorcerers.mongoframework.lib

import java.lang.reflect.Constructor
import java.lang.reflect.Field
import java.util.HashMap
import org.bson.BsonObjectId
import org.bson.BsonReader
import org.bson.BsonType
import org.bson.BsonWriter
import org.bson.codecs.Codec
import org.bson.codecs.CollectibleCodec
import org.bson.codecs.DecoderContext
import org.bson.codecs.EncoderContext
import org.bson.codecs.configuration.CodecRegistry
import org.bson.types.ObjectId
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.xbase.lib.Procedures.Procedure2

class MongoBeanCodec<T extends MongoBean> implements CollectibleCodec<T> {
	@Accessors val Class<T> encoderClass
	val CodecRegistry codecRegistry
	val Constructor<T> constructor
	val HashMap<String, FieldMetadata<T>> fieldMetadataLookup

	protected static class FieldMetadata<T extends MongoBean> {
		Procedure2<T, Object> setter
		Codec<Object> codec = null
	}

	new(CodecRegistry codecRegistry, Class<T> encoderClass) {
		this.codecRegistry = codecRegistry
		this.encoderClass = encoderClass
		try {
			this.constructor = encoderClass.constructor
		} catch (NoSuchMethodException e) {
			throw new IllegalStateException(
				'''No zero-argument constructor found for «encoderClass.name»''',
				e
			)
		}
		try {
			fieldMetadataLookup = new HashMap
			for (setterEntry : (encoderClass.getDeclaredMethod(
				"createFieldSettersLookup"
			).invoke(null) as HashMap<String, Procedure2<T, Object>>).entrySet) {
				val fieldMetadata = new FieldMetadata
				fieldMetadata.setter = setterEntry.value
				fieldMetadataLookup.put(setterEntry.key, fieldMetadata)
			}
		} catch (NoSuchMethodException e) {
			throw new IllegalStateException(
				'''No zero-argument static createFieldSettersLookup method found for «encoderClass.name»''',
				e
			)
		}
	}

	var needsInit = true

	protected def checkInit() {
		if (needsInit) {
			val fieldsMap = new HashMap<String, Field>().addBeanClassFieldsToMap(encoderClass)
			for (fieldMetadataEntry : fieldMetadataLookup.entrySet) {
				fieldMetadataEntry.value.codec = codecRegistry.get(
					fieldsMap.get(fieldMetadataEntry.key).type
				) as Codec<Object>
			}
			needsInit = false
		}
	}

	protected def HashMap<String, Field> addBeanClassFieldsToMap(HashMap<String, Field> fieldsMap, Class<?> clazz) {
		if (clazz != MongoBean) {
			fieldsMap.addBeanClassFieldsToMap(clazz.superclass)
		}
		for (field : clazz.declaredFields) {
			fieldsMap.put(field.name, field)
		}
		return fieldsMap
	}

	override encode(BsonWriter writer, T value, EncoderContext encoderContext) {
		checkInit

		writer.writeStartDocument

		value.observeFields [ fieldName, fieldValue |
			if (fieldValue !== null) {
				writer.writeName(fieldName)
				encoderContext.encodeWithChildContext(fieldMetadataLookup.get(fieldName).codec, writer, fieldValue)
			}
		]

		writer.writeEndDocument
	}

	override decode(BsonReader reader, DecoderContext decoderContext) {
		checkInit

		val result = constructor.newInstance
		reader.readStartDocument

		while (reader.readBsonType != BsonType.END_OF_DOCUMENT) {
			val fieldMetadata = fieldMetadataLookup.get(reader.readName)
			fieldMetadata.setter.apply(
				result,
				fieldMetadata.codec.decode(reader, decoderContext)
			)
		}

		reader.readEndDocument
		return result
	}

	override documentHasId(T document) { return document._id !== null }

	override generateIdIfAbsentFromDocument(T document) {
		if (!document.documentHasId) {
			document._id = new BsonObjectId(new ObjectId)
		}
		return document
	}

	override getDocumentId(T document) { return document._id }
}
