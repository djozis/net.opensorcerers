package net.opensorcerers.game.client.lib

import com.google.gwt.user.client.ui.Panel
import com.google.gwt.user.client.ui.Widget
import net.opensorcerers.game.client.lib.ClientExtensions.LabelForChainer
import org.gwtbootstrap3.client.ui.FormLabel
import org.gwtbootstrap3.client.ui.base.HasId

class ClientExtensions {
	static var idIncrement = 0

	def static generateId() { return "i" + (idIncrement++) }

	def static <T extends Widget> add(Panel parent, T toAdd, (T)=>void configureCallback) {
		configureCallback.apply(toAdd)
		parent.add(toAdd)
		return toAdd
	}

	static interface LabelForChainer {
		def <T extends Widget & HasId> T forAdd(T toAdd, (T, FormLabel)=>void configureCallback)
	}

	def static <T extends FormLabel> LabelForChainer addLabel(Panel parent, T labelToAdd, (T)=>void configureCallback) {
		configureCallback.apply(labelToAdd)
		parent.add(labelToAdd)
		return new LabelForChainer {
			override <T extends Widget & HasId> forAdd(T toAdd, (T, FormLabel)=>void configureCallback) {
				configureCallback.apply(toAdd, labelToAdd)
				parent.add(toAdd)
				toAdd.id = generateId
				labelToAdd.^for = toAdd.id
				return toAdd
			}
		}
	}
}
