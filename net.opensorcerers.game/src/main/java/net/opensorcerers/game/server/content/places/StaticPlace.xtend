package net.opensorcerers.game.server.content.places

import java.util.ArrayList
import net.opensorcerers.game.server.database.entities.DBUserCharacter
import net.opensorcerers.game.shared.servicetypes.Action
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors class StaticPlace implements Place {
	String description
	ArrayList<Action> actions

	override getDescription(DBUserCharacter character) { return description }

	override getActions(DBUserCharacter character) { return actions }
}
