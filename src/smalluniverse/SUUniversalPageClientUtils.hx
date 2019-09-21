package smalluniverse;

#if client
import react.ReactDOM;
import react.React;
import js.Browser.window;
import js.Browser.document;
import js.html.*;
#end
import haxe.ds.Option;

using tink.CoreApi;

#if client
class SUUniversalPageClientUtils {
	public static function hydrate(pageCls:Class<UniversalPage<Dynamic, Dynamic, Dynamic>>):Promise<Noise> {
		var propsElem = document.getElementById('small-universe-props');
		var propsJson = propsElem.innerText;
		var page = Type.createInstance(pageCls, []);
		var props = null;
		try {
			props = @:privateAccess page.deserializeProps(propsJson);
		} catch (e:Dynamic) {
			trace('Failed to deserialize props', e);
			return new Error('Failed to deserialize props: $e');
		}
		return Future.async(function(done:Outcome<Noise, Error>->Void) {
			try {
				doClientRender(page, props, function() done(Success(Noise)));
			} catch (e:Dynamic) {
				trace('Failed to render page', e);
				done(Failure(new Error('Failed to render page: $e')));
			}
		});
	}

	public static function callServerApi<TAction>(page:UniversalPage<TAction, Dynamic, Dynamic>, action:Option<TAction>):Promise<Noise> {
		var serializedAction = action.map(a -> @:privateAccess page.serializeAction({action: a}));
		var request = getRequestForAction(serializedAction);
		return fetchRequest(request).next(getResponseText).next(handleResponseSpecialInstructions).next(rerenderUsingUpdatedJson.bind(page));
	}

	static function doClientRender(page:UniversalPage<Dynamic, Dynamic, Dynamic>, props:Dynamic, ?cb:Void->Void) {
		// Note: React is smart enough to maintain our instance and not recreate a new one,
		// even though we are passing in the class and not the instance.
		var pageCls:Class<react.ReactComponent.ReactComponent> = cast Type.getClass(page);
		var pageElm = React.createElement(pageCls, props);
		var container = document.getElementById('small-universe-app');
		if (container == null) {
			throw new Error('A container with ID small-universe-app was not found, aborting render');
		}
		page.head.syncHeadToDocument();
		ReactDOM.hydrate(pageElm, container, cb);
	}

	static function getRequestForAction(serializedAction:Option<String>):Request {
		return switch serializedAction {
			case Some(body):
				var body = body;
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

	static function fetchRequest(req:Request):Promise<Response> {
		return window.fetch(req).ofJsPromise();
	}

	/** Check the status of the response and return a Promise for the resulting text content of the response. **/
	static function getResponseText(res:Response):Promise<String> {
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
	static function handleResponseSpecialInstructions(serializedResponse:String):Outcome<Option<String>, Error> {
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

	static function logToConsole(values:Array<Dynamic>) {
		var console = js.Browser.console;
		var log = console.log;
		untyped log.apply(console, values);
	}

	static function redirectWindow(newUrl:String) {
		js.Browser.window.location.assign(newUrl);
	}

	static function rerenderUsingUpdatedJson(page:UniversalPage<Dynamic, Dynamic, Dynamic>, responseToRender:Option<String>):Promise<Noise> {
		switch responseToRender {
			case Some(serializedResponse):
				var props = @:privateAccess page.deserializeProps(serializedResponse);
				return Future.async(function(done) {
					doClientRender(page, props, function() done(Noise));
				});
			case None:
				return Noise;
		}
	}
}
#end
