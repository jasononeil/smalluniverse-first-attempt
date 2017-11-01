#if server
import sys.io.File;
#end
import tink.Json;
import HelloPage;
import smalluniverse.BackendApi;
import smalluniverse.SmallUniverseContext;
using tink.CoreApi;

/**
TODO: document.
**/
class HelloBackendApi implements BackendApi<HelloActions, HelloProps> {
	var location:String;

	public function new(location) {
		this.location = location;
	}

	public function get(context):Promise<HelloProps> {
		var json = File.getContent('props.json');
		var props:{name:String, age:Int} = Json.parse(json);
		return {
			name: props.name,
			age: props.age,
			location: (this.location!=null) ? this.location : "the world"
		};
	}

	public function processAction(context, action):Promise<BackendApiResult> {
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
