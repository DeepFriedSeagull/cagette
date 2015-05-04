import Common;

/**
 * ...
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Cart
{

	public var products : Map<Int,ProductInfo>; //full product list
	public var order : Order;
	
	public function new() 
	{
		products = new Map();
		order = { token:"", products:[] };
	}
	

	
	public function add(pid:Int) {
		
		for ( p in order.products) {
			if (p.productId == pid) {
				p.quantity++;
				render();
				return;
			}
		}
		
		order.products.push( { productId:pid, quantity:1 } );
		render();
	}
	
	function render() {
		var c = App.j("#cart");
		c.empty();
		
		c.append( Lambda.map(order.products, function( x ) {
			var p = products.get(x.productId);
			if (p == null) trace("cant find product " + x.productId + " in " + products);
			var btn = "<a onClick='cart.remove(" + p.id + ")' class='btn btn-default btn-xs'><span class='glyphicon glyphicon-remove'></span></a>&nbsp;";
			return "<div class='order'>"+btn + "<b>" + x.quantity + "</b> x " + p.name+" </div>";
		}).join("\n") );
		
		
		//compute totale price
		var total = 0.0;
		for (p in order.products) {
			var pinfo = products.get(p.productId);
			total += p.quantity * pinfo.price;
		}
		var ffilter = new sugoi.form.filters.FloatFilter();
		
		var total = ffilter.filter(Std.string(App.roundTo(total,2)));
		c.append("<div class='total'>TOTAL : "+total+"€</div>");
	}
	
	public function submit() {
		
	}
	
	public function remove(pid:Int ) {
		for ( p in order.products.copy()) {
			if (p.productId == pid) {
				order.products.remove(p);
				render();
				return;
			}
		}
	}
	
	/**
	 * loads products
	 */
	public function init() {
		var req = new haxe.Http("/shop/products");
		req.onData = function(data) {
			//broken in haxe 3.2rc , "Reflect is not defined"
			
			//var pr : Array<ProductInfo> = haxe.Unserializer.run(data);
			//trace(pr);
			////for (p in products) {
				////trace(p);
			////}
			
			var list : Array<ProductInfo> = haxe.Json.parse(data);
			for (p in list) {
				var id : Int = p.id;
				products.set(id, p);
			}
			trace(products);
		}
		req.request();
		
	}
	
}