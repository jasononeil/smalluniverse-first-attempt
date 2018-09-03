package smalluniverse;

// In future this might use AuthedContext, or a custom SmallUniverseContext extension.
typedef SmallUniverseContext = #if server tink.web.routing.Context; #elseif client Dynamic; #end
