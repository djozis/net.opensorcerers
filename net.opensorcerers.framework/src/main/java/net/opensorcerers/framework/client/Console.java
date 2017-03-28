package net.opensorcerers.framework.client;

import com.google.gwt.core.client.JavaScriptObject;

public class Console {
	public static native void log(Object object) /*-{
		console.log(object)
	}-*/;
}
