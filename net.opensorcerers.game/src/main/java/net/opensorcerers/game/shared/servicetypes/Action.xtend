package net.opensorcerers.game.shared.servicetypes

import net.opensorcerers.framework.annotations.ImplementStaticJsonSerialization
import org.eclipse.xtend.lib.annotations.Accessors

@ImplementStaticJsonSerialization @Accessors class Action {
	String display
	String code
}
