package smalluniverse;

#if server
import smalluniverse.UniversalComponent;
import haxe.crypto.Adler32;
import haxe.io.Bytes;
import tink.CoreApi;

/**
	A base class for SmallUniverse components - a subset of React components that can be rendered on any Haxe server-side platform.

	It is designed to be mostly compatible with React components, for a subclass to extend either this or React.Component directly, and the code to work seamlessly on either.
**/
@:autoBuild(smalluniverse.SUComponentBuilder.buildUniversalComponent())
class SUServerSideComponent<TProps, TState, TRefs> {
	public var props(default, null):TProps;
	public var state(default, null):TState;

	public function new(?props:TProps) {
		this.props = props;
	}

	/**
		https://facebook.github.io/react/docs/react-component.html#render
	**/
	public function render():SUServerSideNode {
		return null;
	}

	/**
		React lifecycle hook.
		This is the only lifecycle hook that will be executed in server-side rendering.
		See https://facebook.github.io/react/docs/react-component.html#componentwillmount
	**/
	public function componentWillMount():Void {}

	/**
		React lifecycle hook.
		Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#componentdidmount
	**/
	public function componentDidMount():Void {}

	/**
		React lifecycle hook.
		Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#componentwillunmount
	**/
	public function componentWillUnmount():Void {}

	/**
		React lifecycle hook.
		Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#componentwillreceiveprops
	**/
	public function componentWillReceiveProps(nextProps:TProps):Void {}

	/**
		React lifecycle hook.
		Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#shouldcomponentupdate
	**/
	dynamic public function shouldComponentUpdate(nextProps:TProps, nextState:TState):Bool {
		return true;
	}

	/**
		React lifecycle hook.
		Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#componentwillupdate
	**/
	public function componentWillUpdate(nextProps:TProps, nextState:TState):Void {}

	/**
		React lifecycle hook.
		Please note this will not be executed in server-side rendering, only `componentWillMount` is executed server side.
		See https://facebook.github.io/react/docs/react-component.html#componentdidupdate
	**/
	public function componentDidUpdate(prevProps:TProps, prevState:TState):Void {}
}

/**
	A server-side Virtual-DOM element that is the result of a component rendering.
	Its only real purpose is to render to a String so we can send HTML to the client.
**/
abstract SUServerSideNode(SUServerSideNodeType<Dynamic>) {
	inline function new (type:SUServerSideNodeType<Dynamic>) {
		this = type;
	}

	@:to
	public inline function toEnum():SUServerSideNodeType<Dynamic> {
		return this;
	}

	public function renderToString(?startingId:Ref<Int>, ?onlyChild = false):String {
		if (startingId == null) {
			startingId = Ref.to(0);
		}
		switch this {
			case Text(str):
				str = StringTools.htmlEscape(str);
				if (onlyChild) {
					return str;
				}
				startingId.value = startingId.value + 1;
				return '<!-- react-text: ${startingId.value} -->${str}<!-- /react-text -->';
			case Html(tag, props, children):
				startingId.value = startingId.value + 1;

				var isRootNode = (startingId.value == 1),
					idOfCurrentNode = startingId.value,
					openingTag = "",
					attrsHtml = "",
					childrenHtml = "";

				if (props) {
					var fields = Reflect.fields(props);
					if (fields.length > 0) {
						var ignoredFields = ['onCopy', 'onCut', 'onPaste', 'onCompositionEnd', 'onCompositionStart', 'onCompositionUpdate', 'onKeyDown', 'onKeyPress', 'onKeyUp', 'onFocus', 'onBlur', 'onChange', 'onInput', 'onSubmit', 'onClick', 'onContextMenu', 'onDoubleClick', 'onDrag', 'onDragEnd', 'onDragEnter', 'onDragExit', 'onDragLeave', 'onDragOver', 'onDragStart', 'onDrop', 'onMouseDown', 'onMouseEnter', 'onMouseLeave', 'onMouseMove', 'onMouseOut', 'onMouseOver', 'onMouseUp', 'onSelect', 'onTouchCancel', 'onTouchEnd', 'onTouchMove', 'onTouchStart', 'onScroll', 'onWheel', 'onAbort', 'onCanPlay', 'onCanPlayThrough', 'onDurationChange', 'onEmptied', 'onEncrypted', 'onEnded', 'onError', 'onLoadedData', 'onLoadedMetadata', 'onLoadStart', 'onPause', 'onPlay', 'onPlaying', 'onProgress', 'onRateChange', 'onSeeked', 'onSeeking', 'onStalled', 'onSuspend', 'onTimeUpdate', 'onVolumeChange', 'onWaiting', 'onLoad', 'onError', 'onAnimationStart', 'onAnimationEnd', 'onAnimationIteration', 'onTransitionEnd'];

						for (field in fields) {
							if (ignoredFields.indexOf(field) > -1) {
								continue;
							}
							var value = Reflect.field(props, field);
							value = StringTools.htmlEscape(value);
							attrsHtml += ' $field="$value"';
						}
					}
				}

				if (children != null) {
					for (child in children) {
						childrenHtml += child.renderToString(startingId, children.length == 1);
					}
				}

				openingTag = '<$tag';
				if (isRootNode) {
					openingTag += ' data-reactroot=""';
				}
				openingTag += ' data-reactid="${idOfCurrentNode}"';
				var html =
					openingTag
					 + attrsHtml
					 + ((childrenHtml != "") ? ">" : "/>")
					 + childrenHtml
					 + ((childrenHtml != "") ? '</${tag}>' : '');
				if (isRootNode) {
					// We need a checksum of the full tree, then we
					var checksum = Adler32.make(Bytes.ofString(html));
					// Immediately after the opening tag insert the checksum.
					var posToInsert = '<$tag'.length;
					html = html.substr(0, posToInsert) + ' data-react-checksum="$checksum"' + html.substr(posToInsert);
				}
				return html;
			case Component(component, props, children):
				// We don't render and markup for the component or it's children directly.
				// We leave it entirely up to the component to render itself.
				props.children = children;
				return component.render(props).renderToString(startingId);
		}
	}

	@:from
	public static inline function fromString(str:String):SUServerSideNode {
		return new SUServerSideNode(Text(str));
	}

	// We need the automatic cast because macros generate `var type:SUServerSideNode = $expr` where we don't know what $expr is.
	// With two static casts set up we can send whichever value it happens to be and have it correctly set by the Haxe compiler.
	@:from
	public static inline function fromEnum(type:SUServerSideNodeType<Dynamic>):SUServerSideNode {
		return new SUServerSideNode(type);
	}

	public static function createNodeForComponent<TProps>(component:SUServerSideRenderFn<TProps>, props:TProps, children:Array<SUServerSideNode>):SUServerSideNode {
		return SUServerSideNodeType.Component(component, props, children);
	}

	public static function createNodeForHtml(tagName:String, props:Dynamic, children:Array<SUServerSideNode>):SUServerSideNode {
		return SUServerSideNodeType.Html(tagName, props, children);
	}
}

/**
	An enum describing the different types of nodes - text, html, and sub-components.

	We store our nodes using this representation to make rendering a String easy.

	Internal use only.
**/
enum SUServerSideNodeType<TProps> {
	Text(str:String);
	Html(tagName:String, props:TProps, children:Array<SUServerSideNode>);
	Component(component:SUServerSideRenderFn<TProps>, props:TProps, children:Array<SUServerSideNode>);
}

/**
	A helper type that can instantiate a component, whether it is a component class or a pure function.

	For internal use.
**/
abstract SUServerSideRenderFn<TProps>(UniversalFunctionalComponent<TProps>) from UniversalFunctionalComponent<TProps> {
	public function new (fn) {
		this = fn;
	}

	inline public function render(props) {
		return this(props);
	}

	@:from
	public static function fromClassComponent<TProps>(cls:Class<SUServerSideComponent<TProps,Dynamic,Dynamic>>):SUServerSideRenderFn<TProps> {
		return function (props:TProps):SUServerSideNode {
			var component = Type.createInstance(cls, [props]);
			return component.render();
		}
	}
}
#end
