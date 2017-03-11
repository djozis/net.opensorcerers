package net.opensorcerers.framework.annotations

import com.google.gson.JsonArray
import com.google.gson.JsonElement
import com.google.gson.JsonNull
import com.google.gwt.user.client.rpc.AsyncCallback
import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.Target
import java.util.function.BiConsumer
import net.opensorcerers.framework.annotations.lib.StaticJsonSerializationUtilities
import net.opensorcerers.framework.server.FrameworkServerServiceBase
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.ParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility

import static net.opensorcerers.framework.annotations.lib.StaticJsonSerializationUtilities.*

@Target(ElementType.TYPE)
@Active(ImplementFrameworkServerServiceProcessor)
@Retention(SOURCE)
annotation ImplementFrameworkServerService {
	String remoteServiceRelativePath = ''
}

class ImplementFrameworkServerServiceProcessor extends AbstractClassProcessor {
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

		if (!packageName.contains(SERVER)) {
			addError("A service must reside under the 'server' package.")
		}

		if (extendedClass != Object.newTypeReference) {
			addError("A service must not extend another class.")
		}

		val interfaceType = findInterface(interfaceName)
		interfaceType.primarySourceElement = primarySourceElement
		val proxyType = findClass(proxyName)
		proxyType.primarySourceElement = primarySourceElement

		val transformingClass = it

		extendedClass = FrameworkServerServiceBase.newTypeReference
		implementedInterfaces = implementedInterfaces + #[interfaceType.newTypeReference]

		val methodConsumersType = BiConsumer.newTypeReference(
			JsonArray.newTypeReference,
			AsyncCallback.newTypeReference(JsonElement.newTypeReference)
		)

		val serviceMethods = serviceMethods
		val serviceMethodConsumerClasses = serviceMethods.toMap([it]) [ serviceMethod |
			(findClass(transformingClass.serviceMethodConsumerClassQualifiedName(serviceMethod)) => [
				primarySourceElement = serviceMethod.primarySourceElement
				visibility = Visibility::PRIVATE
				static = false
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

		addField("methodConsumers") [
			visibility = Visibility::PRIVATE
			final = true
			type = methodConsumersType.newArrayTypeReference
			initializer = '''
			new «BiConsumer.name»[] {
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
		// This must be done before method body so that addError works.
		val resultTypeSerializationOperations = serviceMethods.toMap([it]) [ serviceMethod |
			val resultParameter = serviceMethod.parameters.last
			resultParameter.serializeServerField(resultParameter.type.actualTypeArguments.head, resultVar, 0)
		]
		val parameterSerializationOperations = serviceMethods.toMap([it]) [ serviceMethod |
			serviceMethod.serviceMethodParameters.toMap([it]) [ parameter |
				#{
					DESERIALIZE_SERVER_METHOD_NAME -> parameter.deserializeServerField(parameter.type, fieldVar, 0)
				}
			]
		]

		for (serviceMethod : serviceMethods) {
			if (serviceMethod.returnType != void.newTypeReference) {
				serviceMethod.returnType.addError("Public methods on services must return void")
			} else if (serviceMethod.parameters.last.type.type.qualifiedName != AsyncCallback.name) {
				serviceMethod.addError(
					"Public methods on services must have an AsyncCallback as their last argument but found " +
						serviceMethod.parameters.last.type.type.qualifiedName)
			} else {
				serviceMethodConsumerClasses.get(serviceMethod).addMethod("accept") [
					primarySourceElement = serviceMethod.primarySourceElement
					returnType = void.newTypeReference
					visibility = Visibility::PUBLIC
					val arrayName = "message"
					addParameter(arrayName, JsonArray.newTypeReference)
					addParameter("resultCallback", AsyncCallback.newTypeReference(JsonElement.newTypeReference))
					body = '''
						«var arrayIndex = 1 /* skip method number which is index 0 */ »
						«JsonElement.name» «fieldVar»;
						«FOR parameter : serviceMethod.serviceMethodParameters»
							«fieldVar» = «arrayName».get(«arrayIndex++»);
							«parameter.type.toString» «parameter.valueVariableName»;
							if («fieldVar» == null || «fieldVar».isJsonNull()) {
								«IF parameter.type.primitive»
									throw new «NullPointerException.name»(
										"«transformingClass.qualifiedName».«serviceMethod.simpleName» parameter «simpleName» received a null JsonElement for primitive field «parameter.simpleName»."
									);
								«ELSE»
									«parameter.valueVariableName» = null;
								«ENDIF»
							} else {
								«val conversionExpression = parameterSerializationOperations.get(serviceMethod).get(parameter).get(DESERIALIZE_SERVER_METHOD_NAME)»
								«IF conversionExpression === null»
									«Exceptions.name».sneakyThrow(new «IllegalArgumentException.name»(
										"Don't know how to server-deserialize «parameter.type.name» «parameter.simpleName»"
									));
								«ELSE»
									«parameter.valueVariableName» = «conversionExpression»;
								«ENDIF»
							}
						«ENDFOR»
						«serviceMethod.simpleName»(
							«serviceMethod.serviceMethodParameters.map[valueVariableName].join(", ")»,
							«val resultParameter = serviceMethod.parameters.last»
							new «resultParameter.type.toString»() {
								@Override public void onSuccess(«resultParameter.type.actualTypeArguments.head.toString» «resultVar») {
									«JsonElement.name» serializedResult;
									«IF !resultParameter.type.primitive»
										if («resultVar» == null) {
											serializedResult = «JsonNull.name».INSTANCE;
										} else
									«ENDIF»
									«val conversionExpression = resultTypeSerializationOperations.get(serviceMethod)»
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
				interfaceType.addMethod(serviceMethod.simpleName) [
					primarySourceElement = serviceMethod.primarySourceElement
					returnType = serviceMethod.returnType
					for (parameter : serviceMethod.parameters) {
						addParameter(parameter.simpleName, parameter.type)
					}
				]
				proxyType.addMethod(serviceMethod.simpleName) [
					primarySourceElement = serviceMethod.primarySourceElement
					returnType = serviceMethod.returnType
					for (parameter : serviceMethod.parameters) {
						addParameter(parameter.simpleName, parameter.type)
					}
					body = '''
						
					'''
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
		packageName.replace(SERVER, CLIENT) + "." + interfaceSimpleName + "Proxy"
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
