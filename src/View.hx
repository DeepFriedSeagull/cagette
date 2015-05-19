using Std;
import Common;

class View extends sugoi.BaseView {
	public function new() {
		super();
		this.Std = Std;
		this.Date = Date;
		this.Web = neko.Web;
	}
	
	public function count(i) {
		return Lambda.count(i);
	}
	
	/**
	 * newline to <br/>
	 * @param	txt
	 */
	public function nl2br(txt:String):String {	
		return txt.split("\n").join("<br/>");		
	}
	
	override function init() {
		super.init();		
	}
	
	
	/**
	 * Round a number to r digits after coma.
	 * 
	 * @param	n
	 * @param	r
	 */
	public function roundTo(n:Float, r:Int):Float {
		return Math.round(n * Math.pow(10,r)) / Math.pow(10,r) ;
	}
	
	
	public function color(id:Int) {
		if (id == null) throw "color cant be null";
		//try{
			return intToHex(db.CategoryGroup.COLORS[id]);
		//}catch (e:Dynamic) return "#000000";
	}
	
	/**
	 * convert a RVB color from Int to Hexa
	 * @param	c
	 * @param	leadingZeros=6
	 */
	public function intToHex(c:Int, ?leadingZeros=6) {
		var h = StringTools.hex(c);
		while (h.length<leadingZeros)
			h="0"+h;
		return "#"+h;
	}
	
	public function formatNum(n:Float):String {
		//arrondi a 2 apres virgule
		var out  = Std.string(roundTo(n, 2));		
		
		//ajout un zéro, 1,8-->1,80
		if (out.indexOf(".")!=-1 && out.split(".")[1].length == 1) out = out +"0";
		
		//virgule et pas point
		return out.split(".").join(",");
	}
	
	public function isToday(d:Date) {
		var n = Date.now();
		return d.getDate() == n.getDate() && d.getMonth() == n.getMonth() && d.getFullYear() == n.getFullYear();
	}
	
	/**
	 * human readable date 
	 * @param	date
	 */
	public function hDate(date:Date):String {
		if (date == null) return "aucune date";
		
		var days = ["Dimanche","Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"];
		var months = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Aout", "Septembre", "Octobre", "Novembre", "Décembre"];
		
		var out = days[date.getDay()] + " " + date.getDate() + " " + months[date.getMonth()];
		/*if ( date.getFullYear() != Date.now().getFullYear())*/ out += " " + date.getFullYear();
		if ( date.getHours() != 0 || date.getMinutes() != 0) out += " à " + StringTools.lpad(Std.string(date.getHours()), "0", 2) + ":" + StringTools.lpad(Std.string(date.getMinutes()), "0", 2);
		return out;
	}
	
	public function getDate(date:Date) {
		if (date == null) throw "date is null";
		
		var days = ["DIMANCHE","LUNDI", "MARDI", "MERCREDI", "JEUDI", "VENDREDI", "SAMEDI"];
		var months = ["JANVIER", "FEVRIER", "MARS", "AVRIL", "MAI", "JUIN", "JUILLET", "AOUT", "SEPTEMBRE", "OCTOBRE", "NOVEMBRE", "DECEMBRE"];
		
		return {
			dow: days[date.getDay()],
			d : date.getDate(),
			m: months[date.getMonth()],
			y: date.getFullYear(),			
			h: StringTools.lpad(Std.string(date.getHours()),"0",2),
			i: StringTools.lpad(Std.string(date.getMinutes()),"0",2)
		};
	}
	
	public function getProductImage(e):String {
		
		return Std.string(e).substr(2).toLowerCase()+".png";
	}
}
