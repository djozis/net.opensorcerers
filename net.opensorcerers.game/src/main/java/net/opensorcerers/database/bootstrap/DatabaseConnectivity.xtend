package net.opensorcerers.database.bootstrap

import java.io.Closeable
import javax.sql.DataSource
import org.hibernate.SessionFactory
import org.hibernate.dialect.Dialect

interface DatabaseConnectivity extends Closeable {
	def DatabaseConnectivity open()

	def DataSource getDataSource()

	def SessionFactory getSessionFactory()

	def Class<? extends Dialect> getHibernateDialect()
}
