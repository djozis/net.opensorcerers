package net.opensorcerers.game.client

import co.paralleluniverse.fibers.Fiber
import co.paralleluniverse.strands.SuspendableCallable
import co.paralleluniverse.strands.SuspendableRunnable
import com.google.gwt.core.client.Callback
import com.google.gwt.core.client.GWT
import com.google.gwt.core.client.ScriptInjector
import com.google.gwt.core.shared.GwtIncompatible
import com.google.gwt.dev.cfg.ModuleDef
import com.google.gwt.junit.PropertyDefiningStrategy
import com.google.gwt.junit.client.GWTTestCase
import java.util.ArrayList
import java.util.logging.Logger
import javax.servlet.annotation.WebServlet
import net.opensorcerers.coverage.GWTJacocoAdaptor
import net.opensorcerers.game.client.lib.chainreaction.ChainLinkAPI
import net.opensorcerers.game.client.lib.chainreaction.ChainReaction
import net.opensorcerers.game.server.ApplicationResources
import net.opensorcerers.game.server.mongo.TestDatabaseConnectivity
import net.opensorcerers.game.shared.ServerSideTestProcessingService
import net.opensorcerers.game.shared.ServerSideTestProcessingServiceAsync
import net.opensorcerers.util.ReflectionsBootstrap
import org.eclipse.xtend.lib.annotations.Accessors
import org.reflections.Reflections
import org.reflections.scanners.SubTypesScanner
import org.reflections.scanners.TypeAnnotationsScanner

import static net.opensorcerers.game.server.ApplicationResources.*

abstract class BootstrappingGWTTestCase extends GWTTestCase {
	@Accessors val logger = Logger.getLogger(class.simpleName)

	@GwtIncompatible protected static val databaseConnectivity = new TestDatabaseConnectivity

	@GwtIncompatible def getDatabase() { return ApplicationResources.instance.database }

	@GwtIncompatible def inSynchronizedFiber(SuspendableRunnable callback) { new Fiber(callback).start.get }

	@GwtIncompatible def <T> inSynchronizedFiber(SuspendableCallable<T> callback) {
		return new Fiber(callback).start.get
	}

	@GwtIncompatible static boolean needServerInitialization = true

	@GwtIncompatible static def boolean checkInitializeServer() {
		if (needServerInitialization) {
			needServerInitialization = false
			if (ApplicationResources.instance !== null) {
				ApplicationResources.instance.close
			}
			ApplicationResources.instance = new ApplicationResources(
				databaseConnectivity
			)
			return true
		}
		return false
	}

	@GwtIncompatible val strategy = new PropertyDefiningStrategy(this) {
		override void processModule(ModuleDef module) {
			super.processModule(module)
			ReflectionsBootstrap.checkBootstrap
			new Reflections(
				"net.opensorcerers",
				ReflectionsBootstrap.urls,
				new TypeAnnotationsScanner,
				new SubTypesScanner
			).getTypesAnnotatedWith(WebServlet).forEach [ servletClass |
				val servletAnnotation = servletClass.getAnnotation(WebServlet)
				for (urlPattern : (servletAnnotation.value + servletAnnotation.urlPatterns).toSet.map [
					// "/app" prefix comes from rename to attribute in gwt.xml for module
					if(startsWith("/app/")) replaceFirst("/app/", "/") else it
				]) {
					module.mapServlet(urlPattern, servletClass.name)
				}
			]
		}
	}

	@GwtIncompatible override getStrategy() { return strategy }

	@GwtIncompatible static var BootstrappingGWTTestCase currentTest = null

	@GwtIncompatible def static getCurrentTest() { return currentTest }

	/**
	 * Documentation said do not override or call this method. Didn't say anything about doing both.
	 */
	@GwtIncompatible override runTest() {
		checkInitializeServer
		currentTest = this
		GWTJacocoAdaptor.setGwtCoveragePaths
		super.runTest
	}

	@GwtIncompatible def callServerSideMethod(String methodName, Object... arguments) {
		checkInitializeServer
		return class.methods.filter [
			name == methodName && parameterTypes.length == arguments.length
		].head.invoke(this, arguments)
	}

	/**
	 * Executes one of this test classes methods on the server.
	 */
	def callServerMethod(String methodName, Object... arguments) {
		ChainReaction.chain [
			delayTestFinish(60000)
			GWT.<ServerSideTestProcessingServiceAsync>create(ServerSideTestProcessingService).callServerSideMethod(
				methodName,
				new ArrayList<Object> => [addAll(arguments)],
				ifSuccessful[]
			)
		]
	}

	def callServerMethod(String methodName) { callServerMethod(methodName, #[]) }

	def void injectScripts(String... scriptPaths) {
		ChainReaction.chain [
			delayTestFinish(10000)
			for (scriptPath : scriptPaths) {
				// '''/«moduleName».JUnit/«scriptPath»'''
				ScriptInjector.fromUrl("/" + moduleName + ".JUnit/" + scriptPath).setWindow(
					ScriptInjector.TOP_WINDOW
				).setCallback(callbackOrTestFailure[]).inject
			}
		]
	}

	def static <T, F> Callback<T, F> callbackOrTestFailure(ChainLinkAPI chain, (T)=>void handler) {
		return new Callback<T, F>() {
			val delegate = chain.ifSuccessful(handler).ifFailure[throw it]

			override onSuccess(T result) { delegate.onSuccess(result) }

			override onFailure(F caught) {
				if (caught instanceof Throwable) {
					delegate.onFailure(caught)
				} else {
					fail(caught.toString)
				}
			}
		}
	}

	@GwtIncompatible def void processUpdateCodeCoverageServer(String gwtCoverageJsonString) {
		GWTJacocoAdaptor.processCoverage(gwtCoverageJsonString)
	}

	def postCodeCoverage() {
		callServerMethod("processUpdateCodeCoverageServer", TestExtensions.gwtCoverageJsonString)
	}
}
