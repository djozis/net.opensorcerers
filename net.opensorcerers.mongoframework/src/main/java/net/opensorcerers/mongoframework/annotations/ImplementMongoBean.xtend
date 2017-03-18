package net.opensorcerers.mongoframework.annotations

import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import java.util.HashMap
import net.opensorcerers.mongoframework.lib.MongoBean
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtext.xbase.lib.Procedures.Procedure2

@Target(ElementType.TYPE)
@Active(ImplementMongoBeanProcessor)
@Retention(SOURCE)
annotation ImplementMongoBean {
}

class ImplementMongoBeanProcessor extends AbstractClassProcessor {
	override doTransform(MutableClassDeclaration it, extension TransformationContext transformationContext) {
		if (extendedClass == Object.newTypeReference) {
			extendedClass = MongoBean.newTypeReference
		}
		if (!MongoBean.newTypeReference.isAssignableFrom(extendedClass)) {
			addError('''«ImplementMongoBean.simpleName» cannot extend a class that doesn't extend «MongoBean.name»''')
		}

		val transformingClass = it

		addMethod("createFieldSettersLookup") [
			primarySourceElement = transformingClass.primarySourceElement
			val fieldSettersHashMapTypeReference = HashMap.newTypeReference(
				String.newTypeReference,
				Procedure2.newTypeReference(
					MongoBean.newTypeReference.newWildcardTypeReference,
					newWildcardTypeReference
				)
			)

			visibility = Visibility.PUBLIC
			static = true
			returnType = fieldSettersHashMapTypeReference
			body = '''
				final «fieldSettersHashMapTypeReference.toString» result = «transformingClass.extendedClass.toString».createFieldSettersLookup();
				«FOR field : transformingClass.declaredFields»
					result.put("«field.simpleName»", («
						Procedure2.newTypeReference(
							transformingClass.newTypeReference,
							field.type
						)
					») (it, v) -> it.«field.simpleName» = v);
				«ENDFOR»
				return result;
			'''
		]

		addMethod("observeFields") [
			addAnnotation(Override.newAnnotationReference)
			visibility = Visibility.PROTECTED
			returnType = void.newTypeReference
			addParameter("observer", Procedure2.newTypeReference(
				String.newTypeReference.newWildcardTypeReferenceWithLowerBound,
				Object.newTypeReference.newWildcardTypeReferenceWithLowerBound
			))
			body = '''
				«FOR field : transformingClass.declaredFields»
					observer.apply("«field.simpleName»", this.«field.simpleName»);
				«ENDFOR»
			'''
		]
	}
}
