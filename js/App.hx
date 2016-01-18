import js.JQuery;
//import js.SWFObject;

class App {
	
	function new() {
	}

	public static inline function j(r:Dynamic) {
		return new JQuery(r);
	}

	public static function main() {		
		untyped js.Browser.window._ = new App();
	}
	
	public function getCart() {
		return new Cart();
	}
	
	public function getTagger(cid:Int ) {
		return new Tagger(cid);
	}
	
	
	public static function roundTo(n:Float, r:Int):Float {
		return Math.round(n * Math.pow(10,r)) / Math.pow(10,r) ;
	}
	
	//public function __overlay(url:String) {
	//
		//App.j("body").append("<div class='overlayBackground' onclick='_.closeOverlay()'></div>");
		//
		//var r = new haxe.Http(url);
		//r.onData = function(data) {
			//App.j("body").append("<div class='overlayContent' >" + data + "<a class='btn btn-default' onclick='_.closeOverlay()'><span class='glyphicon glyphicon-remove'></span> Fermer</a></div>");
			//
		//}
		//r.request();
	//}
	
	/**
	 * Ajax loads a page and display it in a modal window
	 * @param	url
	 * @param	title
	 */
	public function overlay(url:String,?title,?large=true) {
	
		
		var r = new haxe.Http(url);
		r.onData = function(data) {
			
			//setup body and title
			var m = App.j("#myModal");
			m.find(".modal-body").html(data);			
			if (title != null) m.find(".modal-title").html(title);
			
			if (!large) m.find(".modal-dialog").removeClass("modal-lg");
			
			
			untyped App.j('#myModal').modal(); //bootstrap 3 modal window
			
		}
		r.request();
	}
	
	//public function closeOverlay() {
		//App.j(".overlayContent").remove();
		//App.j(".overlayBackground").remove();
	//}
	
	
}
