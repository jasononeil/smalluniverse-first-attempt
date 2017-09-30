import monsoon.Monsoon;
import monsoon.middleware.Static;
import smalluniverse.SmallUniverse;

class Server {
	static function main() {
		var app = new Monsoon();
		app.use('/js', Static.serve('js'));
		var smallUniverse = new SmallUniverse(app);
		smallUniverse.addPage('/about', AboutPage);
		smallUniverse.addPage('/:location?', HelloPage);
		app.listen(3000);
	}
}
