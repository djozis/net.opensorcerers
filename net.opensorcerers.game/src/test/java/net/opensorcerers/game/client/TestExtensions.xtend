package net.opensorcerers.game.client

import com.google.gwt.dom.client.Node
import com.google.gwt.dom.client.NodeList
import java.util.Iterator

class TestExtensions extends TestJavascriptExtensions {
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
}
