import js.JQuery;
//import js.SWFObject;

class App {
	
	function new() {
	}

	public static inline function j(r:String) {
		return new JQuery(r);
	}

	public static function main() {		
		untyped js.Browser.window._ = new App();
	}
	
	public function getCart() {
		return new Cart();
	}
	
	
	public static function roundTo(n:Float, r:Int):Float {
		return Math.round(n * Math.pow(10,r)) / Math.pow(10,r) ;
	}
	
	public function overlay(url:String) {
	
		App.j("body").append("<div class='overlay background'></div>");
		
		var r = new haxe.Http(url);
		r.onData = function(data) {
			App.j("body").append("<div class='overlay'><div class='overlayContent'>" + data + "<a class='btn btn-default' onclick='_.closeOverlay()'><span class='glyphicon glyphicon-remove'></span> Fermer</a></div></div>");
			
		}
		r.request();
	}
	
	public function closeOverlay() {
		App.j(".overlay").remove();
	}
	
	
}
