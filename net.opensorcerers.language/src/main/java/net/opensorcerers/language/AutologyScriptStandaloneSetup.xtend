/*
 * generated by Xtext 2.11.0
 */
package net.opensorcerers.language


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class AutologyScriptStandaloneSetup extends AutologyScriptStandaloneSetupGenerated {

	def static void doSetup() {
		new AutologyScriptStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}
