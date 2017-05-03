package smalluniverse;

#if client
	import react.ReactDOM;
	import react.React;
	import tink.json.Serialized;
	import js.html.FormData;
	import js.Browser.window;
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
		TODO: This works, but I would like to change it.  Please don't depend on it too heavily.
		TODO: this is static, and renderToString is an instance method. Should we standardise them?
	**/
	public static function renderPage<TProps>(pageCls:Class<UniversalPage<TProps,Dynamic,Dynamic>>, props:TProps, container) {
		#if client
		var cls:Class<react.ReactComponent.ReactComponent> = cast pageCls;
		ReactDOM.render(
			React.createElement(cls, props),
			container
		);
		#end
	}


	public function new() {
		// A page should not receive props through a constructor, but through it's get() method.
		super();
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
		TODO
	**/
	public function callServerApi(action:String, ?formData:FormData):Promise<String> {
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
				// TODO: check if this will create a new instance. Can I keep local state or will it be replaced?
				renderPage(Type.getClass(this), this.props, ReactDOM.findDOMNode(this).parentElement);
				var str:String = (action=='get') ? data.props : data.returnValue;
				return str;
			});
	}
	#end
}
