package smalluniverse;

#if client
import react.ReactDOM;
import react.React;
import js.Browser.window;
import js.Browser.document;
import js.html.*;
#elseif server
#end
import haxe.ds.Option;
import smalluniverse.UniversalComponent;

using tink.CoreApi;

@:autoBuild(smalluniverse.SUBuildMacro.buildUniversalPage())
class UniversalPage<TAction, TProps, TState> extends UniversalComponent<TProps, TState> {
	public var head(default, null):UniversalPageHead;
	#if server
	/**
		TODO
	**/
	public var backendApi:BackendApi<TAction, TProps>;

	/**
		An object containing the server-side request information.

		Please note this is only available on the server.
	**/
	public var context(default, null):SmallUniverseContext;
	#end

	public function new(?backendApi:BackendApi<TAction, TProps>) {
		// A page should not receive props through a constructor, but through it's get() method.
		super();
		this.head = new UniversalPageHead();
		#if server
		this.backendApi = backendApi;
		#end
	}

	/**
		Retrieve the properties for this page.

		TODO: explain how this links with backend API.
	**/
	public function get():Promise<TProps> {
		#if server
		return this.backendApi.get(this.context);
		#elseif client
		return this.callServerAction(None).next(function(_) return this.props);
		#end
	}

	#if server
	/**
		Render the HTML for this Universal page.

		This will fetch the current props using `get()`, call the `componentWillMount()` lifecycle method, and then render to a String.

		Please note this HTML is for the component, not for the full page (including `<head>`, `<title>` etc).
	**/
	public function getPageHtml():Promise<String> {
		return this.get().next(function(props) {
			this.props = props;
			this.componentWillMount();
			return this.render().renderToString();
		});
	}

	public function getPageJson():Promise<String> {
		return this.get().next(function(props) {
			return this.serializeProps(props);
		});
	}
	#end

	function deserializeProps(json:String):TProps {
		return throw 'Assert: should be implemented by macro';
	}

	function serializeProps(props:TProps):String {
		return throw 'Assert: should be implemented by macro';
	}

	function deserializeAction(json:String):TAction {
		return throw 'Assert: should be implemented by macro';
	}

	function serializeAction(action:TAction):String {
		return throw 'Assert: should be implemented by macro';
	}

	#if client
	/**
		TODO:
	**/
	public function trigger(action:TAction):Promise<Noise> {
		return callServerAction(Some(action));
	}

	function doClientRender(?cb:Void->Void) {
		// Note: React is smart enough to maintain our instance and not recreate a new one,
		// even though we are passing in the class and not the instance.
		var pageCls:Class<react.ReactComponent.ReactComponent> = cast Type.getClass(this), pageElm = React.createElement(pageCls, this
			.props), container = document.getElementById('small-universe-app');
		if (container == null) {
			throw new Error('A container with ID small-universe-app was not found, aborting render');
		}
		this.head.syncHeadToDocument();
		ReactDOM.hydrate(pageElm, container, cb);
	}

	function callServerAction(action:Option<TAction>):Promise<Noise> {
		var request = getRequestForAction(action);
		return fetchRequest(request).next(getResponseText).next(handleResponseSpecialInstructions).next(rerenderUsingUpdatedJson);
	}

	function getRequestForAction(action:Option<TAction>):Request {
		return switch action {
			case Some(a):
				var body = serializeAction(a);
				new Request(window.location.href, {
					method: 'POST',
					headers: new Headers({
						'Accept': 'application/json',
						'Content-Type': 'application/json',
					}),
					body: body
				});
			case None:
				new Request(window.location.href, {
					method: 'GET',
					headers: new Headers({
						'Accept': 'application/json',
					})
				});
		}
	}

	function fetchRequest(req:Request):Promise<Response> {
		return Future.ofJsPromise(window.fetch(req)).asPromise();
	}

	/** Check the status of the response and return a Promise for the resulting text content of the response. **/
	function getResponseText(res:Response):Promise<String> {
		var responseText = Future.ofJsPromise(res.text());
		if (res.status != 200) {
			// The text() promise will succeed even if the response is not a 200.
			// Take a Success() and map it to a Failure()
			return responseText.map(function(outcome) return switch outcome {
				case Success(txt): Failure(new Error(res.status, txt));
				default: outcome;
			});
		};
		return responseText;
	}

	/** Handle special instructions (traces and redirects) that were left in the __smallUniverse property of the returned JSON. **/
	function handleResponseSpecialInstructions(serializedResponse:String):Outcome<Option<String>, Error> {
		var response:SUApiResponseInstructions = null;
		try {
			response = tink.Json.parse(serializedResponse);
		} catch (err:Error) {
			return Failure(err);
		}
		var instructions = response.__smallUniverse;
		if (instructions != null) {
			if (instructions.messages != null) {
				for (messageValues in instructions.messages) {
					var args:Array<Dynamic> = [
						// For each arg, try to parse as JSON, but fall back to a String if it isn't valid JSON.
						for (arg in messageValues)
							try haxe.Json.parse(arg) catch (e:Dynamic) arg
					];
					logToConsole(args);
				}
			}
			if (instructions.redirect != null) {
				redirectWindow(instructions.redirect);
				// Fulfill the promise, but do not execute a render.
				return Success(None);
			}
		}
		return Success(Some(serializedResponse));
	}

	function logToConsole(values:Array<Dynamic>) {
		var console = js.Browser.console, log = console.log;
		untyped log.apply(console, values);
	}

	function redirectWindow(newUrl:String) {
		js.Browser.window.location.assign(newUrl);
	}

	function rerenderUsingUpdatedJson(responseToRender:Option<String>):Promise<Noise> {
		switch responseToRender {
			case Some(serializedResponse):
				this.props = this.deserializeProps(serializedResponse);
				return Future.async(function(done) {
					doClientRender(function() done(Noise));
				});
			case None:
				return Noise;
		}
	}
	#end
}
