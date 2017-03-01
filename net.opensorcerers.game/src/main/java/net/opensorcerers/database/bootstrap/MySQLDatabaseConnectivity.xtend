package net.opensorcerers.database.bootstrap

import java.io.IOException
import org.apache.commons.dbcp.BasicDataSource
import org.eclipse.xtend.lib.annotations.Accessors
import org.hibernate.SessionFactory
import org.hibernate.dialect.MySQLDialect

import static extension net.opensorcerers.database.bootstrap.HibernateConfiguration.*

class MySQLDatabaseConnectivity implements DatabaseConnectivity {
	@Accessors(PUBLIC_GETTER) BasicDataSource dataSource
	@Accessors(PUBLIC_GETTER) SessionFactory sessionFactory = null

	override getHibernateDialect() { MySQLDialect }

	override open() {
		// http://stackoverflow.com/questions/12271164/enabling-preparedstatement-pooling-in-dbcp
		// http://commons.apache.org/proper/commons-dbcp/configuration.html
		// http://stackoverflow.com/questions/10987388/connection-using-connectionpooldatasource ??
		new BasicDataSource => [
			driverClassName = "com.mysql.jdbc.Driver"
			url = "jdbc:mysql://localhost/autology"
			username = "autology"
			password = "autology"
			poolPreparedStatements = true
			// maxOpenPreparedStatements should be set to a value less than the maximum number of cursors that can be open on a Connection.
			maxOpenPreparedStatements = 50
			throw new UnsupportedOperationException("You still need a real password.")
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
			dataSource.close
		}
		dataSource = null
	}
}
