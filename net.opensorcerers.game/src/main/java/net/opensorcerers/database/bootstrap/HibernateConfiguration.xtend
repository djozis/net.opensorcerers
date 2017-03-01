package net.opensorcerers.database.bootstrap

import javax.persistence.Entity
import org.hibernate.boot.registry.StandardServiceRegistryBuilder
import org.hibernate.cfg.Configuration
import org.hibernate.cfg.Environment
import org.reflections.Reflections
import net.opensorcerers.database.entities.DBUser

class HibernateConfiguration {
	def static String getEntitiesPackage() { return DBUser.package.name }

	def static createSessionFactory(DatabaseConnectivity databaseConnectivity) {
		return (new Configuration() => [
			for (clazz : new Reflections(entitiesPackage).getTypesAnnotatedWith(Entity)) {
				addAnnotatedClass(clazz)
			}
			physicalNamingStrategy = UnderscorePhysicalNamingStrategy.instance
		]).buildSessionFactory(
			(new StandardServiceRegistryBuilder() => [
				applySetting(Environment.DATASOURCE, databaseConnectivity.dataSource)
				applySetting(Environment.DIALECT, databaseConnectivity.hibernateDialect)
				applySetting(Environment.HBM2DDL_AUTO, "update")
				applySetting(Environment.SHOW_SQL, true)
			]).build
		)
	}
}
