package db;
import sys.db.Object;
import sys.db.Types;
/**
 * Distrib
 */
class Distribution extends Object
{
	public var id : SId;	
	
	@:relation(contractId)
	public var contract : Contract;
	
	@formPopulate("placePopulate")
	@:relation(placeId)
	public var place : Place;
	
	public var text : SNull<SString<1024>>;
	
	public var date : SDateTime; //debut
	public var end : SDateTime;	//fin
	
	@:relation(distributionCycleId)
	public var distributionCycle : SNull<DistributionCycle>;
	public var distributionCycleId: SNull<SInt>;
	
	@formPopulate("populate") @:relation(distributor1Id) public var distributor1 : SNull<db.User>; public var distributor1Id : SNull<SInt>;
	@formPopulate("populate") @:relation(distributor2Id) public var distributor2 : SNull<db.User>; public var distributor2Id : SNull<SInt>;
	@formPopulate("populate") @:relation(distributor3Id) public var distributor3 : SNull<db.User>; public var distributor3Id : SNull<SInt>;
	@formPopulate("populate") @:relation(distributor4Id) public var distributor4 : SNull<db.User>; public var distributor4Id : SNull<SInt>;
	
	
	public function new() 
	{
		super();
		date = Date.now();
		end = DateTools.delta(date, 1000 * 60 * 90);
	}
	
	public function populate():Array<{key:String,value:String}> {
		return App.current.user.getAmap().getMembersFormElementData();
	}
	
	public function placePopulate():Array<{key:String,value:String}> {
		var out = [];
		var places = db.Place.manager.search($amapId == App.current.user.amap.id, false);
		for (p in places) out.push( { key:Std.string(p.id),value:p.name } );
		return out;
	}
	
	public function hasEnoughDistributors() {
		var n = contract.distributorNum;
		
		var d = 0;
		if (distributor1 != null) d++;
		if (distributor2 != null) d++;
		if (distributor3 != null) d++;
		if (distributor4 != null) d++;
		
		return (d >= n) ;
	}
	
	public function isDistributor(u:User) {
		if (u == null) return false;
		return (u.id == distributor1Id) || (u.id == distributor2Id) || (u.id == distributor3Id) || (u.id == distributor4Id);
	}
	
	override public function toString() {
			return "Distribution du " + date.toString()+" de "+contract.name;
	}
	
}