package smalluniverse;

import tink.http.Response;
import tink.http.Header;
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
		// TODO: check context first to decide if we should be returning JSON instead of HTML.
		return renderHtml();
	}

	public function renderHtml(): Promise<OutgoingResponse> {
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
				new ResponseHeader(200, 200, [new HeaderField('Content-Type', 'text/html')]),
				html
			);
		});
	}
}
