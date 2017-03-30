package net.opensorcerers.mongoframework.lib.project

import java.util.ArrayList
import org.bson.BsonDocumentWrapper
import org.bson.codecs.configuration.CodecRegistry
import org.bson.conversions.Bson
import org.eclipse.xtend.lib.annotations.Accessors

class ProjectStatementList implements Bson {
	@Accessors(PACKAGE_GETTER) val statements = new ArrayList<ProjectStatement>

	def add(ProjectStatement statement) { statements.add(statement) }

	override <TDocument> toBsonDocument(Class<TDocument> documentClass, CodecRegistry codecRegistry) {
		return new BsonDocumentWrapper(this, codecRegistry.get(ProjectStatementList))
	}
}
