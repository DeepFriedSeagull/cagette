import Common;
import js.JQuery;
/**
 * JS Shopping Cart
 * 
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Cart
{

	public var products : Map<Int,ProductInfo>; //full product list
	public var order : Order;
	
	var loader : JQuery; //ajax loader gif
	
	//for scroll mgmt
	var cartTop : Int;
	var cartLeft : Int;
	var cartWidth : Int;
	var jWindow : JQuery;
	var cartContainer : JQuery;
	
	
	public function new() 
	{
		products = new Map();
		order = { products:[] };
	}
	

	
	public function add(pid:Int) {
		loader.show();
		
		var q = App.j('#productQt' + pid).val();
		var qt = 0.0;
		var p = products.get(pid);
		if (p.hasFloatQt) {
			q = StringTools.replace(q, ",", ".");
			qt = Std.parseFloat(q);
		}else {
			qt = Std.parseInt(q);			
		}
		
		if (qt == null) {
			qt = 1;
		}
		//trace("qté : "+qt);
		
		//add server side
		var r = new haxe.Http('/shop/add/$pid/$qt');
		
		r.onData = function(data:String) {
			
			loader.hide();
			
			var d = haxe.Json.parse(data);
			if (!d.success) js.Browser.alert("Erreur : "+d);
			
			//add locally
			subAdd(pid, qt);
			render();
			
			
		}
		r.request();
		
	}
	
	
	function subAdd(pid, qt:Float ) {
	
		for ( p in order.products) {
			if (p.productId == pid) {
				p.quantity += qt;
				render();
				return;
			}
		}
			
		order.products.push( { productId:pid, quantity:qt } );
	}
	
	function render() {
		var c = App.j("#cart");
		c.empty();
		
		c.append( Lambda.map(order.products, function( x ) {
			var p = products.get(x.productId);
			if (p == null) js.Browser.alert("Cant find product " + x.productId + " in " + products);
			
			var btn = "<a onClick='cart.remove(" + p.id + ")' class='btn btn-default btn-xs' data-toggle='tooltip' data-placement='top' title='Retirer de la commande'><span class='glyphicon glyphicon-remove'></span></a>&nbsp;";
			return "<div class='row'> 
				<div class = 'order col-md-9' > <b> " + x.quantity + " </b> x " + p.name+" </div>
				<div class = 'col-md-3'> "+btn+"</div>			
			</div>";
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
		var req = new haxe.Http("/shop/submit");
		req.onData = function(d) {
			js.Browser.location.href = "/shop/validate";
			
		}
		req.addParameter("data", haxe.Json.stringify(order));
		req.request(true);
		
	}
	
	/**
	 * filter products by category
	 */
	public function filter(cat:Int) {
		
		//icone sur bouton
		App.j(".tag").removeClass("active").children().remove("span");//clean
		
		var bt = App.j("#tag" + cat);
		bt.addClass("active").prepend("<span class ='glyphicon glyphicon-ok'></span> ");
		
		
		//affiche/masque produits
		for (p in products) {
			if (cat==0 || Lambda.has(p.categories, cat)) {
				App.j("#product" + p.id).fadeIn(300); 
			}else {
				App.j("#product" + p.id).fadeOut(300); 
			}
		}
		
		
		
		
	}
	
	/**
	 * remove a product from cart
	 * @param	pid
	 */
	public function remove(pid:Int ) {
		
		loader.show();
		
		//add server side
		var r = new haxe.Http('/shop/remove/$pid');
		
		r.onData = function(data:String) {
			
			loader.hide();
			
			var d = haxe.Json.parse(data);
			if (!d.success) js.Browser.alert("Erreur : "+d);
			
			//remove locally
			for ( p in order.products.copy()) {
				if (p.productId == pid) {
					order.products.remove(p);
					render();
					return;
				}
			}
			render();
			
			
		}
		r.request();
		
		
		
		
	}
	
	/**
	 * loads products
	 */
	public function init() {
		
		loader = App.j("#cartContainer #loader");
		
		var req = new haxe.Http("/shop/init");
		req.onData = function(data) {
			loader.hide();
			
			var data : { products:Array<ProductInfo>,order:Order } = haxe.Json.parse(data);
			for (p in data.products) {
				var id : Int = p.id;
				products.set(id, p);
			}
			
			for ( p in data.order.products) {
				subAdd(p.productId,p.quantity );
			}
			render();
			
		}
		req.request();
		
		//scroll mgmt
		/*jWindow = App.j(js.Browser.window);
		cartContainer = App.j("#cartContainer");
		//cartTop = cartContainer.position().top;
		cartLeft = cartContainer.position().left;
		cartWidth = cartContainer.width();
		jWindow.scroll(onScroll);*/
		
	}
	
	/**
	 * keep the cart on top when scrolling
	 * @param	e
	 */
	public function onScroll(e:Dynamic) {
		
		//cart container top position		
		
		if (jWindow.scrollTop() > cartTop) {
			//trace("absolute !");
			cartContainer.addClass("scrolled");
			cartContainer.css('left', Std.string(cartLeft) + "px");			
			cartContainer.css('top', Std.string(cartTop) + "px");
			cartContainer.css('width', Std.string(cartWidth) + "px");
			
		}else {
			cartContainer.removeClass("scrolled");
			cartContainer.css('left',"");
			cartContainer.css('top', "");
			cartContainer.css('width', "");
		}
		
		
		
	}
	
}