package net.opensorcerers.database.entities

import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.Id
import javax.persistence.JoinColumn
import javax.persistence.ManyToOne
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors @Entity class DBAuthenticationIdPassword {
	@Id
	@Column(unique=true, nullable=false, length=254)
	String id

	@Column(nullable=false)
	byte[] digest

	@ManyToOne(fetch=LAZY)
	@JoinColumn(nullable=false)
	DBUser user
}
