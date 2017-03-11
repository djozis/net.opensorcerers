package net.opensorcerers.framework.shared

import com.google.gwt.json.client.JSONValue

interface JsonSerializableMethods {
	@Pure def JSONValue serializeToJsonClient()

	def JsonSerializableMethods deserializeFromJsonClient(JSONValue jsonValue) 
}
