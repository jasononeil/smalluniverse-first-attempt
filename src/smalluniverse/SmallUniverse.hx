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

	static function renderPagePropsJson(page:UniversalPage<Dynamic,Dynamic,Dynamic>, res:Response) {
		page.get().handle(function (outcome) {
			var props = outcome.sure();
			var responseData = {
				props: props
			};
			var serializedProps = haxe.Serializer.run(responseData);
			res.send(serializedProps);
		});
	}

	static function renderPageToHtml(page:UniversalPage<Dynamic,Dynamic,Dynamic>, res:Response) {
		page.renderToString().handle(function (outcome) {
			var appHtml = outcome.sure();
			var pageName = Type.getClassName(Type.getClass(page));
			// TODO: switch to tink_JSON
			var propsJson = haxe.Serializer.run(page.props);
			var html = template
				.replace('{BODY}', appHtml)
				.replace('{PAGE}', pageName)
				.replace('{PROPS}', propsJson);
			res.send(html);
		});
	}

	static function executeActionAndRenderJson(page:UniversalPage<Dynamic,Dynamic,Dynamic>, action:String, req:Request, res:Response) {
		// TODO: replace these with macro calls so we're not using Reflect or haxe.Serializer
		getArgsFromBody(req)
			.next(function (args):Promise<Any> {
				return Reflect.callMethod(page, Reflect.field(page, action), args);
			})
			.next(function (val) {
				return page.get().next(function (props) {
					return {
						props: props,
						returnValue: val
					}
				});
			})
			.handle(function (outcome) {
				var data = outcome.sure();
				var serializedData = haxe.Serializer.run(data);
				res.send(serializedData);
			});
	}

	static function executeActionAndSetRedirect(page:UniversalPage<Dynamic,Dynamic,Dynamic>, action:String, req:Request, res:Response) {
		// TODO: replace these with macro calls so we're not using Reflect
		getArgsFromBody(req)
			.next(function (args):Promise<Any> {
				return Reflect.callMethod(page, Reflect.field(page, action), args);
			})
			.handle(function (outcome) {
				outcome.sure();
				var redirectUrl = req.url;
				res.redirect(redirectUrl);
			});
	}
}
