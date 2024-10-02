if get(g:, "erde_bootstrap", v:true) == v:true
	lua erde_bootstrap = require("erde-bootstrap")
	lua erde_bootstrap._plugin_setup()
endif
