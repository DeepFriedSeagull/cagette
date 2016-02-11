package;

/**
 * Small Tutorial utility class
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Tutorial
{

	public function new() 
	{
		
	}
	
	public static function all() {
		return ["amap", "group"];
	}
	
	public static function getStepNum(tuto:String):Int {
		return switch tuto {
			case "amap" : 9;
			case "group" : 4;
			default : null;
			
		}
		
	}
	
	public static function getName(tuto:String):String {
		return switch tuto {
			case "amap" : "Premier contrat AMAP";
			case "group" : "Première commande groupée";
			default : null;
			
		}
		
	}
	
}