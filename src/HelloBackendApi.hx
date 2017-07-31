#if server
import sys.io.File;
#end
import tink.Json;
import HelloPage;
import smalluniverse.BackendApi;
using tink.CoreApi;

/**
TODO: document.
**/
class HelloBackendApi implements smalluniverse.BackendApi<HelloActions, HelloParams, HelloProps> {
	public function new() {}

	public function get(req:Request<HelloParams>):Promise<HelloProps> {
		var json = File.getContent('props.json');
		var props:{name:String, age:Int} = Json.parse(json);
		var location = req.params.location;
		return {
			name: props.name,
			age: props.age,
			location: (location!=null) ? location : "the world"
		};
	}

	public function processAction(req:Request<HelloParams>, action:HelloActions):Promise<BackendApiResult> {
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
		return Done;
	}
}
