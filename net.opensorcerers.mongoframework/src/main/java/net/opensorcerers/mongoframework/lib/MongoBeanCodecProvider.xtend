package net.opensorcerers.mongoframework.lib

import net.opensorcerers.mongoframework.lib.filter.FilterExpression
import net.opensorcerers.mongoframework.lib.filter.FilterExpressionCodec
import net.opensorcerers.mongoframework.lib.project.ProjectStatement
import net.opensorcerers.mongoframework.lib.project.ProjectStatementCodec
import net.opensorcerers.mongoframework.lib.project.ProjectStatementList
import net.opensorcerers.mongoframework.lib.project.ProjectStatementListCodec
import net.opensorcerers.mongoframework.lib.update.UpdateStatement
import net.opensorcerers.mongoframework.lib.update.UpdateStatementCodec
import net.opensorcerers.mongoframework.lib.update.UpdateStatementList
import net.opensorcerers.mongoframework.lib.update.UpdateStatementListCodec
import org.bson.codecs.Codec
import org.bson.codecs.configuration.CodecProvider
import org.bson.codecs.configuration.CodecRegistry

class MongoBeanCodecProvider implements CodecProvider {
	override <T> get(Class<T> clazz, CodecRegistry registry) {
		if (MongoBean.isAssignableFrom(clazz)) {
			return new MongoBeanCodec(registry, clazz as Class<?>)
		}

		switch (clazz) {
			case FilterExpression: return new FilterExpressionCodec(registry) as Codec<T>
			case UpdateStatement: return new UpdateStatementCodec(registry) as Codec<T>
			case UpdateStatementList: return new UpdateStatementListCodec(registry) as Codec<T>
			case ProjectStatement: return new ProjectStatementCodec(registry) as Codec<T>
			case ProjectStatementList: return new ProjectStatementListCodec(registry) as Codec<T>
		}

		return null
	}
}
