package net.opensorcerers.game.shared

import java.util.ArrayList
import java.util.HashSet
import org.eclipse.xtend.lib.annotations.Accessors
import net.opensorcerers.framework.annotations.ImplementStaticJsonSerialization

@Accessors @ImplementStaticJsonSerialization class TestPOJO {
	String a
	int b
	ArrayList<HashSet<TestPOJO2>> d
}
