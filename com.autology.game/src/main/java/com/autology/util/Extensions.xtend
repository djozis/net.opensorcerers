package com.autology.util

class Extensions {
	def static <T extends AutoCloseable> void closeAfter(T it, (T)=>void callback) {
		var success = false
		try {
			callback.apply(it)
			success = true
		} finally {
			try {
				close
			} catch (Throwable e) {
				if (success) {
					Exceptions.sneakyThrow(e)
				}
			}
		}
	}

	def static <T extends AutoCloseable, R> R closeAfterReturn(T it, (T)=>R callback) {
		try {
			return callback.apply(it)
		} finally {
			close
		}
	}

	def static <T> void cleanupAfter(T it, (T)=>void cleanup, (T)=>void callback) {
		try {
			callback.apply(it)
		} finally {
			cleanup.apply(it)
		}
	}

	def static <T, R> R cleanupAfterReturn(T it, (T)=>void cleanup, (T)=>R callback) {
		try {
			return callback.apply(it)
		} finally {
			cleanup.apply(it)
		}
	}
}
