package smalluniverse;

import dodrugs.Injector;
import smalluniverse.SUServerSideComponent;
import smalluniverse.SUMacro.jsx;
import monsoon.Request;
import monsoon.Response;
using StringTools;
using tink.CoreApi;

class SmallUniverse {

	static var template:String = '<html>
		<head>
			<script src="react-test.bundle.js" async></script>
		</head>
		<body>
			<div id="small-universe-app">{BODY}</div>
			<script id="small-universe-props" type="text/json" data-page="{PAGE}">{PROPS}</script>
		</body>
	</html>';

	public var app:Monsoon;
	public var injector:Injector<"smalluniverse">;

	public function new(monsoonApp:Monsoon, injector:Injector<"smalluniverse">) {
		this.app = monsoonApp;
		this.injector = injector;
	}

	// TODO: Figure out a more elegant way of passing in the class and having the injector provide it.
	// Either use macros, or have Injector.getter(Class) -> returns a lazy function.
	public function addPage(route:String, pageFn:Void->UniversalPage<Dynamic,Dynamic,Dynamic>) {
		app.use(route, function (req:Request, res:Response) {
			var page = pageFn();
			page.route(req, res);
		});
	}

	static function getArgsFromBody(req:Request):Promise<Array<Dynamic>> {
		switch req.body {
			case Plain(source):
				return source.all().map(function (outcome) {
					var bytes = outcome.sure();
					var str = bytes.toString();
					var args:Array<Dynamic> = haxe.Unserializer.run(str);
					return args;
				});
			case _:
				throw 'Multipart requests are not supported in SmallUniverse yet';
		}
	}
}
