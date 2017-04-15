package net.opensorcerers.game.server.content.places

import co.paralleluniverse.fibers.Suspendable
import co.paralleluniverse.strands.SuspendableAction2
import java.util.ArrayList
import net.opensorcerers.game.server.ClientServiceProxyFactory
import net.opensorcerers.game.server.database.entities.DBUserCharacter
import net.opensorcerers.game.shared.servicetypes.AvailableCommand
import net.opensorcerers.util.SuspendableFunction1
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static extension java.lang.Integer.*

abstract class BasePlace implements Place {
	@FinalFieldsConstructor static class PlaceCommand {
		private static val SuspendableFunction1<DBUserCharacter, Boolean> TRUE_PREDICATE = [true]

		val String description
		val SuspendableFunction1<DBUserCharacter, Boolean> availablePredicate
		val SuspendableAction2<ClientServiceProxyFactory, DBUserCharacter> execute

		new(String description, SuspendableAction2<ClientServiceProxyFactory, DBUserCharacter> execute) {
			this(description, TRUE_PREDICATE, execute)
		}
	}

	def PlaceCommand[] createCommandsList()

	val commandsList = createCommandsList()


	@Suspendable override getAvailableCommands(DBUserCharacter character) {
		val commands = new ArrayList<AvailableCommand>
		commandsList.forEach [ command, index |
			if (command.availablePredicate.apply(character)) {
				commands.add(new AvailableCommand => [
					it.description = command.description
					it.code = index.toString
				])
			}
		]
		return commands
	}

	@Suspendable override performCommand(
		extension ClientServiceProxyFactory proxyFactory,
		DBUserCharacter character,
		String commandCode
	) {
		val command = try {
			commandsList.get(commandCode.parseInt(10))
		} catch (Throwable e) {
			throw new IllegalArgumentException(
				'''Could not find command «commandCode» for place «id»: «e.message»''',
				e
			)
		}
		if (!command.availablePredicate.apply(character)) {
			throw new IllegalArgumentException(
				'''Command «commandCode» for place «id» is not available to character «character.name»'''
			)
		}
		command.execute.call(proxyFactory, character)
	}
}
