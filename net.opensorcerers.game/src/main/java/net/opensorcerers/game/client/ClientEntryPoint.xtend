package net.opensorcerers.game.client

import com.google.gwt.core.client.EntryPoint
import com.google.gwt.user.client.ui.RootPanel
import net.opensorcerers.framework.client.vertx.VertxEventBus
import net.opensorcerers.game.client.lib.Console
import net.opensorcerers.game.client.lib.chainreaction.ChainReaction
import net.opensorcerers.game.shared.TestPOJO
import org.eclipse.xtend.lib.annotations.Accessors
import org.gwtbootstrap3.client.ui.Label
import org.gwtbootstrap3.client.ui.html.Paragraph

@Accessors(PUBLIC_GETTER) class ClientEntryPoint implements EntryPoint {
	LoginWidget loginWidget

	override onModuleLoad() {
		ChainReaction.chain [
			RootPanel.get.add(loginWidget = new LoginWidget [
				RootPanel.get.add(new Label("SUCCESS"))
			])
			new VertxEventBus("http://localhost:17632/world", new Object) => [ eventBus |
				eventBus.onConnectionClosed = [
					RootPanel.get.add(new Paragraph => [
						text = "Vertx event bus closed"
					])
				]
				eventBus.onConnectionOpened = [
					RootPanel.get.add(new Paragraph => [
						text = "Vertx event bus opened"
					])
					eventBus.<TestPOJO>registerHandler("world") [ error, message |
						Console.log("World handler:")
						Console.log(message.body)
						RootPanel.get.add(new Paragraph => [text = message.body.toString])
						message.reply("I heard you on world")
					]
					eventBus.<String>send("greet", "Client says hi", null) [ error, message |
						Console.log("Greet response:")
						Console.log(message)
					]
				]
			]
		]
	}
}
