package net.opensorcerers.game.client

import com.google.gwt.core.client.Callback
import com.google.gwt.core.client.GWT
import com.google.gwt.core.client.ScriptInjector
import com.google.gwt.core.shared.GwtIncompatible
import com.google.gwt.dev.cfg.ModuleDef
import com.google.gwt.junit.PropertyDefiningStrategy
import com.google.gwt.junit.client.GWTTestCase
import java.util.ArrayList
import javax.servlet.annotation.WebServlet
import net.opensorcerers.coverage.GWTJacocoAdaptor
import net.opensorcerers.database.bootstrap.H2DatabaseConnectivity
import net.opensorcerers.game.client.lib.ChainReaction
import net.opensorcerers.game.server.ApplicationResources
import net.opensorcerers.game.shared.ServerSideTestProcessingService
import net.opensorcerers.game.shared.ServerSideTestProcessingServiceAsync
import net.opensorcerers.util.ReflectionsBootstrap
import org.reflections.Reflections
import org.reflections.scanners.SubTypesScanner
import org.reflections.scanners.TypeAnnotationsScanner

import static net.opensorcerers.game.server.ApplicationResources.*

abstract class BootstrappingGWTTestCase extends GWTTestCase {
	@GwtIncompatible protected static val databaseConnectivity = new H2DatabaseConnectivity

	@GwtIncompatible boolean needServerInitialization = true

	@GwtIncompatible def boolean checkInitializeServer() {
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

	def serverSidePrintln(String toPrint) { println(toPrint) }

	def serverPrintln(String toPrint) {
		GWT.<ServerSideTestProcessingServiceAsync>create(ServerSideTestProcessingService).callServerSideMethod(
			"serverSidePrintln",
			new ArrayList<Object> => [addAll(toPrint)],
			new ChainReaction().chainCallback[]
		)
	}

	/**
	 * Documentation said do not override or call this method. Didn't say anything about doing both.
	 */
	@GwtIncompatible override runTest() {
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
	def addServerMethod(extension ChainReaction chain, String methodName, Object... arguments) {
		return andThen[
			delayTestFinish(60000)
			GWT.<ServerSideTestProcessingServiceAsync>create(ServerSideTestProcessingService).callServerSideMethod(
				methodName,
				new ArrayList<Object> => [addAll(arguments)],
				chainCallback[]
			)
		]
	}

	def addServerMethod(extension ChainReaction chain, String methodName) {
		return chain.addServerMethod(methodName, #[])
	}

	/**
	 * Exists until release of fix for https://github.com/eclipse/xtext-lib/issues/40
	 * Marking Deprecated until then.
	 */
	@Deprecated def void afterInjectScript(String scriptPath, ()=>void callback) {
		val path = "" // '''/«moduleName».JUnit/«scriptPath»'''  
		ScriptInjector.fromUrl(path).setWindow(
			ScriptInjector.TOP_WINDOW
		).setCallback(callbackOrTestFailure[callback.apply]).inject
	}

	def static <T, F> Callback<T, F> callbackOrTestFailure((T)=>void handler) {
		return new Callback<T, F>() {
			override onSuccess(T result) { handler.apply(result) }

			override onFailure(F caught) {
				if (caught instanceof Throwable) {
					throw caught as Throwable
				} else {
					fail(caught.toString)
				}
			}
		}
	}

	@GwtIncompatible def void processUpdateCodeCoverageServer(String gwtCoverageJsonString) {
		GWTJacocoAdaptor.processCoverage(gwtCoverageJsonString)
	}

	def addUpdateCodeCoverage(extension ChainReaction chain) {
		return chain.addServerMethod("processUpdateCodeCoverageServer", TestExtensions.gwtCoverageJsonString)
	}
}
