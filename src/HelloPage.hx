import smalluniverse.SUComponent;
import smalluniverse.SUMacro.jsx;

class HelloPage extends SUComponent<{name:String}, {}, {}> {
	public function new(props) {
		super(props);
	}

	override function render():SUElement {
        	return jsx('<h1 onMouseEnter={function () trace("mouse enter")}>Hello {this.props.name}, <em>or should I say <strong>{this.props.name.toUpperCase()}</strong></em></h1>');
	}

	override function componentDidMount():Void {
		trace('We have mounted it');
	}
}
