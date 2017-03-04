package net.opensorcerers.game.server

import de.itemis.xtend.auto.gwt.GwtService
import java.util.List
import javax.servlet.annotation.WebServlet
import net.opensorcerers.game.client.BootstrappingGWTTestCase
import net.opensorcerers.game.shared.ResponseOrError

import static net.opensorcerers.game.shared.ResponseOrError.*

@GwtService @WebServlet("/app/serverSideTestProcessingService") class ServerSideTestProcessingServiceImpl {
	override ResponseOrError<Void> callServerSideMethod(String methodName, List<Object> arguments) {
		emptyResponseOrError[
			BootstrappingGWTTestCase.currentTest.callServerSideMethod(methodName, arguments.toArray)
		]
	}
}
