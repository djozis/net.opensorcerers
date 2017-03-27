package net.opensorcerers.game.server

import java.io.IOException
import java.io.InputStream
import java.util.logging.Level
import java.util.logging.Logger
import javax.servlet.ServletConfig
import javax.servlet.ServletException
import javax.servlet.annotation.WebServlet
import javax.servlet.http.HttpServlet
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse
import org.apache.commons.io.IOUtils

@WebServlet("/webjars/*", "/xtext/*") class StaticResourcesServlet extends HttpServlet {
	static final Logger logger = Logger.getLogger(StaticResourcesServlet.name)
	boolean disableCache = false

	override void init(ServletConfig config) throws ServletException {
		try {
			var String disableCache = config.getInitParameter("disableCache")
			if (disableCache !== null) {
				this.disableCache = Boolean.parseBoolean(disableCache)
				logger.log(Level.INFO, '''StaticResourcesServlet cache enabled: «!this.disableCache»''')
			}
		} catch (Exception e) {
			logger.log(Level.WARNING, "The StaticResourcesServlet configuration parameter \"disableCache\" is invalid")
		}

		logger.log(Level.INFO, "StaticResourcesServlet initialization completed")
	}

	override protected void doGet(
		HttpServletRequest request,
		HttpServletResponse response
	) throws ServletException, IOException {
		println("X: get")
		val resourcesTopDirectory = request.servletPath.split("/").last
		var String resourceURI = '''/META-INF/resources/«resourcesTopDirectory»«request.pathInfo»'''
		logger.log(Level.INFO, '''Webjars resource requested: «resourceURI»''')
		var InputStream inputStream = class.getResourceAsStream(resourceURI)
		println("X: getResourceAsStream")
		if (inputStream !== null) {
		println("X: not null")
			if (!disableCache && resourcesTopDirectory == "webjars") {
				prepareCacheHeaders(response, resourceURI)
			}
			var String filename = getFileName(resourceURI)
			var String mimeType = request.getSession().getServletContext().getMimeType(filename)
			response.setContentType(if(mimeType !== null) mimeType else "application/octet-stream")
		println("X: set type")
			IOUtils.copy(inputStream, response.getOutputStream())
		println("X: done copy")
		} else {
			response.sendError(HttpServletResponse.SC_NOT_FOUND)
		}
		println("X: endget")
	}

	def private String getFileName(String resourceURI) { return resourceURI.split("/").last }

	static final long DEFAULT_EXPIRE_TIME_S = 86400L // 1 day

	def private void prepareCacheHeaders(HttpServletResponse response, String resourceURI) {
		var String[] tokens = resourceURI.split("/")
		var String version = tokens.get(5)
		var String fileName = tokens.last
		var String eTag = '''«fileName»_«version»'''
		response.setHeader("ETag", eTag)
		response.setDateHeader("Expires", System.currentTimeMillis() + DEFAULT_EXPIRE_TIME_S * 1000L)
		response.addHeader("Cache-Control", '''private, max-age=«DEFAULT_EXPIRE_TIME_S»''')
	}
}
