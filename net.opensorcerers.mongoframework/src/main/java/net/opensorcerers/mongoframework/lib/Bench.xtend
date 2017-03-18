package net.opensorcerers.mongoframework.lib

class Bench {
	static class Thing extends Thread {
		long executions = 0

		override run() {
			for (;;) {
				test
				executions++
			}
		}
	}

	def static void main(String[] args) {
		pre
		val thing = new Thing
		thing.start
		Thread.sleep(10000)
		thing.stop
		println(thing.executions)
	}

	static class Example {
		String k = "donkey"
	}

	static val Object example = new Example
	static val field = Example.getDeclaredField("k") => [
		accessible = true
	]

	static Object kout
	static (Example)=>String lambda = [k]

	def static void pre() {}

	def static void test() {
		kout = lambda.apply(example as Example)
		kout = lambda.apply(example as Example)
		kout = lambda.apply(example as Example)
		kout = lambda.apply(example as Example)
		kout = lambda.apply(example as Example)
	}
}
