package net.opensorcerers.game.server.services

import de.itemis.xtend.auto.gwt.GwtService
import java.util.Random
import javax.servlet.annotation.WebServlet
import net.opensorcerers.database.entities.DBAuthenticationIdPassword
import net.opensorcerers.database.entities.DBUser
import net.opensorcerers.database.entities.DBUserSession
import net.opensorcerers.game.shared.ResponseOrError

import static net.opensorcerers.game.shared.ResponseOrError.*

import static extension net.opensorcerers.util.PasswordHashing.*
import net.opensorcerers.framework.annotations.ImplementFrameworkServerService
import com.google.gwt.user.client.rpc.AsyncCallback
import net.opensorcerers.game.server.ApplicationResources

@ImplementFrameworkServerService class AuthenticationServiceImpl {
	override void createAccount(String email, String password, AsyncCallback<Void> callback) {
		val sessionId = threadLocalSessionId
		ApplicationResources.instance.database.authenticationIdPassword.countWhere([it.loginId == email]) [ existing, e1 |
			if (e1 !== null) {
				callback.onFailure(e1)
			} else if (existing != 0) {
				callback.onFailure(new IllegalArgumentException('''User id "«email»" is already in use'''))
			} else {
				
			}
		]
		emptyResponseOrError[
			val user = new DBUser => [
				alias = new Random().nextLong.toString
			]

			val userConnection = new DBUserSession => [
				it.sessionId = threadLocalRequest.getSession(true).id
				it.user = user
			]

			val authentication = new DBAuthenticationIdPassword => [
				it.id = email
				it.digest = password.toCharArray.createDigest
				it.user = user
			]
		]
	}

//	override ResponseOrError<Void> logIn(String email, String password) {
//		emptyResponseOrError[
//			ApplicationResources.instance.databaseConnectivity.withDatabaseConnection [
//				val authentication = queryClassWhere(
//					DBAuthenticationIdPassword,
//					"id" -> email
//				).head
//
//				if (authentication === null) {
//					throw new ClientVisibleException('''Login id "«email»" does not exist''')
//				}
//				if (!authentication.digest.compareDigest(password.toCharArray)) {
//					throw new ClientVisibleException('''Incorrect password for login id "«email»"''')
//				}
//
//				val userConnection = new DBUserSession => [
//					it.id = threadLocalRequest.getSession(true).id
//					it.user = authentication.user
//				]
//				withTransaction[saveOrUpdate(userConnection)]
//			]
//		]
//	}
}
