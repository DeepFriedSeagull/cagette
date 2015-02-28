package db;
import sys.db.Object;
import sys.db.Types;

enum DayOfWeek {
	Monday;
	Tuesday;
	Wednesday;
	Thursday;
	Friday;
	Saturday;
	Sunday;
}

enum CycleType {
	Weekly;
	//BiWeekly;
	//TriWeekly;
	Monthly;
}


/**
 * Distrib récurrente
 */
class DistributionCycle extends Object
{
	public var id : SId;	
	
	@:relation(contractId) public var contract : Contract;
	@formPopulate("placePopulate") @:relation(placeId) public var place : Place;
	
	public var cycleType:SEnum<CycleType>;
	
	public var startDate : SDate; //debut
	public var endDate : SDate;	//fin de la recurrence

	public var startHour : SDateTime; 
	public var endHour : SDateTime;	
	
	public function new() {
		super();
	}
	
	/**
	 * on créé toutes les distribs en partant du jour de la semaine de la premiere date
	 */
	public static function updateChilds(dc:DistributionCycle) {
		
		var datePointer = dc.startDate;
		var dayOfWeek = dc.startDate.getDay();
		if (dc.id == null) throw "this distributionCycle has not been recorded";
		
		//first distrib
		var d = new Distribution();
		d.contract = dc.contract;
		d.distributionCycle = dc;
		d.place = dc.place;
		d.date = new Date(datePointer.getFullYear(), datePointer.getMonth(), datePointer.getDate(), dc.startHour.getHours(), dc.startHour.getMinutes(), 0);
		d.end = new Date(datePointer.getFullYear(), datePointer.getMonth(), datePointer.getDate(), dc.endHour.getHours(), dc.endHour.getMinutes(), 0);
		d.insert();
			
		//iterations
		for(i in 0...100) {
			
			var d = new Distribution();
			d.contract = dc.contract;
			d.distributionCycle = dc;
			d.place = dc.place;
			
			//date de la distrib
			var oneDay = 1000 * 60 * 60 * 24.0;
			switch(dc.cycleType) {
				case Weekly :
					datePointer = DateTools.delta(datePointer, oneDay * 7.0);
					App.log("datePointer : " + datePointer);
					
				case Monthly :
					datePointer = DateTools.delta(datePointer, oneDay * 28.0);
					App.log("monthly datePointer +28j : "+datePointer);
					while (datePointer.getDay() != dayOfWeek ) {
						
						datePointer = DateTools.delta(datePointer, oneDay);
						App.log("monthly datePointer +24h : "+datePointer);
					}
			}
			/*
			if (dc.cycleType == Weekly) {
				datePointer = DateTools.delta(datePointer, 1000 * 60 * 60 * 24 * 7.0);
				App.log("datePointer : "+datePointer);
			}else {
				
				datePointer = DateTools.delta(datePointer, 1000 * 60 * 60 * 24 * 28.0);
				App.log("monthly datePointer +28j : "+datePointer);
				while (datePointer.getDay() != dayOfWeek ) {
					
					datePointer = DateTools.delta(datePointer, 1000 * 60 * 60 * 24.0);
					App.log("monthly datePointer +24h : "+datePointer);
				}
			}*/
			
			if (datePointer.getTime() > dc.endDate.getTime()) {
				App.log("finish");
				break;
			}
			
			App.log(">>> date def : "+datePointer.toString());
			
			//applique heure de debut et fin
			d.date = new Date(datePointer.getFullYear(), datePointer.getMonth(), datePointer.getDate(), dc.startHour.getHours(), dc.startHour.getMinutes(), 0);
			d.end  = new Date(datePointer.getFullYear(), datePointer.getMonth(), datePointer.getDate(), dc.endHour.getHours(), dc.endHour.getMinutes(), 0);
			d.insert();
		}
	}
	
	public function placePopulate():Array<{key:String,value:String}> {
		var out = [];
		var places = db.Place.manager.search($amapId == App.current.user.amap.id, false);
		for (p in places) out.push( { key:Std.string(p.id),value:p.name } );
		return out;
	}
}