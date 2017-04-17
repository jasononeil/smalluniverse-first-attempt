package smalluniverse;

/**
    A base class for SmallUniverse components - a subset of React components that can be rendered on any Haxe server-side platform.

    It is designed to be mostly compatible with React components, for a subclass to extend either this or React.Component directly, and the code to work seamlessly on either.
**/
class SUServerSideComponent<TProps, TState, TRefs>
{
	var props(default, null):TProps;
	var state(default, null):TState;

	function new(?props:TProps) {
        this.props = props;
    }

	/**
		https://facebook.github.io/react/docs/react-component.html#render
	**/
	function render():SUServerSideElement {
		return null;
	}

	/**
        React lifecycle hook.
        This is the only lifecycle hook that will be executed in server-side rendering.
		See https://facebook.github.io/react/docs/react-component.html#componentwillmount
	**/
	function componentWillMount():Void {}

	/**
        React lifecycle hook.
        Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#componentdidmount
	**/
	function componentDidMount():Void {}

	/**
        React lifecycle hook.
        Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#componentwillunmount
	**/
	function componentWillUnmount():Void {}

	/**
        React lifecycle hook.
        Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#componentwillreceiveprops
	**/
	function componentWillReceiveProps(nextProps:TProps):Void {}

	/**
        React lifecycle hook.
        Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#shouldcomponentupdate
	**/
	dynamic function shouldComponentUpdate(nextProps:TProps, nextState:TState):Bool {
		return true;
	}

	/**
        React lifecycle hook.
        Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#componentwillupdate
	**/
	function componentWillUpdate(nextProps:TProps, nextState:TState):Void {}

	/**
        React lifecycle hook.
        Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#componentdidupdate
	**/
	function componentDidUpdate(prevProps:TProps, prevState:TState):Void {}
}

/**
	A server-side Virtual-DOM element that is the result of a component rendering.
	Its only real purpose is to render to a String so we can send HTML to the client.
**/
class SUServerSideElement {
	public static function createElement(type:CreateElementType, ?attrs:Dynamic, children:Array<CreateElementType>):SUServerSideElement {
		return new SUServerSideElement();
	}

	function new() {}

	public function renderToString():String {
		return '<h1 data-reactroot="" data-reactid="1">this my thingo</h1>';
	}
}

abstract CreateElementType(Dynamic) from String from haxe.Constraints.Function from Class<SUServerSideComponent<Dynamic,Dynamic,Dynamic>> from SUServerSideElement {

}
