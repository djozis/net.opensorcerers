package net.opensorcerers.framework.shared

import io.vertx.core.AbstractVerticle
import io.vertx.core.eventbus.MessageConsumer
import java.lang.reflect.Method
import java.util.Map
import java.util.ArrayList
import io.vertx.core.eventbus.MessageCodec
import io.vertx.core.buffer.Buffer

abstract class GwtVertxServerServiceBase extends AbstractVerticle {
	def String getAddress()

	var MessageConsumer<?> consumer

	var Map<String, Method> methodLookup

	override void start() {
		consumer = vertx.eventBus.consumer(address) [ message |
			message.reply("Greet from Vert.x with: " + message.body)
			vertx.eventBus.<String>send("world", "World from Vert.x! " + message.body) [
				println(result?.body ?: cause)
			]
		]
	}

	override void stop() { consumer.unregister }
}
