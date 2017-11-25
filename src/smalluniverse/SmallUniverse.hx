package smalluniverse;

#if server
import tink.http.Response;
import tink.http.Header;
import tink.Json;
import smalluniverse.UniversalPage.SUApiResponseInstructions;
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
		page.props = page.deserializeProps(propsJson);
		return Future.async(function (done) {
			page.doClientRender(function () done(Noise));
		});
	}
	#end

	#if server
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

	public function new(pageToUse:LazyUniversalPage, context: SmallUniverseContext) {
		var page = pageToUse();
		@:privateAccess page.context = context;
		this = page;
	}

	@:to
	public function render(): Promise<OutgoingResponse> {
		if (this.context.hasParam('action')) {
			return processAction().next(function (result): Promise<OutgoingResponse> switch result {
				case Redirect(url):
					return prepareRedirect(url);
				case Done:
					// If it's JSON, we return the props directly.
					// If it's HTML, we want to redirect, so that if they refresh the page it doesn't repeat the action.
					return isApiRequest() ? prepareJsonResponse() : prepareRedirectToSamePage();
			});
		}
		return renderPage();
	}

	function processAction(): Promise<BackendApiResult> {
		var actionJson = this.context.param('action');
		var action = @:privateAccess this.deserializeAction(actionJson);
		return this.backendApi.processAction(this.context, action);
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
				redirect: url
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
			var html = SmallUniverse.template;
			html = StringTools.replace(html, '{BODY}', pageHtml);
			html = StringTools.replace(html, '{HEAD}', head);
			html = StringTools.replace(html, '{PAGE}', pageName);
			html = StringTools.replace(html, '{PROPS}', propsJson);

			return new OutgoingResponse(
				header(200, 'text/html'),
				html
			);
		});
	}
	#end
}
