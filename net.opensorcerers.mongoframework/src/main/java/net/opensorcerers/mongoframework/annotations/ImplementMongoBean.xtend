package net.opensorcerers.mongoframework.annotations

import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import java.util.HashMap
import java.util.LinkedHashMap
import net.opensorcerers.mongoframework.lib.MongoBean
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationTarget
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
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

		val allFields = new LinkedHashMap<String, MutableFieldDeclaration>
		for (field : declaredFields) {
			allFields.put(field.simpleName, field)
		}
		val allMethods = new LinkedHashMap<String, MutableMethodDeclaration>
		for (method : declaredMethods) {
			allMethods.put(method.simpleName, method)
		}

		for (interface : implementedInterfaces.filter [
			type instanceof AnnotationTarget &&
				(type as AnnotationTarget).findAnnotation(ImplementMongoBeanMixin.findTypeGlobally) !== null
		]) {
			for (interfaceMethod : interface.declaredResolvedMethods) {
				val methodName = interfaceMethod.declaration.simpleName
				val TypeReference fieldType = if (methodName.startsWith("get") &&
						interfaceMethod.resolvedParameters.empty) {
						interfaceMethod.resolvedReturnType
					} else if (methodName.startsWith("set") && interfaceMethod.resolvedParameters.size == 1) {
						interfaceMethod.resolvedParameters.head.resolvedType
					} else {
						null
					}
				if (fieldType !== null) {
					val fieldName = methodName.substring(3).toFirstLower
					val existingField = allFields.get(fieldName)
					if (existingField === null) {
						allFields.put(fieldName, transformingClass.addField(fieldName) [
							primarySourceElement = interfaceMethod.declaration.primarySourceElement
							visibility = Visibility.PRIVATE
							type = fieldType
						])
					} else if (existingField.type != fieldType) {
						addError('''«interface.simpleName».«fieldName» type is «fieldType.toString» but «transformingClass.simpleName».«fieldName» type is «existingField.type»''')
					}
					val existingMethod = allMethods.get(methodName)
					if (existingMethod === null) {
						allMethods.put(methodName, transformingClass.addMethod(methodName) [
							primarySourceElement = interfaceMethod.declaration.primarySourceElement
							visibility = interfaceMethod.declaration.visibility
							returnType = interfaceMethod.resolvedReturnType
							for (parameter : interfaceMethod.resolvedParameters) {
								addParameter(parameter.declaration.simpleName, parameter.resolvedType)
							}
							body = '''
								«IF methodName.startsWith("get")»
									return this.«fieldName»;
								«ELSE»
									this.«fieldName» = «interfaceMethod.resolvedParameters.head.declaration.simpleName»;
								«ENDIF»
							'''
						])
					}
				}
			}
		}

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
					«IF !field.transient»
						result.put("«field.simpleName»", («
							Procedure2.newTypeReference(
								transformingClass.newTypeReference,
								field.type
							)
						») (it, v) -> it.«field.simpleName» = v);
					«ENDIF»
				«ENDFOR»
				return result;
			'''
		]

		addMethod("observeFields") [
			primarySourceElement = transformingClass.primarySourceElement

			addAnnotation(Override.newAnnotationReference)
			visibility = Visibility.PROTECTED
			returnType = void.newTypeReference
			addParameter("observer", Procedure2.newTypeReference(
				String.newTypeReference.newWildcardTypeReferenceWithLowerBound,
				Object.newTypeReference.newWildcardTypeReferenceWithLowerBound
			))
			body = '''
				«FOR field : transformingClass.declaredFields»
					«IF !field.transient»
						observer.apply("«field.simpleName»", this.«field.simpleName»);
					«ENDIF»
				«ENDFOR»
			'''
		]
	}
}
