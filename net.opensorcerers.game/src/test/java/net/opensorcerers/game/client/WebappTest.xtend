package net.opensorcerers.game.client

import com.google.gwt.core.shared.GwtIncompatible
import net.opensorcerers.database.entities.DBAuthenticationIdPassword
import net.opensorcerers.database.entities.DBUser
import net.opensorcerers.game.client.lib.chainreaction.ChainReaction
import org.junit.Test

import static extension net.opensorcerers.database.bootstrap.DatabaseExtensions.*
import static extension net.opensorcerers.game.client.TestExtensions.*
import static extension net.opensorcerers.util.PasswordHashing.*

class WebappTest extends BootstrappingGWTTestCase {
	override getModuleName() '''net.opensorcerers.game.GameClient'''

	@GwtIncompatible def void serverSetupTestCreateAccount() {
		databaseConnectivity.clearDatabase
	}

	@Test def void testCreateAccount() {
		val entryPoint = new ClientEntryPoint()
		ChainReaction.chain [
			callServerMethod("serverSetupTestCreateAccount")
		].andThen [
			delayTestFinish(30000)
			entryPoint.onModuleLoad
		].andThen [
			entryPoint.loginWidget.usernameInput.value = "user"
			entryPoint.loginWidget.passwordInput.value = "pass"
			entryPoint.loginWidget.createNewAccountCheckbox.value = true
			entryPoint.loginWidget.submitButton.formSubmit
		].andThen [
			assertEquals("Account created", entryPoint.loginWidget.footerText.text)
		].andThen [
			postCodeCoverage
		].andThen [
			finishTest
		]
	}

	@GwtIncompatible def void serverValidateCreateAccount() {
		databaseConnectivity.withDatabaseConnection [
			assertEquals(1, queryClassWhere(
				DBAuthenticationIdPassword,
				"id" -> "user"
			).size)
		]
	}

	@GwtIncompatible def void serverSetupTestLogIntoAccount() {
		databaseConnectivity.clearDatabase
		val user = new DBUser => [
			alias = "alias"
		]
		val authentication = new DBAuthenticationIdPassword => [
			it.id = "user2"
			it.digest = "pass2".toCharArray.createDigest
			it.user = user
		]
		databaseConnectivity.databaseTransaction [
			persist(user)
			persist(authentication)
		]
	}

	@Test def void testLogIntoAccount() {
		val entryPoint = new ClientEntryPoint()
		ChainReaction.chain [
			callServerMethod("serverSetupTestLogIntoAccount")
		].andThen [
			delayTestFinish(30000)
			entryPoint.onModuleLoad
		].andThen [
			entryPoint.loginWidget.usernameInput.value = "user2"
			entryPoint.loginWidget.passwordInput.value = "pass2"
			entryPoint.loginWidget.submitButton.formSubmit
		].andThen [
			assertEquals("Log in successful", entryPoint.loginWidget.footerText.text)
		].andThen [
			postCodeCoverage
		].andThen [
			finishTest
		]
	}
}
