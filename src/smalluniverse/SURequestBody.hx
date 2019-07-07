package smalluniverse;

/**
	A typedef representing what an action POST request looks like.

	This is only needed as tink_web currently gives an error:

	> `body` is not used. Please specify its use with the @:params metadata or capture it in the route paths

	if we try to use an enum directly as the request body. Using the enum as a field in a typedef works fine.
**/
typedef SURequestBody<Action> = {
	action:Action
}
