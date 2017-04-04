package net.opensorcerers.game.server.services

import co.paralleluniverse.fibers.Fiber
import co.paralleluniverse.fibers.Suspendable
import co.paralleluniverse.strands.SuspendableAction1
import com.google.gwt.user.client.rpc.AsyncCallback
import java.util.ArrayList
import net.opensorcerers.framework.annotations.ImplementFrameworkServerService
import net.opensorcerers.game.server.ApplicationResources
import net.opensorcerers.game.server.CharacterWidgetServiceProxy
import net.opensorcerers.game.server.content.places.PlaceProvider
import net.opensorcerers.game.server.database.entities.DBUserSession
import net.opensorcerers.game.shared.servicetypes.UserCharacter
import net.opensorcerers.util.SuspendableFunction1

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
			database.userCharacters.insertOne(toCreate.toDbVersion => [
				it.userId = session.userId
			])
			return toCreate
		]
	}

	override void connectCharacter(String characterName, AsyncCallback<Void> callback) {
		callback.fulfillWithSession [ session |
			val widgetService = new CharacterWidgetServiceProxy(vertx.eventBus, session.sessionId)
			val character = findCharacterOrError(session, characterName)
			if (character.position === null) {
				character.position = PlaceProvider.INSTANCE.defaultPosition
			}
			val place = PlaceProvider.INSTANCE.getPlace(character.position)
			inParallel[
				addCall[widgetService.setCurrentOutput(place.getDescription(character), it)]
				addCall[widgetService.setAvailableActions(place.getActions(character), it)]
			]
		]
	}

	override void performAction(String characterName, String actionCode, AsyncCallback<Void> callback) {
		callback.fulfillWithSession [ session |
			val database = ApplicationResources.instance.database
			val widgetService = new CharacterWidgetServiceProxy(vertx.eventBus, session.sessionId)
			val character = findCharacterOrError(session, characterName)
			switch actionCode.split(":").head {
				case "move": {
					val oldPosition = PlaceProvider.INSTANCE.getPlace(
						character.position ?: PlaceProvider.INSTANCE.defaultPosition
					)
					if (oldPosition.getActions(character).map[code].contains(actionCode)) {
						val newPosition = actionCode.substring(actionCode.indexOf(":") + 1)
						if (database.userCharacters.updateOneWhere([
							it._id == character._id && it.position == character.position
						]) [
							it.position = newPosition
						].modifiedCount > 0) {
							val newPlace = PlaceProvider.INSTANCE.getPlace(newPosition)
							fiberBlockingCall[widgetService.setCurrentOutput(newPlace.getDescription(character), it)]
							fiberBlockingCall[widgetService.setAvailableActions(newPlace.getActions(character), it)]
						} else {
							fiberBlockingCall[
								widgetService.setCurrentOutput('''Character was no longer at: «character.position»''',
									it)
							]
						}
					} else {
						fiberBlockingCall[widgetService.setCurrentOutput('''Illegal action: «actionCode»''', it)]
					}
				}
				default:
					fiberBlockingCall[widgetService.setCurrentOutput("Unknown action: " + actionCode, it)]
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
				callback.onFailure(e)
			}
		].start
	}

	protected def <T> void fulfillWithSession(
		AsyncCallback<T> callback,
		SuspendableFunction1<T, DBUserSession> payload
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
