package net.opensorcerers.game.client.lib.chainreaction

import net.opensorcerers.game.client.lib.chainreaction.ChainReaction.ChainedCallback
import net.opensorcerers.game.shared.ResponseOrError

interface ChainLinkAPI {
	def <R, T extends ResponseOrError<R>> ChainedCallback<R, T> ifSuccessful((R)=>void handler)
}
