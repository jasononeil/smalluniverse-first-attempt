package smalluniverse;

#if server
import tink.http.Response;
import tink.http.Header;
import tink.Json;
import haxe.PosInfos;
#elseif client
import js.Browser.document;
#end
using tink.CoreApi;

abstract SmallUniverse(UniversalPage<Dynamic,Dynamic,Dynamic>) {
	#if client
	public static function hydrate(pageCls:Class<Dynamic>): Promise<Noise> {
		var propsElem = document.getElementById('small-universe-props');
		var propsJson = propsElem.innerText;
		var page = Type.createInstance(pageCls, []);
		try {
			page.props = page.deserializeProps(propsJson);
		} catch (e: Dynamic) {
			trace('Failed to deserialize props', e);
			return new Error('Failed to deserialize props: $e');
		}
		return Future.async(function (done: Outcome<Noise, Error>->Void) {
			try {
				page.doClientRender(function () done(Success(Noise)));
			} catch (e: Dynamic) {
				trace('Failed to render page', e);
				done(Failure(new Error('Failed to render page: $e')));
			}
		});
	}
	#end

	#if server
	static var logs: Array<Array<String>> = [];
	public static function captureTraces() {
		haxe.Log.trace = function(v:Dynamic, ?pos:PosInfos) {
			var arr:Array<Dynamic> = [];
			arr.push('%c${pos.className}.${pos.methodName}():${pos.lineNumber}');
			arr.push("background: #222; color: white");
			arr.push(v);
			if (pos.customParams != null) {
				for (arg in pos.customParams) {
					arr.push(arg);
				}
			}
			var stringArray = arr.map(function (val) return haxe.Json.stringify(val));
			#if hxnodejs
			js.Node.console.log('%c${pos.className}.${pos.methodName}():${pos.lineNumber}', v, pos.customParams);
			#end
			logs.push(stringArray);
		};
	}

	static function getMessages(): Null<Array<Array<String>>> {
		if (logs.length > 0) {
			var toReturn = logs;
			logs = [];
			return toReturn;
		}
		return null;
	}

	/**
	The template to use for rendering basic page markup server side.

	The default should be sufficient for most use cases.

	Use `{BODY}`, `{HEAD}`, `{PAGE}`, `{PROPS}` and `{LOGS}` strings as insertion points.
	**/
	static var template:String = '<html>
		<head>{HEAD}</head>
		<body>
			<div id="small-universe-app">{BODY}</div>
			<script id="small-universe-props" type="text/json" data-page="{PAGE}">{PROPS}</script>
			{LOGS}
		</body>
	</html>';

	public function new(pageToUse:LazyUniversalPage, context: SmallUniverseContext) {
		var page = pageToUse();
		@:privateAccess page.context = context;
		this = page;
	}

	@:to
	public function render(): Promise<OutgoingResponse> {
		return this.context.parse().next(function (fields): Promise<OutgoingResponse> {
			var actionJson = null;
			if (this.context.hasParam('action')) {
				actionJson = this.context.param('action');
			} else if (fields.length > 0) {
				// TODO: understand why context.parse() is treating the JSON as key/value pairs, and see if we can clean up this hack.
				var json = "";
				for (field in fields) {
					json += field.name;
					if (field.value != null && field.value != "") {
						json += "=" + field.value;
					}
				}
				var request: {action: String} = haxe.Json.parse(json);
				actionJson = request.action;
			}

			if (actionJson != null) {
				return processAction(actionJson).next(function (result): Promise<OutgoingResponse> switch result {
					case Redirect(url):
						return prepareRedirect(this, url);
					case Done:
						// If it's JSON, we return the props directly.
						// If it's HTML, we want to redirect, so that if they refresh the page it doesn't repeat the action.
						return isApiRequest(this) ? prepareJsonResponse(this) : prepareRedirectToSamePage(this);
				});
			}
			return renderPage();
		});
	}

	function processAction(actionJson: String): Promise<BackendApiResult> {
		try {
			var action = @:privateAccess this.deserializeAction(actionJson);
			return this.backendApi.processAction(this.context, action);
		} catch (e: Dynamic) {
			trace('Failed to deserialise the JSON for the requested JSON', e);
			return new Error('Failed to deserialise the JSON for the requested JSON: $e');
		}
	}

	function isApiRequest(): Bool {
		return !this.context.accepts('text/html');
	}

	function prepareRedirect(url: String): OutgoingResponse {
		return isApiRequest() ? renderJsonRedirect(url) : doHttpRedirect(url);
	}

	function prepareRedirectToSamePage(): OutgoingResponse {
		// Create a copy of the URL, except with the `action=` parameter missing.
		var url: tink.Url = this.context.header.url,
			currentQuery = url.query.toMap(),
			newQuery = tink.url.Query.build();
		for (key in currentQuery.keys()) {
			if (key != 'action') {
				newQuery.add(key, currentQuery[key]);
			}
		}
		var queryString = newQuery.toString();
		var redirectUrl = url.resolve(tink.Url.make({
			path: url.path,
			query: (queryString != "") ? queryString : null,
			hash: url.hash
		})).toString();
		return prepareRedirect(redirectUrl);
	}

	function renderJsonRedirect(url: String): OutgoingResponse {
		var instructions: SUApiResponseInstructions = {
			__smallUniverse: {
				redirect: url,
				messages: getMessages()
			}
		};
		return new OutgoingResponse(
			header(200, 'application/json'),
			Json.stringify(instructions)
		);
	}

	function doHttpRedirect(url: String): OutgoingResponse {
		return new OutgoingResponse(
			new ResponseHeader(TemporaryRedirect, 307, [
				new HeaderField('Location', url)
			]),
			""
		);
	}

	function renderPage(): Promise<OutgoingResponse> {
		if (isApiRequest()) {
			return prepareJsonResponse();
		} else {
			return prepareHtmlResponse();
		}
	}

	function prepareJsonResponse(): Promise<OutgoingResponse> {
		return this.getPageJson().next(function (pageJson) {
			var logs = getMessages();
			if (logs != null) {
				// Please note we have to use haxe.Json instead of tink.Json.
				// The reason is that tink.Json will ignore any fields it isn't expecting when parsing, and we want to preserve all data.
				var responseData: SUApiResponseInstructions = haxe.Json.parse(pageJson);
				responseData.__smallUniverse = {
					messages: logs
				};
				pageJson = haxe.Json.stringify(responseData);
			}
			return new OutgoingResponse(
				header(200, 'application/json'),
				pageJson
			);
		});
	}

	static inline function header(status: Int, contentType: String) {
		return new ResponseHeader(status, status, [new HeaderField('Content-Type', contentType)]);
	}

	function prepareHtmlResponse(): Promise<OutgoingResponse> {
		return this.getPageHtml().next(function (pageHtml) {
			var propsJson = @:privateAccess this.serializeProps(this.props);
			var pageName = Type.getClassName(Type.getClass(this));
			var head = this.head.renderToString();

			var logScripts = prepareLogScript(getMessages());

			var html = SmallUniverse.template;
			html = StringTools.replace(html, '{BODY}', pageHtml);
			html = StringTools.replace(html, '{HEAD}', head);
			html = StringTools.replace(html, '{PAGE}', pageName);
			html = StringTools.replace(html, '{PROPS}', propsJson);
			html = StringTools.replace(html, '{LOGS}', logScripts);

			return new OutgoingResponse(
				header(200, 'text/html'),
				html
			);
		});
	}

	function prepareLogScript(logs: Array<Array<String>>) {
		if (logs == null) {
			return "";
		}
		var script = '\n<script>';
		for (log in logs) {
			var args = log.map(function (arg) {
				// When parsing this to the browser, the `\` escaping is meant for the JSON parser, not the JS parser.
				// Which means we have to double escape, replacing `\"` with `\\"`.
				var backslash = '\\';
				var escapedArg = StringTools.replace(arg, backslash, backslash+backslash);
				return 'JSON.parse(\'$escapedArg\')';
			}).join(", ");
			script += '\nconsole.log($args);';
		}
		script += '\n</script>';
		return script;
	}
	#end
}
