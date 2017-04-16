package net.opensorcerers.game.server.content.places

import co.paralleluniverse.fibers.Suspendable
import net.opensorcerers.game.server.ApplicationResources
import net.opensorcerers.game.server.database.entities.DBUserCharacter
import org.bson.BsonObjectId
import org.bson.types.ObjectId

class PlaceProvider {
	public static val PlaceProvider INSTANCE = new PlaceProvider

	protected new() {
	}

	def getDefaultPosition() { return "0:0:0" }

	@Suspendable def Place getPlace(String position) {
		if (position === null) {
			return null
		}
		val positionSplit = position.split(":")
		switch positionSplit.head {
			case "0": {
				val long[] positionElements = (positionSplit).map [
					try {
						return Long.parseLong(it, 10)
					} catch (Throwable e) {
						return 0L
					}
				]
				return new PseudoRandomPlaceProvider().getPlace(positionElements.get(1), positionElements.get(2))
			}
			case "combat": {
				val database = ApplicationResources.instance.database
				val dbCombatPlace = database.wildEncounters.findWhere [
					it._id == new BsonObjectId(new ObjectId(positionSplit.last))
				].first
				if (dbCombatPlace === null) {
					return null
				}
				return new WildEncounter(dbCombatPlace)
			}
			default: {
				return null
			}
		}
	}

	@Suspendable def Place getPlace(DBUserCharacter character) {
		return getPlace(character.position) ?: {
			ApplicationResources.instance.database.userCharacters.updateOneWhere([it._id == character._id]) [
				it.position = defaultPosition
			]
			character.position = defaultPosition
			getPlace(character.position)
		}
	}
}
