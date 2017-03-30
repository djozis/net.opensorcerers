package net.opensorcerers.framework.annotations

import com.google.gson.JsonArray
import com.google.gson.JsonElement
import com.google.gson.JsonNull
import com.google.gson.JsonPrimitive
import com.google.gwt.json.client.JSONArray
import com.google.gwt.json.client.JSONNull
import com.google.gwt.json.client.JSONValue
import com.google.gwt.user.client.rpc.AsyncCallback
import io.vertx.core.eventbus.EventBus
import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import net.opensorcerers.framework.annotations.lib.StaticJsonSerializationUtilities
import net.opensorcerers.framework.client.FrameworkClientServiceBase
import net.opensorcerers.framework.server.FrameworkClientServiceProxy
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.ParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtext.xbase.lib.Procedures.Procedure3

import static net.opensorcerers.framework.annotations.lib.StaticJsonSerializationUtilities.*

@Target(ElementType.TYPE)
@Active(ImplementFrameworkClientServiceProcessor)
@Retention(SOURCE)
annotation ImplementFrameworkClientService {
}

class ImplementFrameworkClientServiceProcessor extends AbstractClassProcessor {
	static val IMPL = "Impl"
	static val SERVER = ".server"
	static val SHARED = ".shared"
	static val CLIENT = ".client"

	override doRegisterGlobals(ClassDeclaration it, RegisterGlobalsContext context) {
		context.registerInterface(interfaceName)
		context.registerClass(proxyName)
		for (serviceMethod : serviceMethods) {
			context.registerClass(serviceMethodConsumerClassQualifiedName(serviceMethod))
		}
	}

	override doTransform(MutableClassDeclaration it, extension TransformationContext transformationContext) {
		if (!simpleName.endsWith(IMPL)) {
			addError('''The name must end with '«IMPL»'.''')
		}

		if (!packageName.contains(CLIENT)) {
			addError("A client service must reside under the 'client' package.")
		}

		if (extendedClass != Object.newTypeReference) {
			addError("A service must not extend another class.")
		}

		val interfaceType = findInterface(interfaceName)
		interfaceType.primarySourceElement = primarySourceElement
		val proxyType = findClass(proxyName)
		proxyType.primarySourceElement = primarySourceElement

		val transformingClass = it

		val methodConsumersType = Procedure3.newTypeReference(
			transformingClass.newTypeReference,
			JSONArray.newTypeReference,
			AsyncCallback.newTypeReference(JSONValue.newTypeReference)
		)

		val serviceMethods = serviceMethods
		val serviceMethodConsumerClasses = serviceMethods.toMap([it]) [ serviceMethod |
			(findClass(transformingClass.serviceMethodConsumerClassQualifiedName(serviceMethod)) => [
				primarySourceElement = serviceMethod.primarySourceElement
				visibility = Visibility::PRIVATE
				static = true
				implementedInterfaces = #[methodConsumersType]
			])
		]

		addMethod("getAddress") [
			primarySourceElement = transformingClass.primarySourceElement
			addAnnotation(Override.newAnnotationReference)
			visibility = Visibility::PROTECTED
			returnType = String.newTypeReference
			body = '''return "«transformingClass.interfaceSimpleName.toFirstLower»";'''
		]
		proxyType.addMethod("getAddress") [
			primarySourceElement = transformingClass.primarySourceElement
			addAnnotation(Override.newAnnotationReference)
			visibility = Visibility::PROTECTED
			returnType = String.newTypeReference
			body = '''return "«transformingClass.interfaceSimpleName.toFirstLower»";'''
		]

		addField("methodConsumers") [
			visibility = Visibility::PRIVATE
			final = true
			static = true
			type = methodConsumersType.newArrayTypeReference
			initializer = '''
			new «methodConsumersType.type.qualifiedName»[] {
				«serviceMethods.map['''new «serviceMethodConsumerClasses.get(it).qualifiedName»()'''].join(",\n")»
			}'''
		]
		addMethod("getMethodConsumers") [
			addAnnotation(Override.newAnnotationReference)
			visibility = Visibility::PROTECTED
			returnType = methodConsumersType.newArrayTypeReference
			body = '''return methodConsumers;'''
		]

		val extension staticJsonSerializationUtilities = new StaticJsonSerializationUtilities(it, transformationContext)

		val fieldVar = "f"
		val resultVar = "r"
		val arrayName = "message"
		// This must be done before method body so that addError works.
		val resultTypeSerializationOperations = serviceMethods.toMap([it]) [ serviceMethod |
			val resultParameter = serviceMethod.parameters.last
			return #{
				SERIALIZE_CLIENT_METHOD_NAME ->
					resultParameter.serializeClientField(resultParameter.type.actualTypeArguments.head, resultVar, 0),
				DESERIALIZE_SERVER_METHOD_NAME ->
					resultParameter.deserializeServerField(resultParameter.type.actualTypeArguments.head, resultVar, 0)
			}
		]
		val parameterSerializationOperations = serviceMethods.toMap([it]) [ serviceMethod |
			serviceMethod.serviceMethodParameters.toMap([it]) [ parameter |
				#{
					DESERIALIZE_CLIENT_METHOD_NAME -> parameter.deserializeClientField(parameter.type, fieldVar, 0),
					SERIALIZE_SERVER_METHOD_NAME ->
						parameter.serializeServerField(parameter.type, parameter.simpleName, 0)
				}
			]
		]

		extendedClass = FrameworkClientServiceBase.newTypeReference
		implementedInterfaces = implementedInterfaces + #[interfaceType.newTypeReference]
		proxyType.extendedClass = FrameworkClientServiceProxy.newTypeReference
		proxyType.implementedInterfaces = proxyType.implementedInterfaces + #[interfaceType.newTypeReference]
		proxyType.addConstructor [
			visibility = Visibility::PUBLIC
			primarySourceElement = transformingClass.primarySourceElement
			addParameter("eventBus", EventBus.newTypeReference)
			addParameter("sessionId", String.newTypeReference)
			body = '''
				super(eventBus, sessionId);
			'''
		]
		var serviceMethodIndexCounter = 0
		for (serviceMethod : serviceMethods) {
			val serviceMethodIndex = serviceMethodIndexCounter++
			if (serviceMethod.returnType != void.newTypeReference) {
				serviceMethod.returnType.addError("Public methods on services must return void")
			} else if (serviceMethod.parameters.last.type.type.qualifiedName != AsyncCallback.name) {
				serviceMethod.addError(
					"Public methods on services must have an AsyncCallback as their last argument but found " +
						serviceMethod.parameters.last.type.type.qualifiedName)
			} else {
				val resultParameter = serviceMethod.parameters.last
				val resultParameterCallbackType = resultParameter.type.actualTypeArguments.head
				serviceMethodConsumerClasses.get(serviceMethod).addMethod("apply") [
					primarySourceElement = serviceMethod.primarySourceElement
					returnType = void.newTypeReference
					visibility = Visibility::PUBLIC
					addParameter("it", transformingClass.newTypeReference)
					addParameter(arrayName, JSONArray.newTypeReference)
					addParameter("resultCallback", AsyncCallback.newTypeReference(JSONValue.newTypeReference))
					body = '''
						«var arrayIndex = 1 /* skip method number which is index 0 */ »
						«JSONValue.name» «fieldVar»;
						«FOR parameter : serviceMethod.serviceMethodParameters»
							«fieldVar» = «arrayName».get(«arrayIndex++»);
							«parameter.type.toString» «parameter.valueVariableName»;
							if («fieldVar» == null || «fieldVar».isNull() != null) {
								«IF parameter.type.primitive»
									throw new «NullPointerException.name»(
										"«transformingClass.qualifiedName».«serviceMethod.simpleName» parameter «simpleName» received a null JSONValue for primitive field «parameter.simpleName»."
									);
								«ELSE»
									«parameter.valueVariableName» = null;
								«ENDIF»
							} else {
								«val conversionExpression = parameterSerializationOperations.get(serviceMethod).get(parameter).get(DESERIALIZE_CLIENT_METHOD_NAME)»
								«IF conversionExpression === null»
									«Exceptions.name».sneakyThrow(new «IllegalArgumentException.name»(
										"Don't know how to server-deserialize «parameter.type.name» «parameter.simpleName»"
									));
								«ELSE»
									«parameter.valueVariableName» = «conversionExpression»;
								«ENDIF»
							}
						«ENDFOR»
						it.«serviceMethod.simpleName»(
							«serviceMethod.serviceMethodParameters.map[valueVariableName].join(", ")»,
							new «resultParameter.type.toString»() {
								@Override public void onSuccess(«resultParameterCallbackType.toString» «resultVar») {
									«JSONValue.name» serializedResult;
									«IF !resultParameter.type.primitive»
										if («resultVar» == null) {
											serializedResult = «JSONNull.name».getInstance();
										} else
									«ENDIF»
									«val conversionExpression = resultTypeSerializationOperations.get(serviceMethod).get(SERIALIZE_CLIENT_METHOD_NAME)»
									«IF conversionExpression === null»
										«Exceptions.name».sneakyThrow(new «IllegalArgumentException.name»(
											"Don't know how to server-serialize «resultParameter.type.name» «resultParameter.simpleName»"
										));
									«ELSE»
										serializedResult = «conversionExpression»;
									«ENDIF»
									resultCallback.onSuccess(serializedResult);
								}
								
								@Override public void onFailure(Throwable caught) {
									resultCallback.onFailure(caught);
								}
							}
						);
					'''
				]
				proxyType.addMethod(serviceMethod.simpleName) [
					primarySourceElement = serviceMethod.primarySourceElement
					returnType = serviceMethod.returnType
					for (parameter : serviceMethod.parameters) {
						addParameter(parameter.simpleName, parameter.type)
					}
					body = '''
						«JsonArray.name» «arrayName» = new «JsonArray.name»();
						«arrayName».add(new «JsonPrimitive.name»(«serviceMethodIndex»));
						«FOR parameter : serviceMethod.serviceMethodParameters»
							«IF !parameter.type.primitive»
								if («parameter.simpleName» == null) {
									«arrayName».add(«JsonNull.name».INSTANCE);
								} else
							«ENDIF»
							«val conversionExpression = parameterSerializationOperations.get(serviceMethod).get(parameter).get(SERIALIZE_SERVER_METHOD_NAME)»
							«IF conversionExpression === null»
								«Exceptions.name».sneakyThrow(new «IllegalArgumentException.name»(
									"Don't know how to client-serialize «parameter.type.name» «parameter.simpleName»"
								));
							«ELSE»
								«arrayName».add(«conversionExpression»);
							«ENDIF»
						«ENDFOR»
						sendRequest(«arrayName»,
							new «AsyncCallback.name»<«JsonElement.name»>() {
								@Override public void onSuccess(«JsonElement.name» «resultVar») {
									«resultParameterCallbackType.toString» deserializedResult;
									if («resultVar» == null || «resultVar».isJsonNull()) {
										deserializedResult = null;
									} else {
										«val conversionExpression = resultTypeSerializationOperations.get(serviceMethod).get(DESERIALIZE_SERVER_METHOD_NAME)»
										«IF conversionExpression === null»
											«Exceptions.name».sneakyThrow(new «IllegalArgumentException.name»(
												"Don't know how to client-deserialize «resultParameterCallbackType.name» in «resultParameter.simpleName»"
											));
										«ELSE»
											deserializedResult = «conversionExpression»;
										«ENDIF»
									}
									«resultParameter.simpleName».onSuccess(deserializedResult);
								}
								
								@Override public void onFailure(Throwable caught) {
									«resultParameter.simpleName».onFailure(caught);
								}
							}
						);
					'''
				]
				interfaceType.addMethod(serviceMethod.simpleName) [
					primarySourceElement = serviceMethod.primarySourceElement
					returnType = serviceMethod.returnType
					for (parameter : serviceMethod.parameters) {
						addParameter(parameter.simpleName, parameter.type)
					}
				]
			}
		}
	}

	def static getServiceMethods(ClassDeclaration it) {
		declaredMethods.filter[visibility == Visibility::PUBLIC].toList
	}

	def static getServiceMethodParameters(MethodDeclaration it) {
		return parameters.take(parameters.length - 1)
	}

	def static getServiceMethodResultType(MethodDeclaration it) {
		return parameters.last.type.actualTypeArguments.head
	}

	def static String proxyName(ClassDeclaration it) {
		packageName.replace(CLIENT, SERVER) + "." + interfaceSimpleName + "Proxy"
	}

	def static interfaceName(ClassDeclaration it) {
		packageName.replace(SERVER, SHARED) + "." + interfaceSimpleName
	}

	def static interfaceSimpleName(ClassDeclaration it) {
		simpleName.substring(0, simpleName.length - IMPL.length)
	}

	def static String packageName(ClassDeclaration it) {
		qualifiedName.substring(0, qualifiedName.length - simpleName.length - 1)
	}

	def static String serviceMethodConsumerClassSimpleName(MethodDeclaration method) {
		return method.simpleName.toFirstUpper + "__Consumer"
	}

	def static String serviceMethodConsumerClassQualifiedName(
		ClassDeclaration transformingClass,
		MethodDeclaration method
	) {
		return transformingClass.qualifiedName + "." + method.serviceMethodConsumerClassSimpleName
	}

	def static String valueVariableName(ParameterDeclaration it) { return simpleName + "__value" }
}
