package net.opensorcerers.mongoframework.lib

import net.opensorcerers.mongoframework.lib.filter.FilterExpression
import org.bson.codecs.Codec
import org.bson.codecs.configuration.CodecProvider
import org.bson.codecs.configuration.CodecRegistry
import net.opensorcerers.mongoframework.lib.filter.FilterExpressionCodec

class MongoBeanCodecProvider implements CodecProvider {
	override <T> get(Class<T> clazz, CodecRegistry registry) {
		if (MongoBean.isAssignableFrom(clazz)) {
			return new MongoBeanCodec(registry, clazz as Class<?>)
		}

		if (clazz == FilterExpression) {
			return new FilterExpressionCodec(registry) as Codec<T>
		}

		return null
	}
}
