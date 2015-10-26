package db;
import sys.db.Types;

@:id(productId,categoryId)
class ProductCategory extends sys.db.Object
{
	
	@:relation(productId)
	public var product : db.Product;
	public var productId : SInt;
	
	@:relation(categoryId)
	public var category : db.Category;
	public var categoryId : SInt;
}