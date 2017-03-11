package net.opensorcerers.game.shared

import net.opensorcerers.framework.annotations.JsonSerializationMethods
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.List

@Accessors @JsonSerializationMethods class TestPOJO2 {
	String a
	String b
	int k
	TestPOJO x
	
	def dispatch void ok(String k) {}
	def dispatch void ok(Integer k) {}
}
