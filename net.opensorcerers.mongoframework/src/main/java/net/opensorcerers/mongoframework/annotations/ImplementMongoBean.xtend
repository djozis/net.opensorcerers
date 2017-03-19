package net.opensorcerers.mongoframework.annotations

import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import java.util.HashMap
import java.util.LinkedHashMap
import net.opensorcerers.mongoframework.lib.MongoBean
import net.opensorcerers.mongoframework.lib.filter.FilterBeanField
import net.opensorcerers.mongoframework.lib.filter.FilterExpression
import net.opensorcerers.mongoframework.lib.filter.FilterField
import net.opensorcerers.mongoframework.lib.filter.FilterNumberField
import net.opensorcerers.mongoframework.lib.update.UpdateBeanField
import net.opensorcerers.mongoframework.lib.update.UpdateField
import net.opensorcerers.mongoframework.lib.update.UpdateNumberField
import net.opensorcerers.mongoframework.lib.update.UpdateStatementList
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationTarget
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtext.xbase.lib.Functions.Function1
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.eclipse.xtext.xbase.lib.Procedures.Procedure2

@Target(ElementType.TYPE)
@Active(ImplementMongoBeanProcessor)
@Retention(SOURCE)
annotation ImplementMongoBean {
}

class ImplementMongoBeanProcessor extends AbstractClassProcessor {
	def static String getFilterFieldClassName(ClassDeclaration declaration) {
		return declaration.qualifiedName.filterFieldClassName
	}

	def static String getFilterFieldClassName(String qualifiedName) {
		return qualifiedName + ".FilterField"
	}

	def static String getUpdateFieldClassName(ClassDeclaration declaration) {
		return declaration.qualifiedName.updateFieldClassName
	}

	def static String getUpdateFieldClassName(String qualifiedName) {
		return qualifiedName + ".UpdateField"
	}

	override doRegisterGlobals(ClassDeclaration annotatedClass, extension RegisterGlobalsContext context) {
		context.registerClass(annotatedClass.filterFieldClassName)
		context.registerClass(annotatedClass.updateFieldClassName)
	}

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

		val filterFieldClass = findClass(filterFieldClassName)
		filterFieldClass.primarySourceElement = transformingClass.primarySourceElement
		filterFieldClass.extendedClass = FilterBeanField.newTypeReference
		filterFieldClass.addConstructor [
			primarySourceElement = transformingClass.primarySourceElement
			visibility = Visibility.PUBLIC
			addParameter("fieldName", String.newTypeReference)
			body = '''
				super(fieldName);
			'''
		]
		for (field : declaredFields) {
			filterFieldClass.addMethod("get" + field.simpleName.toFirstUpper) [
				primarySourceElement = field.primarySourceElement
				visibility = Visibility.PUBLIC
				returnType = transformationContext.getFilterFieldType(field.type)
				body = '''
					if (this.getFieldName() == null || this.getFieldName().isEmpty()) {
						return new «returnType.toString»("«field.simpleName»");
					} else {
						return new «returnType.toString»(this.getFieldName() + ".«field.simpleName»");
					}
				'''
			]
		}
		addMethod("filter") [
			primarySourceElement = transformingClass.primarySourceElement
			visibility = Visibility.PUBLIC
			static = true
			returnType = FilterExpression.newTypeReference
			addParameter(
				"configurationCallback",
				Function1.newTypeReference(
					filterFieldClass.newTypeReference,
					FilterExpression.newTypeReference
				)
			)
			body = '''
				return configurationCallback.apply(new «filterFieldClass.newTypeReference.toString»(null));
			'''
		]

		val updateFieldClass = findClass(updateFieldClassName)
		updateFieldClass.primarySourceElement = transformingClass.primarySourceElement
		updateFieldClass.extendedClass = UpdateBeanField.newTypeReference
		updateFieldClass.addConstructor [
			primarySourceElement = transformingClass.primarySourceElement
			visibility = Visibility.PUBLIC
			addParameter("updateStatementList", UpdateStatementList.newTypeReference)
			addParameter("fieldName", String.newTypeReference)
			body = '''
				super(updateStatementList, fieldName);
			'''
		]
		for (field : declaredFields) {
			updateFieldClass.addMethod("get" + field.simpleName.toFirstUpper) [
				primarySourceElement = field.primarySourceElement
				visibility = Visibility.PUBLIC
				returnType = transformationContext.getUpdateFieldType(field.type)
				body = '''
					if (this.getFieldName() == null || this.getFieldName().isEmpty()) {
						return new «returnType.toString»(this.getUpdateStatementList(), "«field.simpleName»");
					} else {
						return new «returnType.toString»(this.getUpdateStatementList(), this.getFieldName() + ".«field.simpleName»");
					}
				'''
			]
			updateFieldClass.addMethod("set" + field.simpleName.toFirstUpper) [
				primarySourceElement = field.primarySourceElement
				visibility = Visibility.PUBLIC
				returnType = void.newTypeReference
				addParameter(field.simpleName, field.type)
				body = '''
					this.get«field.simpleName.toFirstUpper»().set(«field.simpleName»);
				'''
			]
		}
		addMethod("update") [
			primarySourceElement = transformingClass.primarySourceElement
			visibility = Visibility.PUBLIC
			static = true
			returnType = UpdateStatementList.newTypeReference
			addParameter(
				"configurationCallback",
				Procedure1.newTypeReference(
					updateFieldClass.newTypeReference
				)
			)
			body = '''
				final «UpdateStatementList.name» updates = new «UpdateStatementList.name»();
				configurationCallback.apply(new «updateFieldClass.newTypeReference.toString»(updates, null));
				return updates;
			'''
		]
	}

	def static TypeReference getFilterFieldType(extension TransformationContext context, TypeReference typeReference) {
		switch (typeReference) {
			case MongoBean.newTypeReference.isAssignableFrom(typeReference):
				findClass(typeReference.name.filterFieldClassName).newTypeReference
			case Number.newTypeReference.isAssignableFrom(typeReference):
				FilterNumberField.newTypeReference
			default:
				FilterField.newTypeReference
		}
	}

	def static TypeReference getUpdateFieldType(extension TransformationContext context, TypeReference typeReference) {
		switch (typeReference) {
			case MongoBean.newTypeReference.isAssignableFrom(typeReference):
				findClass(typeReference.name.updateFieldClassName).newTypeReference
			case Number.newTypeReference.isAssignableFrom(typeReference):
				UpdateNumberField.newTypeReference
			default:
				UpdateField.newTypeReference
		}
	}
}