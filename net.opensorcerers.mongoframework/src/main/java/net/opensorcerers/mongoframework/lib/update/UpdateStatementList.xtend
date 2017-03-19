package net.opensorcerers.mongoframework.lib.update

import java.util.ArrayList
import org.bson.BsonDocumentWrapper
import org.bson.codecs.configuration.CodecRegistry
import org.bson.conversions.Bson
import org.eclipse.xtend.lib.annotations.Accessors

class UpdateStatementList implements Bson {
	@Accessors(PACKAGE_GETTER) val statements = new ArrayList<UpdateStatement>

	def add(UpdateStatement statement) { statements.add(statement) }

	override <TDocument> toBsonDocument(Class<TDocument> documentClass, CodecRegistry codecRegistry) {
		return new BsonDocumentWrapper(this, codecRegistry.get(UpdateStatementList))
	}
}
