package net.opensorcerers.framework.client

import com.google.gwt.core.client.JavaScriptObject
import com.google.gwt.json.client.JSONArray
import net.opensorcerers.framework.client.vertx.VertxEventBus
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor abstract class FrameworkServerServiceProxy {
	val VertxEventBus eventBus

	protected def String getAddress()

	protected def void sendRequest(JSONArray jsonArray, (Object, JSONArray)=>void responseHandler) {
		eventBus.<JavaScriptObject>send(address, jsonArray, null) [ error, message |
			if (error !== null || message.body === null) {
				responseHandler.apply(error, null)
			} else if (message.body === null) {
				responseHandler.apply(error, new JSONArray(message.body))
			}
		]
	}
}
