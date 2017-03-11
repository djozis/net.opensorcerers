package net.opensorcerers.framework.client.vertx

import jsinterop.annotations.JsFunction

@JsFunction interface VertxHandler<T> {
	def void onMessageReceived(Object error, VertxMessage<T> message)
}
