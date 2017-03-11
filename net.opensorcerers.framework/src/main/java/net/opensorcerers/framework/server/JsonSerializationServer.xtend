package net.opensorcerers.framework.server

import com.google.gson.JsonArray
import com.google.gson.JsonElement
import com.google.gson.JsonNull
import com.google.gson.JsonPrimitive
import java.util.Collection

class JsonSerializationServer {
	static val TRUE_JSON = new JsonPrimitive(1)
	static val FALSE_JSON = new JsonPrimitive(0)

	def static serialize(boolean value) { return if(value) TRUE_JSON else FALSE_JSON }

	def static serialize(Boolean value) { return value.booleanValue.serialize }

	def static deserializeBoolean(JsonElement value) { return value.asInt != 0 }

	def static serialize(int value) { return new JsonPrimitive(value) }

	def static deserializeint(JsonElement value) { return value.asInt as int }

	def static serialize(Integer value) { return value.intValue.serialize }

	def static deserializeInteger(JsonElement value) { return value.deserializeint }

	def static serialize(String value) { return new JsonPrimitive(value) }

	def static deserializeString(JsonElement value) { return value.asString }

	def static <T> serializeIterable(Iterable<T> values, (T)=>JsonElement mapper) {
		val result = new JsonArray
		for (value : values) {
			if (value === null) {
				result.add(JsonNull.INSTANCE)
			} else {
				result.add(mapper.apply(value))
			}
		}
		return result
	}

	def static <T, C extends Collection<T>> deserializeIterable(JsonElement values, (JsonElement)=>T mapper, C output) {
		for (value : values.asJsonArray) {
			if (value === null || value.isJsonNull) {
				output.add(null)
			} else {
				output.add(mapper.apply(value))
			}
		}
		return output
	}
}
