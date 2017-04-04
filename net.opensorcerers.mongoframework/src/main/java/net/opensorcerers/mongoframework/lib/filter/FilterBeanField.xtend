package net.opensorcerers.mongoframework.lib.filter

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class FilterBeanField extends FilterField {
	def get_id() {
		if (fieldName === null || fieldName.empty) {
			return new FilterField("_id")
		} else {
			return new FilterField(fieldName + "._id")
		}
	}
}
