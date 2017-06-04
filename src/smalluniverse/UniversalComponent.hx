package smalluniverse;

/**
	A functional component is just a function, it takes properties and renders an element, usually using JSX.

	For the difference between functional components and state components, see:
	https://facebook.github.io/react/docs/components-and-props.html#functional-and-class-components
**/
typedef UniversalFunctionalComponent<TProps> = TProps->UniversalElement;

/**
	Components in Small Universe should extend this class.
**/
@:autoBuild(smalluniverse.SUBuildMacro.buildUniversalComponent())
class UniversalComponent<TProps, TState, TRefs> extends UniversalComponentBaseType<TProps, TState, TRefs> {

}

/**
	A typedef that points to different things on different platforms, allowing "UniversalComponent" to behave consistently across platforms.

	On client-side JS, this points to `ReactComponent`.
	On server-side platforms, this points to `SUServerSideComponent`.
**/
typedef UniversalComponentBaseType<TProps, TState, TRefs> =
	#if (client) react.ReactComponent.ReactComponentOf<TProps, TState, TRefs>
	#else SUServerSideComponent<TProps, TState, TRefs>
	#end;

/**
	A virtual-DOM element that is the result of having rendered a component.

	On client-side JS, this points to `ReactElement`.
	On server-side platforms, this points to `SUServerSideNode`.
**/
typedef UniversalElement =
	#if (client) react.ReactComponent.ReactElement
	#else SUServerSideComponent.SUServerSideNode
	#end;
