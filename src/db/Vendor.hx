package db;
import sys.db.Object;
import sys.db.Types;
/**
 * Vendor (producteur)
 */
class Vendor extends Object
{
	public var id : SId;
	public var name : SString<32>;
	
	public var email : STinyText;
	public var phone:SNull<SString<19>>;
		
	public var address1:SNull<SString<64>>;
	public var address2:SNull<SString<64>>;
	public var zipCode:SString<32>;
	public var city:SString<25>;
	
	public var desc : SNull<SText>;
	
	public var linkText:SNull<SString<256>>;
	public var linkUrl:SNull<SString<256>>;
	
	@hideInForms @:relation(imageId) public var image : SNull<sugoi.db.File>;
	
	@:relation(amapId) public var amap : SNull<Amap>;
	
	public function new() 
	{
		super();
		name = "Producteur";
	}
	
	override function toString() {
		return name;
	}
	
}