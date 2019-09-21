package smalluniverse;

import react.ReactEvent;
import react.React;
import react.ReactComponent.ReactFragment;
import react.ReactType;
import tink.core.Callback;

@:publicFields
class HtmlElements {
	/** An alias for `html()` to save a few keyboard characters. **/
	static inline function h(element, ?props, ?children)
		return html(element, props, children);

	static inline function html<T>(element:ReactType, ?props:T, ?children:ReactFragment)
		return React.createElement(element, props, children);

	/** An alias for `component()` to save a few keyboard characters. **/
	static inline function c(element, ?props, ?children)
		return component(element, props, children);

	static inline function component<T>(element:ReactTypeOf<T>, ?props:T, ?children:ReactFragment)
		return React.createElement(element, props, children);

	static inline function div(?props:HtmlProps, ?children:ReactFragment)
		return html('div', props, children);

	static inline function h1(?props:HtmlProps, ?children:ReactFragment)
		return html('h1', props, children);

	/** A heading level 2 **/
	static inline function h2(?props:HtmlProps, ?children:ReactFragment)
		return html('h2', props, children);

	static inline function h3(?props:HtmlProps, ?children:ReactFragment)
		return html('h3', props, children);

	static inline function h4(?props:HtmlProps, ?children:ReactFragment)
		return html('h4', props, children);

	static inline function h5(?props:HtmlProps, ?children:ReactFragment)
		return html('h5', props, children);

	static inline function h6(?props:HtmlProps, ?children:ReactFragment)
		return html('h6', props, children);

	static inline function p(?props:HtmlProps, ?children:ReactFragment)
		return html('p', props, children);

	static inline function em(?props:HtmlProps, ?children:ReactFragment)
		return html('em', props, children);

	static inline function strong(?props:HtmlProps, ?children:ReactFragment)
		return html('strong', props, children);

	static inline function b(?props:HtmlProps, ?children:ReactFragment)
		return html('b', props, children);

	static inline function input(?props:HtmlProps, ?children:ReactFragment)
		return html('input', props, children);

	static inline function a(?props:AnchorProps, ?children:ReactFragment)
		return html('a', props, children);
}

typedef HtmlProps = {
	> HtmlEvents,
	@:optional var id:String;
	@:optional var className:String;
}

typedef AnchorProps = {
	> HtmlProps,
	var href:String;
}

typedef HtmlEvents = {
	@:optional var onClick:Callback<ReactEvent>;
	@:optional var onKeyUp:Callback<ReactEvent>;
}
