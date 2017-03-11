package net.opensorcerers.framework.client.vertx

import jsinterop.annotations.JsProperty
import jsinterop.annotations.JsType

@JsType(isNative=true, namespace="<global>" /*JsPackage.GLOBAL*/ )
class VertxMessage<T> {
	@JsProperty public T body

	def native <T> void reply(Object message, Object headers, VertxHandler<T> handler);

	def native <T> void reply(Object message);
}
