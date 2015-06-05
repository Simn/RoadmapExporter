package github;

import github.Types;
import haxe.Json;

@:enum abstract IssueFilter(String) {
	var Assigned = "assigned";
	var Created = "created";
	var Mentioned = "mentioned";
	var Subscribed = "subscribed";
	var All = "all";
}

@:enum abstract IssueState(String) {
	var Open = "open";
	var Closed = "closed";
	var All = "all";
}

@:enum abstract IssueSort(String) {
	var Created = "created";
	var Updated = "updated";
	var Comments = "comments";
}

@:enum abstract IssueDirection(String) {
	var Asc = "asc";
	var Desc = "desc";
}

enum IssueOption<T> {
	None;
	All;
	Some(s:T);
}

typedef IssueParameters = {
	?milestone: IssueOption<Int>,
	?assignee: IssueOption<String>,
	?creator: String,
	?filter: IssueFilter,
	?state: IssueState,
	?labels: Array<String>,
	?sort: IssueSort,
	?direction: IssueDirection,
	?since: String // TODO?
}

class Api {

	public var repository(default, null):String;
	public var owner(default, null):String;

	public function new() { }

	public function enterRepository(owner:String, repository:String) {
		this.owner = owner;
		this.repository = repository;
	}

	public function listIssues(parameters:IssueParameters):GetRequest<Array<Issue>> {
		var options = [];
		switch (parameters.milestone) {
			case null:
			case None: options.push("milestone=none");
			case All: options.push("milestone=*");
			case Some(i): options.push("milestone=" + Std.string(i));
		}
		if (parameters.labels != null) {
			options.push("labels=" + parameters.labels.join(","));
		}
		switch (parameters.state) {
			case null:
			case Open: options.push("state=open");
			case Closed: options.push("state=closed");
			case All: options.push("state=all");
		}
		// TODO: other stuff
		var s = '/repos/$owner/$repository/issues';
		if (options.length > 0) {
			s += "?";
			s += options.join("&");
		}
		return s;
	}

	public function getDirectory(path:String):GetRequest<Array<File>> {
		return '/repos/$owner/$repository/contents/$path';
	}

	public function getFile(path:String):GetRequest<File> {
		return '/repos/$owner/$repository/contents/$path';
	}

	public function updateFile(file:File, content:String, commitMessage:String):PutRequest<Dynamic> { // Not sure what this returns
		var content = haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(content));
		var s = '/repos/$owner/$repository/contents/${file.path}';
		var data = Json.stringify({
			"content": content,
			"message": commitMessage,
			"sha": file.sha
		});
		return {
			url: s,
			data: data
		}
	}
}