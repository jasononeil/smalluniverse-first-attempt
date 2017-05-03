package smalluniverse;

import smalluniverse.UniversalPage;

/**
A "Lazy" function that allows us to get a UniversalPage object when we need it.
We use this when setting up our app, so we can describe which pages correspond to which routes, without creating the page objects ahead of time.

You can pass in:

- A `UniversalPage` object directly.
- A `Class<UniversalPage>` that will be constructed with `new MyPage()`.
- A `Void->UniversalPage` function that will return a UniversalPage instance.

It is designed so that it can work with simple pages as is, or work an injection system.
For example, with [dodrugs](https://github.com/jasononeil/dodrugs) you could use:

	var lazyPage:LazyUniversalPage = function () return injector.get(SignupPage);
**/
@:callable
abstract LazyUniversalPage(Void->UniversalPage<Dynamic,Dynamic,Dynamic>) {
	function new(fn) {
		this = fn;
	}

	@:from public static function fromClass<T:UniversalPage<Dynamic,Dynamic,Dynamic>>(cls:Class<T>) {
		return new LazyUniversalPage(function () return Type.createInstance(cls, []));
	}

	@:from public static function fromPage(page:UniversalPage<Dynamic,Dynamic,Dynamic>) {
		return new LazyUniversalPage(function () return page);
	}

	@:from public static function fromFn(getPage:Void->UniversalPage<Dynamic,Dynamic,Dynamic>) {
		return new LazyUniversalPage(getPage);
	}
}
