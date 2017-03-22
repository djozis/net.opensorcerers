package net.opensorcerers.mongoframework.lib.index

import com.mongodb.client.model.IndexModel
import com.mongodb.client.model.IndexOptions
import java.util.concurrent.TimeUnit
import org.bson.conversions.Bson

class IndexModelExtended extends IndexModel {
	new(Bson keys, IndexOptions options) {
		super(keys, options)
	}

	new(Bson keys) {
		super(keys)
	}

	def IndexModelExtended withOptions((IndexOptions)=>void configureCallback) {
		configureCallback.apply(options)
		return this
	}

	override equals(Object other) {
		if (other instanceof IndexModelExtended) {
			return keys == other.keys && options.checkEquals(other.options)
		} else {
			return false
		}
	}

	def static boolean checkEquals(IndexOptions a, IndexOptions b) {
		return a.background == b.background && //
		a.unique == b.unique && //
		a.name == b.name && //
		a.sparse == b.sparse && //
		a.getExpireAfter(TimeUnit.SECONDS) == b.getExpireAfter(TimeUnit.SECONDS) && //
		a.version ?: 2 == b.version ?: 2 && //
		a.weights == b.weights && //
		a.defaultLanguage == b.defaultLanguage && //
		a.languageOverride == b.languageOverride && //
		a.textVersion == b.textVersion && //
		a.sphereVersion == b.sphereVersion && //
		a.bits == b.bits && //
		a.min == b.min && //
		a.max == b.max && //
		a.bucketSize == b.bucketSize && //
		a.storageEngine == b.storageEngine
	}

	def isIdIndex() { return keys == new IndexStatementList => [add(new IndexStatement("_id", 1))] }
}
