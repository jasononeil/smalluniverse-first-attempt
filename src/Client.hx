import react.*;
import js.Browser.window;
import js.Browser.document;
import smalluniverse.SUMacro.jsx;
import smalluniverse.UniversalPage;

class Client {
	static function main() {
		var pages:Map<String,Class<react.ReactComponent>> = [
			'AboutPage' => AboutPage,
			'HelloPage' => HelloPage
		];
		onReady(function () {
			var propsElem = document.getElementById('small-universe-props');
			var propsJson = propsElem.innerText;
			var props = haxe.Unserializer.run(propsJson);
			var container = document.getElementById('small-universe-app');
			var pageCls = pages.get(propsElem.getAttribute('data-page'));
			ReactDOM.render(
				React.createElement(pageCls, props),
				container
			);
		});
	}

	static function onReady(fn:Void->Void) {
		if (document.readyState == "loading") {
			window.addEventListener("DOMContentLoaded", fn);
		} else {
			fn();
		}
	}
}
