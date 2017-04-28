package smalluniverse;

import smalluniverse.SUServerSideComponent;
import smalluniverse.UniversalComponent;
using tink.CoreApi;

@:autoBuild(smalluniverse.SUPageBuilder.buildUniversalPage())
class UniversalPage<TProps, TState, TRefs> extends UniversalComponent<TProps, TState, TRefs> {
	public function new() {
		// A page should not receive props through a constructor, but through it's set method.
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

	/**
		TODO
	**/
	#if server
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
}
