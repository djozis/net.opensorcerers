package net.opensorcerers.game.client

import com.google.gwt.core.client.EntryPoint
import com.google.gwt.user.client.ui.RootPanel
import net.opensorcerers.game.client.lib.chainreaction.ChainReaction
import org.eclipse.xtend.lib.annotations.Accessors
import org.gwtbootstrap3.client.ui.Label

@Accessors(PUBLIC_GETTER) class ClientEntryPoint implements EntryPoint {
	LoginWidget loginWidget

	override onModuleLoad() {
		ChainReaction.chain [
			RootPanel.get.add(loginWidget = new LoginWidget [
				RootPanel.get.add(new Label("SUCCESS"))
			])
		]
	}
}
