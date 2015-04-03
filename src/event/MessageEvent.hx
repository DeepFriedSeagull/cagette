package event;
import Types;
/**
 * Event pour les envois d'emails ou SMS
 * @author fbarbut<francois.barbut@gmail.com>
 */
class MessageEvent extends Event
{
	public var message : sugoi.mail.IMail; 
	
	public function new() 
	{
		
		super();
	}
	
}