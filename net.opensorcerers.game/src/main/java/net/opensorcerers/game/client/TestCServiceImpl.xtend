package net.opensorcerers.game.client

import com.google.gwt.user.client.rpc.AsyncCallback
import java.util.ArrayList
import net.opensorcerers.framework.annotations.ImplementFrameworkClientService

@ImplementFrameworkClientService class TestCServiceImpl {
	override void testMessage(String x, AsyncCallback<ArrayList<String>> callback) {
		callback.onSuccess(new ArrayList<String> => [add("Hello from client: " + x)])
	}
}