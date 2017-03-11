package net.opensorcerers.framework.annotations

import com.google.gson.JsonArray
import com.google.gson.JsonElement
import com.google.gson.JsonNull
import com.google.gwt.core.shared.GwtIncompatible
import com.google.gwt.json.client.JSONArray
import com.google.gwt.json.client.JSONNull
import com.google.gwt.json.client.JSONValue
import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import java.util.HashMap
import java.util.Map
import java.util.Set
import net.opensorcerers.framework.client.JsonSerializationClient
import net.opensorcerers.framework.server.JsonSerializationServer
import net.opensorcerers.framework.shared.JsonSerializableMethods
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility

@Target(ElementType.TYPE)
@Active(JsonSerializationMethodsProcessor)
@Retention(SOURCE)
annotation JsonSerializationMethods {
}

class JsonSerializationMethodsProcessor extends AbstractClassProcessor {
	@Accessors static val SERIALIZE_CLIENT_METHOD_NAME = "serializeToJsonClient"
	@Accessors static val DESERIALIZE_CLIENT_METHOD_NAME = "deserializeFromJsonClient"
	@Accessors static val SERIALIZE_SERVER_METHOD_NAME = "serializeToJsonServer"
	@Accessors static val DESERIALIZE_SERVER_METHOD_NAME = "deserializeFromJsonServer"

	static var Set<TypeReference> serializeClientFieldMethodTypes
	static var Set<TypeReference> serializeServerFieldMethodTypes

	static class ProcessorContext {
		val arrayName = "v"
		val fieldVar = "f"

		val MutableClassDeclaration beanClass
		extension val TransformationContext transformationContext

		new(MutableClassDeclaration beanClass, extension TransformationContext transformationContext) {
			this.beanClass = beanClass
			this.transformationContext = transformationContext

			serializeClientFieldMethodTypes = JsonSerializationClient.methods.filter [
				name == "serialize"
			].map[parameterTypes.head.newTypeReference].toSet
			serializeServerFieldMethodTypes = JsonSerializationServer.methods.filter [
				name == "serialize"
			].map[parameterTypes.head.newTypeReference].toSet
		}
	}

	override doTransform(MutableClassDeclaration it, extension TransformationContext transformationContext) {
		if (extendedClass != Object.newTypeReference) {
			addError("A service must not extend another class.")
		}
		implementedInterfaces = implementedInterfaces + #[JsonSerializableMethods.newTypeReference]

		val extension processorContext = new ProcessorContext(it, transformationContext)

		// This must be done before method body so that addError works.
		val fieldSerializationOperations = new HashMap<MutableFieldDeclaration, Map<String, String>> => [ fieldMap |
			declaredFields.forEach [ field, index |
				fieldMap.put(field, #{
					SERIALIZE_CLIENT_METHOD_NAME ->
						field.serializeClientField(field.type, '''this.«field.simpleName»''', 0, processorContext),
					DESERIALIZE_CLIENT_METHOD_NAME ->
						field.deserializeClientField(field.type, fieldVar, 0, processorContext),
					SERIALIZE_SERVER_METHOD_NAME ->
						field.serializeServerField(field.type, '''this.«field.simpleName»''', 0, processorContext),
					DESERIALIZE_SERVER_METHOD_NAME ->
						field.deserializeServerField(field.type, fieldVar, 0, processorContext)
				})
			]
		]

		addMethod(SERIALIZE_CLIENT_METHOD_NAME) [
			primarySourceElement = beanClass.primarySourceElement
			addAnnotation(Override.newAnnotationReference)
			addAnnotation(Pure.newAnnotationReference)
			visibility = Visibility::PUBLIC
			returnType = JSONValue.newTypeReference
			it.body = '''
				«var arrayIndex = 0»
				«JSONArray.name» «arrayName» = new «JSONArray.name»();
				«FOR field : beanClass.declaredFields.filter[!transient]»
					«val fieldIndex = arrayIndex++»
					«IF !field.type.primitive»
						if (this.«field.simpleName» == null) {
							«arrayName».set(«fieldIndex», «JSONNull.name».getInstance());
						} else
					«ENDIF»
					«val conversionExpression = fieldSerializationOperations.get(field).get(simpleName)»
					«IF conversionExpression === null»
						«Exceptions.name».sneakyThrow(new «IllegalArgumentException.name»(
							"Don't know how to client-serialize «field.type.name» «field.simpleName»"
						));
					«ELSE»
						«arrayName».set(«fieldIndex», «fieldSerializationOperations.get(field).get(simpleName)»);
					«ENDIF»
				«ENDFOR»
				return «arrayName»;
			'''
		]
		addMethod(DESERIALIZE_CLIENT_METHOD_NAME) [
			primarySourceElement = beanClass.primarySourceElement
			addAnnotation(Override.newAnnotationReference)
			visibility = Visibility::PUBLIC
			returnType = beanClass.newTypeReference
			addParameter("jsonValue", JSONValue.newTypeReference)
			it.body = '''
				«var arrayIndex = 0»
				«JSONArray.name» «arrayName» = jsonValue.isArray();
				if («arrayName» == null) {
					throw new «IllegalArgumentException.name»(
						"«beanClass.qualifiedName».«simpleName» received a JSONValue that was not a JSONArray."
					);
				}
				«JSONValue.name» «fieldVar»;
				«FOR field : beanClass.declaredFields.filter[!transient]»
					«fieldVar» = «arrayName».get(«arrayIndex++»);
					if («fieldVar» == null || «fieldVar».isNull() != null) {
						«IF field.type.primitive»
							throw new «NullPointerException.name»(
								"«beanClass.qualifiedName».«simpleName» received a null JSONValue for primitive field «field.simpleName»."
							);
						«ELSE»
							this.«field.simpleName» = null;
						«ENDIF»
					} else {
						«val conversionExpression = fieldSerializationOperations.get(field).get(simpleName)»
						«IF conversionExpression === null»
							«Exceptions.name».sneakyThrow(new «IllegalArgumentException.name»(
								"Don't know how to client-deserialize «field.type.name» «field.simpleName»"
							));
						«ELSE»
							this.«field.simpleName» = «conversionExpression»;
						«ENDIF»
					}
				«ENDFOR»
				return this;
			'''
		]
		addMethod(SERIALIZE_SERVER_METHOD_NAME) [
			primarySourceElement = beanClass.primarySourceElement
			addAnnotation(GwtIncompatible.newAnnotationReference)
			addAnnotation(Pure.newAnnotationReference)
			visibility = Visibility::PUBLIC
			returnType = JsonElement.newTypeReference
			it.body = '''
				«JsonArray.name» «arrayName» = new «JsonArray.name»();
				«FOR field : beanClass.declaredFields.filter[!transient]»
					«IF !field.type.primitive»
						if (this.«field.simpleName» == null) {
							«arrayName».add(«JsonNull.name».INSTANCE);
						} else
					«ENDIF»
					«val conversionExpression = fieldSerializationOperations.get(field).get(simpleName)»
					«IF conversionExpression === null»
						«Exceptions.name».sneakyThrow(new «IllegalArgumentException.name»(
							"Don't know how to server-serialize «field.type.name» «field.simpleName»"
						));
					«ELSE»
						«arrayName».add(«fieldSerializationOperations.get(field).get(simpleName)»);
					«ENDIF»
				«ENDFOR»
				return «arrayName»;
			'''
		]
		addMethod(DESERIALIZE_SERVER_METHOD_NAME) [
			primarySourceElement = beanClass.primarySourceElement
			addAnnotation(GwtIncompatible.newAnnotationReference)
			visibility = Visibility::PUBLIC
			returnType = beanClass.newTypeReference
			addParameter("jsonElement", JsonElement.newTypeReference)
			it.body = '''
				«var arrayIndex = 0»
				if (!jsonElement.isJsonArray()) {
					throw new «IllegalArgumentException.name»(
						"«beanClass.qualifiedName».«simpleName» received a JsonElement that was not a JsonArray."
					);
				}
				«JsonArray.name» «arrayName» = jsonElement.getAsJsonArray();
				«JsonElement.name» «fieldVar»;
				«FOR field : beanClass.declaredFields.filter[!transient]»
					«fieldVar» = «arrayName».get(«arrayIndex++»);
					if («fieldVar» == null || «fieldVar».isJsonNull()) {
						«IF field.type.primitive»
							throw new «NullPointerException.name»(
								"«beanClass.qualifiedName».«simpleName» received a null JsonElement for primitive field «field.simpleName»."
							);
						«ELSE»
							this.«field.simpleName» = null;
						«ENDIF»
					} else {
						«val conversionExpression = fieldSerializationOperations.get(field).get(simpleName)»
						«IF conversionExpression === null»
							«Exceptions.name».sneakyThrow(new «IllegalArgumentException.name»(
								"Don't know how to server-deserialize «field.type.name» «field.simpleName»"
							));
						«ELSE»
							this.«field.simpleName» = «conversionExpression»;
						«ENDIF»
					}
				«ENDFOR»
				return this;
			'''
		]
	}

	def String serializeClientField(
		MutableFieldDeclaration field,
		TypeReference typeReference,
		String subject,
		int depth,
		extension ProcessorContext context
	) {
		val extension transformationContext = transformationContext
		val type = typeReference.type

		if (type.implementsInterface(JsonSerializableMethods.newTypeReference)) {
			return '''«subject».«SERIALIZE_CLIENT_METHOD_NAME»()'''
		}

		if (serializeClientFieldMethodTypes.contains(typeReference)) {
			return '''«JsonSerializationClient.name».serialize(«subject»)'''
		}

		if (Iterable.findTypeGlobally.isAssignableFrom(type)) {
			val genericType = typeReference.actualTypeArguments.head
			val subSubject = "it" + depth
			val conversionExpression = field.serializeClientField(genericType, subSubject, depth + 1, context)
			if (conversionExpression !== null) {
				return '''«JsonSerializationClient.name».serializeIterable(«subject», («genericType.toJava» «subSubject») -> «conversionExpression»)'''
			}
		}

		field.addError('''Don't know how to client-serialize «typeReference.name» «field.simpleName»''')
		return null
	}

	def String deserializeClientField(
		MutableFieldDeclaration field,
		TypeReference typeReference,
		String subject,
		int depth,
		extension ProcessorContext context
	) {
		val extension transformationContext = transformationContext
		val type = typeReference.type

		if (type.implementsInterface(JsonSerializableMethods.newTypeReference)) {
			return '''new «typeReference.name»().«DESERIALIZE_CLIENT_METHOD_NAME»(«subject»)'''
		}

		val method = JsonSerializationClient.getMethodOrNull('''deserialize«type.simpleName»''', JSONValue)
		if (method !== null) {
			return '''«JsonSerializationClient.name».«method.name»(«subject»)'''
		}

		if (Iterable.findTypeGlobally.isAssignableFrom(type)) {
			val genericType = typeReference.actualTypeArguments.head
			val subSubject = "it" + depth
			val conversionExpression = field.deserializeClientField(genericType, subSubject, depth + 1, context)
			if (conversionExpression !== null) {
				return '''«JsonSerializationClient.name».deserializeIterable(«subject», («JSONValue.name» «subSubject») -> «conversionExpression», new «typeReference.toJava»())'''
			}
		}

		field.addError('''Don't know how to client-deserialize «typeReference.toJava» «field.simpleName»''')
		return null
	}

	def String serializeServerField(
		MutableFieldDeclaration field,
		TypeReference typeReference,
		String subject,
		int depth,
		extension ProcessorContext context
	) {
		val extension transformationContext = transformationContext
		val type = typeReference.type

		if (type.implementsInterface(JsonSerializableMethods.newTypeReference)) {
			return '''«subject».«SERIALIZE_SERVER_METHOD_NAME»()'''
		}

		if (serializeServerFieldMethodTypes.contains(typeReference)) {
			return '''«JsonSerializationServer.name».serialize(«subject»)'''
		}

		if (Iterable.findTypeGlobally.isAssignableFrom(type)) {
			val genericType = typeReference.actualTypeArguments.head
			val subSubject = "it" + depth
			val conversionExpression = field.serializeServerField(genericType, subSubject, depth + 1, context)
			if (conversionExpression !== null) {
				return '''«JsonSerializationServer.name».serializeIterable(«subject», («genericType.toJava» «subSubject») -> «conversionExpression»)'''
			}
		}

		field.addError('''Don't know how to server-serialize «typeReference.toJava» «field.simpleName»''')
		return null
	}

	def String deserializeServerField(
		MutableFieldDeclaration field,
		TypeReference typeReference,
		String subject,
		int depth,
		extension ProcessorContext context
	) {
		val extension transformationContext = transformationContext
		val type = typeReference.type

		if (type.implementsInterface(JsonSerializableMethods.newTypeReference)) {
			return '''new «typeReference.name»().«DESERIALIZE_SERVER_METHOD_NAME»(«subject»)'''
		}

		val method = JsonSerializationServer.getMethodOrNull('''deserialize«type.simpleName»''', JsonElement)
		if (method !== null) {
			return '''«JsonSerializationServer.name».«method.name»(«subject»)'''
		}

		if (Iterable.findTypeGlobally.isAssignableFrom(type)) {
			val genericType = typeReference.actualTypeArguments.head
			val subSubject = "it" + depth
			val conversionExpression = field.deserializeServerField(genericType, subSubject, depth + 1, context)
			if (conversionExpression !== null) {
				return '''«JsonSerializationServer.name».deserializeIterable(«subject», («JsonElement.name» «subSubject») -> «conversionExpression», new «typeReference.toJava»())'''
			}
		}

		field.addError('''Don't know how to server-deserialize «typeReference.name» «field.simpleName»''')
		return null
	}

	def static implementsInterface(Type type, TypeReference interfaceTypeReference) {
		return type instanceof ClassDeclaration && (type as ClassDeclaration).implementedInterfaces.findFirst [
			it == interfaceTypeReference
		] !== null
	}

	def static getMethodOrNull(Class<?> clazz, String name, Class<?>... parameterTypes) {
		try {
			return clazz.getMethod(name, parameterTypes)
		} catch (NoSuchMethodException e) {
			return null
		}
	}

	def static String toJava(TypeReference typeReference) {
		val typeArguments = typeReference.actualTypeArguments
		return '''«typeReference.type.qualifiedName»«IF !typeArguments.empty»<«typeArguments.map[toJava].join(", ")»>«ENDIF»'''
	}
}
