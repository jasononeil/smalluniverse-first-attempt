package smalluniverse;

import tink.CoreApi;

enum BackendApiResult {
	Done;
	Redirect(url:String);
}

/**
A backend Api allows you to wire your page up to a backend server.

This allows you to interact with a database, file system, external APIs, or any other backend technology.

A backend API must provide a way to `get()` the current properties for a given page.
This will be called when a page is first loaded, and also after an action has been triggered, allowing a page to update in response to an action.

The backend API must also provide a `processAction()` function, which is used to apply changes to the backend.
For example it might create a new database record in response to an action, or call a 3rd party API in response to an action.

All of your "read" operations should happen in `get()`.
All of your "write" operations should happen in `processAction()`.
**/
@:autoBuild(smalluniverse.SUBuildMacro.buildBackendApi())
interface BackendApi<TAction, TProps> {
	/**
	Load the current props for a page.

	This will be called when the page is initially rendered, and any time a re-render is required.
	This includes after an action has been triggered - we will re-fetch the entire state and send the result to the client so it can re-render.
	This ensures that the client is regularly given a new version of the "canonical" state, as the server sees it.

	If you would like the client side to update it's properties before the server returns its result, you can use a `FrontendApi`.
	**/
	public function get(context:SmallUniverseContext):Promise<TProps>;

	/**
	Execute an action on the server.

	Unlike `FrontendApi.processAction`, this method should make sure the action executes properly on the server, interacting with the DB, FileSystem or any other way of storing your app data.

	Please note this function does not require you to return new properties.
	After actions have been processed by the server, a new `get()` call will be made and will return updated properties to the client.
	This allows each `processAction` call to focus purely on applying the changes, and not worry about fetching and mutating state objects to be rendered.
	**/
	public function processAction(context:SmallUniverseContext, action:TAction):Promise<BackendApiResult>;
}
