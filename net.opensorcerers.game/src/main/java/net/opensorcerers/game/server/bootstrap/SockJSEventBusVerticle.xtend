package net.opensorcerers.game.server.bootstrap

import io.vertx.core.AbstractVerticle
import io.vertx.ext.web.Router
import io.vertx.ext.web.handler.ErrorHandler
import io.vertx.ext.web.handler.sockjs.BridgeOptions
import io.vertx.ext.web.handler.sockjs.PermittedOptions
import io.vertx.ext.web.handler.sockjs.SockJSHandler
import net.opensorcerers.game.shared.EventBusConstants

class SockJSEventBusVerticle extends AbstractVerticle {
	override void start() {
		val router = Router.router(vertx)

		router.route(EventBusConstants.path + "/*").handler(
			SockJSHandler.create(vertx).bridge(new BridgeOptions => [
				addOutboundPermitted(new PermittedOptions => [
					addressRegex = ".*"
				])
				addInboundPermitted(new PermittedOptions => [
					addressRegex = ".*"
				])
			])[event|
				println("EVENT BUS BRIDGE EVENT: "+event.type + " - " + event.toString)
				event.complete(true)
			] => [ handler |
				handler.socketHandler [ socket |
					socket.headers.add("Access-Control-Allow-Origin", "*")
				]
			]
		)
		router.route.failureHandler(ErrorHandler.create)
		vertx.createHttpServer.requestHandler[router.accept(it)].listen(EventBusConstants.port)
	}
}
