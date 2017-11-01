package smalluniverse;

#if client
	import react.ReactDOM;
	import react.React;
	import js.html.FormData;
	import js.Browser.window;
	import js.Browser.document;
	import js.Browser.console;
	import js.html.*;
#elseif server
#end
import smalluniverse.UniversalComponent;
import tink.Json;
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
			return this.callServerAction(None).next(function (_) return this.props);
		#end
	}

	#if server
	/**
	Render the HTML for this Universal page.

	This will fetch the current props using `get()`, call the `componentWillMount()` lifecycle method, and then render to a String.

	Please note this HTML is for the component, not for the full page (including `<head>`, `<title>` etc).
	**/
	public function getPageHtml(): Promise<String> {
		return this.get().next(function (props) {
			this.props = props;
			this.componentWillMount();
			return this.render().renderToString();
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

	/**
		TODO:
	**/
	public static function startClientRendering(cls:Class<Dynamic>, propsJson:String) {
		var page = Type.createInstance(cls, []);
		page.props = page.deserializeProps(propsJson);
		page.doClientRender();
	}

	function doClientRender<TProps>() {
		#if client
		var pageCls:Class<react.ReactComponent.ReactComponent> = cast Type.getClass(this),
			pageElm = React.createElement(pageCls, this.props),
			container = document.getElementById('small-universe-app');
		// Note: React is smart enough to maintain our instance and not recreate a new one,
		// even though we are passing in the class and not the instance.

		ReactDOM.hydrate(pageElm, container);
		#end
	}

	/**
		TODO
	**/
	function callServerAction(action:Option<TAction>):Promise<Noise> {
		var request = switch action {
			case Some(a):
				new Request(window.location.href, {
					method: 'POST',
					headers: new Headers({
						'x-small-universe-api': '1'
					}),
					body: serializeAction(a)
				});
			case None:
				new Request(window.location.href, {
					method: 'GET',
					headers: new Headers({
						'x-small-universe-api': '1'
					})
				});
		};

		return Future
			.ofJsPromise(window.fetch(request))
			.asPromise()
			.next(function (res:Response):Promise<String> {
				var responseText = Future.ofJsPromise(res.text());
				if (res.status != 200) {
					// The text() promise will succeed even if the response is not a 200.
					// Take a Success() and map it to a Failure()
					return responseText.map(function (outcome) return switch outcome {
						case Success(txt):
							var err;
							try {
								var errDetails:{code:Int, message:String} = Json.parse(txt);
								err = new Error(errDetails.code, errDetails.message);
							} catch (e:Dynamic) {
								// If the message wasn't a JSON response with the error, just use the message and HTTP code for the new error.
								err = new Error(res.status, txt);
							}
							Failure(err);
						default: outcome;
					});
				};
				return responseText;
			})
			.next(function (serializedResponse:String):Promise<Option<String>> {
				try {
					var response:{
						__smallUniverse:{
							redirect:Null<String>,
							messages:Array<Array<String>>
						}
					} = tink.Json.parse(serializedResponse);
					for (messageValues in response.__smallUniverse.messages) {
						var console = js.Browser.console,
							log = console.log,
							args:Array<Dynamic> = [for (arg in messageValues) haxe.Json.parse(arg)];
						untyped log.apply(console, args);
					}
					if (response.__smallUniverse.redirect != null) {
						js.Browser.window.location.assign(response.__smallUniverse.redirect);
						// Fulfill the promise, but do not execute a render.
						return None;
						// reject the promise?
					}
				} catch (e:Dynamic) {
					// Ignore errors - they're probably just complaining if the field was missing.
				}
				return Some(serializedResponse);
			})
			.next(function (responseToRender:Option<String>):Promise<Noise> {
				switch responseToRender {
					case Some(serializedResponse):
						this.props = this.deserializeProps(serializedResponse);
						doClientRender();
						return Noise;
					case None:
						return Noise;
				}
			});
	}
	#end
}
