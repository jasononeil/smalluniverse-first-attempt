package smalluniverse;

#if client
	import js.Browser.window;
	import js.html.*;
#end
import smalluniverse.UniversalComponent;
using tink.CoreApi;

@:autoBuild(smalluniverse.SUPageBuilder.buildUniversalPage())
class UniversalPage<TProps, TState, TRefs> extends UniversalComponent<TProps, TState, TRefs> {
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
			.next(function (res:Response):Promise<T> {
				return Future.ofJsPromise(res.json());
			});
	}
	#end
}
