package db;
import sys.db.Object;
import sys.db.Types;
class Place extends Object
{

	public var id : SId;
	public var name : SString<64>;
	public var address1:SNull<SString<64>>;
	public var address2:SNull<SString<64>>;
	public var zipCode:SString<32>;
	public var city:SString<25>;
	
	@hideInForms @:relation(amapId) public var amap : Amap;
	
	
	public function new() 
	{
		super();
	}
	
	override function toString() {
		if (name == null) {
			return "place";
		}else {			
			return name;
		}
	}
	
}