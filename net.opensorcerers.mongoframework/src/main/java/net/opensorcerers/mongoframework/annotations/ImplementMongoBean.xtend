package net.opensorcerers.mongoframework.annotations

import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import net.opensorcerers.mongoframework.annotations.lib.MongoBeanImplementationHelper
import net.opensorcerers.mongoframework.lib.MongoBean
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration

@Target(ElementType.TYPE)
@Active(ImplementMongoBeanProcessor)
@Retention(SOURCE)
annotation ImplementMongoBean {
}

class ImplementMongoBeanProcessor extends AbstractClassProcessor {
	override doRegisterGlobals(ClassDeclaration it, extension RegisterGlobalsContext context) {
		MongoBeanImplementationHelper.doRegisterGlobals(it, context)
	}

	override doTransform(MutableClassDeclaration it, extension TransformationContext transformationContext) {
		if (extendedClass == Object.newTypeReference) {
			extendedClass = MongoBean.newTypeReference
		}
		if (!MongoBean.newTypeReference.isAssignableFrom(extendedClass)) {
			addError('''«ImplementMongoBean.simpleName» cannot extend a class that doesn't extend «MongoBean.name»''')
		}

		MongoBeanImplementationHelper.doTransform(it, transformationContext)
	}
}
