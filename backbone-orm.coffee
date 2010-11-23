
#root of Porkepic
Porkepic = {}
#Export it outside this scope
this.Porkepic = Porkepic

# ModelStore
# Trivial identity map for related models.
Porkepic.ModelStore = (model)->
	this.store = {}
	this.model = model
	this
	
_.extend Porkepic.ModelStore.prototype, Backbone.Events,
	create : (attributes, options) ->
		id = attributes["id"]
		if id? 
			object = this.store[id] 
			if not object?
				this.store[id] = new this.model(attributes, options) 
				object = this.store[id]
				this.trigger("add", object)
		else 
			object = new this.model(attributes, options)
		return object
	
	records: ->
		this.store
		
	lookupOne: (id)->
		this.store[id]

#the different model stores
Porkepic.ModelStores = ->
	this
	
_.extend Porkepic.ModelStores.prototype, Backbone.Events,
	storeForModel : (model) ->
		store = this[model.type]
		return store if store?
		this[model.type] = new Porkepic.ModelStore(model)
		
		
Porkepic.Stores = new Porkepic.ModelStores()

#Types of associations
# EmbedsOne
# EmbedsMany
# HasOne
# HasMany
# EmbeddedInMany
#
# There are no BelongsTo because the last argument of EmbedsOne and HasOne (foreign_key)
# allows you to reciprocate the relation to the other model.


# EmbedsOne
# There is already a complete model inside the model
Porkepic.EmbedsOne = (model_object, foreign_model, key, foreign_key) ->
	this.model_object = model_object
	relation = 
		foreign_model : foreign_model
		key : key
		foreign_key : foreign_key
		store : Porkepic.Stores.storeForModel(foreign_model)
	this[key + "Relation"] = relation
	this.createEmbedsOneRelation(relation)
	this

# _.extend(this, new Porkepic.EmbedsOne(this, Project, "project"))

_.extend Porkepic.EmbedsOne.prototype, Backbone.Events, 
	createEmbedsOneRelation : (relation)->
		object = this.model_object.get(relation.key)
		if object?
			foreign_object = relation.store.create(object)
			# set it on the model
			value = {}
			value[relation.key] = foreign_object
			this.model_object.set value
			
			#check for embdeddedinmany reciprocity
			fRel = foreign_object[relation.key + "RelationEIM"]
			foreign_object.embedInMany(this.model_object, fRel) if fRel? and foreign_object.embedInMany?
			#do the corresponding for one
			if relation.foreign_key
				value = {}
				value[relation.foreign_key] = this.model_object
				foreign_object.set value
					
	
Porkepic.EmbedsMany = (model_object, foreign_model, key, foreign_key) ->
	this.model_object = model_object
	relation = 
		foreign_model : foreign_model
		key : key
		foreign_key : foreign_key
		store : Porkepic.Stores.storeForModel(foreign_model)
	this[key + "Relation"] = relation
	this.createEmbedsManyRelation(relation)
	this
	
_.extend Porkepic.EmbedsMany.prototype, Backbone.Events, 
	createEmbedsManyRelation : (relation)->
		objects = this.model_object.get(relation.key)
		if objects?
			foreign_objects = new Backbone.Collection
			
			#create all objects
			model = this.model_object
			_.each objects, (object)->
				foreign_object = relation.store.create(object)
				foreign_objects.add foreign_object
					
				#check for embdeddedinMany reciprocity
				fRel = foreign_object[relation.key + "RelationEIM"]
				foreign_object.embedInMany(model, fRel) if fRel? and fRel.key == relation.foreign_key and foreign_object.embedInMany?
				
				#do the corresponding for one
				if relation.foreign_key
					value = {}
					value[relation.foreign_key] = model
					foreign_object.set value
					
			# set it on the model
			value = {}
			value[relation.key] = foreign_objects
			this.model_object.set value
					
# EmbeddedInMany
# The model is embedded more than once in different objects
# _.extend(this, new Porkepic.EmbeddedInMany(this, WorkSheet, "worksheets"))
Porkepic.EmbeddedInMany = (model_object, foreign_model, key, foreign_key) ->
	relation = 
		key : key
		foreign_model : foreign_model
		foreign_key: foreign_key
				
	this[foreign_key + "RelationEIM"] = relation
	this.model_object = model_object
	this

_.extend Porkepic.EmbeddedInMany.prototype, Backbone.Events, 
	embedInMany : (object, params)->
		foreign_model = params.foreign_model
		objects = this.model_object.get params.key
		if not objects?
			objects = new Backbone.Collection
		
		objects.add object
		value = {}
		value[params.key] = objects
		this.model_object.set value


# HasOne
# The model is related to one other object
# _.extend(this, new Porkepic.HasOne(this, Foreman, "foreman"))
Porkepic.HasOne = (model_object, foreign_model, key, foreign_key) ->
	this.model_object = model_object
	relation = 
		foreign_model : foreign_model
		key : key
		foreign_key : foreign_key
		store : Porkepic.Stores.storeForModel(foreign_model)
	
	object_id = model_object.get(key + "_id")
	return this if not object_id?
	
	object = relation.store.lookupOne( object_id )
	
	if not object?
		#bind to the add event
		hasOne = this
		relation.store.bind "add", (object)->
			if model_object.get(relation.key + "_id") is object.id
				hasOne.createHasOneRelation(relation, object)
	else
		#create the relation now
		this.createHasOneRelation(relation, object)
	
	this[key + "Relation"] = relation
	this

_.extend Porkepic.HasOne.prototype, Backbone.Events, 
	createHasOneRelation: (relation, object) ->
		value = {}
		value[relation.key] = object
		this.model_object.set value
		
		#check for HasMany reciprocity
		fRel = object[relation.key + "RelationHM"]
		object.addInMany(this.model_object, fRel) if fRel? and fRel.key == relation.foreign_key and object.addInMany?
		
		if relation.foreign_key?
			value = {}
			value[relation.foreign_key] = this.model_object
			object.set value
		
# HasMany
# The model is related to many other objects
# _.extend(this, new Porkepic.HasMany(this, Project, "projects", "foreman"))
Porkepic.HasMany = (model_object, foreign_model, key, foreign_key) ->
	relation = 
		key : key
		foreign_model : foreign_model
		foreign_key: foreign_key
				
	this[foreign_key + "RelationHM"] = relation
	this.model_object = model_object
	this
	
_.extend Porkepic.HasMany.prototype, Backbone.Events,
	addInMany: (object, params)->
		
		foreign_model = params.foreign_model
		objects = this.model_object.get params.key
		if not objects?
			objects = new Backbone.Collection
		
		objects.add object
		value = {}
		value[params.key] = objects
		this.model_object.set value
