package net.opensorcerers.game.client

import com.google.gwt.core.client.EntryPoint
import com.google.gwt.user.client.Cookies
import com.google.gwt.user.client.Window
import com.google.gwt.user.client.rpc.AsyncCallback
import com.google.gwt.user.client.ui.RootPanel
import net.opensorcerers.framework.client.vertx.VertxEventBus
import net.opensorcerers.framework.shared.HeaderConstants
import net.opensorcerers.game.client.lib.Console
import net.opensorcerers.game.client.lib.chainreaction.ChainReaction
import net.opensorcerers.game.client.services.TestClassProxy
import net.opensorcerers.game.shared.EventBusConstants
import net.opensorcerers.game.shared.ResponseOrError
import org.eclipse.xtend.lib.annotations.Accessors
import org.gwtbootstrap3.client.ui.Label
import org.gwtbootstrap3.client.ui.html.Paragraph

import static extension net.opensorcerers.game.client.lib.ClientExtensions.*

@Accessors(PUBLIC_GETTER) class ClientEntryPoint implements EntryPoint {
	VertxEventBus eventBus
	LoginWidget loginWidget

	def getSessionId() { Cookies.getCookie("JSESSIONID") }

	override onModuleLoad() {
		Console.log("Entry: 1")
		ChainReaction.chain [
		Console.log("Entry: 2")
			val connectingElement = new Paragraph(
				"Connecting... if this takes more than a few seconds, there is probably a server error."
			)
		Console.log("Entry: 3")
			RootPanel.get.add(connectingElement)
		Console.log("Entry: 4")
		Console.log("Go for: "+"http://" + Window.Location.hostName + ":" + EventBusConstants.port + EventBusConstants.path)
			eventBus = new VertxEventBus(
				"http://" + Window.Location.hostName + ":" + EventBusConstants.port + EventBusConstants.path,
				new Object
			)
		Console.log("Entry: 5")
		Console.log("Entry: ")
			eventBus.defaultHeaders = #{
				HeaderConstants.sessionId -> Cookies.getCookie("JSESSIONID")
			}.toJSO
		Console.log("Entry: 6")
			eventBus.onConnectionClosed = [
				Console.log("EVENT BUS CLOSED")
				Console.log(it)
				Console.log("STRINGED")
				Console.log(Console.stringify(it))
				Console.log("REASON")
				Console.log(Console.reason(it))
				Console.log("ENDIT")
				RootPanel.get.add(new Paragraph => [text = "Event bus closed"])
			]
			eventBus.onError = [
				Console.log("EVENT BUS ERROR")
				Console.log(it)
				Console.log("ENDERRORIT")
			]
		Console.log("Entry: 7")
			val chainHolder = ifSuccessful[RootPanel.get.remove(connectingElement)]
		Console.log("Entry: 8")
			eventBus.onConnectionOpened = [Console.log("EVENT BUS OPENED")chainHolder.onSuccess(new ResponseOrError)]
		Console.log("Entry: 9")
		Console.log("Entry STATE: "+eventBus.state)
				
			ChainReaction.chain [ // TODO: fix this - this shouldn't need to nest.
			Console.log("Widgetting")
				RootPanel.get.add(loginWidget = new LoginWidget(eventBus) [
					RootPanel.get.add(new Label("SUCCESS"))
				])
				new TestClassProxy(eventBus).sayHello(sessionId, new AsyncCallback<String> {
					override onFailure(Throwable caught) {
						RootPanel.get.add(new Paragraph("Error: " + caught.stacktrace))
					}

					override onSuccess(String result) {
						RootPanel.get.add(new Paragraph(result))
					}
				})
			]
		]
	}
}
