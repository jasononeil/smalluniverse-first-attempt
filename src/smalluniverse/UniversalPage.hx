package smalluniverse;

#if client
	import react.ReactDOM;
	import react.React;
	import js.html.Element;
	import js.Browser.window;
	import js.html.*;
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
	#end

	#if client
	/**
		TODO
	**/
	public function callServerApi<T>(action:String, parameters:String):Promise<T> {
		var l = window.location;
		var query = (l.search != "") ? '${l.search}&' : '?';
		var url = l.protocol + '//' + l.host + l.pathname + query + 'small-universe-action=$action';
		var request = new Request(url, {
			method: 'POST',
			headers: new Headers({
				'Content-Type': 'text/json',
				'x-small-universe-api': '1'
			}),
			body: parameters
		});

		return Future
			.ofJsPromise(window.fetch(request))
			.asPromise()
			.next(function (res:Response):Promise<String> {
				return Future.ofJsPromise(res.text());
			})
			.next(function (serializedResponse:String):Promise<T> {
				var data:{props:TProps, returnValue:T} = haxe.Unserializer.run(serializedResponse);
				renderPage(Type.getClass(this), data.props, ReactDOM.findDOMNode(this).parentElement);
				this.props = data.props;
				this.forceUpdate();
				return data.returnValue;
			});
	}
	#end
}
