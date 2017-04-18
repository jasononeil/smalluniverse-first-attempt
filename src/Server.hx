import monsoon.Monsoon;
import smalluniverse.SmallUniverse;

class Server {
	static function main() {
		var app = new Monsoon();
		var smallUniverse = new SmallUniverse(app);
		smallUniverse.addPage('/', HelloPage);
		app.listen(3000);
	}
}
