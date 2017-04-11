package net.opensorcerers.game.server.content.places

import co.paralleluniverse.fibers.Suspendable
import java.util.ArrayList
import net.opensorcerers.game.server.ClientServiceProxyFactory
import net.opensorcerers.game.server.database.entities.DBUserCharacter
import net.opensorcerers.game.shared.servicetypes.AvailableCommand

interface Place {
	def String getId()

	def String getDescription(DBUserCharacter character)

	@Suspendable def ArrayList<AvailableCommand> getAvailableCommands(DBUserCharacter character)

	@Suspendable def void performCommand(
		extension ClientServiceProxyFactory proxyFactory,
		DBUserCharacter character,
		String command
	)
}
