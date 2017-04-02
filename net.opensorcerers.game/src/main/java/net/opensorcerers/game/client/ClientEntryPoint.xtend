package net.opensorcerers.game.client

import com.google.gwt.core.client.EntryPoint
import com.google.gwt.user.client.Cookies
import com.google.gwt.user.client.ui.RootPanel
import net.opensorcerers.framework.client.vertx.VertxEventBus
import net.opensorcerers.game.client.lib.Console
import net.opensorcerers.game.client.lib.EventBusFactory
import net.opensorcerers.game.client.lib.chainreaction.ChainReaction
import net.opensorcerers.game.shared.ResponseOrError
import org.eclipse.xtend.lib.annotations.Accessors
import org.gwtbootstrap3.client.ui.PanelBody
import org.gwtbootstrap3.client.ui.html.Paragraph

@Accessors(PUBLIC_GETTER) class ClientEntryPoint implements EntryPoint {
	static VertxEventBus eventBus = null
	LoginWidget loginWidget

	def getSessionId() { Cookies.getCookie("JSESSIONID") }

	PanelBody mainDiv

	override onModuleLoad() {
		ChainReaction.chain [
			if (eventBus === null || eventBus.state != 1) {
				val connectingElement = new Paragraph(
					"Connecting... if this takes more than a few seconds, there is probably a server error."
				)
				RootPanel.get.add(connectingElement)
				val chainHolder = ifSuccessful[RootPanel.get.remove(connectingElement)]
				new EventBusFactory().createEventBus [
					eventBus = it
					Console.log("Event bus opened")
					chainHolder.onSuccess(new ResponseOrError)
				]
			}

			ChainReaction.chain [ // TODO: fix this - this shouldn't need to nest.
				eventBus.onConnectionClosed = [
					Console.log("Event bus closed")
					RootPanel.get.add(new Paragraph => [text = "Event bus closed"])
				]
				eventBus.onError = [Console.log("Event bus error: " + it)]

				RootPanel.get.add(mainDiv = new PanelBody)

				mainDiv.add(loginWidget = new LoginWidget(eventBus) [
					mainDiv.add(new CharacterSelectWidget(eventBus) [
						mainDiv.add(new CharacterWidget(eventBus, it.name))
					])
				])
			]
		]
	}
}
