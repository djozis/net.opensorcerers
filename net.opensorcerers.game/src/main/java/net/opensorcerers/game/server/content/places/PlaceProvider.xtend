package net.opensorcerers.game.server.content.places

class PlaceProvider {
	public static val PlaceProvider INSTANCE = new PlaceProvider

	protected new() {
	}

	def getDefaultPosition() { return "0:0:0" }

	def Place getPlace(String position) {
		val long[] positionElements = position.split(":").map [
			try {
				return Long.parseLong(it, 10)
			} catch (Throwable e) {
				return 0l
			}
		]
		return new PseudoRandomPlaceProvider().getPlace(positionElements.get(1), positionElements.get(2))
	}
}
