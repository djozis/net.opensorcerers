package com.autology.database.bootstrap

import java.util.Locale
import org.eclipse.xtend.lib.annotations.Accessors
import org.hibernate.boot.model.naming.Identifier
import org.hibernate.boot.model.naming.PhysicalNamingStrategy
import org.hibernate.engine.jdbc.env.spi.JdbcEnvironment

import static extension java.lang.Character.*

class UnderscorePhysicalNamingStrategy implements PhysicalNamingStrategy {
	@Accessors static val instance = new UnderscorePhysicalNamingStrategy

	def static String addUnderscores(String name) {
		val builder = new StringBuilder(name)
		for (var i = 1; i < builder.length() - 1; i++) {
			if (builder.charAt(i - 1).isLowerCase && builder.charAt(i).isUpperCase) {
				builder.insert(i++, '_')
			}
		}
		return builder.toString.toUpperCase(Locale.ROOT)
	}

	override toPhysicalCatalogName(Identifier name, JdbcEnvironment jdbcEnvironment) {
		return name
	}

	override toPhysicalColumnName(Identifier name, JdbcEnvironment jdbcEnvironment) {
		return new Identifier(name.text.addUnderscores, name.quoted)
	}

	override toPhysicalSchemaName(Identifier name, JdbcEnvironment jdbcEnvironment) {
		return new Identifier(name.text.addUnderscores, name.quoted)
	}

	override toPhysicalSequenceName(Identifier name, JdbcEnvironment jdbcEnvironment) {
		return new Identifier(name.text.addUnderscores, name.quoted)
	}

	override toPhysicalTableName(Identifier name, JdbcEnvironment jdbcEnvironment) {
		var text = name.text
		if (text.startsWith("DB")) {
			text = text.substring(2)
		}
		return new Identifier(text.addUnderscores, name.quoted)
	}
}
