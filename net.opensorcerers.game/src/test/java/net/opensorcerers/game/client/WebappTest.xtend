package net.opensorcerers.game.client

import com.google.gwt.core.shared.GwtIncompatible
import net.opensorcerers.game.client.lib.chainreaction.ChainReaction
import org.junit.Test

import static extension net.opensorcerers.game.client.TestExtensions.*
import static extension net.opensorcerers.util.PasswordHashing.*
import net.opensorcerers.framework.client.Console

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
			injectScripts("webjars/sockjs-client/1.1.2/sockjs.js")
		].andThen [
			injectScripts("webjars/vertx3-eventbus-client/3.4.0/vertx-eventbus.js")
		].andThen [
			delayTestFinish(90000)
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
		inSynchronizedFiber[
			assertEquals(
				1,
				database.authenticationIdPassword.countWhere [
					loginId == "user"
				]
			)
		]
	}

	@GwtIncompatible def void serverSetupTestLogIntoAccount() {
		databaseConnectivity.clearDatabase
		inSynchronizedFiber[
			val user = database.users.insertOne[alias = "alias"]
			database.authenticationIdPassword.insertOne [
				loginId = "user2"
				digest = "pass2".toCharArray.createDigest
				userId = user._id
			]
		]
	}

	@Test def void testLogIntoAccount() {
		val entryPoint = new ClientEntryPoint()
		ChainReaction.chain [
			callServerMethod("serverSetupTestLogIntoAccount")
		].andThen [
			Console.log("TEST: A")
			injectScripts("webjars/sockjs-client/1.1.2/sockjs.min.js")
		].andThen [
			Console.log("TEST: B")
			injectScripts("webjars/vertx3-eventbus-client/3.4.0/vertx-eventbus.js")
		].andThen [
			Console.log("TEST: C")
			delayTestFinish(90000)
			entryPoint.onModuleLoad
		].andThen [
			Console.log("TEST: D")
			entryPoint.loginWidget.usernameInput.value = "user1"
			entryPoint.loginWidget.passwordInput.value = "pass1"
			entryPoint.loginWidget.submitButton.clickFormSubmit
			Console.log("TEST: D2")
		].andThen [
			Console.log("TEST: E")
			assertEquals("Login id \"user1\" does not exist", entryPoint.loginWidget.footerText.text)
			entryPoint.loginWidget.usernameInput.value = "user2"
			entryPoint.loginWidget.passwordInput.value = "pass1"
			entryPoint.loginWidget.submitButton.clickFormSubmit
		].andThen [
			Console.log("TEST: F")
			assertEquals("Incorrect password for login id \"user2\"", entryPoint.loginWidget.footerText.text)
			entryPoint.loginWidget.usernameInput.value = "user2"
			entryPoint.loginWidget.passwordInput.value = "pass2"
			entryPoint.loginWidget.submitButton.clickFormSubmit
		].andThen [
			Console.log("TEST: G")
			assertEquals("Log in successful", entryPoint.loginWidget.footerText.text)
		].andThen [
			Console.log("TEST: H")
			postCodeCoverage
		].andThen [
			Console.log("TEST: I")
			finishTest
		]
	}
}
