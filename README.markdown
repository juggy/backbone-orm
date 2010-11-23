Example in coffeescript:

  this.Foreman = Backbone.Model.extend
  	initialize: -> 
  	# will add a projects attribute to the foreman and a foreman attribute to the project
  		_.extend(this, new Porkepic.HasMany(this, Project, "projects", "foreman"))
  	# will add a worksheets attributes to the foreman
  		_.extend(this, new Porkepic.EmbeddedInMany(this, WorkSheet, "worksheets", "foreman"))
	
  	url : -> "/users/" + this.id