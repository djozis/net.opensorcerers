package net.opensorcerers.game.client

import com.google.gwt.user.client.Cookies
import com.google.gwt.user.client.Timer
import com.google.gwt.user.client.Window
import net.opensorcerers.framework.client.vertx.VertxEventBus
import net.opensorcerers.framework.shared.HeaderConstants
import net.opensorcerers.game.shared.EventBusConstants

import static extension net.opensorcerers.game.client.lib.ClientExtensions.*

class EventBusFactory {
	var timeout = 4000
	var VertxEventBus eventBus = null

	def createEventBus((VertxEventBus)=>void callback) {
		new Timer {
			override run() {
				val expiredEventBus = EventBusFactory.this.eventBus
				val eventBus = EventBusFactory.this.eventBus = new VertxEventBus(
					"http://" + Window.Location.hostName + ":" + EventBusConstants.port + EventBusConstants.path,
					new Object
				)
				eventBus.onConnectionOpened = [
					if (EventBusFactory.this.eventBus == eventBus) {
						this.cancel
						eventBus.defaultHeaders = #{
							HeaderConstants.sessionId -> Cookies.getCookie("JSESSIONID")
						}.toJSO
						callback.apply(eventBus)
					}
				]
				this.schedule(timeout)
				timeout *= 2
				expiredEventBus?.close
			}
		}.run
	}
}
