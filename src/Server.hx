import monsoon.Monsoon;
import smalluniverse.SmallUniverse;
import dodrugs.Injector;

class Server {
	static function main() {
		var app = new Monsoon();
		var injector = Injector.create('smalluniverse', [
			HelloPage
		]);
		var smallUniverse = new SmallUniverse(app, injector);
		smallUniverse.addPage('/', HelloPage);
		app.listen(3000);
	}
}
