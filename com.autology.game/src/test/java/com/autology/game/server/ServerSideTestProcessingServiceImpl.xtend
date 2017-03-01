package com.autology.game.server

import com.autology.game.client.BootstrappingGWTTestCase
import de.itemis.xtend.auto.gwt.GwtService
import javax.servlet.annotation.WebServlet

@GwtService @WebServlet("/app/serverSideTestProcessingService") class ServerSideTestProcessingServiceImpl {
	override Void callServerSideMethod(String methodName) {
		BootstrappingGWTTestCase.currentTest.callServerSideMethod(methodName)
		return null
	}
}
