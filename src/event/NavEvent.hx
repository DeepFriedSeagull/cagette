package event;
import Types;
/**
 * ...
 * @author fbarbut<francois.barbut@gmail.com>
 */
class NavEvent extends Event
{
	public var navId : String;
	public var nav : Array<Link>;
	
	public function new() 
	{
		nav = [];
		super();
	}
	
}