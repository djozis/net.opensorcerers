package net.opensorcerers.game.server.content.places

import net.opensorcerers.game.server.database.entities.DBUserCharacter

import static net.opensorcerers.game.server.content.places.PlaceExtensions.*

class PseudoRandomPlaceProvider {
	/**
	 * Background: http://www.javamex.com/tutorials/random_numbers/xorshift.shtml
	 * This method will produce the number 0 for input of 0, otherwise fairly random output.
	 */
	static def long randomLong(long seed) {
		var x = seed
		x = x.bitwiseXor(x << 21)
		x = x.bitwiseXor(x >>> 35)
		x = x.bitwiseXor(x << 4)
		return x
	}

	/**
	 * This could be something like Cantors or Szudziks, but this is probably fine.
	 */
	static def combine(long x, long y) { return (x << 32) + y }

	static def randomLong(long x, long y) { return combine(x, y).randomLong }

	static val places = #["hill", "mountain", "valley", "lake", "city", "forest", "swamp", "meadow", "cliff", "volcano"]

	def Place getPlace(long x, long y) {
		val place = places.get((randomLong(x, y) % places.length) as int)
		return new BasePlace {
			override createCommandsList() {
				return #[
					new BasePlace.PlaceCommand(
						'''North to «places.get((randomLong(x , y + 1) % places.length) as int)»''',
						[proxyFactory, character|tryToMoveTo(proxyFactory, character, '''0:«x»:«y + 1»''')]
					),
					new BasePlace.PlaceCommand(
						'''South to «places.get((randomLong(x , y - 1) % places.length) as int)»''',
						[proxyFactory, character|tryToMoveTo(proxyFactory, character, '''0:«x»:«y - 1»''')]
					),
					new BasePlace.PlaceCommand(
						'''East to «places.get((randomLong(x + 1, y) % places.length) as int)»''',
						[proxyFactory, character|tryToMoveTo(proxyFactory, character, '''0:«x + 1»:«y»''')]
					),
					new BasePlace.PlaceCommand(
						'''West to «places.get((randomLong(x - 1, y) % places.length) as int)»''',
						[proxyFactory, character|tryToMoveTo(proxyFactory, character, '''0:«x - 1»:«y»''')]
					)
				]
			}

			override getId() '''0:«x»:«y»'''

			override getDescription(DBUserCharacter character) '''
				You stand in a «place».
			'''
		}
	}
}
