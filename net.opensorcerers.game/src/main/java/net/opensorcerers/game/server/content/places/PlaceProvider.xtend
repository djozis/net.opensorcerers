package net.opensorcerers.game.server.content.places

import net.opensorcerers.game.server.database.entities.DBUserCharacter

class PlaceProvider {
	public static val PlaceProvider INSTANCE = new PlaceProvider

	protected new() {
	}

	def getDefaultPosition() { return "0:0:0" }

	def Place getPlace(String position) {
		switch position {
			case "0:0:0":
				return new BasePlace {
					override createCommandsList() {
						return #[
							new BasePlace.PlaceCommand("Go up the hill", new BasePlace.MovementAction("0:0:1"))
						]
					}

					override getId() '''0:0:0'''

					override getDescription(DBUserCharacter character) '''
						You stand in an open field. You can see a hill.
					'''
				}
			case "0:0:1":
				return new BasePlace {
					override createCommandsList() {
						return #[
							new BasePlace.PlaceCommand("Go down the hill", new BasePlace.MovementAction("0:0:0"))
						]
					}

					override getId() '''0:0:1'''

					override getDescription(DBUserCharacter character) '''
						You on the top of a hill. You can see a field.
					'''
				}
		}
	}
}
