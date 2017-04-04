package net.opensorcerers.game.server.content.places

import java.util.ArrayList
import net.opensorcerers.game.shared.servicetypes.Action

class PlaceProvider {
	public static val PlaceProvider INSTANCE = new PlaceProvider

	protected new() {
	}

	def getDefaultPosition() { return "0:0:0" }

	def Place getPlace(String position) {
		return new StaticPlace => [
			description = '''You are at «position»'''
			actions = new ArrayList
			if (position == "0:0:0") {
				actions.add(new Action => [
					display = '''Go to 0:0:1'''
					code = '''move:0:0:1'''
				])
			} else if (position == "0:0:1") {
				actions.add(new Action => [
					display = '''Go to 0:0:0'''
					code = '''move:0:0:0'''
				])
			}
		]
	}
}
