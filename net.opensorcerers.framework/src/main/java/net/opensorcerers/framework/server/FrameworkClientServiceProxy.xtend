package net.opensorcerers.framework.server

import com.google.gson.JsonArray
import com.google.gson.JsonElement
import com.google.gson.JsonParser
import com.google.gwt.user.client.rpc.AsyncCallback
import io.vertx.core.eventbus.EventBus
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor abstract class FrameworkClientServiceProxy {
	val EventBus eventBus
	val String sessionId

	protected def String getAddress()

	protected def void sendRequest(JsonArray jsonArray, AsyncCallback<JsonElement> responseHandler) {
		eventBus.<String>send(sessionId + address, jsonArray.toString) [
			if (cause !== null || result.body === null) {
				responseHandler.onFailure(new IllegalStateException(
					cause.class.simpleName + " in " + class.name + ": " + cause.message,
					cause
				))
			} else {
				responseHandler.onSuccess(new JsonParser().parse(result.body))
			}
		]
	}
}
