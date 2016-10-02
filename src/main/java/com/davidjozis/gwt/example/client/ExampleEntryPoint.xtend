package com.davidjozis.gwt.example.client

import com.davidjozis.gwt.example.shared.HelloWorldService
import com.google.gwt.core.client.EntryPoint
import com.google.gwt.core.client.GWT
import com.google.gwt.user.client.ui.Label
import com.google.gwt.user.client.ui.RootPanel
import com.davidjozis.gwt.example.shared.HelloWorldServiceAsync

import static com.davidjozis.gwt.example.lib.AsyncCallbackExtensions.*

class ExampleEntryPoint implements EntryPoint {
	HelloWorldServiceAsync helloWorldService = GWT.create(HelloWorldService)

	override void onModuleLoad() {
		helloWorldService.getMessage(onSuccess[
			RootPanel.get.add(new Label(it))
		])
	}
}
