package net.opensorcerers.game.server

import de.itemis.xtend.auto.gwt.GwtService
import java.util.List
import javax.servlet.annotation.WebServlet
import net.opensorcerers.game.client.BootstrappingGWTTestCase

@GwtService @WebServlet("/app/serverSideTestProcessingService") class ServerSideTestProcessingServiceImpl {
	override Void callServerSideMethod(String methodName, List<Object> arguments) {
		BootstrappingGWTTestCase.currentTest.callServerSideMethod(methodName, arguments.toArray)
		return null
	}
}
