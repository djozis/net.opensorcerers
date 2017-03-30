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
import net.opensorcerers.framework.annotations.lib.StaticJsonSerializationUtilities
import net.opensorcerers.framework.shared.StaticallyJsonSerializable
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility

import static net.opensorcerers.framework.annotations.lib.StaticJsonSerializationUtilities.*

@Target(ElementType.TYPE)
@Active(ImplementStaticJsonSerializationProcessor)
@Retention(SOURCE)
annotation ImplementStaticJsonSerialization {
}

class ImplementStaticJsonSerializationProcessor extends AbstractClassProcessor {
	override doTransform(MutableClassDeclaration it, extension TransformationContext transformationContext) {
		if (extendedClass != Object.newTypeReference) {
			addError("A statically json-serializable class must not extend another class.")
		}

		implementedInterfaces = implementedInterfaces + #[StaticallyJsonSerializable.newTypeReference]

		val arrayName = "v"
		val fieldVar = "f"
		val extension staticJsonSerializationUtilities = new StaticJsonSerializationUtilities(it, transformationContext)

		// This must be done before method body so that addError works.
		val fieldSerializationOperations = declaredFields.toMap([it]) [ field |
			#{
				SERIALIZE_CLIENT_METHOD_NAME ->
					field.serializeClientField(field.type, '''this.«field.simpleName»''', 0),
				DESERIALIZE_CLIENT_METHOD_NAME -> field.deserializeClientField(field.type, fieldVar, 0),
				SERIALIZE_SERVER_METHOD_NAME ->
					field.serializeServerField(field.type, '''this.«field.simpleName»''', 0),
				DESERIALIZE_SERVER_METHOD_NAME -> field.deserializeServerField(field.type, fieldVar, 0)
			}
		]

		addMethod(SERIALIZE_CLIENT_METHOD_NAME) [
			primarySourceElement = transformingClass.primarySourceElement
			addAnnotation(Override.newAnnotationReference)
			addAnnotation(Pure.newAnnotationReference)
			visibility = Visibility::PUBLIC
			returnType = JSONValue.newTypeReference
			it.body = '''
				«var arrayIndex = 0»
				«JSONArray.name» «arrayName» = new «JSONArray.name»();
				«FOR field : transformingClass.declaredFields.filter[!transient]»
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
						«arrayName».set(«fieldIndex», «conversionExpression»);
					«ENDIF»
				«ENDFOR»
				return «arrayName»;
			'''
		]
		addMethod(DESERIALIZE_CLIENT_METHOD_NAME) [
			primarySourceElement = transformingClass.primarySourceElement
			addAnnotation(Override.newAnnotationReference)
			visibility = Visibility::PUBLIC
			returnType = transformingClass.newTypeReference
			addParameter("jsonValue", JSONValue.newTypeReference)
			it.body = '''
				«var arrayIndex = 0»
				«JSONArray.name» «arrayName» = jsonValue.isArray();
				if («arrayName» == null) {
					throw new «IllegalArgumentException.name»(
						"«transformingClass.qualifiedName».«simpleName» received a JSONValue that was not a JSONArray."
					);
				}
				«JSONValue.name» «fieldVar»;
				«FOR field : transformingClass.declaredFields.filter[!transient]»
					«fieldVar» = «arrayName».get(«arrayIndex++»);
					if («fieldVar» == null || «fieldVar».isNull() != null) {
						«IF field.type.primitive»
							throw new «NullPointerException.name»(
								"«transformingClass.qualifiedName».«simpleName» received a null JSONValue for primitive field «field.simpleName»."
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
			primarySourceElement = transformingClass.primarySourceElement
			addAnnotation(GwtIncompatible.newAnnotationReference)
			addAnnotation(Pure.newAnnotationReference)
			visibility = Visibility::PUBLIC
			returnType = JsonElement.newTypeReference
			it.body = '''
				«JsonArray.name» «arrayName» = new «JsonArray.name»();
				«FOR field : transformingClass.declaredFields.filter[!transient]»
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
						«arrayName».add(«conversionExpression»);
					«ENDIF»
				«ENDFOR»
				return «arrayName»;
			'''
		]
		addMethod(DESERIALIZE_SERVER_METHOD_NAME) [
			primarySourceElement = transformingClass.primarySourceElement
			addAnnotation(GwtIncompatible.newAnnotationReference)
			visibility = Visibility::PUBLIC
			returnType = transformingClass.newTypeReference
			addParameter("jsonElement", JsonElement.newTypeReference)
			it.body = '''
				«var arrayIndex = 0»
				if (!jsonElement.isJsonArray()) {
					throw new «IllegalArgumentException.name»(
						"«transformingClass.qualifiedName».«simpleName» received a JsonElement that was not a JsonArray."
					);
				}
				«JsonArray.name» «arrayName» = jsonElement.getAsJsonArray();
				«JsonElement.name» «fieldVar»;
				«FOR field : transformingClass.declaredFields.filter[!transient]»
					«fieldVar» = «arrayName».get(«arrayIndex++»);
					if («fieldVar» == null || «fieldVar».isJsonNull()) {
						«IF field.type.primitive»
							throw new «NullPointerException.name»(
								"«transformingClass.qualifiedName».«simpleName» received a null JsonElement for primitive field «field.simpleName»."
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
}
