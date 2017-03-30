package net.opensorcerers.mongoframework.lib

import co.paralleluniverse.fibers.FiberAsync
import co.paralleluniverse.fibers.SuspendExecution
import co.paralleluniverse.fibers.Suspendable
import com.mongodb.async.SingleResultCallback
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

abstract class FiberBlockingSingleResultCallback<T> extends FiberAsync<T, Throwable> implements SingleResultCallback<T> {
	new() {
		super()
	}

	@Pure def static <T> fiberBlockingCallback((FiberBlockingSingleResultCallback<T>)=>void callback) {
		return new FiberBlockingSingleResultCallback<T> {
			override protected requestAsync() {
				callback.apply(this)
			}
		}
	}

	override onResult(T result, Throwable t) {
		if (t === null) {
			asyncCompleted(result)
		} else {
			asyncFailed(t)
		}
	}

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
