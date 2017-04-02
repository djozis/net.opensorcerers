package net.opensorcerers.util

import co.paralleluniverse.fibers.Fiber
import co.paralleluniverse.fibers.FiberAsync
import co.paralleluniverse.fibers.SuspendExecution
import co.paralleluniverse.fibers.Suspendable
import com.google.gwt.user.client.rpc.AsyncCallback
import java.util.ArrayList
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

abstract class FiberBlockingAsyncCallback<T> extends FiberAsync<T, Throwable> implements AsyncCallback<T> {
	new() {
		super()
	}

	@Pure def static <T> fiberBlockingCallback((FiberBlockingAsyncCallback<T>)=>void callback) {
		return new FiberBlockingAsyncCallback<T> {
			override protected requestAsync() {
				callback.apply(this)
			}
		}
	}

	def static <T> futureFiber((FiberBlockingAsyncCallback<T>)=>void callback) {
		val fiber = new Fiber [
			new FiberBlockingAsyncCallback<T> {
				override protected requestAsync() {
					callback.apply(this)
				}
			}.run
		]
		fiber.start
		return fiber
	}

	static class ParallelCalls {
		val fibers = new ArrayList<Fiber<?>>

		def <T> void addCall((FiberBlockingAsyncCallback<T>)=>void callback) { fibers.add(futureFiber(callback)) }
	}

	@Suspendable def static <T> void inParallel((ParallelCalls)=>void callback) {
		val calls = new ParallelCalls
		callback.apply(calls)
		for (fiber : calls.fibers) {
			fiber.get
		}
	}

	@Suspendable def static <T> fiberBlockingCall((FiberBlockingAsyncCallback<T>)=>void callback) {
		return fiberBlockingCallback(callback).run
	}

	override onFailure(Throwable caught) { asyncFailed(caught) }

	override onSuccess(T result) { asyncCompleted(result) }

	@Suspendable override T run() throws Throwable, InterruptedException {
		try {
			return super.run
		} catch (SuspendExecution e) {
			throw new AssertionError(e)
		}
	}

	@Suspendable override T run(long timeout, TimeUnit unit) throws Throwable, InterruptedException, TimeoutException {
		try {
			return super.run(timeout, unit);
		} catch (SuspendExecution e) {
			throw new AssertionError(e)
		}
	}
}
