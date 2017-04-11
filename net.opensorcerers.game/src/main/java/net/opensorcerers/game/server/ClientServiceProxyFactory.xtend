package net.opensorcerers.game.server

import io.vertx.core.eventbus.EventBus
import net.opensorcerers.framework.server.FrameworkClientServiceProxy
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class ClientServiceProxyFactory {
	val EventBus eventBus
	val String sessionId

	def <T extends FrameworkClientServiceProxy> T instanciate(Class<T> proxyClass) {
		return proxyClass.getConstructor(EventBus, String).newInstance(eventBus, sessionId)
	}
}
