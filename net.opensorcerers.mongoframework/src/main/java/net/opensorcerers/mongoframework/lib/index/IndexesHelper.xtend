package net.opensorcerers.mongoframework.lib.index

import com.mongodb.async.SingleResultCallback
import com.mongodb.async.client.MongoCollection
import java.util.ArrayList
import java.util.List
import java.util.concurrent.atomic.AtomicInteger

class IndexesHelper {
	def static setIndexes(MongoCollection<?> collection, List<IndexModelExtended> indexes,
		SingleResultCallback<Void> callback) {
		collection.listIndexes(IndexModelExtended).into(new ArrayList<IndexModelExtended>) [ indexList, error |
			try {
				if (error !== null) {
					callback.onResult(null, error)
				} else {
					val IndexModelExtended[] toDrop = indexList.filter[!idIndex && !indexes.contains(it)]
					val IndexModelExtended[] toCreate = indexes.filter[!indexList.contains(it)]
					val ()=>void afterDrop = [
						if (!toCreate.empty) {
							collection.createIndexes(toCreate)[list, createError|callback.onResult(null, createError)]
						} else {
							callback.onResult(null, null)
						}
					]
					if (!toDrop.empty) {
						val responsesCounter = new AtomicInteger(toDrop.length)
						val SingleResultCallback<?> opCallback = [ ignore, opError |
							if (opError !== null) {
								if (responsesCounter.getAndSet(-1) > 0) {
									callback.onResult(null, opError)
								}
							} else {
								if (responsesCounter.decrementAndGet == 0) {
									afterDrop.apply
								}
							}
						]
						for (drop : toDrop) {
							collection.dropIndex(drop.options.name, opCallback as SingleResultCallback<Void>)
						}
					} else {
						afterDrop.apply
					}
				}
			} catch (Throwable e) {
				callback.onResult(null, e)
			}
		]
	}
}
