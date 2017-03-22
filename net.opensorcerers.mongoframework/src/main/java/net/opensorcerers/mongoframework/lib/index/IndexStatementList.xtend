package net.opensorcerers.mongoframework.lib.index

import java.util.ArrayList
import org.bson.BsonDocumentWrapper
import org.bson.codecs.configuration.CodecRegistry
import org.bson.conversions.Bson
import org.eclipse.xtend.lib.annotations.Accessors

class IndexStatementList implements Bson {
	@Accessors(PACKAGE_GETTER) val statements = new ArrayList<IndexStatement>

	def add(IndexStatement statement) { statements.add(statement) }

	override <TDocument> toBsonDocument(Class<TDocument> documentClass, CodecRegistry codecRegistry) {
		return new BsonDocumentWrapper(this, codecRegistry.get(IndexStatementList))
	}

	override toString() { return '''{ «statements.map['''«key»: «value»'''].join(", ")» }''' }

	override equals(Object other) {
		if (other instanceof IndexStatementList) {
			return statements.equals(other.statements)
		} else {
			return false
		}
	}
}
