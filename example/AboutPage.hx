import smalluniverse.UniversalPage;
import smalluniverse.HtmlElements.*;

using tink.CoreApi;

class AboutPage extends UniversalPage<{}, {}, {}> {
	override function get():Promise<{}> {
		return {};
	}

	override function render() {
		this.head.addScript('react-test.bundle.js');
		this.head.setTitle('About!');
		return div([h1({onClick: handleClick}, "About!"), a({href: "/"}, "Link to home")]);
	}

	override function componentDidMount():Void {
		trace('We have mounted the about page!');
	}

	@:client
	function handleClick() {
		trace('Clicked about header');
	}
}
