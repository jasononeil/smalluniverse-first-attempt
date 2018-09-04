package smalluniverse;

#if server
import tink.http.Response;
import tink.http.Header;
import tink.Json;
#elseif client
import js.Browser.document;
#end
using tink.CoreApi;

class SmallUniverse {
	#if client
	public static function hydrate(pageCls:Class<Dynamic>):Promise<Noise> {
		var propsElem = document.getElementById('small-universe-props');
		var propsJson = propsElem.innerText;
		var page = Type.createInstance(pageCls, []);
		try {
			page.props = page.deserializeProps(propsJson);
		} catch (e:Dynamic) {
			trace('Failed to deserialize props', e);
			return new Error('Failed to deserialize props: $e');
		}
		return Future.async(function(done:Outcome<Noise, Error>->Void) {
			try {
				page.doClientRender(function() done(Success(Noise)));
			} catch (e:Dynamic) {
				trace('Failed to render page', e);
				done(Failure(new Error('Failed to render page: $e')));
			}
		});
	}
	#end

	#if server
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

	public static function render(pageToUse:LazyUniversalPage, context:SmallUniverseContext, ?action:Any):Promise<OutgoingResponse> {
		var actionValue = (action != null) ? Some(action) : None;
		var page = pageToUse();
		@:privateAccess page.context = context;
		switch actionValue {
			case Some(action):
				return processAction(page, action).next(function(result):Promise<OutgoingResponse> switch result {
					case Redirect(url):
						return prepareRedirect(context, url);
					case Done:
						// If it's JSON, we return the props directly.
						// If it's HTML, we want to redirect, so that if they refresh the page it doesn't repeat the action.
						return isApiRequest(page.context) ? prepareJsonResponse(page) : prepareRedirectToSamePage(page.context);
				});
			case None:
				return renderPage(page);
		}
	}

	static function processAction<T>(page:UniversalPage<T, Dynamic, Dynamic>, action:T):Promise<BackendApiResult> {
		return page.backendApi.processAction(page.context, action);
	}

	static function prepareRedirect(context:SmallUniverseContext, url:String):OutgoingResponse {
		return isApiRequest(context) ? renderJsonRedirect(url) : doHttpRedirect(url);
	}

	static function isApiRequest(context:SmallUniverseContext):Bool {
		return !context.accepts('text/html');
	}

	static function renderJsonRedirect(url:String):OutgoingResponse {
		var instructions:SUApiResponseInstructions = {
			__smallUniverse: {
				redirect: url,
				messages: getMessages()
			}
		};
		return new OutgoingResponse(header(200, 'application/json'), Json.stringify(instructions));
	}

	static function header(status:Int, contentType:String) {
		return new ResponseHeader(status, status, [new HeaderField('Content-Type', contentType)]);
	}

	static function doHttpRedirect(url:String):OutgoingResponse {
		return new OutgoingResponse(new ResponseHeader(TemporaryRedirect, 307, [new HeaderField('Location', url)]), "");
	}

	static function prepareRedirectToSamePage(context:SmallUniverseContext):OutgoingResponse {
		// Create a copy of the URL, except with the `action=` parameter missing.
		var url:tink.Url = context.header.url;
		var currentQuery = url.query.toMap();
		var newQuery = tink.url.Query.build();
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
		return prepareRedirect(context, redirectUrl);
	}

	static function renderPage(page:UniversalPage<Dynamic, Dynamic, Dynamic>):Promise<OutgoingResponse> {
		if (isApiRequest(page.context)) {
			return prepareJsonResponse(page);
		} else {
			return prepareHtmlResponse(page);
		}
	}

	static function prepareJsonResponse(page:UniversalPage<Dynamic, Dynamic, Dynamic>):Promise<OutgoingResponse> {
		return page.getPageJson().next(function(pageJson) {
			var logs = getMessages();
			if (logs != null) {
				// Please note we have to use haxe.Json instead of tink.Json.
				// The reason is that tink.Json will ignore any fields it isn't expecting when parsing, and we want to preserve all data.
				var responseData:SUApiResponseInstructions = haxe.Json.parse(pageJson);
				responseData.__smallUniverse = {
					messages: logs
				};
				pageJson = haxe.Json.stringify(responseData);
			}
			return new OutgoingResponse(header(200, 'application/json'), pageJson);
		});
	}

	static function prepareHtmlResponse(page:UniversalPage<Dynamic, Dynamic, Dynamic>):Promise<OutgoingResponse> {
		return page.getPageHtml().next(function(pageHtml) {
			var propsJson = @:privateAccess page.serializeProps(page.props);
			var pageName = Type.getClassName(Type.getClass(page));
			var head = page.head.renderToString();

			var logScripts = prepareLogScript(getMessages());

			var html = SmallUniverse.template;
			html = StringTools.replace(html, '{BODY}', pageHtml);
			html = StringTools.replace(html, '{HEAD}', head);
			html = StringTools.replace(html, '{PAGE}', pageName);
			html = StringTools.replace(html, '{PROPS}', propsJson);
			html = StringTools.replace(html, '{LOGS}', logScripts);

			return new OutgoingResponse(header(200, 'text/html'), html);
		});
	}

	static function prepareLogScript(logs:Array<Array<String>>) {
		if (logs == null) {
			return "";
		}
		var script = '\n<script>';
		for (log in logs) {
			var args = log.map(function(arg) {
				// When parsing this to the browser, the `\` escaping is meant for the JSON parser, not the JS parser.
				// Which means we have to double escape, replacing `\"` with `\\"`.
				var backslash = '\\';
				var escapedArg = StringTools.replace(arg, backslash, backslash + backslash);
				return 'JSON.parse(\'$escapedArg\')';
			}).join(", ");
			script += '\nconsole.log($args);';
		}
		script += '\n</script>';
		return script;
	}

	public static function captureTraces() {
		SULogger.instance.captureTraces();
	}

	static function getMessages() {
		return SULogger.instance.getMessages();
	}
	#end
}
