package net.opensorcerers.game.server.content.species

import org.eclipse.xtend.lib.annotations.Accessors
import net.opensorcerers.game.server.database.entities.DBCreature
import net.opensorcerers.game.server.database.entities.DBWildEncounter

@Accessors abstract class Move {
	val String name

	def void apply(DBCreature user, DBWildEncounter encounter)
}
