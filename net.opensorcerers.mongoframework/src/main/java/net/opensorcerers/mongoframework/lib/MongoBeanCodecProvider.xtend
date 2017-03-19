package net.opensorcerers.mongoframework.lib

import net.opensorcerers.mongoframework.lib.filter.FilterExpression
import net.opensorcerers.mongoframework.lib.filter.FilterExpressionEncoder
import org.bson.codecs.Codec
import org.bson.codecs.configuration.CodecProvider
import org.bson.codecs.configuration.CodecRegistry

class MongoBeanCodecProvider implements CodecProvider {
	override <T> get(Class<T> clazz, CodecRegistry registry) {
		if (MongoBean.isAssignableFrom(clazz)) {
			return new MongoBeanCodec(registry, clazz as Class<?>)
		}

		if (clazz == FilterExpression) {
			return new FilterExpressionEncoder(registry) as Codec<T>
		}

		return null
	}
}
