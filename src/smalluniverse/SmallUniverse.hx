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
		monsoonApp.use(new SULogMiddleware());
	}

	public function addPage<T>(route:String, pageToUse:LazyUniversalPage) {
		app.use(route, function (req:Request<T>, res:Response) {
			var page = pageToUse();
			@:privateAccess page.params = req.params;
			page.route(req, res);
		});
	}
}
