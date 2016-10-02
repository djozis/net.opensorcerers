package com.davidjozis.gwt.example.server

import de.itemis.xtend.auto.gwt.GwtService
import javax.servlet.annotation.WebServlet

// The @WebServlet annotation should be automatable using another Xtend active annotation...
@GwtService @WebServlet("/app/helloWorldService") class HelloWorldServiceImpl {
	override String getMessage() '''My Hello World service!'''
}
