#if server
import sys.io.File;
#end
import tink.Json;
import HelloPage;
using tink.CoreApi;

/**
TODO: document.
**/
// TODO: use build macro to allow this to compile client side.
class HelloBackendApi implements smalluniverse.BackendApi<HelloActions, HelloParams, HelloProps> {
	public function new() {}

	public function get(params:HelloParams):Promise<HelloProps> {
		#if server
		var json = File.getContent('props.json');
		var props:{name:String, age:Int} = Json.parse(json);
		var location = params.location;
		return {
			name: props.name,
			age: props.age,
			location: (location!=null) ? location : "the world"
		};
		#else
		return throw 'need to make this skip compilation on client';
		#end
	}

	public function processAction(params:HelloParams, action:HelloActions):Promise<Noise> {
		#if server
		var json = File.getContent('props.json');
		var props:{name:String, age:Int} = Json.parse(json);
		switch action {
			case ChangeName(newName):
				props.name = newName;
			case GetOlder:
				props.age++;
		}
		json = Json.stringify(props);
		File.saveContent('props.json', json);
		return Noise;
		#else
		return throw 'need to make this skip compilation on client';
		#end
	}
}
