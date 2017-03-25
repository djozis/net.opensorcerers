package net.opensorcerers.framework.client

import com.google.gwt.json.client.JSONArray
import com.google.gwt.json.client.JSONParser
import com.google.gwt.user.client.rpc.AsyncCallback
import net.opensorcerers.framework.client.vertx.VertxEventBus
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import com.google.gwt.json.client.JSONValue

@FinalFieldsConstructor abstract class FrameworkServerServiceProxy {
	val VertxEventBus eventBus

	protected def String getAddress()

	protected def void sendRequest(JSONArray jsonArray, AsyncCallback<JSONValue> responseHandler) {
		eventBus.<String>send(address, jsonArray.toString, null) [ error, message |
			if (error !== null || message.body === null) {
				responseHandler.onFailure(new IllegalStateException(error.message))
			/*
			 * new IllegalStateException(
			 * error.failureType + " in " + class.name + ": " + error.message
			 * ) 
			 */
			} else {
				responseHandler.onSuccess(JSONParser.parseStrict(message.body))
			}
		]
	}
}
