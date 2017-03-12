package net.opensorcerers.framework.client

import com.google.gwt.json.client.JSONArray
import com.google.gwt.json.client.JSONNull
import com.google.gwt.json.client.JSONNumber
import com.google.gwt.json.client.JSONString
import com.google.gwt.json.client.JSONValue
import java.util.Collection

class JsonSerializationClient {
	static val TRUE_JSON = new JSONNumber(1)
	static val FALSE_JSON = new JSONNumber(0)

	def static serialize(boolean value) { return if(value) TRUE_JSON else FALSE_JSON }

	def static serialize(Boolean value) { return value.booleanValue.serialize }

	def static deserializeBoolean(JSONValue value) { return value.number.doubleValue != 0 }

	def static serialize(int value) { return new JSONNumber(value) }

	def static deserializeint(JSONValue value) { return value.number.doubleValue as int }

	def static serialize(Integer value) { return value.intValue.serialize }

	def static deserializeInteger(JSONValue value) { return value.deserializeint }

	def static serialize(String value) { return new JSONString(value) }

	def static deserializeString(JSONValue value) { return value.string.stringValue }

	def static JSONValue serialize(Void void) {
		throw new UnsupportedOperationException("This should never happen due to null checking")
	}

	def static Void deserializeVoid(JSONValue value) {
		throw new UnsupportedOperationException("This should never happen due to null checking")
	}

	def static <T> serializeIterable(Iterable<T> values, (T)=>JSONValue mapper) {
		val result = new JSONArray
		var i = 0
		for (value : values) {
			if (value === null) {
				result.set(i++, JSONNull.instance)
			} else {
				result.set(i++, mapper.apply(value))
			}
		}
		return result
	}

	def static <T, C extends Collection<T>> deserializeIterable(JSONValue values, (JSONValue)=>T mapper, C output) {
		val array = values.array
		val size = array.size
		for (var i = 0; i < size; i++) {
			val value = array.get(i)
			if (value === null || value.^null !== null) {
				output.add(null)
			} else {
				output.add(mapper.apply(value))
			}
		}
		return output
	}
}
