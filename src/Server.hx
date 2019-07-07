import tink.http.containers.*;
import tink.http.Response;
import tink.http.Handler;
import tink.web.routing.*;
// Disabling static middleware for now as it depends on asys, which has not been updated for Haxe 4
// import tink.http.middleware.Static;
import tink.http.Response.OutgoingResponse;
import smalluniverse.*;

class Server {
	static function main() {
		SmallUniverse.captureTraces();

		var container = #if js new NodeContainer(8080); #elseif php PhpContainer.inst; #end
		var router = new Router<Root>(new Root());
		var handler:Handler = function(req) {
			return router.route(Context.ofRequest(req)).recover(OutgoingResponse.reportError);
		};
		// handler.applyMiddleware(new Static('js', '/js/'));
		container.run(handler).handle(function(status) {
			switch status {
				case Running(arg1):
					trace('Running: http://localhost:8080');
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

	@:sub('/about')
	public var about = new SmallUniverseRoute<AboutPage>(new AboutPage());

	@:sub('/$location')
	@:sub('/')
	public function hello(location = 'The World') {
		return new SmallUniverseRoute<HelloPage>(new HelloPage(location));
	}
}
