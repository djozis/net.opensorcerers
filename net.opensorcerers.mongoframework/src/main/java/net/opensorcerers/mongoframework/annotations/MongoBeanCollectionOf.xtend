package net.opensorcerers.mongoframework.annotations

import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import net.opensorcerers.mongoframework.lib.MongoBean
import net.opensorcerers.mongoframework.lib.MongoBeanCollection
import net.opensorcerers.mongoframework.lib.MongoBeanMixin
import org.eclipse.xtend.lib.macro.AbstractFieldProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility

@Target(ElementType.FIELD)
@Active(MongoBeanCollectionOfProcessor)
@Retention(SOURCE)
annotation MongoBeanCollectionOf {
}

class MongoBeanCollectionOfProcessor extends AbstractFieldProcessor {
	override doTransform(MutableFieldDeclaration it, extension TransformationContext context) {
		val transformingField = it
		if (!MongoBean.newTypeReference.isAssignableFrom(it.type) &&
			!MongoBeanMixin.newTypeReference.isAssignableFrom(it.type)) {
			addError('''«it.simpleName» must be declared as of a sub-type of «MongoBean.simpleName» or  «MongoBeanMixin.simpleName» since it is annotated with «MongoBeanCollectionOf.simpleName»''')
		} else {
			val utilsType = (it.type.type.qualifiedName + ".Utils").findTypeGlobally.newTypeReference
			it.type = MongoBeanCollection.newTypeReference(
				#[utilsType] + utilsType.declaredSuperTypes.head.actualTypeArguments
			)
			declaringType.addMethod('''get«simpleName.toFirstUpper»''') [
				primarySourceElement = transformingField.primarySourceElement
				visibility = Visibility.PUBLIC
				returnType = transformingField.type
				body = '''return this.«transformingField.simpleName»;'''
			]
		}
	}
}
