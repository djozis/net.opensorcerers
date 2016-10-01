package com.davidjozis.gwt.example.client

import com.google.gwt.core.client.EntryPoint
import com.google.gwt.user.client.ui.Label
import com.google.gwt.user.client.ui.RootPanel

class ExampleEntryPoint implements EntryPoint {
	override void onModuleLoad() {
		RootPanel.get.add(new Label("Hello GWT World! Cats!"))
	}
}
