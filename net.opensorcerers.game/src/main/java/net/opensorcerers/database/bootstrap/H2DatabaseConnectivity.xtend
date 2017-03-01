package net.opensorcerers.database.bootstrap

import java.io.IOException
import org.apache.commons.dbcp.BasicDataSource
import org.eclipse.xtend.lib.annotations.Accessors
import org.hibernate.SessionFactory
import org.hibernate.dialect.H2Dialect

import static extension net.opensorcerers.database.bootstrap.HibernateConfiguration.*
import static extension net.opensorcerers.util.Extensions.*

class H2DatabaseConnectivity implements DatabaseConnectivity, AutoCloseable {
	@Accessors(PUBLIC_GETTER) BasicDataSource dataSource = null
	@Accessors(PUBLIC_GETTER) SessionFactory sessionFactory = null

	override getHibernateDialect() { return H2Dialect }

	override open() {
		dataSource = new BasicDataSource => [
			driverClassName = "org.h2.Driver"
			url = "jdbc:h2:mem:test;DB_CLOSE_DELAY=-1"
			username = "testdbusername"
			password = "testdbpassword"
			poolPreparedStatements = true
			// maxOpenPreparedStatements should be set to a value less than the maximum number of cursors that can be open on a Connection.
			maxOpenPreparedStatements = 50
		]
		sessionFactory = this.createSessionFactory

		return this
	}

	override close() throws IOException {
		if (sessionFactory !== null) {
			sessionFactory.close
		}
		sessionFactory = null

		if (dataSource !== null) {
			dataSource.connection.createStatement.closeAfter [
				execute("SET DB_CLOSE_DELAY 0")
				execute("shutdown")
			]
			dataSource.close
		}
		dataSource = null
	}

	def clearDatabase() {
		close
		open
	}
}
