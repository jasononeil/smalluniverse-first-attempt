package smalluniverse;

import smalluniverse.SUServerSideComponent;
import smalluniverse.SUMacro.jsx;
import smalluniverse.LazyUniversalPage;
import monsoon.Request;
import monsoon.Response;
using StringTools;
using tink.CoreApi;

class SmallUniverse {

	public var app:Monsoon;

	public function new(monsoonApp:Monsoon) {
		this.app = monsoonApp;
	}

	public function addPage<T>(route:String, pageToUse:LazyUniversalPage<T>) {
		app.use(route, function (req:Request<T>, res:Response) {
			var page = pageToUse();
			@:privateAccess page.params = req.params;
			page.route(req, res);
		});
	}

	static function getArgsFromBody<T>(req:Request<T>):Promise<Map<String,String>> {
		switch req.body {
			case Plain(source):
				throw 'Expected multipart/form data';
			case Parsed(structuredBody):
				var params = new Map();
				for (part in structuredBody) {
					switch part.value {
						case Value(v):
							params[part.name] = v;
  						case File(handle):
						  	// TODO
					}
				}
				return params;
		}
	}
}
