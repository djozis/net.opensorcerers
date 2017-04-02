package net.opensorcerers.game.client

import net.opensorcerers.framework.client.vertx.VertxEventBus
import net.opensorcerers.game.client.lib.CollapsiblePanel
import net.opensorcerers.game.client.lib.chainreaction.ChainReaction
import net.opensorcerers.game.client.services.AuthenticationServiceProxy
import org.eclipse.xtend.lib.annotations.Accessors
import org.gwtbootstrap3.client.ui.CheckBox
import org.gwtbootstrap3.client.ui.FieldSet
import org.gwtbootstrap3.client.ui.Form
import org.gwtbootstrap3.client.ui.FormGroup
import org.gwtbootstrap3.client.ui.FormLabel
import org.gwtbootstrap3.client.ui.Heading
import org.gwtbootstrap3.client.ui.Input
import org.gwtbootstrap3.client.ui.PanelBody
import org.gwtbootstrap3.client.ui.PanelFooter
import org.gwtbootstrap3.client.ui.SubmitButton
import org.gwtbootstrap3.client.ui.constants.HeadingSize
import org.gwtbootstrap3.client.ui.constants.InputType
import org.gwtbootstrap3.client.ui.html.Text

import static extension net.opensorcerers.game.client.lib.ClientExtensions.*

@Accessors(PUBLIC_GETTER) class LoginWidget extends CollapsiblePanel {
	@Accessors(NONE) val AuthenticationServiceProxy authenticationService

	Text footerText
	Input usernameInput
	Input passwordInput
	CheckBox createNewAccountCheckbox
	SubmitButton submitButton

	new(VertxEventBus eventBus, (LoginWidget)=>void onSuccessfulAuthentication) {
		authenticationService = new AuthenticationServiceProxy(eventBus)
		getHeaderPanel.add(new Heading(HeadingSize.H3, "Log in"))
		getCollapsePanel => [
			add(new PanelBody) [
				add(new Form) [
					add(new FieldSet) [
						add(new FormGroup) [
							addLabel(new FormLabel) [
								text = "Email address"
							].forAdd(usernameInput = new Input) [ it, label |
								placeholder = label.text
							]
						]
						add(new FormGroup) [
							addLabel(new FormLabel) [
								text = "Password"
							].forAdd(passwordInput = new Input) [ it, label |
								type = InputType.PASSWORD
							]
						]
						add(submitButton = new SubmitButton) [
							text = "Log in"
						]
						add(createNewAccountCheckbox = new CheckBox) [
							text = "Create new account"
							addValueChangeHandler[ event |
								submitButton.text = if (createNewAccountCheckbox.value) {
									"Create account"
								} else {
									"Log in"
								}
							]
						]
					]
					addSubmitHandler[ event |
						event.cancel
						ChainReaction.chain [
							if (createNewAccountCheckbox.value) {
								authenticationService.createAccount(
									usernameInput.value,
									passwordInput.value,
									ifSuccessful[
										footerText.text = "Account created"
										onSuccessfulAuthentication.apply(this)
									].ifFailure [
										footerText.text = message
									]
								)
							} else {
								authenticationService.logIn(
									usernameInput.value,
									passwordInput.value,
									ifSuccessful[
										footerText.text = "Log in successful"
										onSuccessfulAuthentication.apply(this)
									].ifFailure [
										footerText.text = message
									]
								)
							}
						]
					]
				]
			]
			add(new PanelFooter) [
				add(footerText = new Text)
			]
		]
	}
}
