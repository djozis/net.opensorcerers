package net.opensorcerers.game.server.content.places

import co.paralleluniverse.fibers.Suspendable
import co.paralleluniverse.strands.SuspendableAction2
import java.util.ArrayList
import net.opensorcerers.game.server.ApplicationResources
import net.opensorcerers.game.server.ClientServiceProxyFactory
import net.opensorcerers.game.server.database.entities.DBUserCharacter
import net.opensorcerers.game.server.database.entities.DBWildEncounter
import net.opensorcerers.game.shared.servicetypes.AvailableCommand
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static net.opensorcerers.game.server.content.places.PlaceExtensions.*

@FinalFieldsConstructor class WildEncounter implements Place {
	@Accessors val DBWildEncounter dbWildEncounter

	transient BattleContext battleContextStore = null

	@Suspendable def getBattleContext(DBUserCharacter playerCharacter) {
		return battleContextStore ?: (battleContextStore = new BattleContext().init(playerCharacter, this))
	}

	@Suspendable def destroy() {
		ApplicationResources.instance.database.wildEncounters.deleteOneWhere[it._id == this.dbWildEncounter._id]
	}

	override getId() { return '''combat:«dbWildEncounter._id.value.toHexString»''' }

	override getDescription(DBUserCharacter character) {
		return dbWildEncounter.status
	}

	@FinalFieldsConstructor static class PlaceCommand {
		val String description
		val SuspendableAction2<ClientServiceProxyFactory, DBUserCharacter> execute

		def toAvailableCommand() {
			return new AvailableCommand => [
				it.description = this.description
				it.code = this.description
			]
		}
	}

	@Suspendable def calculateAvailableCommands(DBUserCharacter commandsCharacter) {
		val it = new ArrayList

		add(new PlaceCommand("Flee") [ extension proxyFactory, character |
			moveIfUnmoved(proxyFactory, character, dbWildEncounter.parentPosition)
		])

		val battleContext = commandsCharacter.battleContext
		for (creature : battleContext.playerCreatures) {
			creature.addBattleCommands(it, battleContext)
		}

		return it
	}

	@Suspendable override getAvailableCommands(DBUserCharacter character) {
		return new ArrayList(character.calculateAvailableCommands.map[toAvailableCommand])
	}

	@Suspendable override performCommand(
		extension ClientServiceProxyFactory proxyFactory,
		DBUserCharacter character,
		String command
	) {
		val foundCommand = character.calculateAvailableCommands.filter[it.description == command].head
		if (foundCommand === null) {
			throw new IllegalArgumentException('''Could not find command for character "«character.name»": «command»''')
		} else {
			foundCommand.execute.call(proxyFactory, character)
		}
	}
}
