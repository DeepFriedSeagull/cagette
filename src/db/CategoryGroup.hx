package db;
import sys.db.Types;


class CategoryGroup extends sys.db.Object
{
	
	public var id : SId;
	public var name : SString<32>;
	public var color : STinyInt; //id de couleur
	
	
	@:relation(amapId) public  var amap:db.Amap;
	#if neko
	public var amapId:SInt; 
	#end
	
	
	@:skip public static var COLORS = [
		0x7BAD1C, //vert clair
		0x007700, //vert foncé
		0x583816, //marron
		0xD97801, //orange carotte
		0xB1933D, //sable
		0xC91F25, //rouge
		0x6F0D2E, //vin
		0x616161, //gris
	];
	
	public function getCategories() {
		return db.Category.manager.search($categoryGroup == this, false);
	}
	
	public static function get(amap:db.Amap) {
		return manager.search($amap == amap, false);
	}
}