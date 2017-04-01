package net.opensorcerers.util

import co.paralleluniverse.fibers.SuspendExecution
import java.io.Serializable

interface SuspendableFunction1<Result, P1> extends Serializable {
	def Result apply(P1 p1) throws SuspendExecution, InterruptedException
}
