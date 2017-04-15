package net.opensorcerers.game.server

import co.paralleluniverse.fibers.Fiber
import co.paralleluniverse.fibers.Suspendable
import net.opensorcerers.game.server.database.TestDatabaseConnectivity

class Test {
	@Suspendable def static void main(String[] args) {
		extension val resources = new ApplicationResources(new TestDatabaseConnectivity)
		try {
			new Fiber [
				// A simple harness for experimenting with database interactions and such
			].start.get
		} finally {
			resources.close
		}
	}
}
