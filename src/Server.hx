import monsoon.Monsoon;
import smalluniverse.SmallUniverse;

class Server {
	static function main() {
		var app = new Monsoon();
		var smallUniverse = new SmallUniverse(app);
		smallUniverse.addPage('/', HelloPage);
		smallUniverse.addPage('/about', AboutPage);
		app.listen(3000);
	}
}
