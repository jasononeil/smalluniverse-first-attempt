package smalluniverse;

using tink.CoreApi;

@:autoBuild(smalluniverse.SUComponentBuilder.buildUniversalComponent())
class UniversalPage<TProps, TState, TRefs> extends UniversalComponent<TProps, TState, TRefs> {
	/**
		Retrieve the properties for this page.

		This will be executed server-side, and should return a `tink.core.Promise`.
		Note: if you don't need asynchronous loading, returning the props synchronously will work thanks to the `Promise.ofData()` automatic cast.

		If a page does not implement its own get method, then a Promise containing a null value will be returned, representing that there are no props to display.
	**/
	public function get():Promise<TProps> {
		return Future.sync(null);
	}
}
