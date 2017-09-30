import smalluniverse.UniversalPage;
import js.Browser.window;
import js.Browser.document;

class Client {
	static function main() {
		onReady(function () {
			var propsElem = document.getElementById('small-universe-props');
			switch propsElem.getAttribute('data-page') {
				case 'AboutPage':
					UniversalPage.startClientRendering(AboutPage, propsElem.innerText);
					// Webpack.load(AboutPage).then(function () {
					// });
				case 'HelloPage':
					UniversalPage.startClientRendering(HelloPage, propsElem.innerText);
					// Webpack.load(HelloPage).then(function () {
					// });
				default: null;
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
