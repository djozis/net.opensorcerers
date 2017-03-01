package com.autology.game.client

import com.autology.database.entities.DBUser
import com.autology.game.client.lib.ChainReaction
import com.google.gwt.core.shared.GwtIncompatible
import com.google.gwt.dom.client.Element
import com.google.gwt.dom.client.Node
import com.google.gwt.dom.client.NodeList
import com.google.gwt.user.client.Timer
import com.google.gwt.user.client.ui.RootPanel
import java.util.Iterator
import org.junit.Test

import static extension com.autology.database.bootstrap.DatabaseExtensions.*

class WebappTest extends BootstrappingGWTTestCase {
	override getModuleName() '''com.autology.game.GameClient'''

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
		new ChainReaction [ chain |
			chain.addServerMethod("serverSetup1") [
				delayTestFinish(30000)
				new ClientEntryPoint().addOnLoad(chain).andThen [
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
				]
			]
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
		new ChainReaction [ chain |
			chain.addServerMethod("serverSetup2") [
				delayTestFinish(30000)
				new ClientEntryPoint().addOnLoad(chain).andThen [
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
				]
			]
		].start
	}
}
