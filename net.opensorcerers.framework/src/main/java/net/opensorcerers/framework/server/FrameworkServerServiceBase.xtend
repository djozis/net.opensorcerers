package net.opensorcerers.framework.server

import com.google.gson.JsonArray
import com.google.gson.JsonParser
import com.google.gwt.user.client.rpc.AsyncCallback
import io.vertx.core.AbstractVerticle
import io.vertx.core.eventbus.Message
import io.vertx.core.eventbus.MessageConsumer
import java.io.ByteArrayOutputStream
import java.io.PrintStream
import java.util.function.BiConsumer
import com.google.gson.JsonElement

abstract class FrameworkServerServiceBase extends AbstractVerticle {
	protected def String getAddress()

	protected def BiConsumer<JsonArray, AsyncCallback<JsonElement>>[] getMethodConsumers()

	var MessageConsumer<?> consumer

	protected def void handleMessage(JsonArray message, AsyncCallback<JsonElement> resultCallback) {
		val methodConsumers = methodConsumers
		val methodIndex = message.get(0).asInt
		if (methodIndex < 0 || methodIndex >= methodConsumers.length) {
			throw new IllegalArgumentException(
				'''Tried to call method #«methodIndex» on «class.name» which has only has methods #0 .. #«methodConsumers.length-1»'''
			)
		}
		methodConsumers.get(methodIndex).accept(message, resultCallback)
	}

	override void start() {
		consumer = vertx.eventBus.consumer(address) [ Message<String> message |
			val resultCallback = new AsyncCallback<JsonElement> {
				boolean canCall = true

				override onFailure(Throwable caught) {
					if (canCall) {
						canCall = false
						message.fail(
							500,
							(new ByteArrayOutputStream => [
								caught.printStackTrace(new PrintStream(it))
							]).toString("UTF-8")
						)
					}
				}

				override onSuccess(JsonElement result) {
					if (canCall) {
						canCall = false
						message.reply(result.toString)
					}
				}
			}
			try {
				handleMessage(new JsonParser().parse(message.body).asJsonArray, resultCallback)
			} catch (Throwable e) {
				resultCallback.onFailure(e)
			}
		]
	}

	override void stop() { consumer.unregister }
}
