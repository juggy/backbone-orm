"https://github.com/PaulUithol/Backbone-relational": https://github.com/PaulUithol/Backbone-relational looks like a cleaner approach. It relies on the same basic stuff, a model store to keep track globally of model instances. 

Example in coffeescript:

	this.Foreman = Backbone.Model.extend
  		initialize: -> 
  			# will add a projects attribute to the foreman and a foreman attribute to the project
  			_.extend(this, new Porkepic.HasMany(this, Project, "projects", "foreman"))
  			# will add a worksheets attributes to the foreman
  			_.extend(this, new Porkepic.EmbeddedInMany(this, WorkSheet, "worksheets", "foreman"))
	
  		url : -> "/users/" + this.id