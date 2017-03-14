package net.opensorcerers.game.client.lib;

import com.google.gwt.core.client.JavaScriptObject;

public class JavaClientExtensions {
	public static native void setField(JavaScriptObject jso, String fieldName, Object value) /*-{
		jso[fieldName] = value;
	}-*/;
}
