import monsoon.Monsoon;
import smalluniverse.SmallUniverse;
import dodrugs.Injector;

class Server {
	static function main() {
		var app = new Monsoon();
		var smallUniverse = new SmallUniverse(app, null);
		smallUniverse.addPage('/', function () return new HelloPage());
		smallUniverse.addPage('/about', function () return new AboutPage());
		app.listen(3000);
	}
}
