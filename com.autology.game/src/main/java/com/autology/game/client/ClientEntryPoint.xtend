package com.autology.game.client

import com.autology.game.client.lib.ChainReaction
import com.autology.game.shared.HelloWorldService
import com.autology.game.shared.HelloWorldServiceAsync
import com.google.gwt.core.client.EntryPoint
import com.google.gwt.core.client.GWT
import com.google.gwt.user.client.ui.Label
import com.google.gwt.user.client.ui.RootPanel

class ClientEntryPoint implements EntryPoint {
	HelloWorldServiceAsync helloWorldService = GWT.create(HelloWorldService)

	override void onModuleLoad() { addOnLoad(new ChainReaction).start }

	def addOnLoad(extension ChainReaction chain) {
		return andThen[
			helloWorldService.getMessage(chainCallback [
				RootPanel.get.add(new Label(it))
			])
		]
	}
}
