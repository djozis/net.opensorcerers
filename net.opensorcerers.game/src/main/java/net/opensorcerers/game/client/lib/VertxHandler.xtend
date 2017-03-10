package net.opensorcerers.game.client.lib

import jsinterop.annotations.JsFunction;

@JsFunction interface VertxHandler<T> {
	def void onMesssageReceived(Object error, VertxMessage<T> message)
}
