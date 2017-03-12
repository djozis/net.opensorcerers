package net.opensorcerers.framework.client;

public class Console {
	public static native void log(Object object) /*-{
		console.log(object)
	}-*/;
}
