package net.opensorcerers.game.server

import com.google.gwt.user.client.rpc.AsyncCallback
import java.util.ArrayList
import net.opensorcerers.framework.annotations.ImplementFrameworkServerService

@ImplementFrameworkServerService class TestClassImpl {
	override void sayHello(String x, AsyncCallback<ArrayList<String>> callback) {
		callback.onSuccess(new ArrayList<String> => [add('''Hello: «x»''')])
	}
}
