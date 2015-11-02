package event;
import Common;
/**
 * Event pour les envois d'emails ou SMS
 * @author fbarbut<francois.barbut@gmail.com>
 */
class MessageEvent extends Event
{
	public var message : ufront.mail.Email; 
	
	public function new() 
	{
		
		super();
	}
	
}