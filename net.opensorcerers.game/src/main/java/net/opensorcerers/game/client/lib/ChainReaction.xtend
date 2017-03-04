package net.opensorcerers.game.client.lib

import com.google.gwt.core.client.GWT
import com.google.gwt.user.client.rpc.AsyncCallback
import java.util.ArrayDeque

/**
 * Support chaining of asynchronous callbacks. Use chainCallback for all service calls,
 * and use andThen to do something after all outstanding service calls have returned.
 * Use start once your chain is constructed.
 * 
 * Conceptually this iterates over the callbacks added by "andThen" which then chain
 * callbacks, and the next "andThen" is executed only when all chained callbacks have
 * finished.
 *  
 * This allows unit tests to call the chain that modules would run, and then run checks
 * immediately after all callbacks that were part of that chain return.
 */
class ChainReaction {
	val ArrayDeque<(ChainReaction)=>void> actionQueue
	var int outstanding

	new() {
		actionQueue = new ArrayDeque
		outstanding = 0
	}

	new((ChainReaction)=>void callback) {
		this()
		andThen(callback)
	}

	protected def void decrementOutstanding() {
		if ((outstanding = outstanding - 1) == 0) {
			start
		}
	}

	protected def void incrementOutstanding() {
		outstanding += 1
	}

	def start() {
		if (!actionQueue.empty) {
			incrementOutstanding
			actionQueue.poll.apply(this)
			decrementOutstanding
		}
	}

	def <T> andThen((ChainReaction)=>void callback) {
		// If the chain is already going, do the andThen immediately next
		if (outstanding > 0) {
			actionQueue.addFirst(callback)
		} else {
			actionQueue.addLast(callback)
		}
		return this
	}

	private static class ChainedCallback<T> implements AsyncCallback<T> {
		val extension ChainReaction chain
		val (T)=>void handler
		var boolean hasBeenCalled

		new(ChainReaction chain, (T)=>void handler) {
			this.chain = chain
			this.handler = handler
			hasBeenCalled = false
		}

		override onSuccess(T result) {
			if (hasBeenCalled) {
				throw new IllegalStateException(
					"You may not reuse chained callback objects."
				)
			}
			hasBeenCalled = true
			handler.apply(result)
			decrementOutstanding
		}

		override onFailure(Throwable caught) {
			if (hasBeenCalled) {
				throw new IllegalStateException(
					"You may not reuse chained callback objects."
				)
			}
			hasBeenCalled = true
			GWT.log(caught.toString)
			decrementOutstanding
		}
	}

	def <T> AsyncCallback<T> chainCallback((T)=>void handler) {
		incrementOutstanding
		return new ChainedCallback<T>(this, handler)
	}
}
