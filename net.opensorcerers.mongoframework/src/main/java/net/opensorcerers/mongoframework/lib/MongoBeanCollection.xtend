package net.opensorcerers.mongoframework.lib

import co.paralleluniverse.fibers.Suspendable
import com.mongodb.async.SingleResultCallback
import com.mongodb.async.client.FindIterable
import com.mongodb.async.client.MongoCollection
import com.mongodb.async.client.MongoDatabase
import com.mongodb.client.model.CountOptions
import com.mongodb.client.model.FindOneAndDeleteOptions
import com.mongodb.client.model.FindOneAndReplaceOptions
import com.mongodb.client.model.FindOneAndUpdateOptions
import com.mongodb.client.model.IndexOptions
import com.mongodb.client.model.InsertManyOptions
import com.mongodb.client.model.UpdateOptions
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
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static net.opensorcerers.mongoframework.lib.FiberBlockingSingleResultCallback.*

@FinalFieldsConstructor abstract class MongoBeanCollection<T extends MongoBeanUtils<Bean, Filter, Update, Project, Index>, Bean, Filter extends FilterBeanField, Update extends UpdateBeanField, Project extends ProjectBeanField, Index extends IndexBeanField> {
	val Class<T> utilsClass
	val MongoCollection<Bean> collection

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

	val Constructor<Bean> beanConstructor = getClassParameterConstructor(1)
	val Constructor<Filter> filterConstructor = getClassParameterConstructor(2, String)
	val Constructor<Update> updateConstructor = getClassParameterConstructor(3, UpdateStatementList, String)
	val Constructor<Project> projectConstructor = getClassParameterConstructor(4, ProjectStatementList, String)
	val Constructor<Index> indexConstructor = getClassParameterConstructor(5, IndexStatementList, String)

	@Suspendable def setIndexes((CreateIndexesHandler<Index>)=>void configurationCallback) {
		val indexesHandler = new CreateIndexesHandler(indexConstructor)
		configurationCallback.apply(indexesHandler)
		fiberBlockingCallback[collection.setCollectionIndexes(indexesHandler.indexes, it)].run
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

	protected def static setCollectionIndexes(
		MongoCollection<?> collection,
		List<IndexModelExtended> indexes,
		SingleResultCallback<Void> callback
	) {
		collection.listIndexes(IndexModelExtended).into(new ArrayList<IndexModelExtended>) [ indexList, error |
			try {
				if (error !== null) {
					callback.onResult(null, error)
				} else {
					val IndexModelExtended[] toDrop = indexList.filter[!idIndex && !indexes.contains(it)]
					val IndexModelExtended[] toCreate = indexes.filter[!indexList.contains(it)]
					val ()=>void afterDrop = [
						if (!toCreate.empty) {
							collection.createIndexes(toCreate) [ list, createError |
								callback.onResult(null, createError)
							]
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
	 * @return         the number of documents in the collection
	 */
	@Suspendable def countWhere((Filter)=>FilterExpression filter) {
		return fiberBlockingCallback[collection.count(filter.build, it)].run
	}

	/**
	 * Counts the number of documents in the collection according to the given options.
	 * 
	 * @param filter   the query filter
	 * @param options  the options describing the count
	 * @return          the number of documents in the collection
	 */
	@Suspendable def countWhere((Filter)=>FilterExpression filter, CountOptions options) {
		return fiberBlockingCallback[collection.count(filter.build, options, it)].run
	}

	/**
	 * Finds all documents in the collection.
	 * 
	 * @param filter the query filter
	 * @return the find iterable interface
	 * @mongodb.driver.manual tutorial/query-documents/ Find
	 */
	def find() { return collection.find.wrap }

	/**
	 * Finds all documents in the collection.
	 * 
	 * @param filter the query filter
	 * @return the find iterable interface
	 * @mongodb.driver.manual tutorial/query-documents/ Find
	 */
	def findWhere((Filter)=>FilterExpression filter) { return collection.find(filter.build).wrap }

	/**
	 * Removes at most one document from the collection that matches the given filter.  If no documents match, the collection is not
	 * modified.
	 * 
	 * @param filter   the query filter to apply the the delete operation
	 * @return         the result of the remove one operation
	 * @throws com.mongodb.MongoWriteException        
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException             
	 */
	@Suspendable def deleteOneWhere((Filter)=>FilterExpression filter) {
		return fiberBlockingCallback[collection.deleteOne(filter.build, it)].run
	}

	/**
	 * Removes all documents from the collection that match the given query filter.  If no documents match, the collection is not modified.
	 * 
	 * @param filter   the query filter to apply the the delete operation
	 * @return         the result of the remove many operation
	 * @throws com.mongodb.MongoWriteException        
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException             
	 */
	@Suspendable def deleteManyWhere((Filter)=>FilterExpression filter) {
		return fiberBlockingCallback[collection.deleteMany(filter.build, it)].run
	}

	/**
	 * Replace a document in the collection according to the specified arguments.
	 * 
	 * @param filter      the query filter to apply the the replace operation
	 * @param replacement the replacement document
	 * @return            the result of the replace one operation
	 * @throws com.mongodb.MongoWriteException        
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException             
	 * @mongodb.driver.manual tutorial/modify-documents/#replace-the-document Replace
	 */
	@Suspendable def replaceOneWhere((Filter)=>FilterExpression filter, Bean replacement) {
		return fiberBlockingCallback[collection.replaceOne(filter.build, replacement, it)].run
	}

	/**
	 * Replace a document in the collection according to the specified arguments.
	 * 
	 * @param filter      the query filter to apply the the replace operation
	 * @param replacement the replacement document
	 * @param options     the options to apply to the replace operation
	 * @return         the result of the replace one operation
	 * @throws com.mongodb.MongoWriteException        
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException             
	 * @mongodb.driver.manual tutorial/modify-documents/#replace-the-document Replace
	 */
	@Suspendable def replaceOneWhere((Filter)=>FilterExpression filter, Bean replacement, UpdateOptions options) {
		return fiberBlockingCallback[collection.replaceOne(filter.build, replacement, options, it)].run
	}

	/**
	 * Update a single document in the collection according to the specified arguments.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @return         the result of the update one operation
	 * @throws com.mongodb.MongoWriteException        
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException             
	 * @mongodb.driver.manual tutorial/modify-documents/ Updates
	 * @mongodb.driver.manual reference/operator/update/ Update Operators
	 */
	@Suspendable def updateOneWhere((Filter)=>FilterExpression filter, (Update)=>void update) {
		return fiberBlockingCallback[collection.updateOne(filter.build, update.build, it)].run
	}

	/**
	 * Update a single document in the collection according to the specified arguments.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @param options  the options to apply to the update operation
	 * @return         the result of the update one operation
	 * @throws com.mongodb.MongoWriteException        
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException             
	 * @mongodb.driver.manual tutorial/modify-documents/ Updates
	 * @mongodb.driver.manual reference/operator/update/ Update Operators
	 */
	@Suspendable def updateOneWhere((Filter)=>FilterExpression filter, (Update)=>void update, UpdateOptions options) {
		return fiberBlockingCallback[collection.updateOne(filter.build, update.build, options, it)].run
	}

	/**
	 * Update a single document in the collection according to the specified arguments.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @param options  the options to apply to the update operation
	 * @return         the result of the update one operation
	 * @throws com.mongodb.MongoWriteException        
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException             
	 * @mongodb.driver.manual tutorial/modify-documents/ Updates
	 * @mongodb.driver.manual reference/operator/update/ Update Operators
	 */
	@Suspendable def updateOneWhere(
		(Filter)=>FilterExpression filter,
		(Update)=>void update,
		(UpdateOptions)=>void options
	) {
		return fiberBlockingCallback[collection.updateOne(filter.build, update.build, new UpdateOptions => options, it)].
			run
	}

	/**
	 * Update all documents in the collection according to the specified arguments.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators. T
	 * @return         the result of the update one operation
	 * @throws com.mongodb.MongoWriteException        
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException             
	 * @mongodb.driver.manual tutorial/modify-documents/ Updates
	 * @mongodb.driver.manual reference/operator/update/ Update Operators
	 */
	@Suspendable def updateManyWhere((Filter)=>FilterExpression filter, (Update)=>void update) {
		return fiberBlockingCallback[collection.updateMany(filter.build, update.build, it)].run
	}

	/**
	 * Update all documents in the collection according to the specified arguments.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @param options  the options to apply to the update operation
	 * @return         the result of the update one operation
	 * @throws com.mongodb.MongoWriteException        
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException             
	 * @mongodb.driver.manual tutorial/modify-documents/ Updates
	 * @mongodb.driver.manual reference/operator/update/ Update Operators
	 */
	@Suspendable def updateManyWhere((Filter)=>FilterExpression filter, (Update)=>void update, UpdateOptions options) {
		return fiberBlockingCallback[collection.updateMany(filter.build, update.build, options, it)].run
	}

	/**
	 * Atomically find a document and remove it.
	 * 
	 * @param filter   the query filter to find the document with
	 * return          the document that was removed.  If no documents matched the query filter, then null will be
	 *                 returned
	 */
	@Suspendable def findOneAndDeleteWhere((Filter)=>FilterExpression filter) {
		return fiberBlockingCallback[collection.findOneAndDelete(filter.build, it)].run
	}

	/**
	 * Atomically find a document and remove it.
	 * 
	 * @param filter   the query filter to find the document with
	 * @param options  the options to apply to the operation
	 * return          the document that was removed.  If no documents matched the query filter, then null will be
	 *                 returned
	 */
	@Suspendable def findOneAndDeleteWhere((Filter)=>FilterExpression filter, FindOneAndDeleteOptions options) {
		return fiberBlockingCallback[collection.findOneAndDelete(filter.build, options, it)].run
	}

	/**
	 * Atomically find a document and replace it.
	 * 
	 * @param filter      the query filter to apply the the replace operation
	 * @param replacement the replacement document
	 * @return            the document that was replaced.  Depending on the value of the {@code returnOriginal}
	 *                    property, this will either be the document as it was before the update or as it is after the update.  If no
	 *                    documents matched the query filter, then null will be returned
	 */
	@Suspendable def findOneAndReplaceWhere((Filter)=>FilterExpression filter, Bean replacement) {
		return fiberBlockingCallback[collection.findOneAndReplace(filter.build, replacement, it)].run
	}

	/**
	 * Atomically find a document and replace it.
	 * 
	 * @param filter      the query filter to apply the the replace operation
	 * @param replacement the replacement document
	 * @param options     the options to apply to the operation
	 * @return             the document that was replaced.  Depending on the value of the {@code returnOriginal}
	 *                    property, this will either be the document as it was before the update or as it is after the update.  If no
	 *                    documents matched the query filter, then null will be returned
	 */
	@Suspendable def findOneAndReplaceWhere(
		(Filter)=>FilterExpression filter,
		Bean replacement,
		FindOneAndReplaceOptions options
	) {
		return fiberBlockingCallback[collection.findOneAndReplace(filter.build, replacement, options, it)].run
	}

	/**
	 * Atomically find a document and update it.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @return         the document that was updated before the update was applied.  If no documents matched the query
	 *                 filter, then null will be returned
	 */
	@Suspendable def findOneAndUpdateWhere((Filter)=>FilterExpression filter, (Update)=>void update) {
		return fiberBlockingCallback[collection.findOneAndUpdate(filter.build, update.build, it)].run
	}

	/**
	 * Atomically find a document and update it.
	 * 
	 * @param filter   the query filter, which may not be null.
	 * @param update   the update, which may not be null. The update to apply must include only update operators.
	 * @param options  the options to apply to the operation
	 * @return		   Depending on the value of the {@code returnOriginal} property,
	 *                 this will either be the document as it was before the update or as it is after the update.  If no documents matched
	 *                 the query filter, then null will be returned
	 */
	@Suspendable def findOneAndUpdateWhere(
		(Filter)=>FilterExpression filter,
		(Update)=>void update,
		FindOneAndUpdateOptions options
	) {
		return fiberBlockingCallback[collection.findOneAndUpdate(filter.build, update.build, options, it)].run
	}

	/**
	 * Inserts the provided document. If the document is missing an identifier, the driver should generate one.
	 * 
	 * @param document the document to insert
	 * @throws com.mongodb.MongoWriteException 
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException 
	 */
	@Suspendable def void insertOne(Bean document) {
		fiberBlockingCallback[collection.insertOne(document, it)].run
	}

	/**
	 * Inserts the provided document. If the document is missing an identifier, the driver should generate one.
	 * 
	 * @param configureDocument a lambda to configure the document to insert
	 * @throws com.mongodb.MongoWriteException 
	 * @throws com.mongodb.MongoWriteConcernException 
	 * @throws com.mongodb.MongoException 
	 */
	@Suspendable def Bean insertOne((Bean)=>void configureDocument) {
		val document = beanConstructor.newInstance => configureDocument
		fiberBlockingCallback[collection.insertOne(document, it)].run
		return document
	}

	/**
	 * Inserts one or more documents.  A call to this method is equivalent to a call to the {@code bulkWrite} method
	 * 
	 * @param documents the documents to insert
	 * @throws com.mongodb.MongoBulkWriteException if there's an exception in the bulk write operation
	 * @throws com.mongodb.MongoException          if the write failed due some other failure
	 * @see MongoCollection#bulkWrite
	 */
	@Suspendable def void insertMany(List<? extends Bean> documents) {
		fiberBlockingCallback[collection.insertMany(documents, it)].run
	}

	/**
	 * Inserts one or more documents.  A call to this method is equivalent to a call to the {@code bulkWrite} method
	 * 
	 * @param documents the documents to insert
	 * @param options   the options to apply to the operation
	 * @throws com.mongodb.MongoBulkWriteException if there's an exception in the bulk write operation
	 * @throws com.mongodb.MongoException          if the write failed due some other failure
	 * @see MongoCollection#bulkWrite
	 */
	@Suspendable def void insertMany(List<? extends Bean> documents, InsertManyOptions options) {
		fiberBlockingCallback[collection.insertMany(documents, options, it)].run
	}
}
