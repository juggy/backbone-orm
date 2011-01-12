(function() {
  var Porkepic;
  Porkepic = {};
  this.Porkepic = Porkepic;
  Porkepic.ModelStore = function(model) {
    this.store = {};
    this.model = model;
    return this;
  };
  _.extend(Porkepic.ModelStore.prototype, Backbone.Events, {
    create: function(attributes, options) {
      var id, object;
      id = attributes["id"];
      if (id != null) {
        object = this.store[id];
        if (!(object != null)) {
          this.store[id] = new this.model(attributes, options);
          object = this.store[id];
          this.trigger("add", object);
        }
      } else {
        object = new this.model(attributes, options);
      }
      return object;
    },
    records: function() {
      return this.store;
    },
    lookupOne: function(id) {
      return this.store[id];
    }
  });
  Porkepic.ModelStores = function() {
    return this;
  };
  _.extend(Porkepic.ModelStores.prototype, Backbone.Events, {
    storeForModel: function(model) {
      var store;
      store = this[model.type];
      if (store != null) {
        return store;
      }
      return this[model.type] = new Porkepic.ModelStore(model);
    }
  });
  Porkepic.Stores = new Porkepic.ModelStores();
  Porkepic.EmbedsOne = function(model_object, foreign_model, key, foreign_key) {
    var relation;
    this.model_object = model_object;
    relation = {
      foreign_model: foreign_model,
      key: key,
      foreign_key: foreign_key,
      store: Porkepic.Stores.storeForModel(foreign_model)
    };
    this[key + "Relation"] = relation;
    this.createEmbedsOneRelation(relation);
    return this;
  };
  _.extend(Porkepic.EmbedsOne.prototype, Backbone.Events, {
    createEmbedsOneRelation: function(relation) {
      var fRel, foreign_object, object, value;
      object = this.model_object.get(relation.key);
      if (object != null) {
        foreign_object = relation.store.create(object);
        value = {};
        value[relation.key] = foreign_object;
        this.model_object.set(value);
        fRel = foreign_object[relation.key + "RelationEIM"];
        if ((fRel != null) && (foreign_object.embedInMany != null)) {
          foreign_object.embedInMany(this.model_object, fRel);
        }
        if (relation.foreign_key) {
          value = {};
          value[relation.foreign_key] = this.model_object;
          return foreign_object.set(value);
        }
      }
    }
  });
  Porkepic.EmbedsMany = function(model_object, foreign_model, key, foreign_key) {
    var relation;
    this.model_object = model_object;
    relation = {
      foreign_model: foreign_model,
      key: key,
      foreign_key: foreign_key,
      store: Porkepic.Stores.storeForModel(foreign_model)
    };
    this[key + "Relation"] = relation;
    this.createEmbedsManyRelation(relation);
    return this;
  };
  _.extend(Porkepic.EmbedsMany.prototype, Backbone.Events, {
    createEmbedsManyRelation: function(relation) {
      var foreign_objects, model, objects, value;
      objects = this.model_object.get(relation.key);
      if (objects != null) {
        foreign_objects = new Backbone.Collection;
        model = this.model_object;
        _.each(objects, function(object) {
          var fRel, foreign_object, value;
          foreign_object = relation.store.create(object);
          foreign_objects.add(foreign_object);
          fRel = foreign_object[relation.key + "RelationEIM"];
          if ((fRel != null) && fRel.key === relation.foreign_key && (foreign_object.embedInMany != null)) {
            foreign_object.embedInMany(model, fRel);
          }
          if (relation.foreign_key) {
            value = {};
            value[relation.foreign_key] = model;
            return foreign_object.set(value);
          }
        });
        value = {};
        value[relation.key] = foreign_objects;
        return this.model_object.set(value);
      }
    }
  });
  Porkepic.EmbeddedInMany = function(model_object, foreign_model, key, foreign_key) {
    var relation;
    relation = {
      key: key,
      foreign_model: foreign_model,
      foreign_key: foreign_key
    };
    this[foreign_key + "RelationEIM"] = relation;
    this.model_object = model_object;
    return this;
  };
  _.extend(Porkepic.EmbeddedInMany.prototype, Backbone.Events, {
    embedInMany: function(object, params) {
      var foreign_model, objects, value;
      foreign_model = params.foreign_model;
      objects = this.model_object.get(params.key);
      if (!(objects != null)) {
        objects = new Backbone.Collection;
      }
      objects.add(object);
      value = {};
      value[params.key] = objects;
      return this.model_object.set(value);
    }
  });
  Porkepic.HasOne = function(model_object, foreign_model, key, foreign_key) {
    var hasOne, object, object_id, relation;
    this.model_object = model_object;
    relation = {
      foreign_model: foreign_model,
      key: key,
      foreign_key: foreign_key,
      store: Porkepic.Stores.storeForModel(foreign_model)
    };
    object_id = model_object.get(key + "_id");
    if (!(object_id != null)) {
      return this;
    }
    object = relation.store.lookupOne(object_id);
    if (!(object != null)) {
      hasOne = this;
      relation.store.bind("add", function(object) {
        if (model_object.get(relation.key + "_id") === object.id) {
          return hasOne.createHasOneRelation(relation, object);
        }
      });
    } else {
      this.createHasOneRelation(relation, object);
    }
    this[key + "Relation"] = relation;
    return this;
  };
  _.extend(Porkepic.HasOne.prototype, Backbone.Events, {
    createHasOneRelation: function(relation, object) {
      var fRel, value;
      value = {};
      value[relation.key] = object;
      this.model_object.set(value);
      fRel = object[relation.key + "RelationHM"];
      if ((fRel != null) && fRel.key === relation.foreign_key && (object.addInMany != null)) {
        object.addInMany(this.model_object, fRel);
      }
      if (relation.foreign_key != null) {
        value = {};
        value[relation.foreign_key] = this.model_object;
        return object.set(value);
      }
    }
  });
  Porkepic.HasMany = function(model_object, foreign_model, key, foreign_key) {
    var relation;
    relation = {
      key: key,
      foreign_model: foreign_model,
      foreign_key: foreign_key
    };
    this[foreign_key + "RelationHM"] = relation;
    this.model_object = model_object;
    return this;
  };
  _.extend(Porkepic.HasMany.prototype, Backbone.Events, {
    addInMany: function(object, params) {
      var foreign_model, objects, value;
      foreign_model = params.foreign_model;
      objects = this.model_object.get(params.key);
      if (!(objects != null)) {
        objects = new Backbone.Collection;
      }
      objects.add(object);
      value = {};
      value[params.key] = objects;
      return this.model_object.set(value);
    }
  });
}).call(this);
