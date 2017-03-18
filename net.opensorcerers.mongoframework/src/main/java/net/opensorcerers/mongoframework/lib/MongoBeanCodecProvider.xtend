package net.opensorcerers.mongoframework.lib

import org.bson.codecs.configuration.CodecProvider
import org.bson.codecs.configuration.CodecRegistry

class MongoBeanCodecProvider implements CodecProvider {
	override <T> get(Class<T> clazz, CodecRegistry registry) {
		if (MongoBean.isAssignableFrom(clazz)) {
			return new MongoBeanCodec(registry, clazz as Class<?>)
		} else {
			return null
		}
	}
}
