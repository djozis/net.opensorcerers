package net.opensorcerers.game.client;

public class TestJavascriptHooks {
	public static native String getGwtCoverageJsonString() /*-{
		return $wnd.JSON.stringify(@com.google.gwt.lang.CoverageUtil::coverage)
	}-*/;
}
