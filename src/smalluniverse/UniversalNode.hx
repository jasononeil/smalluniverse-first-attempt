package smalluniverse;

import smalluniverse.SUServerSideComponent;

/**
A virtual-DOM node that is the result of having rendered a component.

On client-side JS, this wraps `ReactElement`.
On server-side platforms, this wraps `SUServerSideNode`.

Casting from `String` and `Array<UniversalNode>` is supported.
**/
abstract UniversalNode(UniversalNodeBaseType) from UniversalNodeBaseType to UniversalNodeBaseType {
	function new(val) {
		this = val;
	}

	/**
	Render the HTML for the current node.

	Please note, on the client side this is done by calling `ReactDOM.render(node, emptyDiv)`.
	This means that if the node you are embedding is not a valid child of a div, you may receive runtime warnings.

	In reality, this method is mostly for use server-side, and is only provided client-side for consistency.
	**/
	public function renderToString(): String {
		#if server
			return this.renderToString(true);
		#elseif client
			var container = js.Browser.document.createDivElement();
			react.ReactDOM.render(this, container);
			return container.innerHTML;
		#end
	}

	/**
	Cast an ordinary string into a UniversalNode.
	This allows you to use a simple string wherever a UniversalNode is expected.
	**/
	@:from
	public static inline function fromString(str: String): UniversalNode {
		#if server
		@:privateAccess return new SUServerSideNode(Text(str));
		#elseif client
		// React is actually okay to receive a String instead of a ReactElement, so use an unsafe cast.
		return cast str;
		#end
	}

	/**
	Cast an Int into a UniversalNode (it will be treated as a String).
	**/
	@:from
	public static inline function fromInt(int: Int): UniversalNode {
		return fromString(''+int);
	}

	/**
	Cast an Float into a UniversalNode (it will be treated as a String).
	**/
	@:from
	public static inline function fromFloat(float: Float): UniversalNode {
		return fromString(''+float);
	}

	/**
	Cast an `Array<UniversalNode>` into a UniversalNode.
	This allows you to use a collection of fragment nodes together wherever a UniversalNode is expected.
	**/
	@:from
	public static inline function fromArray(arr:Array<UniversalNode>):UniversalNode {
		#if server
		@:privateAccess return new SUServerSideComponent.SUServerSideNode(NodeList(arr));
		#elseif client
		// React is actually okay to receive an array of nodes here, so use an unsafe cast.
		return cast arr;
		#end
	}
}

typedef UniversalNodeBaseType =
	#if (client) react.ReactComponent.ReactElement
	#else SUServerSideComponent.SUServerSideNode
	#end;
