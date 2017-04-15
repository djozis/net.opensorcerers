package net.opensorcerers.game.server.content.places

import co.paralleluniverse.fibers.Suspendable
import net.opensorcerers.game.server.ApplicationResources
import net.opensorcerers.game.server.database.entities.DBCombatPlace
import net.opensorcerers.game.server.database.entities.DBUserCharacter
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static net.opensorcerers.game.server.content.places.PlaceExtensions.*

@FinalFieldsConstructor class CombatPlace extends BasePlace {
	val DBCombatPlace dbCombatPlace

	override createCommandsList() {
		return #[
			new BasePlace.PlaceCommand(
				'''Magically escape''',
				[ proxyFactory, character |
					moveIfUnmoved(proxyFactory, character, dbCombatPlace.victoryPosition)
					destroy
				]
			)
		]
	}

	@Suspendable def destroy() {
		ApplicationResources.instance.database.combatPlaces.deleteOneWhere[it._id == this.dbCombatPlace._id]
	}

	override getId() { return '''combat:«dbCombatPlace._id.value.toHexString»''' }

	override getDescription(DBUserCharacter character) {
		return '''Oh no! You're in combat!'''
	}
}
