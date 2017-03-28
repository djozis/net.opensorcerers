package net.opensorcerers.game.client.lib;

import com.google.gwt.core.client.JavaScriptObject;

public class Console {
	public static native void log(Object object) /*-{
		console.log(object)
	}-*/;
	public static native String stringify(JavaScriptObject jso) /*-{
	  return JSON.stringify(jso);
	}-*/;
	public static native String reason(JavaScriptObject jso) /*-{
	  return jso.reason;
	}-*/;
}
