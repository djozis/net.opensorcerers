package net.opensorcerers.util

import co.paralleluniverse.fibers.Fiber
import co.paralleluniverse.fibers.Suspendable
import co.paralleluniverse.strands.SuspendableAction1
import co.paralleluniverse.strands.SuspendableCallable
import co.paralleluniverse.strands.SuspendableRunnable
import com.google.gwt.user.client.rpc.AsyncCallback

class Extensions {
	def static <T extends AutoCloseable> void closeAfter(T it, (T)=>void callback) {
		var success = false
		try {
			callback.apply(it)
			success = true
		} finally {
			try {
				close
			} catch (Throwable e) {
				if (success) {
					Exceptions.sneakyThrow(e)
				}
			}
		}
	}

	def static <T extends AutoCloseable, R> R closeAfterReturn(T it, (T)=>R callback) {
		try {
			return callback.apply(it)
		} finally {
			close
		}
	}

	def static <T> void cleanupAfter(T it, (T)=>void cleanup, (T)=>void callback) {
		try {
			callback.apply(it)
		} finally {
			cleanup.apply(it)
		}
	}

	def static <T, R> R cleanupAfterReturn(T it, (T)=>void cleanup, (T)=>R callback) {
		try {
			return callback.apply(it)
		} finally {
			cleanup.apply(it)
		}
	}

	def static void fulfill(AsyncCallback<Void> callback, SuspendableRunnable payload) {
		new Fiber [
			try {
				payload.run
				callback.onSuccess(null)
			} catch (Throwable e) {
				callback.onFailure(e)
			}
		].start
	}

	def static <T> void fulfill(AsyncCallback<T> callback, SuspendableCallable<T> payload) {
		new Fiber [
			try {
				callback.onSuccess(payload.run)
			} catch (Throwable e) {
				callback.onFailure(e)
			}
		].start
	}

	/**
	 * Fiber-compatible '=>' replacement.
	 */
	@Suspendable def static <T> T withSuspendable(T object, SuspendableAction1<? super T> block) {
		block.call(object)
		return object
	}
}
