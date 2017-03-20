package net.opensorcerers.mongoframework.annotations

import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import java.util.List
import net.opensorcerers.mongoframework.annotations.lib.MongoBeanImplementationHelper
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsParticipant
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration

@Target(ElementType.TYPE)
@Active(ImplementMongoBeanMixinProcessor)
@Retention(SOURCE)
annotation ImplementMongoBeanMixin {
}

class ImplementMongoBeanMixinProcessor implements TransformationParticipant<MutableInterfaceDeclaration>, RegisterGlobalsParticipant<InterfaceDeclaration> {
	def void doRegisterGlobals(InterfaceDeclaration it, RegisterGlobalsContext context) {
		MongoBeanImplementationHelper.doRegisterGlobals(it, context)
	}

	def doTransform(MutableInterfaceDeclaration it, extension TransformationContext transformationContext) {
		MongoBeanImplementationHelper.doTransform(it, transformationContext)

		for (field : declaredFields) {
			addMethod('''get«field.simpleName.toFirstUpper»''') [
				visibility = field.visibility
				returnType = field.type
			]
			addMethod('''set«field.simpleName.toFirstUpper»''') [
				visibility = field.visibility
				returnType = void.newTypeReference
				addParameter(field.simpleName, field.type)
			]
			field.remove
		}
	}

	override doTransform(
		List<? extends MutableInterfaceDeclaration> annotatedTargetElements,
		extension TransformationContext context
	) {
		for (target : annotatedTargetElements) {
			target.doTransform(context)
		}
	}

	override doRegisterGlobals(List<? extends InterfaceDeclaration> annotatedSourceElements,
		extension RegisterGlobalsContext context) {
		for (annotatedSourceElement : annotatedSourceElements) {
			doRegisterGlobals(annotatedSourceElement, context)
		}
	}
}
