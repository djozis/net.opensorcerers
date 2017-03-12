package net.opensorcerers.game.server

import io.vertx.core.AbstractVerticle
import io.vertx.core.json.JsonObject
import io.vertx.ext.web.Router
import io.vertx.ext.web.handler.BodyHandler
import io.vertx.ext.web.handler.ErrorHandler
import io.vertx.ext.web.handler.sockjs.BridgeOptions
import io.vertx.ext.web.handler.sockjs.PermittedOptions
import io.vertx.ext.web.handler.sockjs.SockJSHandler
import javax.xml.ws.Holder

class HelloWorldServiceVerticle extends AbstractVerticle {
	override void start() {
		val router = Router.router(vertx);

		router.route("/world/*").handler(eventBusHandler());
		router.mountSubRouter("/api", auctionApiRouter());
		router.route().failureHandler(errorHandler());
		vertx.eventBus.consumer("greet") [ message |
			message.reply("Greet from Vert.x with: " + message.body)
		]

		vertx.createHttpServer().requestHandler[router.accept(it)].listen(17632)
	}

	private def errorHandler() { return ErrorHandler.create }

	private def SockJSHandler eventBusHandler() {
		return SockJSHandler.create(vertx).bridge(new BridgeOptions => [
			addOutboundPermitted(new PermittedOptions => [
				addressRegex = ".*"
			])
			addInboundPermitted(new PermittedOptions => [
				addressRegex = ".*"
			])
		]) [ event |
			switch event.type {
				case SOCKET_CREATED: {
					println("A socket was created")
				}
				default: {
				}
			}
			event.complete(true)
		] => [ handler |
			handler.socketHandler [ socket |
				socket.headers.add("Access-Control-Allow-Origin", "*")
			]
		]
	}

	private def Router auctionApiRouter() {
		val router = Router.router(vertx);
		router.route().handler(BodyHandler.create());

		// router.route().consumes("application/json");
		router.route().produces("application/json");

		router.get("/zz").handler [ context |
			context.vertx.eventBus().<String>send("world", new JsonObject => [
				it.put("a", "cats")
				it.put("b", "dogs")
			]) [
				println(result ?: cause)
			]

			context.response.write("").setStatusCode(200).end
		]

		return router;
	}
}
