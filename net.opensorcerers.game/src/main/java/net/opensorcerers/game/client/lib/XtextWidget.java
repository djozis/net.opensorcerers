package net.opensorcerers.game.client.lib;

import com.google.gwt.core.client.GWT;
import com.google.gwt.dom.client.DivElement;
import com.google.gwt.dom.client.Document;
import com.google.gwt.user.client.ui.Widget;

/**
 * Requires webjars/requirejs/2.3.2/require.min.js to be loaded already on top
 * level window.
 */
public class XtextWidget extends Widget {
	public XtextWidget() {
		DivElement divElement = Document.get().createDivElement();
		divElement.setClassName("xtext-editor");
		divElement.setAttribute("data-editor-xtext-lang", "autology");
		setElement(divElement);
	}

	private boolean initialized = false;

	@Override
	public void onAttach() {
		super.onAttach();
		if (!initialized) {
			init("/" + GWT.getHostPageBaseURL().split("//", 2)[1].split("/", 2)[1]);
			initialized = true;
		}
	}

	public native XtextWidget init(String baseUrl) /*-{
		var widget = this
		var element = this.@com.google.gwt.user.client.ui.Widget::getElement()();
		$wnd.require.config({
			baseUrl : baseUrl,
			paths : {
				"jquery" : "webjars/jquery/2.2.4/jquery",
				"ace/ext/language_tools" : "webjars/ace/1.2.3/src/ext-language_tools",
				"xtext/xtext-ace" : "xtext/2.11.0/xtext-ace"
			}
		});
		$wnd.require([ "jquery", "webjars/ace/1.2.3/src/ace" ], function(jq) {
			console.log("DID IT")
			console.log(jq)
			$wnd.require([ "xtext/xtext-ace" ], function(xtext) {
				widget.editor = xtext.createEditor({
					parent : element,
					baseUrl : baseUrl,
					syntaxDefinition : "xtext-resources/generated/mode-autology"
				});
			});
		});
		return this;
	}-*/;
}
