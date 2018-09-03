package smalluniverse;

/**
	This typedef represents the extra information an API response can pass to the client.

	Browsers cannot easily read HTTP headers or other metadata during a `fetch` call, so we've chosen to bundle information in the JSON packet.

	- If `redirect` is present, the client will redirect the window to the given URL.
	- If `messages` is present, the client will log the values of each message to the developer console.
	- Each message is an array of strings to print out. The strings should be valid JSON.
	- They will be decoded using `haxe.Json.parse` before being logged to the console.
	- If the `__smallUniverse` property is optional and should only be used if there is an instruction from the API.
**/
typedef SUApiResponseInstructions = {
	?__smallUniverse:{
		?redirect:Null<String>,
		?messages:Array<Array<String>>
	}
};
