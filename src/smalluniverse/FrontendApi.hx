package smalluniverse;

import tink.CoreApi;
import haxe.ds.Option;

/**

	Page loaded...
	- get initial props from FrontendApi
		- frontEndApi.get(params, ?lastKnownProps):TProps;
		- render immediately
	- make request to BackendApi
		- backendApi.get(params):TProps;
		- return props
		- render over the top of the client side props.
	Action on page triggered
	- run action on FrontendApi and update local props
		- if a server side request is active, delay all reducer calls until that promise resolves, so we can use new props.
			- have a callback for onPropsBlocked(for:Int=0)
		- use a reducer `frontendApi.process(params, currentProps, action):TProps`
		- render new props immediately
	- debounce 50ms and post all buffered actions to BackendApi
		- when done, we receive new props. Render over the top of what's there.
		- resolve each action promise
	- return a Promise<Noise> that will resolve when the action has been triggered on the server
		- this way if there is a server error, we can handle it client side (or retry the action etc)
		- Also if there's a conflict (an action the client triggered was not possible by the time the server received it), they can trigger an error and handle it from there.

	Potential for race conditions:

	- Initial props: Props1
	- Action 1 runs, client updates -> Props2
	- Action 2 runs, client updates -> Props3
	- ServerApi1 call begins
	- Action 3 runs, client blocked
	- ServerApi1 call returns. Should match Props3.
	- Action 3 client updates -> Props4
	- ServerApi2 call begins
	- ServerApi2 call returns. Should match Props4.
**/

/**
	A FrontEnd API allows you to process actions that occur on a page immediately, even if a network connection is not available.

	This allows you to render pages and interact with pages (trigger actions) while offline.

	It also allows you to provide a more responsive experience, updating the properties of the page immediately in response to an action, while you wait for the server to process the action and return the new properties.
**/
interface FrontendApi<TParams, TProps, TAction> {
	/**
		Get the initial props when a page is loaded.

		If some properties were cached from a previous visit, they will be available in lastKnownProps.
		You can choose to use these, ignore them and generate fresh properties, or modify them slightly.
	**/
	public function get(params:TParams, lastKnownProps:Option<TProps>):TProps;

	/**
		Process the properties client side.

		This allows you to update the properties immediately while you wait for the server to process the action.
		Once we have posted the action to the server, and received new props back, we will use the returned props.
		Therefore the changes here only represent a temporary update to the properties, and will be overridden by the server properties eventually.

		This can be used for a few purposes:

		- To display a "loading" state while we wait for the server to complete.
		- To show the effect of an action immediately, and it will hopefully match the state returned from the server.
		- To allow the app to continue to function while offline, and reconcile later.
	**/
	public function processAction(params:TParams, currentProps:TProps, action:TAction):TProps;
}
