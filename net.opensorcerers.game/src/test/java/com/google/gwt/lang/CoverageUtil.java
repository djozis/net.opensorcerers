package com.google.gwt.lang;

import com.google.gwt.core.client.JavaScriptObject;

/**
 * This class shadows a GWT class which uses super source only. Prevents compile
 * errors in eclipse. Also added a method to get the coverage.
 */
public class CoverageUtil {
	public static JavaScriptObject coverage;
}
