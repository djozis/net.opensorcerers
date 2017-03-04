package net.opensorcerers.game.client

import com.google.gwt.core.client.GWT
import com.google.gwt.user.client.ui.Label
import com.google.gwt.user.client.ui.RootPanel
import net.opensorcerers.game.client.lib.ChainReaction
import net.opensorcerers.game.shared.HelloWorldService
import net.opensorcerers.game.shared.HelloWorldServiceAsync

class ClientEntryPoint extends ChainedEntryPoint {
	HelloWorldServiceAsync helloWorldService = GWT.create(HelloWorldService)

	override addOnLoad(extension ChainReaction chain) {
		return andThen[
			helloWorldService.getMessage(chainCallback [
				RootPanel.get.add(new Label(it))
			])
		]
	}
}
