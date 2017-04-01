package net.opensorcerers.game.server.services

import co.paralleluniverse.fibers.Fiber
import co.paralleluniverse.strands.SuspendableAction1
import com.google.gwt.user.client.rpc.AsyncCallback
import java.util.ArrayList
import net.opensorcerers.framework.annotations.ImplementFrameworkServerService
import net.opensorcerers.game.server.ApplicationResources
import net.opensorcerers.game.server.CharacterWidgetServiceProxy
import net.opensorcerers.game.server.database.entities.DBUserSession
import net.opensorcerers.game.shared.servicetypes.Action
import net.opensorcerers.game.shared.servicetypes.UserCharacter
import net.opensorcerers.util.SuspendableFunction1

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
			val database = ApplicationResources.instance.database
			val dbCharacter = database.userCharacters.findWhere [
				it.userId == session.userId && it.name == characterName
			].first
			if (dbCharacter === null) {
				throw new IllegalArgumentException(
					'''Could not find character with name "«characterName»" under your account.'''
				)
			}
			val widgetService = new CharacterWidgetServiceProxy(vertx.eventBus, session.sessionId)
			widgetService.setDisplayText("Hello World", new AsyncCallback<Void> {
				override onFailure(Throwable caught) {}

				override onSuccess(Void result) {}
			})
			widgetService.setAvailableActions(new ArrayList(#[
				new Action => [
					it.display = "Do a thing"
					it.code = "Top secretz"
				]
			]), callback)
		]
	}

	override void performAction(String characterName, String actionCode, AsyncCallback<Void> callback) {
		callback.fulfillWithSession [ session |
			val widgetService = new CharacterWidgetServiceProxy(vertx.eventBus, session.sessionId)
			widgetService.setDisplayText("Action code: " + actionCode, callback)
		]
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
				callback.onFailure(e)
			}
		].start
	}
}
