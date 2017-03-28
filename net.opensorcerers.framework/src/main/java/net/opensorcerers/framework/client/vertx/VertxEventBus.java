package net.opensorcerers.framework.client.vertx;

import com.google.gwt.core.client.JavaScriptObject;

import jsinterop.annotations.JsPackage;
import jsinterop.annotations.JsProperty;
import jsinterop.annotations.JsType;

@JsType(isNative = true, name = "EventBus", namespace = JsPackage.GLOBAL)
public class VertxEventBus {
	public VertxEventBus(String url, Object options) {
	}

	public native <T> void registerHandler(String address, VertxHandler<T> handler);

	public native <T> void unregisterHandler(String address, VertxHandler<T> handler);

	public native <T> void send(String address, Object message, Object headers, VertxHandler<T> callback);

	@JsProperty(name = "onopen")
	public VertxSimpleCallback onConnectionOpened;
	@JsProperty(name = "onclose")
	public VertxCallback1 onConnectionClosed;
	@JsProperty(name = "onerror")
	public VertxCallback1 onError;

	@JsProperty(name = "state")
	public JavaScriptObject state;

	@JsProperty
	public JavaScriptObject defaultHeaders;
}