package net.opensorcerers.util

import java.io.File
import java.net.URISyntaxException
import java.net.URL
import java.util.ArrayList
import java.util.Collections
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.reflections.util.ClasspathHelper
import org.reflections.vfs.Vfs

/**
 * During unit testing, avoid spam of: org.reflections.ReflectionsException: could not create Vfs.Dir from url, no matching UrlType was found
 */
class ReflectionsBootstrap {
	static boolean needRegister = false // Change to true to enable extension filtering - seems unneeded

	def static void checkBootstrap() {
		if (needRegister) {
			Vfs.setDefaultURLTypes(new ArrayList<Vfs.UrlType> => [
				add(new EmptyIfFileExtensionsUrlType(#{"_trace", ".xtendbin"}))
				addAll(Vfs.DefaultUrlTypes.values)
			])
			needRegister = false
		}
	}

	def static toFile(URL url) {
		return try {
			new File(url.toURI)
		} catch (URISyntaxException e) {
			new File(url.path)
		}
	}

	@Accessors static val urls = ClasspathHelper.forClassLoader().filter [
		protocol != "file" || toFile.exists
	].toList

	@FinalFieldsConstructor private static class EmptyIfFileExtensionsUrlType implements Vfs.UrlType {
		val Set<String> fileEndings

		override boolean matches(URL url) {
			return url.protocol == "file" && fileEndings.contains(url.toExternalForm.split(".").last)
		}

		override Vfs.Dir createDir(URL url) throws Exception {
			return new Vfs.Dir() {
				override String getPath() { return url.toExternalForm }

				override Iterable<Vfs.File> getFiles() { return Collections.emptyList }

				override void close() {}
			}
		}
	}
}
