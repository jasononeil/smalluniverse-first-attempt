package smalluniverse;

#if client
import js.html.*;
#end
import haxe.ds.Option;
import smalluniverse.UniversalComponent;

using tink.CoreApi;

@:autoBuild(smalluniverse.SUBuildMacro.buildUniversalPage())
@:ignoreEmptyRender
class UniversalPage<TAction, TProps:{}, TState:{}> extends UniversalComponent<TProps, TState> {
	#if client
	public static function hydrate(pageCls:Class<UniversalPage<Dynamic, Dynamic, Dynamic>>):Promise<Noise> {
		return SUUniversalPageClientUtils.hydrate(pageCls);
	}
	#end

	public var head(default, null):UniversalPageHead;

	#if server
	/**
		TODO
	**/
	public var backendApi:BackendApi<TAction, TProps>;

	/**
		An object containing the server-side request information.

		Please note this is only available on the server.
	**/
	public var context(default, null):SmallUniverseContext;
	#end

	public function new(?backendApi:BackendApi<TAction, TProps>) {
		// A page should not receive props through a constructor, but through it's get() method.
		super();
		this.head = new UniversalPageHead();
		#if server
		this.backendApi = backendApi;
		#end
	}

	/**
		Retrieve the properties for this page.

		TODO: explain how this links with backend API.
	**/
	public function get():Promise<TProps> {
		#if server
		return this.backendApi.get(this.context);
		#elseif client
		return SUUniversalPageClientUtils.callServerApi(this, None).next(function(_) return this.props);
		#end
	}

	function deserializeProps(json:String):TProps {
		return throw 'Assert: should be implemented by macro';
	}

	function serializeProps(props:TProps):String {
		return throw 'Assert: should be implemented by macro';
	}

	function deserializeAction(json:String):SURequestBody<TAction> {
		return throw 'Assert: should be implemented by macro';
	}

	function serializeAction(action:SURequestBody<TAction>):String {
		return throw 'Assert: should be implemented by macro';
	}

	#if client
	/**
		TODO:
	**/
	public function trigger(action:TAction):Promise<Noise> {
		return SUUniversalPageClientUtils.callServerApi(this, Some(action));
	}
	#end
}
