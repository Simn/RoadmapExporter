package github;
import github.Types;

import haxe.Http;
import haxe.Json;
import haxe.io.Path;
import haxe.ds.Either;

class ApiConnection {
	var apiUrl:String;
	var token:String;

	public function new(apiUrl:String, token:String) {
		this.apiUrl = apiUrl;
		this.token = token;
	}

	public function put<T>(r:PutRequest<T>):Either<T, String> {
		return doRequest(Path.join([apiUrl, r.url]), customRequest.bind(_, true, "PUT"), r.data);
	}

	public function get<T>(s:GetRequest<T>):Either<T, String> {
		return doRequest(Path.join([apiUrl, s]), request.bind(_, false));
	}

	function doRequest<T>(url:String, f:Http->Void, ?data = null):Either<T, String> {
		var http = new Http(url);
		if (data != null) {
			http.setPostData(data);
		}
		var isError:Null<Bool> = null, msg = null;
		http.onData = function (s) { isError = false; msg = s; };
		http.onError = function (s) { isError = true; msg = s; };
		f(http);
		if (isError) {
			return Right(msg);
		} else {
			return Left(Json.parse(msg));
		}
	}

	function request(http:Http, post:Bool) {
		setAuth(http);
		http.request(post);
	}

	function customRequest(http:Http, post:Bool, method:String) {
		setAuth(http);
		var output = new haxe.io.BytesOutput();
		var err = false;
		var old = http.onError;
		http.onError = function(e) {
			#if neko
			untyped http.responseData = neko.Lib.stringReference(output.getBytes());
			#else
			untyped http.responseData = output.getBytes().toString();
			#end
			err = true;
			old(e);
		}
		http.customRequest(post,output, null, method);
		if( !err )
		#if neko
			untyped http.onData(http.responseData = neko.Lib.stringReference(output.getBytes()));
		#else
			untyped http.onData(http.responseData = output.getBytes().toString());
		#end
	}

	function setAuth(http:Http) {
		http.setHeader("User-Agent", "curl/7.27.0");
		http.setHeader("Authorization", 'token $token');
	}
}