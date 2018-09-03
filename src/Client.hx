import smalluniverse.SmallUniverse;
import js.Browser.window;
import js.Browser.document;

class Client {
	static function main() {
		onReady(function() {
			var propsElem = document.getElementById('small-universe-props');
			switch propsElem.getAttribute('data-page') {
				case 'AboutPage':
					SmallUniverse.hydrate(AboutPage);
				// Webpack.load(AboutPage).then(function () {
				// });
				case 'HelloPage':
					SmallUniverse.hydrate(HelloPage);
				// Webpack.load(HelloPage).then(function () {
				// });
				default:
					null;
			}
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
