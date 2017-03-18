package net.opensorcerers.game.test

import net.opensorcerers.mongoframework.annotations.ImplementMongoBean
import org.eclipse.xtend.lib.annotations.Accessors

@ImplementMongoBean @Accessors class MyBean implements MyBeanMixin {
	MyBean another
	String zzz
}
