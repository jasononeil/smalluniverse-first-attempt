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
			<script id="small-universe-props" type="text/json">{PROPS}</script>
		</body>
	</html>';

	var app:Monsoon;
	var injector:Injector<"smalluniverse">;

	public function new(monsoonApp:Monsoon, injector:Injector<"smalluniverse">) {
		this.app = monsoonApp;
		this.injector = injector;
	}

	public function addPage(route:String, page:Class<UniversalPage<Dynamic,Dynamic,Dynamic>>) {
		app.get(route, function (req:Request, res:Response) {
			var page = injector.get(HelloPage);
			page.renderToString().next(function (appHtml) {
				// TODO: switch to tink_JSON
				var propsJson = haxe.Json.stringify(page.props);
				var html = template.replace('{BODY}', appHtml).replace('{PROPS}', propsJson);
				res.send(html);
				return appHtml;
			});
		});
	}
}
