package event;
import Common;
/**
 * ...
 * @author fbarbut<francois.barbut@gmail.com>
 */
class NavEvent extends Event
{
	public var nav : Array<Link>;
	
	public function new() 
	{
		nav = [];
		super();
	}
	
}