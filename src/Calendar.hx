package;

typedef CalEvent = {
	
	name:String,
	//start:Date,
	//end:Date,
	color:Int,
	
}

/**
 * Calendar utility
 * 
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Calendar
{
	
	public static var COLOR_CONTRACT = 0xC91F25;
	public static var COLOR_DELIVERY = 0x7BAD1C;
	public static var COLOR_ORDER = 0xFF9615;

	public function new() 
	{
		
	}
	
	public static function getMonthViewMap():Map<String,Array<CalEvent>> {
	
		var n = Date.now();
		var m = n.getMonth();//0-11
		var pointer = Date.now();
		
		var out = new Map<String,Array<CalEvent>>();
		
		//find last monday
		for ( i in 0...40) {
			if ( pointer.getDay() == 1 && pointer.getMonth() != m) {
				break;
			}
			pointer = DateTools.delta(pointer, -1000.0 * 60 * 60 * 24);
			
		}
		
		//go ahead for at least 27 days
		for ( i in 0...28) {
			pointer = DateTools.delta(pointer, 1000.0 * 60 * 60 * 24);	
			out.set( pointer.toString().substr(0, 10), [] );
		}
		
		//find end
		for ( i in 0...40) {
			if ( pointer.getDay() == 1 && pointer.getMonth() != m) break;
			out.set( pointer.toString().substr(0, 10), [] );
			pointer = DateTools.delta(pointer, 1000.0 * 60 * 60 * 24);
		}
		
		return out;
	}
	
	/**
	 * get ordered CalEvents from an unordered stringMap
	 */
	public static function mapToArray(input : Map<String,Array<CalEvent>>) : Array<{d:Date,events:Array<CalEvent>}> {
		
		var keys = [];
		for (k in input.keys()) keys.push(k);
		keys.sort(function(a, b) {
			return Math.round(Date.fromString(a).getTime()/1000) - Math.round(Date.fromString(b).getTime()/1000);
		});
		
		
		var out  = [];
		for ( k in keys) {
		
			var x = input.get(k);
			out.push( { d:Date.fromString(k),events:x } );
		}
		return out;
	}
	
}