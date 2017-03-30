package net.opensorcerers.mongoframework.lib

import java.util.HashMap
import org.bson.BsonDocument
import org.bson.BsonDocumentWriter
import org.bson.BsonObjectId
import org.bson.codecs.Codec
import org.bson.codecs.EncoderContext
import org.bson.codecs.configuration.CodecRegistry
import org.bson.conversions.Bson
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.xbase.lib.Procedures.Procedure2

@Accessors class MongoBean implements Bson {
	BsonObjectId _id // MUST be called _id for Mongo/collectible codec.

	override <TDocument> toBsonDocument(Class<TDocument> documentClass, CodecRegistry codecRegistry) {
		val document = new BsonDocument
		val codec = codecRegistry.get(class) as Codec<MongoBean>
		codec.encode(
			new BsonDocumentWriter(document),
			this,
			EncoderContext.builder.isEncodingCollectibleDocument(documentClass.isAssignableFrom(class)).build
		)
		return document
	}

	protected def observeFields((String, Object)=>void observer) {
		observer.apply("_id", this._id) // MUST always come first for collectible codec.
	}

	def static HashMap<String, Procedure2<? extends MongoBean, ?>> createFieldSettersLookup() {
		val result = new HashMap<String, Procedure2<? extends MongoBean, ?>>
		result.put("_id")[it, BsonObjectId value|it._id = value]
		return result
	}
}
