package net.opensorcerers.framework.client.vertx

import jsinterop.annotations.JsProperty
import jsinterop.annotations.JsType

@JsType(isNative=true, namespace="<global>" /*JsPackage.GLOBAL*/ )
class VertxError {
	@JsProperty public int failureCode
	@JsProperty public String failureType
	@JsProperty public String message
}
