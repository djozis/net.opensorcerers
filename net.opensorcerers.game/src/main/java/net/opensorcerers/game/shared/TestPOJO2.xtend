package net.opensorcerers.game.shared

import org.eclipse.xtend.lib.annotations.Accessors
import net.opensorcerers.framework.annotations.ImplementStaticJsonSerialization

@Accessors @ImplementStaticJsonSerialization class TestPOJO2 {
	String a
	String b
	int k
	TestPOJO x
}
