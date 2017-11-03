package smalluniverse;

import tink.http.Response;
import tink.http.Header;
import smalluniverse.BackendApi;
using tink.CoreApi;

abstract SmallUniverse(UniversalPage<Dynamic,Dynamic,Dynamic>) {
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

	public function new(context: SmallUniverseContext, pageToUse:LazyUniversalPage) {
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
					return renderPage();
			});
		}
		return renderPage();
	}

	function processAction(): Promise<BackendApiResult> {
		var actionJson = this.context.param('action');
		var action = @:privateAccess this.deserializeAction(actionJson);
		return this.backendApi.processAction(this.context, action);
	}

	function prepareRedirect(url: String): OutgoingResponse {
		return new OutgoingResponse(
			new ResponseHeader(301, 301, [
				new HeaderField('Location', url)
			]),
			""
		);
	}

	function renderPage(): Promise<OutgoingResponse> {
		var isApiRequest = !this.context.accepts('text/html');
		if (isApiRequest) {
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
}
