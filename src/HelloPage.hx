import react.ReactComponent;
import react.ReactMacro.jsx;

class HelloPage extends ReactComponent {
	public function new(props) {
		super(props);
	}

	override function render():ReactElement {
        return jsx('<h1 onMouseEnter={function () trace("mouse enter")}>Hello {this.props.name}, <em>or should I say <strong>{this.props.name.toUpperCase()}</strong></em></h1>');
	}

	override function componentDidMount():Void {
		trace('We have mounted it');
	}
}
