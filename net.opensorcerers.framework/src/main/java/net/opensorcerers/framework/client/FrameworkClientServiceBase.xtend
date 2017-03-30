package net.opensorcerers.framework.client

import com.google.gwt.json.client.JSONArray
import com.google.gwt.json.client.JSONParser
import com.google.gwt.json.client.JSONValue
import com.google.gwt.user.client.Cookies
import com.google.gwt.user.client.rpc.AsyncCallback
import java.io.ByteArrayOutputStream
import java.io.Closeable
import java.io.IOException
import java.io.PrintStream
import net.opensorcerers.framework.client.vertx.VertxEventBus
import net.opensorcerers.framework.client.vertx.VertxHandler
import org.eclipse.xtext.xbase.lib.Procedures.Procedure3

abstract class FrameworkClientServiceBase {
	protected def String getAddress()

	protected def Procedure3<? extends FrameworkClientServiceBase, JSONArray, AsyncCallback<JSONValue>>[] getMethodConsumers()

	protected def static <T extends FrameworkClientServiceBase> void handleMessage(T it, JSONArray message,
		AsyncCallback<JSONValue> resultCallback) {
		val methodConsumers = methodConsumers
		val methodIndex = message.get(0).number.doubleValue as int
		if (methodIndex < 0 || methodIndex >= methodConsumers.length) {
			throw new IllegalArgumentException(
				"Tried to call method #" + methodIndex + " on " + class.name + " which has only has methods #0 .. #" +
					(methodConsumers.length - 1)
			)
		}
		(methodConsumers.get(
			methodIndex
		) as Procedure3<FrameworkClientServiceBase, JSONArray, AsyncCallback<JSONValue>>).apply(
			it,
			message,
			resultCallback
		)
	}

	def addToEventBus(VertxEventBus eventBus) {
		val fullAddress = Cookies.getCookie("JSESSIONID") + address
		val VertxHandler<String> handler = [ error, message |
			val resultCallback = new AsyncCallback<JSONValue> {
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

				override onSuccess(JSONValue result) {
					if (canCall) {
						canCall = false
						message.reply(result.toString)
					}
				}
			}
			try {
				this.handleMessage(JSONParser.parseStrict(message.body).array, resultCallback)
			} catch (Throwable e) {
				resultCallback.onFailure(e)
			}
		]

		eventBus.registerHandler(fullAddress, handler)
		return new Closeable {
			override close() throws IOException {
				eventBus.unregisterHandler(fullAddress, handler)
			}
		}
	}
}
