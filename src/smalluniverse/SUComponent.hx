package smalluniverse;

/**
    A pure component is just a function, it takes properties and renders an element, usually using JSX.

    Pure components have no internal state, and should return the same result every time they are called.
**/
typedef SUPureComponent<TProps> = TProps->SUElement;

/**
    Components in Small Universe should extend this class.

    On client-side JS, this points to `ReactComponent`.
    On server-side platforms, this points to `SUServerSideComponent`.
**/
typedef SUComponent<TProps, TState, TRefs> =
    #if (client) react.ReactComponent.ReactComponentOf<TProps, TState, TRefs>
    #else SUServerSideComponent<TProps, TState, TRefs>
    #end;

/**
    A virtual-DOM element that is the result of having rendered a component.

    On client-side JS, this points to `ReactElement`.
    On server-side platforms, this points to `SUServerSideNode`.
**/
typedef SUElement =
    #if (client) react.ReactComponent.ReactElement
    #else SUServerSideComponent.SUServerSideNode
    #end;
