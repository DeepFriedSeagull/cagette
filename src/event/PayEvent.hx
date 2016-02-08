package event;
import Common;
/**
 * Event related to payment
 */
class PayEvent extends Event
{
	
	//payment plugins
	public var nav : Array<Link>;
	
	
	public function new() 
	{
		nav = [];
		super();
	}
	
}