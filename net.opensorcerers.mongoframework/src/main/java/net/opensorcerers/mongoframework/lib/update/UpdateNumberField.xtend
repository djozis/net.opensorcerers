package net.opensorcerers.mongoframework.lib.update

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class UpdateNumberField extends UpdateField {
	def +=(Number other) { OP_INCREMENT.doOpToField(other) }

	def -=(double other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(Double other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(int other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(Integer other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(float other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(Float other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(byte other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(Byte other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(short other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(Short other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(long other) { OP_INCREMENT.doOpToField(other * -1) }

	def -=(Long other) { OP_INCREMENT.doOpToField(other * -1) }

	def *=(Number other) { OP_MULTIPLY.doOpToField(other) }

	def /=(double other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(Double other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(int other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(Integer other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(float other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(Float other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(byte other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(Byte other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(short other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(Short other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(long other) { OP_MULTIPLY.doOpToField(1 / other) }

	def /=(Long other) { OP_MULTIPLY.doOpToField(1 / other) }
}
