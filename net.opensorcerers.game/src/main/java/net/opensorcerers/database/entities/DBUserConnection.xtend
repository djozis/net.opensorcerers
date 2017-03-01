package net.opensorcerers.database.entities

import java.util.UUID
import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.Id
import javax.persistence.JoinColumn
import javax.persistence.ManyToOne
import org.eclipse.xtend.lib.annotations.Accessors
import org.hibernate.annotations.GenericGenerator

@Accessors @Entity class DBUserConnection {
	@Id
	@GeneratedValue(generator="uuid2")
	@GenericGenerator(name="uuid2", strategy="uuid2")
	@Column(unique=true, nullable=false, columnDefinition="BINARY(16)")
	UUID id

	@Column(nullable=false)
	byte[] digest

	@ManyToOne(fetch=LAZY)
	@JoinColumn(nullable=false)
	DBUser user
}
