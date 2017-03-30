package net.opensorcerers.framework.client.vertx

import jsinterop.annotations.JsFunction

@JsFunction interface VertxSimpleCallback {
	def void apply()
}
