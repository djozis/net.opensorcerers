package net.opensorcerers.game.server

import com.google.gwt.user.client.rpc.AsyncCallback
import java.util.ArrayList
import net.opensorcerers.framework.annotations.ImplementFrameworkServerService

@ImplementFrameworkServerService class TestClassImpl {
	override void sayHello(String x, AsyncCallback<ArrayList<String>> callback) {
		callback.onSuccess(new ArrayList<String> => [add("Hello: " + x)])
	}

	override void testSessionId(String sessionId, AsyncCallback<Void> callback) {
		new TestCServiceProxy(vertx.eventBus, sessionId).testMessage("Server message", new AsyncCallback<ArrayList<String>> {
			override onFailure(Throwable caught) {
				caught.printStackTrace
			}

			override onSuccess(ArrayList<String> result) {
				println("GOT RESPONSE: " + result.toString)
			}
		})
	}
}
