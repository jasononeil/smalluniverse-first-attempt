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
		app.get(route, function (req:Request, res:Response) {
			var page = pageFn();
			page.renderToString().next(function (appHtml) {
				var pageName = Type.getClassName(Type.getClass(page));
				// TODO: switch to tink_JSON
				var propsJson = haxe.Json.stringify(page.props);
				var html = template
					.replace('{BODY}', appHtml)
					.replace('{PAGE}', pageName)
					.replace('{PROPS}', propsJson);
				res.send(html);
				return appHtml;
			});
		});
	}
}
