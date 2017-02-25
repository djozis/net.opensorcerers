package com.davidjozis.gwt.example.lib

import com.google.gwt.user.client.rpc.AsyncCallback

import static com.google.gwt.core.client.GWT.*

class AsyncCallbackExtensions {
	def static <T> AsyncCallback<T> withResult((T)=>void handler) {
		new AsyncCallback<T>() {
			override onSuccess(T result) { handler.apply(result) }

			override onFailure(Throwable caught) { log(caught.toString) }
		}
	}

	def static <T> AsyncCallback<T> withResult((T)=>void handler, (Throwable)=>void errorHandler) {
		new AsyncCallback<T>() {
			override onSuccess(T result) { handler.apply(result) }

			override onFailure(Throwable caught) { errorHandler.apply(caught) }
		}
	}
}
