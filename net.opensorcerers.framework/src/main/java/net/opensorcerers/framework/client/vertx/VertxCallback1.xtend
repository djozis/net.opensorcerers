package net.opensorcerers.framework.client.vertx

import jsinterop.annotations.JsFunction
import com.google.gwt.core.client.JavaScriptObject

@JsFunction interface VertxCallback1 {
	def void apply(JavaScriptObject it)
}
