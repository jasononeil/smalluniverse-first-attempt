import smalluniverse.SUComponent;
import smalluniverse.SUMacro.jsx;

class HelloPage extends SUComponent<{name:String}, {}, {}> {
	override function render():SUElement {
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

class Header extends SUComponent<{text:String}, {}, {}> {
	override function render():SUElement {
		return jsx('<h1 onClick=${alert}>${this.props.text}</h1>');
	}

	function alert() {
		#if client
		js.Browser.alert("click");
		#end
	}
}
