import tink.http.containers.*;
import tink.http.Response;
import tink.http.Handler;
import tink.web.routing.*;
import tink.http.middleware.Static;
import tink.http.Response.OutgoingResponse;
import smalluniverse.SmallUniverse;

class Server {
	static function main() {
		SmallUniverse.captureTraces();

		var container = new NodeContainer(8080);
		var router = new Router<Root>(new Root());
		var handler:Handler = function(req) {
			return router.route(Context.ofRequest(req)).recover(OutgoingResponse.reportError);
		};
		container.run(handler.applyMiddleware(new Static('js', '/js/'))).handle(function(status) {
			switch status {
				case Running(arg1):
					trace('Running: Listening on port 8080');
				case Failed(err):
					trace('Error starting server: $err');
				case Shutdown:
					trace('Shutdown successful');
			};
		});
	}
}

class Root {
	public function new() {}

	@:sub
	public var about = new SmallUniverseRoute<AboutPage>(new AboutPage());

	@:sub('/$location')
	@:sub('/')
	public function hello(location = 'The World') {
		return new SmallUniverseRoute<HelloPage>(new HelloPage(location));
	}
}
