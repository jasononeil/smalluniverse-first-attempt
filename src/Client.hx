import react.*;
import js.Browser.window;
import js.Browser.document;
import smalluniverse.SUMacro.jsx;

class Client {
	static function main() {
		onReady(function () {
			var propsJson = document.getElementById('small-universe-props').innerText;
			var props = haxe.Json.parse(propsJson);
			ReactDOM.render(
				jsx('<HelloPage {...props}/>'),
				document.getElementById('small-universe-app')
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
