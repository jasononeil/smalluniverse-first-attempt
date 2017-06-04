#if server
import sys.io.File;
#end
import tink.Json;
import HelloPage;
using tink.CoreApi;

/**
TODO: document.
**/
class HelloBackendApi implements smalluniverse.BackendApi<HelloActions, HelloParams, HelloProps> {
	public function new() {}

	public function get(params:HelloParams):Promise<HelloProps> {
		var json = File.getContent('props.json');
		var props:{name:String, age:Int} = Json.parse(json);
		var location = params.location;
		return {
			name: props.name,
			age: props.age,
			location: (location!=null) ? location : "the world"
		};
	}

	public function processAction(params:HelloParams, action:HelloActions):Promise<Noise> {
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
	}
}
