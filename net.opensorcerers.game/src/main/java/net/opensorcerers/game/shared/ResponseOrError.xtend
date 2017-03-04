package net.opensorcerers.game.shared

import java.io.Serializable
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors class ResponseOrError<T> implements Serializable {
	ClientVisibleException exception
	T result

	new() {
	}

	static def <T> responseOrError(()=>T generateResponseCallback) {
		val response = new ResponseOrError<T>
		try {
			response.result = generateResponseCallback.apply
		} catch (ClientVisibleException e) {
			response.exception = e
		} catch (Throwable t) {
			response.exception = new ClientVisibleException("Internal server error")
		}
		return response
	}

	static def emptyResponseOrError(()=>void generateResponseCallback) {
		val response = new ResponseOrError<Void>
		try {
			generateResponseCallback.apply
		} catch (ClientVisibleException e) {
			response.exception = e
		}
		return response
	}
}
