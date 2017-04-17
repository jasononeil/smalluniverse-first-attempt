import react.*;
import js.Browser.document;
import react.ReactMacro.jsx;

class Client {
	static function main() {
		ReactDOM.render(jsx('<HelloPage name="Jason" />'), document.getElementById('container'));
	}
}
