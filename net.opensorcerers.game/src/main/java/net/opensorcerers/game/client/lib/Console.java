package net.opensorcerers.game.client.lib;

import com.google.gwt.core.client.JavaScriptObject;

public class Console {
	public static native void log(Object object) /*-{
		console.log(object)
	}-*/;
}
