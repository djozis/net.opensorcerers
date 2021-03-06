package net.opensorcerers.game.server.services

import co.paralleluniverse.fibers.Fiber
import co.paralleluniverse.fibers.Suspendable
import co.paralleluniverse.strands.SuspendableAction1
import com.google.gwt.user.client.rpc.AsyncCallback
import java.util.ArrayList
import net.opensorcerers.framework.annotations.ImplementFrameworkServerService
import net.opensorcerers.game.server.ApplicationResources
import net.opensorcerers.game.server.CharacterWidgetServiceProxy
import net.opensorcerers.game.server.ClientServiceProxyFactory
import net.opensorcerers.game.server.content.places.PlaceProvider
import net.opensorcerers.game.server.content.species.SpeciesProvider
import net.opensorcerers.game.server.database.entities.DBUserSession
import net.opensorcerers.game.shared.servicetypes.UserCharacter
import net.opensorcerers.util.SuspendableFunction1
import org.bson.BsonObjectId
import org.bson.types.ObjectId

import static net.opensorcerers.util.FiberBlockingAsyncCallback.*

import static extension net.opensorcerers.util.Extensions.*

@ImplementFrameworkServerService class CharacterServiceImpl {
	override void listCharacters(AsyncCallback<ArrayList<UserCharacter>> callback) {
		callback.fulfillWithSession [ session |
			return new ArrayList().withSuspendable [
				addAll(
					ApplicationResources.instance.database.userCharacters.findWhere [
						userId == session.userId
					].projection [
						name.include
					].toArrayList.map[UserCharacter.from(it)]
				)
			]
		]
	}

	override void createCharacter(UserCharacter toCreate, AsyncCallback<UserCharacter> callback) {
		callback.fulfillWithSession [ session |
			val database = ApplicationResources.instance.database
			if (database.userCharacters.findWhere [
				name == toCreate.name
			].first !== null) {
				throw new IllegalArgumentException(
					'''Character name «toCreate» is in use.'''
				)
			}
			val newCreatureId = new BsonObjectId(new ObjectId)
			val characterId = database.userCharacters.updateOneWhere(
				[name == toCreate.name],
				[
					it.userId.onInsert = session.userId
					it.name.onInsert = toCreate.name
					it.position = PlaceProvider.INSTANCE.defaultPosition
					it.currentCreature = newCreatureId
				],
				[upsert(true)]
			).upsertedId as BsonObjectId
			if (characterId === null) {
				throw new IllegalArgumentException(
					'''Character name «toCreate» is in use.'''
				)
			}
			database.userCreatures.insertOne(SpeciesProvider.instance.getSpecies(0).generateWildCreature => [
				it._id = newCreatureId
				it.owner = characterId
				it.name = "First Friend"
			])
			return toCreate
		]
	}

	override void connectCharacter(String characterName, AsyncCallback<Void> callback) {
		callback.fulfillWithSession [ session |
			val widgetService = new CharacterWidgetServiceProxy(vertx.eventBus, session.sessionId)
			val character = findCharacterOrError(session, characterName)
			val place = PlaceProvider.INSTANCE.getPlace(character)
			val availableCommands = place.getAvailableCommands(character)
			inParallel[
				addCall[widgetService.setCurrentOutput(place.getDescription(character), it)]
				addCall[widgetService.setAvailablePlaceCommands(availableCommands, it)]
			]
		]
	}

	override void performPlaceCommand(String characterName, String commandCode, AsyncCallback<Void> callback) {
		callback.fulfillWithSession [ session |
			val character = findCharacterOrError(session, characterName)
			val place = PlaceProvider.INSTANCE.getPlace(character)
			if (place !== null) {
				place.performCommand(
					new ClientServiceProxyFactory(vertx.eventBus, session.sessionId),
					character,
					commandCode
				)
			} else {
				throw new IllegalStateException('''Character "«character.name»" is in null place at "«character.position»"''')
			}
		]
	}

	@Suspendable protected def findCharacterOrError(DBUserSession session, String characterName) {
		val database = ApplicationResources.instance.database
		val dbCharacter = database.userCharacters.findWhere [
			it.userId == session.userId && it.name == characterName
		].first
		if (dbCharacter === null) {
			throw new IllegalArgumentException(
				'''Could not find character with name "«characterName»" under your account.'''
			)
		}
		return dbCharacter
	}

	protected def void fulfillWithSession(
		AsyncCallback<Void> callback,
		SuspendableAction1<DBUserSession> payload
	) {
		val sessionId = threadLocalSessionId
		new Fiber [
			try {
				if (sessionId === null) {
					throw new IllegalStateException("You have no session id. Please refresh your browser.")
				}
				val database = ApplicationResources.instance.database
				val session = database.userSessions.findWhere[it.sessionId == sessionId].first
				if (session === null) {
					throw new IllegalStateException("You are not logged in. Please refresh your browser.")
				}
				payload.call(session)
				callback.onSuccess(null)
			} catch (Throwable e) {
				e.printStackTrace // TODO: remove outside of debug
				callback.onFailure(e)
			}
		].start
	}

	protected def <T> void fulfillWithSession(
		AsyncCallback<T> callback,
		SuspendableFunction1<DBUserSession, T> payload
	) {
		val sessionId = threadLocalSessionId
		new Fiber [
			try {
				if (sessionId === null) {
					throw new IllegalStateException("You have no session id. Please refresh your browser.")
				}
				val database = ApplicationResources.instance.database
				val session = database.userSessions.findWhere[it.sessionId == sessionId].first
				if (session === null) {
					throw new IllegalStateException("You are not logged in. Please refresh your browser.")
				}
				callback.onSuccess(payload.apply(session))
			} catch (Throwable e) {
				e.printStackTrace
				callback.onFailure(e)
			}
		].start
	}
}
