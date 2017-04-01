package net.opensorcerers.mongoframework.lib

import co.paralleluniverse.fibers.Suspendable
import com.mongodb.Block
import com.mongodb.CursorType
import com.mongodb.async.AsyncBatchCursor
import com.mongodb.async.client.FindIterable
import java.lang.reflect.Constructor
import java.util.ArrayList
import java.util.Collection
import java.util.concurrent.TimeUnit
import net.opensorcerers.mongoframework.lib.project.ProjectBeanField
import net.opensorcerers.mongoframework.lib.project.ProjectStatementList
import org.bson.conversions.Bson
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static net.opensorcerers.mongoframework.lib.FiberBlockingSingleResultCallback.*

@FinalFieldsConstructor class MongoBeanFindIterable<T, Project extends ProjectBeanField> {
	val FindIterable<T> iterable
	val Constructor<Project> projectionConstructor

	/**
	 * Sets a document describing the fields to return for all matching documents.
	 * 
	 * @param projection the project expression, which may be null.
	 * @return this
	 * @mongodb.driver.manual reference/method/db.collection.find/ Projection
	 */
	def projection((Project)=>void projection) {
		val ProjectStatementList built = new ProjectStatementList
		projection.apply(projectionConstructor.newInstance(built, null))
		iterable.projection(built)
		return this
	}

	/**
	 * Helper to return the first item in the iterator or null.
	 */
	@Suspendable def T first() { fiberBlockingCallback[iterable.first(it)].run }

	/**
	 * Iterates over all documents in the view, applying the given block to each, and completing the returned future after all documents
	 * have been iterated, or an exception has occurred.
	 * 
	 * @param block    the block to apply to each document
	 */
	@Suspendable def void forEach(Block<? super T> block) {
		fiberBlockingCallback[iterable.forEach(block, it)].run
	}

	/**
	 * Iterates over all the documents, adding each to the given target.
	 * 
	 * @param target   the collection to insert into
	 * @param <A>      the collection type
	 */
	@Suspendable def <A extends Collection<? super T>> A into(A target) {
		this.forEach[target.add(it)]
		return target
	}

	/**
	 * Iterates over all the documents, adding each to an array list.
	 * 
	 * @return the array list
	 */
	@Suspendable def ArrayList<T> toArrayList() {
		val result = new ArrayList<T>
		this.forEach[result.add(it)]
		return result
	}

	/**
	 * Sets the number of documents to return per batch.
	 * 
	 * @param batchSize the batch size
	 * @return this
	 * @mongodb.driver.manual reference/method/cursor.batchSize/#cursor.batchSize Batch Size
	 */
	def batchSize(int batchSize) {
		iterable.batchSize(batchSize)
		return this
	}

	/**
	 * Provide the underlying {@link AsyncBatchCursor} allowing fine grained control of the cursor.
	 */
	@Suspendable def AsyncBatchCursor<T> batchCursor() { return fiberBlockingCallback[iterable.batchCursor(it)].run }

	/**
	 * Sets the query filter to apply to the query.
	 * 
	 * @param filter the filter, which may be null.
	 * @return this
	 * @mongodb.driver.manual reference/method/db.collection.find/ Filter
	 */
	def filter(Bson filter) {
		iterable.filter(filter)
		return this
	}

	/**
	 * Sets the limit to apply.
	 * 
	 * @param limit the limit, which may be null
	 * @return this
	 * @mongodb.driver.manual reference/method/cursor.limit/#cursor.limit Limit
	 */
	def limit(int limit) {
		iterable.limit(limit)
		return this
	}

	/**
	 * Sets the number of documents to skip.
	 * 
	 * @param skip the number of documents to skip
	 * @return this
	 * @mongodb.driver.manual reference/method/cursor.skip/#cursor.skip Skip
	 */
	def skip(int skip) {
		iterable.skip(skip)
		return this
	}

	/**
	 * Sets the maximum execution time on the server for this operation.
	 * 
	 * @param maxTime  the max time
	 * @param timeUnit the time unit, which may not be null
	 * @return this
	 * @mongodb.driver.manual reference/method/cursor.maxTimeMS/#cursor.maxTimeMS Max Time
	 */
	def maxTime(long maxTime, TimeUnit timeUnit) {
		iterable.maxTime(maxTime, timeUnit)
		return this
	}

	/**
	 * Sets the query modifiers to apply to this operation.
	 * 
	 * @param modifiers the query modifiers to apply, which may be null.
	 * @return this
	 * @mongodb.driver.manual reference/operator/query-modifier/ Query Modifiers
	 */
	def modifiers(Bson modifiers) {
		iterable.modifiers(modifiers)
		return this
	}

	/**
	 * Sets a document describing the fields to return for all matching documents.
	 * 
	 * @param projection the project document, which may be null.
	 * @return this
	 * @mongodb.driver.manual reference/method/db.collection.find/ Projection
	 */
	def projection(Bson projection) {
		iterable.projection(projection)
		return this
	}

	/**
	 * Sets the sort criteria to apply to the query.
	 * 
	 * @param sort the sort criteria, which may be null.
	 * @return this
	 * @mongodb.driver.manual reference/method/cursor.sort/ Sort
	 */
	def sort(Bson sort) {
		iterable.sort(sort)
		return this
	}

	/**
	 * The server normally times out idle cursors after an inactivity period (10 minutes)
	 * to prevent excess memory use. Set this option to prevent that.
	 * 
	 * @param noCursorTimeout true if cursor timeout is disabled
	 * @return this
	 */
	def noCursorTimeout(boolean noCursorTimeout) {
		iterable.noCursorTimeout(noCursorTimeout)
		return this
	}

	/**
	 * Users should not set this under normal circumstances.
	 * 
	 * @param oplogReplay if oplog replay is enabled
	 * @return this
	 */
	def oplogReplay(boolean oplogReplay) {
		iterable.oplogReplay(oplogReplay)
		return this
	}

	/**
	 * Get partial results from a sharded cluster if one or more shards are unreachable (instead of throwing an error).
	 * 
	 * @param partial if partial results for sharded clusters is enabled
	 * @return this
	 */
	def partial(boolean partial) {
		iterable.partial(partial)
		return this
	}

	/**
	 * Sets the cursor type.
	 * 
	 * @param cursorType the cursor type
	 * @return this
	 */
	def cursorType(CursorType cursorType) {
		iterable.cursorType(cursorType)
		return this
	}
}
