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
import com.google.gwt.user.client.Timer

@Accessors(PUBLIC_GETTER) class ClientEntryPoint implements EntryPoint {
	static VertxEventBus eventBus
	LoginWidget loginWidget

	def getSessionId() { Cookies.getCookie("JSESSIONID") }

	override onModuleLoad() {
		ChainReaction.chain [
			val connectingElement = new Paragraph(
				"Connecting... if this takes more than a few seconds, there is probably a server error."
			)
			RootPanel.get.add(connectingElement)
			val chainHolder = ifSuccessful[RootPanel.get.remove(connectingElement)]
			if (eventBus === null || eventBus.state !== 1) {
				eventBus = new VertxEventBus(
					"http://" + Window.Location.hostName + ":" + EventBusConstants.port + EventBusConstants.path,
					new Object
				)
				eventBus.defaultHeaders = #{
					HeaderConstants.sessionId -> Cookies.getCookie("JSESSIONID")
				}.toJSO
				eventBus.onConnectionClosed = [
					Console.log("EVENT BUS CLOSED")
					RootPanel.get.add(new Paragraph => [text = "Event bus closed"])
				]
				eventBus.onError = [
					Console.log("EVENT BUS ERROR: " + it)
				]
				eventBus.onConnectionOpened = [
					Console.log("EVENT BUS OPENED")
					chainHolder.onSuccess(new ResponseOrError)
					([Console.log("0 seconds after EVENT BUS OPENED")] as Timer).schedule(0)
				]Console.log("Created event bus")
					([Console.log("0 seconds after Creating event bus")] as Timer).schedule(0)
			} else {
				chainHolder.onSuccess(new ResponseOrError)
			}

			ChainReaction.chain [ // TODO: fix this - this shouldn't need to nest.
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
