package net.opensorcerers.game.client.lib;

public class Console {
	public static native void log(Object object) /*-{
		console.log(object)
	}-*/;
}
