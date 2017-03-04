package net.opensorcerers.game.client

import net.opensorcerers.game.shared.Wrapper
import org.junit.Test

class ChainedEntryPointTest extends BootstrappingGWTTestCase {
	override getModuleName() '''net.opensorcerers.game.GameClient'''

	@Test def void testChainedEntryPoint() {
		val validationWrapper = new Wrapper(false)
		val ChainedEntryPoint entryPoint = [andThen[validationWrapper.value = true]]
		assertFalse(validationWrapper.value)
		entryPoint.onModuleLoad
		assertTrue(validationWrapper.value)
	}
}
