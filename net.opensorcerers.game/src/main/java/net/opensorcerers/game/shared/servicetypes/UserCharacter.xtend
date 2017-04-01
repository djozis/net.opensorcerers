package net.opensorcerers.game.shared.servicetypes

import com.google.gwt.core.shared.GwtIncompatible
import net.opensorcerers.framework.annotations.ImplementStaticJsonSerialization
import net.opensorcerers.game.server.database.entities.DBUserCharacter
import org.eclipse.xtend.lib.annotations.Accessors

@ImplementStaticJsonSerialization @Accessors class UserCharacter {
	String name

	@GwtIncompatible def static from(DBUserCharacter it) {
		val result = new UserCharacter
		result.name = it.name
		return result
	}

	@GwtIncompatible def toDbVersion() {
		val result = new DBUserCharacter
		result.name = name
		return result
	}
}
