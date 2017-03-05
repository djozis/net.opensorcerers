package net.opensorcerers.game.client

import com.google.gwt.dom.client.Node
import com.google.gwt.dom.client.NodeList
import com.google.gwt.event.logical.shared.ValueChangeEvent
import com.google.gwt.user.client.ui.Widget
import java.util.Iterator
import org.gwtbootstrap3.client.ui.Button
import org.gwtbootstrap3.client.ui.CheckBox
import org.gwtbootstrap3.client.ui.Form

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

	def static clickFormSubmit(Button button) {
		var Widget form = button
		while (!(form instanceof Form)) {
			form = form.parent
			if (form === null) {
				throw new NullPointerException("Could not find form in button's parents")
			}
		}
		(form as Form).submit
	}

	def static clickToggle(CheckBox checkbox) {
		checkbox.value = !checkbox.value
		ValueChangeEvent.fire(checkbox, checkbox.value)
	}
}
