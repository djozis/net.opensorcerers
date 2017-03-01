package net.opensorcerers.game.client

import net.opensorcerers.database.entities.DBUser
import net.opensorcerers.game.client.lib.ChainReaction
import com.google.gwt.core.shared.GwtIncompatible
import com.google.gwt.dom.client.Element
import com.google.gwt.dom.client.Node
import com.google.gwt.dom.client.NodeList
import com.google.gwt.user.client.Timer
import com.google.gwt.user.client.ui.RootPanel
import java.util.Iterator
import org.junit.Test

import static extension net.opensorcerers.database.bootstrap.DatabaseExtensions.*

class WebappTest extends BootstrappingGWTTestCase {
	override getModuleName() '''net.opensorcerers.game.GameClient'''

	def static <T extends Node> Iterable<T> iterable(NodeList<T> nodeList) {
		return [
			new Iterator<T> {
				val length = nodeList.length
				var nextIndex = 0

				override hasNext() { nextIndex < length }

				override next() { nodeList.getItem(nextIndex++) }
			}
		]
	}

	def static afterMillis(int delayMillis, ()=>void callback) {
		new Timer {
			override run() { callback.apply }
		}.schedule(delayMillis)
	}

	@GwtIncompatible def void serverSetup1() {
		databaseConnectivity.clearDatabase
		databaseConnectivity.withDatabaseConnection [
			withTransaction[
				persist(new DBUser => [
					it.alias = "MyUsername"
				])
			]
		]
	}

	@Test def void testApp1() {
		new ChainReaction [
			addServerMethod("serverSetup1")
		].andThen [
			delayTestFinish(30000)
			new ClientEntryPoint().addOnLoad(it)
		].andThen [
			RootPanel.get.element.childNodes.iterable.map [
				try {
					Element.^as(it).innerText
				} catch (Exception e) {
					null
				}
			].filterNull.toSet.contains(
				"MyUsername"
			).assertTrue
			finishTest
		].start
	}

	@GwtIncompatible def void serverSetup2() {
		databaseConnectivity.clearDatabase
		databaseConnectivity.withDatabaseConnection [
			withTransaction[
				persist(new DBUser => [
					it.alias = "YourUsername"
				])
			]
		]
	}

	@Test def void testApp2() {
		new ChainReaction [
			addServerMethod("serverSetup2")
		].andThen [
			delayTestFinish(30000)
			new ClientEntryPoint().addOnLoad(it)
		].andThen [
			RootPanel.get.element.childNodes.iterable.map [
				try {
					Element.^as(it).innerText
				} catch (Exception e) {
					null
				}
			].filterNull.toSet.contains(
				"YourUsername"
			).assertTrue
			finishTest
		].start
	}
}
