package net.opensorcerers.game.client.lib.chainreaction

import com.google.gwt.core.client.GWT
import com.google.gwt.user.client.rpc.AsyncCallback
import java.util.ArrayDeque
import net.opensorcerers.game.shared.ResponseOrError

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
class ChainReaction implements ChainLinkAPI {
	/**
	 * This is safe because javascript through a browser is single-threaded.
	 */
	static var ChainReaction current = null

	val ArrayDeque<(ChainLinkAPI)=>void> actionQueue
	var int outstanding

	protected new() {
		actionQueue = new ArrayDeque
		outstanding = 0
	}

	protected def void decrementOutstanding() {
		if ((outstanding = outstanding - 1) == 0) {
			start
		}
	}

	protected def void incrementOutstanding() {
		outstanding += 1
	}

	def isInProgress() { return outstanding > 0 }

	protected def ChainReaction start() {
		if (!actionQueue.empty) {
			incrementOutstanding
			ChainReaction.current = this
			actionQueue.poll.apply(this)
			ChainReaction.current = null
			decrementOutstanding
		}
		return this
	}

	def andThen((ChainLinkAPI)=>void callback) {
		actionQueue.addLast(callback)
		if (!inProgress) {
			start
		}
		return this
	}

	protected def andThenImmediate((ChainLinkAPI)=>void callback) {
		actionQueue.addFirst(callback)
		if (!inProgress) {
			start
		}
		return this
	}

	static class ChainedCallback<R, T extends ResponseOrError<R>> implements AsyncCallback<T> {
		val extension ChainReaction chain
		val (R)=>void handler
		var (Throwable)=>void errorHandler = [GWT.log(it.toString)]
		var boolean hasBeenCalled

		new(ChainReaction chain, (R)=>void handler) {
			this.chain = chain
			this.handler = handler
			hasBeenCalled = false
		}

		def ifFailure((Throwable)=>void errorHandler) {
			this.errorHandler = errorHandler
			return this
		}

		override onSuccess(T result) {
			if (hasBeenCalled) {
				throw new IllegalStateException(
					"You may not reuse chained callback objects."
				)
			}
			hasBeenCalled = true
			ChainReaction.current = chain
			if (result.exception === null) {
				handler.apply(result.result)
			} else {
				errorHandler.apply(result.exception)
			}
			ChainReaction.current = null
			decrementOutstanding
		}

		override onFailure(Throwable caught) {
			if (hasBeenCalled) {
				throw new IllegalStateException(
					"You may not reuse chained callback objects."
				)
			}
			hasBeenCalled = true
			errorHandler.apply(caught)
			decrementOutstanding
		}
	}

	override <R, T extends ResponseOrError<R>> ifSuccessful((R)=>void handler) {
		incrementOutstanding
		return new ChainedCallback<R, T>(this, handler)
	}

	/**
	 * Continue an existing chain or start one if there isn't one.
	 */
	static def chain((ChainLinkAPI)=>void callback) {
		return (current ?: new ChainReaction).andThenImmediate(callback)
	}

	/**
	 * Continue an existing chain or start one if there isn't one.
	 */
	static def chain() { return current ?: new ChainReaction }

	/**
	 * Create a new chain (deliberately for concurrency) that will never merge.
	 */
	static def fork((ChainLinkAPI)=>void callback) { return new ChainReaction().andThenImmediate(callback) }

	/**
	 * Create a new chain (deliberately for concurrency) that will never merge.
	 */
	static def fork() { return new ChainReaction }
}
