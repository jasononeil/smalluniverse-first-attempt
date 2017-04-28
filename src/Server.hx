import monsoon.Monsoon;
import smalluniverse.SmallUniverse;
import dodrugs.Injector;

class Server {
	static function main() {
		var app = new Monsoon();
		var injector = Injector.create('smalluniverse', [
			HelloPage,
			AboutPage
		]);
		var smallUniverse = new SmallUniverse(app, injector);
		smallUniverse.addPage('/', function () return injector.get(HelloPage));
		smallUniverse.addPage('/about', function () return injector.get(AboutPage));
		app.listen(3000);
	}
}
