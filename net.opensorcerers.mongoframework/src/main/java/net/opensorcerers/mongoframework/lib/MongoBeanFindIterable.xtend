package net.opensorcerers.mongoframework.lib

import com.mongodb.async.client.FindIterable
import java.lang.reflect.Constructor
import org.eclipse.xtend.lib.annotations.Delegate
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import net.opensorcerers.mongoframework.lib.project.ProjectStatementList

@FinalFieldsConstructor class MongoBeanFindIterable<T, Project> implements FindIterable<T> {
	@Delegate val FindIterable<T> iterable
	val Constructor<Project> projectionConstructor

	def projection((Project)=>void projection) {
		val ProjectStatementList built = new ProjectStatementList
		projection.apply(projectionConstructor.newInstance(built, null))
		return projection(built)
	}
}
