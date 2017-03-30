package net.opensorcerers.framework.shared

import com.google.gwt.json.client.JSONValue

interface StaticallyJsonSerializable {
	@Pure def JSONValue serializeToJsonClient()

	def StaticallyJsonSerializable deserializeFromJsonClient(JSONValue jsonValue) 
}
