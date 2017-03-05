package net.opensorcerers.game.server

import de.itemis.xtend.auto.gwt.GwtService
import java.util.Random
import javax.servlet.annotation.WebServlet
import net.opensorcerers.database.entities.DBAuthenticationIdPassword
import net.opensorcerers.database.entities.DBUser
import net.opensorcerers.database.entities.DBUserSession
import net.opensorcerers.game.shared.ClientVisibleException
import net.opensorcerers.game.shared.ResponseOrError

import static net.opensorcerers.game.shared.ResponseOrError.*

import static extension net.opensorcerers.database.bootstrap.DatabaseExtensions.*
import static extension net.opensorcerers.util.PasswordHashing.*

@GwtService @WebServlet("/app/authenticationService") class AuthenticationServiceImpl {
	override ResponseOrError<Void> createAccount(String email, String password) {
		emptyResponseOrError[
			val user = new DBUser => [
				alias = new Random().nextLong.toString
			]

			val userConnection = new DBUserSession => [
				it.id = threadLocalRequest.getSession(true).id
				it.user = user
			]

			val authentication = new DBAuthenticationIdPassword => [
				it.id = email
				it.digest = password.toCharArray.createDigest
				it.user = user
			]

			ApplicationResources.instance.databaseConnectivity.withDatabaseConnection [
				if (!queryClassWhere(
					DBAuthenticationIdPassword,
					"id" -> email
				).empty) {
					throw new ClientVisibleException(
						'''User id "«email»" is already in use'''
					)
				}

				withTransaction [
					persist(user)
					persist(authentication)
					saveOrUpdate(userConnection)
				]
			]
		]
	}

	override ResponseOrError<Void> logIn(String email, String password) {
		emptyResponseOrError[
			ApplicationResources.instance.databaseConnectivity.withDatabaseConnection [
				val authentication = queryClassWhere(
					DBAuthenticationIdPassword,
					"id" -> email
				).head

				if (authentication === null) {
					throw new ClientVisibleException('''Login id "«email»" does not exist''')
				}
				if (!authentication.digest.compareDigest(password.toCharArray)) {
					throw new ClientVisibleException('''Incorrect password for login id "«email»"''')
				}

				val userConnection = new DBUserSession => [
					it.id = threadLocalRequest.getSession(true).id
					it.user = authentication.user
				]
				withTransaction[saveOrUpdate(userConnection)]
			]
		]
	}
}
