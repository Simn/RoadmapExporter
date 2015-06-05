package github;

typedef Label = { url:String, name:String, color:String };
typedef User = { login:String, id:Int, avatar_url:String, gravatar_id:String, url:String };
typedef Milestone = { url:String, number:Int, state:String, title:String, description:String, creator:User, open_issues:Int, closed_issues:Int, created_at:String, due_on:Null<String> };

typedef Issue = {
	url:String,
	html_url:String,
	number:Int,
	state:String,
	title:String,
	body:String,
	user:User,
	labels:Array<Label>,
	assignee:User,
	milestone:Milestone,
	comments:Int,
	pull_request: { html_url:String, diff_url:String, patch_url:String },
	closed_at: Null<String>,
	created_at:String,
	updated_at:String
}

typedef File = {
	sha: String,
	path: String,
}

typedef PutRequestData = {url: String, data: Dynamic};

abstract GetRequest<T>(String) from String to String { }

@:forward
abstract PutRequest<T>(PutRequestData) from PutRequestData to PutRequestData { }