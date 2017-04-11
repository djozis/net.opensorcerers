package net.opensorcerers.util

import co.paralleluniverse.fibers.SuspendExecution
import java.io.Serializable

interface SuspendableFunction1<P1, Result> extends Serializable {
	def Result apply(P1 p1) throws SuspendExecution, InterruptedException
}
