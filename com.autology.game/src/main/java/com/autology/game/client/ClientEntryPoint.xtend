package com.autology.game.client

import com.autology.game.client.lib.XtextWidget
import com.autology.game.shared.HelloWorldService
import com.autology.game.shared.HelloWorldServiceAsync
import com.google.gwt.core.client.EntryPoint
import com.google.gwt.core.client.GWT
import com.google.gwt.user.client.ui.RootPanel

import static com.autology.game.client.lib.AsyncCallbackExtensions.*

class ClientEntryPoint implements EntryPoint {
	HelloWorldServiceAsync helloWorldService = GWT.create(HelloWorldService)

	override void onModuleLoad() {
		helloWorldService.getMessage(withResult [
			RootPanel.get.add(new XtextWidget())
		])
	}
}
