class CombineItemsInCart < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up do
        # replace multiple items for a single product in a cart with a single item
        Cart.all.each do |cart|
          # count the number of each product in the cart
          sums = cart.line_items.group(:product_id).sum(:quantity)

          sums.each do |product_id, quantity|   # {101=>14, 102=>4, 103=>2, 104=>1, 106=>2}
            if quantity > 1
              # remove individual items
              cart.line_items.where(:product_id => product_id).delete_all

              # replace with a single item
              cart.line_items.create(:product_id => product_id, :quantity => quantity)
            end
          end
        end
      end
      dir.down do
        # split items with quantity > 1 into multiple items
        LineItem.where('quantity > 1').each do |line_item|
          # add individual items
          line_item.quantity.times do
            LineItem.create( :cart_id => line_item.cart_id,
                             :product_id => line_item.product_id,
                             :quantity => 1 )
          end

          # remove original item
          line_item.destroy 
        end
      end
    end

  end
end
