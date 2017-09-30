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
	import monsoon.Request;
	import monsoon.Response;
#end
import smalluniverse.UniversalComponent;
import tink.Json;
using tink.CoreApi;

@:autoBuild(smalluniverse.SUBuildMacro.buildUniversalPage())
class UniversalPage<TAction, TParams, TProps, TState, TRefs> extends UniversalComponent<TProps, TState, TRefs> {

	/**
		The template to use for rendering basic page markup server side.

		The default should be sufficient for most use cases.

		Use `{BODY}`, `{HEAD}`, `{PAGE}` and `{PROPS}` literals as insertion points.
	**/
	static var template:String = '<html>
		<head>{HEAD}</head>
		<body>
			<div id="small-universe-app">{BODY}</div>
			<script id="small-universe-props" type="text/json" data-page="{PAGE}">{PROPS}</script>
		</body>
	</html>';

	public var head(default, null):UniversalPageHead;

	#if server
	/**
	TODO
	**/
	public var backendApi:BackendApi<TAction, TParams, TProps>;

	/**
		An object containing the server-side request information.

		The `request.params` will be correctly typed as `TParams`.
		This is set just before `route()` is called.

		Please note this is currently only available on the server.
	**/
	public var request(default, null):Request<TParams>;
	#end

	public function new(backendApi:BackendApi<TAction, TParams, TProps>) {
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
			return this.backendApi.get(this.request);
		#elseif client
			return this.callServerAction(None).next(function (_) return this.props);
		#end
	}

	#if server
	/**
		TODO
	**/
	public function route(req:Request<TParams>, res:Response):Void {
		var isApiRequest = req.header.byName('x-small-universe-api').isSuccess();
		var contentType = isApiRequest ? 'application/json' : 'text/html';
		res.set('content-type', contentType);

		var propsPromise:Promise<Either<TProps,String>> = switch req.method {
			case GET:
				this.backendApi.get(req).next(function (p) return Left(p));
			case POST:
				// Execute the action, then fetch the props.
				getBodyString(req)
					.next(function (json) return deserializeAction(json))
					.next(function (action) return this.backendApi.processAction(req, action))
					.next(function (result) return switch result {
						case Done: this.backendApi.get(req).next(function (p) return Left(p));
						case Redirect(url): Right(url);
					});
			case _:
				var err = new Error('Expected method to be GET or POST, was' + req.method);
				Future.sync(Failure(err));
		}

		propsPromise.handle(function (outcome) {
			switch outcome {
				case Success(Left(props)):
					res.status(200);
					if (isApiRequest) {
						var json = serializeProps(props);
						res.send(json);
					} else {
						renderFullHtml(res, props);
					}
				case Success(Right(url)):
					if (isApiRequest) {
						res.status(200);
						var json = Json.stringify({
							__smallUniverse: {
								redirect: url
							}
						});
						res.send(json);
					} else {
						res.redirect(url);
					}
				case Failure(err):
					res.status(err.code);
					if (isApiRequest) {
						// TODO: get tink_json to serialize an Error directly.
						var errorSummary = {
							code: (err.code:Int),
							message: err.message,
						};
						var json = Json.stringify(errorSummary);
						res.send(json);
					} else {
						// TODO: have a way to set a custom error handler.
						var html = '<pre>${err.toString()}</pre>';
						res.send(html);
					}
			}
		});
	}

	function renderFullHtml(res:Response, props:TProps) {
		this.props = props;
		this.componentWillMount();
		var appHtml = this.render().renderToString();
		var propsJson = serializeProps(props);
		var pageName = Type.getClassName(Type.getClass(this));
		var head = this.head.renderToString();
		var html = smalluniverse.UniversalPage.template;
		html = StringTools.replace(html, '{BODY}', appHtml);
		html = StringTools.replace(html, '{HEAD}', head);
		html = StringTools.replace(html, '{PAGE}', pageName);
		html = StringTools.replace(html, '{PROPS}', propsJson);
		res.send(html);
	}

	static function getBodyString<T>(req:Request<T>):Promise<String> {
		switch req.body {
			case Plain(source):
				return source.all().asPromise().next(function (bytes) return bytes.toString());
			case Parsed(structuredBody):
				for (part in structuredBody) {
					switch part.value {
						case Value(val):
							if (part.name == 'action') {
								return val;
							}
							// TODO: decide if there's any reason to check for other values.
						case File(handle):
							// TODO: decide if we want to handle file uploads here.
					}
				}
				return new Error('Expected response body to either be JSON, or have an `action` parameter containing the JSON.');
		}
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
