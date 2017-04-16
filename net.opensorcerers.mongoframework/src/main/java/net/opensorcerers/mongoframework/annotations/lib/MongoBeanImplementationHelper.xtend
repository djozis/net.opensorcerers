package net.opensorcerers.mongoframework.annotations.lib

import java.util.HashMap
import java.util.LinkedHashMap
import net.opensorcerers.mongoframework.lib.MongoBean
import net.opensorcerers.mongoframework.lib.MongoBeanMixin
import net.opensorcerers.mongoframework.lib.MongoBeanUtils
import net.opensorcerers.mongoframework.lib.filter.FilterBeanField
import net.opensorcerers.mongoframework.lib.filter.FilterExpression
import net.opensorcerers.mongoframework.lib.filter.FilterField
import net.opensorcerers.mongoframework.lib.filter.FilterNumberField
import net.opensorcerers.mongoframework.lib.index.IndexBeanField
import net.opensorcerers.mongoframework.lib.index.IndexField
import net.opensorcerers.mongoframework.lib.index.IndexModelExtended
import net.opensorcerers.mongoframework.lib.index.IndexStatementList
import net.opensorcerers.mongoframework.lib.project.ProjectBeanField
import net.opensorcerers.mongoframework.lib.project.ProjectField
import net.opensorcerers.mongoframework.lib.project.ProjectStatementList
import net.opensorcerers.mongoframework.lib.update.UpdateBeanField
import net.opensorcerers.mongoframework.lib.update.UpdateField
import net.opensorcerers.mongoframework.lib.update.UpdateNumberField
import net.opensorcerers.mongoframework.lib.update.UpdateStatementList
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtext.xbase.lib.Functions.Function1
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.eclipse.xtext.xbase.lib.Procedures.Procedure2

class MongoBeanImplementationHelper {
	def static String getUtilsClassName(TypeDeclaration declaration) {
		return declaration.qualifiedName.utilsClassName
	}

	def static String getUtilsClassName(String qualifiedName) {
		return qualifiedName + ".Utils"
	}

	def static String getFilterFieldClassName(TypeDeclaration declaration) {
		return declaration.qualifiedName.filterFieldClassName
	}

	def static String getFilterFieldClassName(String qualifiedName) {
		return qualifiedName + ".FilterField"
	}

	def static String getUpdateFieldClassName(TypeDeclaration declaration) {
		return declaration.qualifiedName.updateFieldClassName
	}

	def static String getUpdateFieldClassName(String qualifiedName) {
		return qualifiedName + ".UpdateField"
	}

	def static String getProjectFieldClassName(TypeDeclaration declaration) {
		return declaration.qualifiedName.projectFieldClassName
	}

	def static String getProjectFieldClassName(String qualifiedName) {
		return qualifiedName + ".ProjectField"
	}

	def static String getIndexFieldClassName(TypeDeclaration declaration) {
		return declaration.qualifiedName.indexFieldClassName
	}

	def static String getIndexFieldClassName(String qualifiedName) {
		return qualifiedName + ".IndexField"
	}

	def static doRegisterGlobals(TypeDeclaration annotatedClass, extension RegisterGlobalsContext context) {
		context.registerClass(annotatedClass.utilsClassName)
		context.registerClass(annotatedClass.filterFieldClassName)
		context.registerClass(annotatedClass.updateFieldClassName)
		context.registerClass(annotatedClass.projectFieldClassName)
		context.registerClass(annotatedClass.indexFieldClassName)
	}

	def static doTransform(MutableTypeDeclaration it, extension TransformationContext transformationContext) {
		val transformingClass = it

		val allFields = new LinkedHashMap<String, MutableFieldDeclaration>
		for (field : declaredFields) {
			allFields.put(field.simpleName, field)
		}
		val allMethods = new LinkedHashMap<String, MutableMethodDeclaration>
		for (method : declaredMethods) {
			allMethods.put(method.simpleName, method)
		}

		for (interface : appliedInterfaces.filter [
			MongoBeanMixin.newTypeReference.isAssignableFrom(it)
		]) {
			for (interfaceMethod : interface.declaredResolvedMethods.filter[!declaration.static]) {
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

		if (transformingClass instanceof MutableClassDeclaration) {
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
					super.«simpleName»(observer);
					«FOR field : transformingClass.declaredFields»
						«IF !field.transient»
							observer.apply("«field.simpleName»", this.«field.simpleName»);
						«ENDIF»
					«ENDFOR»
				'''
			]
		}

		val utilsClass = findClass(utilsClassName)

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
						return new «returnType.type.qualifiedName»("«field.simpleName»");
					} else {
						return new «returnType.type.qualifiedName»(this.getFieldName() + ".«field.simpleName»");
					}
				'''
			]
		}
		utilsClass.addMethod("filter") [
			primarySourceElement = transformingClass.primarySourceElement
			visibility = Visibility.PUBLIC
			abstract = false
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
						return new «returnType.type.qualifiedName»(this.getUpdateStatementList(), "«field.simpleName»");
					} else {
						return new «returnType.type.qualifiedName»(this.getUpdateStatementList(), this.getFieldName() + ".«field.simpleName»");
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
		utilsClass.addMethod("update") [
			primarySourceElement = transformingClass.primarySourceElement
			visibility = Visibility.PUBLIC
			abstract = false
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

		val projectFieldClass = findClass(projectFieldClassName)
		projectFieldClass.primarySourceElement = transformingClass.primarySourceElement
		projectFieldClass.extendedClass = ProjectBeanField.newTypeReference
		projectFieldClass.addConstructor [
			primarySourceElement = transformingClass.primarySourceElement
			visibility = Visibility.PUBLIC
			addParameter("projectStatementList", ProjectStatementList.newTypeReference)
			addParameter("fieldName", String.newTypeReference)
			body = '''
				super(projectStatementList, fieldName);
			'''
		]
		for (field : declaredFields) {
			projectFieldClass.addMethod("get" + field.simpleName.toFirstUpper) [
				primarySourceElement = field.primarySourceElement
				addAnnotation(Pure.newAnnotationReference)
				visibility = Visibility.PUBLIC
				returnType = transformationContext.getProjectFieldType(field.type)
				body = '''
					if (this.getFieldName() == null || this.getFieldName().isEmpty()) {
						return new «returnType.type.qualifiedName»(this.getProjectStatementList(), "«field.simpleName»");
					} else {
						return new «returnType.type.qualifiedName»(this.getProjectStatementList(), this.getFieldName() + ".«field.simpleName»");
					}
				'''
			]
		}
		utilsClass.addMethod("project") [
			primarySourceElement = transformingClass.primarySourceElement
			visibility = Visibility.PUBLIC
			abstract = false
			static = true
			returnType = ProjectStatementList.newTypeReference
			addParameter(
				"configurationCallback",
				Procedure1.newTypeReference(
					projectFieldClass.newTypeReference
				)
			)
			body = '''
				final «ProjectStatementList.name» projection = new «ProjectStatementList.name»();
				configurationCallback.apply(new «projectFieldClass.newTypeReference.toString»(projection, null));
				return projection;
			'''
		]

		val indexFieldClass = findClass(indexFieldClassName)
		indexFieldClass.primarySourceElement = transformingClass.primarySourceElement
		indexFieldClass.extendedClass = IndexBeanField.newTypeReference
		indexFieldClass.addConstructor [
			primarySourceElement = transformingClass.primarySourceElement
			visibility = Visibility.PUBLIC
			addParameter("indexStatementList", IndexStatementList.newTypeReference)
			addParameter("fieldName", String.newTypeReference)
			body = '''
				super(indexStatementList, fieldName);
			'''
		]
		for (field : declaredFields) {
			indexFieldClass.addMethod("get" + field.simpleName.toFirstUpper) [
				primarySourceElement = field.primarySourceElement
				addAnnotation(Pure.newAnnotationReference)
				visibility = Visibility.PUBLIC
				returnType = transformationContext.getIndexFieldType(field.type)
				body = '''
					if (this.getFieldName() == null || this.getFieldName().isEmpty()) {
						return new «returnType.type.qualifiedName»(this.getIndexStatementList(), "«field.simpleName»");
					} else {
						return new «returnType.type.qualifiedName»(this.getIndexStatementList(), this.getFieldName() + ".«field.simpleName»");
					}
				'''
			]
		}
		utilsClass.addMethod("index") [
			primarySourceElement = transformingClass.primarySourceElement
			visibility = Visibility.PUBLIC
			abstract = false
			static = true
			returnType = IndexModelExtended.newTypeReference
			addParameter(
				"configurationCallback",
				Procedure1.newTypeReference(
					indexFieldClass.newTypeReference
				)
			)
			body = '''
				final «IndexStatementList.name» keys = new «IndexStatementList.name»();
				configurationCallback.apply(new «indexFieldClass.newTypeReference.toString»(keys, null));
				return new «IndexModelExtended.newTypeReference.toString»(keys);
			'''
		]

		utilsClass.extendedClass = MongoBeanUtils.newTypeReference(
			transformingClass.newTypeReference,
			filterFieldClass.newTypeReference,
			updateFieldClass.newTypeReference,
			projectFieldClass.newTypeReference,
			indexFieldClass.newTypeReference
		)
	}

	def static TypeReference getFilterFieldType(extension TransformationContext context, TypeReference typeReference) {
		switch (typeReference) {
			case MongoBean.newTypeReference.isAssignableFrom(typeReference) ||
				MongoBeanMixin.newTypeReference.isAssignableFrom(typeReference):
				findTypeGlobally(typeReference.name.filterFieldClassName).newTypeReference
			case Number.newTypeReference.isAssignableFrom(typeReference):
				FilterNumberField.newTypeReference
			default:
				FilterField.newTypeReference
		}
	}

	def static TypeReference getUpdateFieldType(extension TransformationContext context, TypeReference typeReference) {
		switch (typeReference) {
			case MongoBean.newTypeReference.isAssignableFrom(typeReference) ||
				MongoBeanMixin.newTypeReference.isAssignableFrom(typeReference):
				typeReference.name.updateFieldClassName.findTypeGlobally.newTypeReference
			case Number.newTypeReference.isAssignableFrom(typeReference):
				UpdateNumberField.newTypeReference
			default:
				UpdateField.newTypeReference
		}
	}

	def static TypeReference getProjectFieldType(extension TransformationContext context, TypeReference typeReference) {
		switch (typeReference) {
			case MongoBean.newTypeReference.isAssignableFrom(typeReference) ||
				MongoBeanMixin.newTypeReference.isAssignableFrom(typeReference):
				typeReference.name.projectFieldClassName.findTypeGlobally.newTypeReference
			default:
				ProjectField.newTypeReference
		}
	}

	def static TypeReference getIndexFieldType(extension TransformationContext context, TypeReference typeReference) {
		switch (typeReference) {
			case MongoBean.newTypeReference.isAssignableFrom(typeReference) ||
				MongoBeanMixin.newTypeReference.isAssignableFrom(typeReference):
				typeReference.name.indexFieldClassName.findTypeGlobally.newTypeReference
			default:
				IndexField.newTypeReference
		}
	}

	def static dispatch appliedInterfaces(MutableClassDeclaration it) { return implementedInterfaces }

	def static dispatch appliedInterfaces(MutableInterfaceDeclaration it) { return extendedInterfaces }
}
