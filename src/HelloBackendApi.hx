#if server
import js.node.Fs;
#end
import tink.Json;
import HelloPage;
import smalluniverse.*;

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
		return Future.async(resolve -> {
			Fs.readFile('props.json', function(err, buffer) {
				if (err != null) {
					resolve(Failure(new Error('Error reading props.json: ${err}')));
				}
				var props:{name:String, age:Int} = Json.parse(buffer.toString());

				resolve(Success({
					name: props.name,
					age: props.age,
					location: (this.location != null) ? this.location : "the world"
				}));
			});
		});
	}

	public function processAction(context, action):Promise<BackendApiResult> {
		return get(context).next(props -> {
			props = updatePropsForAction(props, action);
			return Future.async(resolve -> {
				Fs.writeFile('props.json', Json.stringify(props), function(err) {
					if (err != null) {
						resolve(Failure(Error.withData('Failed to save props.json', err)));
					}
					resolve(Success(BackendApiResult.Done));
				});
			});
		});
	}

	function updatePropsForAction(props:HelloProps, action:HelloActions):HelloProps {
		return switch action {
			case ChangeName(newName):
				{
					name: newName,
					age: props.age,
					location: props.location,
				}
			case GetOlder:
				{
					name: props.name,
					age: props.age + 1,
					location: props.location,
				}
		}
	}
}
