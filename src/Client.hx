import react.*;
import js.Browser.window;
import js.Browser.document;
import smalluniverse.SUMacro.jsx;

class Client {
	static function main() {
		onReady(function () {
			var propsElem = document.getElementById('small-universe-props');
			var propsJson = propsElem.innerText;
			var props = haxe.Json.parse(propsJson);
			var container = document.getElementById('small-universe-app');
			switch propsElem.getAttribute('data-page') {
				case 'HelloPage':
					ReactDOM.render(
						jsx('<HelloPage {...props}/>'),
						container
					);
				case 'AboutPage':
					ReactDOM.render(
						jsx('<AboutPage {...props}/>'),
						container
					);
				case other:
					trace('The page $other was rendered on the server, but we could not find a matching page on the client');
			};
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
