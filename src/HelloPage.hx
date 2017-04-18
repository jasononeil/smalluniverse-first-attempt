import smalluniverse.UniversalComponent;
import smalluniverse.SUMacro.jsx;

class HelloPage extends UniversalComponent<{name:String}, {}, {}> {
	override function render():UniversalElement {
			function MyParagraph(props:{text:String}) {
				return jsx('<p>${props.text}</p>');
			}
        	return jsx('<div>
				<Header text=${"Hello " + this.props.name}></Header>
				<h2><em>or should I say <strong>${this.props.name.toUpperCase()}</strong></em></h2>
				<MyParagraph text="Nice to meet you!"></MyParagraph>
			</div>');
	}

	override function componentDidMount():Void {
		trace('We have mounted it');
	}
}

class Header extends UniversalComponent<{text:String}, {}, {}> {
	override function render():UniversalElement {
		return jsx('<h1 onClick=${alert}>${this.props.text}</h1>');
	}

	@:client
	function alert() {
		js.Browser.alert("click");
	}
}
