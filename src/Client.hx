import react.*;
import js.Browser.window;
import js.Browser.document;
import smalluniverse.SUMacro.jsx;

class Client {
	static function main() {
		onReady(function () {
			ReactDOM.render(jsx('<HelloPage name="Jason" />'), document.getElementById('small-universe-app'));
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
