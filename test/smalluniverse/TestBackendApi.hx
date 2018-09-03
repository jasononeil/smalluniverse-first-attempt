package smalluniverse;

import buddy.*;

using buddy.Should;
using tink.CoreApi;

enum BackendApiTestAction {
	DoAThing;
}

/**
	To make things easier for developers, we try to make `BackendApi` classes exist on the client, so
	no tricky conditional compilation is needed to get your code compiling on both server and client.

	We do this by "emptying" the class using a build macro, getting rid of or emptying all methods, so
	that no server-side only things (like calls to `Sys.*`) exist on the client.

	This class tests that by putting a `Sys.programPath()` call in each method, and checking it compiles
	okay on the client.
**/
class SimpleBackendApi implements BackendApi<BackendApiTestAction, {name:String}> {
	public function new() {
		Sys.programPath();
	}

	public function get(context):Promise<{name:String}> {
		Sys.programPath();
		someInstanceFn();
		return {
			name: "Jason"
		};
	}

	public function processAction(context, action):Promise<BackendApiResult> {
		Sys.programPath();
		someStaticFn();
		return BackendApiResult.Done;
	}

	function someInstanceFn() {
		Sys.programPath();
	}

	static function someStaticFn() {
		Sys.programPath();
	}
}

class TestBackendApi extends BuddySuite {
	public function new() {
		describe("BackendApi", {
			it("should compile an empty copy on the client without any hassle", {
				var backendApi = new SimpleBackendApi();
			});

			#if server
			it("should leave everything in tact and working on the server", function(done) {
				var backendApi = new SimpleBackendApi(), context = null;
				backendApi.get(context).next(function(props) {
					props.name.should.be("Jason");
					return backendApi.processAction(context, DoAThing);
				}).next(function(result) {
					result.should.equal(BackendApiResult.Done);
					return result;
				}).handle(done);
			});
			#end
		});
	}
}
