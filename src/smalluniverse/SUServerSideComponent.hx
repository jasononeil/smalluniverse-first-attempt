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
class SUServerSideComponent<TProps, TState, TRefs> {
	public var props(default, null):TProps;
	public var state(default, null):TState;

	public function new(?props:TProps) {
		this.props = props;
	}

	/**
		Set the state for the current component.
		Please note that on a server-side component, the only place the state can be set is during `componentWillMount`.
		Here the state can be set to either a default value, or a value derived from `this.props`.

		Please note, currently on the server side setting the state overrides the old state with the new one.
		This is different to the behaviour with React on the client, where it will partially overwrite the old one, and only change values you specify.
	**/
	public function setState(newState:TState):Void {
		this.state = newState;
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
		if (this == null) {
			return "";
		}
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
					childrenHtml = "",
					dangerousInnerHtml:String = null;

				if (props) {
					var fields = Reflect.fields(props);
					if (fields.length > 0) {
						var ignoredFields = ['ref', 'children', 'onCopy', 'onCut', 'onPaste', 'onCompositionEnd', 'onCompositionStart', 'onCompositionUpdate', 'onKeyDown', 'onKeyPress', 'onKeyUp', 'onFocus', 'onBlur', 'onChange', 'onInput', 'onSubmit', 'onClick', 'onContextMenu', 'onDoubleClick', 'onDrag', 'onDragEnd', 'onDragEnter', 'onDragExit', 'onDragLeave', 'onDragOver', 'onDragStart', 'onDrop', 'onMouseDown', 'onMouseEnter', 'onMouseLeave', 'onMouseMove', 'onMouseOut', 'onMouseOver', 'onMouseUp', 'onSelect', 'onTouchCancel', 'onTouchEnd', 'onTouchMove', 'onTouchStart', 'onScroll', 'onWheel', 'onAbort', 'onCanPlay', 'onCanPlayThrough', 'onDurationChange', 'onEmptied', 'onEncrypted', 'onEnded', 'onError', 'onLoadedData', 'onLoadedMetadata', 'onLoadStart', 'onPause', 'onPlay', 'onPlaying', 'onProgress', 'onRateChange', 'onSeeked', 'onSeeking', 'onStalled', 'onSuspend', 'onTimeUpdate', 'onVolumeChange', 'onWaiting', 'onLoad', 'onError', 'onAnimationStart', 'onAnimationEnd', 'onAnimationIteration', 'onTransitionEnd'];

						for (field in fields) {
							if (ignoredFields.indexOf(field) > -1) {
								continue;
							}
							var value:Any = Reflect.field(props, field);
							if (field == 'dangerouslySetInnerHTML') {
								var data:Dynamic = value;
								dangerousInnerHtml = (data != null) ? data.__html : null;
								continue;
							}
							if (tag  == 'textarea') {
								if (field == 'value' || field == 'defaultValue') {
									dangerousInnerHtml = value;
									continue;
								}
							}
							if (field == 'style') {
								var styleObject:Dynamic<String> = value;
								var styleRules = [];
								for (styleField in Reflect.fields(styleObject)) {
									var styleValue = Reflect.field(styleObject, styleField);
									var styleName = transformJsNameToCssName(styleField);
									styleRules.push('$styleName:$styleValue;');
								}
								value = styleRules.join("");
							}
							value = StringTools.htmlEscape(value);
							if (field == 'className') {
								field = 'class';
							}
							attrsHtml += ' $field="$value"';
						}
					}
				}

				if (dangerousInnerHtml != null) {
					childrenHtml = dangerousInnerHtml;
				} else if (children != null) {
					for (child in children) {
						childrenHtml += child.renderToString(startingId, children.length == 1);
					}
				}

				openingTag = '<$tag';
				var reactRootTag = isRootNode ? ' data-reactroot=""' : '';
				var selfClosingTags = ['area', 'base', 'br', 'col', 'command', 'embed', 'hr', 'img', 'input', 'keygen', 'link', 'meta', 'param', 'source', 'track', 'wbr'];
				var selfClosingTag = (selfClosingTags.indexOf(tag) > -1) ? '/>' : '></$tag>';
				var html =
					openingTag
					 + attrsHtml
					 + reactRootTag
					 + ' data-reactid="${idOfCurrentNode}"'
					 + ((childrenHtml != "") ? ">" : selfClosingTag)
					 + childrenHtml
					 + ((childrenHtml != "") ? '</${tag}>' : '');
				if (isRootNode) {
					var checksum:Float = Adler32.make(Bytes.ofString(html));
					if (checksum > Math.pow(2, 16)) {
						// Make sure the checksum is in the Int32 range (-2^16 through to +2^16).
						// Even though Adler32 returns an Int, PHP is allowing it's value to exceed this.
						// TODO: file a bug report and pull request so haxe.Adler32 works with Int32s.
						checksum = checksum - Math.pow(2, 32);
					}
					// Insert the checksum at the end of the opening element.
					var TAG_END = ~/( ?\/?>)/;
					html = TAG_END.replace(html,  ' data-react-checksum="$checksum"$1');
				}
				return html;
			case Component(component, props, children):
				// We don't render and markup for the component or it's children directly.
				// We leave it entirely up to the component to render itself.
				props.children = fromArray(children);
				return component.render(props).renderToString(startingId);
			case NodeList(arr):
				var str = "";
				for (node in arr) {
					str += node.renderToString(startingId);
				}
				return str;
		}
	}

	static function transformJsNameToCssName(jsName:String):String {
		var cssName = "";
		for (i in 0...jsName.length) {
			var char = jsName.charAt(i);
			if (char.toUpperCase() == char) {
				cssName += '-';
				char = char.toLowerCase();
			}
			cssName += char;
		}
		return cssName;
	}

	@:from
	public static inline function fromString(str:String):SUServerSideNode {
		return new SUServerSideNode(Text(str));
	}

	@:from
	public static inline function fromArray(arr:Array<SUServerSideNode>):SUServerSideNode {
		return new SUServerSideNode(NodeList(arr));
	}

	// We need the automatic cast because macros generate `var type:SUServerSideNode = $expr` where we don't know what $expr is.
	// With two static casts set up we can send whichever value it happens to be and have it correctly set by the Haxe compiler.
	@:from
	public static inline function fromEnum(type:SUServerSideNodeType<Dynamic>):SUServerSideNode {
		return new SUServerSideNode(type);
	}

	public static function createNodeForComponent<TProps>(component:SUServerSideRenderFn<TProps>, props:TProps, children:Array<SUServerSideNode>):SUServerSideNode {
		var childrenNode = (children.length > 0) ? fromArray(children) : null;
		untyped props.children = childrenNode;
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
	NodeList(arr:Array<SUServerSideNode>);
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
			component.componentWillMount();
			return component.render();
		}
	}
}
#end
