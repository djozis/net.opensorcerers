package net.opensorcerers.framework.annotations.lib

import com.google.gson.JsonElement
import com.google.gwt.json.client.JSONValue
import java.util.Set
import net.opensorcerers.framework.client.JsonSerializationClient
import net.opensorcerers.framework.server.JsonSerializationServer
import net.opensorcerers.framework.shared.StaticallyJsonSerializable
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Declaration

class StaticJsonSerializationUtilities {
	public static val SERIALIZE_CLIENT_METHOD_NAME = "serializeToJsonClient"
	public static val DESERIALIZE_CLIENT_METHOD_NAME = "deserializeFromJsonClient"
	public static val SERIALIZE_SERVER_METHOD_NAME = "serializeToJsonServer"
	public static val DESERIALIZE_SERVER_METHOD_NAME = "deserializeFromJsonServer"

	@Accessors val MutableClassDeclaration transformingClass
	@Accessors extension val TransformationContext transformationContext

	var Set<TypeReference> serializeClientFieldMethodTypes
	var Set<TypeReference> serializeServerFieldMethodTypes

	new(MutableClassDeclaration transformingClass, extension TransformationContext transformationContext) {
		this.transformingClass = transformingClass
		this.transformationContext = transformationContext

		serializeClientFieldMethodTypes = JsonSerializationClient.methods.filter [
			name == "serialize"
		].map[parameterTypes.head.newTypeReference].toSet
		serializeServerFieldMethodTypes = JsonSerializationServer.methods.filter [
			name == "serialize"
		].map[parameterTypes.head.newTypeReference].toSet
	}

	def String serializeClientField(
		Declaration field,
		TypeReference typeReference,
		String subject,
		int depth
	) {
		val extension transformationContext = transformationContext
		val type = typeReference.type

		if (type.implementsInterface(StaticallyJsonSerializable.newTypeReference)) {
			return '''«subject».«SERIALIZE_CLIENT_METHOD_NAME»()'''
		}

		if (serializeClientFieldMethodTypes.contains(typeReference)) {
			return '''«JsonSerializationClient.name».serialize(«subject»)'''
		}

		if (Iterable.findTypeGlobally.isAssignableFrom(type)) {
			val genericType = typeReference.actualTypeArguments.head
			val subSubject = "it" + depth
			val conversionExpression = field.serializeClientField(genericType, subSubject, depth + 1)
			if (conversionExpression !== null) {
				return '''
				«JsonSerializationClient.name».serializeIterable(«subject», («genericType.toJava» «subSubject») ->
					«conversionExpression»
				)'''
			}
		}

		field.addError('''Don't know how to client-serialize «typeReference.name» «field.simpleName»''')
		return null
	}

	def String deserializeClientField(
		Declaration field,
		TypeReference typeReference,
		String subject,
		int depth
	) {
		val extension transformationContext = transformationContext
		val type = typeReference.type

		if (type.implementsInterface(StaticallyJsonSerializable.newTypeReference)) {
			return '''new «typeReference.name»().«DESERIALIZE_CLIENT_METHOD_NAME»(«subject»)'''
		}

		val method = JsonSerializationClient.getMethodOrNull('''deserialize«type.simpleName»''', JSONValue)
		if (method !== null) {
			return '''«JsonSerializationClient.name».«method.name»(«subject»)'''
		}

		if (Iterable.findTypeGlobally.isAssignableFrom(type)) {
			val genericType = typeReference.actualTypeArguments.head
			val subSubject = "it" + depth
			val conversionExpression = field.deserializeClientField(genericType, subSubject, depth + 1)
			if (conversionExpression !== null) {
				return '''
				«JsonSerializationClient.name».deserializeIterable(«subject», («JSONValue.name» «subSubject») ->
					«conversionExpression»,
				new «typeReference.toJava»())'''
			}
		}

		field.addError('''Don't know how to client-deserialize «typeReference.toJava» «field.simpleName»''')
		return null
	}

	def String serializeServerField(
		Declaration field,
		TypeReference typeReference,
		String subject,
		int depth
	) {
		val extension transformationContext = transformationContext
		val type = typeReference.type

		if (type.implementsInterface(StaticallyJsonSerializable.newTypeReference)) {
			return '''«subject».«SERIALIZE_SERVER_METHOD_NAME»()'''
		}

		if (serializeServerFieldMethodTypes.contains(typeReference)) {
			return '''«JsonSerializationServer.name».serialize(«subject»)'''
		}

		if (Iterable.findTypeGlobally.isAssignableFrom(type)) {
			val genericType = typeReference.actualTypeArguments.head
			val subSubject = "it" + depth
			val conversionExpression = field.serializeServerField(genericType, subSubject, depth + 1)
			if (conversionExpression !== null) {
				return '''
				«JsonSerializationServer.name».serializeIterable(«subject», («genericType.toJava» «subSubject») ->
					«conversionExpression»
				)'''
			}
		}

		field.addError('''Don't know how to server-serialize «typeReference.toJava» «field.simpleName»''')
		return null
	}

	def String deserializeServerField(
		Declaration field,
		TypeReference typeReference,
		String subject,
		int depth
	) {
		val extension transformationContext = transformationContext
		val type = typeReference.type

		if (type.implementsInterface(StaticallyJsonSerializable.newTypeReference)) {
			return '''new «typeReference.name»().«DESERIALIZE_SERVER_METHOD_NAME»(«subject»)'''
		}

		val method = JsonSerializationServer.getMethodOrNull('''deserialize«type.simpleName»''', JsonElement)
		if (method !== null) {
			return '''«JsonSerializationServer.name».«method.name»(«subject»)'''
		}

		if (Iterable.findTypeGlobally.isAssignableFrom(type)) {
			val genericType = typeReference.actualTypeArguments.head
			val subSubject = "it" + depth
			val conversionExpression = field.deserializeServerField(genericType, subSubject, depth + 1)
			if (conversionExpression !== null) {
				return '''
				«JsonSerializationServer.name».deserializeIterable(«subject», («JsonElement.name» «subSubject») ->
					«conversionExpression»,
				new «typeReference.toJava»())'''
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
