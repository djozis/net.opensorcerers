package net.opensorcerers.game.shared

import java.util.ArrayList
import java.util.HashSet
import net.opensorcerers.framework.annotations.JsonSerializationMethods
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors @JsonSerializationMethods class TestPOJO {
	String a
	String b
	int k
	ArrayList<HashSet<TestPOJO2>> x
}
