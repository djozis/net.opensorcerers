package net.opensorcerers.mongoframework.annotations

import com.mongodb.async.client.MongoDatabase
import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import net.opensorcerers.mongoframework.lib.MongoBeanCollection
import org.eclipse.xtend.lib.macro.AbstractMethodProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration

@Target(ElementType.METHOD)
@Active(MongoBeanCollectionsInitializerProcessor)
@Retention(SOURCE)
annotation MongoBeanCollectionsInitializer {
}

class MongoBeanCollectionsInitializerProcessor extends AbstractMethodProcessor {
	override doTransform(MutableMethodDeclaration it, extension TransformationContext context) {
		if (parameters.size != 1 || parameters.head.type != MongoDatabase.newTypeReference ||
			parameters.head.simpleName != "database") {
			addError('''Must have exactly one parameter which is of type «MongoDatabase.simpleName» and named "database"''')
		} else {
			body = '''
				«FOR field : declaringType.declaredFields.filter[!static && MongoBeanCollection.findTypeGlobally == type.type]»
					this.«field.simpleName» = new «field.type»(«field.type.actualTypeArguments.head.type.qualifiedName».class, database, "«field.simpleName»") {};
				«ENDFOR»
			'''
		}
	}
}
