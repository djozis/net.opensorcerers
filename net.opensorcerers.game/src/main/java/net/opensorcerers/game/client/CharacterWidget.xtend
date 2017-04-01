package net.opensorcerers.game.client

import com.google.gwt.user.client.rpc.AsyncCallback
import com.google.gwt.user.client.ui.Composite
import java.io.Closeable
import java.io.IOException
import java.util.ArrayList
import net.opensorcerers.framework.annotations.ImplementFrameworkClientService
import net.opensorcerers.framework.client.vertx.VertxEventBus
import net.opensorcerers.game.client.lib.chainreaction.ChainReaction
import net.opensorcerers.game.client.services.CharacterServiceProxy
import net.opensorcerers.game.shared.servicetypes.Action
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.gwtbootstrap3.client.ui.ButtonGroup
import org.gwtbootstrap3.client.ui.Heading
import org.gwtbootstrap3.client.ui.Panel
import org.gwtbootstrap3.client.ui.PanelBody
import org.gwtbootstrap3.client.ui.PanelFooter
import org.gwtbootstrap3.client.ui.PanelHeader
import org.gwtbootstrap3.client.ui.constants.HeadingSize
import org.gwtbootstrap3.client.ui.html.Paragraph

import static extension net.opensorcerers.game.client.lib.ClientExtensions.*
import org.gwtbootstrap3.client.ui.Button

@ImplementFrameworkClientService @FinalFieldsConstructor class CharacterWidgetServiceImpl {
	extension val CharacterWidget widget

	def static void fulfill(AsyncCallback<Void> callback, ()=>void payload) {
		try {
			payload.apply
			callback.onSuccess(null)
		} catch (Throwable e) {
			e.printStackTrace
			callback.onFailure(e)
		}
	}

	def static <T> void fulfill(AsyncCallback<T> callback, ()=>T payload) {
		try {
			callback.onSuccess(payload.apply)
		} catch (Throwable e) {
			e.printStackTrace
			callback.onFailure(e)
		}
	}

	override void setDisplayText(String displayText, AsyncCallback<Void> callback) {
		callback.fulfill [
			displayParagraph.text = displayText
		]
	}

	override void setAvailableActions(ArrayList<Action> availableActions, AsyncCallback<Void> callback) {
		callback.fulfill [
			actionsButtonGroup.clear
			for (action : availableActions) {
				actionsButtonGroup.add(new Button(action.display)) [
					addClickHandler[ event |
						ChainReaction.chain [
							characterService.performAction(characterName, action.code, ifSuccessful[])
						]
					]
				]
			}
		]
	}
}

@Accessors class CharacterWidget extends Composite implements Closeable {
	@Accessors(PACKAGE_GETTER) val CharacterServiceProxy characterService
	val Closeable serviceDetacher
	val String characterName

	Paragraph displayParagraph
	ButtonGroup actionsButtonGroup

	new(VertxEventBus eventBus, String characterName) {
		this.characterName = characterName
		this.characterService = new CharacterServiceProxy(eventBus)
		this.serviceDetacher = new CharacterWidgetServiceImpl(this).addToEventBus(eventBus)
		initWidget(new Panel => [
			add(new PanelHeader) [
				add(new Heading(HeadingSize.H3, "Playing as: " + characterName))
			]
			add(new PanelBody) [
				add(displayParagraph = new Paragraph("Loading..."))
				add(actionsButtonGroup = new ButtonGroup)
			]
			add(new PanelFooter)
		])
		ChainReaction.chain [
			characterService.connectCharacter(characterName, ifSuccessful[])
		]
	}

	override close() throws IOException { serviceDetacher.close }
}