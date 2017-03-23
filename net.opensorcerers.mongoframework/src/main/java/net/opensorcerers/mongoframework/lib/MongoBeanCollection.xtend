package net.opensorcerers.mongoframework.lib

import com.mongodb.async.SingleResultCallback
import com.mongodb.async.client.FindIterable
import com.mongodb.async.client.MongoCollection
import com.mongodb.async.client.MongoDatabase
import com.mongodb.client.model.CountOptions
import com.mongodb.client.model.FindOneAndDeleteOptions
import com.mongodb.client.model.FindOneAndReplaceOptions
import com.mongodb.client.model.FindOneAndUpdateOptions
import com.mongodb.client.model.IndexOptions
import com.mongodb.client.model.UpdateOptions
import com.mongodb.client.result.DeleteResult
import com.mongodb.client.result.UpdateResult
import java.lang.reflect.Constructor
import java.lang.reflect.ParameterizedType
import java.util.ArrayList
import java.util.List
import java.util.concurrent.atomic.AtomicInteger
import net.opensorcerers.mongoframework.lib.filter.FilterBeanField
import net.opensorcerers.mongoframework.lib.filter.FilterExpression
import net.opensorcerers.mongoframework.lib.index.IndexBeanField
import net.opensorcerers.mongoframework.lib.index.IndexModelExtended
import net.opensorcerers.mongoframework.lib.index.IndexStatementList
import net.opensorcerers.mongoframework.lib.project.ProjectBeanField
import net.opensorcerers.mongoframework.lib.project.ProjectStatementList
import net.opensorcerers.mongoframework.lib.update.UpdateBeanField
import net.opensorcerers.mongoframework.lib.update.UpdateStatementList
import org.eclipse.xtend.lib.annotations.Delegate
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor abstract class MongoBeanCollection<T extends MongoBeanUtils<Bean, Filter, Update, Project, Index>, Bean, Filter extends FilterBeanField, Update extends UpdateBeanField, Project extends ProjectBeanField, Index extends IndexBeanField> implements MongoCollection<Bean> {
	val Class<T> utilsClass
	@Delegate val MongoCollection<Bean> collection

	new(Class<T> utilsClass, MongoDatabase database, String collectionName) {
		this(utilsClass, database.getCollection(collectionName, utilsClass.enclosingClass) as MongoCollection<Bean>)
	}

	def <T2 extends MongoBeanUtils<Bean2, Filter2, Update2, Project2, Index2>, Bean2, Filter2 extends FilterBeanField, Update2 extends UpdateBeanField, Project2 extends ProjectBeanField, Index2 extends IndexBeanField> withBeanUtilsClass(
		Class<Bean2> beanClass,
		Class<T2> utilsClass
	) {
		return new MongoBeanCollection<T2, Bean2, Filter2, Update2, Project2, Index2>(
			utilsClass,
			collection.withDocumentClass(beanClass)
		) {
		}
	}

	protected def <T> Constructor<T> getClassParameterConstructor(int index, Class<?>... args) {
		return ((class.genericSuperclass as ParameterizedType).actualTypeArguments.get(index) as Class<T>).
			getConstructor(args)
	}

	val Constructor<Filter> filterConstructor = getClassParameterConstructor(2, String)
	val Constructor<Update> updateConstructor = getClassParameterConstructor(3, UpdateStatementList, String)
	val Constructor<Project> projectConstructor = getClassParameterConstructor(4, ProjectStatementList, String)
	val Constructor<Index> indexConstructor = getClassParameterConstructor(5, IndexStatementList, String)

	def setIndexes((CreateIndexesHandler<Index>)=>void configurationCallback, SingleResultCallback<Void> callback) {
		val indexesHandler = new CreateIndexesHandler(indexConstructor)
		configurationCallback.apply(indexesHandler)
		collection.setCollectionIndexes(indexesHandler.indexes, callback)
	}

	@FinalFieldsConstructor static class CreateIndexesHandler<T extends IndexBeanField> {
		val Constructor<T> constructor
		val indexes = new ArrayList<IndexModelExtended>

		def createIndex((T)=>void callback) {
			val statements = new IndexStatementList
			callback.apply(constructor.newInstance(statements, null))
			val index = new IndexModelExtended(statements, new IndexOptions)
			indexes.add(index)
			return index
		}

		def withOptions(IndexModelExtended index, (IndexOptions)=>void callback) { callback.apply(index.options) }
	}

	def static setCollectionIndexes(MongoCollection<?> collection, List<IndexModelExtended> indexes,
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

	def protected build((Filter)=>FilterExpression it) { return it.apply(filterConstructor.newInstance(#[null])) }

	def protected build((Update)=>void it) {
		val updates = new UpdateStatementList
		it.apply(updateConstructor.newInstance(updates, null))
		return updates
	}

	def protected <D> wrap(FindIterable<D> iterable) { return new MongoBeanFindIterable(iterable, projectConstructor) }

	/**
	 * Counts the number of documents in the collection according to the given options.
	 * 
	 * @param filter   the query filter
	 * @param callback the callback passed the number of documents in the collection
	 */
	def countWhere((Filter)=>FilterExpression filter, SingleResultCallback<Long> callback) {
		count(filter.build, callback)
	}

	/**
	 * Counts the number of documents in the collection according to the given options.
	 * 
	 * @param filter   the query filter
	 * @param options  the options describing the count
	 * @param callback the callback passed the number of documents in the collection
	 */
	def countWhere((Filter)=>FilterExpression filter, CountOptions options, SingleResultCallback<Long> callback) {
		count(filter.build, options, callback)
	}

	/**
	 * Finds all documents in the collection.
	 * 
	 * @param filter the query filter
	 * @return the find iterable interface
	 * @mongodb.driver.manual tutorial/query-documents/ Find
	 */
	override MongoBeanFindIterable<Bean, Project> find() { return collection.find.wrap }

	/**
	 * Finds all documents in the collection.
	 * 
	 * @param filter the query filter
	 * @return the find iterable interface
	 * @mongodb.driver.manual tutorial/query-documents/ Find
	 */
	def findWhere((Filter)=>FilterExpression filter) { return find(filter.build).wrap }

	/**
	 * Removes at most one document from the collection that matches the given filter.  If no documents match, the collection is not
	 * modified.
	 * 
	 * @param filter   the query filter to apply the the delete operation
	 * @param callback the callback passed the result of the remove one operation
	 * @throws com.mongodb.MongoWriteException        returned via the callback
	 * @throws com.mongodb.MongoWriteConcernException returned via the callback
	 * @throws com.mongodb.MongoException             returned via the callback
	 */
	def deleteOneWhere((Filter)=>FilterExpression filter, SingleResultCallback<DeleteResult> callback) {
		deleteOne(filter.build, callback)
	}

	/**
	 * Removes all documents from the collection that match the given query filter.  If no documents match, the collection is not modified.
	 * 
	 * @param filter   the query filter to apply the the delete operation
	 * @param callback the callback passed the result of the remove many operation
	 * @throws com.mongodb.MongoWriteException        returned via the callback
	 * @throws com.mongodb.MongoWriteConcernException returned via the callback
	 * @throws com.mongodb.MongoException             returned via the callback
	 */
	def deleteManyWhere((Filter)=>FilterExpression filter, SingleResultCallback<DeleteResult> callback) {
		deleteMany(filter.build, callback)
	}

	/**
	 * Replace a document in the collection according to the specified arguments.
	 * 
	 * @param filter      the query filter to apply the the replace operation
	 * @param replacement the replacement document
	 * @param callback    the callback passed the result of the replace one operation
	 * @throws com.mongodb.MongoWriteException        returned via the callback
	 * @throws com.mongodb.MongoWriteConcernException returned via the callback
	 * @throws com.mongodb.MongoException             returned via the callback
	 * @mongodb.driver.manual tutorial/modify-documents/#replace-the-document Replace
	 */
	def replaceOneWhere(
		(Filter)=>FilterExpression filter,
		Bean replacement,
		SingleResultCallback<UpdateResult> callback
	) {
		replaceOne(filter.build, replacement, callback)
	}

	/**
	 * Replace a document in the collection according to the specified arguments.
	 * 
	 * @param filter      the query filter to apply the the replace operation
	 * @param replacement the replacement document
	 * @param options     the options to apply to the replace operation
	 * @param callback    the callback passed the result of the replace one operation
	 * @throws com.mongodb.MongoWriteException        returned via the callback
	 * @throws com.mongodb.MongoWriteConcernException returned via the callback
	 * @throws com.mongodb.MongoException             returned via the callback
	 * @mongodb.driver.manual tutorial/modify-documents/#replace-the-document Replace
	 */
	def replaceOneWhere(
		(Filter)=>FilterExpression filter,
		Bean replacement,
		UpdateOptions options,
		SingleResultCallback<UpdateResult> callback
	) {
		replaceOne(filter.build, replacement, options, callback)
	}

	/**
	 * Update a single document in the collection according to the specified arguments.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @param callback the callback passed the result of the update one operation
	 * @throws com.mongodb.MongoWriteException        returned via the callback
	 * @throws com.mongodb.MongoWriteConcernException returned via the callback
	 * @throws com.mongodb.MongoException             returned via the callback
	 * @mongodb.driver.manual tutorial/modify-documents/ Updates
	 * @mongodb.driver.manual reference/operator/update/ Update Operators
	 */
	def updateOneWhere(
		(Filter)=>FilterExpression filter,
		(Update)=>void update,
		SingleResultCallback<UpdateResult> callback
	) {
		updateOne(filter.build, update.build, callback)
	}

	/**
	 * Update a single document in the collection according to the specified arguments.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @param options  the options to apply to the update operation
	 * @param callback the callback passed the result of the update one operation
	 * @throws com.mongodb.MongoWriteException        returned via the callback
	 * @throws com.mongodb.MongoWriteConcernException returned via the callback
	 * @throws com.mongodb.MongoException             returned via the callback
	 * @mongodb.driver.manual tutorial/modify-documents/ Updates
	 * @mongodb.driver.manual reference/operator/update/ Update Operators
	 */
	def updateOneWhere(
		(Filter)=>FilterExpression filter,
		(Update)=>void update,
		UpdateOptions options,
		SingleResultCallback<UpdateResult> callback
	) {
		updateOne(filter.build, update.build, options, callback)
	}

	/**
	 * Update all documents in the collection according to the specified arguments.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators. T
	 * @param callback the callback passed the result of the update one operation
	 * @throws com.mongodb.MongoWriteException        returned via the callback
	 * @throws com.mongodb.MongoWriteConcernException returned via the callback
	 * @throws com.mongodb.MongoException             returned via the callback
	 * @mongodb.driver.manual tutorial/modify-documents/ Updates
	 * @mongodb.driver.manual reference/operator/update/ Update Operators
	 */
	def updateManyWhere(
		(Filter)=>FilterExpression filter,
		(Update)=>void update,
		SingleResultCallback<UpdateResult> callback
	) {
		updateMany(filter.build, update.build, callback)
	}

	/**
	 * Update all documents in the collection according to the specified arguments.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @param options  the options to apply to the update operation
	 * @param callback the callback passed the result of the update one operation
	 * @throws com.mongodb.MongoWriteException        returned via the callback
	 * @throws com.mongodb.MongoWriteConcernException returned via the callback
	 * @throws com.mongodb.MongoException             returned via the callback
	 * @mongodb.driver.manual tutorial/modify-documents/ Updates
	 * @mongodb.driver.manual reference/operator/update/ Update Operators
	 */
	def updateManyWhere(
		(Filter)=>FilterExpression filter,
		(Update)=>void update,
		UpdateOptions options,
		SingleResultCallback<UpdateResult> callback
	) {
		updateMany(filter.build, update.build, options, callback)
	}

	/**
	 * Atomically find a document and remove it.
	 * 
	 * @param filter   the query filter to find the document with
	 * @param callback the callback passed the document that was removed.  If no documents matched the query filter, then null will be
	 *                 returned
	 */
	def findOneAndDeleteWhere((Filter)=>FilterExpression filter, SingleResultCallback<Bean> callback) {
		findOneAndDelete(filter.build, callback)
	}

	/**
	 * Atomically find a document and remove it.
	 * 
	 * @param filter   the query filter to find the document with
	 * @param options  the options to apply to the operation
	 * @param callback the callback passed the document that was removed.  If no documents matched the query filter, then null will be
	 *                 returned
	 */
	def findOneAndDeleteWhere(
		(Filter)=>FilterExpression filter,
		FindOneAndDeleteOptions options,
		SingleResultCallback<Bean> callback
	) {
		findOneAndDelete(filter.build, options, callback)
	}

	/**
	 * Atomically find a document and replace it.
	 * 
	 * @param filter      the query filter to apply the the replace operation
	 * @param replacement the replacement document
	 * @param callback    the callback passed the document that was replaced.  Depending on the value of the {@code returnOriginal}
	 *                    property, this will either be the document as it was before the update or as it is after the update.  If no
	 *                    documents matched the query filter, then null will be returned
	 */
	def findOneAndReplaceWhere(
		(Filter)=>FilterExpression filter,
		Bean replacement,
		SingleResultCallback<Bean> callback
	) {
		findOneAndReplace(filter.build, replacement, callback)
	}

	/**
	 * Atomically find a document and replace it.
	 * 
	 * @param filter      the query filter to apply the the replace operation
	 * @param replacement the replacement document
	 * @param options     the options to apply to the operation
	 * @param callback    the callback passed the document that was replaced.  Depending on the value of the {@code returnOriginal}
	 *                    property, this will either be the document as it was before the update or as it is after the update.  If no
	 *                    documents matched the query filter, then null will be returned
	 */
	def findOneAndReplaceWhere(
		(Filter)=>FilterExpression filter,
		Bean replacement,
		FindOneAndReplaceOptions options,
		SingleResultCallback<Bean> callback
	) {
		findOneAndReplace(filter.build, replacement, options, callback)
	}

	/**
	 * Atomically find a document and update it.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @param callback the callback passed the document that was updated before the update was applied.  If no documents matched the query
	 *                 filter, then null will be returned
	 */
	def findOneAndUpdateWhere(
		(Filter)=>FilterExpression filter,
		(Update)=>void update,
		SingleResultCallback<Bean> callback
	) {
		findOneAndUpdate(filter.build, update.build, callback)
	}

	/**
	 * Atomically find a document and update it.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @param options  the options to apply to the operation
	 * @param callback the callback passed the document that was updated.  Depending on the value of the {@code returnOriginal} property,
	 *                 this will either be the document as it was before the update or as it is after the update.  If no documents matched
	 *                 the query filter, then null will be returned
	 */
	def findOneAndUpdateWhere(
		(Filter)=>FilterExpression filter,
		(Update)=>void update,
		FindOneAndUpdateOptions options,
		SingleResultCallback<Bean> callback
	) {
		findOneAndUpdate(filter.build, update.build, options, callback)
	}
}
