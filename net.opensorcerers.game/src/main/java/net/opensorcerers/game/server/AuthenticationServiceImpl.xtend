package net.opensorcerers.game.server

import de.itemis.xtend.auto.gwt.GwtService
import java.security.SecureRandom
import java.util.Random
import javax.servlet.annotation.WebServlet
import net.opensorcerers.database.entities.DBUser
import net.opensorcerers.database.entities.DBUserConnection

import static extension net.opensorcerers.database.bootstrap.DatabaseExtensions.*
import static extension net.opensorcerers.util.PasswordHashing.*

@GwtService @WebServlet("/app/authenticationService") class AuthenticationServiceImpl {
	val random = new SecureRandom

	protected def createConnectionKey() { return random.randomBytes(16) }

	protected def static randomBytes(Random random, int size) {
		val key = newByteArrayOfSize(size)
		random.nextBytes(key)
		return key
	}

	static val hexArray = "0123456789ABCDEF".toCharArray

	protected def static char[] toHexChars(byte[] bytes) {
		val hexChars = newCharArrayOfSize(bytes.length * 2)
		for (var i = bytes.length - 1; i >= 0; i--) {
			val v = bytes.get(i).bitwiseAnd(0xFF)
			hexChars.set(i * 2, hexArray.get(v >>> 4))
			hexChars.set(i * 2 + 1, hexArray.get(v.bitwiseAnd(0x0F)))
		}
		return hexChars
	}

	override boolean createAccount(String email, String password) {
		val user = new DBUser
		user.alias = new Random().nextLong.toString

		val connectionKey = createConnectionKey
		val userConnection = new DBUserConnection => [
			it.digest = connectionKey.toHexChars.createDigest
			it.user = user
		]

		ApplicationResources.instance.databaseConnectivity.databaseTransaction [
			persist(user)
			persist(userConnection)
		]

		//threadLocalRequest.getSession(true).setAttribute()
		return true
	}
}
