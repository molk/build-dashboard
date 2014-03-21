#module definig the BuilInfoSource class

http = require("http")
EventEmitter = require('events').EventEmitter

class CiBuildInfoSource extends EventEmitter
	constructor: (job) ->
		@job = job #"dashboard_test_script"
	start: ->
	stop: ->

#curl -X POST -d '{"result": "SUCCESS"}' -H "Content-Type: application/json" http://localhost:3000/ciBuildInfo/dashboard_test_script
class ExpressPushCiBuildInfoSource extends CiBuildInfoSource
	constructor: (job, app) ->
		super(job)
		@app = app
		@pathPrefix = "/ciBuildInfo/"

	start: ->
		@app.post(@pathPrefix + @job, @_handleRequest)
	stop: ->
		routes = @app.routes.post
		routes.splice(i, 1) for i in (i for route, i in routes when route.path==@pathPrefix + @job)

	_handleRequest: (req, res) =>
		#TODO: why does this method have to maintain the object context and the others dont? "@emit" is undefined if we dont use "=>""
		@emit("ciBuildInfo", req.body)
		res.send(200)

class HttpPullCiBuildInfoSource extends CiBuildInfoSource
	constructor: (job) ->
		super(job)
		@connectionString = "http://ekis:secret_pw@corevm01:8080/job/#{@job}/lastBuild/api/json"
		@delay = 10000
		@_timerId = null

	start: ->
		@timerId = setInterval(@_retrieve, @delay) 
	stop: ->
		if (@timerId) then clearInterval(@timerid) else console.log "no timer has been started!"

	_retrieve: =>
		http.get(@connectionString, (hudsonRes) =>
			# if hudsonres.statusCode != 20x do something
			if (hudsonRes.statusCode != 200)
				console.log("connection error: " + hudsonRes.statusCode)
				#TODO: errorhandling: throw "err"?
			else
				jsonData = ""
				hudsonRes.on("data", (chunk) =>
					jsonData += chunk
				)
				hudsonRes.on("end", => 
					@emit("ciBuildInfo", JSON.parse(jsonData))
				)
		).on('error', (e) =>
				console.log("Got error: " + e.message);
		)

module.exports.CiBuildInfoSource = CiBuildInfoSource
module.exports.ExpressPushCiBuildInfoSource = ExpressPushCiBuildInfoSource
module.exports.HttpPullCiBuildInfoSource = HttpPullCiBuildInfoSource
