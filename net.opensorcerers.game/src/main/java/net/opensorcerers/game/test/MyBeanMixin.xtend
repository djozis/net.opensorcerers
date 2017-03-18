package net.opensorcerers.game.test

import net.opensorcerers.mongoframework.annotations.ImplementMongoBeanMixin

@ImplementMongoBeanMixin interface MyBeanMixin {
	String mixedInString
}
