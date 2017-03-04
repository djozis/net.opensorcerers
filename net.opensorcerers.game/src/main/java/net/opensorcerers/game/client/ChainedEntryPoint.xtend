package net.opensorcerers.game.client

import com.google.gwt.core.client.EntryPoint
import net.opensorcerers.game.client.lib.ChainReaction

abstract class ChainedEntryPoint implements EntryPoint {
	final override void onModuleLoad() { addOnLoad(new ChainReaction).start }

	def ChainReaction addOnLoad(ChainReaction chain)
}
