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
	override getModuleName() { "net.opensorcerers.game.GameClient" }

	@GwtIncompatible def void serverSetupTestCreateAccount() {
		databaseConnectivity.clearDatabase
	}

	@Test def void testCreateAccount() {
		val entryPoint = new ClientEntryPoint()
		ChainReaction.chain [
			callServerMethod("serverSetupTestCreateAccount")
		].andThen [
			injectScripts("webjars/sockjs-client/1.1.2/sockjs.min.js")
		].andThen [
			injectScripts("webjars/vertx3-eventbus-client/3.4.0/vertx-eventbus.js")
		].andThen [
			delayTestFinish(30000)
			entryPoint.onModuleLoad
		].andThen [
			entryPoint.loginWidget.usernameInput.value = "user"
			entryPoint.loginWidget.passwordInput.value = "pass"
			entryPoint.loginWidget.createNewAccountCheckbox.clickToggle
		].andThen [
			assertEquals("Create account", entryPoint.loginWidget.submitButton.text)
			entryPoint.loginWidget.submitButton.clickFormSubmit
		].andThen [
			assertEquals("Account created", entryPoint.loginWidget.footerText.text)
		].andThen [
			entryPoint.loginWidget.submitButton.clickFormSubmit
		].andThen [
			assertEquals("User id \"user\" is already in use", entryPoint.loginWidget.footerText.text)
			entryPoint.loginWidget.createNewAccountCheckbox.clickToggle
		].andThen [
			assertEquals("Log in", entryPoint.loginWidget.submitButton.text)
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
			injectScripts("webjars/sockjs-client/1.1.2/sockjs.min.js")
		].andThen [
			injectScripts("webjars/vertx3-eventbus-client/3.4.0/vertx-eventbus.js")
		].andThen [
			delayTestFinish(30000)
			entryPoint.onModuleLoad
		].andThen [
			entryPoint.loginWidget.usernameInput.value = "user1"
			entryPoint.loginWidget.passwordInput.value = "pass1"
			entryPoint.loginWidget.submitButton.clickFormSubmit
		].andThen [
			assertEquals("Login id \"user1\" does not exist", entryPoint.loginWidget.footerText.text)
			entryPoint.loginWidget.usernameInput.value = "user2"
			entryPoint.loginWidget.passwordInput.value = "pass1"
			entryPoint.loginWidget.submitButton.clickFormSubmit
		].andThen [
			assertEquals("Incorrect password for login id \"user2\"", entryPoint.loginWidget.footerText.text)
			entryPoint.loginWidget.usernameInput.value = "user2"
			entryPoint.loginWidget.passwordInput.value = "pass2"
			entryPoint.loginWidget.submitButton.clickFormSubmit
		].andThen [
			assertEquals("Log in successful", entryPoint.loginWidget.footerText.text)
		].andThen [
			postCodeCoverage
		].andThen [
			finishTest
		]
	}
}
