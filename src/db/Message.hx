package db;
import sys.db.Object;
import sys.db.Types;
 
class Message extends Object
{

	public var id : SId;

	@:relation(senderId) public var sender : User;
	@:relation(amapId) public var amap : Amap;
	public var recipientListId : SString<12>;
	public var title : SString<128>;
	public var body : SText;
	
	public var date : SDateTime;
	
	
}