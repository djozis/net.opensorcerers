package net.opensorcerers.game.server.content.places

import java.util.ArrayList
import net.opensorcerers.game.server.database.entities.DBUserCharacter
import net.opensorcerers.game.shared.servicetypes.Action

interface Place {
	def String getDescription(DBUserCharacter character)

	def ArrayList<Action> getActions(DBUserCharacter character)
}
