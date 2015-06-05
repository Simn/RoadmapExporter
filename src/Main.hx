import github.Api;
import github.Types;
using StringTools;

class Main {
	static function main() {
		// Parse arguments because we need an access token
		var accessToken = null;
		var handler = hxargs.Args.generate([
			@doc("The OAuth access token to use")
			"-token" => function(token:String) {
				accessToken = token;
			}
		]);
		var args = Sys.args();
		if (args.length == 0) {
			Sys.println(handler.getDoc());
			Sys.exit(0);
		}
		handler.parse(args);
		if (accessToken == null) {
			Sys.println("Missing -token command");
			Sys.exit(1);
		}

		// Create connection
		var request = new github.ApiConnection("https://api.github.com", accessToken);

		// Create the API and get to the right repository
		var api = new Api();
		api.enterRepository("HaxeFoundation", "Haxe");
		// Build the request string
		var requestString = api.listIssues({labels: ["roadmap"], state: All});
		// Request it
		var roadmapIssues = switch (request.get(requestString)) {
			case Left(issues): issues;
			case Right(s): throw 'Error while requesting $requestString: $s';
		}

		// Generate roadmap markdown
		var roadmapContent = generate(roadmapIssues);

		// Edit!
		api.enterRepository("HaxeFoundation", "haxe.org");
		var file = switch (request.get(api.getFile("www/website-content/pages/community/roadmap.html"))) {
			case Left(file): file;
			case Right(s): throw s;
		}
		switch (request.put(api.updateFile(file, roadmapContent, "Regenerate roadmap"))) {
			case Left(_):
			case Right(s): throw s;
		}
	}

	static function generate(issues:Array<Issue>) {
		issues.sort(function (issue1, issue2) return Reflect.compare(issue1.milestone.title, issue2.milestone.title));
		var currentMilestoneName = "";

		var output = new StringBuf();

		for (issue in issues) {
			if (issue.milestone.title != currentMilestoneName) {
				if (currentMilestoneName != "") {
					output.add("</div>\n");
				}
				currentMilestoneName = issue.milestone.title;
				var cssClass = issue.milestone.state == "closed" ? "closed" : "open";
				output.add('<div class="milestone">\n<h2 class="$cssClass">${issue.milestone.title} (${monthDate(issue.milestone.due_on)})</h2>\n\n');
			}

			var cssClass = "alert alert-danger";
			if (issue.state == "closed") {
				cssClass = "alert alert-success";
			}
			output.add('<div class="well well-small"><h3 class="$cssClass">');
			output.add('<a href="${issue.html_url}">');
			output.add(issue.title);
			output.add('</a></h3>\n');
			output.add("<dl>\n\t<dt>Status:</dt>\n\t<dd>");
			if (issue.state == "closed") {
				output.add("Closed " +monthDate(issue.closed_at));
			} else {
				output.add("Open since " +monthDate(issue.created_at));
				for (label in issue.labels) {
					if (label.name.startsWith("roadmap-")) {
						output.add(" (" +label.name.substr(8)+ ")");
					}
				}
			}
			output.add("</dd>\n\t");

			var body = issue.body.split("----------")[0].trim();
			body = Markdown.markdownToHtml(body);
			output.add("<dt>Description</dt>\n\t<dd>");
			output.add(body);
			output.add("</dd>\n</div>\n");
		}

		output.add("</div>\n");

		return output.toString();
	}

	static function monthDate(s:String) {
		var date = Date.fromString(s.substr(0, 10));
		return DateTools.format(date, "%B %Y");
	}
}