package net.opensorcerers.game.server.content.places

import co.paralleluniverse.fibers.SuspendExecution
import co.paralleluniverse.fibers.Suspendable
import java.util.Random
import net.opensorcerers.game.server.ApplicationResources
import net.opensorcerers.game.server.CharacterWidgetServiceProxy
import net.opensorcerers.game.server.ClientServiceProxyFactory
import net.opensorcerers.game.server.content.species.SpeciesProvider
import net.opensorcerers.game.server.database.entities.DBUserCharacter
import org.bson.BsonObjectId
import org.bson.types.ObjectId

import static net.opensorcerers.util.FiberBlockingAsyncCallback.*

class PlaceExtensions {
	static val random = new Random

	@Suspendable def static moveIfUnmoved(
		extension ClientServiceProxyFactory proxyFactory,
		DBUserCharacter character,
		String targetPlaceId
	) throws SuspendExecution, InterruptedException {
		val database = ApplicationResources.instance.database
		val widgetService = CharacterWidgetServiceProxy.instanciate
		if (database.userCharacters.updateOneWhere([
			it._id == character._id && it.position == character.position
		]) [
			it.position = targetPlaceId
		].modifiedCount > 0) {
			val newPlace = PlaceProvider.INSTANCE.getPlace(targetPlaceId)
			if (newPlace === null) {
				throw new IllegalStateException(
					'''Place "«targetPlaceId»" is null from getPlace'''
				)
			}
			fiberBlockingCall[widgetService.setCurrentOutput(newPlace.getDescription(character), it)]
			fiberBlockingCall[widgetService.setAvailablePlaceCommands(newPlace.getAvailableCommands(character), it)]
		} else {
			throw new IllegalArgumentException(
				'''Character was no longer at: «character.position»'''
			)
		}
	}

	@Suspendable def static tryToMoveTo(
		ClientServiceProxyFactory proxyFactory,
		DBUserCharacter character,
		String targetPlaceId
	) {
		if (random.nextDouble < 0.3d) {
			val combatPlace = ApplicationResources.instance.database.wildEncounters.insertOne [
				_id = new BsonObjectId(new ObjectId)
				parentPosition = character.position
				opponent = SpeciesProvider.instance.getSpecies(0).generateWildCreature
				status = '''
					A «opponent.species.name» stops you in your tracks!
					«opponent.name» has «opponent.hitpoints»/«opponent.maxHitpoints» hitpoints.
				'''
			]
			moveIfUnmoved(proxyFactory, character, '''combat:«combatPlace._id.value.toHexString»''')
		} else {
			moveIfUnmoved(proxyFactory, character, targetPlaceId)
		}
	}
}
