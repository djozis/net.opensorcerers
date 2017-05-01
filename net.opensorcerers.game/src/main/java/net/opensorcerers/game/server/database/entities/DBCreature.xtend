package net.opensorcerers.game.server.database.entities

import java.util.ArrayList
import java.util.Random
import net.opensorcerers.game.server.content.places.BattleContext
import net.opensorcerers.game.server.content.places.WildEncounter.PlaceCommand
import net.opensorcerers.game.server.content.species.SpeciesProvider
import net.opensorcerers.mongoframework.annotations.ImplementMongoBean
import org.bson.BsonObjectId
import org.eclipse.xtend.lib.annotations.Accessors
import net.opensorcerers.game.server.ApplicationResources
import co.paralleluniverse.fibers.Suspendable
import net.opensorcerers.game.server.CharacterWidgetServiceProxy

import static extension net.opensorcerers.util.FiberBlockingAsyncCallback.*

@ImplementMongoBean @Accessors class DBCreature {
	BsonObjectId owner
	Integer speciesId
	String name
	Integer hitpoints
	Integer maxHitpoints

	def getSpecies() { return SpeciesProvider.instance.getSpecies(this.speciesId) }

	def isDead() { return hitpoints <= 0 }

	def attack(DBCreature target, StringBuilder output) {
		val damage = new Random().nextInt(3) + 2
		target.hitpoints = target.hitpoints - damage
		output.append(
			'''«name» attacked «target.name» for «damage» damage (-> «target.hitpoints»/«target.maxHitpoints»'''
		)
	}

	@Suspendable def addBattleCommands(ArrayList<PlaceCommand> it, extension BattleContext context) {
		if (this.isCurrentPlayerCreature) {
			add(new PlaceCommand("Attack") [ extension proxyFactory, character |
				val output = new StringBuilder
				attack(opponent, output)
				output.append("\n")
				output.append("\n")
				opponent.attack(this, output)
				val database = ApplicationResources.instance.database
				database.userCreatures.updateOneWhere([it._id == this._id]) [
					it.hitpoints = this.hitpoints
				]
				database.wildEncounters.updateOneWhere([it._id == encounter.dbWildEncounter._id]) [
					it.opponent.hitpoints = context.opponent.hitpoints
				]
				fiberBlockingCall[CharacterWidgetServiceProxy.instanciate.printToOutput(output.toString, it)]
			])
		}
	}
}
