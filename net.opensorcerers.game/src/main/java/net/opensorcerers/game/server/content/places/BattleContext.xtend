package net.opensorcerers.game.server.content.places

import co.paralleluniverse.fibers.Suspendable
import java.util.ArrayList
import net.opensorcerers.game.server.database.entities.DBCreature
import net.opensorcerers.game.server.database.entities.DBUserCharacter
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors class BattleContext {
	WildEncounter encounter
	DBUserCharacter playerCharacter
	ArrayList<DBCreature> playerCreatures
	DBCreature currentPlayerCreature

	@Suspendable def BattleContext init(DBUserCharacter playerCharacter, WildEncounter encounter) {
		this.playerCharacter = playerCharacter
		this.encounter = encounter
		this.playerCreatures = playerCharacter.loadCreatures
		this.currentPlayerCreature = playerCreatures.findFirst[it._id == playerCharacter.currentCreature]
		return this
	}

	def isCurrentPlayerCreature(DBCreature creature) { return creature._id == currentPlayerCreature._id }

	def getOpponent() { return encounter.dbWildEncounter.opponent }
}
