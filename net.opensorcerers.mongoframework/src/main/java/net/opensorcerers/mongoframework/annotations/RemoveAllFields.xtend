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
@Active(RemoveAllFieldsProcessor)
@Retention(SOURCE)
annotation RemoveAllFields {
}

class RemoveAllFieldsProcessor implements TransformationParticipant<MutableInterfaceDeclaration> {
	override doTransform(
		List<? extends MutableInterfaceDeclaration> annotatedTargetElements,
		extension TransformationContext context
	) {
		annotatedTargetElements.forEach [
			declaredFields.forEach[remove]
			declaredMembers.forEach[remove]
		]
	}
}
