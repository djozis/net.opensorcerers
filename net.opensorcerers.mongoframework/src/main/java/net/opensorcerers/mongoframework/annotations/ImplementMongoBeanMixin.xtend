package net.opensorcerers.mongoframework.annotations

import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import java.util.List
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration

@Target(ElementType.TYPE)
@Active(ImplementMongoBeanMixinProcessor)
@Retention(SOURCE)
annotation ImplementMongoBeanMixin {
}

class ImplementMongoBeanMixinProcessor implements TransformationParticipant<MutableInterfaceDeclaration> {
	def doTransform(MutableInterfaceDeclaration it, extension TransformationContext context) {
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
}
