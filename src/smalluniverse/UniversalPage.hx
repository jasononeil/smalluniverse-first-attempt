package smalluniverse;

#if client
	import react.ReactDOM;
	import react.React;
	import tink.json.Serialized;
	import js.html.FormData;
	import js.Browser.window;
	import js.Browser.document;
	import js.html.*;
#elseif server
	import monsoon.Request;
	import monsoon.Response;
#end
import smalluniverse.UniversalComponent;
using tink.CoreApi;

@:autoBuild(smalluniverse.SUPageBuilder.buildUniversalPage())
class UniversalPage<TProps, TState, TRefs> extends UniversalComponent<TProps, TState, TRefs> {

	/**
	The template to use for rendering basic page markup server side.

	The default should be sufficient for most use cases.

	Use `{BODY}`, `{HEAD}`, `{PAGE}` and `{PROPS}` literals as insertion points.
	**/
	static var template:String = '<html>
		<head>{HEAD}</head>
		<body>
			<div id="small-universe-app">{BODY}</div>
			<script id="small-universe-props" type="text/json" data-page="{PAGE}">{PROPS}</script>
		</body>
	</html>';

	public var head(default, null):UniversalPageHead;

	public function new() {
		// A page should not receive props through a constructor, but through it's get() method.
		super();
		this.head = new UniversalPageHead();
	}
	/**
		Retrieve the properties for this page.

		This will be executed server-side, and should return a `tink.core.Promise`.
		Note: if you don't need asynchronous loading, returning the props synchronously will work thanks to the `Promise.ofData()` automatic cast.

		If a page does not implement its own get method, then a Promise containing a null value will be returned, representing that there are no props to display.
	**/
	public function get():Promise<TProps> {
		return Future.sync(Success(null));
	}

	#if server
	/**
		TODO
	**/
	public function renderToString():Promise<String> {
		return this.get().map(function (outcome:Outcome<TProps,Error>) {
			return switch outcome {
				case Success(props):
					this.props = props;
					return Success(this.render().renderToString());
				case Failure(err):
					return Failure(err);
			}
		});
	}

	/**
		TODO
	**/
	public function route(req:Request, res:Response):Void {
		var action = req.query.get('small-universe-action');
		res.error(404, 'Action '+action+' not found');
	}
	#end

	function deserializeProps(json:String):TProps {
		return throw 'Assert: should be implemented by macro';
	}

	#if client
	/**
		TODO:
	**/
	public static function startClientRendering() {
		var propsElem = document.getElementById('small-universe-props');
		var pageCls = Type.resolveClass(propsElem.getAttribute('data-page'));
		var propsJson = propsElem.innerText;
		var page = Type.createInstance(pageCls, []);
		page.props = page.deserializeProps(propsJson);
		page.doClientRender();
	}

	function doClientRender<TProps>() {
		#if client
		var pageCls:Class<react.ReactComponent.ReactComponent> = cast Type.getClass(this);
		// Note: React is smart enough to maintain our instance and not recreate a new one,
		// even though we are passing in the class and not the instance.
		ReactDOM.render(
			React.createElement(pageCls, this.props),
			document.getElementById('small-universe-app')
		);
		#end
	}

	/**
		TODO
	**/
	function callServerApi(action:String, ?formData:FormData):Promise<String> {
		if (formData == null) {
			formData = new FormData();
		}
		var l = window.location;
		var query = (l.search != "") ? '${l.search}&' : '?';
		var url = l.protocol + '//' + l.host + l.pathname + query + 'small-universe-action=$action';
		var request = new Request(url, {
			method: 'POST',
			headers: new Headers({
				'x-small-universe-api': '1'
			}),
			body: formData
		});

		return Future
			.ofJsPromise(window.fetch(request))
			.asPromise()
			.next(function (res:Response):Promise<String> {
				return Future.ofJsPromise(res.text());
			})
			.next(function (serializedResponse:String):Promise<String> {
				var data:{props:Serialized<{}>, ?returnValue:Serialized<{}>} =
					try {
						tink.Json.parse(serializedResponse);
					} catch (e:Dynamic) {
						trace('Error: $e');
						js.Lib.rethrow();
						null;
					}
				this.props = this.deserializeProps(data.props);
				doClientRender();
				var str:String = (action=='get') ? data.props : data.returnValue;
				return str;
			});
	}
	#end
}
