package net.opensorcerers.database.bootstrap

import javax.persistence.criteria.CriteriaQuery
import javax.persistence.criteria.Root
import org.hibernate.Session

import static extension net.opensorcerers.util.Extensions.*

class DatabaseExtensions {
	def static void withDatabaseConnection(DatabaseConnectivity database, (Session)=>void callback) {
		database.sessionFactory.openSession.closeAfter(callback)
	}

	def static <R> R withDatabaseConnectionReturn(DatabaseConnectivity database, (Session)=>R callback) {
		return database.sessionFactory.openSession.closeAfterReturn(callback)
	}

	def static void withTransaction(Session session, (Session)=>void callback) {
		val transaction = session.beginTransaction
		var success = false
		try {
			callback.apply(session)
			success = true
		} finally {
			if (success) {
				transaction.commit
			} else {
				transaction.rollback
			}
		}
	}

	def static void databaseTransaction(DatabaseConnectivity database, (Session)=>void callback) {
		database.withDatabaseConnection[withTransaction(callback)]
	}

	def static <T> databaseQuery(
		Session session,
		Class<T> clazz,
		(CriteriaQuery<T>)=>void callback
	) {
		return session.createQuery(
			session.criteriaBuilder.createQuery(clazz) => callback
		).resultList
	}

	def static <T> queryClassWhere(
		Session session,
		Class<T> clazz,
		Pair<String, Object>... matches
	) {
		return session.databaseQuery(clazz) [
			extension val criteriaBuilder = session.criteriaBuilder
			val root = from(clazz)
			for (match : matches) {
				where(
					equal(
						(root as Root<?>).get(match.key),
						match.value
					)
				)
			}
		]
	}
}
