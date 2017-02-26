package com.autology.game.server

import de.itemis.xtend.auto.gwt.GwtService
import javax.servlet.annotation.WebServlet

@GwtService @WebServlet("/app/helloWorldService") class HelloWorldServiceImpl {
	override String getMessage() '''My Hello World service!'''
}
