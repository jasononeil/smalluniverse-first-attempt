package smalluniverse;

import smalluniverse.SUServerSideComponent;
import smalluniverse.SUMacro.jsx;
import smalluniverse.LazyUniversalPage;
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

	public function new(monsoonApp:Monsoon) {
		this.app = monsoonApp;
	}

	public function addPage(route:String, pageToUse:LazyUniversalPage) {
		app.use(route, function (req:Request, res:Response) {
			var page = pageToUse();
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
