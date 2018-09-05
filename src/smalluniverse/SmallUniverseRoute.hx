package smalluniverse;

#if server
@:genericBuild(smalluniverse.SUBuildMacro.buildSmallUniverseRoute())
class SmallUniverseRoute<TPage:UniversalPage<Dynamic, Dynamic, Dynamic>> {}
#end