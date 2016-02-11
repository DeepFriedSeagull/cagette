package db;
import sys.db.Types;

class TourAttendee extends sys.db.Object
{

	public var id  : SId;
	public var name : SString<256>;
	public var email : SString<256>;
	public var group : SString<256>;
	public var dept : SString<12>;
	public var phone : SString<256>;
	
	
}