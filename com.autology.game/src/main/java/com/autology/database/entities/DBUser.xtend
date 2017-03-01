package com.autology.database.entities

import java.util.UUID
import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.Id
import org.eclipse.xtend.lib.annotations.Accessors
import org.hibernate.annotations.GenericGenerator

@Accessors @Entity class DBUser {
	@Id
	@GeneratedValue(generator="uuid2") @GenericGenerator(name="uuid2", strategy="uuid2")
	@Column(unique=true, nullable=false, columnDefinition="BINARY(16)")
	UUID id

	@Column(nullable=false)
	String alias
}
