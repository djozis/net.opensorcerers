package net.opensorcerers.game.client.lib.chainreaction

import net.opensorcerers.game.client.lib.chainreaction.ChainReaction.ChainedCallback

interface ChainLinkAPI {
	def <T> ChainedCallback<T> ifSuccessful((T)=>void handler)
}
