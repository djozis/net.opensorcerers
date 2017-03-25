package net.opensorcerers.game.server.services

import com.google.gwt.user.client.rpc.AsyncCallback
import java.util.Random
import net.opensorcerers.framework.annotations.ImplementFrameworkServerService
import net.opensorcerers.game.server.ApplicationResources

import static extension net.opensorcerers.util.Extensions.*
import static extension net.opensorcerers.util.PasswordHashing.*

@ImplementFrameworkServerService class AuthenticationServiceImpl {
	override void createAccount(String email, String password, AsyncCallback<Void> callback) {
		val sessionId = threadLocalSessionId
		callback.fulfill [
			val database = ApplicationResources.instance.database
			val authenticationRecordId = database.authenticationIdPassword.updateOneWhere(
				[loginId == email],
				[
					loginId.onInsert = email
					digest.onInsert = password.toCharArray.createDigest
				],
				[upsert(true)]
			).upsertedId
			if (authenticationRecordId === null) {
				throw new IllegalArgumentException('''User id "«email»" is already in use''')
			}

			val user = database.users.insertOne [
				alias = new Random().nextInt(100000).toString
			]
			database.authenticationIdPassword.updateOneWhere(
				[loginId == email],
				[userId = user._id]
			)

			database.userSessions.updateOneWhere(
				[it.sessionId == sessionId],
				[userId = user._id],
				[upsert(true)]
			)
		]
	}

	override void logIn(String email, String password, AsyncCallback<Void> callback) {
		val sessionId = threadLocalSessionId
		callback.fulfill [
			val database = ApplicationResources.instance.database

			val authenticationRecord = database.authenticationIdPassword.findWhere[loginId == email].projection [
				digest.include
				userId.include
			].first

			if (authenticationRecord === null) {
				throw new IllegalArgumentException('''Login id "«email»" does not exist''')
			}
			if (!authenticationRecord.digest.compareDigest(password.toCharArray)) {
				throw new IllegalArgumentException('''Incorrect password for login id "«email»"''')
			}

			database.userSessions.updateOneWhere(
				[it.sessionId == sessionId],
				[userId = authenticationRecord.userId],
				[upsert(true)]
			)
		]
	}
}
