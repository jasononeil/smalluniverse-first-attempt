import react.*;
import js.Browser.document;
import smalluniverse.SUMacro.jsx;

class Client {
	static function main() {
		ReactDOM.render(jsx('<HelloPage name="Jason" />'), document.getElementById('smalluniverse_root'));
	}
}
