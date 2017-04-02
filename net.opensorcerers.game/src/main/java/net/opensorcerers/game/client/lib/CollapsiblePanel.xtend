package net.opensorcerers.game.client.lib

import org.eclipse.xtend.lib.annotations.Accessors
import org.gwtbootstrap3.client.ui.Panel
import org.gwtbootstrap3.client.ui.PanelCollapse
import org.gwtbootstrap3.client.ui.PanelGroup
import org.gwtbootstrap3.client.ui.PanelHeader
import org.gwtbootstrap3.client.ui.constants.Toggle

import static net.opensorcerers.game.client.lib.ClientExtensions.*

class CollapsiblePanel extends Panel {
	/**
	 * GWTTestCase currently can't handle JQuery which is required for collapsing panels.
	 * This should be removable when this is solved: https://github.com/gwtproject/gwt/issues/9410
	 * This flag is set to false from unit tests.
	 */
	public static var collapsingEnabled = true

	@Accessors val headerPanel = new PanelHeader => [
		this.add(it)
	]
	@Accessors val collapsePanel = if (collapsingEnabled) {
		new PanelCollapse => [
			id = generateId
			this.add(it)
		]
	} else {
		this
	}

	override void onAttach() {
		super.onAttach
		if (collapsingEnabled) {
			val parent = this.parent
			if (parent instanceof PanelGroup) {
				headerPanel.dataToggle = Toggle.COLLAPSE
				if (parent.id === null) {
					parent.id = generateId
				}
				headerPanel.dataParent = "#" + parent.id
				headerPanel.dataTarget = "#" + collapsePanel.id
			}
		}
	}

	def setOpen(boolean open) {
		if (collapsePanel instanceof PanelCollapse) {
			collapsePanel.in = open
		}
	}
}
