package net.opensorcerers.game.shared

import java.io.Serializable

class ClientVisibleException extends Exception implements Serializable {
	new(String message) {
		super(message)
	}

	protected new() {
	}
}
