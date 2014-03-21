#Module dependencies.
express = require("express")
routes = require("./routes")
http = require("http")
path = require("path")
io = require('socket.io')
bis = require('./lib/BuildInfoSource') # this is the important module!

#
# this is express boilerplate 
# see http://expressjs.com/guide.html
#

app = express()
server = http.createServer(app)
io = io.listen(server)

app.configure( ->
	app.set("port", process.env.PORT or 3000)
	app.set("views", __dirname + "/views")
	app.set("view engine", "jade")
	app.use(express.favicon())
	app.use(express.logger("dev"))
	app.use(express.bodyParser())
	app.use(express.methodOverride())
	app.use(express.cookieParser("your secret here"))
	app.use(express.session())
	app.use(app.router)
	app.use(require("less-middleware")(src: __dirname + "/public"))
	app.use(express.static(path.join(__dirname, "public")))
)

app.configure("development", ->
	app.use(express.errorHandler())
)

# index is just a blank page
app.get("/", routes.index)

# the "traffic light" view - see views/test.jade
app.get("/test", (req, res) ->
	res.render("test", {title: "test"})
)

app.get("/hallo", (req, res) ->
	res.render("hallo", {title: "Meine erste Seite!"})
)

# start the webserver
server.listen(app.get("port"), ->
	console.log("Express server listening on port " + app.get("port"))
)

#
# this was express boilerplate
#


#
# playgound
#
# we instantiate some BuildInfoSources
#

hpBis = new bis.HttpPullCiBuildInfoSource("dashboard_test_script")
epBis = new bis.ExpressPushCiBuildInfoSource("dashboard_test_script", app)

#hpBis.stop()
#epBis.stop()

sources = [hpBis, epBis]

source.start() for source in sources

#
# add some listeners
# TODO:listeners should be extracted into a module
#

addListerer = (callback) ->
	for source in sources
		do (source) ->
			source.on("ciBuildInfo", (ciBuildInfo) ->
				callback(ciBuildInfo)
			)

addListerer((buildInfo) ->
	console.log buildInfo
)

# websocket listener
io.sockets.on('connection', (socket) ->
	addListerer((ciBuildInfo) ->
		socket.emit("build", ciBuildInfo)
	)
)

