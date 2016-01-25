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
	
	//start and end date for open orders
	@hideInForms public var orderStartDate : SNull<SDateTime>; 
	@hideInForms public var orderEndDate : SNull<SDateTime>;
	
	//start and end date for delivery
	public var date : SDateTime; 
	public var end : SDateTime;
	//public var deliveryStartDate : SDateTime; 
	//public var deliveryEndDate : SDateTime;
	
	@:relation(distributionCycleId) public var distributionCycle : SNull<DistributionCycle>;
	#if neko 
	public var distributionCycleId: SNull<SInt>; 
	#end
	
	@formPopulate("populate") @:relation(distributor1Id) public var distributor1 : SNull<db.User>; 
	@formPopulate("populate") @:relation(distributor2Id) public var distributor2 : SNull<db.User>; 
	@formPopulate("populate") @:relation(distributor3Id) public var distributor3 : SNull<db.User>; 
	@formPopulate("populate") @:relation(distributor4Id) public var distributor4 : SNull<db.User>; 
	
	#if neko
	public var distributor1Id : SNull<SInt>;
	public var distributor2Id : SNull<SInt>;
	public var distributor3Id : SNull<SInt>;
	public var distributor4Id : SNull<SInt>;
	#end
	
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
	
	public function getOrders() {
	
		var pids = db.Product.manager.search($contract == this.contract, false);
		var pids = Lambda.map(pids, function(x) return x.id);
		var sql = "select u.firstName , u.lastName as uname, u.id as uid, p.name as pname ,u.firstName2 , u.lastName2, u.phone, u.email, up.* from User u, UserContract up, Product p where up.userId=u.id and up.productId=p.id and p.contractId=" + contract.id;
		if (contract.type == db.Contract.TYPE_VARORDER) {
			sql += " and up.distributionId=" + this.id;	
		}
		
		sql += " order by uname asc";
		return sys.db.Manager.cnx.request(sql).results();
		
	}
	
	
	public function canOrder() {
		
		if (orderEndDate == null) {
			return this.contract.isUserOrderAvailable();
		}else {
			var n = Date.now().getTime();
			return n < orderEndDate.getTime() && n > orderStartDate.getTime();
			
		}
		
		
		
	}
	
}