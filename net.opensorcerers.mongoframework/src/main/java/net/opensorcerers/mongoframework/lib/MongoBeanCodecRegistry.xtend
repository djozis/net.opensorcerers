package net.opensorcerers.mongoframework.lib

import org.bson.codecs.BsonValueCodecProvider
import org.bson.codecs.DocumentCodecProvider
import org.bson.codecs.ValueCodecProvider
import org.bson.codecs.configuration.CodecProvider
import org.bson.codecs.configuration.CodecRegistries

class MongoBeanCodecRegistry {
	def static create(CodecProvider... providers) {
		return CodecRegistries.fromProviders(
			#[
				new MongoBeanCodecProvider,
				new ValueCodecProvider,
				new DocumentCodecProvider,
				new BsonValueCodecProvider
			] + providers
		)
	}
}
