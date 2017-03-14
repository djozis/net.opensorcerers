package net.opensorcerers.game.server.services

import com.google.gwt.user.client.rpc.AsyncCallback
import net.opensorcerers.framework.annotations.ImplementFrameworkServerService

@ImplementFrameworkServerService class TestClassImpl {
	override void sayHello(String x, AsyncCallback<String> callback) {
		callback.onSuccess('''Hello «threadLocalSessionId», you said «x»''')
	}
}
