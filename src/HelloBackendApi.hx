#if server
import asys.io.File;
#end
import tink.Json;
import HelloPage;
import smalluniverse.BackendApi;
using tink.CoreApi;

/**
TODO: document.
**/
class HelloBackendApi implements BackendApi<HelloActions, HelloProps> {
	var location:String;

	public function new(location) {
		// TODO: see if we can get the build macro to empty the constructor also.
		#if server
		this.location = location;
		#end
	}

	public function get(context):Promise<HelloProps> {
		return File.getContent('props.json').map(function (outcome) {
			var props:{name:String, age:Int} = Json.parse(outcome.sure());
			return {
				name: props.name,
				age: props.age,
				location: (this.location!=null) ? this.location : "the world"
			};
		});
	}

	public function processAction(context, action):Promise<BackendApiResult> {
		return File
			.getContent('props.json')
			.flatMap(function (outcome) {
				var props:{name: String, age: Int} = Json.parse(outcome.sure());
				switch action {
					case ChangeName(newName):
						props.name = newName;
					case GetOlder:
						props.age++;
				}
				var json = Json.stringify(props);
				return File.saveContent('props.json', json);
			}).map(function (outcome) {
				outcome.sure();
				return Done;
			});
	}
}
