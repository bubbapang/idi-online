json.set! @cart_item.id do
    json.extract! @cart_item, :id, :user_id, :store_id, :item_id, :quantity
end