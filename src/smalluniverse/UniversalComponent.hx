package smalluniverse;

/**
	A functional component is just a function, it takes properties and renders an element, usually using JSX.

	For the difference between functional components and state components, see:
	https://facebook.github.io/react/docs/components-and-props.html#functional-and-class-components
**/
typedef UniversalFunctionalComponent<TProps> = TProps->UniversalNode;

/**
	Components in Small Universe should extend this class.
**/
@:autoBuild(smalluniverse.SUBuildMacro.buildUniversalComponent())
class UniversalComponent<TProps:{}, TState:{}> extends UniversalComponentBaseType<TProps, TState> {
	#if client
	override public function render():UniversalNode {
		return null;
	}
	#end
}

/**
	A typedef that points to different things on different platforms, allowing "UniversalComponent" to behave consistently across platforms.

	On client-side JS, this points to `ReactComponent`.
	On server-side platforms, this points to `SUServerSideComponent`.
**/
typedef UniversalComponentBaseType<TProps:{}, TState:{}> = #if (client) react.ReactComponent.ReactComponentOf<TProps,
	TState> #else SUServerSideComponent<TProps, TState> #end;
