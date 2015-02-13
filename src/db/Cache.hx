package db;
import sys.db.Object;
import sys.db.Types;

/**
 * stocke des données serialisée par une id string 
 */
@:id(name)
class Cache extends Object
{
	public var name : SString<32>;
	public var value : SText;
	public var expire : SDateTime;
	
	public static function get(id:String):Dynamic {
		if (Std.random(1000) == 0) Cache.manager.delete($expire < Date.now());
		
		var c = manager.get(id, true);
		if (c == null) return null;
		if (c.expire.getTime() < Date.now().getTime()) return null;
		return haxe.Unserializer.run(c.value);
	}
	
	public static function set(id:String, value:Dynamic,expireInSeconds:Float) {
		var c = manager.get(id, true);
		var niou = false;
		if (c == null) {
			niou = true;
			c = new Cache();			
			c.name = id;
		}
		c.value = haxe.Serializer.run(value);
		c.expire = DateTools.delta(Date.now(), expireInSeconds*1000);
		if (niou) {
			c.insert();
		}else {
			c.update();
		}
	}
	
	
}