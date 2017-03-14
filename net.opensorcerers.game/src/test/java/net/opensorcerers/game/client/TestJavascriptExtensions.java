package net.opensorcerers.game.client;

public class TestJavascriptExtensions {
	public static native String getGwtCoverageJsonString() /*-{
		return $wnd.JSON.stringify(@com.google.gwt.lang.CoverageUtil::coverage)
	}-*/;

	public static native void disableWebsockets() /*-{
		WebSocket = undefined;
	}-*/;
}
