package net.opensorcerers.game.client

import com.google.gwt.user.client.ui.Composite
import java.util.ArrayList
import net.opensorcerers.framework.client.vertx.VertxEventBus
import net.opensorcerers.game.client.lib.chainreaction.ChainReaction
import net.opensorcerers.game.client.services.CharacterServiceProxy
import net.opensorcerers.game.shared.servicetypes.UserCharacter
import org.eclipse.xtend.lib.annotations.Accessors
import org.gwtbootstrap3.client.ui.Button
import org.gwtbootstrap3.client.ui.ButtonGroup
import org.gwtbootstrap3.client.ui.FieldSet
import org.gwtbootstrap3.client.ui.Form
import org.gwtbootstrap3.client.ui.FormGroup
import org.gwtbootstrap3.client.ui.FormLabel
import org.gwtbootstrap3.client.ui.Heading
import org.gwtbootstrap3.client.ui.Input
import org.gwtbootstrap3.client.ui.Panel
import org.gwtbootstrap3.client.ui.PanelBody
import org.gwtbootstrap3.client.ui.PanelFooter
import org.gwtbootstrap3.client.ui.PanelHeader
import org.gwtbootstrap3.client.ui.SubmitButton
import org.gwtbootstrap3.client.ui.constants.FormType
import org.gwtbootstrap3.client.ui.constants.HeadingSize
import org.gwtbootstrap3.client.ui.html.Text

import static extension net.opensorcerers.game.client.lib.ClientExtensions.*

@Accessors class CharacterSelectWidget extends Composite {
	@Accessors(NONE) val CharacterServiceProxy characterService
	@Accessors(NONE) val (UserCharacter)=>void selectionCallback

	PanelBody charactersBody
	Input nameInput
	SubmitButton createCharacterSubmitButton

	def setCharacters(ArrayList<UserCharacter> characters) {
		charactersBody.clear
		if (characters !== null) {
			for (character : characters) {
				charactersBody.add(new ButtonGroup) [
					add(new Button) [
						add(new Text(character.name))
						addClickHandler[event|selectionCallback.apply(character)]
					]
				]
			}
		}
	}

	new(VertxEventBus eventBus, (UserCharacter)=>void selectionCallback) {
		this.characterService = new CharacterServiceProxy(eventBus)
		this.selectionCallback = selectionCallback
		initWidget(new Panel => [
			add(new PanelHeader) [
				add(new Heading(HeadingSize.H3, "Select Character"))
			]
			add(charactersBody = new PanelBody) [
				add(new Text("Characters not yet found..."))
			]
			add(new PanelBody) [
				add(new Text("Create new character"))
				add(new Form) [
					type = FormType.HORIZONTAL
					add(new FieldSet) [
						add(new FormGroup) [
							addLabel(new FormLabel) [
								text = "Character name"
							].forAdd(nameInput = new Input) [ it, label |
								placeholder = label.text
							]
						]
						add(createCharacterSubmitButton = new SubmitButton) [
							text = "Create"
						]
					]
					addSubmitHandler[ event |
						event.cancel
						ChainReaction.chain [
							characterService.createCharacter(new UserCharacter => [
								it.name = nameInput.value
							], ifSuccessful[
								selectionCallback.apply(it)
							])
						]
					]
				]
			]
			add(new PanelFooter)
		])
		ChainReaction.chain [
			characterService.listCharacters(ifSuccessful[ characters |
				this.characters = characters
			])
		]
	}
}
