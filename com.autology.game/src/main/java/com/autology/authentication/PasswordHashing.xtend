package com.autology.authentication

import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec
import org.eclipse.xtend.lib.annotations.Accessors

abstract class PasswordHashing {
	static var PasswordHashing currentAlgorithm = null

	def static createDigest(char[] password) { return currentAlgorithm.digest(password) }

	def static compareDigest(byte[] digest, char[] password) {
		return algorithms.get(digest.get(0)).compare(digest, password)
	}

	// non-static
	def byte[] digest(char[] password)

	def boolean compare(byte[] digest, char[] password)

	def byte getAlgorithmIndex()

	static val random = new SecureRandom

	def static generateSalt(int size) {
		val bytes = newByteArrayOfSize(size)
		random.nextBytes(bytes)
		return bytes
	}

	def static byte[] pbkdf2(String algorithm, char[] password, byte[] salt, int iterations, int bytes) {
		return SecretKeyFactory.getInstance(algorithm).generateSecret(
			new PBEKeySpec(password, salt, iterations, bytes * 8)
		).encoded
	}

	def static slowCompare(byte[] a, byte[] b) {
		var same = a.length == b.length
		for (var i = a.length - 1; i >= 0; i--) {
			same = (a.get(i) == b.get(i)) && same
		}
		return same
	}

	@Accessors static class StandardPasswordHashing extends PasswordHashing {
		var byte algorithmIndex
		var String algorithm
		var int saltSize = 16
		var int hashSize = 16
		var int iterations = 1000

		override digest(char[] password) {
			val digest = newByteArrayOfSize(1 + saltSize + hashSize)
			digest.set(0, algorithmIndex)

			val salt = generateSalt(saltSize)
			System.arraycopy(salt, 0, digest, 1, saltSize)

			val hash = algorithm.pbkdf2(password, salt, iterations, hashSize)
			System.arraycopy(hash, 0, digest, 1 + saltSize, hashSize)

			return digest
		}

		override compare(byte[] digest, char[] password) {
			val salt = newByteArrayOfSize(saltSize)
			System.arraycopy(digest, 1, salt, 0, saltSize)

			val hash = newByteArrayOfSize(hashSize)
			System.arraycopy(digest, 1 + saltSize, hash, 0, hashSize)

			return algorithm.pbkdf2(password, salt, iterations, hashSize).slowCompare(hash)
		}
	}

	static val algorithms = #[
		currentAlgorithm = new StandardPasswordHashing => [
			algorithmIndex = 1 as byte
			algorithm = "PBKDF2WithHmacSHA1"
			saltSize = 16
			hashSize = 16
			iterations = 1000
		]
	].groupBy[algorithmIndex].mapValues [
		if (length > 1) {
			throw new IllegalArgumentException(
				'''Duplicate algorithmIndex: «head.algorithmIndex»'''
			)
		}
		return head
	]
}
